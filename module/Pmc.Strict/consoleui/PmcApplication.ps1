# PmcApplication - Main application wrapper integrating PMC widgets with SpeedTUI
# Handles rendering engine, event loop, and screen management

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

# NOTE: SpeedTUI, widgets, layout, and theme are loaded by Start-PmcTUI.ps1
# Do not load them again here to avoid circular dependencies and duplicate loading

<#
.SYNOPSIS
Main application class for PMC TUI

.DESCRIPTION
PmcApplication manages:
- SpeedTUI rendering engine (OptimizedRenderEngine)
- Screen stack and navigation
- Event loop and input handling
- Layout management
- Theme management

.EXAMPLE
$container = [ServiceContainer]::new()
$app = [PmcApplication]::new($container)
$app.PushScreen($taskScreen)
$app.Run()
#>
class PmcApplication {
    # === Core Components ===
    [object]$RenderEngine
    [object]$LayoutManager
    [object]$ThemeManager
    [object]$Container        # ServiceContainer for dependency injection

    # === Screen Management ===
    [object]$ScreenStack      # Stack of PmcScreen objects
    [object]$CurrentScreen = $null   # Currently active screen

    # === Terminal State ===
    [int]$TermWidth = 80
    [int]$TermHeight = 24
    [bool]$Running = $false

    # === Rendering State ===
    [bool]$IsDirty = $true  # Dirty flag - true when redraw needed

    # === Event Handlers ===
    [scriptblock]$OnTerminalResize = $null
    [scriptblock]$OnError = $null

