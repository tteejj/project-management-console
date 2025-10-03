# PMC FakeTUI Application - Main application entry point
# Lightweight TUI-like interface without framework complexity

# Load dependencies in correct order
. "$PSScriptRoot/Core/PerformanceCore.ps1"
. "$PSScriptRoot/Core/SimpleTerminal.ps1"
. "$PSScriptRoot/Components/MenuSystem.ps1"
. "$PSScriptRoot/Integration/CLIAdapter.ps1"

<#
.SYNOPSIS
Main FakeTUI application for PMC
.DESCRIPTION
Provides a lightweight TUI-like interface with:
- Excel/lynx-style keyboard navigation
- Static UI with selective updates
- Integration with existing PMC CLI commands
- Performance optimized rendering
- No continuous redraws or complex event loops
#>
class PmcFakeTUIApp {
    [PmcSimpleTerminal]$terminal
    [PmcMenuSystem]$menuSystem
    [PmcCLIAdapter]$cliAdapter
    [bool]$running = $true
    [string]$statusMessage = ""
    [string]$lastAction = ""

    PmcFakeTUIApp() {
        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.menuSystem = [PmcMenuSystem]::new()
        $this.cliAdapter = [PmcCLIAdapter]::new()
    }

    # Initialize the application
    [void] Initialize() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Initializing PMC FakeTUI Application"

