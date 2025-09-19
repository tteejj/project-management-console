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
        $badges = @()
        if ($prio) { $badges += $prio }
        if ($due) { $badges += $due }
        $suffix = ''
        if ($badges.Count -gt 0) { $suffix = ' [' + ($badges -join ' ') + ']' }
        $label = ''
        if ($id) { $label = ('#{0} {1}{2}' -f $id, $text, $suffix) } else { $label = ($text + $suffix) }
        if ($label.Length -gt $width) { $label = $label.Substring(0, [Math]::Max(0,$width-1)) + '…' }
        if ($isSelected) {
            $style = Get-PmcStyle 'Selected'
            return $this.GridHelper.ConvertPmcStyleToAnsi($label.PadRight($width), $style, @{})
        }
        return $label.PadRight($width)
    }

    [string] BuildFrame() {
        return [PraxisStringBuilderPool]::Build({ param($sb)
            $termWidth = 100
            try { $termWidth = [Console]::WindowWidth } catch {}
            $laneCount = if ($this.Lanes.Count -gt 0) { $this.Lanes.Count } else { 1 }
            $gap = 3
            $totalGaps = ($laneCount - 1) * $gap
            $laneWidth = [Math]::Max(24, [Math]::Floor( ([double]$termWidth - $totalGaps - 2) / [Math]::Max(1,$laneCount) ))
            $termHeight = 25; try { $termHeight = [Console]::WindowHeight } catch {}
            $statusLines = 2
            $maxItemsPerLane = [Math]::Max(1, $termHeight - $statusLines - 2 - 2) # minus header & sep

            # Prepare lane content lines
            $laneLines = @()
            $maxLines = 0
            for ($i=0; $i -lt $laneCount; $i++) {
                $lane = $this.Lanes[$i]
                $lines = @()
                $isTarget = ($this.MoveActive -and $i -eq $this.MoveTargetLane)
                $header = ('{0} ({1})' -f ($lane.Key ?? '(none)'), @($lane.Items).Count)
                if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                if ($isTarget) {
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
                    if ($this.MoveActive -and $i -eq $this.MoveSourceLane -and ($offset + $idx) -eq $this.MoveSourceIndex) {
                        # Indicate picked card
                        $isSel = $true
                    }
                    $lines += $this.FormatCard($it, $laneWidth, $isSel)
                    $idx++
                }
                $laneLines += ,$lines
                if ($lines.Count -gt $maxLines) { $maxLines = $lines.Count }
            }

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

            # Status
            $laneName = if ($this.Lanes.Count -gt 0) { $this.Lanes[$this.SelectedLane].Key } else { '' }
            $mode = if ($this.MoveActive) { "MOVE: select lane (←/→) and position (↑/↓), Enter/Space=drop, Esc=cancel" } else { "" }
            $status = ('LANE [{0}/{1}] {2} | ITEM {3} {4}' -f ($this.SelectedLane+1), $laneCount, $laneName, ($this.SelectedIndex+1), $mode)
            $sb.AppendLine('') | Out-Null
            $sb.Append($status) | Out-Null
        })
    }

    [void] StartInteractive([array]$Data) {
        $this.CurrentData = $Data
        $this.BuildLanes($Data)
        $refresh = $true
        while ($true) {
            if ($refresh) {
                $content = $this.BuildFrame()
                $this.FrameRenderer.RenderFrame($content)
                $refresh = $false
            }
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
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
                        $termHeight = 25; try { $termHeight = [Console]::WindowHeight } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        if ($this.SelectedIndex -ge ($off + $maxItemsPerLane)) { $this.LaneOffsets[$this.SelectedLane] = $off + 1 }
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageUp'     {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [Console]::WindowHeight } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off - $maxItemsPerLane)
                        $this.SelectedIndex = [Math]::Max(0, $this.SelectedIndex - $maxItemsPerLane)
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageDown'   {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [Console]::WindowHeight } catch {}
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
                    default {}
                }
            } else {
                Start-Sleep -Milliseconds 50
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

            # Reorder in current data to reflect new position (ephemeral)
            $list = New-Object System.Collections.ArrayList
            foreach ($x in $this.CurrentData) { [void]$list.Add($x) }
            $oldIdx = $list.IndexOf($item)
            if ($oldIdx -ge 0) { $list.RemoveAt($oldIdx) }
            # Find insertion index: before MoveTargetIndex in target lane sequence
            $flat = @()
            foreach ($ln in $this.Lanes) { foreach ($it in $ln.Items) { $flat += $it } }
            # Build new lanes based on updated field
            $this.BuildLanes(@($list))
            $tItems = @($this.Lanes[$this.MoveTargetLane].Items)
            $insertRef = if ($this.MoveTargetIndex -ge 0 -and $this.MoveTargetIndex -lt $tItems.Count) { $tItems[$this.MoveTargetIndex] } else { $null }
            $insIdx = if ($insertRef) { $list.IndexOf($insertRef) } else { $list.Count }
            if ($insIdx -lt 0) { $insIdx = $list.Count }
            $list.Insert($insIdx, $item)

            $this.CurrentData = @($list)
            $this.BuildLanes($this.CurrentData)
            $this.SelectedLane = $this.MoveTargetLane; $this.SelectedIndex = $this.MoveTargetIndex
        } catch {
            # Ignore, fail-safe
        } finally {
            $this.MoveActive = $false
            $this.MoveSourceLane = -1
            $this.MoveSourceIndex = -1
            $this.MoveTargetIndex = -1
        }
    }
}
