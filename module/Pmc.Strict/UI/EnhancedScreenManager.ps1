# PMC Enhanced Screen Manager - Non-blocking unified interface
# Combines command line + navigation + real-time updates

Set-StrictMode -Version Latest

# Screen regions helper class
class PmcScreenRegions {
    [int] $Width
    [int] $Height
    [int] $HeaderHeight = 3
    [int] $StatusHeight = 2
    [int] $CommandHeight = 1

    # Region coordinates
    [object] $Header
    [object] $Content
    [object] $Status
    [object] $Command

    PmcScreenRegions([int]$width, [int]$height) {
        $this.Width = $width
        $this.Height = $height
        $this.InitializeRegions()
    }

    PmcScreenRegions([int]$width, [int]$height, [int]$headerHeight, [int]$statusHeight, [int]$commandHeight) {
        $this.Width = $width
        $this.Height = $height
        $this.HeaderHeight = $headerHeight
        $this.StatusHeight = $statusHeight
        $this.CommandHeight = $commandHeight
        $this.InitializeRegions()
    }

    hidden [void] InitializeRegions() {
        $contentHeight = [Math]::Max(0, $this.Height - $this.HeaderHeight - $this.StatusHeight - $this.CommandHeight)
        $this.Header = [PSCustomObject]@{ X=0; Y=0; Width=$this.Width; Height=$this.HeaderHeight }
        $this.Content = [PSCustomObject]@{ X=0; Y=$this.HeaderHeight; Width=$this.Width; Height=$contentHeight }
        $this.Status = [PSCustomObject]@{ X=0; Y=($this.Height - $this.StatusHeight - $this.CommandHeight); Width=$this.Width; Height=$this.StatusHeight }
        $this.Command = [PSCustomObject]@{ X=0; Y=($this.Height - $this.CommandHeight); Width=$this.Width; Height=$this.CommandHeight }
    }

    [int] GetContentHeight() {
        return $this.Height - $this.HeaderHeight - $this.StatusHeight - $this.CommandHeight
    }
}

# UI mode + interaction enums/state
enum PmcUIMode {
    Command = 0
    UI = 1
}

enum PmcUIInteract {
    Browse = 0
    Edit = 1
}

class PmcUIState {
    [PmcUIMode] $Mode = [PmcUIMode]::Command
    [PmcUIInteract] $UIState = [PmcUIInteract]::Browse
    [string] $CommandBuffer = ''
    [int] $CommandCursor = 0
    [int] $SelectedRow = 0
    [int] $SelectedColumn = 0
    [string] $EditText = ''
    [int] $EditCursor = 0
}

# Enhanced screen manager that orchestrates all UI components
class PmcEnhancedScreenManager {
    # Core components
    hidden [PmcDifferentialRenderer] $_renderer
    hidden [PmcUnifiedDataViewer] $_dataViewer
    hidden [PmcScreenRegions] $_regions

    # State management
    hidden [bool] $_active = $false
    hidden [bool] $_initialized = $false
    hidden [datetime] $_lastRefresh = [datetime]::Now

    # Command line state
    hidden [string] $_commandBuffer = ""
    hidden [int] $_commandCursorPos = 0
    hidden [string] $_lastCommand = ""

    # Screen layout
    hidden [string] $_headerText = "PMC - Enhanced Project Management Console"
    hidden [string] $_promptText = "pmc> "
    hidden [bool]   $_headerDirty = $true
    hidden [int] $_preferredHeaderHeight = 0
    hidden [int] $_preferredStatusHeight = 2
    hidden [int] $_preferredCommandHeight = 1

    # Bar colors (configurable)
    hidden [string] $_headerBg = 'blue'
    hidden [string] $_statusBg = 'black'

    # Performance tracking
    hidden [int] $_frameCount = 0
    hidden [datetime] $_sessionStart = [datetime]::Now

    # Resize debounce
    hidden [datetime] $_lastResizeChange = [datetime]::MinValue
    hidden [int] $_pendingWidth = 0
    hidden [int] $_pendingHeight = 0
    hidden [int] $_resizeDebounceMs = 120

    # Event handlers for integration with existing PMC
    [scriptblock] $CommandProcessor = $null
    [scriptblock] $CompletionProvider = $null

    # Query helper overlay state
    hidden [bool] $_queryHelperActive = $false
    hidden [string] $_queryHelperDomain = 'task'
    hidden [object[]] $_queryHelperItems = @()
    hidden [int] $_queryHelperIndex = 0
    # New unified UI state
    hidden [PmcUIState] $_ui = [PmcUIState]::new()
    # Single toggle: Ctrl+Backtick (ConsoleKey.Oem3)

    PmcEnhancedScreenManager() {
        try {
            $this.InitializeComponents()
            $this.LoadBarColors()
            $this._initialized = $true
        } catch {
            "ERROR in constructor: $($_.Exception.Message)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            "ERROR at line: $($_.InvocationInfo.ScriptLineNumber)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            throw
        }
    }

