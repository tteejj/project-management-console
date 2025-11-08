using namespace System.Collections.Generic
using namespace System.Text

# DepRemoveFormScreen - Remove task dependency
# Removes dependency relationship between two tasks

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Remove dependency between tasks

.DESCRIPTION
Shows form to remove task dependency.
Supports:
- Selecting task with dependencies
- Selecting dependency to remove
- Confirming removal
#>
class DepRemoveFormScreen : PmcScreen {
    # Data
    [string]$InputBuffer = ""
    [string]$InputField = "taskId"  # "taskId" or "dependsId"
    [hashtable]$FormData = @{}

    # Constructor
    DepRemoveFormScreen() : base("DepRemove", "Remove Dependency") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Dependencies", "Remove"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Tab", "Next Field")
        $this.Footer.AddShortcut("Enter", "Submit")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # Initialize form data
        $this.FormData = @{
            taskId = ""
            dependsId = ""
        }
    }

    [void] LoadData() {
        $this.ShowStatus("Enter task IDs to remove dependency")
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(2048)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $inputColor = $this.Header.GetThemedAnsi('Primary', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 2
        $x = $contentRect.X + 4

        # Title
        $title = " Remove Dependency "
        $titleX = $contentRect.X + [Math]::Floor(($contentRect.Width - $title.Length) / 2)
        $sb.Append($this.Header.BuildMoveTo($titleX, $y))
        $sb.Append($highlightColor)
        $sb.Append($title)
        $sb.Append($reset)
        $y += 2

        # Task ID field
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.InputField -eq 'taskId') {
            $sb.Append($highlightColor)
        } else {
            $sb.Append($textColor)
        }
        $sb.Append("Task ID:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($x + 13, $y))
        $sb.Append($inputColor)
        if ($this.InputField -eq 'taskId') {
            $sb.Append($this.InputBuffer)
            $sb.Append("_")
        } else {
            $sb.Append($this.FormData['taskId'])
        }
        $sb.Append($reset)
        $y += 2

        # Remove dependency on Task ID field
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.InputField -eq 'dependsId') {
            $sb.Append($highlightColor)
        } else {
            $sb.Append($textColor)
        }
        $sb.Append("Remove dependency on Task ID:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($x + 31, $y))
        $sb.Append($inputColor)
        if ($this.InputField -eq 'dependsId') {
            $sb.Append($this.InputBuffer)
            $sb.Append("_")
        } else {
            $sb.Append($this.FormData['dependsId'])
        }
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Enter' {
                if ($this.InputField -eq 'taskId') {
                    # Save and move to next field
                    $this.FormData['taskId'] = $this.InputBuffer
                    $this.InputBuffer = $this.FormData['dependsId']
                    $this.InputField = 'dependsId'
                    $this.ShowStatus("Now enter dependency task ID to remove")
                } else {
                    # Submit form
                    $this.FormData['dependsId'] = $this.InputBuffer
                    $this._SubmitForm()
                }
                return $true
            }
            'Tab' {
                # Save current field and cycle
                $this.FormData[$this.InputField] = $this.InputBuffer

                if ($this.InputField -eq 'taskId') {
                    $this.InputField = 'dependsId'
                    $this.InputBuffer = $this.FormData['dependsId']
                } else {
                    $this.InputField = 'taskId'
                    $this.InputBuffer = $this.FormData['taskId']
                }
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

        return $false
    }

    hidden [void] _SubmitForm() {
        try {
            $taskId = [int]$this.FormData['taskId']
            $dependsId = [int]$this.FormData['dependsId']

            if ($taskId -le 0 -or $dependsId -le 0) {
                $this.ShowError("Invalid task IDs")
                return
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                $this.ShowError("Task $taskId not found!")
                return
            }

            if (-not $task.PSObject.Properties['depends'] -or -not $task.depends) {
                $this.ShowError("Task has no dependencies!")
                return
            }

            $task.depends = @($task.depends | Where-Object { $_ -ne $dependsId })

            # Clean up empty depends array
            if ($task.depends.Count -eq 0) {
                $task.PSObject.Properties.Remove('depends')
            }

            # Update blocked status
            Update-PmcBlockedStatus -data $data

            Save-PmcData -Data $data -Action "Removed dependency: $taskId no longer depends on $dependsId"
            $this.ShowSuccess("Dependency removed successfully!")

            $this.App.PopScreen()
        } catch {
            $this.ShowError("Failed to remove dependency: $_")
        }
    }
}

# Entry point function for compatibility
function Show-DepRemoveFormScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [DepRemoveFormScreen]::new()
    $App.PushScreen($screen)
}
