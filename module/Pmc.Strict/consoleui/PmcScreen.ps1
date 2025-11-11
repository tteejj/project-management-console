# PmcScreen - Base class for all PMC screens
# Provides standard screen lifecycle, layout, and widget management

using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# NOTE: All dependencies are loaded by Start-PmcTUI.ps1
# Do not load them again here to avoid circular dependencies and duplicate loading

<#
.SYNOPSIS
Base class for all PMC screens

.DESCRIPTION
PmcScreen provides:
- Standard widget composition (MenuBar, Header, Footer, StatusBar, Content)
- Layout management integration
- Screen lifecycle (OnEnter, OnExit, LoadData)
- Input handling delegation
- Rendering orchestration

.EXAMPLE
# Example: Custom screen implementation
# class MyCustomScreen : PmcScreen {
#     MyCustomScreen() : base("MyScreen", "My Screen Title") {
#         $this.Header.SetBreadcrumb(@("Home", "My Screen"))
#     }
#
#     [void] LoadData() {
#         # Load your data...
#     }
#
#     [string] RenderContent() {
#         # Render your content...
#     }
# }
#>
class PmcScreen {
    # === Core Properties ===
    [string]$ScreenKey = ""
    [string]$ScreenTitle = ""

    # === Standard Widgets ===
    [object]$MenuBar = $null
    [object]$Header = $null
    [object]$Footer = $null
    [object]$StatusBar = $null
    [object]$ContentWidgets

    # === Layout ===
    [object]$LayoutManager = $null
    [int]$TermWidth = 80
    [int]$TermHeight = 24

    # === State ===
    [bool]$IsActive = $false
    [object]$RenderEngine = $null
    [bool]$NeedsClear = $false  # Request full screen clear before next render

    # H-UI-4: Message queue for persistent status messages
    [System.Collections.Queue]$_messageQueue = [System.Collections.Queue]::new()
    [DateTime]$_lastMessageTime = [DateTime]::MinValue

    # === Event Handlers ===
    [scriptblock]$OnEnterHandler = $null
    [scriptblock]$OnExitHandler = $null

    # === Constructor ===
    PmcScreen([string]$key, [string]$title) {
        $this.ScreenKey = $key
        $this.ScreenTitle = $title
        $this.ContentWidgets = New-Object 'System.Collections.Generic.List[object]'

        # Create default widgets
        $this._CreateDefaultWidgets()
    }

    hidden [void] _CreateDefaultWidgets() {
        # Menu bar - use shared MenuBar if available (populated by TaskListScreen)
        if (Get-Variable -Name PmcSharedMenuBar -Scope Global -ErrorAction SilentlyContinue) {
            $this.MenuBar = $global:PmcSharedMenuBar
        } else {
            # Create default empty MenuBar (will be populated by TaskListScreen)
            $this.MenuBar = New-Object PmcMenuBar
            $this.MenuBar.AddMenu("Tasks", 'T', @())
            $this.MenuBar.AddMenu("Projects", 'P', @())
            $this.MenuBar.AddMenu("Time", 'M', @())
            $this.MenuBar.AddMenu("Tools", 'L', @())
            $this.MenuBar.AddMenu("Options", 'O', @())
            $this.MenuBar.AddMenu("Help", '?', @())
        }

        # Header
        $this.Header = New-Object PmcHeader -ArgumentList $this.ScreenTitle

        # Footer with standard shortcuts
        $this.Footer = New-Object PmcFooter
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("F10", "Menu")

        # Status bar
        $this.StatusBar = New-Object PmcStatusBar
        $this.StatusBar.SetLeftText("Ready")
    }

    # === Lifecycle Methods ===

    <#
    .SYNOPSIS
    Called when screen becomes active

    .DESCRIPTION
    Override to perform initialization when screen is displayed
    #>
    [void] OnEnter() {
        $this.IsActive = $true
        $this.LoadData()

        if ($this.OnEnterHandler) {
            & $this.OnEnterHandler $this
        }
    }

