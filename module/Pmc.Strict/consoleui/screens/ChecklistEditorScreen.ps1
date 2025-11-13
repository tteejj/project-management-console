using namespace System.Collections.Generic
using namespace System.Text

# ChecklistEditorScreen - Edit checklist instance
# Shows items with completion checkboxes

Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"
. "$PSScriptRoot/../services/ChecklistService.ps1"

<#
.SYNOPSIS
Checklist editor screen for managing checklist instance items

.DESCRIPTION
Edit checklist instance:
- Toggle item completion (Space/Enter)
- Add/Edit/Delete items
- View progress
- Navigate with arrow keys
#>
class ChecklistEditorScreen : PmcScreen {
    hidden [ChecklistService]$_checklistService = $null
    hidden [string]$_instanceId = ""
    hidden [object]$_instance = $null
    hidden [int]$_selectedIndex = 0
    hidden [int]$_scrollOffset = 0

    # Legacy constructor (backward compatible)
    ChecklistEditorScreen([string]$instanceId) : base("ChecklistEditor", "Checklist") {
        $this._InitializeScreen($instanceId)
    }

    # Container constructor
    ChecklistEditorScreen([string]$instanceId, [object]$container) : base("ChecklistEditor", "Checklist", $container) {
        $this._InitializeScreen($instanceId)
    }

    hidden [void] _InitializeScreen([string]$instanceId) {
        $this._instanceId = $instanceId
        $this._checklistService = [ChecklistService]::GetInstance()

        # Load instance
        $this._instance = $this._checklistService.GetInstance($instanceId)
        if (-not $this._instance) {
            throw "Checklist instance not found: $instanceId"
        }

        # Update screen title
        $this.ScreenTitle = $this._instance.title

        # Configure header
        $this.Header.SetBreadcrumb(@("Checklists", $this._instance.title))

        # Configure footer
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Space", "Toggle")
        $this.Footer.AddShortcut("A", "Add Item")
        $this.Footer.AddShortcut("E", "Edit Item")
        $this.Footer.AddShortcut("D", "Delete Item")
        $this.Footer.AddShortcut("Esc", "Back")
    }

    [void] OnEnter() {
        # Call parent to ensure proper lifecycle (sets IsActive, calls LoadData, executes OnEnterHandler)
        ([PmcScreen]$this).OnEnter()
    }

    [void] OnExit() {
        $this.IsActive = $false
    }

    [void] LoadData() {
        # Reload instance
        $this._instance = $this._checklistService.GetInstance($this._instanceId)
        if (-not $this._instance) {
            $this.SetStatusMessage("Checklist not found", "error")
            return
        }

        # Ensure selected index is in bounds
        if ($this._selectedIndex -ge $this._instance.items.Count) {
            $this._selectedIndex = [Math]::Max(0, $this._instance.items.Count - 1)
        }
    }

    [string] Render() {
        $sb = [StringBuilder]::new()

        # Render widgets (header, menubar, footer, statusbar)
        $output = ([PmcScreen]$this).Render()
        $sb.Append($output)

        # Calculate content area
        $contentY = 6  # After menubar and header
        $contentHeight = $this.TermHeight - 8  # Subtract header, footer, statusbar
        $contentWidth = $this.TermWidth

        # Render progress bar
        $progressText = "Progress: $($this._instance.completed_count)/$($this._instance.total_count) ($($this._instance.percent_complete)%)"
        $sb.Append($this.Header.BuildMoveTo(2, $contentY))
        $sb.Append($progressText)

        # Render items
        $itemsY = $contentY + 2
        $itemsHeight = $contentHeight - 2

        for ($i = 0; $i -lt $itemsHeight -and ($i + $this._scrollOffset) -lt $this._instance.items.Count; $i++) {
            $itemIndex = $i + $this._scrollOffset
            $item = $this._instance.items[$itemIndex]

            $y = $itemsY + $i
            $sb.Append($this.Header.BuildMoveTo(2, $y))

            # Highlight selected
            if ($itemIndex -eq $this._selectedIndex) {
                $sb.Append("`e[7m")  # Reverse video
            }

            # Checkbox
            $checkbox = if ($item.completed) { "[X]" } else { "[ ]" }
            $sb.Append($checkbox)
            $sb.Append(" ")

            # Item text
            $text = $item.text
            if ($text.Length -gt ($contentWidth - 10)) {
                $text = $text.Substring(0, $contentWidth - 13) + "..."
            }
            $sb.Append($text)

            if ($itemIndex -eq $this._selectedIndex) {
                $sb.Append("`e[0m")  # Reset
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Up arrow
        if ($keyInfo.Key -eq ([ConsoleKey]::UpArrow)) {
            if ($this._selectedIndex -gt 0) {
                $this._selectedIndex--
                if ($this._selectedIndex -lt $this._scrollOffset) {
                    $this._scrollOffset = $this._selectedIndex
                }
            }
            return $true
        }

        # Down arrow
        if ($keyInfo.Key -eq ([ConsoleKey]::DownArrow)) {
            if ($this._selectedIndex -lt ($this._instance.items.Count - 1)) {
                $this._selectedIndex++
                $visibleHeight = $this.TermHeight - 10
                if ($this._selectedIndex -ge ($this._scrollOffset + $visibleHeight)) {
                    $this._scrollOffset = $this._selectedIndex - $visibleHeight + 1
                }
            }
            return $true
        }

        # Space or Enter - Toggle item
        if ($keyInfo.Key -eq ([ConsoleKey]::Spacebar) -or $keyInfo.Key -eq ([ConsoleKey]::Enter)) {
            try {
                $this._checklistService.ToggleItem($this._instanceId, $this._selectedIndex)
                $this.LoadData()
                $this.SetStatusMessage("Item toggled", "success")
            } catch {
                $this.SetStatusMessage("Error: $($_.Exception.Message)", "error")
            }
            return $true
        }

        # Escape - Go back
        if ($keyInfo.Key -eq ([ConsoleKey]::Escape)) {
            $global:PmcApp.PopScreen()
            return $true
        }

        return $false
    }
}
