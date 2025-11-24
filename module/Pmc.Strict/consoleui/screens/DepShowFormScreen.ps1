using namespace System.Collections.Generic
using namespace System.Text

# DepShowFormScreen - Show task dependencies
# Displays dependencies for a specific task in tree view


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Show task dependencies screen

.DESCRIPTION
Shows task dependencies in tree view.
Supports:
- Viewing tasks this depends on
- Viewing tasks that depend on this
- Read-only view
#>
class DepShowFormScreen : PmcScreen {
    # Data
    [string]$InputBuffer = ""
    [bool]$IsInputMode = $true
    [object]$Task = $null
    [array]$Dependencies = @()

    # Backward compatible constructor
    DepShowFormScreen() : base("DepShow", "Show Dependencies") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Dependencies", "View"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Enter", "Submit")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    # Container constructor
    DepShowFormScreen([object]$container) : base("DepShow", "Show Dependencies", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Dependencies", "View"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Enter", "Submit")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        if ($this.IsInputMode) {
            $this.ShowStatus("Enter task ID to show dependencies")
        }
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $highlightColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $successColor = $this.Header.GetThemedFg('Foreground.Success')
        $errorColor = $this.Header.GetThemedFg('Foreground.Error')
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"

        $y = $contentRect.Y + 2
        $x = $contentRect.X + 4

        # Title
        $title = " Show Task Dependencies "
        $titleX = $contentRect.X + [Math]::Floor(($contentRect.Width - $title.Length) / 2)
        $sb.Append($this.Header.BuildMoveTo($titleX, $y))
        $sb.Append($highlightColor)
        $sb.Append($title)
        $sb.Append($reset)
        $y += 2

        if ($this.IsInputMode) {
            # Input mode - ask for task ID
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append("Task ID:")
            $sb.Append($reset)

            $sb.Append($this.Header.BuildMoveTo($x + 13, $y))
            $sb.Append($highlightColor)
            $sb.Append($this.InputBuffer)
            $sb.Append("_")
            $sb.Append($reset)
        } else {
            # Display mode - show dependencies
            if ($null -eq $this.Task) {
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($errorColor)
                $sb.Append("Task not found")
                $sb.Append($reset)
            } else {
                # Show task info
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($warningColor)
                $sb.Append("Task:")
                $sb.Append($reset)

                $taskText = $this.Task.text
                if ($taskText.Length -gt 60) {
                    $taskText = $taskText.Substring(0, 60) + "..."
                }
                $sb.Append($this.Header.BuildMoveTo($x + 6, $y))
                $sb.Append($textColor)
                $sb.Append($taskText)
                $sb.Append($reset)
                $y += 2

                # Show dependencies
                if ($this.Dependencies.Count -eq 0) {
                    $sb.Append($this.Header.BuildMoveTo($x, $y))
                    $sb.Append($mutedColor)
                    $sb.Append("No dependencies")
                    $sb.Append($reset)
                } else {
                    $sb.Append($this.Header.BuildMoveTo($x, $y))
                    $sb.Append($warningColor)
                    $sb.Append("Dependencies:")
                    $sb.Append($reset)
                    $y += 2

                    $maxLines = [Math]::Min($this.Dependencies.Count, $contentRect.Height - 10)
                    for ($i = 0; $i -lt $maxLines; $i++) {
                        $dep = $this.Dependencies[$i]

                        # Status icon
                        $depStatus = $dep.status
                        $statusIcon = if ($depStatus -eq 'completed') { 'X' } else { 'o' }
                        $statusColor = if ($depStatus -eq 'completed') { $successColor } else { $errorColor }

                        $sb.Append($this.Header.BuildMoveTo($x + 2, $y))
                        $sb.Append($statusColor)
                        $sb.Append($statusIcon)
                        $sb.Append($reset)

                        # Task ID
                        $depId = $dep.id
                        $sb.Append($this.Header.BuildMoveTo($x + 4, $y))
                        $sb.Append($mutedColor)
                        $sb.Append("#$depId")
                        $sb.Append($reset)

                        # Task text
                        $depText = $dep.text
                        if ($depText.Length -gt 50) {
                            $depText = $depText.Substring(0, 50) + "..."
                        }
                        $sb.Append($this.Header.BuildMoveTo($x + 11, $y))
                        $sb.Append($textColor)
                        $sb.Append($depText)
                        $sb.Append($reset)

                        $y++
                    }
                }

                # Show blocked status
                $y += 2
                $isBlocked = $this.Task.blocked
                if ($isBlocked) {
                    $sb.Append($this.Header.BuildMoveTo($x, $y))
                    $sb.Append($errorColor)
                    $sb.Append("WARNING: Task is BLOCKED")
                    $sb.Append($reset)
                } else {
                    $sb.Append($this.Header.BuildMoveTo($x, $y))
                    $sb.Append($successColor)
                    $sb.Append("Task is ready")
                    $sb.Append($reset)
                }
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        if ($this.IsInputMode) {
            switch ($keyInfo.Key) {
                'Enter' {
                    $this._LoadTask()
                    return $true
                }
                'Escape' {
                    $this.App.PopScreen()
                    return $true
                }
                'Backspace' {
                    if ($this.InputBuffer.Length -gt 0) {
                        $this.InputBuffer = $this.InputBuffer.Substring(0, $this.InputBuffer.Length - 1)
                        return $true
                    }
                }
                default {
                    if ($keyInfo.KeyChar -and -not [char]::IsControl($keyInfo.KeyChar)) {
                        $this.InputBuffer += $keyInfo.KeyChar
                        return $true
                    }
                }
            }
        } else {
            # Display mode - just wait for Esc
            if ($keyInfo.Key -eq 'Escape') {
                $this.App.PopScreen()
                return $true
            }
        }

        return $false
    }

    hidden [void] _LoadTask() {
        try {
            $taskId = [int]$this.InputBuffer

            if ($taskId -le 0) {
                $this.ShowError("Invalid task ID")
                return
            }

            $data = Get-PmcData
            $this.Task = $data.tasks | Where-Object { ($_.id) -eq $taskId } | Select-Object -First 1

            if (-not $this.Task) {
                $this.ShowError("Task $taskId not found")
                return
            }

            # Load dependencies
            $depends = $this.Task.depends
            $depends = if ($depends) { $depends } else { @() }
            $this.Dependencies = @()

            foreach ($depId in $depends) {
                $depTask = $data.tasks | Where-Object { ($_.id) -eq $depId } | Select-Object -First 1
                if ($depTask) {
                    $this.Dependencies += $depTask
                }
            }

            $this.IsInputMode = $false
            $this.ShowStatus("Showing dependencies for task #$taskId")

        } catch {
            $this.ShowError("Failed to load task: $_")
        }
    }
}

# Entry point function for compatibility
function Show-DepShowFormScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [DepShowFormScreen]::new()
    $App.PushScreen($screen)
}