    [void] LoadBarColors() {
        try {
            if (Get-Command Get-PmcConfig -ErrorAction SilentlyContinue) {
                $disp = Get-PmcConfig -Section 'Display'
                if ($disp -and $disp.Bars) {
                    if ($disp.Bars.HeaderBg) { $this._headerBg = [string]$disp.Bars.HeaderBg }
                    if ($disp.Bars.StatusBg) { $this._statusBg = [string]$disp.Bars.StatusBg }
                }
            }
        } catch { }
    }

    [void] SetHeaderText([string]$text) {
        if ($null -eq $text) { return }
        if ($this._headerText -ne $text) {
            $this._headerText = $text
            $this._headerDirty = $true
        }
    }

    [void] InitializeComponents() {
        try {
            # Initialize renderer
            $this._renderer = Get-PmcDifferentialRenderer
            if (-not $this._renderer) {
                Initialize-PmcDifferentialRenderer
                $this._renderer = Get-PmcDifferentialRenderer
            }

            # Calculate screen regions
            $width = $this._renderer.GetDrawBuffer().GetWidth()
            $height = $this._renderer.GetDrawBuffer().GetHeight()
            $this._regions = [PmcScreenRegions]::new($width, $height, $this._preferredHeaderHeight, $this._preferredStatusHeight, $this._preferredCommandHeight)
            # Legacy init debug removed

            # Initialize data viewer - always reset to ensure proper bounds
            Reset-PmcUnifiedDataViewer
            Initialize-PmcUnifiedDataViewer -Bounds $this._regions.Content
            $this._dataViewer = Get-PmcUnifiedDataViewer
            # Legacy debug removed

            # Set data viewer renderer
            $this._dataViewer.SetRenderer($this._renderer)

            Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Enhanced screen manager components initialized"

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Component initialization failed: $_"
            throw
        }
    }

    hidden [bool] HasRegionProps([object]$region) {
        try {
            $null = $region.X; $null = $region.Y; $null = $region.Width; $null = $region.Height
            return $true
        } catch { return $false }
    }

