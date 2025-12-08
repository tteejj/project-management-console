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
    [int]$RenderErrorCount = 0  # Track consecutive render errors for recovery

    # === Automation Support ===
    [string]$AutomationCommandFile = ""  # Path to command file for automation
    [string]$AutomationOutputFile = ""   # Path to output capture file
    [System.Collections.Queue]$CommandQueue = $null  # Queue of simulated key presses
    [bool]$AutomationMode = $false       # Enable automation features

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

        # CRITICAL FIX: Reset shared MenuBar state before switching screens
        # The MenuBar is shared across screens and tracks previous dropdown position.
        # We need to reset this so it doesn't write blank spaces on the new screen.
        if ($global:PmcSharedMenuBar) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PushScreen: BEFORE reset - Height=$($global:PmcSharedMenuBar._prevDropdownHeight) X=$($global:PmcSharedMenuBar._prevDropdownX) Y=$($global:PmcSharedMenuBar._prevDropdownY) Width=$($global:PmcSharedMenuBar._prevDropdownWidth)"
            }
            $global:PmcSharedMenuBar._prevDropdownHeight = 0
            $global:PmcSharedMenuBar._prevDropdownX = 0
            $global:PmcSharedMenuBar._prevDropdownY = 0
            $global:PmcSharedMenuBar._prevDropdownWidth = 0
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PushScreen: AFTER reset - Height=$($global:PmcSharedMenuBar._prevDropdownHeight) X=$($global:PmcSharedMenuBar._prevDropdownX) Y=$($global:PmcSharedMenuBar._prevDropdownY) Width=$($global:PmcSharedMenuBar._prevDropdownWidth)"
            }
        }

        # CRITICAL FIX: Invalidate render cache to force full redraw
        # The differential engine will naturally overwrite old content
        # No screen clearing means no flicker or blank space
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PushScreen: About to RequestClear() for screen '$($screen.ScreenKey)'"
        }
        $this.RenderEngine.RequestClear()

        # Push new screen
        $this.ScreenStack.Push($screen)
        $this.CurrentScreen = $screen

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PushScreen: Screen '$($screen.ScreenKey)' pushed, stack depth now $($this.ScreenStack.Count)"
        }

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

        # CRITICAL FIX: Reset shared MenuBar state before switching screens
        # The MenuBar is shared across screens and tracks previous dropdown position.
        # We need to reset this so it doesn't write blank spaces on the new screen.
        if ($global:PmcSharedMenuBar) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PopScreen: BEFORE reset - Height=$($global:PmcSharedMenuBar._prevDropdownHeight) X=$($global:PmcSharedMenuBar._prevDropdownX) Y=$($global:PmcSharedMenuBar._prevDropdownY) Width=$($global:PmcSharedMenuBar._prevDropdownWidth)"
            }
            $global:PmcSharedMenuBar._prevDropdownHeight = 0
            $global:PmcSharedMenuBar._prevDropdownX = 0
            $global:PmcSharedMenuBar._prevDropdownY = 0
            $global:PmcSharedMenuBar._prevDropdownWidth = 0
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PopScreen: AFTER reset - Height=$($global:PmcSharedMenuBar._prevDropdownHeight) X=$($global:PmcSharedMenuBar._prevDropdownX) Y=$($global:PmcSharedMenuBar._prevDropdownY) Width=$($global:PmcSharedMenuBar._prevDropdownWidth)"
            }
        }

        # CRITICAL FIX: Invalidate render cache to force full redraw
        # The differential engine will naturally overwrite old content
        # No screen clearing means no flicker or blank space
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PopScreen: About to RequestClear() after popping '$($poppedScreen.ScreenKey)'"
        }
        $this.RenderEngine.RequestClear()

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
            # RENDER ERROR - Try to recover gracefully
            $errorMsg = "Render error: $_"
            $errorLocation = "$($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"

            # Log to file if available
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] $errorMsg"
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] Location: $errorLocation"
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] Line: $($_.InvocationInfo.Line)"
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] Stack: $($_.ScriptStackTrace)"
            }

            # Increment error count
            if (-not $this.RenderErrorCount) { $this.RenderErrorCount = 0 }
            $this.RenderErrorCount++

            # If too many errors, then we need to fail
            if ($this.RenderErrorCount -gt 10) {
                # Too many errors - give up
                [Console]::Clear()
                [Console]::CursorVisible = $true
                [Console]::SetCursorPosition(0, 0)
                Write-Host "`n========================================" -ForegroundColor Red
                Write-Host "  TOO MANY RENDER ERRORS - EXITING" -ForegroundColor Red
                Write-Host "========================================`n" -ForegroundColor Red
                Write-Host "Error: $errorMsg" -ForegroundColor Red
                Write-Host "Location: $errorLocation" -ForegroundColor Yellow
                Write-Host "`nThe application experienced too many render errors." -ForegroundColor Yellow
                Write-Host "Please restart the application." -ForegroundColor Yellow
                Write-Host "Press any key to exit..." -ForegroundColor Gray

                [Console]::ReadKey($true) | Out-Null
                $this.Stop()
                return
            }

            # Try to show error in a minimal way and continue
            try {
                # Clear screen and show error message
                [Console]::Clear()
                [Console]::SetCursorPosition(0, 0)
                Write-Host "Render Error Occurred" -ForegroundColor Yellow
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "`nPress any key to continue (ESC to exit)..." -ForegroundColor Gray

                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'Escape') {
                    $this.Stop()
                    return
                }

                # Try to recover by requesting full clear and redraw
                $this.RenderEngine.RequestClear()
                $this.IsDirty = $true

                # If current screen is problematic, try to go back
                if ($this.ScreenStack.Count -gt 1 -and $this.RenderErrorCount -gt 3) {
                    Write-Host "Returning to previous screen due to errors..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds 500
                    $this.PopScreen()
                    $this.RenderErrorCount = 0  # Reset counter after navigation
                }

            } catch {
                # Can't even show the error message - now we really need to exit
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [FATAL] Could not display error: $_"
                }
                $this.Stop()
            }

            # Call error handler if registered
            if ($this.OnError) {
                try {
                    & $this.OnError $_
                } catch {
                    # Error handler failed, log it but continue
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] OnError handler failed: $_"
                    }
                }
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
                $hadInput = $false

                # Check for automation commands
                if ($this.AutomationMode) {
                    $this._ProcessAutomationCommands()
                }

                # Process queued automation commands first
                if ($this.AutomationMode -and $this.CommandQueue.Count -gt 0) {
                    $cmdString = $this.CommandQueue.Dequeue()
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation: Processing command '$cmdString'"
                    }

                    try {
                        $key = $this._ParseCommand($cmdString)

                        # Global keys - Ctrl+Q to exit
                        if ($key.Modifiers -eq [ConsoleModifiers]::Control -and $key.Key -eq 'Q') {
                            $this.Stop()
                        } elseif ($this.CurrentScreen -and $this.CurrentScreen.PSObject.Methods['HandleKeyPress']) {
                            $handled = $this.CurrentScreen.HandleKeyPress($key)
                            if ($handled) {
                                $hadInput = $true
                            }
                        }

                        # Capture screen after command
                        $this._CaptureScreen()
                    } catch {
                        if ($global:PmcTuiLogFile) {
                            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation: Error processing command '$cmdString': $_"
                        }
                    }
                }

                # OPTIMIZATION: Drain ALL available input before rendering
                # This eliminates input lag from sleep delays
                try {
                    while ([Console]::KeyAvailable) {
                        $key = [Console]::ReadKey($true)

                    # Global keys - Ctrl+Q to exit
                    if ($key.Modifiers -eq [ConsoleModifiers]::Control -and $key.Key -eq 'Q') {
                        $this.Stop()
                        break
                    }

                    # Pass to current screen (screen handles its own menu)
                    if ($this.CurrentScreen) {
                        if ($this.CurrentScreen.PSObject.Methods['HandleKeyPress']) {
                            if ($global:PmcTuiLogFile) {
                                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication: Calling HandleKeyPress on $($this.CurrentScreen.GetType().Name) Key=$($key.Key) Char='$($key.KeyChar)'"
                            }
                            Add-Content -Path "/tmp/pmc-flow-debug.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication: Calling HandleKeyPress on $($this.CurrentScreen.GetType().Name) Key=$($key.Key) Char='$($key.KeyChar)'"
                            Add-Content -Path "/tmp/pmc-flow-debug.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication: Methods: $($this.CurrentScreen.PSObject.Methods.Name -join ', ')"
                            $handled = $this.CurrentScreen.HandleKeyPress($key)
                            if ($handled) {
                                $hadInput = $true
                            }
                        } else {
                            if ($global:PmcTuiLogFile) {
                                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication: HandleKeyPress MISSING on $($this.CurrentScreen.GetType().Name)"
                            }
                        }
                    }
                }
                } catch {
                    # Console input is redirected or unavailable - skip input processing
                    # This happens when running in non-interactive mode (e.g., piped input, automated tests)
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication.Run: Console input unavailable (redirected): $($_.Exception.Message)"
                    }
                }

                # Mark dirty if we processed input
                if ($hadInput) {
                    $this.IsDirty = $true
                }

                # Capture dirty state before rendering
                $wasActive = $this.IsDirty

                # OPTIMIZATION: Check terminal resize only when idle (reduces console API calls)
                if (-not $this.IsDirty) {
                    $currentWidth = [Console]::WindowWidth
                    $currentHeight = [Console]::WindowHeight

                    if ($currentWidth -ne $this.TermWidth -or $currentHeight -ne $this.TermHeight) {
                        $this._HandleTerminalResize($currentWidth, $currentHeight)
                    }
                } else {
                    # Reset iteration counter when rendering
                    $iteration = 0
                }

                $iteration++

                # Only render when dirty (state changed)
                if ($this.IsDirty) {
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcApplication.Run: IsDirty=true, calling _RenderCurrentScreen"
                    }
                    $this._RenderCurrentScreen()
                    $iteration = 0  # Reset counter after render
                }

                # Sleep longer when idle (no render) vs active
                if ($wasActive) {
                    Start-Sleep -Milliseconds 1  # ~1000 FPS max, instant response to input
                } else {
                    Start-Sleep -Milliseconds 50  # ~20 FPS when idle, reduced from 100ms for better responsiveness
                }
            }

        } finally {
            # CRITICAL: Flush pending changes before exit
            try {
                . "$PSScriptRoot/services/TaskStore.ps1"
                $store = [TaskStore]::GetInstance()
                if ($store.HasPendingChanges) {
                    Write-PmcTuiLog "Flushing pending changes on exit..." "INFO"
                    $store.Flush()
                }
            } catch {
                Write-PmcTuiLog "Failed to flush data on exit: $_" "ERROR"
                # Continue with cleanup even if flush fails
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
            $store = [TaskStore]::GetInstance()
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

    # === Automation Methods ===

    <#
    .SYNOPSIS
    Enable automation mode with command file and output capture

    .PARAMETER CommandFile
    Path to file containing commands (one per line)

    .PARAMETER OutputFile
    Path to file for capturing screen output
    #>
    [void] EnableAutomation([string]$CommandFile, [string]$OutputFile) {
        $this.AutomationMode = $true
        $this.AutomationCommandFile = $CommandFile
        $this.AutomationOutputFile = $OutputFile
        $this.CommandQueue = New-Object System.Collections.Queue

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation enabled: CommandFile=$CommandFile OutputFile=$OutputFile"
        }
    }

    <#
    .SYNOPSIS
    Check for new commands and queue them
    #>
    hidden [void] _ProcessAutomationCommands() {
        if (-not $this.AutomationMode -or -not (Test-Path $this.AutomationCommandFile)) {
            return
        }

        try {
            $commands = Get-Content $this.AutomationCommandFile -ErrorAction SilentlyContinue
            if ($commands) {
                foreach ($cmd in $commands) {
                    if ($cmd -and $cmd.Trim() -ne '') {
                        $this.CommandQueue.Enqueue($cmd.Trim())
                    }
                }
                # Clear the command file after reading
                Clear-Content $this.AutomationCommandFile -ErrorAction SilentlyContinue

                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation: Queued $($commands.Count) commands"
                }
            }
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation: Error reading commands: $_"
            }
        }
    }

    <#
    .SYNOPSIS
    Convert command string to ConsoleKeyInfo
    #>
    hidden [System.ConsoleKeyInfo] _ParseCommand([string]$command) {
        # Parse commands like "j", "k", "Enter", "Ctrl+Q", "Escape"
        $parts = $command -split '\+'
        $modifiers = [ConsoleModifiers]::None
        $keyName = $parts[-1]

        # Parse modifiers
        foreach ($part in $parts[0..($parts.Length - 2)]) {
            switch ($part.ToLower()) {
                'ctrl' { $modifiers = $modifiers -bor [ConsoleModifiers]::Control }
                'alt' { $modifiers = $modifiers -bor [ConsoleModifiers]::Alt }
                'shift' { $modifiers = $modifiers -bor [ConsoleModifiers]::Shift }
            }
        }

        # Parse key
        $key = [ConsoleKey]::A
        $keyChar = [char]0

        switch ($keyName.ToLower()) {
            'enter' { $key = [ConsoleKey]::Enter; $keyChar = "`r" }
            'escape' { $key = [ConsoleKey]::Escape; $keyChar = [char]27 }
            'esc' { $key = [ConsoleKey]::Escape; $keyChar = [char]27 }
            'tab' { $key = [ConsoleKey]::Tab; $keyChar = "`t" }
            'space' { $key = [ConsoleKey]::Spacebar; $keyChar = ' ' }
            'up' { $key = [ConsoleKey]::UpArrow; $keyChar = [char]0 }
            'down' { $key = [ConsoleKey]::DownArrow; $keyChar = [char]0 }
            'left' { $key = [ConsoleKey]::LeftArrow; $keyChar = [char]0 }
            'right' { $key = [ConsoleKey]::RightArrow; $keyChar = [char]0 }
            default {
                # Single character
                if ($keyName.Length -eq 1) {
                    $keyChar = $keyName[0]
                    $key = [ConsoleKey]::($keyName.ToUpper())
                }
            }
        }

        return New-Object System.ConsoleKeyInfo($keyChar, $key, ($modifiers -band [ConsoleModifiers]::Shift) -ne 0, ($modifiers -band [ConsoleModifiers]::Alt) -ne 0, ($modifiers -band [ConsoleModifiers]::Control) -ne 0)
    }

    <#
    .SYNOPSIS
    Capture current screen to output file
    #>
    hidden [void] _CaptureScreen() {
        if (-not $this.AutomationMode -or -not $this.AutomationOutputFile) {
            return
        }

        try {
            # Capture screen state information
            $screenInfo = @"
=== Screen Capture $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===
Current Screen: $($this.CurrentScreen.GetType().Name)
Terminal Size: $($this.TermWidth)x$($this.TermHeight)
Screen Stack Depth: $($this.ScreenStack.Count)

"@
            # Try to capture current screen's rendered content
            if ($this.CurrentScreen -and $this.CurrentScreen.PSObject.Properties['LastRenderedContent']) {
                $screenInfo += "Last Rendered Content:`n"
                $screenInfo += $this.CurrentScreen.LastRenderedContent
                $screenInfo += "`n"
            }

            Add-Content -Path $this.AutomationOutputFile -Value $screenInfo
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Automation: Error capturing screen: $_"
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
