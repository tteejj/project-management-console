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
- ServiceContainer dependency injection

.EXAMPLE
# Example: Custom screen implementation with ServiceContainer
# class MyCustomScreen : PmcScreen {
#     MyCustomScreen([object]$container) : base("MyScreen", "My Screen Title", $container) {
#         $this.Header.SetBreadcrumb(@("Home", "My Screen"))
#     }
#
#     [void] LoadData() {
#         # Access services via container
#         $taskStore = $this.Container.Get('TaskStore')
#         # Load your data...
#     }
#
#     [string] RenderContent() {
#         # Render your content...
#     }
# }
#
# Example: Legacy constructor (backward compatible)
# class MyLegacyScreen : PmcScreen {
#     MyLegacyScreen() : base("MyScreen", "My Screen Title") {
#         # Works without container for backward compatibility
#     }
# }
#>
class PmcScreen {
    # === Core Properties ===
    [string]$ScreenKey = ""
    [string]$ScreenTitle = ""

    # === Service Container ===
    [object]$Container = $null

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

    # === Constructor (backward compatible - no container) ===
    PmcScreen([string]$key, [string]$title) {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen: Legacy constructor called (key=$key, title=$title)"
        }

        $this.ScreenKey = $key
        $this.ScreenTitle = $title
        $this.ContentWidgets = New-Object 'System.Collections.Generic.List[object]'