    hidden [void] EnsureRegions([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        $needsRebuild = $false
        try { if (-not $this.HasRegionProps($this._regions.Header)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Content)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Status)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Command)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        if ($needsRebuild) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h, $this._preferredHeaderHeight, $this._preferredStatusHeight, $this._preferredCommandHeight)
                $this._headerDirty = $true
                # Legacy debug removed
            } catch { }
        }
    }

    [void] SetupInputHandlers() { }

    # Legacy entry rejected — single modal path only
    [void] StartSession() { throw "Use StartModalSession()" }

    # Modal session using blocking input per mode (no background readers)
    [void] StartModalSession() {
        if ($this._active) {
            Write-Warning "Enhanced screen session already active"
            return
        }

        $this._active = $true
        $this._sessionStart = [datetime]::Now

        try {
            # Clear previous temp debug file to avoid stale lines
            try { if (Test-Path "/tmp/pmc-debug.log") { Remove-Item "/tmp/pmc-debug.log" -Force -ErrorAction SilentlyContinue } } catch {}
            $this.Log(2, 'StartModalSession')
            # Clear and initial full compose
            Write-Host "`e[2J`e[H" -NoNewline
            $this._renderer.HideCursor()
            Start-Sleep -Milliseconds 50
            $this.RenderFullInterface()

            # Initial data
            $this._dataViewer.SetDataType("task")
            $this._dataViewer.RefreshData()
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataArea($buf)
            $this.RenderCommandLine($null, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()

            $this.EnterCommandFocus()

            while ($this._active) {
                # Resize debounce handling
                try {
                    $buf = $this._renderer.GetDrawBuffer()
                    $bw = $buf.GetWidth(); $bh = $buf.GetHeight()
                    $cw = [Console]::WindowWidth; $ch = [Console]::WindowHeight
                    if ($cw -ne $bw -or $ch -ne $bh) {
                        $this._pendingWidth = $cw; $this._pendingHeight = $ch
                        $this._lastResizeChange = [datetime]::Now
                        $this._headerDirty = $true
                    }
                    if ($this._lastResizeChange -ne [datetime]::MinValue) {
                        $elapsed = ([datetime]::Now - $this._lastResizeChange).TotalMilliseconds
                        if ($elapsed -ge $this._resizeDebounceMs) {
                            $this._renderer.Resize($this._pendingWidth, $this._pendingHeight)
                            $this._regions = [PmcScreenRegions]::new($this._pendingWidth, $this._pendingHeight)
                            if ($this._dataViewer) { $this._dataViewer.SetBounds($this._regions.Content) }
                            $this.RenderFullInterface()
                            $this._renderer.Render()
                            $this._lastResizeChange = [datetime]::MinValue
                        }
                    }
                } catch { }

                if ($this._ui.Mode -eq [PmcUIMode]::Command) { $this.CommandLoop() }
                else { $this.UiLoop() }
            }
        } finally {
            $this.Cleanup()
        }
    }

    # Mode management helpers
    [void] EnterCommandFocus() {
        $this._ui.Mode = [PmcUIMode]::Command
        $this._ui.UIState = [PmcUIInteract]::Browse
        $this.Log(2,'EnterCommandFocus')
        $this.RenderFullInterface()
    }

    [void] EnterUiFocus() {
        $this._ui.Mode = [PmcUIMode]::UI
        $this._ui.UIState = [PmcUIInteract]::Browse
        $this.Log(2,'EnterUiFocus')
        $this.RenderFullInterface()
    }

    [void] CommandLoop() {
        while ($this._active -and $this._ui.Mode -eq [PmcUIMode]::Command) {
            try { $key = [Console]::ReadKey($true) } catch { Start-Sleep -Milliseconds 25; continue }
            if ( ($key.Key -eq [ConsoleKey]::Oem3) -and ($key.Modifiers -band [ConsoleModifiers]::Control) ) { $this.Log(2,'Toggle via Ctrl+`'); $this.EnterUiFocus(); $this.DrainConsoleInput(25); break }
            if ($key.Key -eq [ConsoleKey]::Escape) {
                $seq = $this.TryReadCsiUSequence()
                if ($seq -eq '[96;5u') { $this.Log(2,'Toggle via CSI-u [96;5u]'); $this.EnterUiFocus(); $this.DrainConsoleInput(25); break }
                continue
            }
            if ($key.Key -eq [ConsoleKey]::F10 -or ($key.Key -eq [ConsoleKey]::Q -and ($key.Modifiers -band [ConsoleModifiers]::Control))) { $this.StopSession(); break }

            $state = [PSCustomObject]@{ CommandBuffer = $this._ui.CommandBuffer; CommandCursorPos = $this._ui.CommandCursor }

            $this.HandleCommandLineInput($key, $state)

            $this._ui.CommandBuffer = $state.CommandBuffer
            $this._ui.CommandCursor = $state.CommandCursorPos
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderCommandLine($state, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()
        }
    }

    [void] UiLoop() {
        while ($this._active -and $this._ui.Mode -eq [PmcUIMode]::UI) {
            try { $key = [Console]::ReadKey($true) } catch { Start-Sleep -Milliseconds 25; continue }
            if ( ($key.Key -eq [ConsoleKey]::Oem3) -and ($key.Modifiers -band [ConsoleModifiers]::Control) ) { $this.Log(2,'Toggle via Ctrl+`'); $this.EnterCommandFocus(); $this.DrainConsoleInput(25); break }
            if ($key.Key -eq [ConsoleKey]::Escape) {
                $seq = $this.TryReadCsiUSequence()
                if ($seq -eq '[96;5u') { $this.Log(2,'Toggle via CSI-u [96;5u]'); $this.EnterCommandFocus(); $this.DrainConsoleInput(25); break }
                continue
            }
            if ($key.Key -eq [ConsoleKey]::F10 -or ($key.Key -eq [ConsoleKey]::Q -and ($key.Modifiers -band [ConsoleModifiers]::Control))) { $this.StopSession(); break }

            if ($this._ui.UIState -eq [PmcUIInteract]::Edit) {
                $this.HandleInlineEditLoopKey($key)
                continue
            }

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)   { $this._dataViewer.MoveSelection(-1) }
                ([ConsoleKey]::DownArrow) { $this._dataViewer.MoveSelection(1) }
                ([ConsoleKey]::PageUp)    { $this._dataViewer.MoveSelection(-10) }
                ([ConsoleKey]::PageDown)  { $this._dataViewer.MoveSelection(10) }
                ([ConsoleKey]::Home)      { $this._dataViewer.MoveSelection(-1000) }
                ([ConsoleKey]::End)       { $this._dataViewer.MoveSelection(1000) }
                ([ConsoleKey]::LeftArrow) { if ($this._ui.SelectedColumn -gt 0) { $this._ui.SelectedColumn-- } }
                ([ConsoleKey]::RightArrow){ $this._ui.SelectedColumn++ }
                ([ConsoleKey]::Enter)     { $this.StartInlineEdit($null) }
                ([ConsoleKey]::F2)        { $this.StartInlineEdit($null) }
                default {
                    if (-not [char]::IsControl($key.KeyChar) -and $key.KeyChar -ne [char]0) { $this.StartInlineEdit([string]$key.KeyChar) }
                }
            }

            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataArea($buf)
            $this.RenderCommandLine($null, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()
        }
    }

    hidden [string] TryReadCsiUSequence() {
        $s = ''
        $deadline = [datetime]::Now.AddMilliseconds(150)
        while ([datetime]::Now -lt $deadline) {
            try {
                if (-not [Console]::KeyAvailable) { Start-Sleep -Milliseconds 1; continue }
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq [ConsoleKey]::Escape) { continue }
            } catch { break }
            if ($k.KeyChar -eq '[' -and $s -eq '') { $s += '['; continue }
            if ($s.StartsWith('[')) {
                $s += [string]$k.KeyChar
                if ($k.KeyChar -eq 'u') { break }
                continue
            }
            # If not part of CSI-u, stop
            break
        }
        return $s
    }

    hidden [void] DrainConsoleInput([int]$ms = 10) {
        $until = [datetime]::Now.AddMilliseconds([Math]::Max(0,$ms))
        while ([datetime]::Now -lt $until) {
            try {
                while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) }
            } catch { break }
            Start-Sleep -Milliseconds 1
        }
    }

    [void] StartInlineEdit([string]$seedChar) {
        $this._ui.UIState = [PmcUIInteract]::Edit
        $columns = $this._dataViewer.GetColumnDefinitions()
        if (-not $columns -or $columns.Count -eq 0) { $this._ui.UIState = [PmcUIInteract]::Browse; return }
        $dvState = $this._dataViewer.GetState()
        $content = $this._regions.Content
        $availableWidth = $content.Width - 2
        $widths = $this._dataViewer.CalculateColumnWidths($columns, $availableWidth)

        $colCount = @($columns).Count
        if ($this._ui.SelectedColumn -ge $colCount) { $this._ui.SelectedColumn = [Math]::Max(0, $colCount - 1) }

        $x = $content.X + 1
        for ($i = 0; $i -lt $this._ui.SelectedColumn; $i++) {
            $n = $this.GetColNameSafe($columns[$i])
            if ($n -and $widths.ContainsKey($n)) { $x += $widths[$n] + 1 }
        }
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $cellWidth = if ($colName -and $widths.ContainsKey($colName)) { [int]$widths[$colName] } else { 10 }
        $y = $content.Y + 1 + ($dvState.SelectedRow - $dvState.ScrollOffset)

        $item = $this._dataViewer.GetSelectedItem()
        $current = ''
        try { if ($item -and $colName) { $current = [string]$item.($colName) } } catch { $current = '' }

        if ($seedChar) { $this._ui.EditText = $seedChar + $current; $this._ui.EditCursor = [Math]::Min($this._ui.EditText.Length, 1) }
        else { $this._ui.EditText = $current; $this._ui.EditCursor = $this._ui.EditText.Length }

        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.SetDesiredCursor($x + $this._ui.EditCursor, $y)
        $this._renderer.Render()
    }

    [void] HandleInlineEditLoopKey([ConsoleKeyInfo]$key) {
        $columns = $this._dataViewer.GetColumnDefinitions()
        $dvState = $this._dataViewer.GetState()
        $content = $this._regions.Content
        $availableWidth = $content.Width - 2
        $widths = $this._dataViewer.CalculateColumnWidths($columns, $availableWidth)
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $cellWidth = if ($colName -and $widths.ContainsKey($colName)) { [int]$widths[$colName] } else { 10 }
        $x = $content.X + 1
        for ($i = 0; $i -lt $this._ui.SelectedColumn; $i++) {
            $n = $this.GetColNameSafe($columns[$i])
            if ($n -and $widths.ContainsKey($n)) { $x += $widths[$n] + 1 }
        }
        $y = $content.Y + 1 + ($dvState.SelectedRow - $dvState.ScrollOffset)

        switch ($key.Key) {
            ([ConsoleKey]::Enter) { $this.CommitInlineEdit(); return }
            ([ConsoleKey]::Escape){ $this.CancelInlineEdit(); return }
            ([ConsoleKey]::Backspace) {
                if ($this._ui.EditCursor -gt 0) { $this._ui.EditText = $this._ui.EditText.Remove($this._ui.EditCursor - 1, 1); $this._ui.EditCursor-- }
            }
            ([ConsoleKey]::Delete) {
                if ($this._ui.EditCursor -lt $this._ui.EditText.Length) { $this._ui.EditText = $this._ui.EditText.Remove($this._ui.EditCursor, 1) }
            }
            ([ConsoleKey]::LeftArrow) { if ($this._ui.EditCursor -gt 0) { $this._ui.EditCursor-- } }
            ([ConsoleKey]::RightArrow){ if ($this._ui.EditCursor -lt $this._ui.EditText.Length) { $this._ui.EditCursor++ } }
            ([ConsoleKey]::Home)      { $this._ui.EditCursor = 0 }
            ([ConsoleKey]::End)       { $this._ui.EditCursor = $this._ui.EditText.Length }
            default {
                if (-not [char]::IsControl($key.KeyChar) -and $key.KeyChar -ne [char]0) { $this._ui.EditText = $this._ui.EditText.Insert($this._ui.EditCursor, [string]$key.KeyChar); $this._ui.EditCursor++ }
            }
        }

        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.SetDesiredCursor($x + [Math]::Min($this._ui.EditCursor, [Math]::Max(0,$cellWidth-1)), $y)
        $this._renderer.Render()
    }

    [void] CommitInlineEdit() {
        $columns = $this._dataViewer.GetColumnDefinitions()
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $item = $this._dataViewer.GetSelectedItem()
        try { if ($item -and $colName) { $item.($colName) = $this._ui.EditText } } catch { }
        $this._ui.UIState = [PmcUIInteract]::Browse
        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.Render()
    }

    [void] CancelInlineEdit() {
        $this._ui.UIState = [PmcUIInteract]::Browse
        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.Render()
    }

    hidden [string] GetColNameSafe([object]$col) {
        if ($null -eq $col) { return '' }
        if ($col -is [hashtable]) { if ($col.ContainsKey('Name')) { return [string]$col['Name'] } }
        if ($col.PSObject.Properties['Name']) { return [string]$col.Name }
        if ($col.PSObject.Properties['Key']) { return [string]$col.Key }
        return ''
    }

    # Removed non-blocking variant — single path only

    [void] StopSession() {
        $this._active = $false
    }

    [void] ProcessInput([ConsoleKeyInfo]$key) { }
    [void] ProcessInputFromString([string]$inputLine) { }

    # Input handlers for different contexts
    [void] HandleCommandLineInput([ConsoleKeyInfo]$key, $state) {
        switch ($key.Key) {
            'Enter' {
                $text = ($state.CommandBuffer ?? '').Trim()
                if ($text) {
                    if ($text -ieq 'help') {
                        $this.Log(2,'Command: help (switching data type to help)')
                        try { $this._dataViewer.SetDataType('help'); $this._dataViewer.RefreshData() } catch {}
                        $state.CommandBuffer = ""
                        $state.CommandCursorPos = 0
                        # Full repaint to stabilize view
                        $this.RenderFullInterface()
                        return
                    }
                    $this.ExecuteCommand($text)
                    $state.CommandBuffer = ""
                    $state.CommandCursorPos = 0
                }
            }
            'Backspace' {
                if ($state.CommandCursorPos -gt 0) {
                    $state.CommandBuffer = $state.CommandBuffer.Remove($state.CommandCursorPos - 1, 1)
                    $state.CommandCursorPos--
                }
            }
            'LeftArrow' {
                if ($state.CommandCursorPos -gt 0) {
                    $state.CommandCursorPos--
                }
            }
            'RightArrow' {
                if ($state.CommandCursorPos -lt $state.CommandBuffer.Length) {
                    $state.CommandCursorPos++
                }
            }
            'UpArrow' {
                return
            }
            'Tab' {
                $this.HandleTabCompletion($state)
            }
            default {
                if (-not [char]::IsControl($key.KeyChar)) {
                    $state.CommandBuffer = $state.CommandBuffer.Insert($state.CommandCursorPos, $key.KeyChar)
                    $state.CommandCursorPos++
                }
            }
        }

        $this.RenderCommandLine($state)
    }

    [void] HandleGridNavigationInput([ConsoleKeyInfo]$key, $state) {
        switch ($key.Key) {
            'UpArrow' { $this._dataViewer.MoveSelection(-1) }
            'DownArrow' { $this._dataViewer.MoveSelection(1) }
            'PageUp' { $this._dataViewer.MoveSelection(-10) }
            'PageDown' { $this._dataViewer.MoveSelection(10) }
            'Home' { $this._dataViewer.MoveSelection(-1000) }
            'End' { $this._dataViewer.MoveSelection(1000) }
            'Enter' {
                $selectedItem = $this._dataViewer.GetSelectedItem()
                if ($selectedItem) {
                    $this.HandleItemSelection($selectedItem)
                }
            }
            'Escape' { $this.EnterCommandFocus(); return }
            default {
                # Letter/number keys for quick search or command
                if ([char]::IsLetterOrDigit($key.KeyChar)) {
                    $state.CommandBuffer = [string]$key.KeyChar
                    $state.CommandCursorPos = 1
                    $this.EnterCommandFocus()
                    $this.RenderCommandLine([pscustomobject]@{ CommandBuffer=$this._ui.CommandBuffer; CommandCursorPos=$this._ui.CommandCursor })
                }
            }
        }
    }

    [void] HandleInlineEditInput([ConsoleKeyInfo]$key, $state) {
        # Placeholder for inline editing
        switch ($key.Key) {
            'Enter' {
                $this._ui.UIState = [PmcUIInteract]::Browse
            }
            'Escape' {
                $this._ui.UIState = [PmcUIInteract]::Browse
            }
        }
    }

    # Command execution
    [void] ExecuteCommand([string]$command) {
        $this._lastCommand = $command
        Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Executing command: '$command'"

        try {
            if ($this.CommandProcessor) {
                & $this.CommandProcessor $command
            } else {
                # Fallback to existing PMC command system
                if (Get-Command Invoke-PmcEnhancedCommand -ErrorAction SilentlyContinue) {
                    Invoke-PmcEnhancedCommand -Command $command
                }
            }

            # Refresh data after command execution
            $this._dataViewer.RefreshData()

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Command execution failed: $_"
            # Show error in status area
            $this.ShowError("Command failed: $_")
        }
    }

    [void] HandleTabCompletion($state) {
        if ($this.CompletionProvider) {
            try {
                $completions = & $this.CompletionProvider $state.CommandBuffer $state.CommandCursorPos
                if ($completions -and $completions.Count -gt 0) {
                    # Simple completion - take first match
                    $completion = $completions[0]
                    $state.CommandBuffer = $completion
                    $state.CommandCursorPos = $completion.Length
                    $this.RenderCommandLine($state)
                }
            } catch {
                Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Tab completion failed: $_"
            }
        }
    }

    [void] HandleItemSelection([object]$item) {
        Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Item selected: $($item | ConvertTo-Json -Compress)"
        # Placeholder for item selection handling
    }

    # Rendering methods
    [void] RenderFullInterface() {
        $buffer = $this._renderer.GetDrawBuffer()
        $this.EnsureRegions($buffer)
        $buffer.Clear()

        $this.RenderHeader($buffer)
        $this.RenderDataArea($buffer)
        $this.RenderCommandLine($null, $buffer)
        $this.RenderStatus($buffer)

        # Force render the buffer to screen
        $this._renderer.Render()
    }

    [void] RenderInterface() {
        $this.EnsureRegions()
        $buffer = $this._renderer.GetDrawBuffer()
        if ($this._headerDirty) { $this.RenderHeader($buffer); $this._headerDirty = $false }
        $this.RenderDataArea($buffer)
        $this.RenderCommandLine($null, $buffer)
        $this.RenderStatus($buffer)
    }

    [void] RenderHeader([PmcScreenBuffer]$buffer = $null) {
        try {
            if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

            $header = $this._regions.Header
            if (-not $this.HasRegionProps($header)) {
                $this.EnsureRegions($buffer)
                $header = $this._regions.Header
            }
            $headerX = $header.X
            $headerY = $header.Y

            if ($this._regions.Header.Height -gt 0 -and $this._headerText) {
                $buffer.SetText($headerX + 2, $headerY, $this._headerText, 'white', $this._headerBg)
            }
        } catch {
            "ERROR in RenderHeader: $($_.Exception.Message)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            "ERROR at line: $($_.InvocationInfo.ScriptLineNumber)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            throw
        }
    }

    [void] RenderDataArea([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        # Validate content region
        $content = $this._regions.Content
        if (-not $this.HasRegionProps($content)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $content = $this._regions.Content
                # Legacy debug removed
            } catch { }
        }
        if ($this._queryHelperActive) {
            $this.RenderQueryHelper($buffer)
        } else {
            try {
                $this._dataViewer.Render()
            } catch {
                # Draw a simple error message in the content area without crashing
                try {
                    $msg = ("Error: {0}" -f $_.Exception.Message)
                    $buffer.ClearRegion($content.X, $content.Y, $content.Width, $content.Height)
                    $buffer.SetText($content.X + 1, $content.Y, $msg, 'red', 'black')
                    $this.Log(1, ("RenderDataArea error: {0}" -f $_.Exception.Message))
                } catch {}
            }
        }
    }

    [void] RenderQueryHelper([PmcScreenBuffer]$buffer) {
        $content = $this._regions.Content
        # Clear content area
        $buffer.ClearRegion($content.X, $content.Y, $content.Width, $content.Height)
        # Header
        $title = "Query Helper — $($this._queryHelperDomain)"
        $buffer.SetText($content.X + 2, $content.Y, $title, 'yellow', 'black')
        # List
        $maxRows = [Math]::Max(3, $content.Height - 2)
        $start = 0
        $end = [Math]::Min(@($this._queryHelperItems).Count, $start + $maxRows)
        for ($i = $start; $i -lt $end; $i++) {
            $rowY = $content.Y + 1 + ($i - $start)
            $item = $this._queryHelperItems[$i]
            $name = [string]$item.Name
            $tok  = [string]$item.Token
            $line = if ($i -eq $this._queryHelperIndex) { "> $name  [$tok]" } else { "  $name  [$tok]" }
            $fg = if ($i -eq $this._queryHelperIndex) { 'black' } else { 'white' }
            $bg = if ($i -eq $this._queryHelperIndex) { 'cyan' } else { 'black' }
            $buffer.SetText($content.X + 2, $rowY, $line, $fg, $bg)
        }
        # Hint
        $hint = "Enter: insert • Esc: close • ↑/↓: select"
        $buffer.SetText($content.X + 2, $content.Y + $content.Height - 1, $hint, 'cyan', 'black')
    }

    [void] OpenQueryHelper($state) {
        # Determine domain from buffer (q <domain> ...), default to 'task'
        $this._queryHelperDomain = 'task'
        try {
            $parts = ($state.CommandBuffer).Trim().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Count -ge 2 -and $parts[0] -ieq 'q') { $this._queryHelperDomain = $parts[1].ToLower() }
        } catch {}

        # Build items from field schemas
        $this._queryHelperItems = @()
        try {
            $schemas = Get-PmcFieldSchemasForDomain -Domain $this._queryHelperDomain
            foreach ($name in ($schemas.Keys | Sort-Object)) {
                $token = switch ($name) {
                    'project' { '@' }
                    'tags'    { '#' }
                    'priority'{ 'p' }
                    'due'     { 'due:' }
                    default   { "${name}:" }
                }
                $this._queryHelperItems += [pscustomobject]@{ Name=$name; Token=$token }
            }
        } catch {}
        $this._queryHelperIndex = 0
        $this._queryHelperActive = $true
        # Internal modal only
        # Render overlay
        $this.RenderInterface()
    }

    [void] CloseQueryHelper($state) {
        $this._queryHelperActive = $false
        # Internal modal only
        $this.RenderInterface()
    }

    [void] HandleQueryHelperInput([ConsoleKeyInfo]$key, $state) {
        if (-not $this._queryHelperActive) { return }
        switch ($key.Key) {
            'UpArrow'   { if ($this._queryHelperIndex -gt 0) { $this._queryHelperIndex-- }; $buf=$this._renderer.GetDrawBuffer(); $this.RenderDataArea($buf); $this.RenderCommandLine($null,$buf); $this.RenderStatus($buf); return }
            'DownArrow' { if ($this._queryHelperIndex -lt (@($this._queryHelperItems).Count - 1)) { $this._queryHelperIndex++ }; $buf=$this._renderer.GetDrawBuffer(); $this.RenderDataArea($buf); $this.RenderCommandLine($null,$buf); $this.RenderStatus($buf); return }
            'Escape'    { $this.CloseQueryHelper($state); return }
            'Enter'     {
                if (@($this._queryHelperItems).Count -eq 0) { $this.CloseQueryHelper($state); return }
                $item = $this._queryHelperItems[$this._queryHelperIndex]
                $tok = [string]$item.Token
                # Insert token at cursor
                $before = $state.CommandBuffer.Substring(0, [Math]::Min($state.CommandCursorPos, $state.CommandBuffer.Length))
                $after  = $state.CommandBuffer.Substring([Math]::Min($state.CommandCursorPos, $state.CommandBuffer.Length))
                # For '@' and '#' add directly; others append token
                $insert = $tok
                if ($tok -eq 'p') { $insert = 'p' } # user types number next
                $state.CommandBuffer = ($before + $insert + ' ' + $after).TrimEnd()
                $state.CommandCursorPos = [Math]::Min($state.CommandBuffer.Length, ($before + $insert + ' ').Length)
                $this.CloseQueryHelper($state)
                return
            }
        }
    }

    [void] RenderCommandLine($state = $null, [PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        if (-not $state) {
            $state = [PSCustomObject]@{ CommandBuffer = $this._ui.CommandBuffer; CommandCursorPos = $this._ui.CommandCursor }
        }

        $input = $this._regions.Command
        # Legacy debug removed
        if (-not $this.HasRegionProps($input)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $input = $this._regions.Command
                # Legacy debug removed
            } catch { }
        }
        $promptX = $input.X + 1
        $promptY = $input.Y

        # Clear input line
        $buffer.ClearRegion($input.X, $input.Y, $input.Width, 1)

        # Render prompt
        $buffer.SetText($promptX, $promptY, $this._promptText, 'green', 'black')

        # Render command buffer
        $commandX = $promptX + $this._promptText.Length
        $bufText = $state.CommandBuffer
        $curPos  = if ($null -ne $state.CommandCursorPos) { [int]$state.CommandCursorPos } elseif ($state.PSObject.Properties['CommandCursor']) { [int]$state.CommandCursor } else { 0 }
        if ($bufText) { $buffer.SetText($commandX, $promptY, $bufText, 'white', 'black') }

        # Set desired hardware cursor position; renderer will move it after flush
        $cursorX = $commandX + $curPos
        $this._renderer.SetDesiredCursor($cursorX, $promptY)
    }

    # Overloads to avoid ambiguous single-argument calls
    [void] RenderCommandLine() {
        $this.RenderCommandLine($null, $this._renderer.GetDrawBuffer())
    }

    [void] RenderCommandLine([PmcScreenBuffer]$buffer) {
        $this.RenderCommandLine($null, $buffer)
    }

    [void] RenderCommandLine([psobject]$state) {
        $this.RenderCommandLine($state, $this._renderer.GetDrawBuffer())
    }

    [void] RenderStatus([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

        $status = $this._regions.Status
        if (-not $this.HasRegionProps($status)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $status = $this._regions.Status
                # Legacy debug removed
            } catch { }
        }
        # Clear the entire status region to avoid bleed/artifacts
        $buffer.ClearRegion($status.X, $status.Y, $status.Width, $status.Height)

        $statusText = "Ready"
        $modeText = if ($this._ui) {
            if ($this._ui.Mode -eq [PmcUIMode]::Command) { 'CMD' }
            elseif ($this._ui.UIState -eq [PmcUIInteract]::Edit) { 'EDIT' }
            else { 'UI' }
        } else {
            'UNK'
        }

        # Frame counter (optional, lightweight)
        $rightText = "Frame: $($this._frameCount)"

        $leftText  = "[$modeText] $statusText"
        $buffer.SetText($status.X + 1, $status.Y, $leftText, 'cyan', $this._statusBg)
        $buffer.SetText([Math]::Max($status.X + $status.Width - $rightText.Length - 2, $status.X + 1), $status.Y, $rightText, 'yellow', $this._statusBg)
    }


    [void] ShowError([string]$message) {
        # Log error without relying on module debug
        $this.Log(1, ("Error: {0}" -f $message))
    }

    [void] Cleanup() {
        try {
            $this._renderer.ShowCursor()
            $this._renderer.Reset()
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Enhanced screen session ended"
        } catch {
            Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Cleanup error: $_"
        }
    }

    # Public interface
    [bool] IsActive() { return $this._active }
    [hashtable] GetPerformanceStats() {
        $runtime = ([datetime]::Now - $this._sessionStart).TotalSeconds
        $fps = if ($runtime -gt 0) { $this._frameCount / $runtime } else { 0 }

        return @{
            FrameCount = $this._frameCount
            Runtime = [Math]::Round($runtime, 2)
            FPS = [Math]::Round($fps, 1)
            LastRefresh = $this._lastRefresh
        }
    }
}

