# ProjectPicker.ps1 - Project selection widget with fuzzy search and inline create
#
# Usage:
#   $picker = [ProjectPicker]::new()
#   $picker.SetPosition(10, 5)
#   $picker.SetSize(35, 12)
#   $picker.OnProjectSelected = { param($project) Write-Host "Selected: $project" }
#
#   # Render
#   $ansiOutput = $picker.Render()
#   Write-Host $ansiOutput -NoNewline
#
#   # Handle input
#   $key = [Console]::ReadKey($true)
#   $handled = $picker.HandleInput($key)
#
#   # Get result
#   if ($picker.IsConfirmed) {
#       $selected = $picker.GetSelectedProject()
#   }

using namespace System
using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# Load PmcWidget base class if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

<#
.SYNOPSIS
Project selection widget with fuzzy search and inline project creation

.DESCRIPTION
Features:
- Load projects from Get-PmcData
- Type-ahead fuzzy filtering (matches substrings and initials)
- Arrow key navigation through filtered list
- Enter to select project
- Alt+N to create new project inline (switches to TextInput mode)
- Recent projects shown at top
- Project count display
- OnProjectSelected event callback
- Visual list with scroll indicators
- Empty state handling

.EXAMPLE
$picker = [ProjectPicker]::new()
$picker.SetPosition(10, 5)
$picker.SetSize(35, 12)
$picker.OnProjectSelected = { param($projectName) Write-Host "Selected: $projectName" }
$picker.OnProjectCreated = { param($projectName) Write-Host "Created: $projectName" }
$ansiOutput = $picker.Render()
#>
class ProjectPicker : PmcWidget {
    # === Public Properties ===
    [string]$Label = "Select Project"      # Widget title
    [bool]$ShowRecentFirst = $true         # Show recent projects at top

    # === Event Callbacks ===
    [scriptblock]$OnProjectSelected = {}   # Called when project selected: param($projectName)
    [scriptblock]$OnProjectCreated = {}    # Called when new project created: param($projectName)
    [scriptblock]$OnCancelled = {}         # Called when Esc pressed

    # === State Flags ===
    [bool]$IsConfirmed = $false            # True when project selected
    [bool]$IsCancelled = $false            # True when Esc pressed

    # === Private State ===
    hidden [string[]]$_allProjects = @()           # All available projects
    hidden [string[]]$_filteredProjects = @()      # Filtered project list
    hidden [string]$_searchText = ""               # Current search filter
    hidden [int]$_selectedIndex = 0                # Selected item index in filtered list
    hidden [int]$_scrollOffset = 0                 # Scroll offset for long lists
    hidden [bool]$_isCreateMode = $false           # True when creating new project
    hidden [string]$_createText = ""               # Text for new project name
    hidden [int]$_createCursorPos = 0              # Cursor position in create mode
    hidden [string]$_errorMessage = ""             # Error message to display
    hidden [DateTime]$_lastRefresh = [DateTime]::MinValue

    # === Constructor ===
    ProjectPicker() : base("ProjectPicker") {
        $this.Width = 35
        $this.Height = 12
        $this.CanFocus = $true
        $this._LoadProjects()
    }

    # === Public API Methods ===

    <#
    .SYNOPSIS
    Refresh project list from data source
    #>
    [void] RefreshProjects() {
        $this._LoadProjects()
        $this._ApplyFilter()
    }

    <#
    .SYNOPSIS
    Get the currently selected project name

    .OUTPUTS
    String project name or empty string if none selected
    #>
    [string] GetSelectedProject() {
        if ($this._filteredProjects.Count -eq 0) {
            return ""
        }

        if ($this._selectedIndex -ge 0 -and $this._selectedIndex -lt $this._filteredProjects.Count) {
            return $this._filteredProjects[$this._selectedIndex]
        }

        return ""
    }

    <#
    .SYNOPSIS
    Set initial search filter text

    .PARAMETER text
    Search text to pre-populate
    #>
    [void] SetSearchText([string]$text) {
        $this._searchText = $text
        $this._ApplyFilter()
    }

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    ConsoleKeyInfo from [Console]::ReadKey($true)