        try {
            # Initialize terminal
            $this.terminal.Initialize()

            # Clear screen and draw initial layout
            $this.DrawInitialLayout()

            # Show welcome message
            $this.statusMessage = "PMC FakeTUI ready. Press Alt to access menus, Ctrl+Q to exit."
            $this.UpdateStatusLine()

            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI initialized successfully"
        } catch {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to initialize FakeTUI: $_"
            throw
        }
    }

    # Draw the initial application layout
    [void] DrawInitialLayout() {
        $this.terminal.Clear()

        # Draw menu bar (top 2 lines)
        $this.menuSystem.DrawMenuBar()

        # Draw main content area border
        $contentY = 3
        $contentHeight = $this.terminal.Height - 6  # Leave room for menu (2) + status (2) + margin
        $this.terminal.DrawBox(1, $contentY, $this.terminal.Width - 2, $contentHeight)

        # Draw content area title
        $title = " PMC - Project Management Console "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, $contentY, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Draw welcome message in content area
        $welcomeY = $contentY + 3
        $welcome = @(
            "Welcome to PMC FakeTUI!",
            "",
            "This is a keyboard-driven interface for Project Management Console.",
            "",
            "GETTING STARTED:",
            "• Press Alt to activate menus",
            "• Use Alt+Letter for direct access (Alt+T for Tasks, Alt+P for Projects)",
            "• Arrow keys navigate, Enter selects, Esc cancels",
            "• Press Ctrl+Q to exit",
            "",
            "Try Alt+T to access the Task menu and add your first task!"
        )

        for ($i = 0; $i -lt $welcome.Count; $i++) {
            $line = $welcome[$i]
            $x = 4
            $y = $welcomeY + $i
            if ($y -lt $this.terminal.Height - 4) {  # Don't write below status area
                if ($line.StartsWith("•")) {
                    $this.terminal.WriteAtColor($x, $y, $line, [PmcVT100]::Yellow(), "")
                } elseif ($line.Contains("GETTING STARTED")) {
                    $this.terminal.WriteAtColor($x, $y, $line, [PmcVT100]::Cyan(), "")
                } elseif ($line.Contains("Welcome")) {
                    $this.terminal.WriteAtColor($x, $y, $line, [PmcVT100]::Green(), "")
                } else {
                    $this.terminal.WriteAt($x, $y, $line)
                }
            }
        }

        # Draw status line separator
        $statusY = $this.terminal.Height - 2
        $this.terminal.DrawHorizontalLine(0, $statusY - 1, $this.terminal.Width)
    }

    # Update the status line at the bottom
    [void] UpdateStatusLine() {
        $statusY = $this.terminal.Height - 1

        # Clear status line
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')

        # Show status message
        if ($this.statusMessage) {
            $this.terminal.WriteAt(2, $statusY, $this.statusMessage)
        }

        # Show last action on the right
        if ($this.lastAction) {
            $actionText = "Last: " + $this.cliAdapter.GetActionDescription($this.lastAction)
            $actionX = $this.terminal.Width - $actionText.Length - 2
            if ($actionX -gt $this.statusMessage.Length + 5) {
                $this.terminal.WriteAtColor($actionX, $statusY, $actionText, [PmcVT100]::Blue(), "")
            }
        }
    }

    # Clear the content area for command output
    [void] ClearContentArea() {
        $contentY = 4  # Below menu bar and title
        $contentHeight = $this.terminal.Height - 8  # Account for menu, title, status
        $contentWidth = $this.terminal.Width - 4   # Account for borders

        $this.terminal.FillArea(2, $contentY, $contentWidth, $contentHeight, ' ')
    }

    # Display command result in content area
    [void] DisplayResult([hashtable]$result) {
        $this.ClearContentArea()

        $contentY = 4
        $maxLines = $this.terminal.Height - 8
        $maxWidth = $this.terminal.Width - 6

        # Display result based on type
        switch ($result.Type) {
            'success' {
                $this.terminal.WriteAtColor(4, $contentY, "✓ SUCCESS", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, $contentY + 1, $result.Message)

                if ($result.Data) {
                    $this.DisplayData($result.Data, $contentY + 3, $maxLines - 3, $maxWidth)
                }
            }
            'error' {
                $this.terminal.WriteAtColor(4, $contentY, "✗ ERROR", [PmcVT100]::Red(), "")
                $this.terminal.WriteAt(4, $contentY + 1, $result.Message)
            }
            'info' {
                $this.terminal.WriteAtColor(4, $contentY, "ℹ INFO", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAt(4, $contentY + 1, $result.Message)

                if ($result.Data) {
                    $this.DisplayData($result.Data, $contentY + 3, $maxLines - 3, $maxWidth)
                }
            }
            'cancelled' {
                $this.terminal.WriteAtColor(4, $contentY, "⚠ CANCELLED", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(4, $contentY + 1, $result.Message)
            }
            'exit' {
                $this.running = $false
                return
            }
        }

        # Update status
        $this.statusMessage = "$($result.Type.ToUpper()): $($result.Message)"
        $this.UpdateStatusLine()
    }

    # Display data in content area (simplified)
    [void] DisplayData([object]$data, [int]$startY, [int]$maxLines, [int]$maxWidth) {
        if (-not $data) { return }

        $currentY = $startY
        $linesUsed = 0

        # Convert data to displayable text
        if ($data -is [string]) {
            $lines = $data -split "`n"
            foreach ($line in $lines) {
                if ($linesUsed -ge $maxLines) { break }
                $displayLine = if ($line.Length -gt $maxWidth) {
                    $line.Substring(0, $maxWidth - 3) + "..."
                } else { $line }
                $this.terminal.WriteAt(4, $currentY, $displayLine)
                $currentY++
                $linesUsed++
            }
        } elseif ($data -is [array]) {
            foreach ($item in $data) {
                if ($linesUsed -ge $maxLines) { break }
                $itemText = $item.ToString()
                $displayLine = if ($itemText.Length -gt $maxWidth) {
                    $itemText.Substring(0, $maxWidth - 3) + "..."
                } else { $itemText }
                $this.terminal.WriteAt(4, $currentY, $displayLine)
                $currentY++
                $linesUsed++
            }
        } else {
            # Try to format as string
            $dataText = $data | Format-List | Out-String
            $lines = $dataText -split "`n"
            foreach ($line in $lines) {
                if ($linesUsed -ge $maxLines) { break }
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $displayLine = if ($line.Length -gt $maxWidth) {
                        $line.Substring(0, $maxWidth - 3) + "..."
                    } else { $line }
                    $this.terminal.WriteAt(4, $currentY, $displayLine)
                    $currentY++
                    $linesUsed++
                }
            }
        }

        if ($linesUsed -ge $maxLines) {
            $this.terminal.WriteAtColor(4, $currentY - 1, "[Output truncated - use CLI for full results]", [PmcVT100]::Yellow(), "")
        }
    }

    # Main application loop
    [void] Run() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Starting PMC FakeTUI main loop"

        while ($this.running) {
            try {
                # Handle menu input (this blocks until user takes action)
                $action = $this.menuSystem.HandleInput()

                if ($action) {
                    Write-PmcDebug -Level 2 -Category 'FakeTUI' -Message "Processing action: $action"

                    # Record last action
                    $this.lastAction = $action

                    # Execute the action via CLI adapter
                    $result = $this.cliAdapter.ExecuteAction($action)

                    # Display the result
                    $this.DisplayResult($result)

                    # If it's an exit action, stop the loop
                    if ($result.Type -eq 'exit') {
                        $this.running = $false
                    }
                } else {
                    # No action - could be used for other global key handling
                    # For now, just continue the loop
                }

            } catch {
                Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Error in main loop: $_"
                $errorResult = @{
                    Type = 'error'
                    Message = "Application error: $($_.Exception.Message)"
                    Data = $null
                }
                $this.DisplayResult($errorResult)
            }
        }

        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI main loop ended"
    }

    # Cleanup and shutdown
    [void] Shutdown() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Shutting down PMC FakeTUI"

        try {
            # Restore terminal
            $this.terminal.Cleanup()

            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI shutdown complete"
        } catch {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Error during shutdown: $_"
        }
    }
}

# Main entry point function
function Start-PmcFakeTUI {
    <#
    .SYNOPSIS
    Start the PMC FakeTUI application
    .DESCRIPTION
    Launches the lightweight TUI interface for PMC with keyboard-driven
    menu navigation and integration with existing CLI commands.
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting PMC FakeTUI..." -ForegroundColor Green

        $app = [PmcFakeTUIApp]::new()
        $app.Initialize()
        $app.Run()
        $app.Shutdown()

        Write-Host "PMC FakeTUI exited." -ForegroundColor Green

    } catch {
        Write-Host "Failed to start PMC FakeTUI: $($_.Exception.Message)" -ForegroundColor Red
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to start FakeTUI: $_"
        throw
    }
}

# Export the main function
Export-ModuleMember -Function Start-PmcFakeTUI