# Compatibility shim for old initializer and launcher (exported)
function Initialize-PmcScreen {
    param([string]$Title = "PMC — Project Management Console")
    # No-op in enhanced mode; kept for compatibility with existing initializer
    return $true
}

# Global instance
$Script:PmcEnhancedScreenManager = $null

function Start-PmcEnhancedSession {
    [CmdletBinding()]
    param(
        [switch]$NonBlocking  # Use experimental non-blocking mode
    )


    if ($Script:PmcEnhancedScreenManager -and $Script:PmcEnhancedScreenManager.IsActive()) {
        Write-Warning "Enhanced session already active"
        return
    }

    try {
        # Initialize components
        if (-not $Script:PmcEnhancedScreenManager) {
            $Script:PmcEnhancedScreenManager = [PmcEnhancedScreenManager]::new()

            # Set up integration with existing PMC systems
            $Script:PmcEnhancedScreenManager.CommandProcessor = {
                param([string]$command)
                try {
                    # Sanitize input using PMC security system
                    if (Get-Command Test-PmcInputSafety -ErrorAction SilentlyContinue) {
                        if (-not (Test-PmcInputSafety -Input $command -InputType 'command')) {
                            Write-PmcStyled -Style 'Error' -Text "Input rejected for security reasons"
                            return
                        }
                    }
                    if (Get-Command Invoke-PmcEnhancedCommand -ErrorAction SilentlyContinue) {
                        Invoke-PmcEnhancedCommand -Command $command
                    }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message ("Command execution error: {0}" -f $_)
                }
            }

            $Script:PmcEnhancedScreenManager.CompletionProvider = {
                param([string]$buffer, [int]$cursorPos)
                try {
                    $text = $buffer.Substring(0, [Math]::Min($cursorPos, $buffer.Length))
                } catch { $text = $buffer }
                $parts = $text.Trim().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                if ($parts.Count -eq 0) { return @('q task ') }
                # Basic query completions for 'q'
                if ($parts[0] -ieq 'q') {
                    if ($parts.Count -eq 1) { return @('q task ','q project ','q timelog ') }
                    $domain = $parts[1].ToLower()
                    if ($parts.Count -eq 2) { return @("q $domain @","q $domain #","q $domain p1","q $domain due:today ") }
                    # If last token starts with '@' suggest projects; '#' suggest tags
                    $last = $parts[-1]
                    if ($last.StartsWith('@')) {
                        try { $projs = Get-PmcProjectsData | ForEach-Object { $_.name } | Where-Object { $_ } | Select-Object -Unique | Sort-Object | Select-Object -First 20; return @($projs | ForEach-Object { "q $domain @$($_) " }) } catch {}
                    }
                    if ($last.StartsWith('#')) {
                        try {
                            $tags = @(); foreach ($t in (Get-PmcTasksData)) { if ($t.tags) { foreach ($x in $t.tags) { if ($x) { $tags += [string]$x } } } }
                            $tags = $tags | Select-Object -Unique | Sort-Object | Select-Object -First 20
                            return @($tags | ForEach-Object { "q $domain #$($_) " })
                        } catch {}
                    }
                    return @()
                }
                return @()
            }
        }

        # Single-path session
        $Script:PmcEnhancedScreenManager.StartModalSession()

    } catch {
        Write-Error "Failed to start enhanced session: $_"
        throw
    }
}

function Stop-PmcEnhancedSession {
    if ($Script:PmcEnhancedScreenManager) {
        $Script:PmcEnhancedScreenManager.StopSession()
    }
}

function Get-PmcEnhancedSessionStats {
    if ($Script:PmcEnhancedScreenManager) {
        return $Script:PmcEnhancedScreenManager.GetPerformanceStats()
    }
    return @{}
}

    hidden [void] Log([int]$level, [string]$message) {
        # Write to a temp debug file without relying on module debug implementation
        try { "[$([datetime]::Now.ToString('HH:mm:ss.fff'))] $message" | Out-File -FilePath "/tmp/pmc-debug.log" -Append -Encoding utf8 } catch {}
    }
Export-ModuleMember -Function Start-PmcEnhancedSession, Stop-PmcEnhancedSession, Get-PmcEnhancedSessionStats, Initialize-PmcScreen
