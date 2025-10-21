# Kanban-style rendering system for grouped task and project views

Set-StrictMode -Version Latest

class PmcKanbanRenderer {
    [string] $Domain
    [string] $GroupField
    [hashtable] $Columns
    [object] $FrameRenderer
    [int] $SelectedLane = 0
    [int] $SelectedIndex = 0
    [array] $Lanes = @()  # array of @{ Key=<string>; Items=<array> }
    [object] $GridHelper
    [bool] $MoveActive = $false
    [int] $MoveSourceLane = -1
    [int] $MoveSourceIndex = -1
    [int] $MoveTargetLane = -1
    [int] $MoveTargetIndex = -1
    [array] $CurrentData = @()
    [int[]] $LaneOffsets = @()
    [bool] $ShowHelp = $false
    [string] $FilterText = ''
    [bool] $FilterActive = $false

    PmcKanbanRenderer([string]$domain, [string]$group, [hashtable]$columns) {
        $this.Domain = $domain
        $this.GroupField = $group
        $this.Columns = $columns
        $this.FrameRenderer = [PraxisFrameRenderer]::new()
        $this.GridHelper = [PmcGridRenderer]::new($columns, @($domain), @{})
    }

    [void] BuildLanes([array]$Data) {
        $map = @{}
        foreach ($row in $Data) {
            if ($null -eq $row) { continue }
            $key = ''
            try { if ($row.PSObject.Properties[$this.GroupField]) { $key = [string]$row.($this.GroupField) } } catch {}
            if (-not $map.ContainsKey($key)) { $map[$key] = @() }
            $map[$key] += $row
        }
        $keys = @($map.Keys | Sort-Object)
        $this.Lanes = @()
        foreach ($k in $keys) { $this.Lanes += @{ Key=$k; Items=$map[$k] } }
        # Preserve offsets by lane key
        $newOffsets = @()
        for ($i=0; $i -lt $this.Lanes.Count; $i++) {
            $key = $this.Lanes[$i].Key
            $off = 0
            if ($this.LaneOffsets -and $this.LaneOffsets.Count -eq $this.Lanes.Count) { $off = $this.LaneOffsets[$i] }
            $newOffsets += $off
        }
        $this.LaneOffsets = $newOffsets
        if ($this.SelectedLane -ge $this.Lanes.Count) { $this.SelectedLane = [Math]::Max(0, $this.Lanes.Count-1) }
        if ($this.SelectedLane -lt 0) { $this.SelectedLane = 0 }
        $currentCount = if ($this.Lanes.Count -gt 0) { @($this.Lanes[$this.SelectedLane].Items).Count } else { 0 }
        if ($this.SelectedIndex -ge $currentCount) { $this.SelectedIndex = [Math]::Max(0, $currentCount-1) }
        if ($this.SelectedIndex -lt 0) { $this.SelectedIndex = 0 }
        if (-not $this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
    }

    [string] FormatCard([object]$item, [int]$width, [bool]$isSelected) {
        $id = ''
        if ($item -and $item.PSObject.Properties['id']) { $id = [string]$item.id }
        $text = $this.GridHelper.GetItemValue($item, 'text')
        $prio = $this.GridHelper.GetItemValue($item, 'priority')
        $due = $this.GridHelper.GetItemValue($item, 'due')
        $status = $this.GridHelper.GetItemValue($item, 'status')

        # Priority indicators with colors
        $prioIndicator = ''
        $prioColor = ''
        if ($prio) {
            try {
                $p = [int]$prio
                switch ($p) {
                    1 { $prioIndicator = '🔴'; $prioColor = 'Red' }
                    2 { $prioIndicator = '🟡'; $prioColor = 'Yellow' }
                    3 { $prioIndicator = '🟢'; $prioColor = 'Green' }
                    default { $prioIndicator = '●'; $prioColor = 'Gray' }
                }
            } catch {
                $prioIndicator = '●'; $prioColor = 'Gray'
            }
        }

        # Due date highlighting
        $dueIndicator = ''
        $dueColor = ''
        if ($due) {
            try {
                $dueDate = [datetime]$due
                $today = (Get-Date).Date
                $daysDiff = ($dueDate.Date - $today).Days
                if ($daysDiff -lt 0) {
                    $dueIndicator = '⚠️'; $dueColor = 'Red'  # Overdue
                } elseif ($daysDiff -eq 0) {
                    $dueIndicator = '⏰'; $dueColor = 'Yellow'  # Due today
                } elseif ($daysDiff -le 3) {
                    $dueIndicator = '📅'; $dueColor = 'Cyan'  # Due soon
                } else {
                    $dueIndicator = '📆'; $dueColor = 'Gray'  # Future
                }
            } catch {
                $dueIndicator = '📅'; $dueColor = 'Gray'
            }
        }

        # Status indicator
        $statusIndicator = ''
        if ($status) {
            switch ($status.ToLower()) {
                'done' { $statusIndicator = '✅' }
                'in progress' { $statusIndicator = '🔄' }
                'blocked' { $statusIndicator = '🚫' }
                'pending' { $statusIndicator = '⏳' }
                default { $statusIndicator = '📋' }
            }
        }

        # Build card content
        $indicators = @()
        if ($prioIndicator) { $indicators += $prioIndicator }
        if ($dueIndicator) { $indicators += $dueIndicator }
        if ($statusIndicator) { $indicators += $statusIndicator }

        $prefix = if ($indicators.Count -gt 0) { ($indicators -join '') + ' ' } else { '' }
        $idText = if ($id) { "#{0} " -f $id } else { '' }
        $mainText = $text

        # Calculate available space for text
        $prefixLen = ($prefix -replace '[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', 'XX').Length
        $availableWidth = $width - $prefixLen - $idText.Length
        if ($mainText.Length -gt $availableWidth -and $availableWidth -gt 3) {
            $mainText = $mainText.Substring(0, $availableWidth - 1) + '…'
        }

        $label = $prefix + $idText + $mainText
        $label = $label.PadRight($width)

        if ($isSelected) {
            $style = Get-PmcStyle 'Selected'
            return $this.GridHelper.ConvertPmcStyleToAnsi($label, $style, @{})
        }

        # Apply priority-based coloring for non-selected cards
        if ($prioColor -and $prioColor -ne 'Gray') {
            try {
                $style = @{ ForegroundColor = $prioColor }
                return $this.GridHelper.ConvertPmcStyleToAnsi($label, $style, @{})
            } catch {
                return $label
            }
        }

        return $label
    }

    [string] BuildFrame() {
        return [PraxisStringBuilderPool]::Build({ param($sb)
            $termWidth = 100
            try { $termWidth = [PmcTerminalService]::GetWidth() } catch {}
            $laneCount = if ($this.Lanes.Count -gt 0) { $this.Lanes.Count } else { 1 }
            $gap = 3
            $totalGaps = ($laneCount - 1) * $gap
            $laneWidth = [Math]::Max(24, [Math]::Floor( ([double]$termWidth - $totalGaps - 2) / [Math]::Max(1,$laneCount) ))
            $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
            $statusLines = 2
            # Reserve space for: header(1) + separator(1) + status lines(2) + potential drop indicator(1-2 in move mode)
            $moveModePadding = if ($this.MoveActive) { 2 } else { 0 }
            $reservedLines = 2 + $statusLines + $moveModePadding
            $maxItemsPerLane = [Math]::Max(1, $termHeight - $reservedLines)

            # Prepare lane content lines
            $laneLines = @()
            $maxLines = 0
            for ($i=0; $i -lt $laneCount; $i++) {
                $lane = $this.Lanes[$i]
                $lines = @()
                $isTarget = ($this.MoveActive -and $i -eq $this.MoveTargetLane)
                $itemCount = @($lane.Items).Count
                $header = ('{0} ({1})' -f ($lane.Key ?? '(none)'), $itemCount)
                if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }

                # Enhanced header styling for move mode
                if ($isTarget -and $this.MoveActive) {
                    $moveIndicator = '📥 '
                    $header = $moveIndicator + $header
                    if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                    $style = @{ BackgroundColor = 'DarkBlue'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } elseif ($this.MoveActive -and $i -eq $this.MoveSourceLane) {
                    $moveIndicator = '📤 '
                    $header = $moveIndicator + $header
                    if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                    $style = @{ BackgroundColor = 'DarkRed'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } elseif ($i -eq $this.SelectedLane -and -not $this.MoveActive) {
                    $style = Get-PmcStyle 'Selected'
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } else {
                    $lines += $header.PadRight($laneWidth)
                }
                $lines += (('─' * [Math]::Max(1, $laneWidth)).Substring(0, $laneWidth))
                $idx = 0
                $offset = if ($this.LaneOffsets.Count -gt $i) { [Math]::Max(0, $this.LaneOffsets[$i]) } else { 0 }
                $visible = @($lane.Items | Select-Object -Skip $offset -First $maxItemsPerLane)
                foreach ($it in $visible) {
                    $isSel = ($i -eq $this.SelectedLane -and ($offset + $idx) -eq $this.SelectedIndex)
                    $isBeingMoved = ($this.MoveActive -and $i -eq $this.MoveSourceLane -and ($offset + $idx) -eq $this.MoveSourceIndex)
                    $isDropTarget = ($this.MoveActive -and $i -eq $this.MoveTargetLane -and ($offset + $idx) -eq $this.MoveTargetIndex)

                    if ($isBeingMoved) {
                        # Show card being moved with special styling
                        $cardText = $this.FormatCard($it, $laneWidth, $false)
                        $style = @{ BackgroundColor = 'DarkRed'; ForegroundColor = 'Yellow' }
                        $moveIndicator = '📦 MOVING → '
                        $cardText = $moveIndicator + $cardText.Trim()
                        if ($cardText.Length -gt $laneWidth) { $cardText = $cardText.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                        $lines += $this.GridHelper.ConvertPmcStyleToAnsi($cardText.PadRight($laneWidth), $style, @{})
                    } elseif ($isDropTarget) {
                        # Show drop target position
                        $dropIndicator = '▼ DROP HERE ▼'
                        $style = @{ BackgroundColor = 'DarkGreen'; ForegroundColor = 'White' }
                        $lines += $this.GridHelper.ConvertPmcStyleToAnsi($dropIndicator.PadRight($laneWidth), $style, @{})
                        $lines += $this.FormatCard($it, $laneWidth, $isSel)
                    } else {
                        $lines += $this.FormatCard($it, $laneWidth, $isSel)
                    }
                    $idx++
                }

                # Add drop target at end of lane if target is beyond items
                if ($this.MoveActive -and $i -eq $this.MoveTargetLane -and $this.MoveTargetIndex -ge @($lane.Items).Count) {
                    $dropIndicator = '▼ DROP HERE ▼'
                    $style = @{ BackgroundColor = 'DarkGreen'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($dropIndicator.PadRight($laneWidth), $style, @{})
                }
                $laneLines += ,$lines
                if ($lines.Count -gt $maxLines) { $maxLines = $lines.Count }
            }

            # Cap maxLines to prevent terminal overflow
            $maxAllowedLines = $termHeight - $statusLines
            if ($maxLines -gt $maxAllowedLines) { $maxLines = $maxAllowedLines }

            # Compose lines row by row
            for ($row=0; $row -lt $maxLines; $row++) {
                $lineParts = @()
                for ($i=0; $i -lt $laneCount; $i++) {
                    $lines = $laneLines[$i]
                    $seg = if ($row -lt $lines.Count) { $lines[$row] } else { ''.PadRight($laneWidth) }
                    $lineParts += $seg
                }
                $sb.AppendLine(($lineParts -join (' ' * $gap))) | Out-Null
            }

            # Enhanced Status and Help
            $laneName = if ($this.Lanes.Count -gt 0) { $this.Lanes[$this.SelectedLane].Key } else { '' }
            $itemCount = if ($this.Lanes.Count -gt 0) { @($this.Lanes[$this.SelectedLane].Items).Count } else { 0 }

            $filterStatus = if ($this.FilterActive) { " | 🔍 Filter: '$($this.FilterText)'" } else { '' }

            if ($this.MoveActive) {
                $sourceLane = $this.Lanes[$this.MoveSourceLane].Key
                $targetLane = $this.Lanes[$this.MoveTargetLane].Key
                $status1 = ('🔄 MOVING from [{0}] to [{1}] | Position: {2}{3}' -f $sourceLane, $targetLane, ($this.MoveTargetIndex+1), $filterStatus)
                $status2 = ('📋 ←/→: change lane | ↑/↓: change position | Enter/Space: drop | Esc: cancel')
            } else {
                $selectedItem = if ($itemCount -gt 0 -and $this.SelectedIndex -lt $itemCount) {
                    $item = $this.Lanes[$this.SelectedLane].Items[$this.SelectedIndex]
                    $text = $this.GridHelper.GetItemValue($item, 'text')
                    if ($text.Length -gt 30) { $text.Substring(0, 27) + '...' } else { $text }
                } else { '' }

                $status1 = ('📂 LANE [{0}/{1}] {2} | ITEM [{3}/{4}] {5}{6}' -f ($this.SelectedLane+1), $laneCount, $laneName, ($this.SelectedIndex+1), $itemCount, $selectedItem, $filterStatus)
                $status2 = ('🎮 ←/→: lanes | ↑/↓: items | Space: move | Enter: drill down | /: filter | c: clear filter | ?/H: help | Q/Esc: exit')
            }

            $sb.AppendLine($status1) | Out-Null
            $sb.Append($status2) | Out-Null
        })
    }

    [string] BuildHelpOverlay() {
        return [PraxisStringBuilderPool]::Build({ param($sb)
            $sb.AppendLine('╔═══════════════════════════════ KANBAN HELP ═══════════════════════════════╗') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('║  NAVIGATION:                          ACTIONS:                           ║') | Out-Null
            $sb.AppendLine('║  ←/→  Navigate between lanes          Space    Start/complete move       ║') | Out-Null
            $sb.AppendLine('║  ↑/↓  Navigate between items          Enter    Drill down to item detail ║') | Out-Null
            $sb.AppendLine('║  PgUp/PgDn  Page through items        /        Filter cards by text      ║') | Out-Null
            $sb.AppendLine('║                                       c        Clear current filter      ║') | Out-Null
            $sb.AppendLine('║  VISUAL INDICATORS:                   r        Refresh view             ║') | Out-Null
            $sb.AppendLine('║  🔴🟡🟢  Priority (High/Med/Low)         ?/h      Show/hide this help      ║') | Out-Null
            $sb.AppendLine('║  ⚠️📅⏰   Due (Overdue/Soon/Today)        Q/Esc    Exit kanban view         ║') | Out-Null
            $sb.AppendLine('║  ✅🔄🚫   Status (Done/Progress/Block)                                    ║') | Out-Null
            $sb.AppendLine('║  📥📤     Move target/source lanes                                       ║') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('║  MOVE MODE: Select item → Space → Navigate to target → Enter/Space      ║') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('╚═══════════════════════════════════════════════════════════════════════════╝') | Out-Null
            $sb.AppendLine('') | Out-Null
            $sb.Append('Press any key to continue...') | Out-Null
        })
    }

    [void] StartInteractive([array]$Data) {
        $this.CurrentData = $Data
        $this.BuildLanes($Data)
        $refresh = $true
        while ($true) {
            if ($refresh) {
                if ($this.ShowHelp) {
                    $content = $this.BuildHelpOverlay()
                } else {
                    $content = $this.BuildFrame()
                }
                $this.FrameRenderer.RenderFrame($content)
                $refresh = $false
            }

            # Block on ReadKey - no polling needed
            $k = [Console]::ReadKey($true)

                # Handle help overlay
                if ($this.ShowHelp) {
                    $this.ShowHelp = $false
                    $refresh = $true
                    continue
                }

                switch ($k.Key) {
                    'LeftArrow'  {
                        if ($this.MoveActive) { if ($this.MoveTargetLane -gt 0) { $this.MoveTargetLane--; $refresh=$true } }
                        else { if ($this.SelectedLane -gt 0) { $this.SelectedLane--; $this.SelectedIndex = 0; $refresh=$true } }
                    }
                    'RightArrow' {
                        if ($this.MoveActive) { if ($this.MoveTargetLane -lt ($this.Lanes.Count-1)) { $this.MoveTargetLane++; $refresh=$true } }
                        else { if ($this.SelectedLane -lt ($this.Lanes.Count-1)) { $this.SelectedLane++; $this.SelectedIndex = 0; $refresh=$true } }
                    }
                    'UpArrow'    {
                        $cnt = @($this.Lanes[$this.SelectedLane].Items).Count
                        if ($this.SelectedIndex -gt 0) { $this.SelectedIndex-- }
                        # adjust offset
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        if ($this.SelectedIndex -lt $off) { $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off-1) }
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'DownArrow'  {
                        $cnt = @($this.Lanes[$this.SelectedLane].Items).Count
                        if ($this.SelectedIndex -lt ($cnt-1)) { $this.SelectedIndex++ }
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        if ($this.SelectedIndex -ge ($off + $maxItemsPerLane)) { $this.LaneOffsets[$this.SelectedLane] = $off + 1 }
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageUp'     {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off - $maxItemsPerLane)
                        $this.SelectedIndex = [Math]::Max(0, $this.SelectedIndex - $maxItemsPerLane)
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageDown'   {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        $this.LaneOffsets[$this.SelectedLane] = $off + $maxItemsPerLane
                        $this.SelectedIndex = $this.SelectedIndex + $maxItemsPerLane
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'Spacebar'   {
                        if (-not $this.MoveActive) {
                            $this.MoveActive = $true
                            $this.MoveSourceLane = $this.SelectedLane
                            $this.MoveSourceIndex = $this.SelectedIndex
                            $this.MoveTargetLane = $this.SelectedLane
                            $refresh = $true
                        } else {
                            # Drop
                            $this.ApplyMove()
                            $refresh = $true
                        }
                    }
                    'Enter'      {
                        if ($this.MoveActive) { $this.ApplyMove(); $refresh=$true }
                        else {
                            try {
                                $lane = $this.Lanes[$this.SelectedLane]
                                if ($lane) {
                                    Show-PmcCustomGrid -Domain $this.Domain -Columns $this.Columns -Data $lane.Items -Interactive
                                    $this.BuildLanes($this.CurrentData)
                                    $refresh = $true
                                }
                            } catch {}
                        }
                    }
                    'Escape'     { if ($this.MoveActive) { $this.MoveActive=$false; $refresh=$true } else { break } }
                    'Q' { break }
                    'H' { $this.ShowHelp = $true; $refresh = $true }
                    'R' { $this.BuildLanes($this.CurrentData); $refresh = $true }
                    'C' { $this.FilterText = ''; $this.FilterActive = $false; $this.BuildLanes($this.CurrentData); $refresh = $true }
                    default {
                        # Handle special characters
                        if ($k.KeyChar -eq '?') { $this.ShowHelp = $true; $refresh = $true }
                        elseif ($k.KeyChar -eq '/') { $this.StartFilter(); $refresh = $true }
                    }
                }
        }
    }

    [void] ApplyMove() {
        if (-not $this.MoveActive) { return }
        try {
            $srcLane = $this.Lanes[$this.MoveSourceLane]
            if (-not $srcLane) { $this.MoveActive=$false; return }
            $item = $srcLane.Items[$this.MoveSourceIndex]
            if (-not $item) { $this.MoveActive=$false; return }
            $targetLane = $this.Lanes[$this.MoveTargetLane]
            $newKey = [string]($targetLane.Key)

            # Only support task domain for move in MVP
            if ($this.Domain -ne 'task') { $this.MoveActive=$false; return }
            $field = $this.GroupField
            if ([string]::IsNullOrWhiteSpace($field)) { $this.MoveActive=$false; return }

            # Find insertion reference BEFORE modifying anything
            $tItems = @($targetLane.Items)
            $insertRef = if ($this.MoveTargetIndex -ge 0 -and $this.MoveTargetIndex -lt $tItems.Count) {
                $tItems[$this.MoveTargetIndex]
            } else {
                $null
            }

            # Update persistent store
            $root = Get-PmcDataAlias
            $id = if ($item.PSObject.Properties['id']) { [int]$item.id } else { -1 }
            if ($id -lt 0) { $this.MoveActive=$false; return }
            $target = $root.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['id'] -and [int]$_.id -eq $id } | Select-Object -First 1
            if (-not $target) { $this.MoveActive=$false; return }

            $val = $newKey
            if ($field -eq 'project' -and [string]::IsNullOrWhiteSpace($val)) { $val = 'inbox' }
            if ($target.PSObject.Properties[$field]) { $target.$field = $val } else { Add-Member -InputObject $target -MemberType NoteProperty -Name $field -NotePropertyValue $val -Force }
            Save-PmcData -data $root -Action ("kanban-move:$field")

            # Reflect change in live item
            if ($item.PSObject.Properties[$field]) { $item.$field = $val } else { Add-Member -InputObject $item -MemberType NoteProperty -Name $field -NotePropertyValue $val -Force }

            # Reorder in current data to reflect new position
            $list = New-Object System.Collections.ArrayList
            foreach ($x in $this.CurrentData) { [void]$list.Add($x) }

            # Remove item from its current position
            $oldIdx = $list.IndexOf($item)
            if ($oldIdx -ge 0) { $list.RemoveAt($oldIdx) }

            # Find insertion position using the reference item (if it exists)
            $insIdx = if ($insertRef) {
                $refIdx = $list.IndexOf($insertRef)
                if ($refIdx -ge 0) { $refIdx } else { $list.Count }
            } else {
                $list.Count
            }

            # Insert item at calculated position
            $list.Insert($insIdx, $item)

            # Update data and rebuild lanes ONCE
            $this.CurrentData = @($list)
            $this.BuildLanes($this.CurrentData)

            # Calculate final selection position
            # Find where the item ended up in the target lane
            $finalLane = $this.Lanes[$this.MoveTargetLane]
            if ($finalLane) {
                $finalItems = @($finalLane.Items)
                $finalIdx = 0
                for ($i = 0; $i -lt $finalItems.Count; $i++) {
                    if ($finalItems[$i] -eq $item) {
                        $finalIdx = $i
                        break
                    }
                }
                $this.SelectedLane = $this.MoveTargetLane
                $this.SelectedIndex = $finalIdx
            }
        } catch {
            # Ignore, fail-safe
        } finally {
            $this.MoveActive = $false
            $this.MoveSourceLane = -1
            $this.MoveSourceIndex = -1
            $this.MoveTargetIndex = -1
        }
    }

    [void] StartFilter() {
        Write-Host "`r`e[2KFilter: " -NoNewline
        $filter = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($filter)) {
            $this.FilterText = $filter.Trim()
            $this.FilterActive = $true
            $this.ApplyFilter()
        }
    }

    [void] ApplyFilter() {
        if ($this.FilterActive -and -not [string]::IsNullOrWhiteSpace($this.FilterText)) {
            $filteredData = @()
            foreach ($item in $this.CurrentData) {
                if ($null -eq $item) { continue }
                $text = $this.GridHelper.GetItemValue($item, 'text')
                $id = if ($item.PSObject.Properties['id']) { [string]$item.id } else { '' }
                if ($text.ToLower().Contains($this.FilterText.ToLower()) -or $id.Contains($this.FilterText)) {
                    $filteredData += $item
                }
            }
            $this.BuildLanes($filteredData)
        } else {
            $this.BuildLanes($this.CurrentData)
        }
    }
}
