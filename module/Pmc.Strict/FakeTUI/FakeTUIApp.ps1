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

    [void] Initialize() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Initializing PMC FakeTUI Application"
        try {
            $this.terminal.Initialize()
            $this.DrawInitialLayout()
            $this.statusMessage = "PMC FakeTUI ready. Press Alt to access menus, Ctrl+Q to exit."
            $this.UpdateStatusLine()
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI initialized successfully"
        } catch {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to initialize FakeTUI: $_"
            throw
        }
    }

    [void] DrawInitialLayout() {
        # Skip landing screen - go straight to task list
        $result = $this.cliAdapter.ExecuteAction('task:list')
        if ($result) {
            $this.DisplayResult($result)
        }
    }

    [void] UpdateStatusLine() {
        $statusY = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')
        if ($this.statusMessage) { $this.terminal.WriteAt(2, $statusY, $this.statusMessage) }
        if ($this.lastAction) {
            $actionText = "Last: " + $this.cliAdapter.GetActionDescription($this.lastAction)
            $actionX = $this.terminal.Width - $actionText.Length - 2
            if ($actionX -gt $this.statusMessage.Length + 5) { $this.terminal.WriteAtColor($actionX, $statusY, $actionText, [PmcVT100]::Blue(), "") }
        }
    }

    [void] ClearContentArea() {
        $contentY = 4; $contentHeight = $this.terminal.Height - 8; $contentWidth = $this.terminal.Width - 4
        $this.terminal.FillArea(2, $contentY, $contentWidth, $contentHeight, ' ')
    }

    [void] DisplayResult([hashtable]$result) {
        $this.ClearContentArea(); $contentY = 4; $maxLines = $this.terminal.Height - 8; $maxWidth = $this.terminal.Width - 6
        switch ($result.Type) {
            'success' { $this.terminal.WriteAtColor(4, $contentY, "✓ SUCCESS", [PmcVT100]::Green(), ""); $this.terminal.WriteAt(4, $contentY + 1, $result.Message); if ($result.Data) { $this.DisplayData($result.Data, $contentY + 3, $maxLines - 3, $maxWidth) } }
            'error' { $this.terminal.WriteAtColor(4, $contentY, "✗ ERROR", [PmcVT100]::Red(), ""); $this.terminal.WriteAt(4, $contentY + 1, $result.Message) }
            'info' { $this.terminal.WriteAtColor(4, $contentY, "ℹ INFO", [PmcVT100]::Cyan(), ""); $this.terminal.WriteAt(4, $contentY + 1, $result.Message); if ($result.Data) { $this.DisplayData($result.Data, $contentY + 3, $maxLines - 3, $maxWidth) } }
            'cancelled' { $this.terminal.WriteAtColor(4, $contentY, "⚠ CANCELLED", [PmcVT100]::Yellow(), ""); $this.terminal.WriteAt(4, $contentY + 1, $result.Message) }
            'exit' { $this.running = $false; return }
        }
        $this.statusMessage = "$($result.Type.ToUpper()): $($result.Message)"; $this.UpdateStatusLine()
    }

    [void] DisplayData([object]$data, [int]$startY, [int]$maxLines, [int]$maxWidth) {
        if (-not $data) { return }
        $currentY = $startY; $linesUsed = 0
        if ($data -is [string]) {
            $lines = $data -split "`n"; foreach ($line in $lines) { if ($linesUsed -ge $maxLines) { break }; $display = if ($line.Length -gt $maxWidth) { $line.Substring(0, $maxWidth - 3) + "..." } else { $line }; $this.terminal.WriteAt(4, $currentY, $display); $currentY++; $linesUsed++ }
        } elseif ($data -is [array]) {
            foreach ($item in $data) { if ($linesUsed -ge $maxLines) { break }; $text = $item.ToString(); $display = if ($text.Length -gt $maxWidth) { $text.Substring(0, $maxWidth - 3) + "..." } else { $text }; $this.terminal.WriteAt(4, $currentY, $display); $currentY++; $linesUsed++ }
        } else {
            $dataText = $data | Format-List | Out-String; $lines = $dataText -split "`n"; foreach ($line in $lines) { if ($linesUsed -ge $maxLines) { break }; if (-not [string]::IsNullOrWhiteSpace($line)) { $display = if ($line.Length -gt $maxWidth) { $line.Substring(0, $maxWidth - 3) + "..." } else { $line }; $this.terminal.WriteAt(4, $currentY, $display); $currentY++; $linesUsed++ } }
        }
        if ($linesUsed -ge $maxLines) { $this.terminal.WriteAtColor(4, $currentY - 1, "[Output truncated - use CLI for full results]", [PmcVT100]::Yellow(), "") }
    }

    [void] Run() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Starting PMC FakeTUI main loop"
        while ($this.running) {
            try {
                $action = $this.menuSystem.HandleInput()
                if ($action) {
                    Write-PmcDebug -Level 2 -Category 'FakeTUI' -Message "Processing action: $action"
                    $this.lastAction = $action
                    $result = $this.cliAdapter.ExecuteAction($action)
                    $this.DisplayResult($result)
                    if ($result.Type -eq 'exit') { $this.running = $false }
                }
            } catch {
                Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Error in main loop: $_"
                $this.DisplayResult(@{ Type='error'; Message = "Application error: $($_.Exception.Message)"; Data=$null })
            }
        }
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI main loop ended"
    }

    [void] Shutdown() {
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Shutting down PMC FakeTUI"
        try { $this.terminal.Cleanup(); Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "PMC FakeTUI shutdown complete" } catch { Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Error during shutdown: $_" }
    }
}

function Start-PmcFakeTUI {
    [CmdletBinding()] param()
    try {
        Write-Host "Starting PMC FakeTUI..." -ForegroundColor Green
        $app = [PmcFakeTUIApp]::new(); $app.Initialize(); $app.Run(); $app.Shutdown()
        Write-Host "PMC FakeTUI exited." -ForegroundColor Green
    } catch {
        Write-Host "Failed to start PMC FakeTUI: $($_.Exception.Message)" -ForegroundColor Red
        Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to start FakeTUI: $_"
        throw
    }
}

# Export-ModuleMember -Function Start-PmcFakeTUI  # Not needed when dot-sourced

