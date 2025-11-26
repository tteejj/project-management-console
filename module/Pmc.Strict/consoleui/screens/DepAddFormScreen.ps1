using namespace System.Collections.Generic
using namespace System.Text

# DepAddFormScreen - Add task dependency
# Creates dependency relationship between two tasks


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Add dependency between tasks

.DESCRIPTION
Shows form to create task dependency.
Supports:
- Selecting task that depends on another
- Selecting dependency task
- Creating dependency relationship
#>
class DepAddFormScreen : PmcScreen {
    # Data
    [string]$InputBuffer = ""
    [string]$InputField = "taskId"  # "taskId" or "dependsId"
    [hashtable]$FormData = @{}

    # Backward compatible constructor
    DepAddFormScreen() : base("DepAdd", "Add Dependency") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Dependencies", "Add"))

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

    # Container constructor
    DepAddFormScreen([object]$container) : base("DepAdd", "Add Dependency", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Dependencies", "Add"))

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
        $this.ShowStatus("Enter task IDs to create dependency")
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(2048)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $highlightColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $inputColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $reset = "`e[0m"

        $y = $contentRect.Y + 2
        $x = $contentRect.X + 4

        # Title
        $title = " Add Dependency "
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

        # Depends on Task ID field
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.InputField -eq 'dependsId') {
            $sb.Append($highlightColor)
        } else {
            $sb.Append($textColor)
        }
        $sb.Append("Depends on Task ID:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($x + 22, $y))
        $sb.Append($inputColor)
        if ($this.InputField -eq 'dependsId') {
            $sb.Append($this.InputBuffer)
            $sb.Append("_")
        } else {
            $sb.Append($this.FormData['dependsId'])
        }
        $sb.Append($reset)
        $y += 2

        # Help text
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($mutedColor)
        $sb.Append("(Task will be blocked until dependency is completed)")
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
                    $this.ShowStatus("Now enter dependency task ID")
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

            $data = Get-PmcData
            $task = $data.tasks | Where-Object { ($_.id) -eq $taskId } | Select-Object -First 1
            $dependsTask = $data.tasks | Where-Object { ($_.id) -eq $dependsId } | Select-Object -First 1

            if (-not $task) {
                $this.ShowError("Task $taskId not found!")
                return
            }

            if (-not $dependsTask) {
                $this.ShowError("Task $dependsId not found!")
                return
            }

            # Get existing depends or initialize
            $taskDepends = $task.depends
            if (-not $taskDepends) {
                $task | Add-Member -NotePropertyName depends -NotePropertyValue @()
                $taskDepends = @()
            }

            # Check if dependency already exists
            if ($taskDepends -contains $dependsId) {
                $this.ShowError("Dependency already exists!")
                return
            }

            $task.depends = @($taskDepends + $dependsId)

            # Update blocked status
            Update-PmcBlockedStatus -data $data

            Save-PmcData -Data $data -Action "Added dependency: $taskId depends on $dependsId"
            $this.ShowSuccess("Dependency added successfully! Task $taskId now depends on task $dependsId.")

            $this.App.PopScreen()
        } catch {
            $this.ShowError("Failed to add dependency: $_")
        }
    }
}

# Entry point function for compatibility
function Show-DepAddFormScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object DepAddFormScreen
    $App.PushScreen($screen)
}