    <#
    .SYNOPSIS
    Called when screen becomes inactive

    .DESCRIPTION
    Override to perform cleanup when leaving screen
    #>
    [void] OnExit() {
        $this.IsActive = $false

        if ($this.OnExitHandler) {
            & $this.OnExitHandler $this
        }
    }

    <#
    .SYNOPSIS
    Load data for this screen

    .DESCRIPTION
    Override to load screen-specific data
    #>
    [void] LoadData() {
        # Override in subclass
    }

    # === Layout Management ===

    <#
    .SYNOPSIS
    Apply layout to all widgets

    .PARAMETER layoutManager
    Layout manager instance

    .PARAMETER termWidth
    Terminal width

    .PARAMETER termHeight
    Terminal height
    #>
    [void] ApplyLayout([object]$layoutManager, [int]$termWidth, [int]$termHeight) {
        $this.LayoutManager = $layoutManager
        $this.TermWidth = $termWidth
        $this.TermHeight = $termHeight

        # Apply layout to standard widgets
        if ($this.MenuBar) {
            $rect = $layoutManager.GetRegion('MenuBar', $termWidth, $termHeight)
            $this.MenuBar.SetPosition($rect.X, $rect.Y)
            $this.MenuBar.SetSize($rect.Width, $rect.Height)
        }

        if ($this.Header) {
            $rect = $layoutManager.GetRegion('Header', $termWidth, $termHeight)
            $this.Header.SetPosition($rect.X, $rect.Y)
            $this.Header.SetSize($rect.Width, $rect.Height)
        }

        if ($this.Footer) {
            $rect = $layoutManager.GetRegion('Footer', $termWidth, $termHeight)
            $this.Footer.SetPosition($rect.X, $rect.Y)
            $this.Footer.SetSize($rect.Width, $rect.Height)
        }

        if ($this.StatusBar) {
            $rect = $layoutManager.GetRegion('StatusBar', $termWidth, $termHeight)
            $this.StatusBar.SetPosition($rect.X, $rect.Y)
            $this.StatusBar.SetSize($rect.Width, $rect.Height)
        }

        # Apply layout to content widgets
        $this.ApplyContentLayout($layoutManager, $termWidth, $termHeight)
    }

    <#
    .SYNOPSIS
    Apply layout to content area widgets

    .DESCRIPTION
    Override to position custom content widgets
    #>
    [void] ApplyContentLayout([PmcLayoutManager]$layoutManager, [int]$termWidth, [int]$termHeight) {
        # Override in subclass to position content widgets
    }

    <#
    .SYNOPSIS
    Handle terminal resize

    .PARAMETER newWidth
    New terminal width

    .PARAMETER newHeight
    New terminal height
    #>
    [void] OnTerminalResize([int]$newWidth, [int]$newHeight) {
        if ($this.LayoutManager) {
            $this.ApplyLayout($this.LayoutManager, $newWidth, $newHeight)
        }
    }

    # === Rendering ===

    <#
    .SYNOPSIS
    Initialize widgets with render engine

    .PARAMETER renderEngine
    SpeedTUI render engine instance
    #>
    [void] Initialize([object]$renderEngine) {
        $this.RenderEngine = $renderEngine

        # Initialize standard widgets
        if ($this.MenuBar) {
            $this.MenuBar.Initialize($renderEngine)
        }
        if ($this.Header) {
            $this.Header.Initialize($renderEngine)
        }
        if ($this.Footer) {
            $this.Footer.Initialize($renderEngine)
        }
        if ($this.StatusBar) {
            $this.StatusBar.Initialize($renderEngine)
        }

        # Initialize content widgets
        foreach ($widget in $this.ContentWidgets) {
            $widget.Initialize($renderEngine)
        }
    }