        # Create default widgets
        $this._CreateDefaultWidgets()
    }

    # === Constructor (with ServiceContainer) ===
    PmcScreen([string]$key, [string]$title, [object]$container) {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen: Constructor called with ServiceContainer (key=$key, title=$title, container=$($null -ne $container))"
        }

        $this.ScreenKey = $key
        $this.ScreenTitle = $title
        $this.Container = $container
        $this.ContentWidgets = New-Object 'System.Collections.Generic.List[object]'

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen: ServiceContainer stored (available=$($null -ne $this.Container))"
        }

        # Create default widgets
        $this._CreateDefaultWidgets()
    }

    hidden [void] _CreateDefaultWidgets() {
        # Menu bar - use shared MenuBar if available (populated by TaskListScreen)
        # CRITICAL: Check if variable exists AND is not null
        if ((Get-Variable -Name PmcSharedMenuBar -Scope Global -ErrorAction SilentlyContinue) -and $global:PmcSharedMenuBar) {
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
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [LIFECYCLE] PmcScreen.OnEnter() - Screen='$($this.ScreenKey)' entering"
        }
        $this.IsActive = $true
        $this.LoadData()

        if ($this.OnEnterHandler) {
            & $this.OnEnterHandler $this
        }
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [LIFECYCLE] PmcScreen.OnEnter() - Screen='$($this.ScreenKey)' entered successfully"
        }
    }

    <#
    .SYNOPSIS
    Called when screen becomes inactive

    .DESCRIPTION
    Override to perform cleanup when leaving screen
    #>
    [void] OnExit() {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [LIFECYCLE] PmcScreen.OnExit() - Screen='$($this.ScreenKey)' exiting"
        }
        $this.IsActive = $false

        if ($this.OnExitHandler) {
            & $this.OnExitHandler $this
        }
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [LIFECYCLE] PmcScreen.OnExit() - Screen='$($this.ScreenKey)' exited successfully"
        }
    }

    <#
    .SYNOPSIS
    Load data for this screen

    .DESCRIPTION
    Override to load screen-specific data
    #>
    [void] LoadData() {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [LIFECYCLE] PmcScreen.LoadData() - Screen='$($this.ScreenKey)' (base class - no-op)"
        }
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
    # Initialize with render engine only (backward compatible)
    [void] Initialize([object]$renderEngine) {
        $this.Initialize($renderEngine, $null)
    }

    # Initialize with render engine and container (new pattern)
    [void] Initialize([object]$renderEngine, [object]$container) {
        $this.RenderEngine = $renderEngine

        # Store container if provided
        if ($container) {
            $this.Container = $container
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.Initialize: Container set for screen '$($this.ScreenKey)'"
            }
        }

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

        # NOTE: Footer rendering removed from here - now handled by RenderToEngine() at Layer 55
        # This prevents double-rendering when RenderToEngine() calls RenderContent() then also renders Footer

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
        # Z-INDEX LAYER RENDERING
        # All rendering now uses explicit layers for proper z-ordering.
        # Higher z-index values render on top of lower values.

        # Layer 50: Header
        $engine.BeginLayer([ZIndex]::Header)
        if ($this.Header) {
            try {
                $output = $this.Header.Render()
                if ($output) {
                    $this._ParseAnsiAndWrite($engine, $output)
                }
            } catch {
                $this._HandleWidgetRenderError("Header", $_, $engine, 1)
            }
        }

        # Layer 10: Content (main screen content)
        $engine.BeginLayer([ZIndex]::Content)
        # Render content - wrap in try-catch to prevent rendering crashes
        try {
            # PERFORMANCE: Use direct engine rendering if available (avoids ANSI parsing)
            if ($this.PSObject.Methods['RenderContentToEngine'] -and
                $this.GetType().GetMethod('RenderContentToEngine').DeclaringType.Name -ne 'PmcScreen') {
                # Subclass overrides RenderContentToEngine - use direct path (no ANSI parsing)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: Using RenderContentToEngine path"
                }
                $this.RenderContentToEngine($engine)
            } else {
                # Fallback: Use ANSI string rendering (legacy path)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: Using RenderContent path (fallback)"
                }
                $contentOutput = $this.RenderContent()
                if ($global:PmcTuiLogFile) {
                    $outputLen = if ($contentOutput) { $contentOutput.Length } else { "NULL" }
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: RenderContent returned length=$outputLen"
                }
                if ($contentOutput) {
                    $this._ParseAnsiAndWrite($engine, $contentOutput)
                }
            }
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] PmcScreen.RenderToEngine: Exception in content rendering: $_"
            }
            $this._HandleWidgetRenderError("RenderContent", $_, $engine, 5)
        }

        # Layer 20: Panel (content widgets like FilterPanel, DatePicker, etc.)
        $engine.BeginLayer([ZIndex]::Panel)
        # Render content widgets - each with error boundary
        $widgetRow = 10  # Start position for widget error messages
        foreach ($widget in $this.ContentWidgets) {
            # Define widgetName outside try block for catch scope
            $widgetName = if ($widget.Name) { $widget.Name } else { $widget.GetType().Name }
            try {
                $output = $widget.Render()
                # PERFORMANCE: If widget returns empty string, it used direct engine rendering
                # No need to parse ANSI - widget already called WriteAt() directly
                if ($output -and $output.Length -gt 0) {
                    $this._ParseAnsiAndWrite($engine, $output)
                }
                # else: widget used fast path (OnRenderToEngine), already rendered
            } catch {
                $this._HandleWidgetRenderError($widgetName, $_, $engine, $widgetRow)
                $widgetRow += 2  # Space out error messages
            }
        }

        # Layer 55: Footer
        $engine.BeginLayer([ZIndex]::Footer)
        if ($this.Footer) {
            try {
                $output = $this.Footer.Render()
                if ($output) {
                    $this._ParseAnsiAndWrite($engine, $output)
                }
            } catch {
                # Footer errors shown at bottom of screen
                $footerRow = [Math]::Max(20, $this.TermHeight - 4)
                $this._HandleWidgetRenderError("Footer", $_, $engine, $footerRow)
            }
        }

        # Layer 65: StatusBar
        $engine.BeginLayer([ZIndex]::StatusBar)
        if ($this.StatusBar) {
            try {
                $output = $this.StatusBar.Render()
                if ($output) {
                    $this._ParseAnsiAndWrite($engine, $output)
                }
            } catch {
                # StatusBar errors shown at very bottom
                $statusRow = [Math]::Max(22, $this.TermHeight - 2)
                $this._HandleWidgetRenderError("StatusBar", $_, $engine, $statusRow)
            }
        }

        # Layer 100: Dropdown (MenuBar with dropdowns)
        # CRITICAL: Render MenuBar LAST with highest z-index for proper z-ordering
        # Dropdowns must render on top of all other content
        $engine.BeginLayer([ZIndex]::Dropdown)
        if ($this.MenuBar) {
            try {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.RenderToEngine: Calling MenuBar.Render() (LAST for z-order)"
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
            } catch {
                $this._HandleWidgetRenderError("MenuBar", $_, $engine, 0)
            }
        }
    }

    <#
    .SYNOPSIS
    Handle widget render errors gracefully

    .DESCRIPTION
    Shows error inline without crashing the app, logs the error,
    and allows the rest of the UI to continue rendering.
    #>
    hidden [void] _HandleWidgetRenderError([string]$widgetName, [object]$error, [object]$engine, [int]$row) {
        $errorMsg = "$widgetName render failed: $($error.Exception.Message)"
        $stackTrace = $error.ScriptStackTrace

        # Log error details
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] Widget render error: $errorMsg"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] Stack: $stackTrace"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] TargetObject: $($error.TargetObject)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] InvocationInfo: $($error.InvocationInfo.Line)"
        }

        # Show error inline where widget would have rendered
        try {
            $engine.WriteAt(2, $row, "`e[1;31m[!] $widgetName Error: $($error.Exception.Message -replace "`n", " ")`e[0m")

            # If status bar is available, also show error there
            if ($this.StatusBar) {
                $this.SetStatusMessage("$widgetName render failed - see logs", "error")
            }
        } catch {
            # If we can't even write the error, just log it
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [FATAL] Could not write error to screen: $_"
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

            # Debug: dump full content for first two position writes
            if ($i -lt 2 -and ($x -eq 9 -or $x -eq 51) -and $y -eq 10) {
                $debugFile = "/tmp/pmc-layer-parse-debug.log"
                $timestamp = Get-Date -Format 'HH:mm:ss.fff'
                Add-Content -Path $debugFile -Value "=== $timestamp WriteAt($x,$y) content_length=$($content.Length) ==="
                Add-Content -Path $debugFile -Value "Raw: $($content -replace "`e", '<ESC>')"
                Add-Content -Path $debugFile -Value "Bytes: $([System.Text.Encoding]::UTF8.GetBytes($content) | ForEach-Object { $_.ToString('X2') } | Join-String -Separator ' ')"
                Add-Content -Path $debugFile -Value "==="
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

    # === Service Container Methods ===

    <#
    .SYNOPSIS
    Get a service from the container

    .PARAMETER serviceName
    Name of the service to retrieve

    .OUTPUTS
    Service instance or $null if container not available or service not found

    .EXAMPLE
    $taskStore = $this.GetService('TaskStore')
    #>
    [object] GetService([string]$serviceName) {
        if ($null -eq $this.Container) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.GetService: Container not available (service=$serviceName)"
            }
            return $null
        }

        try {
            $service = $this.Container.Get($serviceName)
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.GetService: Retrieved service (name=$serviceName, found=$($null -ne $service))"
            }
            return $service
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.GetService: Error retrieving service (name=$serviceName, error=$($_.Exception.Message))"
            }
            return $null
        }
    }

    <#
    .SYNOPSIS
    Check if a service is available in the container

    .PARAMETER serviceName
    Name of the service to check

    .OUTPUTS
    Boolean indicating if service is available

    .EXAMPLE
    if ($this.HasService('TaskStore')) { ... }
    #>
    [bool] HasService([string]$serviceName) {
        if ($null -eq $this.Container) {
            return $false
        }

        try {
            return $this.Container.Has($serviceName)
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcScreen.HasService: Error checking service (name=$serviceName, error=$($_.Exception.Message))"
            }
            return $false
        }
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
    [void] ShowSuccess([string]$message) {
        $this.ShowSuccess($message, $false)
    }

    [void] ShowSuccess([string]$message, [bool]$autoSaved) {
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
    [void] ShowReady() {
        $this.ShowReady("")
    }

    [void] ShowReady([string]$itemType) {
        $message = if ([string]::IsNullOrWhiteSpace($itemType)) {
            "Ready"
        } else {
            "$itemType ready"
        }
        $this.ShowStatus($message)
    }
}

# Classes exported automatically in PowerShell 5.1+