    # === Constructor ===
    PmcApplication([object]$container) {
        # Store container for passing to screens
        $this.Container = $container
        # Initialize render engine (OptimizedRenderEngine with cell buffering)
        try {
            $this.RenderEngine = New-Object OptimizedRenderEngine
            if ($null -eq $this.RenderEngine) {
                throw "Failed to create OptimizedRenderEngine instance"
            }
            $this.RenderEngine.Initialize()
        } catch {
            Write-Host "FATAL: Failed to initialize RenderEngine: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }

        # Initialize layout manager
        $this.LayoutManager = New-Object PmcLayoutManager

        # Initialize theme manager
        $this.ThemeManager = $container.Resolve('ThemeManager')

        # Initialize screen stack
        $this.ScreenStack = New-Object "System.Collections.Generic.Stack[object]"

        # Get terminal size
        $this._UpdateTerminalSize()
    }

    # === Screen Management ===

    <#
    .SYNOPSIS
    Push a screen onto the stack and make it active

    .PARAMETER screen
    Screen object to push (should have Render() and HandleInput() methods)
    #>
    [void] PushScreen([object]$screen) {
        # Deactivate current screen
        if ($this.CurrentScreen) {
            if ($this.CurrentScreen.PSObject.Methods['OnExit']) {
                $this.CurrentScreen.OnExit()
            }
        }

        # Clear screen to prevent old content from showing through
        [Console]::Write("`e[2J")

        # Push new screen
        $this.ScreenStack.Push($screen)
        $this.CurrentScreen = $screen

        # Initialize screen with render engine and container
        if ($screen.PSObject.Methods['Initialize']) {
            $screen.Initialize($this.RenderEngine, $this.Container)
        }

        # Apply layout if screen has widgets
        if ($screen.PSObject.Methods['ApplyLayout']) {
            $screen.ApplyLayout($this.LayoutManager, $this.TermWidth, $this.TermHeight)
        }

        # Activate screen
        if ($screen.PSObject.Methods['OnEnter']) {
            $screen.OnEnter()
        }

        # Mark dirty for render
        $this.IsDirty = $true
    }

    <#
    .SYNOPSIS
    Pop current screen and return to previous

    .OUTPUTS
    The popped screen object
    #>
    [object] PopScreen() {
        if ($this.ScreenStack.Count -eq 0) {
            return $null
        }

        # Exit current screen
        $poppedScreen = $this.ScreenStack.Pop()
        if ($poppedScreen.PSObject.Methods['OnExit']) {
            $poppedScreen.OnExit()
        }

        # Clear screen to prevent old content from showing through
        [Console]::Write("`e[2J")

        # Restore previous screen
        if ($this.ScreenStack.Count -gt 0) {
            $this.CurrentScreen = $this.ScreenStack.Peek()

            # Re-enter previous screen
            if ($this.CurrentScreen.PSObject.Methods['OnEnter']) {
                $this.CurrentScreen.OnEnter()
            }

            # Mark dirty for render
            $this.IsDirty = $true
        } else {
            $this.CurrentScreen = $null
        }

        return $poppedScreen
    }

    <#
    .SYNOPSIS
    Clear screen stack and set a new root screen

    .PARAMETER screen
    New root screen
    #>
    [void] SetRootScreen([object]$screen) {
        # Clear stack
        while ($this.ScreenStack.Count -gt 0) {
            $this.PopScreen()
        }

        # Push new root
        $this.PushScreen($screen)
    }

    # === Rendering ===

    hidden [void] _RenderCurrentScreen() {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Starting (CurrentScreen=$($null -ne $this.CurrentScreen))"
        }

        if (-not $this.CurrentScreen) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: CurrentScreen is null, returning"
            }
            return
        }

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: CurrentScreen exists, entering try block"
        }

        try {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Inside try block, checking NeedsClear"
            }

            # Check if screen requests full clear
            if ($this.CurrentScreen.NeedsClear) {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: NeedsClear=true, calling RequestClear"
                }
                $this.RenderEngine.RequestClear()
                $this.CurrentScreen.NeedsClear = $false
            }

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: About to call BeginFrame"
            }

            # USE SPEEDTUI PROPERLY - BeginFrame/WriteAt/EndFrame
            $this.RenderEngine.BeginFrame()

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: BeginFrame completed, checking for RenderToEngine method"
            }

            # Get screen output (ANSI strings with position info)
            if ($this.CurrentScreen.PSObject.Methods['RenderToEngine']) {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Has RenderToEngine, calling it"
                }
                # New method: screen writes directly to engine
                $this.CurrentScreen.RenderToEngine($this.RenderEngine)
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: RenderToEngine completed"
                }
            } else {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: No RenderToEngine, calling Render()"
                }
                # Fallback: screen returns ANSI string, we parse and WriteAt
                $output = $this.CurrentScreen.Render()
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Render() completed, output length=$($output.Length)"
                }
                if ($output) {
                    # Parse ANSI positioning and write to engine
                    $this._WriteAnsiToEngine($output)
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: _WriteAnsiToEngine completed"
                    }
                }
            }

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: About to call EndFrame"
            }

            # EndFrame does differential rendering
            $this.RenderEngine.EndFrame()

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: EndFrame completed, clearing dirty flag"
            }

            # Clear dirty flag after successful render
            $this.IsDirty = $false

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Render cycle complete"
            }

        } catch {
            # Render error - log if Write-PmcTuiLog available
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: EXCEPTION CAUGHT - $_"
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Exception at: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _RenderCurrentScreen: Exception line: $($_.InvocationInfo.Line)"
            }
            if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                Write-PmcTuiLog "Render error: $_" "ERROR"
                Write-PmcTuiLog "Error at: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" "ERROR"
                Write-PmcTuiLog "Error line: $($_.InvocationInfo.Line)" "ERROR"
            }
            if ($this.OnError) {
                & $this.OnError $_
            }
        }
    }

    hidden [void] _WriteAnsiToEngine([string]$ansiOutput) {
        # Parse ANSI cursor positioning and write to engine
        # ANSI format: ESC[row;colH (1-based)
        # WriteAt format: WriteAt(x, y) where x=col-1, y=row-1 (0-based)
        $pattern = "`e\[(\d+);(\d+)H"
        $matches = [regex]::Matches($ansiOutput, $pattern)

        if ($matches.Count -eq 0) {
            # No positioning - write at 0,0
            if ($ansiOutput) {
                $this.RenderEngine.WriteAt(0, 0, $ansiOutput)
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

            if ($content) {
                $this.RenderEngine.WriteAt($x, $y, $content)
            }
        }
    }

    # === Event Loop ===

    <#
    .SYNOPSIS
    Start the application event loop

    .DESCRIPTION
    Runs until Stop() is called or screen stack is empty
    #>
    [void] Run() {
        $this.Running = $true

        # Hide cursor
        [Console]::CursorVisible = $false

        # Track iterations for terminal size check optimization
        $iteration = 0

        try {
            # Event loop - render only when dirty
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication.Run: Entering event loop (IsDirty=$($this.IsDirty))"
            }

            while ($this.Running -and $this.ScreenStack.Count -gt 0) {
                # Check for terminal resize every 20th iteration (not every loop)
                if ($iteration % 20 -eq 0) {
                    $currentWidth = [Console]::WindowWidth
                    $currentHeight = [Console]::WindowHeight

                    if ($currentWidth -ne $this.TermWidth -or $currentHeight -ne $this.TermHeight) {
                        $this._HandleTerminalResize($currentWidth, $currentHeight)
                    }
                }
                $iteration++

                # Check for input
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)

                    # Global keys - Ctrl+Q to exit
                    if ($key.Modifiers -eq [ConsoleModifiers]::Control -and $key.Key -eq 'Q') {
                        $this.Stop()
                        continue
                    }

                    # Pass to current screen (screen handles its own menu)
                    if ($this.CurrentScreen -and $this.CurrentScreen.PSObject.Methods['HandleKeyPress']) {
                        $handled = $this.CurrentScreen.HandleKeyPress($key)
                        # Mark dirty if screen handled the key (likely changed state)
                        if ($handled) {
                            $this.IsDirty = $true
                        }
                    }
                }

                # Only render when dirty (state changed)
                if ($this.IsDirty) {
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication.Run: IsDirty=true, calling _RenderCurrentScreen"
                    }
                    $this._RenderCurrentScreen()
                    $iteration = 0  # Reset counter after render
                }

                # Only sleep when no input is pending (prevents lag on input)
                # Don't sleep at all if KeyAvailable - immediate response to user input
                if (-not [Console]::KeyAvailable) {
                    Start-Sleep -Milliseconds 10  # Small sleep when idle to prevent CPU spinning
                }
                # If KeyAvailable, loop immediately for instant response
            }

        } finally {
            # CRITICAL: Flush pending changes before exit
            try {
                $store = $this.Container.Resolve('TaskStore')
                if ($store.HasPendingChanges) {
                    Write-PmcTuiLog "Flushing pending changes on exit..." "INFO"
                    $store.Flush()
                }
            } catch {
                Write-PmcTuiLog "Failed to flush data on exit: $_" "ERROR"
                # Continue with cleanup even if flush fails
            }

            # Flush buffered logs before exit
            if ($global:PmcLoggingService) {
                try {
                    $global:PmcLoggingService.Flush()
                } catch {
                    # Ignore flush errors on exit
                }
            }

            # Cleanup
            [Console]::CursorVisible = $true
            [Console]::Clear()
        }
    }

    <#
    .SYNOPSIS
    Stop the application event loop
    #>
    [void] Stop() {
        $this.Running = $false

        # Flush any pending TaskStore changes before exit
        try {
            $store = $this.Container.Resolve('TaskStore')
            if ($null -ne $store -and $store.HasPendingChanges) {
                $store.Flush()
            }
        } catch {
            # TaskStore might not be available during shutdown - safe to ignore
            if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                Write-PmcTuiLog "Stop: Could not flush TaskStore: $($_.Exception.Message)" "WARNING"
            }
        }
    }

    # === Terminal Management ===

    hidden [void] _UpdateTerminalSize() {
        try {
            $this.TermWidth = [Console]::WindowWidth
            $this.TermHeight = [Console]::WindowHeight
        } catch {
            # Fallback to defaults
            $this.TermWidth = 80
            $this.TermHeight = 24
        }
    }

    hidden [void] _HandleTerminalResize([int]$newWidth, [int]$newHeight) {
        $this.TermWidth = $newWidth
        $this.TermHeight = $newHeight

        # Notify current screen
        if ($this.CurrentScreen) {
            if ($this.CurrentScreen.PSObject.Methods['OnTerminalResize']) {
                $this.CurrentScreen.OnTerminalResize($newWidth, $newHeight)
            }

            # Reapply layout
            if ($this.CurrentScreen.PSObject.Methods['ApplyLayout']) {
                $this.CurrentScreen.ApplyLayout($this.LayoutManager, $newWidth, $newHeight)
            }
        }

        # Fire event
        if ($this.OnTerminalResize) {
            & $this.OnTerminalResize $newWidth $newHeight
        }

        # Mark dirty for render
        $this.IsDirty = $true
    }

    # === Utility Methods ===

    <#
    .SYNOPSIS
    Get current terminal size

    .OUTPUTS
    Hashtable with Width and Height properties
    #>
    [hashtable] GetTerminalSize() {
        return @{
            Width = $this.TermWidth
            Height = $this.TermHeight
        }
    }

    <#
    .SYNOPSIS
    Request a render on next frame

    .DESCRIPTION
    Schedules a re-render of the current screen by setting dirty flag
    #>
    [void] RequestRender() {
        if ($global:PmcTuiLogFile) {
            $caller = (Get-PSCallStack)[1]
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] RequestRender called from: $($caller.Command) at line $($caller.ScriptLineNumber)"
        }
        $this.IsDirty = $true
    }
}

# Classes exported automatically in PowerShell 5.1+