    .OUTPUTS
    True if input was handled, False otherwise
    #>
    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Check if we need to refresh projects (every 5 seconds)
        if (([DateTime]::Now - $this._lastRefresh).TotalSeconds -gt 5) {
            $this._LoadProjects()
            $this._ApplyFilter()
        }

        # Create mode has different input handling
        if ($this._isCreateMode) {
            return $this._HandleCreateModeInput($keyInfo)
        }

        # Enter - select current project
        if ($keyInfo.Key -eq 'Enter') {
            $selected = $this.GetSelectedProject()
            if (-not [string]::IsNullOrWhiteSpace($selected)) {
                $this.IsConfirmed = $true
                $this._InvokeCallback($this.OnProjectSelected, $selected)
                return $true
            }
            return $true
        }

        # Escape - cancel
        if ($keyInfo.Key -eq 'Escape') {
            $this.IsCancelled = $true
            $this._InvokeCallback($this.OnCancelled, $null)
            return $true
        }

        # Alt+N - create new project
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt -and $keyInfo.Key -eq 'N') {
            $this._EnterCreateMode()
            return $true
        }

        # Navigation
        if ($keyInfo.Key -eq 'UpArrow') {
            $this._MoveSelectionUp()
            return $true
        }

        if ($keyInfo.Key -eq 'DownArrow') {
            $this._MoveSelectionDown()
            return $true
        }

        if ($keyInfo.Key -eq 'PageUp') {
            $this._MoveSelectionUp()
            $this._MoveSelectionUp()
            $this._MoveSelectionUp()
            return $true
        }

        if ($keyInfo.Key -eq 'PageDown') {
            $this._MoveSelectionDown()
            $this._MoveSelectionDown()
            $this._MoveSelectionDown()
            return $true
        }

        if ($keyInfo.Key -eq 'Home') {
            $this._selectedIndex = 0
            $this._AdjustScrollOffset()
            return $true
        }

        if ($keyInfo.Key -eq 'End') {
            $this._selectedIndex = [Math]::Max(0, $this._filteredProjects.Count - 1)
            $this._AdjustScrollOffset()
            return $true
        }

        # Backspace - remove character from search
        if ($keyInfo.Key -eq 'Backspace') {
            if ($this._searchText.Length -gt 0) {
                $this._searchText = $this._searchText.Substring(0, $this._searchText.Length - 1)
                $this._ApplyFilter()
            }
            return $true
        }

        # Ctrl+U - clear search
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Control -and $keyInfo.Key -eq 'U') {
            $this._searchText = ""
            $this._ApplyFilter()
            return $true
        }

        # Regular character - add to search
        if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
            $this._searchText += $keyInfo.KeyChar
            $this._ApplyFilter()
            return $true
        }

        # Space
        if ($keyInfo.Key -eq 'Spacebar') {
            $this._searchText += ' '
            $this._ApplyFilter()
            return $true
        }

        return $false
    }

    <#
    .SYNOPSIS
    Render the project picker widget

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] Render() {
        $sb = [StringBuilder]::new(2048)

        # Colors from theme
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $textColor = $this.GetThemedAnsi('Text', $false)
        $primaryColor = $this.GetThemedAnsi('Primary', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $errorColor = $this.GetThemedAnsi('Error', $false)
        $successColor = $this.GetThemedAnsi('Success', $false)
        $highlightBg = $this.GetThemedAnsi('Primary', $true)
        $reset = "`e[0m"

        # Draw top border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'top', 'single'))

        # Title
        $title = if ($this._isCreateMode) { "Create New Project" } else { $this.Label }
        $titlePos = 2
        $sb.Append($this.BuildMoveTo($this.X + $titlePos, $this.Y))
        $sb.Append($primaryColor)
        $sb.Append(" $title ")

        # Project count
        if (-not $this._isCreateMode) {
            $countText = "($($this._filteredProjects.Count))"
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - $countText.Length - 2, $this.Y))
            $sb.Append($mutedColor)
            $sb.Append($countText)
        }

        $currentRow = 1

        # Create mode UI
        if ($this._isCreateMode) {
            # Input row
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $currentRow))
            $sb.Append($textColor)

            # Render input with cursor
            $innerWidth = $this.Width - 4
            if ([string]::IsNullOrEmpty($this._createText)) {
                $sb.Append($mutedColor)
                $sb.Append($this.TruncateText("Enter project name...", $innerWidth))
            } else {
                $displayText = $this._createText
                if ($displayText.Length -gt $innerWidth) {
                    $displayText = $displayText.Substring(0, $innerWidth)
                }

                # Text before cursor
                if ($this._createCursorPos -gt 0 -and $this._createCursorPos -le $displayText.Length) {
                    $sb.Append($displayText.Substring(0, $this._createCursorPos))
                }

                # Cursor
                if ($this._createCursorPos -lt $displayText.Length) {
                    $sb.Append("`e[7m")
                    $sb.Append($displayText[$this._createCursorPos])
                    $sb.Append("`e[27m")

                    if ($this._createCursorPos + 1 -lt $displayText.Length) {
                        $sb.Append($displayText.Substring($this._createCursorPos + 1))
                    }
                } elseif ($this._createCursorPos -eq $displayText.Length) {
                    $sb.Append($displayText)
                    $sb.Append("`e[7m `e[27m")
                }

                # Padding
                $textLen = $displayText.Length
                $padding = $innerWidth - $textLen - 1
                if ($padding -gt 0) {
                    $sb.Append(" " * $padding)
                }
            }

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++

            # Instructions
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $currentRow))
            $sb.Append($mutedColor)
            $sb.Append($this.TruncateText("Enter=Create | Esc=Cancel", $this.Width - 4))

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++

            # Fill remaining rows
            for ($i = $currentRow; $i -lt $this.Height - 1; $i++) {
                $sb.Append($this.BuildMoveTo($this.X, $this.Y + $i))
                $sb.Append($borderColor)
                $sb.Append($this.GetBoxChar('single_vertical'))
                $sb.Append(" " * ($this.Width - 2))
                $sb.Append($this.GetBoxChar('single_vertical'))
            }
        } else {
            # Search filter row
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $currentRow))
            if ([string]::IsNullOrWhiteSpace($this._searchText)) {
                $sb.Append($mutedColor)
                $sb.Append($this.TruncateText("Type to filter...", $this.Width - 4))
            } else {
                $sb.Append($primaryColor)
                $sb.Append($this.TruncateText($this._searchText, $this.Width - 4))
            }

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++

            # Project list
            $maxVisibleItems = $this.Height - 4  # Top, search, bottom, help
            $visibleProjects = @()
            if ($this._filteredProjects.Count -gt 0) {
                $endIndex = [Math]::Min($this._scrollOffset + $maxVisibleItems, $this._filteredProjects.Count)
                for ($i = $this._scrollOffset; $i -lt $endIndex; $i++) {
                    $visibleProjects += $this._filteredProjects[$i]
                }
            }

            # Render visible project items
            for ($i = 0; $i -lt $maxVisibleItems; $i++) {
                $rowY = $this.Y + $currentRow + $i
                $sb.Append($this.BuildMoveTo($this.X, $rowY))
                $sb.Append($borderColor)
                $sb.Append($this.GetBoxChar('single_vertical'))

                if ($i -lt $visibleProjects.Count) {
                    $projectName = $visibleProjects[$i]
                    $isSelected = ($this._scrollOffset + $i) -eq $this._selectedIndex

                    if ($isSelected) {
                        $sb.Append($highlightBg)
                        $sb.Append("`e[30m")  # Black text on highlighted background
                    } else {
                        $sb.Append($textColor)
                    }

                    # L-POL-8: Show task count after project name
                    $taskCount = $this._GetTaskCountForProject($projectName)
                    $displayName = if ($taskCount -ge 0) {
                        "$projectName ($taskCount)"
                    } else {
                        $projectName
                    }

                    $sb.Append(" ")
                    $sb.Append($this.TruncateText($displayName, $this.Width - 4))
                    $sb.Append($reset)

                    # Padding
                    $textLen = [Math]::Min($projectName.Length, $this.Width - 4)
                    $padding = $this.Width - 3 - $textLen
                    if ($padding -gt 0) {
                        if ($isSelected) {
                            $sb.Append($highlightBg)
                        }
                        $sb.Append(" " * $padding)
                        $sb.Append($reset)
                    }
                } else {
                    # Empty row
                    $sb.Append(" " * ($this.Width - 2))
                }

                $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
                $sb.Append($borderColor)
                $sb.Append($this.GetBoxChar('single_vertical'))
            }

            $currentRow += $maxVisibleItems

            # Help row
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $currentRow))
            $sb.Append($mutedColor)

            if ($this._filteredProjects.Count -eq 0) {
                $sb.Append($this.TruncateText("Alt+N=Create", $this.Width - 4))
            } else {
                $sb.Append($this.TruncateText("Enter=Select | Alt+N=Create", $this.Width - 4))
            }

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++
        }

        # Bottom border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + $this.Height - 1))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'bottom', 'single'))

        # Error message in bottom border
        if (-not [string]::IsNullOrWhiteSpace($this._errorMessage)) {
            $errorMsg = " $($this._errorMessage) "
            $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $this.Height - 1))
            $sb.Append($errorColor)
            $sb.Append($this.TruncateText($errorMsg, $this.Width - 4))
        }

        $sb.Append($reset)
        return $sb.ToString()
    }

    <#
    .SYNOPSIS
    Render directly to engine (optimized path)

    .PARAMETER engine
    RenderEngine instance to write to
    #>
    [void] RenderToEngine([object]$engine) {
        # Colors from theme
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $textColor = $this.GetThemedAnsi('Text', $false)
        $primaryColor = $this.GetThemedAnsi('Primary', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $errorColor = $this.GetThemedAnsi('Error', $false)
        $successColor = $this.GetThemedAnsi('Success', $false)
        $highlightBg = $this.GetThemedAnsi('Primary', $true)
        $reset = "`e[0m"

        # Top border
        $topLine = [StringBuilder]::new(256)
        $topLine.Append($borderColor)
        $topLine.Append($this.BuildBoxBorder($this.Width, 'top', 'single'))
        $topLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y, $topLine.ToString())

        # Title
        $title = if ($this._isCreateMode) { "Create New Project" } else { $this.Label }
        $titlePos = 2
        $engine.WriteAt($this.X + $titlePos, $this.Y, $primaryColor + " $title " + $reset)

        # Project count (if not create mode)
        if (-not $this._isCreateMode) {
            $countText = "($($this._filteredProjects.Count))"
            $engine.WriteAt($this.X + $this.Width - $countText.Length - 2, $this.Y, $mutedColor + $countText + $reset)
        }

        # Content area
        if ($this._isCreateMode) {
            $this._RenderCreateModeToEngine($engine, $borderColor, $textColor, $mutedColor, $reset)
        } else {
            $this._RenderSelectModeToEngine($engine, $borderColor, $textColor, $primaryColor, $mutedColor, $highlightBg, $reset)
        }

        # Bottom border
        $bottomLine = [StringBuilder]::new(256)
        $bottomLine.Append($borderColor)
        $bottomLine.Append($this.BuildBoxBorder($this.Width, 'bottom', 'single'))
        $bottomLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y + $this.Height - 1, $bottomLine.ToString())

        # Error message in bottom border (if present)
        if (-not [string]::IsNullOrWhiteSpace($this._errorMessage)) {
            $errorMsg = " $($this._errorMessage) "
            $engine.WriteAt($this.X + 2, $this.Y + $this.Height - 1, $errorColor + $this.TruncateText($errorMsg, $this.Width - 4) + $reset)
        }
    }

    <#
    .SYNOPSIS
    Render create mode UI to engine

    .PARAMETER engine
    RenderEngine instance

    .PARAMETER borderColor, textColor, mutedColor, reset
    Theme colors
    #>
    hidden [void] _RenderCreateModeToEngine([object]$engine, [string]$borderColor, [string]$textColor, [string]$mutedColor, [string]$reset) {
        $currentRow = 1

        # Input row
        $inputLine = [StringBuilder]::new(256)
        $inputLine.Append($borderColor)
        $inputLine.Append($this.GetBoxChar('single_vertical'))
        $inputLine.Append(" ")

        $innerWidth = $this.Width - 4
        if ([string]::IsNullOrEmpty($this._createText)) {
            $inputLine.Append($mutedColor)
            $inputLine.Append($this.TruncateText("Enter project name...", $innerWidth))
        } else {
            $inputLine.Append($textColor)
            $displayText = $this._createText
            if ($displayText.Length -gt $innerWidth) {
                $displayText = $displayText.Substring(0, $innerWidth)
            }

            # Text before cursor
            if ($this._createCursorPos -gt 0 -and $this._createCursorPos -le $displayText.Length) {
                $inputLine.Append($displayText.Substring(0, $this._createCursorPos))
            }

            # Cursor
            if ($this._createCursorPos -lt $displayText.Length) {
                $inputLine.Append("`e[7m")
                $inputLine.Append($displayText[$this._createCursorPos])
                $inputLine.Append("`e[27m")

                if ($this._createCursorPos + 1 -lt $displayText.Length) {
                    $inputLine.Append($displayText.Substring($this._createCursorPos + 1))
                }
            } elseif ($this._createCursorPos -eq $displayText.Length) {
                $inputLine.Append($displayText)
                $inputLine.Append("`e[7m `e[27m")
            }

            # Padding
            $textLen = $displayText.Length
            $padding = $innerWidth - $textLen - 1
            if ($padding -gt 0) {
                $inputLine.Append(" " * $padding)
            }
        }

        $inputLine.Append(" ")
        $inputLine.Append($borderColor)
        $inputLine.Append($this.GetBoxChar('single_vertical'))
        $inputLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y + $currentRow, $inputLine.ToString())

        $currentRow++

        # Instructions row
        $instLine = [StringBuilder]::new(256)
        $instLine.Append($borderColor)
        $instLine.Append($this.GetBoxChar('single_vertical'))
        $instLine.Append(" ")
        $instLine.Append($mutedColor)
        $instLine.Append($this.TruncateText("Enter=Create | Esc=Cancel", $this.Width - 4))
        $instLine.Append(" ")
        $instLine.Append($borderColor)
        $instLine.Append($this.GetBoxChar('single_vertical'))
        $instLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y + $currentRow, $instLine.ToString())

        $currentRow++

        # Fill remaining rows
        $emptyLine = [StringBuilder]::new(256)
        $emptyLine.Append($borderColor)
        $emptyLine.Append($this.GetBoxChar('single_vertical'))
        $emptyLine.Append(" " * ($this.Width - 2))
        $emptyLine.Append($this.GetBoxChar('single_vertical'))
        $emptyLine.Append($reset)

        for ($i = $currentRow; $i -lt $this.Height - 1; $i++) {
            $engine.WriteAt($this.X, $this.Y + $i, $emptyLine.ToString())
        }
    }

    <#
    .SYNOPSIS
    Render select mode UI to engine

    .PARAMETER engine
    RenderEngine instance

    .PARAMETER borderColor, textColor, primaryColor, mutedColor, highlightBg, reset
    Theme colors
    #>
    hidden [void] _RenderSelectModeToEngine([object]$engine, [string]$borderColor, [string]$textColor, [string]$primaryColor, [string]$mutedColor, [string]$highlightBg, [string]$reset) {
        $currentRow = 1

        # Search filter row
        $searchLine = [StringBuilder]::new(256)
        $searchLine.Append($borderColor)
        $searchLine.Append($this.GetBoxChar('single_vertical'))
        $searchLine.Append(" ")

        if ([string]::IsNullOrWhiteSpace($this._searchText)) {
            $searchLine.Append($mutedColor)
            $searchLine.Append($this.TruncateText("Type to filter...", $this.Width - 4))
        } else {
            $searchLine.Append($primaryColor)
            $searchLine.Append($this.TruncateText($this._searchText, $this.Width - 4))
        }

        $searchLine.Append(" ")
        $searchLine.Append($borderColor)
        $searchLine.Append($this.GetBoxChar('single_vertical'))
        $searchLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y + $currentRow, $searchLine.ToString())

        $currentRow++

        # Project list
        $maxVisibleItems = $this.Height - 4
        $visibleProjects = @()
        if ($this._filteredProjects.Count -gt 0) {
            $endIndex = [Math]::Min($this._scrollOffset + $maxVisibleItems, $this._filteredProjects.Count)
            for ($i = $this._scrollOffset; $i -lt $endIndex; $i++) {
                $visibleProjects += $this._filteredProjects[$i]
            }
        }

        # Render visible project items
        for ($i = 0; $i -lt $maxVisibleItems; $i++) {
            $rowY = $this.Y + $currentRow + $i
            $projectLine = [StringBuilder]::new(256)
            $projectLine.Append($borderColor)
            $projectLine.Append($this.GetBoxChar('single_vertical'))

            if ($i -lt $visibleProjects.Count) {
                $projectName = $visibleProjects[$i]
                $isSelected = ($this._scrollOffset + $i) -eq $this._selectedIndex

                if ($isSelected) {
                    $projectLine.Append($highlightBg)
                    $projectLine.Append("`e[30m")
                } else {
                    $projectLine.Append($textColor)
                }

                # L-POL-8: Show task count after project name
                $taskCount = $this._GetTaskCountForProject($projectName)
                $displayName = if ($taskCount -ge 0) {
                    "$projectName ($taskCount)"
                } else {
                    $projectName
                }

                $projectLine.Append(" ")
                $projectLine.Append($this.TruncateText($displayName, $this.Width - 4))

                # Padding
                $textLen = [Math]::Min($displayName.Length, $this.Width - 4)
                $padding = $this.Width - 3 - $textLen
                if ($padding -gt 0) {
                    $projectLine.Append(" " * $padding)
                }

                $projectLine.Append($reset)
            } else {
                # Empty row
                $projectLine.Append(" " * ($this.Width - 2))
            }

            $projectLine.Append($borderColor)
            $projectLine.Append($this.GetBoxChar('single_vertical'))
            $projectLine.Append($reset)
            $engine.WriteAt($this.X, $rowY, $projectLine.ToString())
        }

        $currentRow += $maxVisibleItems

        # Help row
        $helpLine = [StringBuilder]::new(256)
        $helpLine.Append($borderColor)
        $helpLine.Append($this.GetBoxChar('single_vertical'))
        $helpLine.Append(" ")
        $helpLine.Append($mutedColor)

        if ($this._filteredProjects.Count -eq 0) {
            $helpLine.Append($this.TruncateText("Alt+N=Create", $this.Width - 4))
        } else {
            $helpLine.Append($this.TruncateText("Enter=Select | Alt+N=Create", $this.Width - 4))
        }

        $helpLine.Append(" ")
        $helpLine.Append($borderColor)
        $helpLine.Append($this.GetBoxChar('single_vertical'))
        $helpLine.Append($reset)
        $engine.WriteAt($this.X, $this.Y + $currentRow, $helpLine.ToString())
    }

    # === Private Helper Methods ===

    <#
    .SYNOPSIS
    Load projects from PMC data
    #>
    hidden [void] _LoadProjects() {
        try {
            # Get TaskStore from global container
            $store = $global:Pmc.Container.Resolve('TaskStore')
            $projectsData = $store.GetAllProjects()

            # FIX: Always include "(No Project)" option at the beginning
            $projects = @("(No Project)")

            if ($null -ne $projectsData -and $projectsData.Count -gt 0) {
                foreach ($proj in $projectsData) {
                    if ($null -ne $proj.name -and -not [string]::IsNullOrWhiteSpace($proj.name)) {
                        $projects += $proj.name.ToString()
                    }
                }
            }

            $this._allProjects = $projects
            $this._lastRefresh = [DateTime]::Now
        } catch {
            # Failed to load projects - use "(No Project)" only
            $this._allProjects = @("(No Project)")
        }

        # Apply filter to refresh filtered list
        $this._ApplyFilter()
    }

    <#
    .SYNOPSIS
    Apply fuzzy search filter to project list
    #>
    hidden [void] _ApplyFilter() {
        if ([string]::IsNullOrWhiteSpace($this._searchText)) {
            $this._filteredProjects = $this._allProjects
        } else {
            $searchLower = $this._searchText.ToLower()
            $filtered = @()

            foreach ($project in $this._allProjects) {
                $projectLower = $project.ToLower()

                # Exact substring match
                if ($projectLower.Contains($searchLower)) {
                    $filtered += $project
                    continue
                }

                # Fuzzy match - initials or character sequence
                if ($this._FuzzyMatch($projectLower, $searchLower)) {
                    $filtered += $project
                }
            }

            $this._filteredProjects = $filtered
        }

        # Ensure filtered projects is initialized
        if ($null -eq $this._filteredProjects) {
            $this._filteredProjects = @()
        }

        # Reset selection if out of bounds
        if ($this._selectedIndex -ge $this._filteredProjects.Count) {
            $this._selectedIndex = [Math]::Max(0, $this._filteredProjects.Count - 1)
        }

        $this._AdjustScrollOffset()
    }

    <#
    .SYNOPSIS
    Fuzzy match algorithm - matches initials and subsequences

    .PARAMETER text
    Text to search in (lowercase)

    .PARAMETER pattern
    Pattern to match (lowercase)

    .OUTPUTS
    True if pattern matches text
    #>
    hidden [bool] _FuzzyMatch([string]$text, [string]$pattern) {
        $patternIdx = 0
        $textIdx = 0

        while ($patternIdx -lt $pattern.Length -and $textIdx -lt $text.Length) {
            if ($pattern[$patternIdx] -eq $text[$textIdx]) {
                $patternIdx++
            }
            $textIdx++
        }

        return $patternIdx -eq $pattern.Length
    }

    <#
    .SYNOPSIS
    Move selection up
    #>
    hidden [void] _MoveSelectionUp() {
        if ($this._selectedIndex -gt 0) {
            $this._selectedIndex--
            $this._AdjustScrollOffset()
        }
    }

    <#
    .SYNOPSIS
    Move selection down
    #>
    hidden [void] _MoveSelectionDown() {
        if ($this._selectedIndex -lt ($this._filteredProjects.Count - 1)) {
            $this._selectedIndex++
            $this._AdjustScrollOffset()
        }
    }

    <#
    .SYNOPSIS
    Adjust scroll offset to keep selection visible
    #>
    hidden [void] _AdjustScrollOffset() {
        $maxVisibleItems = $this.Height - 4

        # If selected item is above visible area, scroll up
        if ($this._selectedIndex -lt $this._scrollOffset) {
            $this._scrollOffset = $this._selectedIndex
        }

        # If selected item is below visible area, scroll down
        if ($this._selectedIndex -ge ($this._scrollOffset + $maxVisibleItems)) {
            $this._scrollOffset = $this._selectedIndex - $maxVisibleItems + 1
        }

        # Clamp scroll offset
        if ($this._scrollOffset -lt 0) {
            $this._scrollOffset = 0
        }

        $maxScroll = [Math]::Max(0, $this._filteredProjects.Count - $maxVisibleItems)
        if ($this._scrollOffset -gt $maxScroll) {
            $this._scrollOffset = $maxScroll
        }
    }

    <#
    .SYNOPSIS
    Enter create mode for new project
    #>
    hidden [void] _EnterCreateMode() {
        $this._isCreateMode = $true
        $this._createText = ""
        $this._createCursorPos = 0
        $this._errorMessage = ""
    }

    <#
    .SYNOPSIS
    Handle input in create mode

    .PARAMETER keyInfo
    ConsoleKeyInfo

    .OUTPUTS
    True if handled
    #>
    hidden [bool] _HandleCreateModeInput([ConsoleKeyInfo]$keyInfo) {
        # Enter - create project
        if ($keyInfo.Key -eq 'Enter') {
            $projectName = $this._createText.Trim()

            if ([string]::IsNullOrWhiteSpace($projectName)) {
                $this._errorMessage = "Project name cannot be empty"
                return $true
            }

            # Check for duplicates
            $exists = $false
            foreach ($existing in $this._allProjects) {
                if ($existing.ToLower() -eq $projectName.ToLower()) {
                    $exists = $true
                    break
                }
            }

            if ($exists) {
                $this._errorMessage = "Project already exists"
                return $true
            }

            # Create project in PMC data
            try {
                $data = Get-PmcData
                if ($null -eq $data.projects) {
                    $data | Add-Member -NotePropertyName 'projects' -NotePropertyValue @() -Force
                }

                $newProject = [PSCustomObject]@{
                    name = $projectName
                    description = ""
                    aliases = @()
                    created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }

                $data.projects += $newProject
                Save-PmcData $data

                # Refresh and select new project
                $this._LoadProjects()
                $this._isCreateMode = $false
                $this._createText = ""
                $this._errorMessage = ""

                # Find and select the new project
                for ($i = 0; $i -lt $this._filteredProjects.Count; $i++) {
                    if ($this._filteredProjects[$i] -eq $projectName) {
                        $this._selectedIndex = $i
                        $this._AdjustScrollOffset()
                        break
                    }
                }

                $this.IsConfirmed = $true
                $this._InvokeCallback($this.OnProjectCreated, $projectName)
                $this._InvokeCallback($this.OnProjectSelected, $projectName)

                return $true
            } catch {
                $this._errorMessage = "Failed to create project"
                return $true
            }
        }

        # Escape - cancel create mode
        if ($keyInfo.Key -eq 'Escape') {
            $this._isCreateMode = $false
            $this._createText = ""
            $this._createCursorPos = 0
            $this._errorMessage = ""
            return $true
        }

        # Backspace
        if ($keyInfo.Key -eq 'Backspace') {
            if ($this._createCursorPos -gt 0) {
                $before = $this._createText.Substring(0, $this._createCursorPos - 1)
                $after = if ($this._createCursorPos -lt $this._createText.Length) {
                    $this._createText.Substring($this._createCursorPos)
                } else { "" }
                $this._createText = $before + $after
                $this._createCursorPos--
            }
            return $true
        }

        # Delete
        if ($keyInfo.Key -eq 'Delete') {
            if ($this._createCursorPos -lt $this._createText.Length) {
                $before = $this._createText.Substring(0, $this._createCursorPos)
                $after = if ($this._createCursorPos + 1 -lt $this._createText.Length) {
                    $this._createText.Substring($this._createCursorPos + 1)
                } else { "" }
                $this._createText = $before + $after
            }
            return $true
        }

        # Navigation
        if ($keyInfo.Key -eq 'LeftArrow') {
            if ($this._createCursorPos -gt 0) {
                $this._createCursorPos--
            }
            return $true
        }

        if ($keyInfo.Key -eq 'RightArrow') {
            if ($this._createCursorPos -lt $this._createText.Length) {
                $this._createCursorPos++
            }
            return $true
        }

        if ($keyInfo.Key -eq 'Home') {
            $this._createCursorPos = 0
            return $true
        }

        if ($keyInfo.Key -eq 'End') {
            $this._createCursorPos = $this._createText.Length
            return $true
        }

        # Regular character input
        if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
            $before = $this._createText.Substring(0, $this._createCursorPos)
            $after = if ($this._createCursorPos -lt $this._createText.Length) {
                $this._createText.Substring($this._createCursorPos)
            } else { "" }
            $this._createText = $before + $keyInfo.KeyChar + $after
            $this._createCursorPos++
            return $true
        }

        # Space
        if ($keyInfo.Key -eq 'Spacebar') {
            $before = $this._createText.Substring(0, $this._createCursorPos)
            $after = if ($this._createCursorPos -lt $this._createText.Length) {
                $this._createText.Substring($this._createCursorPos)
            } else { "" }
            $this._createText = $before + ' ' + $after
            $this._createCursorPos++
            return $true
        }

        return $false
    }

    <#
    .SYNOPSIS
    L-POL-8: Get task count for a project

    .PARAMETER projectName
    Name of the project

    .OUTPUTS
    Number of tasks in project, or -1 if count unavailable
    #>
    hidden [int] _GetTaskCountForProject([string]$projectName) {
        try {
            # Get TaskStore from global container
            $store = $global:Pmc.Container.Resolve('TaskStore')
            $allTasks = $store.GetAllTasks()

            if ($null -eq $allTasks) {
                return -1
            }

            $count = 0
            foreach ($task in $allTasks) {
                $taskProject = Get-SafeProperty $task 'project'
                if ($taskProject -eq $projectName -and -not (Get-SafeProperty $task 'completed')) {
                    $count++
                }
            }

            return $count
        } catch {
            # Failed to get count - return -1 to skip displaying count
            return -1
        }
    }

    <#
    .SYNOPSIS
    Invoke a callback scriptblock safely

    .PARAMETER callback
    Scriptblock to invoke

    .PARAMETER args
    Arguments to pass
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $args) {
        if ($null -ne $callback) {
            try {
                if ($null -ne $args) {
                    & $callback $args
                } else {
                    & $callback
                }
            } catch {
                # Callback failed - log but don't crash widget
            }
        }
    }
}