    <#
    .SYNOPSIS
    Render the entire screen

    .OUTPUTS
    String containing ANSI-formatted screen output
    #>
    [string] Render() {
        $sb = [System.Text.StringBuilder]::new(4096)

        # DEBUG
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: Starting (MenuBar=$($null -ne $this.MenuBar), Header=$($null -ne $this.Header))"
        }

        # Render MenuBar (if present)
        if ($this.MenuBar) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: Rendering MenuBar"
            }
            $output = $this.MenuBar.Render()
            if ($output) {
                $sb.Append($output)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: MenuBar output length=$($output.Length)"
                }
            } else {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: MenuBar returned null/empty"
                }
            }
        }

        # Render Header
        if ($this.Header) {
            $output = $this.Header.Render()
            if ($output) {
                $sb.Append($output)
            }
        }

        # Render content (override in subclass) - wrap in try-catch to prevent rendering crashes
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: Calling RenderContent()"
        }
        try {
            $contentOutput = $this.RenderContent()
            if ($contentOutput) {
                $sb.Append($contentOutput)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: Content output length=$($contentOutput.Length)"
                }
            } else {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: RenderContent() returned null/empty"
                }
            }
        } catch {
            $errorMsg = "RenderContent() crashed: $($_.Exception.Message)"
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Render: $errorMsg"
            }
            # Append error message to output so user sees something instead of blank screen
            $sb.Append("`e[1;31mERROR: $errorMsg`e[0m`n")
        }

        # Render content widgets
        foreach ($widget in $this.ContentWidgets) {
            $output = $widget.Render()
            if ($output) {
                $sb.Append($output)
            }
        }

        # Render Footer
        if ($this.Footer) {
            $output = $this.Footer.Render()
            if ($output) {
                $sb.Append($output)
            }
        }

        # H-UI-4: Check if message expired (3 seconds) and clear status
        if ($this.StatusBar -and ([DateTime]::Now - $this._lastMessageTime).TotalSeconds -gt 3) {
            $this.StatusBar.SetLeftText("")
        }

        # Render StatusBar
        if ($this.StatusBar) {
            $output = $this.StatusBar.Render()
            if ($output) {
                $sb.Append($output)
            }
        }

        $result = $sb.ToString()
        return $result
    }

    <#
    .SYNOPSIS
    Render content area

    .DESCRIPTION
    Override in subclass to render screen-specific content

    .OUTPUTS
    String containing ANSI-formatted content
    #>
    [string] RenderContent() {
        # Override in subclass
        return ""
    }

    <#
    .SYNOPSIS
    Render directly to engine

    .PARAMETER engine
    RenderEngine instance to write to

    .DESCRIPTION
    Renders screen by calling widget Render() methods and writing ANSI output to engine.
    Widgets use SpeedTUI's Render() → OnRender() pattern which returns ANSI strings.
    We parse those ANSI strings and write them to the engine using WriteAt().
    #>
    [void] RenderToEngine([object]$engine) {
        # Render MenuBar (if present)
        if ($this.MenuBar) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: Calling MenuBar.Render()"
            }
            $output = $this.MenuBar.Render()
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: MenuBar.Render() returned length=$($output.Length)"
            }
            if ($output) {
                $this._ParseAnsiAndWrite($engine, $output)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: MenuBar ANSI parsed and written to engine"
                }
            }
        }

        # Render Header
        if ($this.Header) {
            $output = $this.Header.Render()
            if ($output) {
                $this._ParseAnsiAndWrite($engine, $output)
            }
        }

        # Render content - wrap in try-catch to prevent rendering crashes
        try {
            $contentOutput = $this.RenderContent()
            if ($contentOutput) {
                $this._ParseAnsiAndWrite($engine, $contentOutput)
            }
        } catch {
            $errorMsg = "RenderContent() crashed in RenderToEngine: $($_.Exception.Message)"
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: $errorMsg"
            }
            # Write error message to engine so user sees something
            $engine.WriteAt(0, 5, "`e[1;31mERROR: $errorMsg`e[0m")
        }

        # Render content widgets
        foreach ($widget in $this.ContentWidgets) {
            $output = $widget.Render()
            if ($output) {
                $this._ParseAnsiAndWrite($engine, $output)
            }
        }

        # Render Footer
        if ($this.Footer) {
            $output = $this.Footer.Render()
            if ($output) {
                $this._ParseAnsiAndWrite($engine, $output)
            }
        }

        # Render StatusBar
        if ($this.StatusBar) {
            $output = $this.StatusBar.Render()
            if ($output) {
                $this._ParseAnsiAndWrite($engine, $output)
            }
        }
    }

    hidden [void] _ParseAnsiAndWrite([object]$engine, [string]$ansiOutput) {
        # Parse ANSI cursor positioning and write to engine
        # ANSI format: ESC[row;colH (1-based)
        # WriteAt format: WriteAt(x, y) where x=col-1, y=row-1 (0-based)

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _ParseAnsiAndWrite: Input length=$($ansiOutput.Length)"
        }

        $pattern = "`e\[(\d+);(\d+)H"
        $matches = [regex]::Matches($ansiOutput, $pattern)

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _ParseAnsiAndWrite: Found $($matches.Count) position markers"
        }

        if ($matches.Count -eq 0) {
            # No positioning - write at 0,0
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _ParseAnsiAndWrite: No position markers, writing entire output at (0,0)"
            }
            if ($ansiOutput) {
                $engine.WriteAt(0, 0, $ansiOutput)
            }
            return
        }

        for ($i = 0; $i -lt $matches.Count; $i++) {
            $match = $matches[$i]
            $row = [int]$match.Groups[1].Value
            $col = [int]$match.Groups[2].Value

            # Convert to 0-based coordinates
            $x = $col - 1
            $y = $row - 1

            # Get content after this position marker until next position marker
            $startIndex = $match.Index + $match.Length

            if ($i + 1 -lt $matches.Count) {
                # There's another position marker - content goes until there
                $endIndex = $matches[$i + 1].Index
            } else {
                # Last marker - content goes to end
                $endIndex = $ansiOutput.Length
            }

            $content = $ansiOutput.Substring($startIndex, $endIndex - $startIndex)

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _ParseAnsiAndWrite: Match $i - pos($x,$y) content_length=$($content.Length)"
            }

            if ($content) {
                $engine.WriteAt($x, $y, $content)
            }
        }
    }

    <#
    .SYNOPSIS
    Render content area directly to engine

    .PARAMETER engine
    RenderEngine instance

    .DESCRIPTION
    Override in subclass to render screen-specific content directly
    to the engine without ANSI string building.
    #>
    [void] RenderContentToEngine([object]$engine) {
        # Override in subclass for direct engine rendering
        # This is the new high-performance path
    }

    # === Input Handling ===

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    Console key info

    .OUTPUTS
    Boolean indicating if input was handled
    #>
    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # MenuBar gets priority (if active)
        if ($this.MenuBar -and $this.MenuBar.IsActive) {
            if ($this.MenuBar.HandleKeyPress($keyInfo)) {
                return $true
            }
        }

        # F10 activates menu bar
        if ($keyInfo.Key -eq 'F10' -and $this.MenuBar) {
            $this.MenuBar.Activate()
            return $true
        }

        # Pass to content widgets FIRST (in reverse order for z-index)
        # CRITICAL FIX #5: Check widgets before menu Alt-keys to prevent conflicts with focused editors
        for ($i = $this.ContentWidgets.Count - 1; $i -ge 0; $i--) {
            $widget = $this.ContentWidgets[$i]
            if ($widget.PSObject.Methods['HandleKeyPress']) {
                if ($widget.HandleKeyPress($keyInfo)) {
                    return $true
                }
            }
        }

        # Alt+letter hotkeys activate menu bar (only if no widget handled it)
        # CRITICAL FIX #5: Moved AFTER widget handling to prevent conflicts
        if ($this.MenuBar -and ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt)) {
            if ($this.MenuBar.HandleKeyPress($keyInfo)) {
                return $true
            }
        }

        # Pass to subclass
        return $this.HandleInput($keyInfo)
    }

    <#
    .SYNOPSIS
    Handle screen-specific input

    .DESCRIPTION
    Override in subclass to handle custom input

    .PARAMETER keyInfo
    Console key info

    .OUTPUTS
    Boolean indicating if input was handled
    #>
    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Override in subclass
        return $false
    }

    # === Widget Management ===

    <#
    .SYNOPSIS
    Add a widget to the content area

    .PARAMETER widget
    Widget to add
    #>
    [void] AddContentWidget([PmcWidget]$widget) {
        $this.ContentWidgets.Add($widget)

        # Initialize if render engine available
        if ($this.RenderEngine) {
            $widget.Initialize($this.RenderEngine)
        }
    }

    <#
    .SYNOPSIS
    Remove a widget from the content area

    .PARAMETER widget
    Widget to remove
    #>
    [void] RemoveContentWidget([PmcWidget]$widget) {
        $this.ContentWidgets.Remove($widget)
    }

    # === Utility Methods ===

    <#
    .SYNOPSIS
    Show a message in the status bar

    .PARAMETER message
    Message to display
    #>
    [void] ShowStatus([string]$message) {
        if ($this.StatusBar) {
            # H-UI-4: Queue message with timestamp for persistence
            $this._messageQueue.Enqueue(@{ Message=$message; Type='info'; Time=[DateTime]::Now })
            $this._lastMessageTime = [DateTime]::Now
            $this.StatusBar.SetLeftText($message)
        }
    }

    <#
    .SYNOPSIS
    Show an error in the status bar

    .PARAMETER message
    Error message
    #>
    [void] ShowError([string]$message) {
        if ($this.StatusBar) {
            $this.StatusBar.ShowError($message)
        }
    }

    <#
    .SYNOPSIS
    Show a success message in the status bar

    .PARAMETER message
    Success message

    .PARAMETER autoSaved
    L-POL-6: If true, append "Saved." to indicate auto-save occurred
    #>
    [void] ShowSuccess([string]$message, [bool]$autoSaved = $false) {
        if ($this.StatusBar) {
            # L-POL-6: Append "Saved." indicator when auto-save is active
            $displayMessage = if ($autoSaved) {
                "$message Saved."
            } else {
                $message
            }
            $this.StatusBar.ShowSuccess($displayMessage)
        }
    }

    <#
    .SYNOPSIS
    L-POL-3: Show loading message with consistent format

    .PARAMETER itemType
    Type of items being loaded (e.g., "tasks", "projects", "notes")
    #>
    [void] ShowLoading([string]$itemType) {
        $this.ShowStatus("Loading $itemType...")
    }

    <#
    .SYNOPSIS
    L-POL-3: Show loaded message with count

    .PARAMETER itemType
    Type of items loaded (e.g., "tasks", "projects", "notes")

    .PARAMETER count
    Number of items loaded
    #>
    [void] ShowLoaded([string]$itemType, [int]$count) {
        $this.ShowStatus("Loaded $count $itemType")
    }

    <#
    .SYNOPSIS
    L-POL-3: Show ready message after loading complete

    .PARAMETER itemType
    Optional type of items ready (defaults to "Ready")
    #>
    [void] ShowReady([string]$itemType = "") {
        $message = if ([string]::IsNullOrWhiteSpace($itemType)) {
            "Ready"
        } else {
            "$itemType ready"
        }
        $this.ShowStatus($message)
    }
}

# Classes exported automatically in PowerShell 5.1+
