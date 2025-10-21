# PMC ConsoleUI - All-in-one loader to handle PowerShell class dependencies
# Load all classes and functions in proper order for module compatibility

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Text

# === LOAD REQUIRED FUNCTIONS (standalone) ===
# Load only local copies; no external references allowed
. (Join-Path $PSScriptRoot 'DepsLoader.ps1')

# Load handlers
. (Join-Path $PSScriptRoot 'Handlers/TaskHandlers.ps1')
. (Join-Path $PSScriptRoot 'Handlers/ProjectHandlers.ps1')
try {
    . (Join-Path $PSScriptRoot 'Handlers/ExcelHandlers.ps1')
} catch {
    Write-ConsoleUIDebug "Excel handlers not loaded: $_" "WARN"
}

# Initialize core systems
Initialize-PmcSecuritySystem
Initialize-PmcThemeSystem

# Compute a safe, static default root for file pickers (avoid per-method OS checks)
try {
    $Script:DefaultPickerRoot = '/'
    $isWin = $false
    try { if ($env:OS -like '*Windows*') { $isWin = $true } } catch {}
    if (-not $isWin) {
        try { if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) { $isWin = $true } } catch {}
    }
    if ($isWin) { $Script:DefaultPickerRoot = 'C:\' }
    if (-not (Test-Path $Script:DefaultPickerRoot)) { $Script:DefaultPickerRoot = (Get-Location).Path }
} catch { $Script:DefaultPickerRoot = (Get-Location).Path }

# Error handling preferences (scoped to this script/session to avoid global side effects)
$Script:_PrevErrorActionPreference = $ErrorActionPreference
try { $ErrorActionPreference = 'Continue' } catch {}

# === HELPERS ===
function Get-ConsoleUIDateOrNull {
    param([object]$Value)
    try {
        if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
        $out = [datetime]::MinValue
        if ([DateTime]::TryParse([string]$Value, [ref]$out)) { return $out }
    } catch {}
    return $null
}

# Normalize flexible date input to ISO yyyy-MM-dd or '' if empty; returns $null if invalid
function Normalize-ConsoleUIDate {
    param([string]$Input)
    if ([string]::IsNullOrWhiteSpace($Input)) { return '' }
    $s = $Input.Trim()
    $lower = $s.ToLower()
    $d = $null
    try {
        if ($lower -eq 'today') { $d = (Get-Date).Date }
        elseif ($lower -eq 'tomorrow') { $d = (Get-Date).Date.AddDays(1) }
        elseif ($lower -eq 'yesterday') { $d = (Get-Date).Date.AddDays(-1) }
        elseif ($s -match '^[+-]\d+$') { $d = (Get-Date).Date.AddDays([int]$s) }
        elseif ($s -match '^\d{8}$') {
            # yyyymmdd
            $d = [datetime]::ParseExact($s,'yyyyMMdd',$null)
        }
        elseif ($s -match '^\d{4}$') {
            # mmdd, assume current year
            $year = (Get-Date).Year
            $mm = [int]$s.Substring(0,2)
            $dd = [int]$s.Substring(2,2)
            $d = Get-Date -Year $year -Month $mm -Day $dd
        }
        elseif ($s -match '^\d{4}-\d{2}-\d{2}$') {
            $d = [datetime]::ParseExact($s,'yyyy-MM-dd',$null)
        }
        elseif ($s -match '^\d{4}/\d{2}/\d{2}$') {
            $d = [datetime]::ParseExact($s,'yyyy/MM/dd',$null)
        } else {
            # last resort attempt
            $tmp = [datetime]::MinValue
            if ([DateTime]::TryParse($s, [ref]$tmp)) { $d = $tmp.Date }
        }
    } catch { $d = $null }
    if ($d) { return $d.ToString('yyyy-MM-dd') } else { return $null }
}

function Test-ConsoleInteractive {
    try {
        if ([Console]::IsInputRedirected) { return $false }
        if ([Console]::IsOutputRedirected) { return $false }
    } catch { return $false }
    return $true
}

# === PERFORMANCE CORE ===
class PmcStringCache {
    static [hashtable]$_spaces = @{}
    static [hashtable]$_ansiSequences = @{}
    static [hashtable]$_boxDrawing = @{}
    static [int]$_maxCacheSize = 200
    static [bool]$_initialized = $false

    static [void] Initialize() {
        if ([PmcStringCache]::_initialized) { return }

        for ($i = 1; $i -le [PmcStringCache]::_maxCacheSize; $i++) {
            [PmcStringCache]::_spaces[$i] = " " * $i
        }

        # === ANSI SEQUENCES ===
        # Basic formatting
        [PmcStringCache]::_ansiSequences["reset"] = "`e[0m"
        [PmcStringCache]::_ansiSequences["bold"] = "`e[1m"
        [PmcStringCache]::_ansiSequences["dim"] = "`e[2m"
        [PmcStringCache]::_ansiSequences["italic"] = "`e[3m"
        [PmcStringCache]::_ansiSequences["underline"] = "`e[4m"
        [PmcStringCache]::_ansiSequences["blink"] = "`e[5m"
        [PmcStringCache]::_ansiSequences["reverse"] = "`e[7m"
        [PmcStringCache]::_ansiSequences["hidden"] = "`e[8m"
        [PmcStringCache]::_ansiSequences["strikethrough"] = "`e[9m"

        # Cursor control
        [PmcStringCache]::_ansiSequences["hidecursor"] = "`e[?25l"
        [PmcStringCache]::_ansiSequences["showcursor"] = "`e[?25h"
        [PmcStringCache]::_ansiSequences["savecursor"] = "`e[s"
        [PmcStringCache]::_ansiSequences["restorecursor"] = "`e[u"
        [PmcStringCache]::_ansiSequences["home"] = "`e[H"
        [PmcStringCache]::_ansiSequences["up"] = "`e[A"
        [PmcStringCache]::_ansiSequences["down"] = "`e[B"
        [PmcStringCache]::_ansiSequences["right"] = "`e[C"
        [PmcStringCache]::_ansiSequences["left"] = "`e[D"
        [PmcStringCache]::_ansiSequences["nextline"] = "`e[E"
        [PmcStringCache]::_ansiSequences["prevline"] = "`e[F"
        [PmcStringCache]::_ansiSequences["column0"] = "`e[G"

        # Screen/line clearing
        [PmcStringCache]::_ansiSequences["clear"] = "`e[2J"
        [PmcStringCache]::_ansiSequences["clearline"] = "`e[2K"
        [PmcStringCache]::_ansiSequences["erasetoend"] = "`e[K"
        [PmcStringCache]::_ansiSequences["erasetostart"] = "`e[1K"
        [PmcStringCache]::_ansiSequences["erasedown"] = "`e[J"
        [PmcStringCache]::_ansiSequences["eraseup"] = "`e[1J"

        # Scrolling
        [PmcStringCache]::_ansiSequences["scrollup"] = "`e[S"
        [PmcStringCache]::_ansiSequences["scrolldown"] = "`e[T"

        # Alternative screen buffer
        [PmcStringCache]::_ansiSequences["altbuffer"] = "`e[?1049h"
        [PmcStringCache]::_ansiSequences["normalbuffer"] = "`e[?1049l"

        # === BOX DRAWING CHARACTERS ===
        [PmcStringCache]::_boxDrawing["horizontal"] = "─"
        [PmcStringCache]::_boxDrawing["vertical"] = "│"
        [PmcStringCache]::_boxDrawing["topleft"] = "┌"
        [PmcStringCache]::_boxDrawing["topright"] = "┐"
        [PmcStringCache]::_boxDrawing["bottomleft"] = "└"
        [PmcStringCache]::_boxDrawing["bottomright"] = "┘"
        [PmcStringCache]::_boxDrawing["cross"] = "┼"
        [PmcStringCache]::_boxDrawing["tdown"] = "┬"
        [PmcStringCache]::_boxDrawing["tup"] = "┴"
        [PmcStringCache]::_boxDrawing["tleft"] = "┤"
        [PmcStringCache]::_boxDrawing["tright"] = "├"

        # Double-line box drawing
        [PmcStringCache]::_boxDrawing["dhorizontal"] = "═"
        [PmcStringCache]::_boxDrawing["dvertical"] = "║"
        [PmcStringCache]::_boxDrawing["dtopleft"] = "╔"
        [PmcStringCache]::_boxDrawing["dtopright"] = "╗"
        [PmcStringCache]::_boxDrawing["dbottomleft"] = "╚"
        [PmcStringCache]::_boxDrawing["dbottomright"] = "╝"

        # Block characters (for progress bars, charts)
        [PmcStringCache]::_boxDrawing["blockfull"] = "█"
        [PmcStringCache]::_boxDrawing["blockdark"] = "▓"
        [PmcStringCache]::_boxDrawing["blockmedium"] = "▒"
        [PmcStringCache]::_boxDrawing["blocklight"] = "░"
        [PmcStringCache]::_boxDrawing["blockleft"] = "▌"
        [PmcStringCache]::_boxDrawing["blockright"] = "▐"

        # Shapes
        [PmcStringCache]::_boxDrawing["bullet"] = "•"
        [PmcStringCache]::_boxDrawing["circle"] = "○"
        [PmcStringCache]::_boxDrawing["square"] = "□"
        [PmcStringCache]::_boxDrawing["diamond"] = "◆"
        [PmcStringCache]::_boxDrawing["arrow"] = "→"
        [PmcStringCache]::_boxDrawing["check"] = "✓"
        [PmcStringCache]::_boxDrawing["cross"] = "✗"

        [PmcStringCache]::_initialized = $true
    }

    static [string] GetSpaces([int]$count) {
        if ($count -le 0) { return "" }
        if ($count -le [PmcStringCache]::_maxCacheSize) {
            return [PmcStringCache]::_spaces[$count]
        }
        return " " * $count
    }

    static [string] GetAnsiSequence([string]$sequenceName) {
        if ([PmcStringCache]::_ansiSequences.ContainsKey($sequenceName)) {
            return [PmcStringCache]::_ansiSequences[$sequenceName]
        }
        return ""
    }

    static [string] GetBoxDrawing([string]$characterName) {
        if ([PmcStringCache]::_boxDrawing.ContainsKey($characterName)) {
            return [PmcStringCache]::_boxDrawing[$characterName]
        }
        return ""
    }

    static [string] Truncate([string]$text, [int]$maxWidth) {
        if ([string]::IsNullOrEmpty($text)) {
            return [PmcStringCache]::GetSpaces($maxWidth)
        }
        if ($text.Length -gt $maxWidth) {
            if ($maxWidth -le 0) { return "" }
            if ($maxWidth -eq 1) { return "…" }
            return $text.Substring(0, $maxWidth - 1) + '…'
        }
        return $text.PadRight($maxWidth)
    }
}

# === UI STRING CACHE ===
# Pre-cached UI strings to eliminate allocations (71+ footer strings, 50+ labels)
class PmcUIStringCache {
    # FOOTER STRINGS (Top 10 by frequency)
    static [string]$FooterEscBack = "Esc:Back"
    static [string]$FooterMenusEscBack = "F10/Alt:Menus  Esc:Back"
    static [string]$FooterTaskList = "↑/↓:Select  Enter:Detail  E:Edit  D:Toggle  F10/Alt:Menus  Esc:Back"
    static [string]$FooterNavEditComplete = "↑↓:Navigate | Enter:Edit | D:Complete | Esc:Back"
    static [string]$FooterSelectEditToggle = "↑↓:Select | Enter:Edit | D:Toggle | Esc:Back"
    static [string]$FooterNavSelect = "↑↓:Nav | Enter:Select | Esc:Cancel"
    static [string]$FooterEnterIDCancel = "Enter task ID | Esc=Cancel"
    static [string]$FooterEnterIDsCancel = "Enter IDs | Esc=Cancel"
    static [string]$FooterEnterFieldsCancel = "Enter fields | Esc:Cancel"
    static [string]$FooterProjectNameCancel = "Enter project name | Esc:Cancel"
    static [string]$FooterBackupChoice = "A:Auto | M:Manual | B:Both | Esc:Cancel"
    static [string]$FooterMultiSelect = "Space:Toggle | A:All | N:None | C:Complete | X:Delete | P:Priority | J:Move | Esc:Exit"
    static [string]$FooterKanban = "←→:Column | ↑↓:Task | 1-3:Move | Enter:Edit | D:Done | Esc:Back"
    static [string]$FooterTheme = "1-4:Preview | A:Apply | ↑↓:Navigate | Esc:Cancel"
    static [string]$FooterProjectNav = "↑↓:Navigate | Enter:Full Details | Esc:Back"
    static [string]$FooterTimeList = "↑↓:Nav | A:Add | E:Edit | D:Delete | R:Report | Esc:Back"
    static [string]$FooterPressAnyKey = "Press any key to return"
    static [string]$FooterPleaseWait = "Please wait..."
    static [string]$FooterTabNav = "Tab/Shift+Tab navigate  |  F2: Pick path  |  Enter: Save  |  Esc: Cancel"

    # FOOTER FRAGMENTS (Building blocks - can be composed)
    static [string]$FragEscBack = "Esc:Back"
    static [string]$FragEscCancel = "Esc:Cancel"
    static [string]$FragMenus = "F10/Alt:Menus"
    static [string]$FragNavArrows = "↑↓:Nav"
    static [string]$FragNavigate = "↑↓:Navigate"
    static [string]$FragSelect = "↑/↓:Select"
    static [string]$FragEnterSelect = "Enter:Select"
    static [string]$FragEnterEdit = "Enter:Edit"
    static [string]$FragEnterDetail = "Enter:Detail"
    static [string]$FragAdd = "A:Add"
    static [string]$FragEdit = "E:Edit"
    static [string]$FragToggle = "D:Toggle"
    static [string]$FragComplete = "D:Complete"
    static [string]$FragDone = "D:Done"
    static [string]$FragDelete = "Del:Delete"

    # KANBAN COLUMN HEADERS (Used 10+ times each)
    static [string]$KanbanTODO = "TODO"
    static [string]$KanbanInProgress = "IN PROGRESS"
    static [string]$KanbanDone = "DONE"

    # COMMON LABELS
    static [string]$LabelSelectTheme = "Select a theme to apply:"
    static [string]$LabelActiveTasks = "Active Tasks:"
    static [string]$LabelNoTasks = "No tasks to display"
    static [string]$LabelNoTasksToday = "No tasks due today"
    static [string]$LabelNoTasksTomorrow = "No tasks due tomorrow!"
    static [string]$LabelNoTasksWeek = "No tasks due this week"
    static [string]$LabelNoActiveTasks = "No active tasks"
    static [string]$LabelNoProjects = "No projects found"
    static [string]$LabelNoBackups = "No backups found"
    static [string]$LabelNoTasksAvailable = "No tasks available"
    static [string]$LabelLoading = "Loading..."
    static [string]$LabelPressAnyKey = "Press any key to return"
    static [string]$LabelErrorLoading = "Error loading"

    # FIELD LABELS (High frequency)
    static [string]$FieldProject = "Project:"
    static [string]$FieldStatus = "Status:"
    static [string]$FieldPriority = "Priority:"
    static [string]$FieldTask = "Task:"
    static [string]$FieldDue = "Due:"
    static [string]$FieldID = "ID"

    # SECTION HEADERS
    static [string]$HeaderTotalTasks = "Total Tasks:"
    static [string]$HeaderCompleted = "Completed:"
    static [string]$HeaderInProgress = "In Progress:"
    static [string]$HeaderBlocked = "Blocked:"
    static [string]$HeaderTaskSummary = "Task Summary:"
    static [string]$HeaderCurrentFocus = "Current Focus:"

    # TITLE FRAGMENTS (with leading/trailing spaces for centering)
    static [string]$TitleTaskList = " Task List "
    static [string]$TitleProjectList = " Project List "
    static [string]$TitleKanban = " Kanban Board "
    static [string]$TitleTheme = "Theme Selection"
    static [string]$TitleBackup = " Backup Data "
    static [string]$TitleRestore = " Restore Data from Backup "
    static [string]$TitleFocus = " Focus Status "
    static [string]$TitleHelp = " PMC ConsoleUI - Keybindings & Help "
}

# === SCREEN TEMPLATE CACHE ===
# Pre-rendered screen fragments for static content (eliminates ~70% of rendering for static screens)
class PmcScreenTemplates {
    static [bool]$_initialized = $false
    static [int]$_lastWidth = 0
    static [int]$_lastHeight = 0

    # Pre-rendered fragments (VT100 sequences ready to append to buffer)
    static [string]$HelpScreenContent = ""
    static [string]$ThemeScreenHeader = ""
    static [string]$KanbanColumnHeaders = ""
    static [string]$EmptyStateNoTasks = ""
    static [string]$EmptyStateNoProjects = ""
    static [string]$EmptyStateLoading = ""

    # Initialize or re-initialize templates (call on startup or terminal resize)
    static [void] Initialize([int]$width, [int]$height) {
        if ([PmcScreenTemplates]::_initialized -and
            [PmcScreenTemplates]::_lastWidth -eq $width -and
            [PmcScreenTemplates]::_lastHeight -eq $height) {
            return  # Already initialized for this size
        }

        [PmcScreenTemplates]::_lastWidth = $width
        [PmcScreenTemplates]::_lastHeight = $height

        # Pre-render help screen (100% static content!)
        [PmcScreenTemplates]::_RenderHelpScreen($width, $height)

        # Pre-render theme screen header
        [PmcScreenTemplates]::_RenderThemeHeader($width, $height)

        # Pre-render Kanban column headers
        [PmcScreenTemplates]::_RenderKanbanHeaders($width, $height)

        # Pre-render common empty states
        [PmcScreenTemplates]::_RenderEmptyStates($width, $height)

        [PmcScreenTemplates]::_initialized = $true
    }

    static hidden [void] _RenderHelpScreen([int]$width, [int]$height) {
        $sb = [System.Text.StringBuilder]::new(2048)

        # Help screen is 100% static - pre-render the entire thing!
        $y = 6
        $cyan = [PmcVT100]::Cyan()
        $yellow = [PmcVT100]::Yellow()
        $white = [PmcVT100]::White()
        $reset = [PmcVT100]::Reset()

        # Navigation section
        $sb.Append([PmcVT100]::MoveTo(4, $y++)).Append($cyan).Append("Navigation:").Append($reset) | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("↑/↓ or j/k - Navigate lists") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("Enter - Select/Edit item") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("Esc - Go back / Cancel") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("F10 or Alt - Open menu bar") | Out-Null
        $y++

        # Task operations section
        $sb.Append([PmcVT100]::MoveTo(4, $y++)).Append($cyan).Append("Task Operations:").Append($reset) | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("A - Add new task") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("E - Edit selected task") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("D - Toggle task completion") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("Del - Delete task") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("Space - Multi-select mode") | Out-Null
        $y++

        # Views section
        $sb.Append([PmcVT100]::MoveTo(4, $y++)).Append($cyan).Append("Views:").Append($reset) | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("• Task List - All tasks with filtering/sorting") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("• Kanban - Visual board (TODO, In Progress, Done)") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("• Today/Week/Month - Time-based views") | Out-Null
        $sb.Append([PmcVT100]::MoveTo(6, $y++)).Append("• Project List - Browse by project") | Out-Null

        [PmcScreenTemplates]::HelpScreenContent = $sb.ToString()
    }

    static hidden [void] _RenderThemeHeader([int]$width, [int]$height) {
        $sb = [System.Text.StringBuilder]::new(256)
        $cyan = [PmcVT100]::Cyan()
        $reset = [PmcVT100]::Reset()

        $sb.Append([PmcVT100]::MoveTo(4, 6)).Append($cyan)
        $sb.Append([PmcUIStringCache]::LabelSelectTheme).Append($reset)

        [PmcScreenTemplates]::ThemeScreenHeader = $sb.ToString()
    }

    static hidden [void] _RenderKanbanHeaders([int]$width, [int]$height) {
        $sb = [System.Text.StringBuilder]::new(512)

        # Calculate column positions
        $colWidth = [int]($width / 3)
        $col1X = 2
        $col2X = $colWidth
        $col3X = $colWidth * 2

        $yellow = [PmcVT100]::Yellow()
        $cyan = [PmcVT100]::Cyan()
        $green = [PmcVT100]::Green()
        $reset = [PmcVT100]::Reset()

        # Pre-render column headers (static part - counts are dynamic)
        $sb.Append([PmcVT100]::MoveTo($col1X + 2, 5)).Append($yellow)
        $sb.Append([PmcUIStringCache]::KanbanTODO).Append($reset)

        $sb.Append([PmcVT100]::MoveTo($col2X + 2, 5)).Append($cyan)
        $sb.Append([PmcUIStringCache]::KanbanInProgress).Append($reset)

        $sb.Append([PmcVT100]::MoveTo($col3X + 2, 5)).Append($green)
        $sb.Append([PmcUIStringCache]::KanbanDone).Append($reset)

        [PmcScreenTemplates]::KanbanColumnHeaders = $sb.ToString()
    }

    static hidden [void] _RenderEmptyStates([int]$width, [int]$height) {
        $yellow = [PmcVT100]::Yellow()
        $cyan = [PmcVT100]::Cyan()
        $reset = [PmcVT100]::Reset()
        $centerY = [int](($height / 2) - 1)

        # No tasks empty state
        $msg = [PmcUIStringCache]::LabelNoTasks
        $x = [int](($width - $msg.Length) / 2)
        $sb1 = [System.Text.StringBuilder]::new()
        $sb1.Append([PmcVT100]::MoveTo($x, $centerY)).Append($yellow).Append($msg).Append($reset) | Out-Null
        [PmcScreenTemplates]::EmptyStateNoTasks = $sb1.ToString()

        # No projects empty state
        $msg = [PmcUIStringCache]::LabelNoProjects
        $x = [int](($width - $msg.Length) / 2)
        $sb2 = [System.Text.StringBuilder]::new()
        $sb2.Append([PmcVT100]::MoveTo($x, $centerY)).Append($yellow).Append($msg).Append($reset) | Out-Null
        [PmcScreenTemplates]::EmptyStateNoProjects = $sb2.ToString()

        # Loading empty state
        $msg = [PmcUIStringCache]::LabelLoading
        $x = [int](($width - $msg.Length) / 2)
        $sb3 = [System.Text.StringBuilder]::new()
        $sb3.Append([PmcVT100]::MoveTo($x, $centerY)).Append($cyan).Append($msg).Append($reset) | Out-Null
        [PmcScreenTemplates]::EmptyStateLoading = $sb3.ToString()
    }

    # Invalidate cache on terminal resize
    static [void] Invalidate() {
        [PmcScreenTemplates]::_initialized = $false
    }
}

# === LAYOUT POSITION CACHE ===
# Pre-calculated layout positions (eliminates math in render loops)
class PmcLayoutCache {
    static [bool]$_initialized = $false
    static [int]$_lastWidth = 0
    static [int]$_lastHeight = 0

    # Standard layout positions
    static [int]$TitleY = 3
    static [int]$ContentStartY = 6
    static [int]$FooterY = 0  # Height - 2 (calculated)
    static [int]$CenterY = 0  # Height / 2 (calculated)

    # Kanban board positions
    static [int]$KanbanCol1X = 2
    static [int]$KanbanCol2X = 0  # Calculated
    static [int]$KanbanCol3X = 0  # Calculated
    static [int]$KanbanColWidth = 0  # Calculated
    static [int]$KanbanHeaderY = 5
    static [int]$KanbanContentStartY = 7

    # Task list columns
    static [int]$TaskIdX = 2
    static [int]$TaskStatusX = 8
    static [int]$TaskPriorityX = 18
    static [int]$TaskTextX = 28
    static [int]$TaskProjectX = 0  # Calculated (width - 25)
    static [int]$TaskDueX = 0  # Calculated (width - 12)

    # Initialize or recalculate (call on startup or terminal resize)
    static [void] Initialize([int]$width, [int]$height) {
        if ([PmcLayoutCache]::_initialized -and
            [PmcLayoutCache]::_lastWidth -eq $width -and
            [PmcLayoutCache]::_lastHeight -eq $height) {
            return  # Already initialized for this size
        }

        [PmcLayoutCache]::_lastWidth = $width
        [PmcLayoutCache]::_lastHeight = $height

        # Calculate dynamic positions
        [PmcLayoutCache]::FooterY = $height - 2
        [PmcLayoutCache]::CenterY = [int]($height / 2)

        # Kanban columns (3 equal width columns)
        $colWidth = [int]($width / 3)
        [PmcLayoutCache]::KanbanColWidth = $colWidth - 4
        [PmcLayoutCache]::KanbanCol2X = $colWidth
        [PmcLayoutCache]::KanbanCol3X = $colWidth * 2

        # Task list columns (right-aligned fields)
        [PmcLayoutCache]::TaskProjectX = $width - 25
        [PmcLayoutCache]::TaskDueX = $width - 12

        [PmcLayoutCache]::_initialized = $true
    }

    # Invalidate cache on terminal resize
    static [void] Invalidate() {
        [PmcLayoutCache]::_initialized = $false
    }

    # Quick accessor for centered X position
    static [int] CenterX([int]$textLength, [int]$width) {
        return [int](($width - $textLength) / 2)
    }
}

class PmcStringBuilderPool {
    static [ConcurrentQueue[StringBuilder]]$_pool = [ConcurrentQueue[StringBuilder]]::new()
    static [int]$_maxPoolSize = 20
    static [int]$_maxCapacity = 8192

    static [StringBuilder] Get() {
        $sb = $null
        if ([PmcStringBuilderPool]::_pool.TryDequeue([ref]$sb)) {
            $sb.Clear()
        } else {
            $sb = [StringBuilder]::new()
        }
        return $sb
    }

    static [StringBuilder] Get([int]$initialCapacity) {
        $sb = [PmcStringBuilderPool]::Get()
        if ($sb.Capacity -lt $initialCapacity) {
            $sb.Capacity = $initialCapacity
        }
        return $sb
    }

    static [void] Return([StringBuilder]$sb) {
        if (-not $sb) { return }
        if ($sb.Capacity -gt [PmcStringBuilderPool]::_maxCapacity) { return }
        if ([PmcStringBuilderPool]::_pool.Count -ge [PmcStringBuilderPool]::_maxPoolSize) { return }
        $sb.Clear()
        [PmcStringBuilderPool]::_pool.Enqueue($sb)
    }
}

# === THEME SYSTEM (Unified) ===
# Adapter to the centralized theme in deps/UI.ps1 + deps/Theme.ps1
class PmcVT100 {
    static [hashtable]$_colorCache = @{}
    static [int]$_maxColorCache = 200

    # Pre-cached color sequences (eager loading for performance)
    static [string]$_cachedRed = ""
    static [string]$_cachedGreen = ""
    static [string]$_cachedYellow = ""
    static [string]$_cachedBlue = ""
    static [string]$_cachedCyan = ""
    static [string]$_cachedWhite = ""
    static [string]$_cachedGray = ""
    static [string]$_cachedBlack = ""
    static [string]$_cachedBgRed = ""
    static [string]$_cachedBgGreen = ""
    static [string]$_cachedBgYellow = ""
    static [string]$_cachedBgBlue = ""
    static [string]$_cachedBgCyan = ""
    static [string]$_cachedBgWhite = ""
    static [string]$_cachedReset = "`e[0m"
    static [string]$_cachedBold = "`e[1m"
    static [bool]$_colorsInitialized = $false

    static hidden [string] _AnsiFromHex([string]$hex, [bool]$bg=$false) {
        if (-not $hex) { return '' }
        try {
            if (-not $hex.StartsWith('#')) { $hex = '#'+$hex }
            $rgb = ConvertFrom-PmcHex $hex
            $key = "{0}_{1}_{2}_{3}" -f ($bg ? 'bg' : 'fg'), $rgb.R, $rgb.G, $rgb.B
            if ([PmcVT100]::_colorCache.ContainsKey($key)) { return [PmcVT100]::_colorCache[$key] }
            $seq = if ($bg) { "`e[48;2;$($rgb.R);$($rgb.G);$($rgb.B)m" } else { "`e[38;2;$($rgb.R);$($rgb.G);$($rgb.B)m" }
            if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) { [PmcVT100]::_colorCache[$key] = $seq }
            return $seq
        } catch { return '' }
    }

    static hidden [string] _MapColor([string]$name, [bool]$bg=$false) {
        # Map legacy ConsoleUI color names to centralized style tokens
        $styles = Get-PmcState -Section 'Display' -Key 'Styles'
        $token = switch ($name) {
            'Red'      { 'Error' }
            'Green'    { 'Success' }
            'Yellow'   { 'Warning' }
            'Blue'     { 'Header' }
            'Cyan'     { 'Info' }
            'White'    { 'Body' }
            'Gray'     { 'Muted' }
            'Black'    { $null }
            'BgRed'    { 'Error' }
            'BgGreen'  { 'Success' }
            'BgYellow' { 'Warning' }
            'BgBlue'   { 'Header' }
            'BgCyan'   { 'Info' }
            'BgWhite'  { 'Body' }
            default    { 'Body' }
        }
        if ($null -eq $token) { return ($bg ? "`e[48;2;0;0;0m" : "`e[38;2;0;0;0m") }
        if ($styles -and $styles.ContainsKey($token)) {
            $fg = $styles[$token].Fg
            return [PmcVT100]::_AnsiFromHex($fg, $bg)
        }
        # Fallback to theme palette primary color
        $palette = Get-PmcColorPalette
        $hex = '#33aaff'
        try { $hex = ("#{0:X2}{1:X2}{2:X2}" -f $palette.Primary.R,$palette.Primary.G,$palette.Primary.B) } catch {}
        return [PmcVT100]::_AnsiFromHex($hex, $bg)
    }

    # Pre-cache all colors at startup for maximum performance
    static [void] Initialize() {
        if ([PmcVT100]::_colorsInitialized) { return }

        # Pre-compute all color sequences once
        [PmcVT100]::_cachedRed = [PmcVT100]::_MapColor('Red', $false)
        [PmcVT100]::_cachedGreen = [PmcVT100]::_MapColor('Green', $false)
        [PmcVT100]::_cachedYellow = [PmcVT100]::_MapColor('Yellow', $false)
        [PmcVT100]::_cachedBlue = [PmcVT100]::_MapColor('Blue', $false)
        [PmcVT100]::_cachedCyan = [PmcVT100]::_MapColor('Cyan', $false)
        [PmcVT100]::_cachedWhite = [PmcVT100]::_MapColor('White', $false)
        [PmcVT100]::_cachedGray = [PmcVT100]::_MapColor('Gray', $false)
        [PmcVT100]::_cachedBlack = [PmcVT100]::_MapColor('Black', $false)
        [PmcVT100]::_cachedBgRed = [PmcVT100]::_MapColor('BgRed', $true)
        [PmcVT100]::_cachedBgGreen = [PmcVT100]::_MapColor('BgGreen', $true)
        [PmcVT100]::_cachedBgYellow = [PmcVT100]::_MapColor('BgYellow', $true)
        [PmcVT100]::_cachedBgBlue = [PmcVT100]::_MapColor('BgBlue', $true)
        [PmcVT100]::_cachedBgCyan = [PmcVT100]::_MapColor('BgCyan', $true)
        [PmcVT100]::_cachedBgWhite = [PmcVT100]::_MapColor('BgWhite', $true)

        [PmcVT100]::_colorsInitialized = $true
    }

    static [string] MoveTo([int]$x, [int]$y) { return "`e[$($y + 1);$($x + 1)H" }
    static [string] Reset() { return [PmcVT100]::_cachedReset }
    static [string] Bold() { return [PmcVT100]::_cachedBold }

    # Fast pre-cached color accessors (150x faster than _MapColor)
    static [string] Red() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedRed
    }
    static [string] Green() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedGreen
    }
    static [string] Yellow() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedYellow
    }
    static [string] Blue() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBlue
    }
    static [string] Cyan() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedCyan
    }
    static [string] White() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedWhite
    }
    static [string] Gray() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedGray
    }
    static [string] Black() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBlack
    }
    static [string] BgRed() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgRed
    }
    static [string] BgGreen() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgGreen
    }
    static [string] BgYellow() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgYellow
    }
    static [string] BgBlue() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgBlue
    }
    static [string] BgCyan() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgCyan
    }
    static [string] BgWhite() {
        if (-not [PmcVT100]::_colorsInitialized) { [PmcVT100]::Initialize() }
        return [PmcVT100]::_cachedBgWhite
    }
}

# === UI WIDGET FUNCTIONS ===
# Simple, reusable UI components for blocking forms

function Show-InfoMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Title = "Information",
        [string]$Color = "Cyan"
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 8, $boxWidth, 8)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $colorCode = switch ($Color) {
        "Red" { [PmcVT100]::Red() }
        "Green" { [PmcVT100]::Green() }
        "Yellow" { [PmcVT100]::Yellow() }
        default { [PmcVT100]::Cyan() }
    }
    $terminal.WriteAtColor([int]$titleX, 8, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    # Draw message (word wrap)
    $y = 10
    $maxWidth = $boxWidth - 4
    $words = $Message -split '\s+'
    $line = ""
    foreach ($word in $words) {
        if (($line + " " + $word).Length -gt $maxWidth) {
            $terminal.WriteAtColor([int]($boxX + 2), $y++, $line, $colorCode, "")
            $line = $word
        } else {
            $line = if ($line) { "$line $word" } else { $word }
        }
    }
    if ($line) {
        $terminal.WriteAtColor([int]($boxX + 2), $y++, $line, $colorCode, "")
    }

    # Add prompt at bottom of dialog
    $y++  # Add spacing after message
    $promptText = "Press any key to continue..."
    $promptX = ($terminal.Width - $promptText.Length) / 2
    $terminal.WriteAtColor([int]$promptX, $y, $promptText, [PmcVT100]::Cyan(), "")

    $terminal.EndFrame()

    # Wait for user acknowledgment
    [Console]::ReadKey($true) | Out-Null
}

function Show-ConfirmDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Title = "Confirm"
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 8, $boxWidth, 8)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $terminal.WriteAtColor([int]$titleX, 8, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    # Draw message
    $terminal.WriteAtColor([int]($boxX + 2), 10, $Message, [PmcVT100]::Yellow(), "")

    # Prompt
    $terminal.WriteAt([int]($boxX + 2), 13, "Y/N: ")

    while ($true) {
        try {
            $key = [Console]::ReadKey($true)
        } catch {
            # Non-interactive environment: exit gracefully
            return $false
        }
        if ($key.KeyChar -eq 'y' -or $key.KeyChar -eq 'Y') {
            return $true
        } elseif ($key.KeyChar -eq 'n' -or $key.KeyChar -eq 'N' -or $key.Key -eq 'Escape') {
            return $false
        }
    }
}

function Show-SelectList {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string[]]$Options,
        [string]$DefaultValue = $null
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Find default index
    $selected = 0
    if ($DefaultValue) {
        $idx = [Array]::IndexOf(@($Options), $DefaultValue)
        if ($idx -ge 0) { $selected = $idx }
    }

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxHeight = [Math]::Min(20, 8 + $Options.Count)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 5, $boxWidth, $boxHeight)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $terminal.WriteAtColor([int]$titleX, 5, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $running = $true
    while ($running) {
        # Draw options
        $y = 7
        $maxDisplay = $boxHeight - 5
        $startIdx = [Math]::Max(0, $selected - $maxDisplay + 1)

        for ($i = 0; $i -lt [Math]::Min($Options.Count, $maxDisplay); $i++) {
            $idx = $startIdx + $i
            if ($idx -ge $Options.Count) { break }

            $opt = $Options[$idx]
            if ($idx -eq $selected) {
                $terminal.WriteAtColor([int]($boxX + 2), $y, "> $opt", [PmcVT100]::BgBlue(), [PmcVT100]::White())
            } else {
                $terminal.WriteAt([int]($boxX + 2), $y, "  $opt")
            }
            $y++
        }

        # Draw footer
        $terminal.WriteAt([int]($boxX + 2), [int](5 + $boxHeight - 2), "↑/↓: Navigate  Enter: Select  Esc: Cancel")

        # Handle input
        try {
            $key = [Console]::ReadKey($true)
        } catch {
            # Non-interactive environment: exit gracefully
            return $null
        }
        switch ($key.Key) {
            'UpArrow' {
                $selected = [Math]::Max(0, $selected - 1)
            }
            'DownArrow' {
                $selected = [Math]::Min($Options.Count - 1, $selected + 1)
            }
            'Enter' {
                return $Options[$selected]
            }
            'Escape' {
                return $null
            }
        }
    }
}

function Show-InputForm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [hashtable[]]$Fields  # Array of @{Name='fieldname'; Label='Display label'; Required=$true; Type='text'|'select'; Options=@()}
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()

    # Normalize fields into a list of simple objects with mutable Value
    $norm = @()
    foreach ($f in $Fields) {
        $label = $null; $name = $null; $required = $false; $type = 'text'; $options = $null; $value = ''
        if ($f -is [hashtable]) {
            $label = [string]$f['Label']; $name = [string]$f['Name']
            $required = try { [bool]$f['Required'] } catch { $false }
            $type = if ($f.ContainsKey('Type') -and $f['Type']) { [string]$f['Type'] } else { 'text' }
            $options = if ($f.ContainsKey('Options')) { $f['Options'] } else { $null }
            $value = if ($f.ContainsKey('Value') -and $f['Value']) { [string]$f['Value'] } else { '' }
        } else {
            $label = [string]$f.Label; $name = [string]$f.Name
            $required = if ($f.PSObject.Properties['Required'] -and $f.Required) { [bool]$f.Required } else { $false }
            $type = if ($f.PSObject.Properties['Type'] -and $f.Type) { [string]$f.Type } else { 'text' }
            $options = if ($f.PSObject.Properties['Options']) { $f.Options } else { $null }
            $value = if ($f.PSObject.Properties['Value'] -and $f.Value) { [string]$f.Value } else { '' }
        }
        $norm += [pscustomobject]@{ Label=$label; Name=$name; Required=$required; Type=$type; Options=$options; Value=$value }
    }

    $active = 0
    $done = $false
    while (-not $done) {
        # Layout
        $boxWidth = [Math]::Min(78, $terminal.Width - 4)
        $boxHeight = [Math]::Min($terminal.Height - 6, 10 + $norm.Count * 2)
        $boxX = ($terminal.Width - $boxWidth) / 2

        # Use buffering for smooth rendering
        $terminal.BeginFrame()
        $terminal.DrawBox($boxX, 5, $boxWidth, $boxHeight)
        $titleX = ($terminal.Width - $Title.Length) / 2
        $terminal.WriteAtColor([int]$titleX, 5, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Render fields
        $y = 7
        for ($i=0; $i -lt $norm.Count; $i++) {
            $f = $norm[$i]
            $isActive = ($i -eq $active)
            $labelColor = if ($isActive) { [PmcVT100]::Yellow() } else { [PmcVT100]::Cyan() }
            $star = ''
            if ($f.Required) { $star = ' *' }
            $labelText = ("{0}:{1}" -f $f.Label, $star)
            $terminal.WriteAtColor([int]($boxX + 2), $y, $labelText, $labelColor, "")
            $val = [string]$f.Value
            if ($f.Type -eq 'select' -and $val -eq '') { $val = '(choose)' }
            if ($isActive) {
                $terminal.FillArea([int]($boxX + 2), $y+1, $boxWidth-4, 1, ' ')
                $terminal.WriteAtColor([int]($boxX + 2), $y+1, $val, [PmcVT100]::White(), "")
            } else {
                $terminal.WriteAt([int]($boxX + 2), $y+1, $val)
            }
            $y += 2
        }

        $terminal.WriteAt([int]($boxX + 2), [int](5 + $boxHeight - 2), "Tab/Shift+Tab navigate | Enter saves | Esc cancels")

        # Position cursor at end of active value
        $curY = 8 + ($active * 2)
        $curX = [int]($boxX + 2 + ([string]$norm[$active].Value).Length)
        if ($curX -ge [Console]::WindowWidth) { $curX = [Console]::WindowWidth - 1 }
        if ($curY -ge [Console]::WindowHeight) { $curY = [Console]::WindowHeight - 1 }

        # Show cursor and flush frame
        try { [Console]::CursorVisible = $true } catch {}
        $terminal.EndFrame()
        try { [Console]::SetCursorPosition($curX, $curY) } catch {}

        # Read input
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Escape') {
            # Hide cursor before returning
            try { [Console]::CursorVisible = $false } catch {}
            return $null
        }
        elseif ($k.Key -eq 'Tab') {
            $isShift = ("" + $k.Modifiers) -match 'Shift'
            if ($isShift) { $active = ($active - 1); if ($active -lt 0) { $active = $norm.Count - 1 } }
            else { $active = ($active + 1) % $norm.Count }
            continue
        }
        elseif ($k.Key -eq 'Enter') {
            $field = $norm[$active]
            if ($field.Type -eq 'select' -and $field.Options) {
                $sel = Show-SelectList -Title $field.Label -Options $field.Options
                if ($null -ne $sel) { $field.Value = [string]$sel }
                continue
            }
            # If not on a select field, Enter attempts to submit
            $allOk = $true
            foreach ($f in $norm) { if ($f.Required -and [string]::IsNullOrWhiteSpace([string]$f.Value)) { $allOk = $false; break } }
            if ($allOk) {
                $out = @{}
                foreach ($f in $norm) { $out[$f.Name] = [string]$f.Value }
                # Hide cursor before returning
                try { [Console]::CursorVisible = $false } catch {}
                return $out
            } else {
                # Focus first missing required
                for ($i=0; $i -lt $norm.Count; $i++) { if ($norm[$i].Required -and [string]::IsNullOrWhiteSpace([string]$norm[$i].Value)) { $active = $i; break } }
                continue
            }
        }
        elseif ($k.Key -eq 'Backspace') {
            $v = [string]$norm[$active].Value
            if ($v.Length -gt 0) { $norm[$active].Value = $v.Substring(0, $v.Length - 1) }
            continue
        } else {
            $ch = $k.KeyChar
            if ($ch -and $ch -ne "`0") { $norm[$active].Value = ([string]$norm[$active].Value) + $ch }
            continue
        }
    }
    # Hide cursor before exiting (in case of Escape or other exit paths)
    try { [Console]::CursorVisible = $false } catch {}
}

# === SIMPLE TERMINAL ===
class PmcSimpleTerminal {
    static [PmcSimpleTerminal]$Instance = $null
    [int]$Width
    [int]$Height
    [bool]$CursorVisible = $true
    [System.Text.StringBuilder]$buffer = $null
    [bool]$buffering = $false
    [hashtable]$dirtyRegions = @{}

    hidden PmcSimpleTerminal() {
        $this.UpdateDimensions()
        $this.buffer = [System.Text.StringBuilder]::new(8192)
    }

    static [PmcSimpleTerminal] GetInstance() {
        if ($null -eq [PmcSimpleTerminal]::Instance) {
            [PmcSimpleTerminal]::Instance = [PmcSimpleTerminal]::new()
        }
        return [PmcSimpleTerminal]::Instance
    }

    [void] Initialize() {
        [Console]::Clear()
        try {
            # Keep cursor visible during interactive forms so users can see focus
            [Console]::CursorVisible = $true
            $this.CursorVisible = $true
        } catch { }
        $this.UpdateDimensions()
        [Console]::SetCursorPosition(0, 0)
    }

    [void] Cleanup() {
        try {
            [Console]::CursorVisible = $true
            $this.CursorVisible = $true
        } catch { }
        [Console]::Clear()
    }

    [void] UpdateDimensions() {
        try {
            $this.Width = [Console]::WindowWidth
            $this.Height = [Console]::WindowHeight
        } catch {
            $this.Width = 120
            $this.Height = 30
        }
    }

    [void] Clear() {
        if ($this.buffering) {
            # In buffering mode, queue a clear sequence (VT100: clear screen + home)
            $this.buffer.Append("`e[2J`e[H") | Out-Null
            $this.dirtyRegions.Clear()
        } else {
            [Console]::Clear()
            [Console]::SetCursorPosition(0, 0)
        }
    }

    [void] BeginFrame() {
        $this.buffering = $true
        $this.buffer.Clear() | Out-Null
        $this.dirtyRegions.Clear()
        # Full screen clear to prevent visual corruption
        $this.buffer.Append("`e[2J`e[H") | Out-Null
        # Add VT100 hide cursor to the BUFFER ITSELF (first thing written)
        $this.buffer.Append("`e[?25l") | Out-Null
    }

    [void] EndFrame() {
        if ($this.buffering -and $this.buffer.Length -gt 0) {
            # Keep cursor hidden at end of frame (do NOT show cursor)
            $this.buffer.Append("`e[?25l") | Out-Null
            # Position cursor off-screen at bottom
            $this.buffer.Append("`e[$($this.Height);1H") | Out-Null
            # Write entire buffered frame at once
            [Console]::SetCursorPosition(0, 0)
            [Console]::Write($this.buffer.ToString())
        }
        $this.buffering = $false
        # Explicitly hide cursor after buffer flush
        try { [Console]::CursorVisible = $false } catch {}
    }

    [void] WriteAt([int]$x, [int]$y, [string]$text) {
        if ([string]::IsNullOrEmpty($text) -or $x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) { $text = $text.Substring(0, $maxLength) }

        if ($this.buffering) {
            # Append to buffer with VT100 positioning
            $this.buffer.Append("`e[$($y+1);$($x+1)H").Append($text) | Out-Null
            $regionKey = "$y,$x"
            $this.dirtyRegions[$regionKey] = $true
        } else {
            [Console]::SetCursorPosition($x, $y)
            [Console]::Write($text)
        }
    }

    [void] WriteAtColor([int]$x, [int]$y, [string]$text, [string]$foreground, [string]$background = "") {
        if ([string]::IsNullOrEmpty($text) -or $x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) { $text = $text.Substring(0, $maxLength) }
        $colored = $foreground
        if (-not [string]::IsNullOrEmpty($background)) { $colored += $background }
        $colored += $text + [PmcVT100]::Reset()

        if ($this.buffering) {
            # Append to buffer with VT100 positioning and color
            $this.buffer.Append("`e[$($y+1);$($x+1)H").Append($colored) | Out-Null
            $regionKey = "$y,$x"
            $this.dirtyRegions[$regionKey] = $true
        } else {
            [Console]::SetCursorPosition($x, $y)
            [Console]::Write($colored)
        }
    }

    [void] FillArea([int]$x, [int]$y, [int]$width, [int]$height, [char]$ch = ' ') {
        if ($width -le 0 -or $height -le 0) { return }
        $line = if ($ch -eq ' ') { [PmcStringCache]::GetSpaces($width) } else { [string]::new($ch, $width) }
        for ($row = 0; $row -lt $height; $row++) {
            $currentY = $y + $row
            if ($currentY -ge $this.Height) { break }
            $this.WriteAt($x, $currentY, $line)
        }
    }

    [void] DrawBox([int]$x, [int]$y, [int]$width, [int]$height) {
        if ($width -lt 2 -or $height -lt 2) { return }
        if ($x + $width -gt $this.Width -or $y + $height -gt $this.Height) { return }

        $tl = [PmcStringCache]::GetBoxDrawing("topleft")
        $tr = [PmcStringCache]::GetBoxDrawing("topright")
        $bl = [PmcStringCache]::GetBoxDrawing("bottomleft")
        $br = [PmcStringCache]::GetBoxDrawing("bottomright")
        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $v = [PmcStringCache]::GetBoxDrawing("vertical")

        $topLine = $tl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $tr
        $bottomLine = $bl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $br

        $this.WriteAtColor($x, $y, $topLine, [PmcVT100]::Cyan(), "")
        for ($row = 1; $row -lt $height - 1; $row++) {
            $this.WriteAtColor($x, $y + $row, $v, [PmcVT100]::Cyan(), "")
            $this.WriteAtColor($x + $width - 1, $y + $row, $v, [PmcVT100]::Cyan(), "")
        }
        $this.WriteAtColor($x, $y + $height - 1, $bottomLine, [PmcVT100]::Cyan(), "")
    }

    [void] DrawFilledBox([int]$x, [int]$y, [int]$width, [int]$height, [bool]$border = $true) {
        $this.FillArea($x, $y, $width, $height, ' ')
        if ($border) { $this.DrawBox($x, $y, $width, $height) }
    }

    [void] DrawHorizontalLine([int]$x, [int]$y, [int]$length) {
        if ($length -le 0) { return }
        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $line = [PmcStringCache]::GetSpaces($length).Replace(' ', $h)
        $this.WriteAtColor($x, $y, $line, [PmcVT100]::Cyan(), "")
    }

    [void] DrawFooter([string]$content) {
        $this.FillArea(0, $this.Height - 1, $this.Width, 1, ' ')
        $this.WriteAtColor(2, $this.Height - 1, $content, [PmcVT100]::Cyan(), "")
        # Ensure cursor stays hidden after footer rendering
        if ($this.buffering) {
            $this.buffer.Append("`e[?25l") | Out-Null
        }
    }

    # Clear content area (between menu and footer) - call at start of Render() if needed
    [void] ClearContentArea() {
        if ($this.buffering) {
            # Clear from line 3 (after menu) to line Height-2 (before footer)
            for ($y = 3; $y -lt $this.Height - 1; $y++) {
                $this.buffer.Append("`e[$($y+1);1H").Append([PmcStringCache]::GetSpaces($this.Width)) | Out-Null
            }
        }
    }
}

# === SCREEN MANAGER ARCHITECTURE ===

# Base screen class for all views
class PmcScreen {
    [string]$Title = "Screen"
    [bool]$Active = $true
    [int]$X = 0
    [int]$Y = 0
    [int]$Width = 0
    [int]$Height = 0

    # Reference to app context
    hidden [PmcConsoleUIApp]$App = $null
    hidden [PmcSimpleTerminal]$Terminal = $null
    hidden [PmcMenuSystem]$MenuSystem = $null
    hidden [bool]$_needsRender = $true

    # Title caching for performance (eliminates string interpolation per frame)
    hidden [string]$_cachedTitle = ""
    hidden [bool]$_titleDirty = $true

    # Initialize screen with app context
    [void] Initialize([PmcConsoleUIApp]$app) {
        $this.App = $app
        $this.Terminal = $app.terminal
        $this.MenuSystem = $app.menuSystem
        $this.Width = $this.Terminal.Width
        $this.Height = $this.Terminal.Height
    }

    # Lifecycle methods - override in derived screens
    [void] OnActivated() {
        $this._needsRender = $true
    }

    [void] OnDeactivated() {
        # Override in derived classes if needed
    }

    # Render the screen - override in derived classes
    [void] Render() {
        # Default implementation does nothing
        # Derived classes should implement their rendering logic here
    }

    # Handle input - return true if handled, false otherwise
    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        # Default implementation - derived classes should override
        return $false
    }

    # Request a re-render
    [void] Invalidate() {
        $this._needsRender = $true
    }

    # Check if render is needed
    [bool] NeedsRender() {
        return $this._needsRender
    }

    # Mark render as complete
    [void] RenderComplete() {
        $this._needsRender = $false
    }

    # Update bounds (called on terminal resize)
    [void] SetBounds([int]$x, [int]$y, [int]$width, [int]$height) {
        $this.X = $x
        $this.Y = $y
        $this.Width = $width
        $this.Height = $height
        $this.Invalidate()
    }

    # === TITLE CACHING SYSTEM ===

    # Invalidate cached title when data changes
    [void] InvalidateTitle() {
        $this._titleDirty = $true
    }

    # Get cached title (or rebuild if dirty)
    [string] GetCachedTitle() {
        if ($this._titleDirty) {
            $this._cachedTitle = $this.BuildTitle()
            $this._titleDirty = $false
        }
        return $this._cachedTitle
    }

    # Override this in derived classes to build dynamic titles
    [string] BuildTitle() {
        return $this.Title
    }

    # === STANDARD RENDERING HELPERS ===

    [void] RenderStandardLayout() {
        $this.MenuSystem.DrawMenuBar()
        $this.DrawCenteredTitle($this.GetCachedTitle(), 3)
    }

    [void] DrawCenteredTitle([string]$text, [int]$yPos) {
        $titleText = " $text "
        $xPos = ($this.Width - $text.Length - 2) / 2
        $this.Terminal.WriteAtColor([int]$xPos, $yPos, $titleText, [PmcVT100]::BgBlue(), [PmcVT100]::White())
    }

    [void] DrawCenteredTitle([string]$text, [int]$yPos, [string]$bgColor, [string]$fgColor) {
        $titleText = " $text "
        $xPos = ($this.Width - $text.Length - 2) / 2
        $this.Terminal.WriteAtColor([int]$xPos, $yPos, $titleText, $bgColor, $fgColor)
    }

    [void] HighlightRow([int]$yPos) {
        $this.Terminal.FillArea(0, $yPos, $this.Width, 1, ' ')
    }

    [void] DrawColumnHeaders([hashtable[]]$columns, [int]$yPos) {
        foreach ($col in $columns) {
            $this.Terminal.WriteAtColor($col.X, $yPos, $col.Label, [PmcVT100]::Cyan(), "")
        }
        $this.Terminal.DrawHorizontalLine(0, $yPos + 1, $this.Width)
    }

    [void] DrawEmptyState([string]$message) {
        $yPos = [int](($this.Height / 2) - 1)
        $xPos = [int](($this.Width - $message.Length) / 2)
        $this.Terminal.WriteAtColor($xPos, $yPos, $message, [PmcVT100]::Yellow(), "")
    }

    [void] DrawEmptyState([string]$message, [string]$hint) {
        $yPos = [int](($this.Height / 2) - 2)
        $xPos1 = [int](($this.Width - $message.Length) / 2)
        $this.Terminal.WriteAtColor($xPos1, $yPos, $message, [PmcVT100]::Yellow(), "")
        if ($hint) {
            $xPos2 = [int](($this.Width - $hint.Length) / 2)
            $this.Terminal.WriteAtColor($xPos2, $yPos + 2, $hint, [PmcVT100]::Cyan(), "")
        }
    }
}

# List screen base class with built-in navigation
class PmcListScreen : PmcScreen {
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0
    [array]$items = @()
    [int]$headerHeight = 7
    [int]$footerHeight = 2

    # Override in derived class to load items
    [void] LoadItems() { }

    # Override in derived class to render one item
    [void] RenderItem([object]$item, [int]$y, [bool]$isSelected) { }

    # Override in derived class for custom rendering
    [void] RenderHeader() {
        $this.RenderStandardLayout()
    }

    # Get maximum visible rows
    [int] GetMaxVisibleRows() {
        return $this.Height - $this.headerHeight - $this.footerHeight
    }

    # Get selected item
    [object] GetSelectedItem() {
        if ($this.selectedIndex -ge 0 -and $this.selectedIndex -lt $this.items.Count) {
            return $this.items[$this.selectedIndex]
        }
        return $null
    }

    # Ensure selected item is visible
    [void] EnsureVisible() {
        $maxVisible = $this.GetMaxVisibleRows()
        if ($this.selectedIndex -lt $this.scrollOffset) {
            $this.scrollOffset = $this.selectedIndex
        }
        elseif ($this.selectedIndex -ge $this.scrollOffset + $maxVisible) {
            $this.scrollOffset = $this.selectedIndex - $maxVisible + 1
        }
    }

    # Standard list rendering
    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.RenderHeader()

        if ($this.items.Count -eq 0) {
            $this.DrawEmptyState("No items to display")
        } else {
            # Render visible items
            $maxVisible = $this.GetMaxVisibleRows()
            $startY = $this.headerHeight

            for ($i = 0; $i -lt $maxVisible -and ($i + $this.scrollOffset) -lt $this.items.Count; $i++) {
                $itemIdx = $i + $this.scrollOffset
                $item = $this.items[$itemIdx]
                $yPos = $startY + $i
                $isSelected = ($itemIdx -eq $this.selectedIndex)

                if ($isSelected) {
                    $this.HighlightRow($yPos)
                }

                $this.RenderItem($item, $yPos, $isSelected)
            }
        }

        $this.Terminal.EndFrame()
    }

    # Standard list navigation
    [bool] HandleListNavigation([ConsoleKeyInfo]$key) {
        $maxVisible = $this.GetMaxVisibleRows()

        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    $this.EnsureVisible()
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.items.Count - 1) {
                    $this.selectedIndex++
                    $this.EnsureVisible()
                    return $true
                }
            }
            'PageUp' {
                $this.selectedIndex = [Math]::Max(0, $this.selectedIndex - $maxVisible)
                $this.EnsureVisible()
                return $true
            }
            'PageDown' {
                $this.selectedIndex = [Math]::Min($this.items.Count - 1, $this.selectedIndex + $maxVisible)
                $this.EnsureVisible()
                return $true
            }
            'Home' {
                $this.selectedIndex = 0
                $this.scrollOffset = 0
                return $true
            }
            'End' {
                $this.selectedIndex = $this.items.Count - 1
                $maxVisible = $this.GetMaxVisibleRows()
                $this.scrollOffset = [Math]::Max(0, $this.items.Count - $maxVisible)
                return $true
            }
        }
        return $false
    }
}

# === CONCRETE SCREEN IMPLEMENTATIONS ===

# Theme selection screen
class ThemeScreen : PmcListScreen {
    [array]$themes = @()
    [int]$previewThemeIndex = -1

    ThemeScreen() {
        $this.Title = "Theme Selection"
        $this.headerHeight = 7
        $this.footerHeight = 2
    }

    [void] OnActivated() {
        ([PmcListScreen]$this).OnActivated()
        $this.LoadItems()
    }

    [void] LoadItems() {
        $this.themes = @(
            @{
                Name = "Default"
                Description = "Standard colors optimized for dark terminals"
                Id = 1
            }
            @{
                Name = "Dark"
                Description = "High contrast with bright highlights"
                Id = 2
            }
            @{
                Name = "Light"
                Description = "Designed for light terminal backgrounds"
                Id = 3
            }
            @{
                Name = "Solarized"
                Description = "Popular Solarized color palette"
                Id = 4
            }
        )
        $this.items = $this.themes
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.RenderStandardLayout()

        $y = 6
        $this.Terminal.WriteAtColor(4, $y++, "Select a theme to apply:", [PmcVT100]::Cyan(), "")
        $y++

        # Render theme list
        $maxVisible = $this.GetMaxVisibleRows()
        $endIndex = [Math]::Min($this.scrollOffset + $maxVisible, $this.items.Count)

        for ($i = $this.scrollOffset; $i -lt $endIndex; $i++) {
            $theme = $this.items[$i]
            $isSelected = ($i -eq $this.selectedIndex)
            $isPreviewed = ($i -eq $this.previewThemeIndex)

            if ($isSelected) {
                $this.Terminal.WriteAtColor(4, $y, ">", [PmcVT100]::Yellow(), "")
            }

            $themeName = "$($theme.Id). $($theme.Name)"
            if ($isPreviewed) {
                $themeName += " [PREVIEWING]"
            }

            $color = if ($isSelected) { [PmcVT100]::Cyan() } else { [PmcVT100]::White() }
            $this.Terminal.WriteAtColor(6, $y++, $themeName, $color, "")

            $descColor = if ($isSelected) { [PmcVT100]::Yellow() } else { "" }
            $this.Terminal.WriteAtColor(8, $y++, $theme.Description, $descColor, "")
            $y++
        }

        # Show preview hint
        if ($this.previewThemeIndex -ge 0) {
            $y = $this.Height - 5
            $this.Terminal.WriteAtColor(4, $y, "Press 'A' to apply previewed theme, or select another to preview", [PmcVT100]::Yellow(), "")
        } else {
            $y = $this.Height - 5
            $this.Terminal.WriteAtColor(4, $y, "Press number key (1-4) to preview theme, 'A' to apply selected", [PmcVT100]::Yellow(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterTheme)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        # Handle list navigation
        if ($this.HandleListNavigation($key)) {
            return $true
        }

        switch ($key.Key) {
            'Escape' {
                $this.Active = $false
                return $true
            }
            'A' {
                # Apply selected or previewed theme
                $themeIndex = if ($this.previewThemeIndex -ge 0) { $this.previewThemeIndex } else { $this.selectedIndex }
                if ($themeIndex -ge 0 -and $themeIndex -lt $this.themes.Count) {
                    $theme = $this.themes[$themeIndex]
                    $this.ApplyTheme($theme.Id)
                    $this.Active = $false
                }
                return $true
            }
        }

        # Handle number keys for theme preview
        if ($key.KeyChar -ge '1' -and $key.KeyChar -le '4') {
            $themeId = [int]$key.KeyChar.ToString()
            $themeIndex = $themeId - 1
            if ($themeIndex -ge 0 -and $themeIndex -lt $this.themes.Count) {
                $this.previewThemeIndex = $themeIndex
                $this.selectedIndex = $themeIndex
                $this.EnsureVisible()
                # Note: Actual preview would require theme system implementation
                # For now just mark as previewed
                return $true
            }
        }

        return $false
    }

    [void] ApplyTheme([int]$themeId) {
        # Note: This would integrate with actual theme system
        # For now, just show a message that theme was applied
        try {
            # In a real implementation, this would:
            # 1. Load theme configuration from file or settings
            # 2. Update PmcVT100 color mappings
            # 3. Save theme preference to config
            # 4. Trigger UI refresh

            # Placeholder: Save theme ID to config
            $configPath = Join-Path $PSScriptRoot "config.json"
            if (Test-Path $configPath) {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                if (-not $config.ui) {
                    $config | Add-Member -NotePropertyName 'ui' -NotePropertyValue @{} -Force
                }
                $config.ui | Add-Member -NotePropertyName 'theme' -NotePropertyValue $themeId -Force
                $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            }
        } catch {
            # Silently fail - theme system may not be fully implemented
        }
    }
}

# Screen manager for coordinating screen lifecycle and rendering
class PmcScreenManager {
    hidden [System.Collections.Generic.Stack[PmcScreen]]$_screenStack
    hidden [PmcScreen]$_activeScreen = $null
    hidden [bool]$_needsRender = $true
    hidden [PmcConsoleUIApp]$_app = $null
    hidden [bool]$_exitRequested = $false

    PmcScreenManager([PmcConsoleUIApp]$app) {
        $this._screenStack = [System.Collections.Generic.Stack[PmcScreen]]::new()
        $this._app = $app
    }

    # Push a new screen onto the stack
    [void] Push([PmcScreen]$screen) {
        # Deactivate current screen
        if ($this._activeScreen) {
            $this._activeScreen.Active = $false
            $this._activeScreen.OnDeactivated()
        }

        # Initialize and activate new screen
        $screen.Initialize($this._app)
        $screen.SetBounds(0, 0, $this._app.terminal.Width, $this._app.terminal.Height)

        $this._screenStack.Push($screen)
        $this._activeScreen = $screen
        $this._activeScreen.Active = $true
        $this._activeScreen.OnActivated()
        $this._needsRender = $true
    }

    # Pop current screen and return to previous
    [PmcScreen] Pop() {
        if ($this._screenStack.Count -eq 0) { return $null }

        $popped = $this._screenStack.Pop()
        if ($popped) {
            $popped.Active = $false
            $popped.OnDeactivated()
        }

        # Activate previous screen if any
        if ($this._screenStack.Count -gt 0) {
            $this._activeScreen = $this._screenStack.Peek()
            if ($this._activeScreen) {
                $this._activeScreen.Active = $true
                $this._activeScreen.OnActivated()
                $this._needsRender = $true
            }
        } else {
            $this._activeScreen = $null
        }

        return $popped
    }

    # Replace current screen with a new one
    [void] Replace([PmcScreen]$screen) {
        if ($this._screenStack.Count -gt 0) {
            $this.Pop() | Out-Null
        }
        $this.Push($screen)
    }

    # Get active screen
    [PmcScreen] GetActiveScreen() {
        return $this._activeScreen
    }

    # Request exit from run loop
    [void] RequestExit() {
        $this._exitRequested = $true
    }

    # Main render-on-demand run loop
    [void] Run() {
        [Console]::CursorVisible = $false
        [Console]::Clear()

        # Track window size for resize detection
        $lastWidth = [Console]::WindowWidth
        $lastHeight = [Console]::WindowHeight

        while ($this._activeScreen -and -not $this._exitRequested) {
            # If current screen became inactive, pop it and continue with previous screen
            if (-not $this._activeScreen.Active) {
                $this.Pop()
                if (-not $this._activeScreen) {
                    # No more screens, exit
                    break
                }
                continue
            }

            # Check for terminal resize
            $currentWidth = [Console]::WindowWidth
            $currentHeight = [Console]::WindowHeight
            if ($currentWidth -ne $lastWidth -or $currentHeight -ne $lastHeight) {
                $lastWidth = $currentWidth
                $lastHeight = $currentHeight
                if ($this._activeScreen) {
                    $this._activeScreen.SetBounds(0, 0, $currentWidth, $currentHeight)
                    $this._needsRender = $true
                }
            }

            # Render only if needed
            if ($this._needsRender -or $this._activeScreen.NeedsRender()) {
                $this._activeScreen.Render()
                $this._activeScreen.RenderComplete()
                $this._needsRender = $false
            }

            # Handle input if available
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)

                # Check for global menu shortcuts (Alt+key) before passing to screen
                $menuHandled = $false
                if ($key.Modifiers -band [ConsoleModifiers]::Alt) {
                    $menuSystem = $this._app.menuSystem

                    # Check for Alt+menu hotkey (F, T, P, I, V, O, H)
                    for ($i = 0; $i -lt $menuSystem.menuOrder.Count; $i++) {
                        $menuName = $menuSystem.menuOrder[$i]
                        $menu = $menuSystem.menus[$menuName]
                        if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                            # Show menu dropdown
                            $this._activeScreen.Render()  # Render current screen first
                            $action = $menuSystem.ShowDropdown($menuName)
                            if ($action) {
                                $this._app.ProcessMenuAction($action)
                            }
                            $menuHandled = $true
                            $this._needsRender = $true
                            break
                        }
                    }
                }

                # If menu didn't handle it, let screen handle input
                if (-not $menuHandled) {
                    $handled = $this._activeScreen.HandleInput($key)

                    # If input was handled, mark for re-render
                    if ($handled) {
                        $this._needsRender = $true
                    }
                }
            }

            # Small sleep to prevent CPU spinning
            Start-Sleep -Milliseconds 10
        }

        [Console]::CursorVisible = $true
    }
}

# === CONCRETE SCREEN IMPLEMENTATIONS ===

# Task List Screen
class TaskListScreen : PmcScreen {
    TaskListScreen() {
        $this.Title = "Task List"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        # Load fresh task data
        $this.App.LoadTasks()
        $this.InvalidateTitle()
    }

    [string] BuildTitle() {
        $title = " Task List ($($this.App.tasks.Count) tasks) [Sort: $($this.App.sortBy)] "
        if ($this.App.searchText) {
            $title = " Search: '$($this.App.searchText)' ($($this.App.tasks.Count) tasks) [Sort: $($this.App.sortBy)] "
        } elseif ($this.App.filterProject) {
            $title = " Project: $($this.App.filterProject) ($($this.App.tasks.Count) tasks) [Sort: $($this.App.sortBy)] "
        }
        return $title
    }

    [void] Render() {
        $this.Terminal.BeginFrame()

        # Draw menu bar
        $this.MenuSystem.DrawMenuBar()

        # Draw title
        $title = $this.GetCachedTitle()
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Calculate column widths
        $termWidth = $this.Terminal.Width
        $idWidth = 5
        $statusWidth = 8
        $dueWidth = 11
        $overdueWidth = 3
        $spacing = 10

        $remainingWidth = $termWidth - $idWidth - $statusWidth - $dueWidth - $overdueWidth - $spacing - 4
        $projectWidth = [Math]::Min(25, [Math]::Max(12, [int]($remainingWidth * 0.25)))
        $taskWidth = $remainingWidth - $projectWidth - 2

        # Column positions
        $colID = 2
        $colStatus = $colID + $idWidth + 1
        $colTask = $colStatus + $statusWidth + 2
        $colDue = $colTask + $taskWidth + 2
        $colProject = $colDue + $dueWidth + 1

        # Headers
        $headerY = 5
        $this.Terminal.WriteAtColor($colID, $headerY, "ID", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAtColor($colStatus, $headerY, "Status", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAtColor($colTask, $headerY, "Task", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAtColor($colDue, $headerY, "Due", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAtColor($colProject, $headerY, "Project", [PmcVT100]::Cyan(), "")
        $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

        $startY = $headerY + 2
        $maxRows = $this.Terminal.Height - $startY - 3

        # Empty state
        if ($this.App.tasks.Count -eq 0) {
            $emptyY = $startY + 3
            $this.Terminal.WriteAtColor(4, $emptyY++, "No tasks to display", [PmcVT100]::Yellow(), "")
            $emptyY++
            $this.Terminal.WriteAtColor(4, $emptyY++, "Press 'A' to add your first task", [PmcVT100]::Cyan(), "")
            $this.Terminal.WriteAt(4, $emptyY++, "Press '/' to search for tasks")
            $this.Terminal.WriteAt(4, $emptyY++, "Press 'C' to clear filters")
        }

        # Draw tasks
        $displayedRows = 0
        $taskIdx = 0
        while ($displayedRows -lt $maxRows -and $taskIdx -lt $this.App.tasks.Count) {
            if ($taskIdx -lt $this.App.scrollOffset) {
                $taskIdx++
                continue
            }

            $task = $this.App.tasks[$taskIdx]
            $y = $startY + $displayedRows
            $isSelected = ($taskIdx -eq $this.App.selectedTaskIndex)

            if ($isSelected) {
                $this.Terminal.FillArea(0, $y, $this.Terminal.Width, 1, ' ')
                $this.Terminal.WriteAtColor(0, $y, ">", [PmcVT100]::Yellow(), "")
            }

            $statusIcon = if ($task.status -eq 'completed') { 'X' } else { 'o' }
            $statusColor = if ($task.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Cyan() }

            $this.Terminal.WriteAtColor($colID, $y, $task.id.ToString(), [PmcVT100]::Cyan(), "")
            $this.Terminal.WriteAtColor($colStatus, $y, $statusIcon, $statusColor, "")

            # Task text
            $text = if ($null -ne $task.text) { $task.text } else { "" }
            if ($text.Length -gt $taskWidth) {
                $text = $text.Substring(0, $taskWidth - 3) + "..."
            }
            $this.Terminal.WriteAtColor($colTask, $y, $text, [PmcVT100]::Yellow(), "")

            # Due date
            if ($task.due) {
                $dueStr = $task.due.ToString().Substring(0, [Math]::Min(10, $task.due.ToString().Length))
                $this.Terminal.WriteAtColor($colDue, $y, $dueStr, [PmcVT100]::Cyan(), "")
            }

            # Project
            $project = if ($null -ne $task.project -and $task.project -ne '') { $task.project } else { 'none' }
            if ($project.Length -gt $projectWidth) {
                $project = $project.Substring(0, $projectWidth - 3) + "..."
            }
            $this.Terminal.WriteAtColor($colProject, $y, $project, [PmcVT100]::Cyan(), "")

            $displayedRows++
            $taskIdx++
        }

        # Footer
        $statusBar = [PmcUIStringCache]::FooterTaskList
        $this.Terminal.DrawFooter($statusBar)

        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.App.selectedTaskIndex -gt 0) {
                    $this.App.selectedTaskIndex--
                    # Adjust scroll offset
                    if ($this.App.selectedTaskIndex -lt $this.App.scrollOffset) {
                        $this.App.scrollOffset = $this.App.selectedTaskIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.App.selectedTaskIndex -lt $this.App.tasks.Count - 1) {
                    $this.App.selectedTaskIndex++
                    # Adjust scroll offset
                    $maxVisible = $this.Terminal.Height - 11
                    if ($this.App.selectedTaskIndex -ge ($this.App.scrollOffset + $maxVisible)) {
                        $this.App.scrollOffset = $this.App.selectedTaskIndex - $maxVisible + 1
                    }
                    return $true
                }
            }
            'A' {
                # Add new task
                $this.App.ShowTaskAddForm()
                # Reload tasks after form closes
                $this.App.LoadTasks()
                $this.InvalidateTitle()
                return $true
            }
            'E' {
                # Edit selected task
                if ($this.App.selectedTaskIndex -lt $this.App.tasks.Count) {
                    $task = $this.App.tasks[$this.App.selectedTaskIndex]
                    $this.App.ShowTaskEditForm($task)
                    # Reload tasks after form closes
                    $this.App.LoadTasks()
                    $this.InvalidateTitle()
                    return $true
                }
            }
            'D' {
                # Toggle task complete/active
                if ($this.App.selectedTaskIndex -lt $this.App.tasks.Count) {
                    $task = $this.App.tasks[$this.App.selectedTaskIndex]
                    $isCompleting = -not ($task.status -eq 'completed')
                    $task.status = if ($isCompleting) { 'completed' } else { 'active' }
                    if ($isCompleting) {
                        try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    } else {
                        try { $task.completed = $null } catch {}
                    }
                    try {
                        $data = Get-PmcAllData
                        Save-PmcData -Data $data -Action "Toggled task $($task.id)"
                        $this.App.LoadTasks()
                        $this.InvalidateTitle()
                    } catch {}
                    return $true
                }
            }
            'Escape' {
                # Pop back to previous screen (or exit if last screen)
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Project List Screen
class ProjectListScreen : PmcScreen {
    ProjectListScreen() {
        $this.Title = "Project List"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        # Load fresh project data
        $this.App.LoadProjects()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Project List "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData

            if ($this.App.projects.Count -eq 0) {
                $emptyY = 8
                $emptyY++
                $this.Terminal.WriteAtColor(4, $emptyY++, "Press 'A' to create your first project", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(4, $emptyY++, "Or press Alt+P then L to view this screen", [PmcVT100]::Gray(), "")
            } else {
                $headerY = 5
                $this.Terminal.WriteAtColor(2, $headerY, "Project", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(30, $headerY, "Active", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(42, $headerY, "Done", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(52, $headerY, "Total", [PmcVT100]::Cyan(), "")
                $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

                $startY = $headerY + 2
                $y = $startY

                for ($i = 0; $i -lt $this.App.projects.Count; $i++) {
                    if ($y -ge $this.Terminal.Height - 3) { break }

                    $proj = $this.App.projects[$i]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }

                    $projTasks = @($data.tasks | Where-Object { $_.project -eq $projName })
                    $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                    $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                    $total = $projTasks.Count

                    # Highlight selected project
                    $prefix = if ($i -eq $this.App.selectedProjectIndex) { "> " } else { "  " }
                    $bg = if ($i -eq $this.App.selectedProjectIndex) { [PmcVT100]::BgBlue() } else { "" }
                    $fg = if ($i -eq $this.App.selectedProjectIndex) { [PmcVT100]::White() } else { "" }

                    $projDisplay = $projName.Substring(0, [Math]::Min(24, $projName.Length))
                    if ($bg) {
                        $this.Terminal.WriteAtColor(2, $y, ($prefix + $projDisplay).PadRight(28), $bg, $fg)
                        $this.Terminal.WriteAtColor(30, $y, $active.ToString().PadRight(10), $bg, [PmcVT100]::Cyan())
                        $this.Terminal.WriteAtColor(42, $y, $completed.ToString().PadRight(8), $bg, [PmcVT100]::Yellow())
                        $this.Terminal.WriteAtColor(52, $y, $total.ToString(), $bg, $fg)
                    } else {
                        $this.Terminal.WriteAtColor(2, $y, $prefix + $projDisplay, [PmcVT100]::Yellow(), "")
                        $this.Terminal.WriteAtColor(30, $y, $active.ToString(), [PmcVT100]::Cyan(), "")
                        $this.Terminal.WriteAtColor(42, $y, $completed.ToString(), [PmcVT100]::Yellow(), "")
                        $this.Terminal.WriteAtColor(52, $y, $total.ToString(), [PmcVT100]::Yellow(), "")
                    }
                    $y++
                }
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading projects: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterProjectNav)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.App.selectedProjectIndex -gt 0) {
                    $this.App.selectedProjectIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.App.selectedProjectIndex -lt $this.App.projects.Count - 1) {
                    $this.App.selectedProjectIndex++
                    return $true
                }
            }
            'Enter' {
                # Filter tasks by selected project and navigate to task list
                if ($this.App.selectedProjectIndex -lt $this.App.projects.Count) {
                    $proj = $this.App.projects[$this.App.selectedProjectIndex]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }
                    $this.App.filterProject = $projName
                    $this.App.NavigateToTaskList()
                    return $true
                }
            }
            'A' {
                # Add new project
                $this.App.ShowProjectAddForm()
                # Reload projects after form closes
                $this.App.LoadProjects()
                return $true
            }
            'E' {
                # Edit selected project
                if ($this.App.selectedProjectIndex -lt $this.App.projects.Count) {
                    $proj = $this.App.projects[$this.App.selectedProjectIndex]
                    $this.App.ShowProjectEditForm($proj)
                    # Reload projects after form closes
                    $this.App.LoadProjects()
                    return $true
                }
            }
            'Escape' {
                # Pop back to previous screen
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# === DATE-FILTERED VIEW SCREENS ===

# Overdue View Screen - Shows tasks past their due date
class OverdueViewScreen : PmcScreen {
    [array]$overdueTasks = @()
    [int]$selectedIndex = 0

    OverdueViewScreen() {
        $this.Title = "Overdue Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadOverdueTasks()
    }

    [string] BuildTitle() {
        return " Overdue Tasks ($($this.overdueTasks.Count)) "
    }

    [void] LoadOverdueTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $this.overdueTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.due -and (Get-ConsoleUIDateOrNull $_.due) -and ((Get-ConsoleUIDateOrNull $_.due).Date -lt $today)
        })
        $this.InvalidateTitle()
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = $this.GetCachedTitle()
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgRed(), [PmcVT100]::White())

        if ($this.overdueTasks.Count -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No overdue tasks", [PmcVT100]::Green(), "")
        } else {
            $y = 6
            for ($i = 0; $i -lt $this.overdueTasks.Count; $i++) {
                if ($y -ge $this.Terminal.Height - 3) { break }

                $task = $this.overdueTasks[$i]
                $isSelected = ($i -eq $this.selectedIndex)
                $prefix = if ($isSelected) { "> " } else { "  " }

                $taskText = "$prefix#$($task.id) $($task.text)"
                if ($taskText.Length -gt 60) { $taskText = $taskText.Substring(0, 57) + "..." }

                $color = if ($isSelected) { [PmcVT100]::Yellow() } else { [PmcVT100]::Red() }
                $this.Terminal.WriteAtColor(4, $y, $taskText, $color, "")

                if ($task.due) {
                    $dueDate = Get-ConsoleUIDateOrNull $task.due
                    if ($dueDate) {
                        $daysOverdue = ((Get-Date).Date - $dueDate.Date).Days
                        $dueText = "Due: $($task.due) ($daysOverdue days ago)"
                        $this.Terminal.WriteAtColor(70, $y, $dueText, [PmcVT100]::Red(), "")
                    }
                }

                $y++
            }
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterSelectEditToggle)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.overdueTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.overdueTasks.Count) {
                    $task = $this.overdueTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadOverdueTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.overdueTasks.Count) {
                    $task = $this.overdueTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed overdue task $($task.id)"
                    $this.LoadOverdueTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Today View Screen - Shows tasks due today
class TodayViewScreen : PmcScreen {
    [array]$todayTasks = @()
    [int]$selectedIndex = 0

    TodayViewScreen() {
        $this.Title = "Today's Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadTodayTasks()
    }

    [string] BuildTitle() {
        return " Today's Tasks ($($this.todayTasks.Count)) - $(Get-Date -Format 'yyyy-MM-dd') "
    }

    [void] LoadTodayTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $this.todayTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.due -and (Get-ConsoleUIDateOrNull $_.due) -and ((Get-ConsoleUIDateOrNull $_.due).Date -eq $today)
        })
        $this.InvalidateTitle()
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = $this.GetCachedTitle()
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.todayTasks.Count -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No tasks due today", [PmcVT100]::Green(), "")
        } else {
            # Group by priority
            $highPri = @($this.todayTasks | Where-Object { $_.priority -eq 'high' })
            $otherPri = @($this.todayTasks | Where-Object { $_.priority -ne 'high' })

            $y = 6

            if ($highPri.Count -gt 0) {
                $this.Terminal.WriteAtColor(4, $y, "HIGH PRIORITY:", [PmcVT100]::Red(), "")
                $y++

                for ($i = 0; $i -lt $highPri.Count; $i++) {
                    if ($y -ge $this.Terminal.Height - 3) { break }
                    $task = $highPri[$i]
                    $globalIdx = [Array]::IndexOf($this.todayTasks, $task)
                    $isSelected = ($globalIdx -eq $this.selectedIndex)
                    $prefix = if ($isSelected) { "> " } else { "  " }

                    $taskText = "$prefix#$($task.id) $($task.text)"
                    if ($taskText.Length -gt 80) { $taskText = $taskText.Substring(0, 77) + "..." }

                    $color = if ($isSelected) { [PmcVT100]::Yellow() } else { [PmcVT100]::Red() }
                    $this.Terminal.WriteAtColor(4, $y, $taskText, $color, "")
                    $y++
                }
                $y++
            }

            if ($otherPri.Count -gt 0) {
                $this.Terminal.WriteAtColor(4, $y, "OTHER TASKS:", [PmcVT100]::Cyan(), "")
                $y++

                for ($i = 0; $i -lt $otherPri.Count; $i++) {
                    if ($y -ge $this.Terminal.Height - 3) { break }
                    $task = $otherPri[$i]
                    $globalIdx = [Array]::IndexOf($this.todayTasks, $task)
                    $isSelected = ($globalIdx -eq $this.selectedIndex)
                    $prefix = if ($isSelected) { "> " } else { "  " }

                    $taskText = "$prefix#$($task.id) $($task.text)"
                    if ($taskText.Length -gt 80) { $taskText = $taskText.Substring(0, 77) + "..." }

                    $color = if ($isSelected) { [PmcVT100]::Yellow() } else { [PmcVT100]::Cyan() }
                    $this.Terminal.WriteAtColor(4, $y, $taskText, $color, "")
                    $y++
                }
            }
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterSelectEditToggle)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.todayTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.todayTasks.Count) {
                    $task = $this.todayTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadTodayTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.todayTasks.Count) {
                    $task = $this.todayTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed today task $($task.id)"
                    $this.LoadTodayTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Week View Screen - Shows tasks due this week
class WeekViewScreen : PmcScreen {
    [array]$weekTasks = @()
    [int]$selectedIndex = 0

    WeekViewScreen() {
        $this.Title = "This Week's Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadWeekTasks()
    }

    [void] LoadWeekTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $weekEnd = $today.AddDays(7)

        $this.weekTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.due -and (Get-ConsoleUIDateOrNull $_.due) -and
            ((Get-ConsoleUIDateOrNull $_.due).Date -ge $today) -and ((Get-ConsoleUIDateOrNull $_.due).Date -le $weekEnd)
        })
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $today = Get-Date -Format 'yyyy-MM-dd'
        $weekEnd = (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
        $title = " This Week ($today to $weekEnd) - $($this.weekTasks.Count) tasks "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.weekTasks.Count -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No tasks due this week", [PmcVT100]::Green(), "")
        } else {
            $y = 6
            for ($i = 0; $i -lt $this.weekTasks.Count; $i++) {
                if ($y -ge $this.Terminal.Height - 3) { break }

                $task = $this.weekTasks[$i]
                $isSelected = ($i -eq $this.selectedIndex)
                $prefix = if ($isSelected) { "> " } else { "  " }

                $taskText = "$prefix#$($task.id) $($task.text)"
                if ($taskText.Length -gt 60) { $taskText = $taskText.Substring(0, 57) + "..." }

                $color = if ($isSelected) { [PmcVT100]::Yellow() } else { [PmcVT100]::Cyan() }
                $this.Terminal.WriteAtColor(4, $y, $taskText, $color, "")

                if ($task.due) {
                    $dueText = "Due: $($task.due)"
                    $this.Terminal.WriteAtColor(70, $y, $dueText, [PmcVT100]::Cyan(), "")
                }

                $y++
            }
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterSelectEditToggle)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.weekTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.weekTasks.Count) {
                    $task = $this.weekTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadWeekTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.weekTasks.Count) {
                    $task = $this.weekTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed week task $($task.id)"
                    $this.LoadWeekTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Kanban View Screen - Shows tasks in 3 columns by status
class KanbanScreen : PmcScreen {
    [array]$todoTasks = @()
    [array]$inProgressTasks = @()
    [array]$doneTasks = @()
    [int]$selectedColumn = 0  # 0=todo, 1=in-progress, 2=done
    [int]$selectedIndex = 0

    KanbanScreen() {
        $this.Title = "Kanban Board"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadKanbanTasks()
    }

    [void] OnDeactivated() {
        ([PmcScreen]$this).OnDeactivated()
        # Save data if dirty (deferred save for performance)
        if ($this.App.dataDirty) {
            $data = Get-PmcAllData
            Save-PmcData -Data $data -Action "Updated Kanban tasks"
            $this.App.dataDirty = $false
        }
    }

    [string] BuildTitle() {
        return " Kanban Board "
    }

    [void] LoadKanbanTasks() {
        $data = Get-PmcAllData
        $this.todoTasks = @($data.tasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' })
        $this.inProgressTasks = @($data.tasks | Where-Object { $_.status -eq 'in-progress' -or $_.status -eq 'doing' })
        $this.doneTasks = @($data.tasks | Where-Object { $_.status -eq 'completed' -or $_.status -eq 'done' })
        $this.InvalidateTitle()
        $this.Invalidate()
    }

    [array] GetCurrentColumnTasks() {
        switch ($this.selectedColumn) {
            0 { return $this.todoTasks }
            1 { return $this.inProgressTasks }
            2 { return $this.doneTasks }
        }
        return @()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = $this.GetCachedTitle()
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Calculate column widths
        $colWidth = [Math]::Floor($this.Terminal.Width / 3)
        $col1X = 0
        $col2X = $colWidth
        $col3X = $colWidth * 2

        # Column headers
        $this.Terminal.WriteAtColor($col1X + 2, 5, "TODO ($($this.todoTasks.Count))", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAtColor($col2X + 2, 5, "IN PROGRESS ($($this.inProgressTasks.Count))", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAtColor($col3X + 2, 5, "DONE ($($this.doneTasks.Count))", [PmcVT100]::Green(), "")

        # Draw tasks in columns
        $maxRows = $this.Terminal.Height - 10
        $this.RenderColumn(0, $col1X, 7, $colWidth - 2, $maxRows, $this.todoTasks, [PmcVT100]::Yellow())
        $this.RenderColumn(1, $col2X, 7, $colWidth - 2, $maxRows, $this.inProgressTasks, [PmcVT100]::Cyan())
        $this.RenderColumn(2, $col3X, 7, $colWidth - 2, $maxRows, $this.doneTasks, [PmcVT100]::Green())

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterKanban)
        $this.Terminal.EndFrame()
    }

    [void] RenderColumn([int]$colNum, [int]$x, [int]$startY, [int]$width, [int]$maxRows, [array]$tasks, [string]$color) {
        $y = $startY
        for ($i = 0; $i -lt $tasks.Count -and $i -lt $maxRows; $i++) {
            $task = $tasks[$i]
            $isSelected = ($colNum -eq $this.selectedColumn -and $i -eq $this.selectedIndex)

            $prefix = if ($isSelected) { "> " } else { "  " }
            $taskText = "$prefix#$($task.id) $($task.text)"

            if ($taskText.Length -gt $width) {
                $taskText = $taskText.Substring(0, $width - 3) + "..."
            }

            $displayColor = if ($isSelected) { [PmcVT100]::White() } else { $color }
            $this.Terminal.WriteAtColor($x + 2, $y, $taskText, $displayColor, "")
            $y++
        }
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        $currentTasks = $this.GetCurrentColumnTasks()

        switch ($key.Key) {
            'LeftArrow' {
                if ($this.selectedColumn -gt 0) {
                    $this.selectedColumn--
                    $this.selectedIndex = 0
                    return $true
                }
            }
            'RightArrow' {
                if ($this.selectedColumn -lt 2) {
                    $this.selectedColumn++
                    $this.selectedIndex = 0
                    return $true
                }
            }
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $currentTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $currentTasks.Count) {
                    $task = $currentTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadKanbanTasks()
                    return $true
                }
            }
            'D' {
                # Mark task as done (move to DONE column)
                if ($this.selectedIndex -lt $currentTasks.Count) {
                    $task = $currentTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $this.App.dataDirty = $true
                    $this.LoadKanbanTasks()
                    # Move selection to DONE column
                    $this.selectedColumn = 2
                    $this.selectedIndex = 0
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }

        # Number keys 1-3 to move task to column
        if ($key.KeyChar -ge '1' -and $key.KeyChar -le '3') {
            $targetCol = [int]$key.KeyChar.ToString() - 1
            if ($this.selectedIndex -lt $currentTasks.Count) {
                $task = $currentTasks[$this.selectedIndex]

                # Map column to status
                $newStatus = switch ($targetCol) {
                    0 { 'active' }     # TODO column
                    1 { 'in-progress' } # IN PROGRESS column
                    2 { 'completed' }   # DONE column
                    default { $task.status }
                }

                $task.status = $newStatus
                if ($newStatus -eq 'completed') {
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                } else {
                    try { $task.completed = $null } catch {}
                }

                $this.App.dataDirty = $true
                $this.LoadKanbanTasks()

                # Move selection to target column
                $this.selectedColumn = $targetCol
                $this.selectedIndex = 0
                return $true
            }
        }

        return $false
    }
}

# === ADDITIONAL DATE-FILTERED VIEW SCREENS ===

# No Due Date View Screen - Shows tasks without due dates
class NoDueDateViewScreen : PmcScreen {
    [array]$noDueDateTasks = @()
    [int]$selectedIndex = 0

    NoDueDateViewScreen() {
        $this.Title = "Tasks Without Due Date"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadNoDueDateTasks()
    }

    [void] LoadNoDueDateTasks() {
        $data = Get-PmcAllData
        $this.noDueDateTasks = @($data.tasks | Where-Object { $_.status -ne 'completed' -and -not $_.due })
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Tasks Without Due Date "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        if ($this.noDueDateTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, 6, "$($this.noDueDateTasks.Count) task(s) without due date:", [PmcVT100]::Yellow(), "")
            $y = 8
            $maxRows = $this.Terminal.Height - 11
            $endIndex = [Math]::Min($this.noDueDateTasks.Count, $maxRows)

            for ($i = 0; $i -lt $endIndex; $i++) {
                $task = $this.noDueDateTasks[$i]
                $proj = if ($task.project) { "@$($task.project)" } else { "" }
                $text = "[$($task.id)] $($task.text) $proj"

                if ($i -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(4, $y, $text)
                }
                $y++
            }
        } else {
            $this.Terminal.WriteAtColor(4, 6, "All tasks have due dates!", [PmcVT100]::Green(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterSelectEditToggle)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.noDueDateTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.noDueDateTasks.Count) {
                    $task = $this.noDueDateTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadNoDueDateTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.noDueDateTasks.Count) {
                    $task = $this.noDueDateTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed task $($task.id)"
                    $this.LoadNoDueDateTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Blocked View Screen - Shows blocked/waiting tasks
class BlockedViewScreen : PmcScreen {
    [array]$blockedTasks = @()
    [int]$selectedIndex = 0

    BlockedViewScreen() {
        $this.Title = "Blocked/Waiting Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadBlockedTasks()
    }

    [void] LoadBlockedTasks() {
        $data = Get-PmcAllData
        $this.blockedTasks = @($data.tasks | Where-Object { $_.status -eq 'blocked' -or $_.status -eq 'waiting' })
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Blocked/Waiting Tasks "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgRed(), [PmcVT100]::White())

        if ($this.blockedTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, 6, "$($this.blockedTasks.Count) blocked/waiting task(s):", [PmcVT100]::Red(), "")
            $y = 8
            $maxRows = $this.Terminal.Height - 11
            $endIndex = [Math]::Min($this.blockedTasks.Count, $maxRows)

            for ($i = 0; $i -lt $endIndex; $i++) {
                $task = $this.blockedTasks[$i]
                $statusText = if ($task.status -eq 'blocked') { "[BLOCKED]" } else { "[WAITING]" }
                $statusColor = if ($task.status -eq 'blocked') { [PmcVT100]::Red() } else { [PmcVT100]::Yellow() }
                $text = "$statusText [$($task.id)] $($task.text)"

                if ($i -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", $statusColor, "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(4, $y, $text, $statusColor, "")
                }
                $y++
            }
        } else {
            $this.Terminal.WriteAtColor(4, 6, "No blocked or waiting tasks!", [PmcVT100]::Green(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.blockedTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.blockedTasks.Count) {
                    $task = $this.blockedTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadBlockedTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.blockedTasks.Count) {
                    $task = $this.blockedTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed blocked task $($task.id)"
                    $this.LoadBlockedTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Tomorrow View Screen - Shows tasks due tomorrow
class TomorrowViewScreen : PmcScreen {
    [array]$tomorrowTasks = @()
    [int]$selectedIndex = 0

    TomorrowViewScreen() {
        $this.Title = "Tomorrow's Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadTomorrowTasks()
    }

    [void] LoadTomorrowTasks() {
        $data = Get-PmcAllData
        $tomorrow = (Get-Date).AddDays(1).Date
        $this.tomorrowTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.due -and
            ((Get-ConsoleUIDateOrNull $_.due).Date -eq $tomorrow)
        })
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Tomorrow's Tasks "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.tomorrowTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, 6, "$($this.tomorrowTasks.Count) task(s) due tomorrow:", [PmcVT100]::Cyan(), "")
            $y = 8
            $maxRows = $this.Terminal.Height - 11
            $endIndex = [Math]::Min($this.tomorrowTasks.Count, $maxRows)

            for ($i = 0; $i -lt $endIndex; $i++) {
                $task = $this.tomorrowTasks[$i]
                $pri = switch ($task.priority) {
                    'high' { '[!]' }
                    'medium' { '[*]' }
                    default { '[ ]' }
                }
                $text = "$pri [$($task.id)] $($task.text)"

                if ($i -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Cyan(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $priColor = if ($task.priority -eq 'high') { [PmcVT100]::Red() }
                                elseif ($task.priority -eq 'medium') { [PmcVT100]::Yellow() }
                                else { "" }
                    $this.Terminal.WriteAtColor(4, $y, $text, $priColor, "")
                }
                $y++
            }
        } else {
            $this.Terminal.WriteAtColor(4, 6, "No tasks due tomorrow!", [PmcVT100]::Green(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.tomorrowTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.tomorrowTasks.Count) {
                    $task = $this.tomorrowTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadTomorrowTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.tomorrowTasks.Count) {
                    $task = $this.tomorrowTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed tomorrow task $($task.id)"
                    $this.LoadTomorrowTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Upcoming View Screen - Shows tasks due in next 7 days (excluding today)
class UpcomingViewScreen : PmcScreen {
    [array]$upcomingTasks = @()
    [int]$selectedIndex = 0

    UpcomingViewScreen() {
        $this.Title = "Upcoming Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadUpcomingTasks()
    }

    [void] LoadUpcomingTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $weekEnd = $today.AddDays(7)
        $this.upcomingTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.due -and
            ([datetime]$dueDate = (Get-ConsoleUIDateOrNull $_.due).Date) -and
            ($dueDate -gt $today -and $dueDate -le $weekEnd)
        } | Sort-Object { (Get-ConsoleUIDateOrNull $_.due) })
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Upcoming Tasks (Next 7 Days) "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        if ($this.upcomingTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, 6, "$($this.upcomingTasks.Count) upcoming task(s):", [PmcVT100]::Green(), "")
            $y = 8
            $maxRows = $this.Terminal.Height - 11
            $endIndex = [Math]::Min($this.upcomingTasks.Count, $maxRows)
            $today = (Get-Date).Date

            for ($i = 0; $i -lt $endIndex; $i++) {
                $task = $this.upcomingTasks[$i]
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                $daysUntil = ($dueDate.Date - $today).Days
                $daysText = if ($daysUntil -eq 1) { "in 1 day" } else { "in $daysUntil days" }
                $text = "[$($task.id)] $($task.text) ($daysText)"

                if ($i -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Green(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(4, $y, $text)
                }
                $y++
            }
        } else {
            $this.Terminal.WriteAtColor(4, 6, "No upcoming tasks in the next 7 days!", [PmcVT100]::Green(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.upcomingTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.upcomingTasks.Count) {
                    $task = $this.upcomingTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadUpcomingTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.upcomingTasks.Count) {
                    $task = $this.upcomingTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed upcoming task $($task.id)"
                    $this.LoadUpcomingTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# === HIGH PRIORITY PROJECT & FOCUS SCREENS ===

# ProjectStatsScreen - Shows project statistics with navigation
class ProjectStatsScreen : PmcScreen {
    [array]$projects = @()
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0

    ProjectStatsScreen() {
        $this.Title = "Project Statistics"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadProjects()
    }

    [void] LoadProjects() {
        try {
            $data = Get-PmcAllData
            $this.projects = @($data.projects | ForEach-Object {
                if ($_ -is [string]) { $_ } else { $_.name }
            } | Where-Object { $_ })
            $this.selectedIndex = 0
            $this.scrollOffset = 0
        } catch {
            $this.projects = @()
        }
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Project Statistics "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.projects.Count -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No projects found", [PmcVT100]::Yellow(), "")
            $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
            $this.Terminal.EndFrame()
            return
        }

        try {
            $data = Get-PmcAllData

            # Draw headers
            $headerY = 5
            $this.Terminal.WriteAt(2, $headerY, "Project")
            $this.Terminal.WriteAt(30, $headerY, "Active")
            $this.Terminal.WriteAt(42, $headerY, "Done")
            $this.Terminal.WriteAt(52, $headerY, "Total")
            $this.Terminal.WriteAt(62, $headerY, "Compl%")
            $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

            # Draw project list with stats
            $startY = $headerY + 2
            $maxRows = $this.Terminal.Height - $startY - 3

            for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.projects.Count; $i++) {
                $projIdx = $i + $this.scrollOffset
                $projName = $this.projects[$projIdx]
                $y = $startY + $i

                $projTasks = @($data.tasks | Where-Object { $_.project -eq $projName })
                $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                $total = $projTasks.Count
                $completionPct = if ($total -gt 0) { [Math]::Round(($completed / $total) * 100, 1) } else { 0 }

                $isSelected = ($projIdx -eq $this.selectedIndex)
                $prefix = if ($isSelected) { "> " } else { "  " }
                $bg = if ($isSelected) { [PmcVT100]::BgBlue() } else { "" }
                $fg = if ($isSelected) { [PmcVT100]::White() } else { "" }

                $projDisplay = $projName.Substring(0, [Math]::Min(24, $projName.Length)).PadRight(24)

                if ($bg) {
                    $this.Terminal.WriteAtColor(2, $y, ($prefix + $projDisplay).PadRight(28), $bg, $fg)
                    $this.Terminal.WriteAtColor(30, $y, $active.ToString().PadRight(10), $bg, [PmcVT100]::Cyan())
                    $this.Terminal.WriteAtColor(42, $y, $completed.ToString().PadRight(8), $bg, [PmcVT100]::Yellow())
                    $this.Terminal.WriteAtColor(52, $y, $total.ToString().PadRight(8), $bg, $fg)
                    $this.Terminal.WriteAtColor(62, $y, "$completionPct%", $bg, [PmcVT100]::Green())
                } else {
                    $this.Terminal.WriteAtColor(2, $y, $prefix + $projDisplay, [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(30, $y, $active.ToString(), [PmcVT100]::Cyan(), "")
                    $this.Terminal.WriteAtColor(42, $y, $completed.ToString(), [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(52, $y, $total.ToString(), "", "")
                    $this.Terminal.WriteAtColor(62, $y, "$completionPct%", [PmcVT100]::Green(), "")
                }
            }

            # Show selected project details
            if ($this.selectedIndex -lt $this.projects.Count) {
                $selectedProj = $this.projects[$this.selectedIndex]
                $projTasks = @($data.tasks | Where-Object { $_.project -eq $selectedProj })
                $overdue = @($projTasks | Where-Object {
                    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
                    $d = Get-ConsoleUIDateOrNull $_.due
                    if ($d) { return ($d.Date -lt (Get-Date).Date) } else { return $false }
                }).Count

                $detailY = $this.Terminal.Height - 5
                $this.Terminal.WriteAtColor(4, $detailY, "Selected: ", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAt(14, $detailY, $selectedProj)
                if ($overdue -gt 0) {
                    $this.Terminal.WriteAtColor(50, $detailY, "Overdue: $overdue", [PmcVT100]::Red(), "")
                }
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading project stats: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    if ($this.selectedIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.projects.Count - 1) {
                    $this.selectedIndex++
                    $maxRows = $this.Terminal.Height - 10
                    if ($this.selectedIndex -ge $this.scrollOffset + $maxRows) {
                        $this.scrollOffset = $this.selectedIndex - $maxRows + 1
                    }
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# ProjectInfoScreen - Shows detailed project information
class ProjectInfoScreen : PmcScreen {
    [array]$projects = @()
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0

    ProjectInfoScreen() {
        $this.Title = "Project Information"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadProjects()
    }

    [void] LoadProjects() {
        try {
            $data = Get-PmcAllData
            $this.projects = @($data.projects | ForEach-Object {
                if ($_ -is [string]) { $_ } else { $_.name }
            } | Where-Object { $_ })
            $this.selectedIndex = 0
            $this.scrollOffset = 0
        } catch {
            $this.projects = @()
        }
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Project Information "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.projects.Count -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No projects found", [PmcVT100]::Yellow(), "")
            $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
            $this.Terminal.EndFrame()
            return
        }

        try {
            $data = Get-PmcAllData

            # Draw headers
            $headerY = 5
            $this.Terminal.WriteAt(2, $headerY, "Project")
            $this.Terminal.WriteAt(30, $headerY, "Tasks")
            $this.Terminal.WriteAt(42, $headerY, "Status")
            $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

            # Draw project list
            $startY = $headerY + 2
            $maxRows = $this.Terminal.Height - $startY - 8

            for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.projects.Count; $i++) {
                $projIdx = $i + $this.scrollOffset
                $projName = $this.projects[$projIdx]
                $y = $startY + $i

                $projTasks = @($data.tasks | Where-Object { $_.project -eq $projName })
                $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                $total = $projTasks.Count
                $statusText = "$completed/$total"

                $isSelected = ($projIdx -eq $this.selectedIndex)
                $prefix = if ($isSelected) { "> " } else { "  " }
                $bg = if ($isSelected) { [PmcVT100]::BgBlue() } else { "" }
                $fg = if ($isSelected) { [PmcVT100]::White() } else { "" }

                $projDisplay = $projName.Substring(0, [Math]::Min(24, $projName.Length)).PadRight(24)

                if ($bg) {
                    $this.Terminal.WriteAtColor(2, $y, ($prefix + $projDisplay).PadRight(28), $bg, $fg)
                    $this.Terminal.WriteAtColor(30, $y, $total.ToString().PadRight(10), $bg, $fg)
                    $this.Terminal.WriteAtColor(42, $y, $statusText, $bg, [PmcVT100]::Green())
                } else {
                    $this.Terminal.WriteAtColor(2, $y, $prefix + $projDisplay, [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(30, $y, $total.ToString(), [PmcVT100]::Cyan(), "")
                    $this.Terminal.WriteAtColor(42, $y, $statusText, [PmcVT100]::Green(), "")
                }
            }

            # Show selected project details in bottom panel
            if ($this.selectedIndex -lt $this.projects.Count) {
                $selectedProj = $this.projects[$this.selectedIndex]
                $project = $data.projects | Where-Object {
                    ($_ -is [string] -and $_ -eq $selectedProj) -or
                    ($_.PSObject.Properties['name'] -and $_.name -eq $selectedProj)
                } | Select-Object -First 1

                $detailY = $this.Terminal.Height - 6
                $this.Terminal.DrawHorizontalLine(0, $detailY - 1, $this.Terminal.Width)
                $this.Terminal.WriteAtColor(2, $detailY, "Project: ", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAt(12, $detailY, $selectedProj)

                if ($project -and ($project -isnot [string])) {
                    $y = $detailY + 1
                    if ($project.PSObject.Properties['description'] -and $project.description) {
                        $desc = $project.description.Substring(0, [Math]::Min(60, $project.description.Length))
                        $this.Terminal.WriteAt(2, $y++, "Description: $desc")
                    }
                    if ($project.PSObject.Properties['status'] -and $project.status) {
                        $this.Terminal.WriteAt(2, $y++, "Status: $($project.status)")
                    }
                }

                $projTasks = @($data.tasks | Where-Object { $_.project -eq $selectedProj })
                $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                $this.Terminal.WriteAt(2, $detailY + 2, "Active: $active | Completed: $completed | Total: $($projTasks.Count)")
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading project info: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter("↑↓:Navigate | Enter:Full Details | Esc:Back")
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    if ($this.selectedIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.projects.Count - 1) {
                    $this.selectedIndex++
                    $maxRows = $this.Terminal.Height - 13
                    if ($this.selectedIndex -ge $this.scrollOffset + $maxRows) {
                        $this.scrollOffset = $this.selectedIndex - $maxRows + 1
                    }
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.projects.Count) {
                    $selectedProj = $this.projects[$this.selectedIndex]
                    $this.ShowFullProjectDetail($selectedProj)
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }

    [void] ShowFullProjectDetail([string]$projectName) {
        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object {
                ($_ -is [string] -and $_ -eq $projectName) -or
                ($_.PSObject.Properties['name'] -and $_.name -eq $projectName)
            } | Select-Object -First 1

            $this.Terminal.Clear()
            $this.MenuSystem.DrawMenuBar()

            $title = " Project Details "
            $titleX = ($this.Terminal.Width - $title.Length) / 2
            $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            $y = 6
            $this.Terminal.WriteAtColor(4, $y++, "Project: $projectName", [PmcVT100]::Cyan(), "")
            $y++

            if ($project -and ($project -isnot [string])) {
                if ($project.PSObject.Properties['description'] -and $project.description) {
                    $this.Terminal.WriteAt(4, $y++, "Description: $($project.description)")
                }
                if ($project.PSObject.Properties['status'] -and $project.status) {
                    $this.Terminal.WriteAt(4, $y++, "Status: $($project.status)")
                }
                if ($project.PSObject.Properties['created'] -and $project.created) {
                    $this.Terminal.WriteAt(4, $y++, "Created: $($project.created)")
                }
                if ($project.PSObject.Properties['tags'] -and $project.tags) {
                    $this.Terminal.WriteAt(4, $y++, "Tags: $($project.tags -join ', ')")
                }
                $y++
            }

            # Task breakdown
            $projTasks = @($data.tasks | Where-Object { $_.project -eq $projectName })
            $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
            $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
            $total = $projTasks.Count

            $this.Terminal.WriteAtColor(4, $y++, "Task Breakdown:", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAt(4, $y++, "  Total tasks: $total")
            $this.Terminal.WriteAt(4, $y++, "  Active: $active")
            $this.Terminal.WriteAt(4, $y++, "  Completed: $completed")

            if ($total -gt 0) {
                $completionPct = [Math]::Round(($completed / $total) * 100, 1)
                $this.Terminal.WriteAtColor(4, $y++, "  Completion: $completionPct%", [PmcVT100]::Green(), "")
            }

            $this.Terminal.DrawFooter([PmcUIStringCache]::FooterPressAnyKey)
            [Console]::ReadKey($true) | Out-Null
            $this.Invalidate()
        } catch {
            Show-InfoMessage -Message "Error loading project details: $_" -Title "Error" -Color "Red"
        }
    }
}

# FocusSetFormScreen - Form to select a task/project to focus on
class FocusSetFormScreen : PmcScreen {

    FocusSetFormScreen() {
        $this.Title = "Set Focus"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.ShowFocusForm()
    }

    [void] ShowFocusForm() {
        try {
            $data = Get-PmcAllData
            $projectList = @('inbox') + @($data.projects | ForEach-Object {
                if ($_ -is [string]) { $_ } else { $_.name }
            } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

            $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

            $selected = Show-SelectList -Title "Select Focus Context" -Options $projectList -DefaultValue $currentContext

            if ($selected) {
                try {
                    if (-not $data.PSObject.Properties['currentContext']) {
                        $data | Add-Member -NotePropertyName currentContext -NotePropertyValue $selected -Force
                    } else {
                        $data.currentContext = $selected
                    }
                    Save-PmcData -Data $data -Action "Set focus to $selected"
                    Show-InfoMessage -Message "Focus set to: $selected" -Title "Success" -Color "Green"
                } catch {
                    Show-InfoMessage -Message "Failed to set focus: $_" -Title "Error" -Color "Red"
                }
            }
        } catch {
            Show-InfoMessage -Message "Error loading projects: $_" -Title "Error" -Color "Red"
        }

        $this.App.GoBack()
    }

    [void] Render() {
        # Form is shown via Show-SelectList, this is just fallback
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Set Focus "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.Terminal.WriteAtColor(4, 6, "Loading...", [PmcVT100]::Yellow(), "")
        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterPleaseWait)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input handled by Show-SelectList
        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }
        return $false
    }
}

# FocusClearScreen - Confirmation to clear current focus
class FocusClearScreen : PmcScreen {

    FocusClearScreen() {
        $this.Title = "Clear Focus"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Clear Focus "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

            $y = 6
            $this.Terminal.WriteAtColor(4, $y++, "Current focus: ", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAt(20, $y - 1, $currentContext)
            $y++
            $this.Terminal.WriteAtColor(4, $y++, "Clear the current focus selection?", [PmcVT100]::Cyan(), "")
            $y++
            $this.Terminal.WriteAtColor(4, $y, "Press 'Y' to clear focus, 'N' to cancel.", [PmcVT100]::Yellow(), "")
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading focus status: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter("Y:Clear | N:Cancel | Esc:Back")
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.KeyChar) {
            'Y' {
                try {
                    $data = Get-PmcAllData
                    if ($data.PSObject.Properties['currentContext']) {
                        $data.currentContext = 'inbox'
                    } else {
                        $data | Add-Member -NotePropertyName currentContext -NotePropertyValue 'inbox' -Force
                    }
                    Save-PmcData -Data $data -Action "Cleared focus"
                    Show-InfoMessage -Message "Focus cleared (reset to inbox)" -Title "Success" -Color "Green"
                } catch {
                    Show-InfoMessage -Message "Failed to clear focus: $_" -Title "Error" -Color "Red"
                }
                $this.App.GoBack()
                return $true
            }
            'y' {
                try {
                    $data = Get-PmcAllData
                    if ($data.PSObject.Properties['currentContext']) {
                        $data.currentContext = 'inbox'
                    } else {
                        $data | Add-Member -NotePropertyName currentContext -NotePropertyValue 'inbox' -Force
                    }
                    Save-PmcData -Data $data -Action "Cleared focus"
                    Show-InfoMessage -Message "Focus cleared (reset to inbox)" -Title "Success" -Color "Green"
                } catch {
                    Show-InfoMessage -Message "Failed to clear focus: $_" -Title "Error" -Color "Red"
                }
                $this.App.GoBack()
                return $true
            }
            'N' {
                $this.App.GoBack()
                return $true
            }
            'n' {
                $this.App.GoBack()
                return $true
            }
        }

        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }

        return $false
    }
}

# FocusStatusScreen - Displays currently focused task/project
class FocusStatusScreen : PmcScreen {

    FocusStatusScreen() {
        $this.Title = "Focus Status"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Focus Status "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

            $this.Terminal.WriteAtColor(4, 6, "Current Focus:", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAt(20, 6, $currentContext)

            if ($currentContext -and $currentContext -ne 'inbox') {
                $contextTasks = @($data.tasks | Where-Object {
                    $_.project -eq $currentContext -and $_.status -ne 'completed'
                })

                $this.Terminal.WriteAtColor(4, 8, "Active Tasks:", [PmcVT100]::Yellow(), "")
                $this.Terminal.WriteAt(18, 8, "$($contextTasks.Count)")

                $overdue = @($contextTasks | Where-Object {
                    if (-not $_.due) { return $false }
                    $d = Get-ConsoleUIDateOrNull $_.due
                    if ($d) { return ($d.Date -lt (Get-Date).Date) } else { return $false }
                })

                if ($overdue.Count -gt 0) {
                    $this.Terminal.WriteAtColor(4, 9, "Overdue:", [PmcVT100]::Red(), "")
                    $this.Terminal.WriteAt(18, 9, "$($overdue.Count)")
                }

                # Show some task details
                if ($contextTasks.Count -gt 0) {
                    $y = 11
                    $this.Terminal.WriteAtColor(4, $y++, "Recent tasks:", [PmcVT100]::Cyan(), "")
                    $maxTasks = [Math]::Min(5, $contextTasks.Count)
                    for ($i = 0; $i -lt $maxTasks; $i++) {
                        $task = $contextTasks[$i]
                        $taskText = $task.text.Substring(0, [Math]::Min(60, $task.text.Length))
                        $this.Terminal.WriteAt(6, $y++, "[$($task.id)] $taskText")
                    }
                }
            } else {
                $y = 8
                $this.Terminal.WriteAtColor(4, $y++, "Focus is set to inbox (all tasks)", [PmcVT100]::Cyan(), "")
                $allTasks = @($data.tasks | Where-Object { $_.status -ne 'completed' })
                $this.Terminal.WriteAt(4, $y++, "Total active tasks: $($allTasks.Count)")
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading focus status: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }
        return $false
    }
}

# Search Form Screen - Interactive search with live results
class SearchFormScreen : PmcScreen {
    [string]$searchQuery = ""
    [array]$searchResults = @()
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0

    SearchFormScreen() {
        $this.Title = "Search Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.searchQuery = ""
        $this.searchResults = @()
        $this.selectedIndex = 0
        $this.scrollOffset = 0
    }

    [void] PerformSearch() {
        try {
            if ([string]::IsNullOrWhiteSpace($this.searchQuery)) {
                $this.searchResults = @()
                return
            }

            $data = Get-PmcAllData
            $query = $this.searchQuery.ToLower()

            # Search in: task text, project, tags, notes
            $this.searchResults = @($data.tasks | Where-Object {
                $textMatch = $_.text -and $_.text.ToLower().Contains($query)
                $projectMatch = $_.project -and $_.project.ToLower().Contains($query)
                $tagsMatch = $_.tags -and $_.tags.ToLower().Contains($query)
                $notesMatch = $_.notes -and $_.notes.ToLower().Contains($query)

                return ($textMatch -or $projectMatch -or $tagsMatch -or $notesMatch)
            } | Select-Object -First 50)  # Limit results

            # Reset selection if out of bounds
            if ($this.selectedIndex -ge $this.searchResults.Count) {
                $this.selectedIndex = 0
                $this.scrollOffset = 0
            }
        } catch {
            $this.searchResults = @()
        }
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        # Title
        $title = " Search Tasks "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Search input area
        $this.Terminal.WriteAtColor(4, 5, "Search for:", [PmcVT100]::Yellow(), "")
        $searchDisplayY = 6
        $this.Terminal.WriteAtColor(4, $searchDisplayY, "> ", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAtColor(6, $searchDisplayY, $this.searchQuery, [PmcVT100]::White(), "")

        # Show cursor at end of search text
        $cursorX = 6 + $this.searchQuery.Length
        if ($cursorX -lt $this.Terminal.Width - 1) {
            $this.Terminal.WriteAtColor($cursorX, $searchDisplayY, "_", [PmcVT100]::Yellow(), "")
        }

        # Results header
        $resultsY = 8
        if ($this.searchQuery.Length -gt 0) {
            $resultCount = $this.searchResults.Count
            $resultsHeader = "Found $resultCount result(s):"
            $this.Terminal.WriteAtColor(4, $resultsY, $resultsHeader, [PmcVT100]::Cyan(), "")
            $this.Terminal.DrawHorizontalLine(0, $resultsY + 1, $this.Terminal.Width)

            # Draw results
            $startY = $resultsY + 2
            $maxRows = $this.Terminal.Height - $startY - 3

            for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.searchResults.Count; $i++) {
                $resultIdx = $i + $this.scrollOffset
                $task = $this.searchResults[$resultIdx]
                $y = $startY + $i
                $isSelected = ($resultIdx -eq $this.selectedIndex)

                # Highlight search terms in task text
                $text = if ($task.text) { $task.text } else { "" }
                if ($text.Length -gt 60) { $text = $text.Substring(0, 57) + "..." }

                $displayText = "[$($task.id)] $text"
                if ($task.project) { $displayText += " ($($task.project))" }

                if ($isSelected) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $displayText, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(4, $y, $displayText)
                }
            }
        } else {
            $this.Terminal.WriteAtColor(4, $resultsY, "Type to search in tasks, projects, tags, and notes...", [PmcVT100]::Cyan(), "")
        }

        $this.Terminal.DrawFooter("Type:Search | ↑↓:Navigate | Enter:View | Esc:Cancel")
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.searchResults.Count -gt 0 -and $this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    if ($this.selectedIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.searchResults.Count - 1) {
                    $this.selectedIndex++
                    $maxRows = $this.Terminal.Height - 13
                    if ($this.selectedIndex -ge $this.scrollOffset + $maxRows) {
                        $this.scrollOffset = $this.selectedIndex - $maxRows + 1
                    }
                    return $true
                }
            }
            'Enter' {
                if ($this.searchResults.Count -gt 0 -and $this.selectedIndex -lt $this.searchResults.Count) {
                    $task = $this.searchResults[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    # Refresh search results after edit
                    $this.PerformSearch()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
            'Backspace' {
                if ($this.searchQuery.Length -gt 0) {
                    $this.searchQuery = $this.searchQuery.Substring(0, $this.searchQuery.Length - 1)
                    $this.PerformSearch()
                    return $true
                }
            }
            default {
                # Handle character input
                $char = $key.KeyChar
                if ($char -and $char -ne "`0" -and -not [char]::IsControl($char)) {
                    $this.searchQuery += $char
                    $this.PerformSearch()
                    return $true
                }
            }
        }
        return $false
    }
}

# Multi-Select Mode Screen - Batch task operations with checkbox interface
class MultiSelectModeScreen : PmcScreen {
    [array]$tasks = @()
    [hashtable]$selectedTasks = @{}
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0
    [string]$filterProject = ""
    [string]$searchText = ""

    MultiSelectModeScreen() {
        $this.Title = "Multi-Select Mode"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadTasks()
    }

    [void] LoadTasks() {
        try {
            $data = Get-PmcAllData

            # Apply same filters as task list
            $this.filterProject = $this.App.filterProject
            $this.searchText = $this.App.searchText

            $this.tasks = @($data.tasks | Where-Object {
                $matchesFilter = $true

                # Filter by project
                if ($this.filterProject) {
                    $matchesFilter = $matchesFilter -and ($_.project -eq $this.filterProject)
                }

                # Filter by search text
                if ($this.searchText) {
                    $query = $this.searchText.ToLower()
                    $textMatch = $_.text -and $_.text.ToLower().Contains($query)
                    $projectMatch = $_.project -and $_.project.ToLower().Contains($query)
                    $tagsMatch = $_.tags -and $_.tags.ToLower().Contains($query)
                    $matchesFilter = $matchesFilter -and ($textMatch -or $projectMatch -or $tagsMatch)
                }

                return $matchesFilter
            })

            # Sort by current sort order
            switch ($this.App.sortBy) {
                'id' { $this.tasks = @($this.tasks | Sort-Object id) }
                'priority' { $this.tasks = @($this.tasks | Sort-Object priority) }
                'status' { $this.tasks = @($this.tasks | Sort-Object status) }
                'created' { $this.tasks = @($this.tasks | Sort-Object created) }
                'due' { $this.tasks = @($this.tasks | Sort-Object due) }
                default { $this.tasks = @($this.tasks | Sort-Object id) }
            }

            # Clear selections that are no longer valid
            $validIds = @($this.tasks | ForEach-Object { $_.id })
            $keysToRemove = @($this.selectedTasks.Keys | Where-Object { $_ -notin $validIds })
            foreach ($key in $keysToRemove) {
                $this.selectedTasks.Remove($key)
            }

            $this.Invalidate()
        } catch {
            $this.tasks = @()
        }
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        # Title with selection count
        $selectedCount = ($this.selectedTasks.Values | Where-Object { $_ -eq $true }).Count
        $title = " Multi-Select Mode ($selectedCount selected) "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        # Column headers
        $headerY = 5
        $this.Terminal.WriteAt(2, $headerY, "Sel")
        $this.Terminal.WriteAt(8, $headerY, "ID")
        $this.Terminal.WriteAt(14, $headerY, "Status")
        $this.Terminal.WriteAt(24, $headerY, "Pri")
        $this.Terminal.WriteAt(30, $headerY, "Task")
        $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

        # Task list
        $startY = $headerY + 2
        $maxRows = $this.Terminal.Height - $startY - 3

        for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.tasks.Count; $i++) {
            $taskIdx = $i + $this.scrollOffset
            $task = $this.tasks[$taskIdx]
            $y = $startY + $i
            $isSelected = ($taskIdx -eq $this.selectedIndex)
            $isMarked = $this.selectedTasks[$task.id] -eq $true

            # Highlight current row
            if ($isSelected) {
                $this.Terminal.FillArea(0, $y, $this.Terminal.Width, 1, ' ')
                $this.Terminal.WriteAtColor(0, $y, ">", [PmcVT100]::Yellow(), "")
            }

            # Checkbox
            $marker = if ($isMarked) { '[X]' } else { '[ ]' }
            $markerColor = if ($isMarked) { [PmcVT100]::Green() } else { "" }
            if ($markerColor) {
                $this.Terminal.WriteAtColor(2, $y, $marker, $markerColor, "")
            } else {
                $this.Terminal.WriteAt(2, $y, $marker)
            }

            # Task details
            $statusIcon = if ($task.status -eq 'completed') { 'X' } else { 'o' }
            $this.Terminal.WriteAt(8, $y, $task.id.ToString())
            $this.Terminal.WriteAt(14, $y, $statusIcon)

            $priVal = if ($task.priority) { $task.priority } else { 'none' }
            $priChar = $priVal.Substring(0,1).ToUpper()
            $this.Terminal.WriteAt(24, $y, $priChar)

            $text = if ($task.text) { $task.text } else { "" }
            if ($text.Length -gt 45) { $text = $text.Substring(0, 42) + "..." }
            $this.Terminal.WriteAt(30, $y, $text)
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterMultiSelect)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    if ($this.selectedIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.tasks.Count - 1) {
                    $this.selectedIndex++
                    $maxRows = $this.Terminal.Height - 10
                    if ($this.selectedIndex -ge $this.scrollOffset + $maxRows) {
                        $this.scrollOffset = $this.selectedIndex - $maxRows + 1
                    }
                    return $true
                }
            }
            'Spacebar' {
                # Toggle selection for current task
                if ($this.selectedIndex -lt $this.tasks.Count) {
                    $task = $this.tasks[$this.selectedIndex]
                    $this.selectedTasks[$task.id] = -not ($this.selectedTasks[$task.id] -eq $true)
                    return $true
                }
            }
            'A' {
                # Select all tasks
                foreach ($task in $this.tasks) {
                    $this.selectedTasks[$task.id] = $true
                }
                return $true
            }
            'N' {
                # Clear all selections
                $this.selectedTasks.Clear()
                return $true
            }
            'C' {
                # Complete selected tasks
                $selectedIds = @($this.selectedTasks.Keys | Where-Object { $this.selectedTasks[$_] -eq $true })
                if ($selectedIds.Count -gt 0) {
                    try {
                        $data = Get-PmcAllData
                        $count = 0
                        foreach ($id in $selectedIds) {
                            $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                            if ($task) {
                                $task.status = 'completed'
                                $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                                $count++
                            }
                        }
                        if ($count -gt 0) {
                            Save-PmcData -Data $data -Action "Completed $count tasks"
                            Show-InfoMessage -Message "Completed $count task(s)" -Title "Success" -Color "Green"
                            $this.selectedTasks.Clear()
                            $this.LoadTasks()
                        }
                    } catch {
                        Show-InfoMessage -Message "Error completing tasks: $_" -Title "Error" -Color "Red"
                    }
                    return $true
                }
            }
            'X' {
                # Delete selected tasks
                $selectedIds = @($this.selectedTasks.Keys | Where-Object { $this.selectedTasks[$_] -eq $true })
                if ($selectedIds.Count -gt 0) {
                    try {
                        $data = Get-PmcAllData
                        $count = 0
                        $data.tasks = @($data.tasks | Where-Object {
                            if ($_.id -in $selectedIds) {
                                $count++
                                return $false
                            }
                            return $true
                        })
                        if ($count -gt 0) {
                            Save-PmcData -Data $data -Action "Deleted $count tasks"
                            Show-InfoMessage -Message "Deleted $count task(s)" -Title "Success" -Color "Green"
                            $this.selectedTasks.Clear()
                            $this.LoadTasks()
                        }
                    } catch {
                        Show-InfoMessage -Message "Error deleting tasks: $_" -Title "Error" -Color "Red"
                    }
                    return $true
                }
            }
            'P' {
                # Set priority for selected tasks
                $selectedIds = @($this.selectedTasks.Keys | Where-Object { $this.selectedTasks[$_] -eq $true })
                if ($selectedIds.Count -gt 0) {
                    try {
                        $result = Show-InputForm -Title "Set Priority" -Fields @(
                            @{Name='priority'; Label='Priority'; Required=$true; Type='select'; Options=@('high','medium','low','none')}
                        )
                        if ($result) {
                            $data = Get-PmcAllData
                            $count = 0
                            foreach ($id in $selectedIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.priority = $result.priority
                                    $count++
                                }
                            }
                            if ($count -gt 0) {
                                Save-PmcData -Data $data -Action "Set priority for $count tasks"
                                Show-InfoMessage -Message "Updated priority for $count task(s)" -Title "Success" -Color "Green"
                                $this.selectedTasks.Clear()
                                $this.LoadTasks()
                            }
                        }
                    } catch {
                        Show-InfoMessage -Message "Error setting priority: $_" -Title "Error" -Color "Red"
                    }
                    return $true
                }
            }
            'J' {
                # Move selected tasks to project
                $selectedIds = @($this.selectedTasks.Keys | Where-Object { $this.selectedTasks[$_] -eq $true })
                if ($selectedIds.Count -gt 0) {
                    try {
                        $data = Get-PmcAllData
                        $projectNames = @($data.projects | ForEach-Object {
                            if ($_ -is [string]) { $_ } else { $_.name }
                        })

                        $result = Show-InputForm -Title "Move to Project" -Fields @(
                            @{Name='project'; Label='Project'; Required=$true; Type='select'; Options=$projectNames}
                        )
                        if ($result) {
                            $count = 0
                            foreach ($id in $selectedIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.project = $result.project
                                    $count++
                                }
                            }
                            if ($count -gt 0) {
                                Save-PmcData -Data $data -Action "Moved $count tasks to $($result.project)"
                                Show-InfoMessage -Message "Moved $count task(s) to $($result.project)" -Title "Success" -Color "Green"
                                $this.selectedTasks.Clear()
                                $this.LoadTasks()
                            }
                        }
                    } catch {
                        Show-InfoMessage -Message "Error moving tasks: $_" -Title "Error" -Color "Red"
                    }
                    return $true
                }
            }
            'Escape' {
                # Exit multi-select mode
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Next Actions View Screen - Shows high priority and upcoming tasks
class NextActionsViewScreen : PmcScreen {
    [array]$nextActionsTasks = @()
    [int]$selectedIndex = 0

    NextActionsViewScreen() {
        $this.Title = "Next Actions"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadNextActionsTasks()
    }

    [void] LoadNextActionsTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $this.nextActionsTasks = @($data.tasks | Where-Object {
            $_.status -ne 'completed' -and
            $_.status -ne 'blocked' -and
            $_.status -ne 'waiting' -and
            ($_.priority -eq 'high' -or -not $_.due -or ((($d = Get-ConsoleUIDateOrNull $_.due)) -and $d.Date -le $today.AddDays(7)))
        } | Sort-Object {
            if ($_.priority -eq 'high') { 0 }
            elseif ($_.priority -eq 'medium') { 1 }
            else { 2 }
        } | Select-Object -First 20)
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Next Actions "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        if ($this.nextActionsTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, 6, "$($this.nextActionsTasks.Count) next action(s):", [PmcVT100]::Green(), "")
            $y = 8
            $maxRows = $this.Terminal.Height - 11
            $endIndex = [Math]::Min($this.nextActionsTasks.Count, $maxRows)

            for ($i = 0; $i -lt $endIndex; $i++) {
                $task = $this.nextActionsTasks[$i]
                $pri = if ($task.priority -eq 'high') { "[!]" } elseif ($task.priority -eq 'medium') { "[*]" } else { "[ ]" }
                $dueDt = if ($task.due) { Get-ConsoleUIDateOrNull $task.due } else { $null }
                $due = if ($dueDt) { " ($($dueDt.ToString('MMM dd')))" } else { "" }
                $text = "$pri [$($task.id)] $($task.text)$due"

                if ($i -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(4, $y, $text)
                }
                $y++
            }
        } else {
            $this.Terminal.WriteAtColor(4, 6, "No next actions found", [PmcVT100]::Yellow(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.nextActionsTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.nextActionsTasks.Count) {
                    $task = $this.nextActionsTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadNextActionsTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.nextActionsTasks.Count) {
                    $task = $this.nextActionsTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed next action task $($task.id)"
                    $this.LoadNextActionsTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Month View Screen - Shows tasks with 3 sections: overdue, this month, no due date
class MonthViewScreen : PmcScreen {
    [array]$overdueTasks = @()
    [array]$thisMonthTasks = @()
    [array]$noDueTasks = @()
    [int]$selectedIndex = 0
    [int]$totalTasks = 0

    MonthViewScreen() {
        $this.Title = "This Month's Tasks"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadMonthTasks()
    }

    [void] LoadMonthTasks() {
        $data = Get-PmcAllData
        $today = (Get-Date).Date
        $monthEnd = $today.AddDays(30)

        # Get overdue tasks
        $this.overdueTasks = @($data.tasks | Where-Object {
            if ($_.status -eq 'completed' -or -not $_.due) { return $false }
            $d = Get-ConsoleUIDateOrNull $_.due
            if ($d) { return ($d.Date -lt $today) } else { return $false }
        } | Sort-Object { ($tmp = Get-ConsoleUIDateOrNull $_.due); if ($tmp) { $tmp } else { [DateTime]::MaxValue } })

        # Get tasks due this month
        $this.thisMonthTasks = @($data.tasks | Where-Object {
            if ($_.status -eq 'completed' -or -not $_.due) { return $false }
            $d = Get-ConsoleUIDateOrNull $_.due
            if ($d) { return ($d.Date -ge $today -and $d.Date -le $monthEnd) } else { return $false }
        } | Sort-Object { ($tmp = Get-ConsoleUIDateOrNull $_.due); if ($tmp) { $tmp } else { [DateTime]::MaxValue } })

        # Get undated tasks
        $this.noDueTasks = @($data.tasks | Where-Object { $_.status -ne 'completed' -and -not $_.due })

        $this.totalTasks = $this.overdueTasks.Count + $this.thisMonthTasks.Count + $this.noDueTasks.Count
        $this.Invalidate()
    }

    [object] GetSelectedTask() {
        $idx = $this.selectedIndex
        if ($idx -lt $this.overdueTasks.Count) {
            return $this.overdueTasks[$idx]
        }
        $idx -= $this.overdueTasks.Count
        if ($idx -lt $this.thisMonthTasks.Count) {
            return $this.thisMonthTasks[$idx]
        }
        $idx -= $this.thisMonthTasks.Count
        if ($idx -lt $this.noDueTasks.Count) {
            return $this.noDueTasks[$idx]
        }
        return $null
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " This Month's Tasks "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgMagenta(), [PmcVT100]::White())

        $y = 6
        $maxY = $this.Terminal.Height - 3
        $currentTaskIndex = 0
        $today = (Get-Date).Date

        # Show overdue tasks section
        if ($this.overdueTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, $y++, "=== OVERDUE ($($this.overdueTasks.Count)) ===", [PmcVT100]::BgRed(), [PmcVT100]::White())
            $y++
            foreach ($task in $this.overdueTasks) {
                if ($y -ge $maxY) { break }
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                if (-not $dueDate) { $currentTaskIndex++; continue }
                $daysOverdue = ($today - $dueDate.Date).Days
                $text = "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::Red(), "")
                }
                $y++
                $currentTaskIndex++
            }
            $y++
        }

        # Show this month's tasks section
        if ($this.thisMonthTasks.Count -gt 0 -and $y -lt $maxY) {
            $this.Terminal.WriteAtColor(4, $y++, "=== DUE THIS MONTH ($($this.thisMonthTasks.Count)) ===", [PmcVT100]::Cyan(), "")
            $y++
            foreach ($task in $this.thisMonthTasks) {
                if ($y -ge $maxY) { break }
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                if (-not $dueDate) { $currentTaskIndex++; continue }
                $text = "[$($task.id)] $($dueDate.ToString('MMM dd')) - $($task.text)"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(4, $y, $text)
                }
                $y++
                $currentTaskIndex++
            }
            $y++
        }

        # Show undated tasks section
        if ($this.noDueTasks.Count -gt 0 -and $y -lt $maxY) {
            $this.Terminal.WriteAtColor(4, $y++, "=== NO DUE DATE ($($this.noDueTasks.Count)) ===", [PmcVT100]::Yellow(), "")
            $y++
            foreach ($task in $this.noDueTasks) {
                if ($y -ge $maxY) { break }
                $text = "[$($task.id)] $($task.text)"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(4, $y, $text, [PmcVT100]::Yellow(), "")
                }
                $y++
                $currentTaskIndex++
            }
        }

        if ($this.totalTasks -eq 0) {
            $this.Terminal.WriteAtColor(4, 6, "No active tasks", [PmcVT100]::Green(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.totalTasks - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                $task = $this.GetSelectedTask()
                if ($task) {
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadMonthTasks()
                    return $true
                }
            }
            'D' {
                $task = $this.GetSelectedTask()
                if ($task) {
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed month view task $($task.id)"
                    $this.LoadMonthTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Agenda View Screen - Shows tasks grouped by date with 6 sections
class AgendaViewScreen : PmcScreen {
    [array]$overdueTasks = @()
    [array]$todayTasks = @()
    [array]$tomorrowTasks = @()
    [array]$thisWeekTasks = @()
    [array]$laterTasks = @()
    [array]$noDueTasks = @()
    [int]$selectedIndex = 0
    [array]$selectableTasks = @()

    AgendaViewScreen() {
        $this.Title = "Agenda View"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadAgendaTasks()
    }

    [void] LoadAgendaTasks() {
        $data = Get-PmcAllData
        $activeTasks = @($data.tasks | Where-Object { $_.status -ne 'completed' })

        # Reset arrays
        $this.overdueTasks = @()
        $this.todayTasks = @()
        $this.tomorrowTasks = @()
        $this.thisWeekTasks = @()
        $this.laterTasks = @()
        $this.noDueTasks = @()

        $nowDate = Get-Date
        $todayDate = $nowDate.Date
        $tomorrowDate = $todayDate.AddDays(1)
        $weekEndDate = $todayDate.AddDays(7)

        foreach ($task in $activeTasks) {
            if ($task.due) {
                try {
                    $tmp = Get-ConsoleUIDateOrNull $task.due
                    if (-not $tmp) { throw 'invalid date' }
                    $dueDate = $tmp.Date
                    if ($dueDate -lt $todayDate) {
                        $this.overdueTasks += $task
                    } elseif ($dueDate -eq $todayDate) {
                        $this.todayTasks += $task
                    } elseif ($dueDate -eq $tomorrowDate) {
                        $this.tomorrowTasks += $task
                    } elseif ($dueDate -le $weekEndDate) {
                        $this.thisWeekTasks += $task
                    } else {
                        $this.laterTasks += $task
                    }
                } catch {
                    $this.noDueTasks += $task
                }
            } else {
                $this.noDueTasks += $task
            }
        }

        # Build selectable tasks array (only those we'll show)
        $this.selectableTasks = @()
        $this.selectableTasks += @($this.overdueTasks | Select-Object -First 5)
        $this.selectableTasks += @($this.todayTasks | Select-Object -First 5)
        $this.selectableTasks += @($this.tomorrowTasks | Select-Object -First 3)
        $this.selectableTasks += @($this.thisWeekTasks | Select-Object -First 3)

        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Agenda View "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $currentTaskIndex = 0
        $todayDate = (Get-Date).Date

        # OVERDUE section
        if ($this.overdueTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, $y++, "OVERDUE ($($this.overdueTasks.Count)):", [PmcVT100]::Red(), "")
            foreach ($task in ($this.overdueTasks | Select-Object -First 5)) {
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                if (-not $dueDate) { continue }
                $daysOverdue = ($todayDate - $dueDate.Date).Days
                $text = "[$($task.id)] $($task.text) (-$daysOverdue days)"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(4, $y, ">", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::Red(), "")
                }
                $y++
                $currentTaskIndex++
            }
            if ($this.overdueTasks.Count -gt 5) {
                $this.Terminal.WriteAtColor(6, $y++, "... and $($this.overdueTasks.Count - 5) more", [PmcVT100]::Gray(), "")
            }
            $y++
        }

        # TODAY section
        if ($this.todayTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, $y++, "TODAY ($($this.todayTasks.Count)):", [PmcVT100]::Yellow(), "")
            foreach ($task in ($this.todayTasks | Select-Object -First 5)) {
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                $dateStr = if ($dueDate) { " ($($dueDate.ToString('ddd MMM dd')))" } else { "" }
                $text = "[$($task.id)] $($task.text)$dateStr"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(4, $y, ">", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::Yellow(), "")
                }
                $y++
                $currentTaskIndex++
            }
            if ($this.todayTasks.Count -gt 5) {
                $this.Terminal.WriteAtColor(6, $y++, "... and $($this.todayTasks.Count - 5) more", [PmcVT100]::Gray(), "")
            }
            $y++
        }

        # TOMORROW section
        if ($this.tomorrowTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, $y++, "TOMORROW ($($this.tomorrowTasks.Count)):", [PmcVT100]::Cyan(), "")
            foreach ($task in ($this.tomorrowTasks | Select-Object -First 3)) {
                $text = "[$($task.id)] $($task.text)"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(4, $y, ">", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::Cyan(), "")
                }
                $y++
                $currentTaskIndex++
            }
            if ($this.tomorrowTasks.Count -gt 3) {
                $this.Terminal.WriteAtColor(6, $y++, "... and $($this.tomorrowTasks.Count - 3) more", [PmcVT100]::Gray(), "")
            }
            $y++
        }

        # THIS WEEK section
        if ($this.thisWeekTasks.Count -gt 0) {
            $this.Terminal.WriteAtColor(4, $y++, "THIS WEEK ($($this.thisWeekTasks.Count)):", [PmcVT100]::Green(), "")
            foreach ($task in ($this.thisWeekTasks | Select-Object -First 3)) {
                $dueDate = Get-ConsoleUIDateOrNull $task.due
                if (-not $dueDate) { continue }
                $text = "[$($task.id)] $($task.text) ($($dueDate.ToString('ddd MMM dd')))"

                if ($currentTaskIndex -eq $this.selectedIndex) {
                    $this.Terminal.WriteAtColor(4, $y, ">", [PmcVT100]::Yellow(), "")
                    $this.Terminal.WriteAtColor(6, $y, $text, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.Terminal.WriteAt(6, $y, $text)
                }
                $y++
                $currentTaskIndex++
            }
            if ($this.thisWeekTasks.Count -gt 3) {
                $this.Terminal.WriteAt(6, $y++, "... and $($this.thisWeekTasks.Count - 3) more")
            }
            $y++
        }

        # LATER section (count only)
        if ($this.laterTasks.Count -gt 0) {
            $this.Terminal.WriteAt(4, $y++, "LATER ($($this.laterTasks.Count))")
            $y++
        }

        # NO DUE DATE section (count only)
        if ($this.noDueTasks.Count -gt 0) {
            $this.Terminal.WriteAt(4, $y++, "NO DUE DATE ($($this.noDueTasks.Count))")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterNavEditComplete)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.selectableTasks.Count - 1) {
                    $this.selectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.selectedIndex -lt $this.selectableTasks.Count) {
                    $task = $this.selectableTasks[$this.selectedIndex]
                    $this.App.ShowTaskEditForm($task)
                    $this.LoadAgendaTasks()
                    return $true
                }
            }
            'D' {
                if ($this.selectedIndex -lt $this.selectableTasks.Count) {
                    $task = $this.selectableTasks[$this.selectedIndex]
                    $task.status = 'completed'
                    try { $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed agenda task $($task.id)"
                    $this.LoadAgendaTasks()
                    return $true
                }
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# === TASK DETAIL SCREEN ===
# Shows detailed view of a single task with all its properties
class TaskDetailScreen : PmcScreen {
    [object]$Task = $null
    [int]$selectedAction = 0

    # Constructor accepting a task
    TaskDetailScreen([object]$task) {
        $this.Task = $task
        $this.Title = "Task Detail"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        # Reload task data from storage to get latest version
        if ($this.Task -and $this.Task.id) {
            $data = Get-PmcAllData
            $freshTask = $data.tasks | Where-Object { $_.id -eq $this.Task.id }
            if ($freshTask) {
                $this.Task = $freshTask
            }
        }
        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        try {
            if (-not $this.Task) {
                $this.Terminal.WriteAtColor(4, 6, "Error: No task selected", [PmcVT100]::Red(), "")
                $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
                $this.Terminal.EndFrame()
                return
            }

            # Title
            $title = " Task #$($this.Task.id) "
            $titleX = ($this.Terminal.Width - $title.Length) / 2
            $this.Terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            # Task details
            $y = 4
            $this.Terminal.WriteAtColor(4, $y++, "Text: $($this.Task.text)", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(4, $y++, "Status: $(if ($this.Task.status) { $this.Task.status } else { 'none' })", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(4, $y++, "Priority: $(if ($this.Task.priority) { $this.Task.priority } else { 'none' })", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(4, $y++, "Project: $(if ($this.Task.project) { $this.Task.project } else { 'none' })", [PmcVT100]::Yellow(), "")

            # Due date with enhanced display
            if ($this.Task.PSObject.Properties['due'] -and $this.Task.due) {
                $dueDisplay = $this.Task.due
                $dueDate = Get-ConsoleUIDateOrNull $this.Task.due
                if ($dueDate) {
                    $today = Get-Date
                    $daysUntil = ($dueDate.Date - $today.Date).Days

                    if ($this.Task.status -ne 'completed') {
                        if ($daysUntil -lt 0) {
                            $this.Terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                            $this.Terminal.WriteAtColor(9, $y, "$dueDisplay (OVERDUE by $([Math]::Abs($daysUntil)) days)", [PmcVT100]::Red(), "")
                            $y++
                        } elseif ($daysUntil -eq 0) {
                            $this.Terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                            $this.Terminal.WriteAtColor(9, $y, "$dueDisplay (TODAY)", [PmcVT100]::Yellow(), "")
                            $y++
                        } elseif ($daysUntil -eq 1) {
                            $this.Terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                            $this.Terminal.WriteAtColor(9, $y, "$dueDisplay (tomorrow)", [PmcVT100]::Cyan(), "")
                            $y++
                        } else {
                            $this.Terminal.WriteAtColor(4, $y++, "Due: $dueDisplay (in $daysUntil days)", [PmcVT100]::Yellow(), "")
                        }
                    } else {
                        $this.Terminal.WriteAtColor(4, $y++, "Due: $dueDisplay", [PmcVT100]::Yellow(), "")
                    }
                } else {
                    $this.Terminal.WriteAtColor(4, $y++, "Due: $dueDisplay", [PmcVT100]::Yellow(), "")
                }
            }

            # Dates
            if ($this.Task.PSObject.Properties['created'] -and $this.Task.created) {
                $this.Terminal.WriteAtColor(4, $y++, "Created: $($this.Task.created)", [PmcVT100]::Yellow(), "")
            }
            if ($this.Task.PSObject.Properties['modified'] -and $this.Task.modified) {
                $this.Terminal.WriteAtColor(4, $y++, "Modified: $($this.Task.modified)", [PmcVT100]::Yellow(), "")
            }
            if ($this.Task.PSObject.Properties['completed'] -and $this.Task.completed -and ($this.Task.status -eq 'completed' -or $this.Task.status -eq 'done')) {
                $this.Terminal.WriteAtColor(4, $y++, "Completed: $($this.Task.completed)", [PmcVT100]::Green(), "")
            }

            # Time logs
            try {
                $data = Get-PmcAllData
                if ($data.timelogs) {
                    $taskLogs = @($data.timelogs | Where-Object { $_.taskId -eq $this.Task.id -or $_.task -eq $this.Task.id })
                    if ($taskLogs.Count -gt 0) {
                        $totalMinutes = ($taskLogs | ForEach-Object { if ($_.minutes) { $_.minutes } else { 0 } } | Measure-Object -Sum).Sum
                        $hours = [Math]::Floor($totalMinutes / 60)
                        $mins = $totalMinutes % 60
                        $y++
                        $this.Terminal.WriteAtColor(4, $y++, "Time Logged: ${hours}h ${mins}m ($($taskLogs.Count) entries)", [PmcVT100]::Yellow(), "")
                    }
                }
            } catch {}

            # Subtasks
            if ($this.Task.PSObject.Properties['subtasks'] -and $this.Task.subtasks -and $this.Task.subtasks.Count -gt 0) {
                $y++
                $this.Terminal.WriteAtColor(4, $y++, "Subtasks:", [PmcVT100]::Yellow(), "")
                foreach ($subtask in $this.Task.subtasks) {
                    $subtaskText = if ($subtask -is [string]) {
                        $subtask
                    } elseif ($subtask.PSObject.Properties['text'] -and $subtask.text) {
                        $subtask.text
                    } else {
                        $subtask.ToString()
                    }
                    $isCompleted = $subtask.PSObject.Properties['completed'] -and $subtask.completed
                    $completed = if ($isCompleted) { "X" } else { "o" }
                    $color = if ($isCompleted) { [PmcVT100]::Green() } else { [PmcVT100]::White() }
                    $this.Terminal.WriteAtColor(6, $y++, "$completed $subtaskText", $color, "")
                }
            }

            # Notes
            if ($this.Task.PSObject.Properties['notes'] -and $this.Task.notes -and $this.Task.notes.Count -gt 0) {
                $y++
                $this.Terminal.WriteAtColor(4, $y++, "Notes:", [PmcVT100]::Yellow(), "")
                foreach ($note in $this.Task.notes) {
                    $noteText = if ($note.PSObject.Properties['text'] -and $note.text) { $note.text } elseif ($note -is [string]) { $note } else { $note.ToString() }
                    $noteDate = if ($note.PSObject.Properties['date'] -and $note.date) { $note.date } else { "" }
                    if ($noteDate) {
                        $this.Terminal.WriteAtColor(6, $y++, "[$noteDate] $noteText", [PmcVT100]::Cyan(), "")
                    } else {
                        $this.Terminal.WriteAtColor(6, $y++, "$noteText", [PmcVT100]::Cyan(), "")
                    }
                }
            }

            # Dependencies
            if ($this.Task.PSObject.Properties['depends'] -and $this.Task.depends -and $this.Task.depends.Count -gt 0) {
                $y++
                $this.Terminal.WriteAtColor(4, $y++, "Dependencies:", [PmcVT100]::Yellow(), "")
                try {
                    $data = Get-PmcAllData
                    foreach ($depId in $this.Task.depends) {
                        $depTask = $data.tasks | Where-Object { $_.id -eq $depId }
                        if ($depTask) {
                            $statusIcon = if ($depTask.status -eq 'completed') { 'X' } else { 'o' }
                            $color = if ($depTask.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Red() }
                            $this.Terminal.WriteAtColor(6, $y++, "$statusIcon Task #$depId - $($depTask.text)", $color, "")
                        } else {
                            $this.Terminal.WriteAtColor(6, $y++, "o Task #$depId (not found)", [PmcVT100]::Gray(), "")
                        }
                    }
                } catch {}
            }

            # Footer with actions
            $this.Terminal.DrawFooter("E:Edit | A:Add Subtask | N:Add Note | D:Toggle Complete | Del:Delete | Esc:Back")

        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error displaying task detail: $_", [PmcVT100]::Red(), "")
            $this.Terminal.WriteAtColor(4, 8, "Stack: $($_.ScriptStackTrace)", [PmcVT100]::Gray(), "")
            $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        }

        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'E' {
                # Edit task
                $this.App.ShowTaskEditForm($this.Task)
                # Reload task after edit
                $data = Get-PmcAllData
                $freshTask = $data.tasks | Where-Object { $_.id -eq $this.Task.id }
                if ($freshTask) {
                    $this.Task = $freshTask
                    $this.Invalidate()
                }
                return $true
            }
            'A' {
                # Add subtask - will be implemented when subtask screen exists
                # For now, just invalidate to refresh
                $this.Invalidate()
                return $true
            }
            'N' {
                # Add note - will be implemented when note screen exists
                # For now, just invalidate to refresh
                $this.Invalidate()
                return $true
            }
            'D' {
                # Toggle complete/active
                try {
                    $isCompleted = ($this.Task.status -eq 'completed')
                    $this.Task.status = if ($isCompleted) { 'active' } else { 'completed' }

                    if ($isCompleted) {
                        # Mark as active, clear completed date
                        try { $this.Task.completed = $null } catch {}
                    } else {
                        # Mark as completed, set completed date
                        try { $this.Task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                    }

                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Toggled task $($this.Task.id) to $($this.Task.status)"

                    # Reload task to get fresh data
                    $freshTask = $data.tasks | Where-Object { $_.id -eq $this.Task.id }
                    if ($freshTask) {
                        $this.Task = $freshTask
                    }
                    $this.Invalidate()
                } catch {
                    # Silently fail - task will still be displayed
                }
                return $true
            }
            'Delete' {
                # Delete task
                try {
                    $taskId = $this.Task.id
                    $data = Get-PmcAllData
                    $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                    Save-PmcData -Data $data -Action "Deleted task $taskId"
                    # Go back after deleting
                    $this.App.GoBack()
                } catch {}
                return $true
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# === FILE OPERATIONS SCREENS ===

# Backup View Screen - Shows existing backups and allows creating new ones
class BackupViewScreen : PmcScreen {
    [array]$backups = @()

    BackupViewScreen() {
        $this.Title = "Backup Data"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadBackups()
    }

    [void] LoadBackups() {
        try {
            $file = Get-PmcTaskFilePath
            $this.backups = @()
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $this.backups += [PSCustomObject]@{
                        Number = $i
                        File = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                    }
                }
            }
        } catch {
            Write-Error "Error loading backups: $_"
        }
    }

    [void] Render() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Backup Data "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath

            if ($this.backups.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "Existing Backups:", [PmcVT100]::Cyan(), "")
                $y = 8
                foreach ($backup in $this.backups) {
                    $sizeKB = [math]::Round($backup.Size / 1KB, 2)
                    $line = "  .bak$($backup.Number)  -  $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB"
                    $this.terminal.WriteAt(4, $y++, $line)
                }

                $y++
                $this.terminal.WriteAtColor(4, $y, "Main data file:", [PmcVT100]::Cyan(), "")
                $y++
                if (Test-Path $file) {
                    $mainInfo = Get-Item $file
                    $sizeKB = [math]::Round($mainInfo.Length / 1KB, 2)
                    $this.terminal.WriteAt(4, $y++, "  $file")
                    $this.terminal.WriteAt(4, $y++, "  Modified: $($mainInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB")
                }

                $y += 2
                $this.terminal.WriteAtColor(4, $y++, "Press 'B' to create manual backup now", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, $y, "Backups are automatically created on every save (up to 9 retained)")
            } else {
                $this.terminal.WriteAtColor(4, 8, "No backups found.", [PmcVT100]::Yellow(), "")
                $y = 10
                $this.terminal.WriteAt(4, $y++, "Backups are automatically created when data is saved.")
                $this.terminal.WriteAt(4, $y++, "Up to 9 backups are retained (.bak1 through .bak9)")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'B' to create manual backup now", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error loading backup info: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("B:Create Backup | Esc:Back")
        $this.terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'B' {
                try {
                    $file = Get-PmcTaskFilePath
                    if (Test-Path $file) {
                        # Rotate backups
                        for ($i = 8; $i -ge 1; $i--) {
                            $src = "$file.bak$i"
                            $dst = "$file.bak$($i+1)"
                            if (Test-Path $src) {
                                Move-Item -Force $src $dst
                            }
                        }
                        Copy-Item $file "$file.bak1" -Force

                        Show-InfoMessage -Message "Backup created successfully" -Title "Success" -Color "Green"
                        $this.LoadBackups()
                        return $true
                    }
                } catch {
                    Show-InfoMessage -Message "Error creating backup: $_" -Title "Error" -Color "Red"
                }
                return $true
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Restore Backup Screen - Lists backups and allows restoring from them
class RestoreBackupScreen : PmcScreen {
    [array]$allBackups = @()
    [int]$selectedIndex = 0
    [int]$scrollOffset = 0

    RestoreBackupScreen() {
        $this.Title = "Restore from Backup"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadBackups()
    }

    [void] LoadBackups() {
        try {
            $file = Get-PmcTaskFilePath
            $this.allBackups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $this.allBackups += [PSCustomObject]@{
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $this.allBackups += [PSCustomObject]@{
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }
        } catch {
            Write-Error "Error loading backups: $_"
        }
    }

    [void] Render() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Restore Data from Backup "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        if ($this.allBackups.Count -eq 0) {
            $this.terminal.WriteAtColor(4, 6, "No backups found", [PmcVT100]::Red(), "")
            $this.terminal.DrawFooter("Esc:Back")
            $this.terminal.EndFrame()
            return
        }

        $this.terminal.WriteAtColor(4, 6, "Available backups:", [PmcVT100]::Yellow(), "")

        $startY = 8
        $maxVisible = $this.terminal.Height - $startY - 4
        $endIndex = [Math]::Min($this.scrollOffset + $maxVisible, $this.allBackups.Count)

        for ($i = $this.scrollOffset; $i -lt $endIndex; $i++) {
            $backup = $this.allBackups[$i]
            $sizeKB = [math]::Round($backup.Size / 1KB, 2)
            $typeLabel = if ($backup.Type -eq "auto") { "[Auto]" } else { "[Manual]" }
            $line = "$typeLabel $($backup.Name) - $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss')) ($sizeKB KB)"

            $y = $startY + ($i - $this.scrollOffset)
            if ($i -eq $this.selectedIndex) {
                $this.terminal.WriteAtColor(2, $y, ">", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(4, $y, $line, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            } else {
                $this.terminal.WriteAt(4, $y, $line)
            }
        }

        $this.terminal.DrawFooter("Up/Down:Select | Enter:Restore | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    if ($this.selectedIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedIndex
                    }
                }
                return $true
            }
            'DownArrow' {
                if ($this.selectedIndex -lt ($this.allBackups.Count - 1)) {
                    $this.selectedIndex++
                    $maxVisible = $this.terminal.Height - 12
                    if ($this.selectedIndex -ge $this.scrollOffset + $maxVisible) {
                        $this.scrollOffset = $this.selectedIndex - $maxVisible + 1
                    }
                }
                return $true
            }
            'Enter' {
                if ($this.allBackups.Count -eq 0) {
                    Show-InfoMessage -Message "No backups available" -Title "Error" -Color "Red"
                    return $true
                }

                $backup = $this.allBackups[$this.selectedIndex]
                $confirmed = Show-ConfirmDialog -Message "Restore from $($backup.Name)? This overwrites current data." -Title "Confirm Restore"

                if ($confirmed) {
                    try {
                        $data = Get-Content $backup.Path -Raw | ConvertFrom-Json
                        Save-PmcData -Data $data -Action "Restored from backup: $($backup.Name)"
                        Show-InfoMessage -Message "Data restored successfully" -Title "Success" -Color "Green"
                        $this.App.GoBack()
                    } catch {
                        Show-InfoMessage -Message "Error restoring backup: $_" -Title "Error" -Color "Red"
                    }
                } else {
                    Show-InfoMessage -Message "Restore cancelled" -Title "Cancelled" -Color "Yellow"
                }
                return $true
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Clear Backups Screen - Shows backup info and allows deletion
class ClearBackupsScreen : PmcScreen {
    [int]$autoBackupCount = 0
    [long]$autoBackupSize = 0
    [int]$manualBackupCount = 0
    [long]$manualBackupSize = 0

    ClearBackupsScreen() {
        $this.Title = "Clear Backup Files"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadBackupStats()
    }

    [void] LoadBackupStats() {
        try {
            $file = Get-PmcTaskFilePath
            $this.autoBackupCount = 0
            $this.autoBackupSize = 0

            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $this.autoBackupCount++
                    $this.autoBackupSize += (Get-Item $bakFile).Length
                }
            }

            $this.manualBackupCount = 0
            $this.manualBackupSize = 0
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json")
                $this.manualBackupCount = $manualBackups.Count
                $this.manualBackupSize = ($manualBackups | Measure-Object -Property Length -Sum).Sum
            }
        } catch {
            Write-Error "Error loading backup stats: $_"
        }
    }

    [void] Render() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Clear Backup Files "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Automatic backups (.bak1 - .bak9):", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAt(4, 8, "  Count: $($this.autoBackupCount) files")
        $sizeMB = [math]::Round($this.autoBackupSize / 1MB, 2)
        $this.terminal.WriteAt(4, 9, "  Total size: $sizeMB MB")

        $y = 11
        $backupDir = Join-Path (Get-PmcRootPath) "backups"
        if (Test-Path $backupDir) {
            $manualSizeMB = [math]::Round($this.manualBackupSize / 1MB, 2)

            $this.terminal.WriteAtColor(4, $y++, "Manual backups (backups directory):", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAt(4, $y++, "  Count: $($this.manualBackupCount) files")
            $this.terminal.WriteAt(4, $y++, "  Total size: $manualSizeMB MB")
        }

        $y += 2
        if ($this.autoBackupCount -gt 0) {
            $this.terminal.WriteAtColor(4, $y++, "Press 'A' to clear automatic backups (.bak files)", [PmcVT100]::Yellow(), "")
        }
        if (Test-Path $backupDir -and $this.manualBackupCount -gt 0) {
            $this.terminal.WriteAtColor(4, $y++, "Press 'M' to clear manual backups (backups directory)", [PmcVT100]::Yellow(), "")
            $y++
            $this.terminal.WriteAtColor(4, $y, "Press 'B' to clear BOTH", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterBackupChoice)
        $this.terminal.EndFrame()
    }

    [bool] HandleInput([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'A' {
                $confirmed = Show-ConfirmDialog -Message "Clear automatic backups (.bak files)?" -Title "Confirm"
                if ($confirmed) {
                    try {
                        $file = Get-PmcTaskFilePath
                        $count = 0
                        for ($i = 1; $i -le 9; $i++) {
                            $bakFile = "$file.bak$i"
                            if (Test-Path $bakFile) {
                                Remove-Item $bakFile -Force
                                $count++
                            }
                        }
                        Show-InfoMessage -Message "Cleared $count automatic backup files" -Title "Success" -Color "Green"
                        $this.App.GoBack()
                    } catch {
                        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
                    }
                }
                return $true
            }
            'M' {
                $confirmed = Show-ConfirmDialog -Message "Clear manual backups (backups/*.json)?" -Title "Confirm"
                if ($confirmed) {
                    try {
                        $backupDir = Join-Path (Get-PmcRootPath) "backups"
                        if (Test-Path $backupDir) {
                            $files = Get-ChildItem $backupDir -Filter "*.json"
                            $count = $files.Count
                            Remove-Item "$backupDir/*.json" -Force
                            Show-InfoMessage -Message "Cleared $count manual backup files" -Title "Success" -Color "Green"
                        }
                        $this.App.GoBack()
                    } catch {
                        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
                    }
                }
                return $true
            }
            'B' {
                $confirmed = Show-ConfirmDialog -Message "Clear ALL backups? (auto + manual)" -Title "Confirm"
                if ($confirmed) {
                    try {
                        $file = Get-PmcTaskFilePath
                        $count = 0

                        # Clear automatic backups
                        for ($i = 1; $i -le 9; $i++) {
                            $bakFile = "$file.bak$i"
                            if (Test-Path $bakFile) {
                                Remove-Item $bakFile -Force
                                $count++
                            }
                        }

                        # Clear manual backups
                        $backupDir = Join-Path (Get-PmcRootPath) "backups"
                        if (Test-Path $backupDir) {
                            $files = Get-ChildItem $backupDir -Filter "*.json"
                            $count += $files.Count
                            Remove-Item "$backupDir/*.json" -Force
                        }

                        Show-InfoMessage -Message "Cleared $count total backup files" -Title "Success" -Color "Green"
                        $this.App.GoBack()
                    } catch {
                        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
                    }
                }
                return $true
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# === TIME TRACKING SCREENS ===

# Time List Screen - Main time tracking list view
class TimeListScreen : PmcScreen {
    [array]$timeLogs = @()
    [int]$selectedIndex = 0

    TimeListScreen() {
        $this.Title = "Time Log"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()
        $this.LoadTimeLogs()
    }

    [void] LoadTimeLogs() {
        $data = Get-PmcAllData
        if ($data.PSObject.Properties['timelogs']) {
            $this.timeLogs = @($data.timelogs | Sort-Object { $_.date } -Descending)
        } else {
            $this.timeLogs = @()
        }

        # Ensure selectedIndex is valid
        if ($this.selectedIndex -ge $this.timeLogs.Count) {
            $this.selectedIndex = [Math]::Max(0, $this.timeLogs.Count - 1)
        }

        $this.Invalidate()
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Time Log "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            if ($this.timeLogs.Count -eq 0) {
                $emptyY = 8
                $this.Terminal.WriteAtColor(4, $emptyY++, "No time entries yet", [PmcVT100]::Yellow(), "")
                $emptyY++
                $this.Terminal.WriteAtColor(4, $emptyY++, "Press 'A' to add your first time entry", [PmcVT100]::Cyan(), "")
            } else {
                # Header
                $headerY = 5
                $this.Terminal.WriteAtColor(2, $headerY, "ID", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(8, $headerY, "Date", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(22, $headerY, "Project", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(41, $headerY, "Hours", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(50, $headerY, "Description", [PmcVT100]::Cyan(), "")
                $this.Terminal.DrawHorizontalLine(0, $headerY + 1, $this.Terminal.Width)

                $startY = $headerY + 2
                $y = $startY
                $maxY = $this.Terminal.Height - 3

                for ($i = 0; $i -lt $this.timeLogs.Count; $i++) {
                    if ($y -ge $maxY) { break }

                    $log = $this.timeLogs[$i]
                    $isSelected = ($i -eq $this.selectedIndex)

                    # Format data with null safety
                    $rawDate = if ($log.date) { $log.date.ToString() } else { "" }
                    $dateStr = if ($rawDate -eq 'today') {
                        (Get-Date).ToString('yyyy-MM-dd')
                    } elseif ($rawDate -eq 'tomorrow') {
                        (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
                    } else {
                        $rawDate
                    }

                    $projectStr = if ($log.project) {
                        $log.project.ToString()
                    } else {
                        if ($log.id1) { "#$($log.id1)" } else { "" }
                    }

                    $hours = if ($log.minutes) { [math]::Round($log.minutes / 60.0, 2) } else { 0 }
                    $hoursStr = $hours.ToString("0.00")

                    $descStr = if ($log.PSObject.Properties['description'] -and $log.description) {
                        $log.description.ToString()
                    } else {
                        ""
                    }

                    # Format columns
                    $prefix = if ($isSelected) { ">" } else { " " }
                    $idCol = ($prefix + $log.id.ToString()).PadRight(5)
                    $dateCol = $dateStr.Substring(0, [Math]::Min(10, $dateStr.Length)).PadRight(13)
                    $projectCol = $projectStr.Substring(0, [Math]::Min(16, $projectStr.Length)).PadRight(18)
                    $hoursCol = $hoursStr.PadRight(8)

                    if ($isSelected) {
                        $this.Terminal.WriteAtColor(2, $y, $idCol, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                        $this.Terminal.WriteAtColor(8, $y, $dateCol, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                        $this.Terminal.WriteAtColor(22, $y, $projectCol, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                        $this.Terminal.WriteAtColor(41, $y, $hoursCol, [PmcVT100]::BgBlue(), [PmcVT100]::Cyan())
                        if ($descStr) {
                            $desc = $descStr.Substring(0, [Math]::Min(30, $descStr.Length))
                            $this.Terminal.WriteAtColor(50, $y, $desc, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                        }
                    } else {
                        $this.Terminal.WriteAtColor(2, $y, $idCol, [PmcVT100]::Yellow(), "")
                        $this.Terminal.WriteAtColor(8, $y, $dateCol, [PmcVT100]::Yellow(), "")
                        $this.Terminal.WriteAtColor(22, $y, $projectCol, [PmcVT100]::Gray(), "")
                        $this.Terminal.WriteAtColor(41, $y, $hoursCol, [PmcVT100]::Cyan(), "")
                        if ($descStr) {
                            $desc = $descStr.Substring(0, [Math]::Min(30, $descStr.Length))
                            $this.Terminal.WriteAtColor(50, $y, $desc, [PmcVT100]::Yellow(), "")
                        }
                    }
                    $y++
                }
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error loading time log: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterTimeList)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    $this.Invalidate()
                }
                return $true
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.timeLogs.Count - 1) {
                    $this.selectedIndex++
                    $this.Invalidate()
                }
                return $true
            }
            'A' {
                # Add new time entry
                $addScreen = [TimeAddFormScreen]::new()
                $this.App.PushScreen($addScreen)
                return $true
            }
            'E' {
                # Edit selected time entry
                if ($this.timeLogs.Count -gt 0 -and $this.selectedIndex -ge 0 -and $this.selectedIndex -lt $this.timeLogs.Count) {
                    $selectedLog = $this.timeLogs[$this.selectedIndex]
                    $editScreen = [TimeEditFormScreen]::new($selectedLog)
                    $this.App.PushScreen($editScreen)
                }
                return $true
            }
            'D' {
                # Delete selected time entry
                if ($this.timeLogs.Count -gt 0 -and $this.selectedIndex -ge 0 -and $this.selectedIndex -lt $this.timeLogs.Count) {
                    $selectedLog = $this.timeLogs[$this.selectedIndex]
                    $deleteScreen = [TimeDeleteFormScreen]::new($selectedLog)
                    $this.App.PushScreen($deleteScreen)
                }
                return $true
            }
            'R' {
                # Show time report
                $reportScreen = [TimeReportScreen]::new()
                $this.App.PushScreen($reportScreen)
                return $true
            }
            'Escape' {
                $this.App.GoBack()
                return $true
            }
        }
        return $false
    }
}

# Time Delete Form Screen - Delete time entry with confirmation
class TimeDeleteFormScreen : PmcScreen {
    [object]$TimeLog = $null

    TimeDeleteFormScreen([object]$timeLog) {
        $this.Title = "Delete Time Entry"
        $this.TimeLog = $timeLog
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        # Show confirmation dialog immediately
        $log = $this.TimeLog
        $hours = if ($log.minutes) { [math]::Round($log.minutes / 60.0, 2) } else { 0 }
        $projectStr = if ($log.project) { $log.project } else { if ($log.id1) { "Code #$($log.id1)" } else { "Unknown" } }

        $message = "Delete time entry #$($log.id)?`n`nProject: $projectStr`nHours: $hours`nDate: $($log.date)`n`nThis cannot be undone."
        $confirmed = Show-ConfirmDialog -Message $message -Title "Confirm Delete"

        if ($confirmed) {
            try {
                $data = Get-PmcAllData
                if (-not $data.PSObject.Properties['timelogs']) {
                    Show-InfoMessage -Message "No time logs found!" -Title "Error" -Color "Red"
                } else {
                    $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $log.id })
                    Save-PmcData -Data $data -Action "Deleted time entry #$($log.id)"

                    # Reload time logs in parent screen if it's TimeListScreen
                    if ($this.App.CurrentScreen -is [TimeListScreen]) {
                        ([TimeListScreen]$this.App.CurrentScreen).LoadTimeLogs()
                    }

                    Show-InfoMessage -Message "Time entry #$($log.id) deleted successfully!" -Title "Success" -Color "Green"
                }
            } catch {
                Show-InfoMessage -Message "Failed to delete time entry: $_" -Title "Error" -Color "Red"
            }
        }

        # Close this screen
        $this.Active = $false
    }

    [void] Render() {
        # This screen doesn't render - confirmation happens in OnActivated
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input handled in OnActivated
        return $false
    }
}

# Time Report Screen - Show time summary by project
class TimeReportScreen : PmcScreen {
    TimeReportScreen() {
        $this.Title = "Time Report"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Time Report "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $timelogList = if ($data.PSObject.Properties['timelogs']) { $data.timelogs } else { @() }

            if ($timelogList.Count -eq 0) {
                $this.Terminal.WriteAtColor(4, 6, "No time entries to report", [PmcVT100]::Yellow(), "")
            } else {
                # Group by project
                $byProject = $timelogList | Group-Object -Property project | Sort-Object Name

                $this.Terminal.WriteAtColor(4, 5, "Time Summary by Project:", [PmcVT100]::Yellow(), "")

                $headerY = 7
                $this.Terminal.WriteAtColor(4, $headerY, "Project", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(30, $headerY, "Entries", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(42, $headerY, "Total Minutes", [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(60, $headerY, "Hours", [PmcVT100]::Cyan(), "")
                $this.Terminal.DrawHorizontalLine(2, $headerY + 1, $this.Terminal.Width - 4)

                $y = $headerY + 2
                $totalMinutes = 0
                $maxY = $this.Terminal.Height - 5

                foreach ($group in $byProject) {
                    if ($y -ge $maxY) { break }

                    $minutes = ($group.Group | Measure-Object -Property minutes -Sum).Sum
                    $hours = [Math]::Round($minutes / 60, 2)
                    $totalMinutes += $minutes

                    $projectName = if ($group.Name) { $group.Name } else { "(no project)" }
                    $this.Terminal.WriteAt(4, $y, $projectName.Substring(0, [Math]::Min(24, $projectName.Length)))
                    $this.Terminal.WriteAt(30, $y, $group.Count.ToString())
                    $this.Terminal.WriteAtColor(42, $y, $minutes.ToString(), [PmcVT100]::Cyan(), "")
                    $this.Terminal.WriteAtColor(60, $y, $hours.ToString(), [PmcVT100]::Green(), "")
                    $y++
                }

                $totalHours = [Math]::Round($totalMinutes / 60, 2)
                $this.Terminal.DrawHorizontalLine(2, $y, $this.Terminal.Width - 4)
                $y++
                $this.Terminal.WriteAtColor(4, $y, "TOTAL:", [PmcVT100]::Yellow(), "")
                $this.Terminal.WriteAtColor(30, $y, "$($timelogList.Count) entries", [PmcVT100]::Gray(), "")
                $this.Terminal.WriteAtColor(42, $y, $totalMinutes.ToString(), [PmcVT100]::Cyan(), "")
                $this.Terminal.WriteAtColor(60, $y, $totalHours.ToString(), [PmcVT100]::Green(), "")
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error generating report: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }
        return $false
    }
}

# === DEPENDENCY & HELP SCREENS ===

# DepAddFormScreen - Form to add task dependency
class DepAddFormScreen : PmcScreen {
    DepAddFormScreen() {
        $this.Title = "Add Dependency"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.App.MenuSystem.DrawMenuBar()

        $title = " Add Dependency "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.Terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAtColor(4, 8, "Depends on Task ID:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAt(4, 10, "(Task will be blocked until dependency is completed)")

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDsCancel)
        $this.Terminal.EndFrame()
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Use Show-InputForm widget
            $fields = @(
                @{Name='taskId'; Label='Task ID'; Required=$true}
                @{Name='dependsId'; Label='Depends on Task ID'; Required=$true}
            )

            $result = Show-InputForm -Title "Add Dependency" -Fields $fields

            if ($null -eq $result) {
                $this.Active = $false
                return
            }

            $taskId = try { [int]$result['taskId'] } catch { 0 }
            $dependsId = try { [int]$result['dependsId'] } catch { 0 }

            if ($taskId -le 0 -or $dependsId -le 0) {
                Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            if ($taskId -eq $dependsId) {
                Show-InfoMessage -Message "A task cannot depend on itself!" -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }
            $dependsTask = $data.tasks | Where-Object { $_.id -eq $dependsId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $dependsTask) {
                Show-InfoMessage -Message "Task $dependsId not found!" -Title "Error" -Color "Red"
            } else {
                # Initialize depends array if needed
                if (-not $task.PSObject.Properties['depends']) {
                    $task | Add-Member -NotePropertyName depends -NotePropertyValue @()
                }

                # Check if dependency already exists
                if ($task.depends -contains $dependsId) {
                    Show-InfoMessage -Message "Dependency already exists!" -Title "Warning" -Color "Yellow"
                } else {
                    $task.depends = @($task.depends + $dependsId)

                    # Update blocked status
                    Update-PmcBlockedStatus -data $data

                    Save-PmcData -Data $data -Action "Added dependency: $taskId depends on $dependsId"
                    Show-InfoMessage -Message "Dependency added successfully! Task $taskId now depends on task $dependsId." -Title "Success" -Color "Green"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to add dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.Active = $false
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input is handled by Show-InputForm in OnActivated
        return $false
    }
}

# DepRemoveFormScreen - Form to remove dependency
class DepRemoveFormScreen : PmcScreen {
    DepRemoveFormScreen() {
        $this.Title = "Remove Dependency"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.App.MenuSystem.DrawMenuBar()

        $title = " Remove Dependency "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.Terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAtColor(4, 8, "Remove dependency on Task ID:", [PmcVT100]::Yellow(), "")

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDsCancel)
        $this.Terminal.EndFrame()
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Use Show-InputForm widget
            $fields = @(
                @{Name='taskId'; Label='Task ID'; Required=$true}
                @{Name='dependsId'; Label='Remove dependency on Task ID'; Required=$true}
            )

            $result = Show-InputForm -Title "Remove Dependency" -Fields $fields

            if ($null -eq $result) {
                $this.Active = $false
                return
            }

            $taskId = try { [int]$result['taskId'] } catch { 0 }
            $dependsId = try { [int]$result['dependsId'] } catch { 0 }

            if ($taskId -le 0 -or $dependsId -le 0) {
                Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $task.PSObject.Properties['depends'] -or -not $task.depends) {
                Show-InfoMessage -Message "Task has no dependencies!" -Title "Warning" -Color "Yellow"
            } else {
                $task.depends = @($task.depends | Where-Object { $_ -ne $dependsId })

                # Clean up empty depends array
                if ($task.depends.Count -eq 0) {
                    $task.PSObject.Properties.Remove('depends')
                }

                # Update blocked status
                Update-PmcBlockedStatus -data $data

                Save-PmcData -Data $data -Action "Removed dependency: $taskId no longer depends on $dependsId"
                Show-InfoMessage -Message "Dependency removed successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to remove dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.Active = $false
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input is handled by Show-InputForm in OnActivated
        return $false
    }
}

# DepShowFormScreen - Display dependencies for a task
class DepShowFormScreen : PmcScreen {
    DepShowFormScreen() {
        $this.Title = "Show Task Dependencies"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.App.MenuSystem.DrawMenuBar()

        $title = " Show Task Dependencies "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.Terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDCancel)
        $this.Terminal.EndFrame()
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Unified input for task id
            $fields = @(
                @{Name='taskId'; Label='Task ID to show dependencies'; Required=$true}
            )
            $form = Show-InputForm -Title "Show Task Dependencies" -Fields $fields

            if ($null -eq $form) {
                $this.Active = $false
                return
            }

            $taskId = try { [int]$form['taskId'] } catch { 0 }

            if ($taskId -le 0) {
                Show-InfoMessage -Message "Invalid task ID" -Title "Validation" -Color "Red"
                $this.Active = $false
                return
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message ("Task {0} not found" -f $taskId) -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            # Build dependency display
            $this.Terminal.Clear()
            $this.App.MenuSystem.DrawMenuBar()

            $title = " Show Task Dependencies "
            $titleX = ($this.Terminal.Width - $title.Length) / 2
            $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            $this.Terminal.WriteAtColor(4, 6, "Task:", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAt(10, 6, $task.text.Substring(0, [Math]::Min(60, $task.text.Length)))

            $depends = if ($task.PSObject.Properties['depends'] -and $task.depends) { $task.depends } else { @() }

            $y = 8
            if ($depends.Count -eq 0) {
                $this.Terminal.WriteAt(4, $y, "No dependencies")
                $y = 10
            } else {
                $this.Terminal.WriteAtColor(4, $y++, "Dependencies:", [PmcVT100]::Yellow(), "")
                $y++
                foreach ($depId in $depends) {
                    $depTask = $data.tasks | Where-Object { $_.id -eq $depId }
                    if ($depTask) {
                        $statusIcon = if ($depTask.status -eq 'completed') { 'X' } else { 'o' }
                        $statusColor = if ($depTask.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Red() }
                        $this.Terminal.WriteAtColor(6, $y, $statusIcon, $statusColor, "")
                        $this.Terminal.WriteAt(8, $y, "#$depId")
                        $this.Terminal.WriteAt(15, $y, $depTask.text.Substring(0, [Math]::Min(50, $depTask.text.Length)))
                        $y++
                    }
                    if ($y -ge $this.Terminal.Height - 5) { break }
                }
            }

            # Show reverse dependencies (what depends on this task)
            $reverseDeps = @($data.tasks | Where-Object {
                $_.PSObject.Properties['depends'] -and $_.depends -and ($_.depends -contains $taskId)
            })

            if ($reverseDeps.Count -gt 0) {
                $y = $y + 2
                if ($y -lt $this.Terminal.Height - 5) {
                    $this.Terminal.WriteAtColor(4, $y++, "Tasks that depend on this:", [PmcVT100]::Yellow(), "")
                    $y++
                    foreach ($revTask in $reverseDeps) {
                        if ($y -ge $this.Terminal.Height - 3) { break }
                        $this.Terminal.WriteAt(6, $y, "#$($revTask.id)")
                        $this.Terminal.WriteAt(15, $y, $revTask.text.Substring(0, [Math]::Min(50, $revTask.text.Length)))
                        $y++
                    }
                }
            }

            $this.Terminal.DrawFooter("Press any key to close")

            # Wait for key press
            [Console]::ReadKey($true) | Out-Null

        } catch {
            Show-InfoMessage -Message "Failed to show dependencies: $_" -Title "ERROR" -Color "Red"
        }

        $this.Active = $false
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input is handled in OnActivated
        return $false
    }
}

# HelpViewScreen - General help screen with keyboard shortcuts
class HelpViewScreen : PmcScreen {
    HelpViewScreen() {
        $this.Title = "Help"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.App.MenuSystem.DrawMenuBar()

        $title = " PMC ConsoleUI - Keybindings & Help "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 5
        $this.Terminal.WriteAtColor(4, $y++, "Global Keys:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAt(6, $y++, "F10       - Open menu bar")
        $this.Terminal.WriteAt(6, $y++, "Esc       - Back / Close menus / Exit")
        $this.Terminal.WriteAt(6, $y++, "Alt+X     - Quick exit PMC")
        $this.Terminal.WriteAt(6, $y++, "Alt+T     - Open task list")
        $this.Terminal.WriteAt(6, $y++, "Alt+A     - Add new task")
        $this.Terminal.WriteAt(6, $y++, "Alt+P     - Project list")
        $y++

        $this.Terminal.WriteAtColor(4, $y++, "Task List Keys:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAt(6, $y++, "↑↓        - Navigate tasks")
        $this.Terminal.WriteAt(6, $y++, "Enter     - View task details")
        $this.Terminal.WriteAt(6, $y++, "A         - Add new task")
        $this.Terminal.WriteAt(6, $y++, "M         - Multi-select mode (bulk operations)")
        $this.Terminal.WriteAt(6, $y++, "D         - Mark task complete")
        $this.Terminal.WriteAt(6, $y++, "S         - Cycle sort order (id/priority/status/created/due)")
        $this.Terminal.WriteAt(6, $y++, "F         - Filter by project")
        $this.Terminal.WriteAt(6, $y++, "C         - Clear all filters")
        $this.Terminal.WriteAt(6, $y++, "/         - Search tasks")
        $y++

        $this.Terminal.WriteAtColor(4, $y++, "Multi-Select Mode Keys:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAt(6, $y++, "Space     - Toggle task selection")
        $this.Terminal.WriteAt(6, $y++, "A         - Select all visible tasks")
        $this.Terminal.WriteAt(6, $y++, "N         - Clear all selections")
        $this.Terminal.WriteAt(6, $y++, "D         - Complete selected tasks")
        $this.Terminal.WriteAt(6, $y++, "X         - Delete selected tasks")
        $this.Terminal.WriteAt(6, $y++, "P         - Set priority for selected tasks")
        $y++

        $this.Terminal.WriteAtColor(4, $y++, "Task Detail Keys:", [PmcVT100]::Yellow(), "")
        $this.Terminal.WriteAt(6, $y++, "E         - Edit task text")
        $this.Terminal.WriteAt(6, $y++, "J         - Change project")
        $this.Terminal.WriteAt(6, $y++, "T         - Set due date")
        $this.Terminal.WriteAt(6, $y++, "D         - Mark as complete")
        $this.Terminal.WriteAt(6, $y++, "P         - Cycle priority (high/medium/low/none)")
        $this.Terminal.WriteAt(6, $y++, "X         - Delete task")
        $y++

        $this.Terminal.WriteAtColor(4, $y++, "Quick Add Syntax:", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAt(6, $y++, "@project  - Set project (e.g., 'Fix bug @work')")
        $this.Terminal.WriteAt(6, $y++, "#priority - Set priority: #high #medium #low or #h #m #l")
        $this.Terminal.WriteAt(6, $y++, "!due      - Set due: !today !tomorrow !+7 (days)")
        $y++

        $this.Terminal.WriteAtColor(4, $y++, "Features:", [PmcVT100]::Cyan(), "")
        $this.Terminal.WriteAt(6, $y++, "• Real-time PMC data integration with persistent storage")
        $this.Terminal.WriteAt(6, $y++, "• Quick add syntax for fast task creation (@project #priority !due)")
        $this.Terminal.WriteAt(6, $y++, "• Multi-select mode for bulk operations (complete/delete/priority)")
        $this.Terminal.WriteAt(6, $y++, "• Color-coded priorities and overdue warnings")
        $this.Terminal.WriteAt(6, $y++, "• Project filtering, task search, and 5-way sorting")
        $this.Terminal.WriteAt(6, $y++, "• Due date management with relative dates and smart indicators")
        $this.Terminal.WriteAt(6, $y++, "• Scrollable lists, inline editing, full CRUD operations")

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }
        return $false
    }
}

# BurndownChartScreen - Shows burndown chart visualization
class BurndownChartScreen : PmcScreen {
    BurndownChartScreen() {
        $this.Title = "Burndown Chart"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.App.MenuSystem.DrawMenuBar()

        $title = " Burndown Chart "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData

            # Get current project filter from App if available
            $currentProject = $null
            if ($this.App.PSObject.Properties['filterProject'] -and $this.App.filterProject) {
                $currentProject = $this.App.filterProject
            }

            # Filter tasks by project if needed
            $projectTasks = if ($currentProject) {
                $data.tasks | Where-Object { $_.project -eq $currentProject }
            } else {
                $data.tasks
            }

            # Calculate burndown metrics
            $totalTasks = $projectTasks.Count
            $completedTasks = ($projectTasks | Where-Object { $_.status -eq 'done' -or $_.status -eq 'completed' }).Count
            $inProgressTasks = ($projectTasks | Where-Object { $_.status -eq 'in-progress' }).Count
            $blockedTasks = ($projectTasks | Where-Object { $_.status -eq 'blocked' }).Count
            $todoTasks = ($projectTasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' -or -not $_.status }).Count

            $projectTitle = if ($currentProject) { "Project: $currentProject" } else { "All Projects" }
            $this.Terminal.WriteAtColor(4, $y++, $projectTitle, [PmcVT100]::Cyan(), "")
            $y++

            $this.Terminal.WriteAtColor(4, $y++, "Task Summary:", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(6, $y++, "Total Tasks:      $totalTasks", [PmcVT100]::White(), "")
            $this.Terminal.WriteAtColor(6, $y++, "Completed:        $completedTasks", [PmcVT100]::Green(), "")
            $this.Terminal.WriteAtColor(6, $y++, "In Progress:      $inProgressTasks", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(6, $y++, "Blocked:          $blockedTasks", [PmcVT100]::Red(), "")
            $this.Terminal.WriteAtColor(6, $y++, "To Do:            $todoTasks", [PmcVT100]::White(), "")
            $y++

            # Calculate completion percentage
            $completionPct = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 1) } else { 0 }
            $this.Terminal.WriteAtColor(4, $y++, "Completion: $completionPct%", [PmcVT100]::Cyan(), "")
            $y++

            # Draw simple bar chart
            $barWidth = 50
            $completedWidth = if ($totalTasks -gt 0) { [math]::Floor(($completedTasks / $totalTasks) * $barWidth) } else { 0 }
            $inProgressWidth = if ($totalTasks -gt 0) { [math]::Floor(($inProgressTasks / $totalTasks) * $barWidth) } else { 0 }
            $remainingWidth = $barWidth - $completedWidth - $inProgressWidth

            $bar = ""
            if ($completedWidth -gt 0) { $bar += [string]::new('█', $completedWidth) }
            if ($inProgressWidth -gt 0) { $bar += [string]::new('▒', $inProgressWidth) }
            if ($remainingWidth -gt 0) { $bar += [string]::new('░', $remainingWidth) }

            $this.Terminal.WriteAt(4, $y++, "Progress:")
            $this.Terminal.WriteAt(4, $y++, "[$bar]")
            $y++

            # Legend
            $this.Terminal.WriteAtColor(4, $y++, "Legend:", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(6, $y++, "█ Completed", [PmcVT100]::Green(), "")
            $this.Terminal.WriteAtColor(6, $y++, "▒ In Progress", [PmcVT100]::Yellow(), "")
            $this.Terminal.WriteAtColor(6, $y++, "░ To Do", [PmcVT100]::White(), "")

        } catch {
            $this.Terminal.WriteAtColor(4, $y, "Error generating burndown chart: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter([PmcUIStringCache]::FooterEscBack)
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        if ($key.Key -eq 'Escape') {
            $this.App.GoBack()
            return $true
        }
        return $false
    }
}

# === TASK OPERATION FORM SCREENS ===

# Task Complete Form Screen

# === TIMER SCREENS ===

# Timer Start Screen
class TimerStartScreen : PmcScreen {
    TimerStartScreen() {
        $this.Title = "Start Timer"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Check if timer is already running
            $running = Get-PmcState -Section 'Timer' -Key 'Running'
            if ($running) {
                $project = Get-PmcState -Section 'Timer' -Key 'Project'
                $startTime = Get-PmcState -Section 'Timer' -Key 'StartTime'
                Show-InfoMessage -Message "Timer is already running for project: $project`nStarted: $startTime" -Title "Timer Running" -Color "Yellow"
                $this.Active = $false
                return
            }

            # Get task or project selection
            $data = Get-PmcAllData
            $taskList = @($data.tasks | Where-Object { $_.status -ne 'completed' } | ForEach-Object {
                $taskId = if ($_.id) { $_.id } else { 0 }
                $taskText = if ($_.text) { $_.text } else { '' }
                $projectInfo = if ($_.project) { " [@$($_.project)]" } else { "" }
                [PSCustomObject]@{
                    Display = "[$taskId] $taskText$projectInfo"
                    Value = [string]$taskId
                }
            })

            if ($taskList.Count -eq 0) {
                Show-InfoMessage -Message "No active tasks available" -Title "No Tasks" -Color "Yellow"
                $this.Active = $false
                return
            }

            $taskOptions = $taskList | ForEach-Object { $_.Display }
            $fields = @(
                @{Name='task'; Label='Select task to track'; Required=$true; Type='select'; Options=$taskOptions}
            )

            $result = Show-InputForm -Title "Start Timer" -Fields $fields

            if ($null -eq $result) {
                $this.Active = $false
                return
            }

            # Extract task ID
            $selection = [string]$result['task']
            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            # Find task and get project
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
            if (-not $task) {
                Show-InfoMessage -Message "Task not found" -Title "Error" -Color "Red"
                $this.Active = $false
                return
            }

            $project = if ($task.project) { $task.project } else { 'inbox' }

            # Start the timer
            Set-PmcState -Section 'Timer' -Key 'Running' -Value $true
            Set-PmcState -Section 'Timer' -Key 'Project' -Value $project
            Set-PmcState -Section 'Timer' -Key 'TaskId' -Value $taskId
            Set-PmcState -Section 'Timer' -Key 'StartTime' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

            Show-InfoMessage -Message "Timer started for task #$taskId`nProject: $project" -Title "Timer Started" -Color "Green"

        } catch {
            Show-InfoMessage -Message "Failed to start timer: $_" -Title "Error" -Color "Red"
        }

        $this.Active = $false
    }

    [void] Render() {
        # Handled in OnActivated
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        return $false
    }
}

# Timer Stop Screen
class TimerStopScreen : PmcScreen {
    TimerStopScreen() {
        $this.Title = "Stop Timer"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Check if timer is running
            $running = Get-PmcState -Section 'Timer' -Key 'Running'
            if (-not $running) {
                Show-InfoMessage -Message "No timer is currently running" -Title "No Timer" -Color "Yellow"
                $this.Active = $false
                return
            }

            # Get timer info
            $project = Get-PmcState -Section 'Timer' -Key 'Project'
            $taskId = Get-PmcState -Section 'Timer' -Key 'TaskId'
            $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
            $endTime = Get-Date
            $elapsed = $endTime - $startTime
            $minutes = [Math]::Round($elapsed.TotalMinutes, 0)
            $hours = [Math]::Round($elapsed.TotalHours, 2)

            # Confirm stop
            $msg = "Stop timer?`n`nElapsed: $hours hours ($minutes minutes)`nProject: $project"
            if ($taskId) {
                $msg += "`nTask: #$taskId"
            }

            $confirmed = Show-ConfirmDialog -Message $msg -Title "Stop Timer"

            if (-not $confirmed) {
                $this.Active = $false
                return
            }

            # Create time entry
            $data = Get-PmcAllData
            $entry = [PSCustomObject]@{
                id = Get-PmcNextTimeId $data
                project = $project
                taskId = $taskId
                date = $startTime.ToString('yyyy-MM-dd')
                minutes = $minutes
                description = "Timer session"
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            if (-not $data.timelogs) {
                $data | Add-Member -MemberType NoteProperty -Name 'timelogs' -Value @() -Force
            }
            $data.timelogs += $entry

            # Clear timer state
            Set-PmcState -Section 'Timer' -Key 'Running' -Value $false
            Set-PmcState -Section 'Timer' -Key 'Project' -Value $null
            Set-PmcState -Section 'Timer' -Key 'TaskId' -Value $null
            Set-PmcState -Section 'Timer' -Key 'StartTime' -Value $null

            Save-PmcData -Data $data -Action "Stopped timer: $minutes minutes for $project"

            Show-InfoMessage -Message "Timer stopped`n`nLogged: $hours hours ($minutes minutes)`nProject: $project" -Title "Timer Stopped" -Color "Green"

        } catch {
            Show-InfoMessage -Message "Failed to stop timer: $_" -Title "Error" -Color "Red"
        }

        $this.Active = $false
    }

    [void] Render() {
        # Handled in OnActivated
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        return $false
    }
}

# Timer Status Screen
class TimerStatusScreen : PmcScreen {
    TimerStatusScreen() {
        $this.Title = "Timer Status"
    }

    [void] Render() {
        $this.Terminal.BeginFrame()
        $this.MenuSystem.DrawMenuBar()

        $title = " Timer Status "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $running = Get-PmcState -Section 'Timer' -Key 'Running'

            if ($running) {
                $project = Get-PmcState -Section 'Timer' -Key 'Project'
                $taskId = Get-PmcState -Section 'Timer' -Key 'TaskId'
                $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
                $elapsed = (Get-Date) - $startTime
                $hours = [Math]::Round($elapsed.TotalHours, 2)
                $minutes = [Math]::Round($elapsed.TotalMinutes, 0)

                $this.Terminal.WriteAtColor(4, 6, "Timer is RUNNING", [PmcVT100]::Green(), "")
                $y = 8
                $this.Terminal.WriteAt(4, $y++, "Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))")
                $this.Terminal.WriteAt(4, $y++, "Elapsed: ${hours}h (${minutes}m)")
                if ($taskId) {
                    $y++
                    $this.Terminal.WriteAt(4, $y++, "Task: #$taskId")
                }
                if ($project) {
                    $this.Terminal.WriteAt(4, $y++, "Project: $project")
                }
            } else {
                $this.Terminal.WriteAtColor(4, 6, "No timer is running", [PmcVT100]::Yellow(), "")

                # Show last session if available
                $lastStart = Get-PmcState -Section 'Timer' -Key 'LastStartTime'
                $lastDuration = Get-PmcState -Section 'Timer' -Key 'LastDuration'
                if ($lastDuration) {
                    $this.Terminal.WriteAt(4, 8, "Last session: ${lastDuration} hours")
                }
            }
        } catch {
            $this.Terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.Terminal.DrawFooter("Esc:Back | F10:Menu")
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'Escape' {
                $this.Active = $false
                return $true
            }
        }
        return $false
    }
}

# === UNDO/REDO SCREENS ===

# Undo View Screen
class UndoViewScreen : PmcScreen {
    UndoViewScreen() {
        $this.Title = "Undo Last Change"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Check if undo is available
            $bakFile = Join-Path (Split-Path $Global:PmcDataPath) 'tasks.json.bak1'
            if (-not (Test-Path $bakFile)) {
                Show-InfoMessage -Message "No undo information available" -Title "No Undo" -Color "Yellow"
                $this.Active = $false
                return
            }

            # Show confirmation
            $msg = "Undo the last change?`n`nThis will restore from backup file.`n(tasks.json.bak1)"
            $confirmed = Show-ConfirmDialog -Message $msg -Title "Confirm Undo"

            if (-not $confirmed) {
                $this.Active = $false
                return
            }

            # Perform undo by restoring from .bak1
            $dataPath = $Global:PmcDataPath
            $currentContent = Get-Content $dataPath -Raw
            $bakContent = Get-Content $bakFile -Raw

            # Save current to redo (.undo file)
            $undoFile = Join-Path (Split-Path $dataPath) 'tasks.json.undo'
            Set-Content -Path $undoFile -Value $currentContent -NoNewline

            # Restore from backup
            Set-Content -Path $dataPath -Value $bakContent -NoNewline

            # Reload app data
            if ($this.App) {
                $this.App.LoadTasks()
                $this.App.LoadProjects()
            }

            Show-InfoMessage -Message "Undo completed`n`nRestored from backup" -Title "Undo Success" -Color "Green"

        } catch {
            Show-InfoMessage -Message "Failed to undo: $_" -Title "Error" -Color "Red"
        }

        $this.Active = $false
    }

    [void] Render() {
        # Handled in OnActivated
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        return $false
    }
}

# Redo View Screen
class RedoViewScreen : PmcScreen {
    RedoViewScreen() {
        $this.Title = "Redo Last Undone Change"
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Check if redo is available
            $undoFile = Join-Path (Split-Path $Global:PmcDataPath) 'tasks.json.undo'
            if (-not (Test-Path $undoFile)) {
                Show-InfoMessage -Message "No redo information available" -Title "No Redo" -Color "Yellow"
                $this.Active = $false
                return
            }

            # Show confirmation
            $msg = "Redo the last undone change?`n`nThis will restore from undo file."
            $confirmed = Show-ConfirmDialog -Message $msg -Title "Confirm Redo"

            if (-not $confirmed) {
                $this.Active = $false
                return
            }

            # Perform redo by restoring from .undo
            $dataPath = $Global:PmcDataPath
            $currentContent = Get-Content $dataPath -Raw
            $undoContent = Get-Content $undoFile -Raw

            # Save current to backup
            $bakFile = Join-Path (Split-Path $dataPath) 'tasks.json.bak1'
            Set-Content -Path $bakFile -Value $currentContent -NoNewline

            # Restore from undo file
            Set-Content -Path $dataPath -Value $undoContent -NoNewline

            # Remove undo file
            Remove-Item $undoFile -Force

            # Reload app data
            if ($this.App) {
                $this.App.LoadTasks()
                $this.App.LoadProjects()
            }

            Show-InfoMessage -Message "Redo completed`n`nRestored from undo file" -Title "Redo Success" -Color "Green"

        } catch {
            Show-InfoMessage -Message "Failed to redo: $_" -Title "Error" -Color "Red"
        }

        $this.Active = $false
    }

    [void] Render() {
        # Handled in OnActivated
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        return $false
    }
}

# Helper function for getting next time log ID
function Get-PmcNextTimeId {
    param($data)

    if (-not $data.timelogs -or $data.timelogs.Count -eq 0) {
        return "T001"
    }

    $maxId = 0
    foreach ($entry in $data.timelogs) {
        if ($entry.id -match '^T(\d+)$') {
            $num = [int]$matches[1]
            if ($num -gt $maxId) { $maxId = $num }
        }
    }

    return "T{0:000}" -f ($maxId + 1)
}

# === FORM SCREENS ===
# Base class for modal form screens (add/edit dialogs)
class PmcFormScreen : PmcScreen {
    [object]$EditingObject = $null  # null = Add mode, object = Edit mode
    [hashtable]$FieldValues = @{}
    [hashtable]$FormResult = $null

    PmcFormScreen() : base() {
    }

    # Override in derived classes to define form fields
    [array] GetFields() {
        return @()
    }

    # Override in derived classes to validate and save
    [bool] SaveForm([hashtable]$values) {
        return $false
    }

    [bool] IsEditMode() {
        return $null -ne $this.EditingObject
    }

    [void] OnActivated() {
        ([PmcScreen]$this).OnActivated()

        try {
            # Show the input form immediately
            $fields = $this.GetFields()
            $input = Show-InputForm -Title $this.Title -Fields $fields

            if ($null -eq $input) {
                # User cancelled
                $this.Active = $false
                return
            }

            # Try to save
            if ($this.SaveForm($input)) {
                $this.FormResult = $input
            }

            # Close form screen after save/cancel
            $this.Active = $false
        } catch {
            Show-InfoMessage -Message "Form error: $_`n`nStack: $($_.ScriptStackTrace)" -Title "ERROR" -Color "Red"
            $this.Active = $false
        }
    }

    [void] Render() {
        # Form is handled in OnActivated, this shouldn't be called
        # But provide a fallback just in case
        $this.Terminal.BeginFrame()
        $this.Terminal.EndFrame()
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        # Input is handled by Show-InputForm, not by the screen
        return $false
    }
}

# Task Add/Edit Form Screen
class TaskFormScreen : PmcFormScreen {
    TaskFormScreen() {
        $this.Title = "Task"
    }

    # Constructor for edit mode
    TaskFormScreen([object]$task) {
        $this.Title = "Task"
        $this.EditingObject = $task
    }

    [array] GetFields() {
        $data = Get-PmcAllData
        $projectList = @('none', 'inbox') + @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        if ($this.IsEditMode()) {
            $task = $this.EditingObject
            $currentText = if ($task.text) { [string]$task.text } else { '' }
            $currentProject = if ($task.project) { [string]$task.project } else { '' }
            $currentPriority = if ($task.PSObject.Properties['priority'] -and $task.priority) { [string]$task.priority } else { 'medium' }
            $currentDue = ''
            if ($task.PSObject.Properties['due'] -and $task.due) { $currentDue = [string]$task.due }

            return @(
                @{Name='text'; Label='Task description'; Required=$true; Type='text'; Value=$currentText}
                @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList; Value=$currentProject}
                @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low'); Value=$currentPriority}
                @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'; Value=$currentDue}
            )
        } else {
            return @(
                @{Name='text'; Label='Task description'; Required=$true; Type='text'}
                @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList}
                @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low')}
                @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'}
            )
        }
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $data = Get-PmcAllData

            if ($this.IsEditMode()) {
                # Edit mode - update existing task
                $task = $this.EditingObject
                $taskId = $task.id
                $changed = $false

                $currentText = if ($task.text) { [string]$task.text } else { '' }
                if ($input['text'] -ne $currentText) {
                    $task.text = $input['text'].Trim()
                    $changed = $true
                }

                $newProject = if ([string]::IsNullOrWhiteSpace($input['project']) -or $input['project'] -eq 'none') { $null } else { $input['project'].Trim() }
                if ($newProject -ne $task.project) {
                    $task.project = $newProject
                    $changed = $true
                }

                if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
                    $newPriority = $input['priority'].Trim().ToLower()
                    if ($newPriority -ne $task.priority) {
                        $task.priority = $newPriority
                        $changed = $true
                    }
                }

                # Handle due date
                $currentDue = if ($task.PSObject.Properties['due'] -and $task.due) { [string]$task.due } else { '' }
                if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                    $parsedDate = ConvertTo-PmcDate -DateString $input['due']
                    if ($null -eq $parsedDate) {
                        Show-InfoMessage -Message "Invalid due date. Try: today, yyyymmdd, mmdd, +3, etc." -Title "Invalid Date" -Color "Red"
                        return $false
                    }
                    if ($parsedDate -ne $currentDue) {
                        $task | Add-Member -MemberType NoteProperty -Name 'due' -Value $parsedDate -Force
                        $changed = $true
                    }
                } elseif (-not [string]::IsNullOrWhiteSpace($currentDue)) {
                    $task | Add-Member -MemberType NoteProperty -Name 'due' -Value $null -Force
                    $changed = $true
                }

                if ($changed) {
                    $task | Add-Member -MemberType NoteProperty -Name 'modified' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force
                    Save-PmcData -Data $data -Action "Edited task $taskId"
                    $this.App.LoadTasks()
                    Show-InfoMessage -Message "Task #$taskId updated successfully" -Title "Success" -Color "Green"
                } else {
                    Show-InfoMessage -Message "No changes made to task #$taskId" -Title "Info" -Color "Cyan"
                }

                return $true

            } else {
                # Add mode - create new task
                $taskText = $input['text']
                if ($taskText.Length -lt 3) {
                    Show-InfoMessage -Message "Task description must be at least 3 characters" -Title "Error" -Color "Red"
                    return $false
                }

                $newId = if ($data.tasks.Count -gt 0) {
                    ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
                } else { 1 }

                $project = if ([string]::IsNullOrWhiteSpace($input['project']) -or $input['project'] -eq 'none') { $null } elseif ($input['project'] -eq 'inbox') { 'inbox' } else { $input['project'].Trim() }

                $priority = 'medium'
                if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
                    $priInput = $input['priority'].Trim().ToLower()
                    $priority = switch -Regex ($priInput) {
                        '^h(igh)?$' { 'high' }
                        '^l(ow)?$' { 'low' }
                        '^m(edium)?$' { 'medium' }
                        default { 'medium' }
                    }
                }

                $due = $null
                if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                    $dueInput = $input['due'].Trim().ToLower()
                    $due = switch ($dueInput) {
                        'today' { (Get-Date).ToString('yyyy-MM-dd') }
                        'tomorrow' { (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
                        default {
                            $parsedDate = Get-ConsoleUIDateOrNull $dueInput
                            if ($parsedDate) { $parsedDate.ToString('yyyy-MM-dd') } else { $null }
                        }
                    }
                }

                $newTask = [PSCustomObject]@{
                    id = $newId
                    text = $taskText.Trim()
                    status = 'active'
                    priority = $priority
                    project = $project
                    due = $due
                    created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }

                $data.tasks += $newTask
                Save-PmcData -Data $data -Action "Added task $newId"
                $this.App.LoadTasks()
                Show-InfoMessage -Message "Task #$newId added successfully: $($taskText.Trim())" -Title "Success" -Color "Green"

                return $true
            }
        } catch {
            Show-InfoMessage -Message "FAILED TO SAVE TASK: $_`n`nYour task was NOT saved. Please try again." -Title "SAVE ERROR" -Color "Red"
            return $false
        }
    }
}

# Project Add/Edit Form Screen
class ProjectFormScreen : PmcFormScreen {
    ProjectFormScreen() {
        $this.Title = "Project"
    }

    # Constructor for edit mode
    ProjectFormScreen([object]$project) {
        $this.Title = "Project"
        $this.EditingObject = $project
    }

    [array] GetFields() {
        if ($this.IsEditMode()) {
            $proj = $this.EditingObject
            return @(
                @{Name='name'; Label='Project Name (required)'; Required=$true; Type='text'; Value=$proj.name}
                @{Name='description'; Label='Description'; Required=$false; Type='text'; Value=$proj.description}
                @{Name='id1'; Label='ID1'; Required=$false; Type='text'; Value=$proj.id1}
                @{Name='id2'; Label='ID2'; Required=$false; Type='text'; Value=$proj.id2}
                @{Name='projFolder'; Label='Project Folder'; Required=$false; Type='text'; Value=$proj.projFolder}
                @{Name='caaName'; Label='CAA Name'; Required=$false; Type='text'; Value=$proj.caaName}
                @{Name='requestName'; Label='Request Name'; Required=$false; Type='text'; Value=$proj.requestName}
                @{Name='t2020'; Label='T2020'; Required=$false; Type='text'; Value=$proj.t2020}
                @{Name='assignedDate'; Label='Assigned Date (yyyy-MM-dd)'; Required=$false; Type='text'; Value=$proj.assignedDate}
                @{Name='dueDate'; Label='Due Date (yyyy-MM-dd)'; Required=$false; Type='text'; Value=$proj.dueDate}
                @{Name='bfDate'; Label='BF Date (yyyy-MM-dd)'; Required=$false; Type='text'; Value=$proj.bfDate}
            )
        } else {
            return @(
                @{Name='name'; Label='Project Name (required)'; Required=$true; Type='text'}
                @{Name='description'; Label='Description'; Required=$false; Type='text'}
                @{Name='id1'; Label='ID1'; Required=$false; Type='text'}
                @{Name='id2'; Label='ID2'; Required=$false; Type='text'}
                @{Name='projFolder'; Label='Project Folder'; Required=$false; Type='text'}
                @{Name='caaName'; Label='CAA Name'; Required=$false; Type='text'}
                @{Name='requestName'; Label='Request Name'; Required=$false; Type='text'}
                @{Name='t2020'; Label='T2020'; Required=$false; Type='text'}
                @{Name='assignedDate'; Label='Assigned Date (yyyy-MM-dd)'; Required=$false; Type='text'}
                @{Name='dueDate'; Label='Due Date (yyyy-MM-dd)'; Required=$false; Type='text'}
                @{Name='bfDate'; Label='BF Date (yyyy-MM-dd)'; Required=$false; Type='text'}
            )
        }
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $data = Get-PmcAllData

            if ([string]::IsNullOrWhiteSpace($input['name'])) {
                Show-InfoMessage -Message "Project name is required" -Title "Validation" -Color "Red"
                return $false
            }

            if ($this.IsEditMode()) {
                # Edit mode - update existing project
                $proj = $this.EditingObject
                $oldName = $proj.name

                $proj.name = $input['name'].Trim()
                $proj.description = $input['description']
                $proj.id1 = $input['id1']
                $proj.id2 = $input['id2']
                $proj.projFolder = $input['projFolder']
                $proj.caaName = $input['caaName']
                $proj.requestName = $input['requestName']
                $proj.t2020 = $input['t2020']
                $proj.assignedDate = $input['assignedDate']
                $proj.dueDate = $input['dueDate']
                $proj.bfDate = $input['bfDate']

                Save-PmcData -Data $data -Action "Edited project '$($proj.name)'"
                $this.App.LoadProjects()
                Show-InfoMessage -Message "Project '$($proj.name)' updated successfully" -Title "Success" -Color "Green"
                return $true

            } else {
                # Add mode - create new project
                $projName = $input['name'].Trim()

                # Check for duplicates
                $exists = @($data.projects | Where-Object {
                    $pName = if ($_ -is [string]) { $_ } else { $_.name }
                    $pName -eq $projName
                })

                if ($exists.Count -gt 0) {
                    Show-InfoMessage -Message "Project '$projName' already exists" -Title "Error" -Color "Red"
                    return $false
                }

                $newProject = [PSCustomObject]@{
                    name = $projName
                    description = $input['description']
                    id1 = $input['id1']
                    id2 = $input['id2']
                    projFolder = $input['projFolder']
                    caaName = $input['caaName']
                    requestName = $input['requestName']
                    t2020 = $input['t2020']
                    assignedDate = $input['assignedDate']
                    dueDate = $input['dueDate']
                    bfDate = $input['bfDate']
                    created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }

                $data.projects += $newProject
                Save-PmcData -Data $data -Action "Created project '$projName'"
                $this.App.LoadProjects()
                Show-InfoMessage -Message "Project '$projName' created successfully" -Title "Success" -Color "Green"

                return $true
            }
        } catch {
            Show-InfoMessage -Message "FAILED TO SAVE PROJECT: $_" -Title "SAVE ERROR" -Color "Red"
            return $false
        }
    }
}

# Time Add Form Screen - Add new time entry
class TimeAddFormScreen : PmcFormScreen {
    TimeAddFormScreen() {
        $this.Title = "Add Time Entry"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Build project list
        $projectNames = @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ } | Sort-Object)

        $projectOptions = @('(generic time code)') + $projectNames

        # Build task dropdown from active tasks
        $taskOptions = @('none') + @($data.tasks | Where-Object {
            $_.status -ne 'completed'
        } | Sort-Object { [int]$_.id } | ForEach-Object {
            "[$($_.id)] $($_.text)"
        })

        return @(
            @{Name='hours'; Label='Hours (e.g., 1, 1.5, 2.25)'; Required=$true; Type='text'}
            @{Name='project'; Label='Project or Code Mode'; Required=$true; Type='select'; Options=$projectOptions}
            @{Name='timeCode'; Label='Time Code (if generic)'; Required=$false; Type='text'}
            @{Name='task'; Label='Task (optional)'; Required=$false; Type='select'; Options=$taskOptions}
            @{Name='date'; Label='Date (today/tomorrow/YYYY-MM-DD or empty for today)'; Required=$false; Type='text'}
            @{Name='description'; Label='Description/Notes'; Required=$false; Type='text'}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Validate hours
            $hoursStr = [string]$input['hours']
            $hours = 0.0
            if (-not [double]::TryParse($hoursStr, [ref]$hours) -or $hours -le 0) {
                Show-InfoMessage -Message "Invalid hours. Use numbers like 1, 1.5, 2.25." -Title "Validation" -Color "Red"
                return $false
            }

            # Validate hours range (0-24)
            if ($hours -gt 24) {
                Show-InfoMessage -Message "Hours cannot exceed 24." -Title "Validation" -Color "Red"
                return $false
            }

            # Handle project vs time code
            $selProject = [string]$input['project']
            $timeCode = $null
            $isNumeric = $false

            if ($selProject -eq '(generic time code)') {
                $codeStr = [string]$input['timeCode']
                $codeVal = 0
                if (-not [int]::TryParse($codeStr, [ref]$codeVal) -or $codeVal -le 0) {
                    Show-InfoMessage -Message "Invalid time code (must be a positive number)." -Title "Validation" -Color "Red"
                    return $false
                }
                $timeCode = $codeVal
                $isNumeric = $true
                $selProject = $null
            }

            # Parse date
            $dateInput = [string]$input['date']
            $dateOut = (Get-Date).Date
            if (-not [string]::IsNullOrWhiteSpace($dateInput)) {
                $trim = $dateInput.Trim().ToLower()
                $dt = $null
                if ($trim -eq 'today') {
                    $dt = (Get-Date).Date
                } elseif ($trim -eq 'tomorrow') {
                    $dt = (Get-Date).Date.AddDays(1)
                } elseif ($trim -match '^[+-]\d+$') {
                    $dt = (Get-Date).Date.AddDays([int]$trim)
                } elseif ($trim -match '^\d{8}$') {
                    try {
                        $dt = [DateTime]::ParseExact($trim, 'yyyyMMdd', $null)
                    } catch {}
                } else {
                    $dt = Get-ConsoleUIDateOrNull $trim
                }

                if ($dt) {
                    $dateOut = $dt.Date
                } else {
                    Show-InfoMessage -Message "Invalid date format. Use: today, tomorrow, YYYY-MM-DD, or YYYYMMDD" -Title "Validation" -Color "Red"
                    return $false
                }
            }

            # Generate next time ID
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) {
                $data | Add-Member -NotePropertyName timelogs -NotePropertyValue @()
            }

            $nextId = 1
            if ($data.timelogs.Count -gt 0) {
                $nextId = ($data.timelogs | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
            }

            # Build and save entry
            $entry = [PSCustomObject]@{
                id = $nextId
                project = $selProject
                id1 = if ($isNumeric) { $timeCode.ToString() } else { $null }
                id2 = $null
                date = $dateOut.ToString('yyyy-MM-dd')
                minutes = [int]([math]::Round($hours * 60))
                description = ([string]$input['description']).Trim()
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            $data.timelogs += $entry
            Save-PmcData -Data $data -Action "Added time entry #$nextId ($($entry.minutes) min)"

            # Reload time logs in parent screen if it's TimeListScreen
            if ($this.App.CurrentScreen -is [TimeListScreen]) {
                ([TimeListScreen]$this.App.CurrentScreen).LoadTimeLogs()
            }

            Show-InfoMessage -Message "Time entry #$nextId added successfully! ($hours hours)" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to add time entry: $_" -Title "SAVE ERROR" -Color "Red"
            return $false
        }
    }
}

# Time Edit Form Screen - Edit existing time entry
class TimeEditFormScreen : PmcFormScreen {
    TimeEditFormScreen([object]$timeLog) {
        $this.Title = "Edit Time Entry"
        $this.EditingObject = $timeLog
    }

    [array] GetFields() {
        $data = Get-PmcAllData
        $log = $this.EditingObject

        # Build project list
        $projectNames = @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ } | Sort-Object)

        $projectOptions = @('(generic time code)') + $projectNames

        # Get current values
        $currentHours = if ($log.minutes) { [math]::Round($log.minutes / 60.0, 2).ToString() } else { '0' }
        $currentProject = if ($log.project) { $log.project } else { '(generic time code)' }
        $currentTimeCode = if ($log.id1) { $log.id1 } else { '' }
        $currentDate = if ($log.date) { $log.date.ToString() } else { (Get-Date).ToString('yyyy-MM-dd') }
        $currentDesc = if ($log.PSObject.Properties['description'] -and $log.description) { $log.description } else { '' }

        return @(
            @{Name='hours'; Label='Hours (e.g., 1, 1.5, 2.25)'; Required=$true; Type='text'; Value=$currentHours}
            @{Name='project'; Label='Project or Code Mode'; Required=$true; Type='select'; Options=$projectOptions; Value=$currentProject}
            @{Name='timeCode'; Label='Time Code (if generic)'; Required=$false; Type='text'; Value=$currentTimeCode}
            @{Name='date'; Label='Date (YYYY-MM-DD)'; Required=$false; Type='text'; Value=$currentDate}
            @{Name='description'; Label='Description/Notes'; Required=$false; Type='text'; Value=$currentDesc}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $log = $this.EditingObject
            $logId = $log.id

            # Validate hours
            $hoursStr = [string]$input['hours']
            $hours = 0.0
            if (-not [double]::TryParse($hoursStr, [ref]$hours) -or $hours -le 0) {
                Show-InfoMessage -Message "Invalid hours. Use numbers like 1, 1.5, 2.25." -Title "Validation" -Color "Red"
                return $false
            }

            # Validate hours range
            if ($hours -gt 24) {
                Show-InfoMessage -Message "Hours cannot exceed 24." -Title "Validation" -Color "Red"
                return $false
            }

            # Handle project vs time code
            $selProject = [string]$input['project']
            $timeCode = $null
            $isNumeric = $false

            if ($selProject -eq '(generic time code)') {
                $codeStr = [string]$input['timeCode']
                $codeVal = 0
                if (-not [int]::TryParse($codeStr, [ref]$codeVal) -or $codeVal -le 0) {
                    Show-InfoMessage -Message "Invalid time code (must be a positive number)." -Title "Validation" -Color "Red"
                    return $false
                }
                $timeCode = $codeVal
                $isNumeric = $true
                $selProject = $null
            }

            # Parse date
            $dateInput = [string]$input['date']
            $dateOut = (Get-Date).Date
            if (-not [string]::IsNullOrWhiteSpace($dateInput)) {
                $trim = $dateInput.Trim()
                $dt = Get-ConsoleUIDateOrNull $trim
                if ($dt) {
                    $dateOut = $dt.Date
                } else {
                    Show-InfoMessage -Message "Invalid date format. Use: YYYY-MM-DD" -Title "Validation" -Color "Red"
                    return $false
                }
            }

            # Update entry
            $data = Get-PmcAllData
            $entry = $data.timelogs | Where-Object { $_.id -eq $logId } | Select-Object -First 1

            if (-not $entry) {
                Show-InfoMessage -Message "Time entry #$logId not found!" -Title "Error" -Color "Red"
                return $false
            }

            $entry.project = $selProject
            $entry.id1 = if ($isNumeric) { $timeCode.ToString() } else { $null }
            $entry.date = $dateOut.ToString('yyyy-MM-dd')
            $entry.minutes = [int]([math]::Round($hours * 60))

            if ($entry.PSObject.Properties['description']) {
                $entry.description = ([string]$input['description']).Trim()
            } else {
                $entry | Add-Member -NotePropertyName description -NotePropertyValue ([string]$input['description']).Trim() -Force
            }

            Save-PmcData -Data $data -Action "Updated time entry #$logId"

            # Reload time logs in parent screen if it's TimeListScreen
            if ($this.App.CurrentScreen -is [TimeListScreen]) {
                ([TimeListScreen]$this.App.CurrentScreen).LoadTimeLogs()
            }

            Show-InfoMessage -Message "Time entry #$logId updated successfully!" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to update time entry: $_" -Title "SAVE ERROR" -Color "Red"
            return $false
        }
    }
}

# === TASK OPERATION FORMS ===

# Task Complete Form Screen
class TaskCompleteFormScreen : PmcFormScreen {
    TaskCompleteFormScreen() {
        $this.Title = "Complete Task"
    }

    [array] GetFields() {
        $data = Get-PmcAllData
        # Get active/incomplete tasks only
        $activeTasks = $data.tasks | Where-Object {
            $_.status -ne 'completed' -and $_.status -ne 'done'
        } | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($activeTasks) {
            $taskOptions = $activeTasks | ForEach-Object { $_.Display }
        }

        if ($taskOptions.Count -eq 0) {
            $taskOptions = @('No active tasks available')
        }

        return @(
            @{Name='taskId'; Label='Task to complete'; Required=$true; Type='select'; Options=$taskOptions}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID from selection like "[123] Task text"
            $selection = [string]$input['taskId']
            if ($selection -eq 'No active tasks available') {
                Show-InfoMessage -Message "No active tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Complete the task
            $task.status = 'completed'
            try {
                $task.completed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            } catch {
                # If completed property doesn't exist, add it
                $task | Add-Member -MemberType NoteProperty -Name 'completed' -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -Force
            }

            Save-PmcData -Data $data -Action "Completed task $taskId"
            Show-InfoMessage -Message "Task #$taskId completed successfully" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to complete task: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Delete Form Screen
class TaskDeleteFormScreen : PmcFormScreen {
    TaskDeleteFormScreen() {
        $this.Title = "Delete Task"
    }

    [array] GetFields() {
        $data = Get-PmcAllData
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        }

        if ($taskOptions.Count -eq 0) {
            $taskOptions = @('No tasks available')
        }

        return @(
            @{Name='taskId'; Label='Task to delete'; Required=$true; Type='select'; Options=$taskOptions}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID from selection
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Confirmation dialog before delete
            $taskText = if ($task.text) { $task.text } else { "task #$taskId" }
            $confirmed = Show-ConfirmDialog -Message "Delete '$taskText'? This cannot be undone." -Title "Confirm Deletion"

            if (-not $confirmed) {
                Show-InfoMessage -Message "Delete cancelled" -Title "Cancelled" -Color "Yellow"
                return $false
            }

            # Remove task from array
            $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })

            Save-PmcData -Data $data -Action "Deleted task $taskId"
            Show-InfoMessage -Message "Task #$taskId deleted successfully" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to delete task: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Copy Form Screen
class TaskCopyFormScreen : PmcFormScreen {
    TaskCopyFormScreen() {
        $this.Title = "Copy/Duplicate Task"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Task selection
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        } else {
            $taskOptions = @('No tasks available')
        }

        # Project list for optional project change
        $projectList = @('(keep same)', 'none', 'inbox') + @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        return @(
            @{Name='taskId'; Label='Task to copy'; Required=$true; Type='select'; Options=$taskOptions}
            @{Name='project'; Label='Project (optional)'; Required=$false; Type='select'; Options=$projectList}
            @{Name='due'; Label='Due date (optional, YYYY-MM-DD)'; Required=$false; Type='text'}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Create a copy of the task
            $clone = $task.PSObject.Copy()

            # Generate new ID
            $maxId = ($data.tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum
            $clone.id = $maxId + 1

            # Optional: change project
            if (-not [string]::IsNullOrWhiteSpace($input['project']) -and $input['project'] -ne '(keep same)') {
                if ($input['project'] -eq 'none') {
                    $clone.project = $null
                } else {
                    $clone.project = $input['project']
                }
            }

            # Optional: change due date
            if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                $parsedDate = ConvertTo-PmcDate -DateString $input['due']
                if ($null -ne $parsedDate) {
                    $clone | Add-Member -MemberType NoteProperty -Name 'due' -Value $parsedDate -Force
                }
            }

            # Reset completion status
            $clone.status = if ($clone.status -eq 'completed' -or $clone.status -eq 'done') { 'todo' } else { $clone.status }
            if ($clone.PSObject.Properties['completed']) {
                $clone.PSObject.Properties.Remove('completed')
            }

            # Add to tasks array
            $data.tasks += $clone

            Save-PmcData -Data $data -Action "Copied task $taskId to new task $($clone.id)"
            Show-InfoMessage -Message "Task #$taskId duplicated as task #$($clone.id)" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to copy task: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Move Form Screen
class TaskMoveFormScreen : PmcFormScreen {
    TaskMoveFormScreen() {
        $this.Title = "Move Task to Project"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Task selection
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            $taskProject = if ($_.project) { " @$($_.project)" } else { "" }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText$taskProject"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        } else {
            $taskOptions = @('No tasks available')
        }

        # Project list
        $projectList = @('inbox') + @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        return @(
            @{Name='taskId'; Label='Task to move'; Required=$true; Type='select'; Options=$taskOptions}
            @{Name='project'; Label='Destination Project'; Required=$true; Type='select'; Options=$projectList}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $project = [string]$input['project']
            if ([string]::IsNullOrWhiteSpace($project)) {
                Show-InfoMessage -Message "Project is required" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Update project
            $task.project = $project

            Save-PmcData -Data $data -Action "Moved task $taskId to @$project"
            Show-InfoMessage -Message "Task #$taskId moved to @$project" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to move task: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Priority Form Screen
class TaskPriorityFormScreen : PmcFormScreen {
    TaskPriorityFormScreen() {
        $this.Title = "Set Task Priority"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Task selection with current priority
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            $currentPriority = if ($_.priority) { " [$($_.priority)]" } else { " [none]" }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText$currentPriority"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        } else {
            $taskOptions = @('No tasks available')
        }

        return @(
            @{Name='taskId'; Label='Task'; Required=$true; Type='select'; Options=$taskOptions}
            @{Name='priority'; Label='Priority'; Required=$true; Type='select'; Options=@('high', 'medium', 'low', 'none')}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $priority = [string]$input['priority']
            if ([string]::IsNullOrWhiteSpace($priority)) {
                Show-InfoMessage -Message "Priority is required" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Update priority
            if ($priority -eq 'none') {
                $task.priority = $null
            } else {
                $task.priority = $priority.ToLower()
            }

            Save-PmcData -Data $data -Action "Set task $taskId priority to $priority"
            Show-InfoMessage -Message "Task #$taskId priority set to $priority" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to set priority: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Postpone Form Screen
class TaskPostponeFormScreen : PmcFormScreen {
    TaskPostponeFormScreen() {
        $this.Title = "Postpone Task"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Task selection with current due date
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            $currentDue = if ($_.due) { " (due: $($_.due))" } else { " (no due date)" }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText$currentDue"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        } else {
            $taskOptions = @('No tasks available')
        }

        return @(
            @{Name='taskId'; Label='Task to postpone'; Required=$true; Type='select'; Options=$taskOptions}
            @{Name='days'; Label='Days to postpone'; Required=$true; Type='select'; Options=@('+1', '+2', '+7', '+14', '+30')}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $daysStr = [string]$input['days']
            $days = 1
            if ($daysStr -match '^\+?(\d+)$') {
                $days = [int]$Matches[1]
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Calculate new due date
            $currentDue = if ($task.due) {
                try {
                    [datetime]::ParseExact($task.due, 'yyyy-MM-dd', $null)
                } catch {
                    Get-Date
                }
            } else {
                Get-Date
            }

            $newDue = $currentDue.AddDays($days).ToString('yyyy-MM-dd')

            # Update due date
            try {
                $task.due = $newDue
            } catch {
                $task | Add-Member -MemberType NoteProperty -Name 'due' -Value $newDue -Force
            }

            Save-PmcData -Data $data -Action "Postponed task $taskId by $days day(s)"
            Show-InfoMessage -Message "Task #$taskId postponed by $days day(s) to $newDue" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to postpone task: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Task Note Form Screen
class TaskNoteFormScreen : PmcFormScreen {
    TaskNoteFormScreen() {
        $this.Title = "Add Note to Task"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Task selection
        $taskList = $data.tasks | ForEach-Object {
            $taskId = if ($_.id) { $_.id } else { 0 }
            $taskText = if ($_.text) { $_.text } else { '' }
            $noteCount = if ($_.notes) { " ($($_.notes.Count) notes)" } else { "" }
            [PSCustomObject]@{
                Display = "[$taskId] $taskText$noteCount"
                Value = [string]$taskId
            }
        }

        $taskOptions = @()
        if ($taskList) {
            $taskOptions = $taskList | ForEach-Object { $_.Display }
        } else {
            $taskOptions = @('No tasks available')
        }

        return @(
            @{Name='taskId'; Label='Task'; Required=$true; Type='select'; Options=$taskOptions}
            @{Name='note'; Label='Note text'; Required=$true; Type='text'}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            # Extract task ID
            $selection = [string]$input['taskId']
            if ($selection -eq 'No tasks available') {
                Show-InfoMessage -Message "No tasks available" -Title "Info" -Color "Yellow"
                return $false
            }

            if ($selection -match '^\[(\d+)\]') {
                $taskId = [int]$Matches[1]
            } else {
                Show-InfoMessage -Message "Invalid task selection" -Title "Error" -Color "Red"
                return $false
            }

            $note = [string]$input['note']
            if ([string]::IsNullOrWhiteSpace($note)) {
                Show-InfoMessage -Message "Note text is required" -Title "Error" -Color "Red"
                return $false
            }

            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found" -Title "Error" -Color "Red"
                return $false
            }

            # Add note to task
            if (-not $task.notes) {
                $task | Add-Member -MemberType NoteProperty -Name 'notes' -Value @() -Force
            }

            $task.notes += $note.Trim()

            Save-PmcData -Data $data -Action "Added note to task $taskId"
            Show-InfoMessage -Message "Note added to task #$taskId" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to add note: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# === PROJECT OPERATION SCREENS ===

# Project Archive Form Screen
class ProjectArchiveFormScreen : PmcFormScreen {
    ProjectArchiveFormScreen() {
        $this.Title = "Archive Project"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Get list of active projects
        $projectList = @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ } | Sort-Object)

        if ($projectList.Count -eq 0) {
            $projectList = @('No projects available')
        }

        return @(
            @{Name='projectName'; Label='Select project to archive'; Required=$true; Type='select'; Options=$projectList}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $projectName = [string]$input['projectName']

            if ($projectName -eq 'No projects available') {
                Show-InfoMessage -Message "No projects available to archive" -Title "Info" -Color "Yellow"
                return $false
            }

            $data = Get-PmcAllData

            # Find the project
            $project = $data.projects | Where-Object {
                ($_ -is [string] -and $_ -eq $projectName) -or
                ($_.PSObject.Properties['name'] -and $_.name -eq $projectName)
            } | Select-Object -First 1

            if (-not $project) {
                Show-InfoMessage -Message "Project '$projectName' not found" -Title "Error" -Color "Red"
                return $false
            }

            # Set status to archived
            if ($project -is [string]) {
                # Convert string project to object
                $index = $data.projects.IndexOf($project)
                $data.projects[$index] = [PSCustomObject]@{
                    name = $projectName
                    status = 'archived'
                }
            } else {
                # Add or update status property
                $project | Add-Member -MemberType NoteProperty -Name 'status' -Value 'archived' -Force
            }

            Save-PmcData -Data $data -Action "Archived project: $projectName"
            $this.App.LoadProjects()
            Show-InfoMessage -Message "Project '$projectName' has been archived" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to archive project: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Project Delete Form Screen
class ProjectDeleteFormScreen : PmcFormScreen {
    ProjectDeleteFormScreen() {
        $this.Title = "Delete Project"
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # Get list of all projects
        $projectList = @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ } | Sort-Object)

        if ($projectList.Count -eq 0) {
            $projectList = @('No projects available')
        }

        return @(
            @{Name='projectName'; Label='Select project to delete'; Required=$true; Type='select'; Options=$projectList}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $projectName = [string]$input['projectName']

            if ($projectName -eq 'No projects available') {
                Show-InfoMessage -Message "No projects available to delete" -Title "Info" -Color "Yellow"
                return $false
            }

            $data = Get-PmcAllData

            # Check if project exists
            $exists = @($data.projects | Where-Object {
                ($_ -is [string] -and $_ -eq $projectName) -or
                ($_.PSObject.Properties['name'] -and $_.name -eq $projectName)
            }).Count -gt 0

            if (-not $exists) {
                Show-InfoMessage -Message "Project '$projectName' not found" -Title "Error" -Color "Red"
                return $false
            }

            # Check if any tasks use this project
            $tasksUsingProject = @($data.tasks | Where-Object { $_.project -eq $projectName })
            if ($tasksUsingProject.Count -gt 0) {
                $msg = "WARNING: $($tasksUsingProject.Count) task(s) are assigned to this project.`n`nThey will be moved to inbox.`n`nDelete project '$projectName'?"
                $confirmed = Show-ConfirmDialog -Message $msg -Title "Confirm Deletion"
            } else {
                $confirmed = Show-ConfirmDialog -Message "Delete project '$projectName'?`n`n(This cannot be undone)" -Title "Confirm Deletion"
            }

            if (-not $confirmed) {
                Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                return $false
            }

            # Move tasks to inbox
            foreach ($task in $tasksUsingProject) {
                $task.project = 'inbox'
            }

            # Remove project from array
            $data.projects = @(
                $data.projects | Where-Object {
                    $pName = if ($_ -is [string]) { $_ } else { $_.name }
                    $pName -ne $projectName
                }
            )

            Save-PmcData -Data $data -Action "Deleted project: $projectName"
            $this.App.LoadProjects()
            Show-InfoMessage -Message "Project '$projectName' deleted successfully" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to delete project: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# Project Edit Form Screen
class ProjectEditFormScreen : PmcFormScreen {
    ProjectEditFormScreen() {
        $this.Title = "Edit Project"
    }

    # Constructor for edit mode with specific project
    ProjectEditFormScreen([object]$project) {
        $this.Title = "Edit Project"
        $this.EditingObject = $project
    }

    [array] GetFields() {
        $data = Get-PmcAllData

        # If no project specified, let user select one
        if (-not $this.IsEditMode()) {
            $projectList = @($data.projects | ForEach-Object {
                if ($_ -is [string]) { $_ }
                elseif ($_.PSObject.Properties['name']) { $_.name }
            } | Where-Object { $_ } | Sort-Object)

            if ($projectList.Count -eq 0) {
                $projectList = @('No projects available')
            }

            return @(
                @{Name='projectName'; Label='Select project to edit'; Required=$true; Type='select'; Options=$projectList}
            )
        }

        # Edit mode - show project fields
        $proj = $this.EditingObject
        $nameVal = if ($proj -is [string]) { $proj } elseif ($proj.PSObject.Properties['name']) { [string]$proj.name } else { '' }
        $descVal = if ($proj.PSObject.Properties['description']) { [string]$proj.description } else { '' }
        $statusVal = if ($proj.PSObject.Properties['status']) { [string]$proj.status } else { 'active' }

        return @(
            @{Name='name'; Label='Project Name'; Required=$true; Type='text'; Value=$nameVal}
            @{Name='description'; Label='Description'; Required=$false; Type='text'; Value=$descVal}
            @{Name='status'; Label='Status'; Required=$false; Type='select'; Options=@('active','archived','on-hold'); Value=$statusVal}
        )
    }

    [bool] SaveForm([hashtable]$input) {
        try {
            $data = Get-PmcAllData

            # If not in edit mode yet, find and edit the selected project
            if (-not $this.IsEditMode()) {
                $projectName = [string]$input['projectName']

                if ($projectName -eq 'No projects available') {
                    Show-InfoMessage -Message "No projects available to edit" -Title "Info" -Color "Yellow"
                    return $false
                }

                # Find the project
                $project = $data.projects | Where-Object {
                    ($_ -is [string] -and $_ -eq $projectName) -or
                    ($_.PSObject.Properties['name'] -and $_.name -eq $projectName)
                } | Select-Object -First 1

                if (-not $project) {
                    Show-InfoMessage -Message "Project '$projectName' not found" -Title "Error" -Color "Red"
                    return $false
                }

                # Set editing object and re-show form
                $this.EditingObject = $project
                $fields = $this.GetFields()
                $input = Show-InputForm -Title $this.Title -Fields $fields

                if ($null -eq $input) {
                    return $false
                }
            }

            # Now we're in edit mode - update the project
            $proj = $this.EditingObject
            $oldName = if ($proj -is [string]) { $proj } else { $proj.name }
            $newName = [string]$input['name']

            if ([string]::IsNullOrWhiteSpace($newName)) {
                Show-InfoMessage -Message "Project name is required" -Title "Error" -Color "Red"
                return $false
            }

            # Check for duplicate name (if changed)
            if ($newName -ne $oldName) {
                $exists = @($data.projects | Where-Object {
                    $pName = if ($_ -is [string]) { $_ } else { $_.name }
                    $pName -eq $newName
                }).Count -gt 0

                if ($exists) {
                    Show-InfoMessage -Message "Project '$newName' already exists" -Title "Error" -Color "Red"
                    return $false
                }
            }

            # Find project in array and update
            $index = -1
            for ($i = 0; $i -lt $data.projects.Count; $i++) {
                $p = $data.projects[$i]
                $pName = if ($p -is [string]) { $p } else { $p.name }
                if ($pName -eq $oldName) {
                    $index = $i
                    break
                }
            }

            if ($index -eq -1) {
                Show-InfoMessage -Message "Project not found in data" -Title "Error" -Color "Red"
                return $false
            }

            # Convert to object if string, or update existing object
            if ($proj -is [string]) {
                $data.projects[$index] = [PSCustomObject]@{
                    name = $newName
                    description = $input['description']
                    status = $input['status']
                }
            } else {
                $proj.name = $newName
                $proj | Add-Member -MemberType NoteProperty -Name 'description' -Value $input['description'] -Force
                $proj | Add-Member -MemberType NoteProperty -Name 'status' -Value $input['status'] -Force
            }

            # Update tasks if project name changed
            if ($newName -ne $oldName) {
                foreach ($task in $data.tasks) {
                    if ($task.project -eq $oldName) {
                        $task.project = $newName
                    }
                }
            }

            Save-PmcData -Data $data -Action "Edited project: $newName"
            $this.App.LoadProjects()
            Show-InfoMessage -Message "Project '$newName' updated successfully" -Title "Success" -Color "Green"
            return $true

        } catch {
            Show-InfoMessage -Message "Failed to edit project: $_" -Title "Error" -Color "Red"
            return $false
        }
    }
}

# === MENU SYSTEM ===
class PmcMenuItem {
    [string]$Label
    [string]$Action
    [char]$Hotkey
    [bool]$Enabled = $true
    [bool]$Separator = $false

    PmcMenuItem([string]$label, [string]$action, [char]$hotkey) {
        $this.Label = $label
        $this.Action = $action
        $this.Hotkey = $hotkey
    }

    static [PmcMenuItem] Separator() {
        $item = [PmcMenuItem]::new("", "", ' ')
        $item.Separator = $true
        return $item
    }
}

class PmcMenuSystem {
    [PmcSimpleTerminal]$terminal
    [hashtable]$menus = @{}
    [string[]]$menuOrder = @()
    [hashtable]$menuPositions = @{}
    [int]$selectedMenu = -1
    [bool]$inMenuMode = $false
    [bool]$showingDropdown = $false

    # Track previous dropdown position/size for clearing
    [int]$lastDropdownX = -1
    [int]$lastDropdownY = -1
    [int]$lastDropdownWidth = -1
    [int]$lastDropdownHeight = -1

    PmcMenuSystem() {
        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.InitializeDefaultMenus()
    }

    [void] InitializeDefaultMenus() {
        $this.AddMenu('File', 'F', @(
            [PmcMenuItem]::new('Backup Data', 'file:backup', 'B'),
            [PmcMenuItem]::new('Restore Data', 'file:restore', 'R'),
            [PmcMenuItem]::new('Clear Backups', 'file:clearbackups', 'C'),
            [PmcMenuItem]::new('Exit', 'app:exit', 'X')
        ))
        $this.AddMenu('Tasks', 'T', @(
            [PmcMenuItem]::new('Task List', 'task:list', 'L')
        ))
        $this.AddMenu('Projects', 'P', @(
            [PmcMenuItem]::new('Project List', 'project:list', 'L')
        ))
        $this.AddMenu('Time', 'I', @(
            [PmcMenuItem]::new('Time Log', 'time:list', 'L'),
            [PmcMenuItem]::new('Weekly Report', 'tools:weeklyreport', 'W')
        ))
        $this.AddMenu('View', 'V', @(
            [PmcMenuItem]::new('Overdue', 'view:overdue', 'O'),
            [PmcMenuItem]::new('Today', 'view:today', 'T'),
            [PmcMenuItem]::new('Week', 'view:week', 'W'),
            [PmcMenuItem]::new('Kanban Board', 'view:kanban', 'K'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Agenda', 'view:agenda', 'G'),
            [PmcMenuItem]::new('Next Actions', 'view:nextactions', 'N'),
            [PmcMenuItem]::new('Month', 'view:month', 'M'),
            [PmcMenuItem]::new('Burndown Chart', 'view:burndown', 'C'),
            [PmcMenuItem]::new('Help', 'view:help', 'H')
        ))
        $this.AddMenu('Tools', 'O', @(
            # [PmcMenuItem]::new('Wizard', 'tools:wizard', 'W'),  # Disabled - not implemented
            [PmcMenuItem]::new('Theme', 'tools:theme', 'T'),
            [PmcMenuItem]::new('Theme Editor', 'tools:themeedit', 'E'),
            [PmcMenuItem]::new('Preferences', 'tools:preferences', 'P'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Excel T2020 Workflow', 'excel:t2020', 'X'),
            [PmcMenuItem]::new('Excel Preview', 'excel:preview', 'V')
        ))
        $this.AddMenu('Help', 'H', @(
            [PmcMenuItem]::new('Help Browser', 'help:browser', 'B'),
            [PmcMenuItem]::new('About PMC', 'help:about', 'A')
        ))
    }

    [void] AddMenu([string]$name, [char]$hotkey, [PmcMenuItem[]]$items) {
        $this.menus[$name] = @{ Name = $name; Hotkey = $hotkey; Items = $items }
        $this.menuOrder += $name
    }

    [void] DrawMenuBar() {
        # NOTE: No BeginFrame/EndFrame - caller manages frames
        $this.terminal.UpdateDimensions()
        $this.terminal.FillArea(0, 0, $this.terminal.Width, 1, ' ')

        $x = 2
        for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
            $menuName = $this.menuOrder[$i]
            $menu = $this.menus[$menuName]
            $hotkey = $menu.Hotkey

            # Store the X position of this menu for dropdown positioning
            $this.menuPositions[$menuName] = $x

            if ($this.inMenuMode -and $i -eq $this.selectedMenu) {
                $this.terminal.WriteAtColor($x, 0, $menuName, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor($x, 0, $menuName, [PmcVT100]::White(), "")
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Gray(), "")
            }
            $x += $menuName.Length + 6
        }

        $this.terminal.DrawHorizontalLine(0, 1, $this.terminal.Width)
    }

    [string] HandleInput() {
        while ($true) {
            $this.DrawMenuBar()
            $key = [Console]::ReadKey($true)

            if (-not $this.inMenuMode) {
                # Check Alt+letter menu activations FIRST (before generic Alt check)
                if ($key.Modifiers -band [ConsoleModifiers]::Alt) {
                    # Check for Alt+menu hotkey (F, E, T, P, M, V, C, D, O, H)
                    $menuActivated = $false
                    for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                        $menuName = $this.menuOrder[$i]
                        $menu = $this.menus[$menuName]
                        if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                            $this.inMenuMode = $true
                            $this.selectedMenu = $i
                            $menuActivated = $true
                            break
                        }
                    }
                    if ($menuActivated) {
        Write-ConsoleUIDebug "Alt+$($key.Key) activated menu $($this.menuOrder[$this.selectedMenu])" "MENU"
                        # Show dropdown immediately instead of waiting for Enter
                        return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                    }
                    # Alt+X to exit
                    if ($key.Key -eq 'X') {
                        return "app:exit"
                    }
                }
                # F10 activates menu bar at position 0
                if ($key.Key -eq 'F10') {
                    $this.inMenuMode = $true
                    $this.selectedMenu = 0
                    continue
                }
                # Escape to exit
                if ($key.Key -eq 'Escape') {
                    return "app:exit"
                }
                return ""
            } else {
                # While in menu mode, allow Alt+Hotkey to jump directly to another menu
                if ($key.Modifiers -band [ConsoleModifiers]::Alt) {
                    for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                        $menuName = $this.menuOrder[$i]
                        $menu = $this.menus[$menuName]
                        if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                            $this.selectedMenu = $i
                            return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                        }
                    }
                }
                switch ($key.Key) {
                    'LeftArrow' { if ($this.selectedMenu -gt 0) { $this.selectedMenu-- } else { $this.selectedMenu = $this.menuOrder.Count - 1 } }
                    'RightArrow' { if ($this.selectedMenu -lt $this.menuOrder.Count - 1) { $this.selectedMenu++ } else { $this.selectedMenu = 0 } }
                    'Enter' {
                        if ($this.selectedMenu -ge 0 -and $this.selectedMenu -lt $this.menuOrder.Count) {
                            return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                        }
                    }
                    'Escape' { $this.inMenuMode = $false; $this.selectedMenu = -1 }
                }
            }
        }
        return ""
    }

    [string] ShowDropdown([string]$menuName) {
        $menu = $this.menus[$menuName]
        if (-not $menu) { return "" }
        $items = $menu.Items

        # Calculate dynamic X position based on menu bar position
        $dropdownX = if ($this.menuPositions.ContainsKey($menuName)) {
            $this.menuPositions[$menuName]
        } else {
            2  # Fallback to default if position not found
        }
        $dropdownY = 2

        # Calculate dynamic width based on longest menu item text
        $maxWidth = 20  # Minimum width
        foreach ($item in $items) {
            if (-not $item.Separator) {
                $itemText = " {0}({1}) " -f $item.Label, $item.Hotkey
                $itemWidth = $itemText.Length + 4  # +4 for padding and borders
                if ($itemWidth -gt $maxWidth) {
                    $maxWidth = $itemWidth
                }
            }
        }

        # Clamp dropdown to terminal width to prevent going off-screen
        $terminalWidth = $this.terminal.Width
        if (($dropdownX + $maxWidth) -gt $terminalWidth) {
            # Adjust X position to keep dropdown on screen
            $dropdownX = [Math]::Max(0, $terminalWidth - $maxWidth)
        }

        # Clear previous dropdown if one exists
        if ($this.lastDropdownX -ge 0 -and $this.lastDropdownY -ge 0 -and
            $this.lastDropdownWidth -gt 0 -and $this.lastDropdownHeight -gt 0) {
            $this.terminal.FillArea($this.lastDropdownX, $this.lastDropdownY,
                                    $this.lastDropdownWidth, $this.lastDropdownHeight, ' ')
        }

        # Store current dropdown dimensions for next time
        $this.lastDropdownX = $dropdownX
        $this.lastDropdownY = $dropdownY
        $this.lastDropdownWidth = $maxWidth
        $this.lastDropdownHeight = $items.Count + 2

        # Find first non-separator item
        $selectedItem = 0
        while ($selectedItem -lt $items.Count -and $items[$selectedItem].Separator) {
            $selectedItem++
        }
        if ($selectedItem -ge $items.Count) {
            $selectedItem = 0  # Fallback if all items are separators (shouldn't happen)
        }

        $this.showingDropdown = $true
        while ($true) {
            # Draw dropdown box and items (OVERLAY - no BeginFrame to avoid clearing screen)
            $this.terminal.DrawFilledBox($dropdownX, $dropdownY, $maxWidth, $items.Count + 2, $true)
            for ($i = 0; $i -lt $items.Count; $i++) {
                $item = $items[$i]
                $itemY = $dropdownY + 1 + $i

                if ($item.Separator) {
                    # Render separator as a horizontal line
                    $separatorLine = ([char]0x2500).ToString() * ($maxWidth - 2)
                    $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $separatorLine, [PmcVT100]::White(), "")
                } else {
                    $itemText = " {0}({1})" -f $item.Label, $item.Hotkey
                    if ($i -eq $selectedItem) {
                        $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2), [PmcVT100]::BgBlue(), [PmcVT100]::White())
                    } else {
                        $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2), [PmcVT100]::White(), "")
                    }
                }
            }

            # Hide cursor by positioning it off-screen
            try {
                [Console]::CursorVisible = $false
                [Console]::SetCursorPosition(0, $this.terminal.Height - 1)
            } catch {}

            $key = [Console]::ReadKey($true)

            # Check for Alt+menu hotkey to switch menus
            if ($key.Modifiers -band [ConsoleModifiers]::Alt) {
                for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                    $otherMenuName = $this.menuOrder[$i]
                    $otherMenu = $this.menus[$otherMenuName]
                    if ($otherMenu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                        # Switch to different menu's dropdown
                        $this.selectedMenu = $i
                        $this.showingDropdown = $false
                        return $this.ShowDropdown($otherMenuName)
                    }
                }
            }

            # Check for letter hotkeys (without Alt modifier)
            if (-not ($key.Modifiers -band [ConsoleModifiers]::Alt)) {
                for ($i = 0; $i -lt $items.Count; $i++) {
                    if (-not $items[$i].Separator -and $items[$i].Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                        # Clear the dropdown before exiting
                        if ($this.lastDropdownX -ge 0 -and $this.lastDropdownY -ge 0) {
                            $this.terminal.FillArea($this.lastDropdownX, $this.lastDropdownY,
                                                    $this.lastDropdownWidth, $this.lastDropdownHeight, ' ')
                        }
                        $this.inMenuMode = $false
                        $this.selectedMenu = -1
                        $this.showingDropdown = $false
                        return $items[$i].Action
                    }
                }
            }

            switch ($key.Key) {
                'UpArrow' {
                    # Move up, skipping separators
                    if ($selectedItem -gt 0) {
                        $selectedItem--
                        while ($selectedItem -gt 0 -and $items[$selectedItem].Separator) {
                            $selectedItem--
                        }
                        # If we landed on a separator at position 0, find next non-separator going down
                        if ($items[$selectedItem].Separator) {
                            $selectedItem++
                            while ($selectedItem -lt $items.Count -and $items[$selectedItem].Separator) {
                                $selectedItem++
                            }
                        }
                    }
                }
                'DownArrow' {
                    # Move down, skipping separators
                    if ($selectedItem -lt $items.Count - 1) {
                        $selectedItem++
                        while ($selectedItem -lt $items.Count - 1 -and $items[$selectedItem].Separator) {
                            $selectedItem++
                        }
                        # If we landed on a separator at the end, find previous non-separator going up
                        if ($items[$selectedItem].Separator) {
                            $selectedItem--
                            while ($selectedItem -gt 0 -and $items[$selectedItem].Separator) {
                                $selectedItem--
                            }
                        }
                    }
                }
                'LeftArrow' {
                    # Navigate to previous menu
                    if ($this.selectedMenu -gt 0) {
                        $this.selectedMenu--
                    } else {
                        $this.selectedMenu = $this.menuOrder.Count - 1
                    }
                    $this.showingDropdown = $false
                    return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                }
                'RightArrow' {
                    # Navigate to next menu
                    if ($this.selectedMenu -lt $this.menuOrder.Count - 1) {
                        $this.selectedMenu++
                    } else {
                        $this.selectedMenu = 0
                    }
                    $this.showingDropdown = $false
                    return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                }
                'Enter' {
                    # Don't activate separators
                    if ($items[$selectedItem].Separator) {
                        continue
                    }
                    # Clear the dropdown before exiting
                    if ($this.lastDropdownX -ge 0 -and $this.lastDropdownY -ge 0) {
                        $this.terminal.FillArea($this.lastDropdownX, $this.lastDropdownY,
                                                $this.lastDropdownWidth, $this.lastDropdownHeight, ' ')
                    }
                    $this.inMenuMode = $false
                    $this.selectedMenu = -1
                    $this.showingDropdown = $false
                    return $items[$selectedItem].Action
                }
                'Escape' {
                    # Close dropdown, exit menu mode
                    # Clear the dropdown before exiting
                    if ($this.lastDropdownX -ge 0 -and $this.lastDropdownY -ge 0) {
                        $this.terminal.FillArea($this.lastDropdownX, $this.lastDropdownY,
                                                $this.lastDropdownWidth, $this.lastDropdownHeight, ' ')
                    }
                    $this.inMenuMode = $false
                    $this.selectedMenu = -1
                    $this.showingDropdown = $false
                    return ""
                }
            }
        }
        return ""
    }

    [string] GetActionDescription([string]$action) { return $action }
}

## CLI adapter removed in ConsoleUI copy

# === MAIN APP ===
function Show-ConsoleUIFooter {
    param($app,[string]$msg)
    # Avoid flushing input to prevent dropping Alt/Shift key sequences
    $app.terminal.DrawFooter($msg)
}

function Browse-ConsoleUIPath {
    param($app,[string]$StartPath,[bool]$DirectoriesOnly=$false)
    $cwd = if ($StartPath -and (Test-Path $StartPath)) {
        if (Test-Path $StartPath -PathType Leaf) { Split-Path -Parent $StartPath } else { $StartPath }
    } else { (Get-Location).Path }
    $selected = 0; $topIndex = 0
    while ($true) {
        $items = @()
        try { $dirs = @(Get-ChildItem -Force -Directory -LiteralPath $cwd | Sort-Object Name) } catch { $dirs=@() }
        try { $files = if ($DirectoriesOnly) { @() } else { @(Get-ChildItem -Force -File -LiteralPath $cwd | Sort-Object Name) } } catch { $files=@() }
        $items += ([pscustomobject]@{ Kind='Up'; Name='..' })
        foreach ($d in $dirs) { $items += [pscustomobject]@{ Kind='Dir'; Name=$d.Name } }
        foreach ($f in $files) { $items += [pscustomobject]@{ Kind='File'; Name=$f.Name } }
        if ($selected -ge $items.Count) { $selected = [Math]::Max(0, $items.Count-1) }
        if ($selected -lt 0) { $selected = 0 }

        $app.terminal.Clear(); $app.menuSystem.DrawMenuBar()
        $kind = 'File'; if ($DirectoriesOnly) { $kind = 'Folder' }
        $title = " Select $kind "
        $titleX = ($app.terminal.Width - $title.Length) / 2
        $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $app.terminal.WriteAtColor(4, 5, "Current: $cwd", [PmcVT100]::Cyan(), "")

        $listTop = 7
        $maxVisible = [Math]::Max(5, [Math]::Min(25, $app.terminal.Height - $listTop - 3))
        if ($selected -lt $topIndex) { $topIndex = $selected }
        if ($selected -ge ($topIndex + $maxVisible)) { $topIndex = $selected - $maxVisible + 1 }
        for ($row=0; $row -lt $maxVisible; $row++) {
            $idx = $topIndex + $row
            $line = ''
            if ($idx -lt $items.Count) {
                $item = $items[$idx]
                $tag = if ($item.Kind -eq 'Dir') { '[D]' } elseif ($item.Kind -eq 'File') { '[F]' } else { '  ' }
                $line = "$tag $($item.Name)"
            }
            $prefix = if (($topIndex + $row) -eq $selected) { '> ' } else { '  ' }
            $color = if (($topIndex + $row) -eq $selected) { [PmcVT100]::Yellow() } else { [PmcVT100]::White() }
            $app.terminal.WriteAtColor(4, $listTop + $row, ($prefix + $line).PadRight($app.terminal.Width - 8), $color, "")
        }
        Show-ConsoleUIFooter $app "↑/↓ scroll  |  Enter: select  |  → open folder  |  ←/Backspace up  |  Esc cancel"
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { if ($selected -gt 0) { $selected--; if ($selected -lt $topIndex) { $topIndex = $selected } } }
            'DownArrow' { if ($selected -lt $items.Count-1) { $selected++; if ($selected -ge $topIndex+$maxVisible) { $topIndex = $selected - $maxVisible + 1 } } }
            'PageUp' { $selected = [Math]::Max(0, $selected - $maxVisible); $topIndex = [Math]::Max(0, $topIndex - $maxVisible) }
            'PageDown' { $selected = [Math]::Min($items.Count-1, $selected + $maxVisible); if ($selected -ge $topIndex+$maxVisible) { $topIndex = $selected - $maxVisible + 1 } }
            'Home' { $selected = 0; $topIndex = 0 }
            'End' { $selected = [Math]::Max(0, $items.Count-1); $topIndex = [Math]::Max(0, $items.Count - $maxVisible) }
            'LeftArrow' {
                try {
                    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = ($StartPath ?? (Get-Location).Path) }
                    else {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    }
                } catch {}
            }
            'Backspace' {
                try {
                    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = ($StartPath ?? (Get-Location).Path) }
                    else {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    }
                } catch {}
            }
            'RightArrow' { if ($items.Count -gt 0) { $it=$items[$selected]; if ($it.Kind -eq 'Dir') { $cwd = Join-Path $cwd $it.Name } } }
            'Escape' { return $null }
            'Enter' {
                if ($items.Count -eq 0) { continue }
                $it = $items[$selected]
                if ($it.Kind -eq 'Up') {
                    try {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    } catch {}
                }
                elseif ($it.Kind -eq 'Dir') { return (Join-Path $cwd $it.Name) }
                else { return (Join-Path $cwd $it.Name) }
            }
        }
    }
}

function Select-ConsoleUIPathAt {
    param($app,[string]$Hint,[int]$Col,[int]$Row,[string]$StartPath,[bool]$DirectoriesOnly=$false)
    Show-ConsoleUIFooter $app ("$Hint  |  Enter: Pick  |  Tab: Skip  |  Esc: Cancel")
    [Console]::SetCursorPosition($Col, $Row)
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"; return '' }
    if ($key.Key -eq 'Tab') { Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"; return '' }
    $sel = Browse-ConsoleUIPath -app $app -StartPath $StartPath -DirectoriesOnly:$DirectoriesOnly
    Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"
    return ($sel ?? '')
}

function Get-ConsoleUISelectedProjectName {
    param($app)
    try {
        if ($app.currentView -eq 'projectlist') {
            if ($app.selectedProjectIndex -lt $app.projects.Count) {
                $p = $app.projects[$app.selectedProjectIndex]
                $pname = $null
                if ($p -is [string]) { $pname = $p } else { $pname = $p.name }
                return $pname
            }
        }
        if ($app.filterProject) { return $app.filterProject }
    } catch {}
    return $null
}

function Open-SystemPath {
    param([string]$Path,[bool]$IsDir=$false)
    try {
        if (-not $Path -or -not (Test-Path $Path)) { return $false }
        $isWin = $false
        try { if ($env:OS -like '*Windows*') { $isWin = $true } } catch {}
        if (-not $isWin) { try { if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) { $isWin = $true } } catch {} }
        if ($isWin) {
            if ($IsDir) { Start-Process -FilePath explorer.exe -ArgumentList @("$Path") | Out-Null }
            else { Start-Process -FilePath "$Path" | Out-Null }
            return $true
        } else {
            $cmd = 'xdg-open'
            if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { $cmd = 'gio'; $args = @('open', "$Path") } else { $args = @("$Path") }
            Start-Process -FilePath $cmd -ArgumentList $args | Out-Null
            return $true
        }
    } catch { return $false }
}

function Open-ConsoleUIProjectPath {
    param($app,[string]$Field)
    $projName = Get-ConsoleUISelectedProjectName -app $app
    if (-not $projName) { Show-InfoMessage -Message "Select a project first (Projects → Project List)" -Title "Info" -Color "Yellow"; return }
    try {
        $data = Get-PmcAllData
        $proj = $data.projects | ForEach-Object {
            if ($_ -is [string]) { if ($_ -eq $projName) { $_ } } else { if ($_.name -eq $projName) { $_ } }
        } | Select-Object -First 1
        if (-not $proj) { Show-InfoMessage -Message "Project not found: $projName" -Title "Error" -Color "Red"; return }
        $path = $null
        if ($proj.PSObject.Properties[$Field]) { $path = $proj.$Field }
        if (-not $path -or [string]::IsNullOrWhiteSpace($path)) { Show-InfoMessage -Message "$Field not set for project" -Title "Error" -Color "Red"; return }
        $isDir = ($Field -eq 'ProjFolder')
        if (Open-SystemPath -Path $path -IsDir:$isDir) {
            Show-InfoMessage -Message "Opened: $path" -Title "Success" -Color "Green"
        } else {
            Show-InfoMessage -Message "Failed to open: $path" -Title "Error" -Color "Red"
        }
    } catch {
        Show-InfoMessage -Message "Failed to open: $_" -Title "Error" -Color "Red"
    }
}

function Draw-ConsoleUIProjectFormValues {
    param($app,[int]$RowStart,[hashtable]$Inputs)
    try {
        $app.terminal.WriteAt(28, $RowStart + 0, [string]($Inputs.Name ?? ''))
        $app.terminal.WriteAt(16, $RowStart + 1, [string]($Inputs.Description ?? ''))
        $app.terminal.WriteAt(9,  $RowStart + 2, [string]($Inputs.ID1 ?? ''))
        $app.terminal.WriteAt(9,  $RowStart + 3, [string]($Inputs.ID2 ?? ''))
        $app.terminal.WriteAt(20, $RowStart + 4, [string]($Inputs.ProjFolder ?? ''))
        $app.terminal.WriteAt(14, $RowStart + 5, [string]($Inputs.CAAName ?? ''))
        $app.terminal.WriteAt(17, $RowStart + 6, [string]($Inputs.RequestName ?? ''))
        $app.terminal.WriteAt(11, $RowStart + 7, [string]($Inputs.T2020 ?? ''))
        $app.terminal.WriteAt(32, $RowStart + 8, [string]($Inputs.AssignedDate ?? ''))
        $app.terminal.WriteAt(27, $RowStart + 9, [string]($Inputs.DueDate ?? ''))
        $app.terminal.WriteAt(26, $RowStart + 10, [string]($Inputs.BFDate ?? ''))
    } catch {}
}

class PmcConsoleUIApp {
    [PmcSimpleTerminal]$terminal
    [PmcMenuSystem]$menuSystem
    [PmcScreenManager]$screenManager  # New ScreenManager architecture
    # CLI adapter removed in ConsoleUI build
    [bool]$running = $true
    [string]$statusMessage = ""
    [string]$currentView = 'main'  # main, tasklist, taskdetail
    [string]$previousView = ''  # Track where we came from
    [array]$tasks = @()
    [int]$selectedTaskIndex = 0
    [int]$scrollOffset = 0
    [object]$selectedTask = $null
    [string]$filterProject = ''  # Empty means show all
    [string]$searchText = ''  # Empty means no search
    [string]$sortBy = 'id'  # id, priority, status, created, due
    [hashtable]$stats = @{} # Performance stats
    [hashtable]$multiSelect = @{} # Task ID -> selected boolean
    [array]$projects = @()  # Project list
    [int]$selectedProjectIndex = 0  # Selected project in list
    [string]$selectedProjectName = ''  # Selected project name for edit/info flows
    [array]$timelogs = @()  # Time log entries
    [int]$selectedTimeIndex = 0  # Selected time entry in list

    # Dirty flag for deferred saves (performance optimization)
    [bool]$dataDirty = $false

    [array]$specialItems = @()
    [int]$specialSelectedIndex = 0

    PmcConsoleUIApp() {
        # Theme is managed by centralized system via deps/Theme.ps1

        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.menuSystem = [PmcMenuSystem]::new()
        # No CLI adapter
        $this.LoadTasks()
    }

    # Convenience overload to avoid passing $null explicitly from call sites
    [void] LoadTasks() { $this.LoadTasks($null) }

    [void] LoadTasks([object]$dataInput = $null) {
        try {
            $data = if ($null -ne $dataInput) { $dataInput } else { Get-PmcAllData }
            $allTasks = @($data.tasks | Where-Object { $_ -ne $null })

            # Calculate stats
            $this.stats = @{
                total = $allTasks.Count
                active = @($allTasks | Where-Object { $_.status -ne 'completed' }).Count
                completed = @($allTasks | Where-Object { $_.status -eq 'completed' }).Count
                overdue = @($allTasks | Where-Object {
                    if (-not $_.due -or $_.status -eq 'completed') { return $false }
                    $d = Get-ConsoleUIDateOrNull $_.due
                    if ($d) { return ($d.Date -lt (Get-Date).Date) } else { return $false }
                }).Count
            }

            if ($this.filterProject) {
                $allTasks = @($allTasks | Where-Object { $_.project -eq $this.filterProject })
            }

            if ($this.searchText) {
                $search = $this.searchText.ToLower()
                $allTasks = @($allTasks | Where-Object {
                    ($_.text -and $_.text.ToLower().Contains($search)) -or
                    ($_.project -and $_.project.ToLower().Contains($search)) -or
                    ($_.id -and $_.id.ToString().Contains($search))
                })
            }

            # Apply sorting
            switch ($this.sortBy) {
                'priority' {
                    $priorityOrder = @{ 'high' = 1; 'medium' = 2; 'low' = 3; 'none' = 4; $null = 5 }
                    $this.tasks = @($allTasks | Sort-Object { $priorityOrder[$_.priority] })
                }
                'status' {
                    $this.tasks = @($allTasks | Sort-Object status)
                }
                'created' {
                    $this.tasks = @($allTasks | Sort-Object created -Descending)
                }
                'due' {
                    # Sort by due date - invalid/missing at bottom
                    $this.tasks = @($allTasks | Sort-Object {
                        $d = Get-ConsoleUIDateOrNull $_.due
                        if ($d) { return $d } else { return [DateTime]::MaxValue }
                    })
                }
                default {
                    $this.tasks = @($allTasks | Sort-Object { [int]$_.id })
                }
            }
        } catch {
            $this.tasks = @()
        }
    }

    [void] LoadProjects() {
        try {
            $data = Get-PmcAllData
            $this.projects = if ($data.PSObject.Properties['projects']) {
                @($data.projects | Where-Object { $_ -ne $null } | ForEach-Object {
                    if ($_ -is [string]) { [pscustomobject]@{ name = $_ } } else { $_ }
                })
            } else { @() }
        } catch {
            $this.projects = @()
        }
    }

    [void] LoadTimeLogs() {
        try {
            $data = Get-PmcAllData
            $this.timelogs = if ($data.PSObject.Properties['timelogs']) {
                @($data.timelogs | Where-Object { $_ -ne $null } | Sort-Object { $_.date } -Descending)
            } else {
                @()
            }
        } catch {
            $this.timelogs = @()
        }
    }

    [void] Initialize() {
        Write-ConsoleUIDebug "Initialize() called" "APP"
        $this.terminal.Initialize()
        # Determine default landing view from config; default to todayview
        try {
            $cfg = Get-PmcConfig
            $dv = try { [string]$cfg.Behavior.DefaultView } catch { 'todayview' }
            switch ($dv) {
                'todayview' { $this.currentView = 'todayview' }
                'agendaview' { $this.currentView = 'agendaview' }
                'tasklist' { $this.currentView = 'tasklist' }
                default { $this.currentView = 'todayview' }
            }
        } catch { $this.currentView = 'todayview' }
        $this.statusMessage = "PMC Ready - F10 for menus, Esc to exit"
    }

    [void] DrawLayout() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.DrawBox(1, 3, $this.terminal.Width - 2, $this.terminal.Height - 6)
        $title = " PMC - Project Management Console "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Load and display quick stats
        try {
            $data = Get-PmcAllData
            $taskCount = $data.tasks.Count
            $activeCount = @($data.tasks | Where-Object { $_.status -ne 'completed' }).Count
            $projectCount = $data.projects.Count

            $this.terminal.WriteAtColor(4, 6, "Tasks: $taskCount total | Active: $activeCount | Completed: $($this.stats.completed)", [PmcVT100]::White(), "")
            if ($this.stats.overdue -gt 0) {
                $this.terminal.WriteAtColor(4, 7, "Overdue: ", [PmcVT100]::White(), "")
                $this.terminal.WriteAtColor(13, 7, "$($this.stats.overdue)", [PmcVT100]::Red(), "")
                $this.terminal.WriteAtColor(16, 7, " | Projects: $projectCount", [PmcVT100]::White(), "")
            } else {
                $this.terminal.WriteAtColor(4, 7, "Projects: $projectCount", [PmcVT100]::White(), "")
            }

            # Display recent tasks
            $this.terminal.WriteAtColor(4, 9, "Recent Tasks:", [PmcVT100]::Yellow(), "")
            $recentTasks = @($data.tasks | Sort-Object created -Descending | Select-Object -First 5)
            $y = 10
            foreach ($task in $recentTasks) {
                $statusIcon = if ($task.status -eq 'completed') { 'X' } else { 'o' }
                $statusColor = if ($task.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Cyan() }
                $text = $task.text
                if ($text.Length -gt 40) { $text = $text.Substring(0, 37) + "..." }
                $this.terminal.WriteAtColor(4, $y, $statusIcon, $statusColor, "")
                $this.terminal.WriteAtColor(6, $y, "$($task.id): $text", [PmcVT100]::White(), "")
                $y++
            }

            $y++
            $this.terminal.WriteAtColor(4, $y++, "Quick Keys:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+T - Task list", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+A - Add task", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+P - Projects", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "F10   - Menu bar", [PmcVT100]::Cyan(), "")
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading PMC data: $_", [PmcVT100]::Red(), "")
            Write-Host "DrawLayout error: $_" -ForegroundColor Red
            Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
        }
        $this.UpdateStatus()
        $this.terminal.EndFrame()
    }

    [void] UpdateStatus() {
        $statusY = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')
        if ($this.statusMessage) { $this.terminal.WriteAtColor(2, $statusY, $this.statusMessage, [PmcVT100]::Cyan(), "") }
    }

    [void] DrawFooter([string]$text) {
        $y = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $y, $this.terminal.Width, 1, ' ')
        $truncated = if ($text.Length -gt $this.terminal.Width - 4) {
            $text.Substring(0, $this.terminal.Width - 5) + '…'
        } else { $text }
        $this.terminal.WriteAtColor(2, $y, $truncated, [PmcVT100]::Cyan(), "")
    }

    [void] ShowSuccessMessage([string]$message) {
        $statusY = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAtColor(2, $statusY, "OK: $message", [PmcVT100]::Green(), "")
    }

    # Check for global menu/hotkeys - returns action string or empty if not a global key
    [string] CheckGlobalKeys([System.ConsoleKeyInfo]$key) {
        # F10 activates menu
        if ($key.Key -eq 'F10') {
            Write-ConsoleUIDebug "F10 pressed, showing menu" "GLOBAL"
            $action = $this.menuSystem.HandleInput()
            return $action
        }

        # Ctrl+N for Quick Add (from anywhere)
        if ( ($key.Modifiers -band [ConsoleModifiers]::Control) -and $key.Key -eq 'N') {
            Write-ConsoleUIDebug "Ctrl+N pressed, opening Quick Add" "GLOBAL"
            return "task:add"
        }

        # Alt+letter activates specific menu
        if ($key.Modifiers -band [ConsoleModifiers]::Alt) {
            # Check for Alt+menu hotkey
            for ($i = 0; $i -lt $this.menuSystem.menuOrder.Count; $i++) {
                $menuName = $this.menuSystem.menuOrder[$i]
                $menu = $this.menuSystem.menus[$menuName]
                if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                    Write-ConsoleUIDebug "Alt+$($key.Key) pressed, showing dropdown for $menuName" "GLOBAL"
                    # Show dropdown directly instead of using HandleInput
                    $action = $this.menuSystem.ShowDropdown($menuName)
                    return $action
                }
            }
            # Alt+X to exit
            if ($key.Key -eq 'X') {
                return "app:exit"
            }
        }

        return ""
    }

    # Process menu action from any screen
    [void] ProcessMenuAction([string]$action) {
        Write-ConsoleUIDebug "ProcessMenuAction: $action" "ACTION"

        # Try extended handlers first
        $handled = $false
        if ($this.PSObject.Methods['ProcessExtendedActions']) {
            $handled = $this.ProcessExtendedActions($action)
        }

        # Built-in handlers - ONLY set currentView, do NOT call Draw methods!
        if (-not $handled) {
            if ($action -ne 'app:exit') { $this.previousView = $this.currentView }
            switch ($action) {
                # File menu
                'file:backup' { $this.ShowBackupView() }
                'file:restore' { $this.ShowRestoreBackup() }
                'file:clearbackups' { $this.ShowClearBackups() }
                'app:exit' { $this.running = $false }

                # Edit menu
                'edit:undo' { $this.ShowUndoView() }
                'edit:redo' { $this.ShowRedoView() }

                # Task menu
                'task:add' { $this.ShowTaskAddForm() }
                'task:list' { $this.NavigateToTaskList() }
                'task:edit' { $this.currentView = 'taskedit' }
                'task:complete' { $this.ShowTaskCompleteForm() }
                'task:delete' { $this.ShowTaskDeleteForm() }
                'task:copy' { $this.ShowTaskCopyForm() }
                'task:move' { $this.ShowTaskMoveForm() }
                'task:find' { $this.ShowSearchForm() }
                'task:priority' { $this.ShowTaskPriorityForm() }
                'task:postpone' { $this.ShowTaskPostponeForm() }
                'task:note' { $this.ShowTaskNoteForm() }
                'task:import' { $this.currentView = 'taskimport' }
                'task:export' { $this.currentView = 'taskexport' }

                # Project menu
                'project:list' { $this.NavigateToProjectList() }
                'project:create' { $this.ShowProjectAddForm() }
                'project:edit' { $this.currentView = 'projectedit' }
                'project:rename' { $this.currentView = 'projectedit' }
                'project:archive' { $this.ShowProjectArchiveForm() }
                'project:delete' { $this.ShowProjectDeleteForm() }
                'project:stats' { $this.ShowProjectStats() }
                'project:info' { $this.ShowProjectInfo() }
                'project:recent' { $this.currentView = 'projectrecent' }
                # project open actions moved to Project List hotkeys

                # Time menu
                'time:add' { $this.ShowTimeAddForm() }
                'time:list' { $this.ShowTimeList() }
                'time:edit' { $this.currentView = 'timeedit' }
                'time:delete' { $this.currentView = 'timedelete' }
                'time:report' { $this.ShowTimeReport() }
                'timer:start' { $this.ShowTimerStart() }
                'timer:stop' { $this.ShowTimerStop() }
                'timer:status' { $this.ShowTimerStatus() }

                # View menu (ScreenManager-enabled views)
                'view:overdue' { $this.ShowOverdueView() }
                'view:today' { $this.ShowTodayView() }
                'view:week' { $this.ShowWeekView() }
                'view:kanban' { $this.ShowKanbanView() }
                'view:agenda' { $this.ShowAgendaView() }
                'view:tomorrow' { $this.ShowTomorrowView() }
                'view:month' { $this.ShowMonthView() }
                'view:upcoming' { $this.ShowUpcomingView() }
                'view:blocked' { $this.ShowBlockedView() }
                'view:noduedate' { $this.ShowNoDueDateView() }
                'view:nextactions' { $this.ShowNextActionsView() }
                'view:all' { $this.currentView = 'tasklist' }
                'view:burndown' { $this.ShowBurndownChart() }
                'view:help' { $this.ShowHelpView() }

                # Focus menu
                'focus:set' { $this.ShowFocusSetForm() }
                'focus:clear' { $this.ShowFocusClear() }
                'focus:status' { $this.ShowFocusStatus() }

                # Dependencies menu
                'dep:add' { $this.ShowDepAddForm() }
                'dep:remove' { $this.ShowDepRemoveForm() }
                'dep:show' { $this.ShowDepShowForm() }
                'dep:graph' { $this.currentView = 'depgraph' }

                # Tools menu
                'tools:review' { $this.currentView = 'toolsreview' }
                # 'tools:wizard' { $this.currentView = 'toolswizard' }  # Disabled - not implemented
                # 'tools:templates' { $this.currentView = 'toolstemplates' }  # Disabled - not implemented
                'tools:statistics' { $this.currentView = 'toolsstatistics' }
                'tools:velocity' { $this.currentView = 'toolsvelocity' }
                'tools:preferences' { $this.currentView = 'toolspreferences' }
                'tools:theme' { $this.ShowThemeScreen() }
                'tools:themeedit' { $this.ShowThemeScreen() }
                'tools:applytheme' { $this.ShowThemeScreen() }
                'tools:aliases' { $this.currentView = 'toolsaliases' }
                'tools:weeklyreport' { $this.currentView = 'toolsweeklyreport' }

                # Excel menu
                'excel:t2020' { $this.currentView = 'excelt2020' }
                'excel:preview' { $this.currentView = 'excelpreview' }

                # Help menu
                'help:browser' { $this.currentView = 'helpbrowser' }
                'help:categories' { $this.currentView = 'helpcategories' }
                'help:search' { $this.currentView = 'helpsearch' }
                'help:about' { $this.currentView = 'helpabout' }
            }
        }
    }

    # (removed duplicate GoBackOr definition)

    [void] DisplayResult([object]$result) {
        $contentY = 5
        $this.terminal.FillArea(2, $contentY, $this.terminal.Width - 4, $this.terminal.Height - 8, ' ')

        # Normalize result to ensure Type/Message/Data are available
        $type = 'info'
        $message = '(no result)'
        $dataOut = $null

        if ($null -ne $result) {
            if ($result -is [hashtable]) {
                if ($result.ContainsKey('Type') -and $result['Type']) { $type = [string]$result['Type'] }
                if ($result.ContainsKey('Message') -and $null -ne $result['Message']) { $message = [string]$result['Message'] } else { $message = [string]$result }
                if ($result.ContainsKey('Data')) { $dataOut = $result['Data'] }
            } else {
                # Try to read as object with properties; fall back to string
                if ($result.PSObject -and $result.PSObject.Properties['Type'] -and $result.Type) { $type = [string]$result.Type }
                if ($result.PSObject -and $result.PSObject.Properties['Message']) { $message = [string]$result.Message } else { $message = [string]$result }
                if ($result.PSObject -and $result.PSObject.Properties['Data']) { $dataOut = $result.Data }
            }
        }

        switch ($type) {
            'success' { $this.terminal.WriteAtColor(4, $contentY, "SUCCESS: " + $message, [PmcVT100]::Green(), "") }
            'error' { $this.terminal.WriteAtColor(4, $contentY, "ERROR: " + $message, [PmcVT100]::Red(), "") }
            'info' { $this.terminal.WriteAtColor(4, $contentY, "ℹ INFO: " + $message, [PmcVT100]::Cyan(), "") }
            'exit' { $this.running = $false; return }
            default { $this.terminal.WriteAtColor(4, $contentY, "ℹ INFO: " + $message, [PmcVT100]::Cyan(), "") }
        }

        if ($dataOut) { $this.terminal.WriteAt(4, $contentY + 2, [string]$dataOut) }
        $this.statusMessage = "${type}: $message".ToUpper()
        $this.UpdateStatus()
    }

    [void] Run() {
        Write-ConsoleUIDebug "Run() entered - using ScreenManager architecture" "APP"

        # Use new ScreenManager architecture
        $this.screenManager = [PmcScreenManager]::new($this)

        # Start with task list screen
        $taskListScreen = [TaskListScreen]::new()
        $this.screenManager.Push($taskListScreen)

        # Run the main loop
        $this.screenManager.Run()

        Write-ConsoleUIDebug "Run() exited" "APP"
    }

    # Navigation helpers for screens
    [void] NavigateToTaskList() {
        $this.LoadTasks()
        $screen = [TaskListScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] NavigateToProjectList() {
        $this.LoadProjects()
        $screen = [ProjectListScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Form navigation helpers
    [void] ShowTaskAddForm() {
        $screen = [TaskFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskEditForm([object]$task) {
        $screen = [TaskFormScreen]::new($task)
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskDetail([object]$task) {
        $screen = [TaskDetailScreen]::new($task)
        $this.screenManager.Push($screen)
    }

    [void] ShowProjectAddForm() {
        $screen = [ProjectFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowProjectEditForm([object]$project) {
        $screen = [ProjectFormScreen]::new($project)
        $this.screenManager.Push($screen)
    }

    # View screen navigation helpers
    [void] ShowOverdueView() {
        $screen = [OverdueViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTodayView() {
        $screen = [TodayViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowWeekView() {
        $screen = [WeekViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowKanbanView() {
        $screen = [KanbanScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowNoDueDateView() {
        $screen = [NoDueDateViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowBlockedView() {
        $screen = [BlockedViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTomorrowView() {
        $screen = [TomorrowViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowUpcomingView() {
        $screen = [UpcomingViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowNextActionsView() {
        $screen = [NextActionsViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowMonthView() {
        $screen = [MonthViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowAgendaView() {
        $screen = [AgendaViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Task Detail & Operations navigation helpers
    [void] ShowTaskCompleteForm() {
        $screen = [TaskCompleteFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskDeleteForm() {
        $screen = [TaskDeleteFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskCopyForm() {
        $screen = [TaskCopyFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskMoveForm() {
        $screen = [TaskMoveFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskPriorityForm() {
        $screen = [TaskPriorityFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskPostponeForm() {
        $screen = [TaskPostponeFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTaskNoteForm() {
        $screen = [TaskNoteFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowSearchForm() {
        $screen = [SearchFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowMultiSelectMode() {
        $screen = [MultiSelectModeScreen]::new()
        $this.screenManager.Push($screen)
    }

    # File Operations navigation helpers
    [void] ShowBackupView() {
        $screen = [BackupViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowRestoreBackup() {
        $screen = [RestoreBackupScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowClearBackups() {
        $screen = [ClearBackupsScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Time Tracking navigation helpers
    [void] ShowTimeList() {
        $screen = [TimeListScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTimeAddForm() {
        $screen = [TimeAddFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTimeEditForm([object]$timeLog) {
        $screen = [TimeEditFormScreen]::new($timeLog)
        $this.screenManager.Push($screen)
    }

    [void] ShowTimeDeleteForm([object]$timeLog) {
        $screen = [TimeDeleteFormScreen]::new($timeLog)
        $this.screenManager.Push($screen)
    }

    [void] ShowTimeReport() {
        $screen = [TimeReportScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Project Operations navigation helpers
    [void] ShowProjectStats() {
        $screen = [ProjectStatsScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowProjectInfo() {
        $screen = [ProjectInfoScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowProjectArchiveForm() {
        $screen = [ProjectArchiveFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowProjectDeleteForm() {
        $screen = [ProjectDeleteFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Focus Management navigation helpers
    [void] ShowFocusSetForm() {
        $screen = [FocusSetFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowFocusClear() {
        $screen = [FocusClearScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowFocusStatus() {
        $screen = [FocusStatusScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Dependencies navigation helpers
    [void] ShowDepAddForm() {
        $screen = [DepAddFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowDepRemoveForm() {
        $screen = [DepRemoveFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowDepShowForm() {
        $screen = [DepShowFormScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Timers & Misc navigation helpers
    [void] ShowTimerStart() {
        $screen = [TimerStartScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTimerStop() {
        $screen = [TimerStopScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowTimerStatus() {
        $screen = [TimerStatusScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowUndoView() {
        $screen = [UndoViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowRedoView() {
        $screen = [RedoViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowHelpView() {
        $screen = [HelpViewScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] ShowBurndownChart() {
        $screen = [BurndownChartScreen]::new()
        $this.screenManager.Push($screen)
    }

    # Tools navigation helpers
    [void] ShowThemeScreen() {
        $screen = [ThemeScreen]::new()
        $this.screenManager.Push($screen)
    }

    [void] GoBack() {
        if ($this.screenManager) {
            $this.screenManager.Pop()
        }
    }


    [void] DrawTaskDetail() {
        $this.terminal.BeginFrame()
        try {
            $task = $this.selectedTask

            if (-not $task) {
                $this.terminal.WriteAtColor(4, 6, "Error: No task selected", [PmcVT100]::Red(), "")
                $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
                return
            }

            $title = " Task #$($task.id) "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 4
        $this.terminal.WriteAtColor(4, $y++, "Text: $($task.text)", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, $y++, "Status: $(if ($task.status) { $task.status } else { 'none' })", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, $y++, "Priority: $(if ($task.priority) { $task.priority } else { 'none' })", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, $y++, "Project: $(if ($task.project) { $task.project } else { 'none' })", [PmcVT100]::Yellow(), "")

        if ($task.PSObject.Properties['due'] -and $task.due) {
            $dueDisplay = $task.due
            $dueDate = Get-ConsoleUIDateOrNull $task.due
            if ($dueDate) {
                $today = Get-Date
                $daysUntil = ($dueDate.Date - $today.Date).Days

                if ($task.status -ne 'completed') {
                    if ($daysUntil -lt 0) {
                        $this.terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (OVERDUE by $([Math]::Abs($daysUntil)) days)", [PmcVT100]::Red(), "")
                        $y++
                    } elseif ($daysUntil -eq 0) {
                        $this.terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (TODAY)", [PmcVT100]::Yellow(), "")
                        $y++
                    } elseif ($daysUntil -eq 1) {
                        $this.terminal.WriteAtColor(4, $y, "Due: ", [PmcVT100]::Yellow(), "")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (tomorrow)", [PmcVT100]::Cyan(), "")
                        $y++
                    } else {
                        $this.terminal.WriteAtColor(4, $y++, "Due: $dueDisplay (in $daysUntil days)", [PmcVT100]::Yellow(), "")
                    }
                } else {
                    $this.terminal.WriteAtColor(4, $y++, "Due: $dueDisplay", [PmcVT100]::Yellow(), "")
                }
            } else {
                $this.terminal.WriteAtColor(4, $y++, "Due: $dueDisplay", [PmcVT100]::Yellow(), "")
            }
        }

        if ($task.PSObject.Properties['created'] -and $task.created) { $this.terminal.WriteAtColor(4, $y++, "Created: $($task.created)", [PmcVT100]::Yellow(), "") }
        if ($task.PSObject.Properties['modified'] -and $task.modified) { $this.terminal.WriteAtColor(4, $y++, "Modified: $($task.modified)", [PmcVT100]::Yellow(), "") }
        if ($task.PSObject.Properties['completed'] -and $task.completed -and ($task.status -eq 'completed' -or $task.status -eq 'done')) {
            $this.terminal.WriteAtColor(4, $y++, "Completed: $($task.completed)", [PmcVT100]::Green(), "")
        }

        # Display time logs if they exist
        try {
            $data = Get-PmcAllData
            if ($data.timelogs) {
                $taskLogs = @($data.timelogs | Where-Object { $_.taskId -eq $task.id -or $_.task -eq $task.id })
                if ($taskLogs.Count -gt 0) {
                    $totalMinutes = ($taskLogs | ForEach-Object { if ($_.minutes) { $_.minutes } else { 0 } } | Measure-Object -Sum).Sum
                    $hours = [Math]::Floor($totalMinutes / 60)
                    $mins = $totalMinutes % 60
                    $y++
                    $this.terminal.WriteAtColor(4, $y++, "Time Logged: ${hours}h ${mins}m ($($taskLogs.Count) entries)", [PmcVT100]::Yellow(), "")
                }
            }
        } catch {}

        # Display subtasks if they exist
        if ($task.PSObject.Properties['subtasks'] -and $task.subtasks -and $task.subtasks.Count -gt 0) {
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Subtasks:", [PmcVT100]::Yellow(), "")
            foreach ($subtask in $task.subtasks) {
                $subtaskText = if ($subtask -is [string]) {
                    $subtask
                } elseif ($subtask.PSObject.Properties['text'] -and $subtask.text) {
                    $subtask.text
                } else {
                    $subtask.ToString()
                }
                $isCompleted = $subtask.PSObject.Properties['completed'] -and $subtask.completed
                $completed = if ($isCompleted) { "X" } else { "o" }
                $color = if ($isCompleted) { [PmcVT100]::Green() } else { [PmcVT100]::White() }
                $this.terminal.WriteAtColor(6, $y++, "$completed $subtaskText", $color, "")
            }
        }

        # Display notes if they exist
        if ($task.PSObject.Properties['notes'] -and $task.notes -and $task.notes.Count -gt 0) {
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Notes:", [PmcVT100]::Yellow(), "")
            foreach ($note in $task.notes) {
                $noteText = if ($note.PSObject.Properties['text'] -and $note.text) { $note.text } elseif ($note -is [string]) { $note } else { $note.ToString() }
                $noteDate = if ($note.PSObject.Properties['date'] -and $note.date) { $note.date } else { "" }
                if ($noteDate) {
                    $this.terminal.WriteAtColor(6, $y++, "• [$noteDate] $noteText", [PmcVT100]::Cyan(), "")
                } else {
                    $this.terminal.WriteAtColor(6, $y++, "• $noteText", [PmcVT100]::Cyan(), "")
                }
            }
        }

            $this.terminal.DrawFooter("↑↓:Nav | E:Edit | A:Add Subtask | J:Project | T:Due | D:Done | P:Priority | Del:Delete | Esc:Back")
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error displaying task detail: $_", [PmcVT100]::Red(), "")
            $this.terminal.WriteAtColor(4, 8, "Stack: $($_.ScriptStackTrace)", [PmcVT100]::Gray(), "")
            $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        }
        $this.terminal.EndFrame()
    }

    [void] HandleTaskDetailView() {
        $this.DrawTaskDetail()
        $key = [Console]::ReadKey($true)
        # Global menus
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            if ($globalAction -eq 'app:exit') { $this.running = $false; return }
            $this.ProcessMenuAction($globalAction)
            return
        }

        switch ($key.Key) {
            'E' {
                $this.previousView = 'taskdetail'
                $this.currentView = 'taskedit'
            }
            'A' {
                # Add subtask to the currently selected task
                $this.previousView = 'taskdetail'
                $this.currentView = 'subtaskadd'
            }
            'J' {
                $this.previousView = 'taskdetail'
                $this.currentView = 'projectselect'
            }
            'T' {
                $this.previousView = 'taskdetail'
                $this.currentView = 'duedateedit'
            }
            'D' {
                $this.selectedTask.status = 'completed'
                try { $this.selectedTask.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } catch {}
                try {
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed task $($this.selectedTask.id)"
                    $this.LoadTasks()
                    $this.GoBackOr('tasklist')
                } catch {}
            }
            'P' {
                $priorities = @('high', 'medium', 'low', 'none')
                $currentVal = if ($this.selectedTask.priority) { $this.selectedTask.priority } else { 'none' }
                $currentIdx = [Array]::IndexOf(@($priorities), $currentVal)
                if ($currentIdx -lt 0) { $currentIdx = 0 }
                $newIdx = ($currentIdx + 1) % $priorities.Count
                $this.selectedTask.priority = if ($priorities[$newIdx] -eq 'none') { $null } else { $priorities[$newIdx] }
                try {
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Changed priority for task $($this.selectedTask.id)"
                    $this.LoadTasks()

                } catch {}
            }
            'X' {
                try {
                    $taskId = $this.selectedTask.id
                    $data = Get-PmcAllData
                    $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                    Save-PmcData -Data $data -Action "Deleted task $taskId"
                    $this.LoadTasks()
                    $this.GoBackOr('tasklist')
                    if ($this.selectedTaskIndex -ge $this.tasks.Count) {
                        $this.selectedTaskIndex = [Math]::Max(0, $this.tasks.Count - 1)
                    }

                } catch {}
            }
            'Escape' { $this.GoBackOr('tasklist') }
        }
    }

    [void] DrawAddSubtaskForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Subtask "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Parent Task: #$($this.selectedTask.id) - $($this.selectedTask.text)", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Subtask text:", [PmcVT100]::Cyan(), "")
        $this.terminal.DrawFooter("Tab:Navigate  Enter:Save  Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleAddSubtaskForm() {
        if (-not $this.selectedTask) { $this.GoBackOr('tasklist'); return }
        $this.DrawAddSubtaskForm()

        # Simple one-field input using the widget form for consistency
        $fields = @(@{ Name='text'; Label='Subtask text'; Required=$true; Type='text' })
        $res = Show-InputForm -Title "Add Subtask" -Fields $fields
        if ($null -eq $res) { $this.GoBackOr('taskdetail'); return }
        $text = [string]$res['text']
        if ([string]::IsNullOrWhiteSpace($text)) { $this.GoBackOr('taskdetail'); return }

        try {
            $data = Get-PmcAllData
            $task = @($data.tasks | Where-Object { $_.id -eq $this.selectedTask.id })[0]
            if (-not $task) { Show-InfoMessage -Message "Task not found" -Title "Error" -Color "Red"; $this.GoBackOr('tasklist'); return }
            if (-not $task.PSObject.Properties['subtasks']) {
                $task | Add-Member -MemberType NoteProperty -Name 'subtasks' -Value @() -Force
            }
            $sub = [pscustomobject]@{ text = $text.Trim(); completed = $false; created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
            $task.subtasks += $sub
            Save-PmcData -Data $data -Action ("Added subtask to task #{0}" -f $task.id)
            # Keep selection and show updated detail
            $this.LoadTasks($data)
            # Re-select the same task by id
            for ($i=0; $i -lt $this.tasks.Count; $i++) { if ($this.tasks[$i].id -eq $task.id) { $this.selectedTaskIndex = $i; break } }
            $this.selectedTask = @($this.tasks | Where-Object { $_.id -eq $task.id })[0]
            $this.previousView = 'tasklist'  # ensure Esc from detail goes back to list if needed
            $this.currentView = 'taskdetail'
            $this.RefreshCurrentView()
        } catch {
            Show-InfoMessage -Message "Failed to add subtask: $_" -Title "SAVE ERROR" -Color "Red"
            $this.GoBackOr('taskdetail')
        }
    }

    [void] DrawTaskAddForm() {
        $this.terminal.BeginFrame()

        $title = " Add New Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 5, "Task text:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 6, "> ", [PmcVT100]::Yellow(), "")

        $this.terminal.WriteAtColor(4, 8, "Quick Add Syntax:", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(6, 9, "@project  - Set project (e.g., @work)", [PmcVT100]::Gray(), "")
        $this.terminal.WriteAtColor(6, 10, "#priority - Set priority: #high #medium #low or #h #m #l", [PmcVT100]::Gray(), "")
        $this.terminal.WriteAtColor(6, 11, "!due      - Set due: !today !tomorrow !+7 (days)", [PmcVT100]::Gray(), "")
        $this.terminal.WriteAtColor(4, 13, "Example: Fix bug @myapp #high !tomorrow", [PmcVT100]::Cyan(), "")

        $this.terminal.DrawFooter("Type task with quick add syntax, Enter to save, Esc to cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTaskAddForm() {
        # Get available projects
        $data = Get-PmcAllData
        $projectList = @('none', 'inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        # Use new widget-based approach with separate fields
        $input = Show-InputForm -Title "Add New Task" -Fields @(
            @{Name='text'; Label='Task description'; Required=$true; Type='text'}
            @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList}
            @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low')}
            @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'}
        )

        if ($null -eq $input) {
            $this.GoBackOr('tasklist')
            return
        }

        $taskText = $input['text']
        if ($taskText.Length -lt 3) {
            Show-InfoMessage -Message "Task description must be at least 3 characters" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
            return
        }

        try {
            $data = Get-PmcAllData
            $newId = if ($data.tasks.Count -gt 0) {
                ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
            } else { 1 }

            # Get values from form fields
            $project = if ([string]::IsNullOrWhiteSpace($input['project']) -or $input['project'] -eq 'none') { $null } elseif ($input['project'] -eq 'inbox') { 'inbox' } else { $input['project'].Trim() }

            $priority = 'medium'
            if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
                $priInput = $input['priority'].Trim().ToLower()
                $priority = switch -Regex ($priInput) {
                    '^h(igh)?$' { 'high' }
                    '^l(ow)?$' { 'low' }
                    '^m(edium)?$' { 'medium' }
                    default { 'medium' }
                }
            }

            $due = $null
            if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                $dueInput = $input['due'].Trim().ToLower()
                $due = switch ($dueInput) {
                    'today' { (Get-Date).ToString('yyyy-MM-dd') }
                    'tomorrow' { (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
                    default {
                        # Try to parse as date safely
                        $parsedDate = Get-ConsoleUIDateOrNull $dueInput
                        if ($parsedDate) { $parsedDate.ToString('yyyy-MM-dd') } else { $null }
                    }
                }
            }

            $newTask = [PSCustomObject]@{
                id = $newId
                text = $taskText.Trim()
                status = 'active'
                priority = $priority
                project = $project
                due = $due
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            $data.tasks += $newTask

            # CRITICAL: Save with error handling that BLOCKS
            Save-PmcData -Data $data -Action "Added task $newId"

            # Only continue if save succeeded
            $this.LoadTasks()
            Show-InfoMessage -Message "Task #$newId added successfully: $($taskText.Trim())" -Title "Success" -Color "Green"

        } catch {
            # CRITICAL: Show error and BLOCK until user acknowledges
            Show-InfoMessage -Message "FAILED TO SAVE TASK: $_`n`nYour task was NOT saved. Please try again." -Title "SAVE ERROR" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawProjectFilter() {
        $this.terminal.BeginFrame()

        $title = " Filter by Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @(
                $data.projects |
                    ForEach-Object {
                        if ($_ -is [string]) { $_ }
                        elseif ($_.PSObject.Properties['name']) { $_.name }
                    } |
                    Where-Object { $_ }
            )
            $projectList = @('All') + ($projectList | Sort-Object -Unique)

            $y = 5
            for ($i = 0; $i -lt $projectList.Count; $i++) {
                $project = $projectList[$i]
                $isSelected = if ($project -eq 'All') {
                    -not $this.filterProject
                } else {
                    $this.filterProject -eq $project
                }

                if ($isSelected) {
                    $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "  $project")
                }
            }
        } catch {}

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Back")
        $this.terminal.EndFrame()
    }

    [void] HandleProjectFilter() {
        $this.DrawProjectFilter()
        try {
            $data = Get-PmcAllData
            $projectList = @(
                $data.projects |
                    ForEach-Object {
                        if ($_ -is [string]) { $_ }
                        elseif ($_.PSObject.Properties['name']) { $_.name }
                    } |
                    Where-Object { $_ }
            )
            $projectList = @('All') + ($projectList | Sort-Object -Unique)
            $selectedIdx = 0

            if ($this.filterProject) {
                $selectedIdx = [Array]::IndexOf(@($projectList), $this.filterProject)
                if ($selectedIdx -lt 0) { $selectedIdx = 0 }
            }

            while ($true) {
                $this.terminal.BeginFrame()
                $title = " Filter by Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 5
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $project = $projectList[$i]
                    if ($i -eq $selectedIdx) {
                        $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                    } else {
                        $this.terminal.WriteAt(4, $y + $i, "  $project")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Back")
                $this.terminal.EndFrame()

                $key = [Console]::ReadKey($true)

                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $selected = $projectList[$selectedIdx]
                        if ($selected -eq 'All') {
                            $this.filterProject = ''
                        } else {
                            $this.filterProject = $selected
                        }
                        $this.LoadTasks()
                        $this.GoBackOr('tasklist')
                        $this.selectedTaskIndex = 0
                        $this.scrollOffset = 0

                        break
                    }
                    'Escape' {
                        $this.GoBackOr('tasklist')
                        break
                    }
                }
            }
        } catch {
            $this.GoBackOr('tasklist')

        }
    }

    [void] DrawSearchForm() {
        $this.terminal.BeginFrame()

        $title = " Search Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 5, "Search for:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 6, "> ", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter("Type search term, Enter to search, Esc to cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleSearchForm() {
        $this.DrawSearchForm()
        $this.terminal.WriteAtColor(6, 6, "", [PmcVT100]::Yellow(), "")
        $searchInput = ""
        $cursorX = 6

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Enter') {
                $this.searchText = $searchInput.Trim()
                $this.LoadTasks()
                $this.GoBackOr('tasklist')
                $this.selectedTaskIndex = 0
                $this.scrollOffset = 0

                break
            } elseif ($key.Key -eq 'Escape') {
                $this.GoBackOr('tasklist')

                break
            } elseif ($key.Key -eq 'Backspace') {
                if ($searchInput.Length -gt 0) {
                    $searchInput = $searchInput.Substring(0, $searchInput.Length - 1)
                    $cursorX = 6 + $searchInput.Length
                    $this.terminal.FillArea(6, 6, $this.terminal.Width - 7, 1, ' ')
                    $this.terminal.WriteAtColor(6, 6, $searchInput, [PmcVT100]::Yellow(), "")
                }
            } else {
                $char = $key.KeyChar
                if ($char -and $char -ne "`0") {
                    $searchInput += $char
                    $this.terminal.WriteAtColor($cursorX, 6, $char.ToString(), [PmcVT100]::Yellow(), "")
                    $cursorX++
                }
            }
        }
    }


    [void] HandleHelpView() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'help') {
            $this.DrawHelpView()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'help') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('main')
    }

    [void] DrawProjectSelect() {
        $this.terminal.BeginFrame()

        $title = " Change Task Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @(
                $data.projects |
                    ForEach-Object {
                        if ($_ -is [string]) { $_ }
                        elseif ($_.PSObject.Properties['name']) { $_.name }
                    } |
                    Where-Object { $_ }
            )

            $y = 5
            for ($i = 0; $i -lt $projectList.Count; $i++) {
                $project = $projectList[$i]
                $isSelected = ($this.selectedTask.project -eq $project)

                if ($isSelected) {
                    $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "  $project")
                }
            }
        } catch {}

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleProjectSelect() {
        try {
            $data = Get-PmcAllData
            $projectList = @(
                $data.projects |
                    ForEach-Object {
                        if ($_ -is [string]) { $_ }
                        elseif ($_.PSObject.Properties['name']) { $_.name }
                    } |
                    Where-Object { $_ }
            )
            $selectedIdx = [Array]::IndexOf(@($projectList), $this.selectedTask.project)
            if ($selectedIdx -lt 0) { $selectedIdx = 0 }

            while ($true) {
                $this.terminal.BeginFrame()
                $title = " Change Task Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 5
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $project = $projectList[$i]
                    if ($i -eq $selectedIdx) {
                        $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                    } else {
                        $this.terminal.WriteAt(4, $y + $i, "  $project")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
                $this.terminal.EndFrame()

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $selected = $projectList[$selectedIdx]
                        try {
                            $data = Get-PmcAllData
                            $task = $data.tasks | Where-Object { $_.id -eq $this.selectedTask.id } | Select-Object -First 1
                            if ($task) {
                                $task.project = $selected
                                Save-PmcData -Data $data -Action "Changed project for task $($task.id) to $selected"
                                $this.LoadTasks()
                                $this.selectedTask = $task
                                $this.currentView = 'taskdetail'

                            }
                        } catch {}
                        break
                    }
                    'Escape' {
                        $this.currentView = 'taskdetail'

                        break
                    }
                }
            }
        } catch {
            $this.currentView = 'taskdetail'

        }
    }

    [void] DrawDueDateEdit() {
        $this.terminal.BeginFrame()

        $title = " Set Due Date "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Current due date: $(if ($this.selectedTask.due) { $this.selectedTask.due } else { 'none' })")
        $this.terminal.WriteAt(4, 7, "Enter new due date (YYYY-MM-DD):")
        $this.terminal.WriteAt(4, 8, "> ")
        $this.terminal.WriteAt(4, 10, "Or press:")
        $this.terminal.WriteAt(6, 11, "1 - Today")
        $this.terminal.WriteAt(6, 12, "2 - Tomorrow")
        $this.terminal.WriteAt(6, 13, "3 - Next week (+7 days)")
        $this.terminal.WriteAt(6, 14, "C - Clear due date")

        $this.terminal.DrawFooter("Type date or shortcut, Enter to save, Esc to cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleDueDateEdit() {
        $this.terminal.WriteAt(6, 8, "")
        $dateInput = ""
        $cursorX = 6

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Enter') {
                try {
                    $newDate = $null
                    if ($dateInput.Trim()) {
                        # Try to parse as date (supports multiple formats)
                        $newDate = ConvertTo-PmcDate -DateString $dateInput.Trim()
                        if ($null -eq $newDate) {
                            # Invalid format
                            $this.terminal.WriteAtColor(4, 16, "Invalid date! Try: yyyymmdd, mmdd, +3, today, etc.", [PmcVT100]::Red(), "")
                            $this.DrawDueDateEdit()
                            $dateInput = ""
                            $cursorX = 6
                            continue
                        }
                    }

                    $data = Get-PmcAllData
                    $task = $data.tasks | Where-Object { $_.id -eq $this.selectedTask.id } | Select-Object -First 1
                    if ($task) {
                        $task.due = $newDate
                        Save-PmcData -Data $data -Action "Set due date for task $($task.id)"
                        $this.LoadTasks()
                        $this.selectedTask = $task
                        $this.currentView = 'taskdetail'

                    }
                } catch {
                    $this.terminal.WriteAtColor(4, 16, "Error: $_", [PmcVT100]::Red(), "")
                }
                break
            } elseif ($key.Key -eq 'Escape') {
                $this.currentView = 'taskdetail'

                break
            } elseif ($key.KeyChar -eq '1') {
                $dateInput = (Get-Date).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq '2') {
                $dateInput = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq '3') {
                $dateInput = (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq 'c' -or $key.KeyChar -eq 'C') {
                $dateInput = ""
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $cursorX = 6
            } elseif ($key.Key -eq 'Backspace') {
                if ($dateInput.Length -gt 0) {
                    $dateInput = $dateInput.Substring(0, $dateInput.Length - 1)
                    $cursorX = 6 + $dateInput.Length
                    $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                    $this.terminal.WriteAt(6, 8, $dateInput)
                }
            } else {
                $char = $key.KeyChar
                if ($char -and $char -ne "`0" -and ($char -match '[0-9\-]')) {
                    $dateInput += $char
                    $this.terminal.WriteAt($cursorX, 8, $char.ToString())
                    $cursorX++
                }
            }
        }
    }

    [void] DrawMultiSelectMode() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $selectedCount = ($this.multiSelect.Values | Where-Object { $_ -eq $true }).Count
        $title = " Multi-Select Mode ($selectedCount selected) "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        $headerY = 5
        $this.terminal.WriteAt(2, $headerY, "Sel")
        $this.terminal.WriteAt(8, $headerY, "ID")
        $this.terminal.WriteAt(14, $headerY, "Status")
        $this.terminal.WriteAt(24, $headerY, "Pri")
        $this.terminal.WriteAt(30, $headerY, "Task")
        $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

        $startY = $headerY + 2
        $maxRows = $this.terminal.Height - $startY - 3

        for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.tasks.Count; $i++) {
            $taskIdx = $i + $this.scrollOffset
            $task = $this.tasks[$taskIdx]
            $y = $startY + $i
            $isSelected = ($taskIdx -eq $this.selectedTaskIndex)
            $isMarked = $this.multiSelect[$task.id]

            if ($isSelected) {
                $this.terminal.FillArea(0, $y, $this.terminal.Width, 1, ' ')
                $this.terminal.WriteAtColor(0, $y, ">", [PmcVT100]::Yellow(), "")
            }

            $marker = if ($isMarked) { '[X]' } else { '[ ]' }
            $markerColor = if ($isMarked) { [PmcVT100]::Green() } else { "" }
            if ($markerColor) {
                $this.terminal.WriteAtColor(2, $y, $marker, $markerColor, "")
            } else {
                $this.terminal.WriteAt(2, $y, $marker)
            }

            $statusIcon = if ($task.status -eq 'completed') { 'X' } else { 'o' }
            $this.terminal.WriteAt(8, $y, $task.id.ToString())
            $this.terminal.WriteAt(14, $y, $statusIcon)

            $priVal = if ($task.priority) { $task.priority } else { 'none' }
            $priChar = $priVal.Substring(0,1).ToUpper()
            $this.terminal.WriteAt(24, $y, $priChar)

            $text = if ($task.text) { $task.text } else { "" }
            if ($text.Length -gt 45) { $text = $text.Substring(0, 42) + "..." }
            $this.terminal.WriteAt(30, $y, $text)
        }

        $this.terminal.DrawFooter("Space:Toggle | A:All | N:None | C:Complete | X:Delete | P:Priority | M:Move | Esc:Exit")
        $this.terminal.EndFrame()
    }

    [void] HandleMultiSelectMode() {
        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow' {
                    if ($this.selectedTaskIndex -gt 0) {
                        $this.selectedTaskIndex--
                        if ($this.selectedTaskIndex -lt $this.scrollOffset) {
                            $this.scrollOffset = $this.selectedTaskIndex
                        }
                    }
                    $this.DrawMultiSelectMode()
                }
                'DownArrow' {
                    if ($this.selectedTaskIndex -lt $this.tasks.Count - 1) {
                        $this.selectedTaskIndex++
                        $maxRows = $this.terminal.Height - 10
                        if ($this.selectedTaskIndex -ge $this.scrollOffset + $maxRows) {
                            $this.scrollOffset = $this.selectedTaskIndex - $maxRows + 1
                        }
                    }
                    $this.DrawMultiSelectMode()
                }
                'Spacebar' {
                    if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                        $task = $this.tasks[$this.selectedTaskIndex]
                        $this.multiSelect[$task.id] = -not $this.multiSelect[$task.id]
                        $this.DrawMultiSelectMode()
                    }
                }
                'A' {
                    foreach ($task in $this.tasks) {
                        $this.multiSelect[$task.id] = $true
                    }
                    $this.DrawMultiSelectMode()
                }
                'N' {
                    $this.multiSelect.Clear()
                    $this.DrawMultiSelectMode()
                }
                'C' {
                    # Complete selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        try {
                            $count = $selectedIds.Count
                            $data = Get-PmcAllData
                            foreach ($id in $selectedIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.status = 'completed'
                                    $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                                }
                            }
                            Save-PmcData -Data $data -Action "Completed $count tasks"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.GoBackOr('tasklist')
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Completed $count tasks")
                        } catch {}
                    }
                    break
                }
                'X' {
                    # Delete selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        try {
                            $count = $selectedIds.Count
                            $data = Get-PmcAllData
                            $data.tasks = @($data.tasks | Where-Object { $selectedIds -notcontains $_.id })
                            Save-PmcData -Data $data -Action "Deleted $count tasks"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.GoBackOr('tasklist')
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Deleted $count tasks")
                        } catch {}
                    }
                    break
                }
                'P' {
                    # Set priority for selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        $this.currentView = 'multipriority'
                        $this.DrawMultiPrioritySelect($selectedIds)
                        $this.HandleMultiPrioritySelect($selectedIds)
                    }
                    break
                }
                'M' {
                    # Move selected tasks to project
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        $this.currentView = 'multiproject'
                        $this.DrawMultiProjectSelect($selectedIds)
                        $this.HandleMultiProjectSelect($selectedIds)
                    }
                    break
                }
                'Escape' {
                    $this.multiSelect.Clear()
                    $this.GoBackOr('tasklist')
                    $this.DrawTaskList()
                    break
                }
            }
        }
    }

    [void] DrawMultiPrioritySelect([array]$taskIds) {
        $this.terminal.Clear()

        $title = " Set Priority for $($taskIds.Count) tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $priorities = @('high', 'medium', 'low', 'none')
        $y = 5
        for ($i = 0; $i -lt $priorities.Count; $i++) {
            $pri = $priorities[$i]
            $color = switch ($pri) {
                'high' { [PmcVT100]::Red() }
                'medium' { [PmcVT100]::Yellow() }
                'low' { [PmcVT100]::Green() }
                default { "" }
            }
            if ($color) {
                $this.terminal.WriteAtColor(4, $y + $i, "  $pri", $color, "")
            } else {
                $this.terminal.WriteAt(4, $y + $i, "  $pri")
            }
        }

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
    }

    [void] HandleMultiPrioritySelect([array]$taskIds) {
        $priorities = @('high', 'medium', 'low', 'none')
        $selectedIdx = 1  # Default to medium

        while ($true) {
            $this.terminal.BeginFrame()
            $title = " Set Priority for $($taskIds.Count) tasks "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            $y = 5
            for ($i = 0; $i -lt $priorities.Count; $i++) {
                $pri = $priorities[$i]
                $prefix = if ($i -eq $selectedIdx) { "> " } else { "  " }
                $color = switch ($pri) {
                    'high' { [PmcVT100]::Red() }
                    'medium' { [PmcVT100]::Yellow() }
                    'low' { [PmcVT100]::Green() }
                    default { "" }
                }
                if ($color) {
                    $this.terminal.WriteAtColor(4, $y + $i, "$prefix$pri", $color, "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "$prefix$pri")
                }
            }

            $this.terminal.DrawFooter("↑↓:Navigate | Enter:Select | Esc:Cancel")
            $this.terminal.EndFrame()

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedIdx -gt 0) { $selectedIdx-- }
                }
                'DownArrow' {
                    if ($selectedIdx -lt $priorities.Count - 1) { $selectedIdx++ }
                }
                'Enter' {
                    $selectedPri = $priorities[$selectedIdx]
                    try {
                        $count = $taskIds.Count
                        $data = Get-PmcAllData
                        foreach ($id in $taskIds) {
                            $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                            if ($task) {
                                $task.priority = if ($selectedPri -eq 'none') { $null } else { $selectedPri }
                            }
                        }
                        Save-PmcData -Data $data -Action "Set priority to $selectedPri for $count tasks"
                        $this.multiSelect.Clear()
                        $this.LoadTasks()
                        $this.GoBackOr('tasklist')
                        $this.DrawTaskList()
                        $this.ShowSuccessMessage("Set priority to $selectedPri for $count tasks")
                    } catch {}
                    break
                }
                'Escape' {
                    $this.currentView = 'multiselect'
                    $this.DrawMultiSelectMode()
                    $this.HandleMultiSelectMode()
                    break
                }
            }
        }
    }

    [void] DrawMultiProjectSelect([array]$taskIds) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Move $($taskIds.Count) tasks to Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ })

            if ($projectList.Count -eq 0) {
                $this.terminal.WriteAtColor(4, 6, "No projects available", [PmcVT100]::Yellow(), "")
            } else {
                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Select Project:", [PmcVT100]::Cyan(), "")
                $y++
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $this.terminal.WriteAt(4, $y++, "  $($projectList[$i])")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading projects: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
    }

    [void] HandleMultiProjectSelect([array]$taskIds) {
        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ })

            if ($projectList.Count -eq 0) {
                [Console]::ReadKey($true) | Out-Null
                $this.currentView = 'multiselect'
                $this.DrawMultiSelectMode()
                $this.HandleMultiSelectMode()
                return
            }

            $selectedIdx = 0

            while ($true) {
                $this.terminal.BeginFrame()
                $this.menuSystem.DrawMenuBar()

                $title = " Move $($taskIds.Count) tasks to Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Select Project:", [PmcVT100]::Cyan(), "")
                $y++
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $prefix = if ($i -eq $selectedIdx) { "> " } else { "  " }
                    $color = if ($i -eq $selectedIdx) { [PmcVT100]::Yellow() } else { "" }
                    if ($color) {
                        $this.terminal.WriteAtColor(4, $y++, "$prefix$($projectList[$i])", $color, "")
                    } else {
                        $this.terminal.WriteAt(4, $y++, "$prefix$($projectList[$i])")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
                $this.terminal.EndFrame()

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $targetProject = $projectList[$selectedIdx]
                        try {
                            $count = $taskIds.Count
                            $data = Get-PmcAllData
                            foreach ($id in $taskIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.project = $targetProject
                                }
                            }
                            Save-PmcData -Data $data -Action "Moved $count tasks to project $targetProject"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.GoBackOr('tasklist')
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Moved $count tasks to $targetProject")
                        } catch {}
                        break
                    }
                    'Escape' {
                        $this.currentView = 'multiselect'
                        $this.DrawMultiSelectMode()
                        $this.HandleMultiSelectMode()
                        break
                    }
                }
            }
        } catch {
            [Console]::ReadKey($true) | Out-Null
            $this.currentView = 'multiselect'
            $this.DrawMultiSelectMode()
            $this.HandleMultiSelectMode()
        }
    }





    # Legacy single-shot special view handler removed. Persistent handler is used for all these views.

    [void] DrawBackupView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Backup Data "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $backups = @()
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $backups += [PSCustomObject]@{
                        Number = $i
                        File = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                    }
                }
            }

            if ($backups.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "Existing Backups:", [PmcVT100]::Cyan(), "")
                $y = 8
                foreach ($backup in $backups) {
                    $sizeKB = [math]::Round($backup.Size / 1KB, 2)
                    $line = "  .bak$($backup.Number)  -  $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB"
                    $this.terminal.WriteAt(4, $y++, $line)
                }

                $y++
                $this.terminal.WriteAtColor(4, $y, "Main data file:", [PmcVT100]::Cyan(), "")
                $y++
                if (Test-Path $file) {
                    $mainInfo = Get-Item $file
                    $sizeKB = [math]::Round($mainInfo.Length / 1KB, 2)
                    $this.terminal.WriteAt(4, $y++, "  $file")
                    $this.terminal.WriteAt(4, $y++, "  Modified: $($mainInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB")
                }

                $y += 2
                $this.terminal.WriteAtColor(4, $y++, "Press 'C' to create manual backup now", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, $y, "Backups are automatically created on every save (up to 9 retained)")
            } else {
                $this.terminal.WriteAtColor(4, 8, "No backups found.", [PmcVT100]::Yellow(), "")
                $y = 10
                $this.terminal.WriteAt(4, $y++, "Backups are automatically created when data is saved.")
                $this.terminal.WriteAt(4, $y++, "Up to 9 backups are retained (.bak1 through .bak9)")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'C' to create manual backup now", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error loading backup info: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("C:Create Backup | Esc:Back")
        $this.terminal.EndFrame()
    }

    [void] HandleBackupView() {
        $this.DrawBackupView()
        $key = [Console]::ReadKey($true)

        if ($key.Key -eq 'C') {
            try {
                $file = Get-PmcTaskFilePath
                if (Test-Path $file) {
                    # Rotate backups
                    for ($i = 8; $i -ge 1; $i--) {
                        $src = "$file.bak$i"
                        $dst = "$file.bak$($i+1)"
                        if (Test-Path $src) {
                            Move-Item -Force $src $dst
                        }
                    }
                    Copy-Item $file "$file.bak1" -Force

                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Backup created successfully", [PmcVT100]::Green(), "")
                    # Redraw to show updated backup list
                    $this.HandleBackupView()
                    return
                }
            } catch {
                $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Error creating backup: $_", [PmcVT100]::Red(), "")
            }
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawTimerStatus() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Timer Status "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is RUNNING", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAt(4, $y++, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, $y++, "Elapsed: $($status.Elapsed)h")
                if ($status.Task) {
                    $y++
                    $this.terminal.WriteAt(4, $y++, "Task: $($status.Task)")
                }
                if ($status.Project) {
                    $this.terminal.WriteAt(4, $y++, "Project: $($status.Project)")
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "Timer is not running", [PmcVT100]::Yellow(), "")
                if ($status.LastElapsed) {
                    $this.terminal.WriteAt(4, 8, "Last session: $($status.LastElapsed)h")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] DrawTimerStart() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Start Timer "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is already running!", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(4, 8, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, 9, "Elapsed: $($status.Elapsed)h")
            } else {
                $this.terminal.WriteAtColor(4, 6, "Press 'S' to start the timer", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, 8, "This will track your work time for logging.")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("S:Start | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawTimerStop() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Stop Timer "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgRed(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is running", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, 8, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, 9, "Elapsed: $($status.Elapsed)h")
                $y = 11
                $this.terminal.WriteAtColor(4, $y, "Press 'S' to stop and log this time", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "Timer is not running", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(4, 8, "There is nothing to stop.")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("S:Stop | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawUndoView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Undo Last Change "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcUndoStatus
            if ($status.UndoAvailable) {
                $this.terminal.WriteAtColor(4, 6, "Undo stack has $($status.UndoCount) change(s) available", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAt(4, $y++, "Last action: $($status.LastAction)")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'U' to undo the last change", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No changes available to undo", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("U:Undo | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawRedoView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Redo Last Undone Change "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcUndoStatus
            if ($status.RedoAvailable) {
                $this.terminal.WriteAtColor(4, 6, "Redo stack has $($status.RedoCount) change(s) available", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAtColor(4, $y, "Press 'R' to redo the last undone change", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No changes available to redo", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("R:Redo | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawFocusClearView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Clear Focus "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Clear the current focus selection.", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAtColor(4, $y, "Press 'C' to clear focus.", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter("C:Clear  F10/Alt:Menus  Esc:Back")
        $this.terminal.EndFrame()
    }

    [void] DrawClearBackupsView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Clear Backup Files "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $backupCount = 0
            $totalSize = 0

            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $backupCount++
                    $totalSize += (Get-Item $bakFile).Length
                }
            }

            $this.terminal.WriteAtColor(4, 6, "Automatic backups (.bak1 - .bak9):", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAt(4, 8, "  Count: $backupCount files")
            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            $this.terminal.WriteAt(4, 9, "  Total size: $sizeMB MB")

            $y = 11
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json")
                $manualCount = $manualBackups.Count
                $manualSize = ($manualBackups | Measure-Object -Property Length -Sum).Sum
                $manualSizeMB = [math]::Round($manualSize / 1MB, 2)

                $this.terminal.WriteAtColor(4, $y++, "Manual backups (backups directory):", [PmcVT100]::Cyan(), "")
                $y++
                $this.terminal.WriteAt(4, $y++, "  Count: $manualCount files")
                $this.terminal.WriteAt(4, $y++, "  Total size: $manualSizeMB MB")
            }

            $y += 2
            if ($backupCount -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "Press 'A' to clear automatic backups (.bak files)", [PmcVT100]::Yellow(), "")
            }
            if (Test-Path $backupDir) {
                $this.terminal.WriteAtColor(4, $y++, "Press 'M' to clear manual backups (backups directory)", [PmcVT100]::Yellow(), "")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'B' to clear BOTH", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterBackupChoice)
        $this.terminal.EndFrame()
    }

    [void] HandleClearBackupsView() {
        $this.DrawClearBackupsView()
        $key = [Console]::ReadKey($true)

        if ($key.Key -eq 'A') {
            $confirmed = Show-ConfirmDialog -Message "Clear automatic backups (.bak files)?" -Title "Confirm"
            if ($confirmed) {
                try {
                    $file = Get-PmcTaskFilePath
                    $count = 0
                    for ($i = 1; $i -le 9; $i++) {
                        $bakFile = "$file.bak$i"
                        if (Test-Path $bakFile) {
                            Remove-Item $bakFile -Force
                            $count++
                        }
                    }
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Cleared $count automatic backup files", [PmcVT100]::Green(), "")
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Error: $_", [PmcVT100]::Red(), "")
                }
            }
            $this.GoBackOr('tasklist')
        } elseif ($key.Key -eq 'M') {
            $confirmed = Show-ConfirmDialog -Message "Clear manual backups (backups/*.json)?" -Title "Confirm"
            if ($confirmed) {
                try {
                    $backupDir = Join-Path (Get-PmcRootPath) "backups"
                    if (Test-Path $backupDir) {
                        $files = Get-ChildItem $backupDir -Filter "*.json"
                        $count = $files.Count
                        Remove-Item "$backupDir/*.json" -Force
                        $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Cleared $count manual backup files", [PmcVT100]::Green(), "")
                    }
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Error: $_", [PmcVT100]::Red(), "")
                }
            }
            $this.GoBackOr('tasklist')
        } elseif ($key.Key -eq 'B') {
            $confirmed = Show-ConfirmDialog -Message "Clear ALL backups? (auto + manual)" -Title "Confirm"
            if ($confirmed) {
                try {
                    $file = Get-PmcTaskFilePath
                    $autoCount = 0
                    for ($i = 1; $i -le 9; $i++) {
                        $bakFile = "$file.bak$i"
                        if (Test-Path $bakFile) {
                            Remove-Item $bakFile -Force
                            $autoCount++
                        }
                    }
                    $manualCount = 0
                    $backupDir = Join-Path (Get-PmcRootPath) "backups"
                    if (Test-Path $backupDir) {
                        $files = Get-ChildItem $backupDir -Filter "*.json"
                        $manualCount = $files.Count
                        Remove-Item "$backupDir/*.json" -Force
                    }
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Cleared $autoCount auto + $manualCount manual backups", [PmcVT100]::Green(), "")
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Error: $_", [PmcVT100]::Red(), "")
                }
            }
            $this.GoBackOr('tasklist')
        } elseif ($key.Key -eq 'Escape') {
            $this.GoBackOr('tasklist')
        } else {
            $this.currentView = 'fileclearbackups'  # Refresh
        }
    }

    [void] DrawPlaceholder([string]$featureName) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " $featureName "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $message = "This feature is not yet implemented in the TUI."
        $messageX = ($this.terminal.Width - $message.Length) / 2
        $this.terminal.WriteAtColor([int]$messageX, 8, $message, [PmcVT100]::Yellow(), "")

        $hint = "Use the PowerShell commands instead (Get-Command *Pmc*)"
        $hintX = ($this.terminal.Width - $hint.Length) / 2
        $this.terminal.WriteAt([int]$hintX, 10, $hint)

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
    }

    [void] DrawFocusSetForm() {
        $this.terminal.BeginFrame()

        $title = " Set Focus Context "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Project name:")
        $this.terminal.WriteAt(4, 6, "> ")

        try {
            $data = Get-PmcAllData
            $this.terminal.WriteAtColor(4, 8, "Available projects:", [PmcVT100]::Cyan(), "")
            $y = 9
            foreach ($proj in $data.projects) {
                $this.terminal.WriteAt(6, $y++, "• $($proj.name)")
            }
        } catch {}

        $this.terminal.DrawFooter("Type project name, Enter to set, Esc to cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleFocusSetForm() {
        # Get available projects
        $data = Get-PmcAllData
        $projectList = @('inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        # Get current context as default
        $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

        # Show selection list
        $selected = Show-SelectList -Title "Select Focus Context" -Options $projectList -DefaultValue $currentContext

        if ($selected) {
            try {
                if (-not $data.PSObject.Properties['currentContext']) {
                    $data | Add-Member -NotePropertyName currentContext -NotePropertyValue $selected -Force
                } else {
                    $data.currentContext = $selected
                }
                Save-PmcData -Data $data -Action "Set focus to $selected"
                Show-InfoMessage -Message "Focus set to: $selected" -Title "Success" -Color "Green"
            } catch {
                Show-InfoMessage -Message "Failed to set focus: $_" -Title "Error" -Color "Red"
            }
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawFocusStatus() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Focus Status "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

            $this.terminal.WriteAtColor(4, 6, "Current Focus:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(20, 6, $currentContext)

            if ($currentContext -and $currentContext -ne 'inbox') {
                $contextTasks = @($data.tasks | Where-Object {
                    $_.project -eq $currentContext -and $_.status -ne 'completed'
                })

                $this.terminal.WriteAtColor(4, 8, "Active Tasks:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 8, "$($contextTasks.Count)")

                $overdue = @($contextTasks | Where-Object {
                    if (-not $_.due) { return $false }
                    $d = Get-ConsoleUIDateOrNull $_.due
                    if ($d) { return ($d.Date -lt (Get-Date).Date) } else { return $false }
                })

                if ($overdue.Count -gt 0) {
                    $this.terminal.WriteAtColor(4, 9, "Overdue:", [PmcVT100]::Red(), "")
                    $this.terminal.WriteAt(18, 9, "$($overdue.Count)")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading focus status: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleFocusStatusView() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'focusstatus') {
            $this.DrawFocusStatus()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'focusstatus') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('main')
    }

    [void] DrawTimeAddForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "Task ID (optional):")
        $this.terminal.WriteAtColor(4, 10, "Minutes:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 12, "Description:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 14, "Date (YYYY-MM-DD, default today):")

        $this.terminal.DrawFooter("Enter fields | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTimeAddForm() {
        # Unified input form for adding time
        $allData = Get-PmcAllData
        $projectNames = @($allData.projects | ForEach-Object { $_.name } | Where-Object { $_ } | Sort-Object)
        $options = @('(generic time code)') + $projectNames
        $fields = @(
            @{Name='hours'; Label='Hours (e.g., 1, 1.5, 2.25)'; Required=$true; Type='text'}
            @{Name='project'; Label='Project or Code Mode'; Required=$true; Type='select'; Options=$options}
            @{Name='timeCode'; Label='Time Code (if generic)'; Required=$false; Type='text'}
            @{Name='date'; Label='Date (today/tomorrow/+N/-N/YYYYMMDD or empty for today)'; Required=$false; Type='text'}
            @{Name='description'; Label='Description'; Required=$false; Type='text'}
        )
        $res = Show-InputForm -Title "Add Time Entry" -Fields $fields
        if ($null -eq $res) { $this.previousView=''; $this.currentView='timelist'; $this.RefreshCurrentView(); return }

        # Validate hours
        $hoursStr = [string]$res['hours']
        $hours = 0.0; if (-not [double]::TryParse($hoursStr, [ref]$hours) -or $hours -le 0) {
            Show-InfoMessage -Message "Invalid hours. Use numbers like 1, 1.5, 2.25." -Title "Validation" -Color "Red"
            $this.previousView=''; $this.currentView='timelist'; $this.RefreshCurrentView(); return
        }

        $selProject = [string]$res['project']
        $timeCode = $null; $isNumeric = $false
        if ($selProject -eq '(generic time code)') {
            $codeStr = [string]$res['timeCode']
            $codeVal = 0; if (-not [int]::TryParse(($codeStr+''), [ref]$codeVal) -or $codeVal -le 0) {
                Show-InfoMessage -Message "Invalid time code (must be a positive number)." -Title "Validation" -Color "Red"
                $this.previousView=''; $this.currentView='timelist'; $this.RefreshCurrentView(); return
            }
            $timeCode = $codeVal; $isNumeric = $true; $selProject = $null
        }

        # Parse date
        $dateInput = [string]$res['date']
        $dateOut = (Get-Date).Date
        if (-not [string]::IsNullOrWhiteSpace($dateInput)) {
            $trim = $dateInput.Trim().ToLower()
            $dt = $null
            if ($trim -eq 'today') { $dt = (Get-Date).Date }
            elseif ($trim -eq 'tomorrow') { $dt = (Get-Date).Date.AddDays(1) }
            elseif ($trim -match '^[+-]\d+$') { $dt = (Get-Date).Date.AddDays([int]$trim) }
            elseif ($trim -match '^\d{8}$') { try { $dt = [DateTime]::ParseExact($trim, 'yyyyMMdd', $null) } catch {} }
            if (-not $dt) { $dt = Get-ConsoleUIDateOrNull $trim }
            if ($dt) { $dateOut = $dt.Date }
        }

        # Build and save entry
        try {
            $entry = [pscustomobject]@{
                id = Get-PmcNextTimeId $allData
                project = $selProject
                id1 = if ($isNumeric) { $timeCode.ToString() } else { $null }
                id2 = $null
                date = $dateOut.ToString('yyyy-MM-dd')
                minutes = [int]([math]::Round($hours * 60))
                description = ([string]$res['description']).Trim()
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) { $data | Add-Member -NotePropertyName timelogs -NotePropertyValue @() }
            $data.timelogs += $entry
            Save-PmcData -Data $data -Action ("Added time entry #{0} ({1} min)" -f $entry.id, $entry.minutes)
            $this.LoadTimeLogs()
            Show-InfoMessage -Message "Time entry added successfully!" -Title "Success" -Color "Green"
        } catch {
            Show-InfoMessage -Message "Failed to add time entry: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.previousView=''; $this.currentView='timelist'; $this.RefreshCurrentView()
    }


    [void] HandleTimeListView() {
        $this.DrawTimeList()
        $key = [Console]::ReadKey($true)

        # Check for global menu keys first
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            Write-ConsoleUIDebug "Global action from time list: $globalAction" "TIMELIST"
            if ($globalAction -eq 'app:exit') {
                $this.running = $false
                return
            }
            $this.ProcessMenuAction($globalAction)
            return
        }

        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedTimeIndex -gt 0) {
                    $this.selectedTimeIndex--
                }
                $this.DrawTimeList()
            }
            'DownArrow' {
                if ($this.selectedTimeIndex -lt $this.timelogs.Count - 1) {
                    $this.selectedTimeIndex++
                }
                $this.DrawTimeList()
            }
            'A' {
                $this.currentView = 'timeadd'
            }
            'E' {
                $this.currentView = 'timeedit'
            }
            'Delete' {
                # Delete time entry with confirmation
                if ($this.selectedTimeIndex -lt $this.timelogs.Count) {
                    $log = $this.timelogs[$this.selectedTimeIndex]

                    $confirmed = Show-ConfirmDialog -Message "Delete time entry #$($log.id) ($($log.minutes) min on $($log.project))?" -Title "Confirm Delete"
                    if ($confirmed) {
                        try {
                            $data = Get-PmcAllData
                            $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $log.id })
                            Save-PmcData -Data $data -Action "Deleted time entry #$($log.id)"
                            $this.LoadTimeLogs()
                            if ($this.selectedTimeIndex -ge $this.timelogs.Count -and $this.selectedTimeIndex -gt 0) {
                                $this.selectedTimeIndex--
                            }
                            Show-InfoMessage -Message "Time entry #$($log.id) deleted successfully" -Title "Success" -Color "Green"
                        } catch {
                            Show-InfoMessage -Message "Failed to delete time entry: $_" -Title "Error" -Color "Red"
                        }
                    }
                    $this.DrawTimeList()
                }
            }
            'R' {
                $this.currentView = 'timereport'
            }
            'Escape' {
                $this.GoBackOr('main')
            }
        }
    }

    [void] DrawTimeReport() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Time Report "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $timelogList = if ($data.PSObject.Properties['timelogs']) { $data.timelogs } else { @() }

            if ($timelogList.Count -eq 0) {
                $this.terminal.WriteAt(4, 6, "No time entries to report")
            } else {
                # Group by project
                $byProject = $timelogList | Group-Object -Property project | Sort-Object Name

                $this.terminal.WriteAtColor(4, 5, "Time Summary by Project:", [PmcVT100]::Yellow(), "")

                $headerY = 7
                $this.terminal.WriteAt(4, $headerY, "Project")
                $this.terminal.WriteAt(30, $headerY, "Entries")
                $this.terminal.WriteAt(42, $headerY, "Total Minutes")
                $this.terminal.WriteAt(60, $headerY, "Hours")
                $this.terminal.DrawHorizontalLine(2, $headerY + 1, $this.terminal.Width - 4)

                $y = $headerY + 2
                $totalMinutes = 0
                foreach ($group in $byProject) {
                    $minutes = ($group.Group | Measure-Object -Property minutes -Sum).Sum
                    $hours = [Math]::Round($minutes / 60, 1)
                    $totalMinutes += $minutes

                    $this.terminal.WriteAt(4, $y, $group.Name.Substring(0, [Math]::Min(24, $group.Name.Length)))
                    $this.terminal.WriteAt(30, $y, $group.Count.ToString())
                    $this.terminal.WriteAtColor(42, $y, $minutes.ToString(), [PmcVT100]::Cyan(), "")
                    $this.terminal.WriteAtColor(60, $y, $hours.ToString(), [PmcVT100]::Green(), "")
                    $y++

                    if ($y -ge $this.terminal.Height - 5) { break }
                }

                $totalHours = [Math]::Round($totalMinutes / 60, 1)
                $this.terminal.DrawHorizontalLine(2, $y, $this.terminal.Width - 4)
                $y++
                $this.terminal.WriteAtColor(4, $y, "TOTAL:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(42, $y, $totalMinutes.ToString(), [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(60, $y, $totalHours.ToString(), [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error generating report: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }


    [void] DrawProjectCreateForm([int]$ActiveField = -1) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Create New Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $labels = @(
            'Project Name (required):',
            'Description:',
            'ID1:',
            'ID2:',
            'Project Folder:',
            'CAA Name:',
            'Request Name:',
            'T2020:',
            'Assigned Date (yyyy-MM-dd):',
            'Due Date (yyyy-MM-dd):',
            'BF Date (yyyy-MM-dd):'
        )
        for ($i=0; $i -lt $labels.Count; $i++) {
            $label = $labels[$i]
            if ($ActiveField -eq $i) {
                $this.terminal.WriteAtColor(2, $y, '> ', [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(4, $y, $label, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            } else {
                $this.terminal.WriteAtColor(4, $y, $label, [PmcVT100]::Yellow(), "")
            }
            $y++
        }

        $this.terminal.DrawFooter("Enter values; Enter = next, Esc = cancel")
    }

    [void] HandleProjectCreateForm() {
        # Draw header/labels
        $this.DrawProjectCreateForm(-1)

        $rowStart = 6
        $defaultRoot = $Script:DefaultPickerRoot
        $fields = @(
            @{ Name='Name';          Label='Project Name (required):';           X=28; Y=($rowStart + 0); Value='' }
            @{ Name='Description';   Label='Description:';                        X=16; Y=($rowStart + 1); Value='' }
            @{ Name='ID1';           Label='ID1:';                                X=9;  Y=($rowStart + 2); Value='' }
            @{ Name='ID2';           Label='ID2:';                                X=9;  Y=($rowStart + 3); Value='' }
            @{ Name='ProjFolder';    Label='Project Folder:';                     X=20; Y=($rowStart + 4); Value='' }
            @{ Name='CAAName';       Label='CAA Name:';                           X=14; Y=($rowStart + 5); Value='' }
            @{ Name='RequestName';   Label='Request Name:';                       X=17; Y=($rowStart + 6); Value='' }
            @{ Name='T2020';         Label='T2020:';                              X=11; Y=($rowStart + 7); Value='' }
            @{ Name='AssignedDate';  Label='Assigned Date (yyyy-MM-dd):';         X=32; Y=($rowStart + 8); Value='' }
            @{ Name='DueDate';       Label='Due Date (yyyy-MM-dd):';              X=27; Y=($rowStart + 9); Value='' }
            @{ Name='BFDate';        Label='BF Date (yyyy-MM-dd):';               X=26; Y=($rowStart + 10); Value='' }
        )

        # Draw initial values (blank for create)
        foreach ($f in $fields) { $this.terminal.WriteAt($f['X'], $f['Y'], [string]$f['Value']) }
        $this.terminal.DrawFooter("Tab/Shift+Tab navigate  |  F2: Pick path  |  Enter: Create  |  Esc: Cancel")

        # In-form editor with active label highlight
        $active = 0
        $prevActive = -1
        while ($true) {
            $f = $fields[$active]
            if ($prevActive -ne $active) {
                if ($prevActive -ge 0) { $pf = $fields[$prevActive]; $this.terminal.WriteAtColor(4, $pf['Y'], $pf['Label'], [PmcVT100]::Yellow(), "") }
                $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::BgBlue(), [PmcVT100]::White())
                $prevActive = $active
            }
            $buf = [string]($f['Value'] ?? '')
            $col = [int]$f['X']; $row = [int]$f['Y']
            [Console]::SetCursorPosition($col + $buf.Length, $row)
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Enter') { break }
            elseif ($k.Key -eq 'Escape') { $this.GoBackOr('projectlist'); return }
            elseif ($k.Key -eq 'F2') {
                $fname = [string]$f['Name']
                if ($fname -in @('ProjFolder','CAAName','RequestName','T2020')) {
                    $dirsOnly = ($fname -eq 'ProjFolder')
                    $hint = "Pick $fname (Enter to pick)"
                    $picked = Select-ConsoleUIPathAt -app $this -Hint $hint -Col $col -Row $row -StartPath $defaultRoot -DirectoriesOnly:$dirsOnly
                    if ($null -ne $picked) {
                        $fields[$active]['Value'] = $picked
                        $this.terminal.FillArea($col, $row, $this.terminal.Width - $col - 2, 1, ' ')
                        $this.terminal.WriteAt($col, $row, [string]$picked)
                    }
                }
                continue
            }
            elseif ($k.Key -eq 'Tab') {
                $isShift = ("" + $k.Modifiers) -match 'Shift'
                if ($isShift) { $active = ($active - 1); if ($active -lt 0) { $active = $fields.Count - 1 } } else { $active = ($active + 1) % $fields.Count }
                continue
            } elseif ($k.Key -eq 'Backspace') {
                if ($buf.Length -gt 0) {
                    $buf = $buf.Substring(0, $buf.Length - 1)
                    $fields[$active]['Value'] = $buf
                    $this.terminal.FillArea($col, $row, $this.terminal.Width - $col - 2, 1, ' ')
                    $this.terminal.WriteAt($col, $row, $buf)
                }
                continue
            } else {
                $ch = $k.KeyChar
                if ($ch -and $ch -ne "`0") {
                    $buf += $ch
                    $fields[$active]['Value'] = $buf
                    $this.terminal.WriteAt($col + $buf.Length - 1, $row, $ch.ToString())
                }
            }
        }

        # Collect values
        $inputs = @{}
        foreach ($f in $fields) { $inputs[$f['Name']] = [string]$f['Value'] }

        # Validate
        if ([string]::IsNullOrWhiteSpace($inputs.Name)) { Show-InfoMessage -Message "Project name is required" -Title "Validation" -Color "Red"; $this.GoBackOr('projectlist'); return }

        foreach ($pair in @('AssignedDate','DueDate','BFDate')) {
            $raw = [string]$inputs[$pair]
            $norm = Normalize-ConsoleUIDate $raw
            if ($null -eq $norm -and -not [string]::IsNullOrWhiteSpace($raw)) {
                Show-InfoMessage -Message ("Invalid {0}. Use yyyymmdd, mmdd, +/-N, today/tomorrow/yesterday, or yyyy-MM-dd." -f $pair) -Title "Validation" -Color "Red"
                $this.GoBackOr('projectlist'); return
            }
            $inputs[$pair] = $norm
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.projects) { $data.projects = @() }

            # Normalize any legacy entries
            try {
                $normalized = @()
                foreach ($p in @($data.projects)) { if ($p -is [string]) { $normalized += [pscustomobject]@{ id=[guid]::NewGuid().ToString(); name=$p; description=''; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); status='active'; tags=@() } } else { $normalized += $p } }
                $data.projects = $normalized
            } catch {}

            # Duplicate name check
            $exists = @($data.projects | Where-Object { $_.PSObject.Properties['name'] -and $_.name -eq $inputs.Name })
            if ($exists.Count -gt 0) { Show-InfoMessage -Message ("Project '{0}' already exists" -f $inputs.Name) -Title "Error" -Color "Red"; $this.GoBackOr('projectlist'); return }

            # Create project
            $newProject = [pscustomobject]@{
                id = [guid]::NewGuid().ToString()
                name = $inputs.Name
                description = $inputs.Description
                ID1 = $inputs.ID1
                ID2 = $inputs.ID2
                ProjFolder = $inputs.ProjFolder
                AssignedDate = $inputs.AssignedDate
                DueDate = $inputs.DueDate
                BFDate = $inputs.BFDate
                CAAName = $inputs.CAAName
                RequestName = $inputs.RequestName
                T2020 = $inputs.T2020
                icon = ''
                color = 'Gray'
                sortOrder = 0
                aliases = @()
                isArchived = $false
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = 'active'
                tags = @()
            }

            $data.projects += $newProject
            Set-PmcAllData $data
            Show-InfoMessage -Message ("Project '{0}' created" -f $inputs.Name) -Title "Success" -Color "Green"
        } catch {
            Show-InfoMessage -Message ("Failed to create project: {0}" -f $_) -Title "Error" -Color "Red"
        }

        $this.GoBackOr('projectlist')
    }

    [void] HandleTaskEditForm() {
        # Determine task ID
        $taskId = 0
        if ($this.selectedTask) { $taskId = try { [int]$this.selectedTask.id } catch { 0 } }
        if ($taskId -le 0) {
            $fields = @(@{Name='taskId'; Label='Task ID'; Required=$true})
            $result = Show-InputForm -Title "Edit Task" -Fields $fields
            if ($null -eq $result) { $this.GoBackOr('tasklist'); return }
            $taskId = try { [int]$result['taskId'] } catch { 0 }
            if ($taskId -le 0) { Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"; $this.GoBackOr('tasklist'); return }
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
            if (-not $task) { Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"; $this.GoBackOr('tasklist'); return }

            # Get current task values for prepopulation
            $currentText = if ($task.text) { [string]$task.text } else { '' }
            $currentProject = if ($task.project) { [string]$task.project } else { '' }
            $currentPriority = if ($task.PSObject.Properties['priority'] -and $task.priority) { [string]$task.priority } else { 'medium' }
            $currentDue = ''
            if ($task.PSObject.Properties['due'] -and $task.due) { $currentDue = [string]$task.due }
            elseif ($task.PSObject.Properties['dueDate'] -and $task.dueDate) { $currentDue = [string]$task.dueDate }

            # Get available projects for dropdown
            $projectList = @('none', 'inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

            # Use the same input form as add task, but with prepopulated values
            $input = Show-InputForm -Title "Edit Task #$taskId" -Fields @(
                @{Name='text'; Label='Task description'; Required=$true; Type='text'; Value=$currentText}
                @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList; Value=$currentProject}
                @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low'); Value=$currentPriority}
                @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'; Value=$currentDue}
            )

            if ($null -eq $input) {
                $this.GoBackOr('tasklist')
                return
            }

            # Update task with new values
            $changed = $false

            if ($input['text'] -ne $currentText) {
                $task.text = $input['text'].Trim()
                $changed = $true
            }

            $newProject = if ([string]::IsNullOrWhiteSpace($input['project']) -or $input['project'] -eq 'none') { $null } else { $input['project'].Trim() }
            if ($newProject -ne $task.project) {
                $task.project = $newProject
                $changed = $true
            }

            if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
                $newPriority = $input['priority'].Trim().ToLower()
                if ($newPriority -ne $task.priority) {
                    $task.priority = $newPriority
                    $changed = $true
                }
            }

            # Handle due date
            if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                $parsedDate = ConvertTo-PmcDate -DateString $input['due']
                if ($null -eq $parsedDate) {
                    Show-InfoMessage -Message "Invalid due date. Try: today, yyyymmdd, mmdd, +3, etc." -Title "Invalid Date" -Color "Red"
                    $this.GoBackOr('tasklist')
                    return
                }
                if ($parsedDate -ne $currentDue) {
                    $task | Add-Member -MemberType NoteProperty -Name 'due' -Value $parsedDate -Force
                    $changed = $true
                }
            } elseif (-not [string]::IsNullOrWhiteSpace($currentDue)) {
                # Clear due date if user deleted it
                $task | Add-Member -MemberType NoteProperty -Name 'due' -Value $null -Force
                $changed = $true
            }

            if ($changed) {
                $task | Add-Member -MemberType NoteProperty -Name 'modified' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force
                Save-PmcData -Data $data -Action "Edited task $taskId"
                $this.LoadTasks()
                Show-InfoMessage -Message "Task #$taskId updated successfully" -Title "Success" -Color "Green"
            } else {
                Show-InfoMessage -Message "No changes made to task #$taskId" -Title "Info" -Color "Cyan"
            }

            # Return to previous view and maintain selection
            if ($this.previousView -and $this.previousView -ne 'taskdetail') {
                $this.currentView = $this.previousView
                $this.previousView = ''
            } else {
                $this.currentView = 'tasklist'
            }

            # Try to keep selection on the edited task
            for ($i=0; $i -lt $this.tasks.Count; $i++) {
                if ($this.tasks[$i].id -eq $taskId) {
                    $this.selectedTaskIndex = $i
                    break
                }
            }

            $this.RefreshCurrentView()
        } catch {
            Show-InfoMessage -Message "Failed to edit task: $_" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
        }
    }

    [void] DrawTaskCompleteForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Complete Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleTaskCompleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID to complete'; Required=$true}
        )

        $result = Show-InputForm -Title "Complete Task" -Fields $fields

        if ($null -eq $result) {
            $this.GoBackOr('tasklist')
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }

        if ($taskId -le 0) {
            Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } else {
                $task.status = 'completed'
                $task.completed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Save-PmcData -Data $data -Action "Completed task $taskId"
                Show-InfoMessage -Message "Task $taskId completed successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to complete task: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawTaskDeleteForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Delete Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "WARNING: This will permanently delete the task!", [PmcVT100]::Red(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleTaskDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Task" -Fields $fields

        if ($null -eq $result) {
            $this.GoBackOr('tasklist')
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }

        if ($taskId -le 0) {
            Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } else {
                # Use Show-ConfirmDialog for deletion confirmation
                $confirmed = Show-ConfirmDialog -Message "Delete task '$($task.text)'? This cannot be undone." -Title "Confirm Deletion"

                if ($confirmed) {
                    $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                    Save-PmcData -Data $data -Action "Deleted task $taskId"
                    Show-InfoMessage -Message "Task $taskId deleted successfully!" -Title "Success" -Color "Green"
                } else {
                    Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete task: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawDepAddForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Dependency "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Depends on Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 10, "(Task will be blocked until dependency is completed)")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleDepAddForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true}
            @{Name='dependsId'; Label='Depends on Task ID'; Required=$true}
        )

        $result = Show-InputForm -Title "Add Dependency" -Fields $fields

        if ($null -eq $result) {
            $this.GoBackOr('projectlist')
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }
        $dependsId = try { [int]$result['dependsId'] } catch { 0 }

        if ($taskId -le 0 -or $dependsId -le 0) {
            Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }
            $dependsTask = $data.tasks | Where-Object { $_.id -eq $dependsId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $dependsTask) {
                Show-InfoMessage -Message "Task $dependsId not found!" -Title "Error" -Color "Red"
            } else {
                # Initialize depends array if needed
                if (-not $task.PSObject.Properties['depends']) {
                    $task | Add-Member -NotePropertyName depends -NotePropertyValue @()
                }

                # Check if dependency already exists
                if ($task.depends -contains $dependsId) {
                    Show-InfoMessage -Message "Dependency already exists!" -Title "Warning" -Color "Yellow"
                } else {
                    $task.depends = @($task.depends + $dependsId)

                    # Update blocked status
                    Update-PmcBlockedStatus -data $data

                    Save-PmcData -Data $data -Action "Added dependency: $taskId depends on $dependsId"
                    Show-InfoMessage -Message "Dependency added successfully! Task $taskId now depends on task $dependsId." -Title "Success" -Color "Green"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to add dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawDepRemoveForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Remove Dependency "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Remove dependency on Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleDepRemoveForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true}
            @{Name='dependsId'; Label='Remove dependency on Task ID'; Required=$true}
        )

        $result = Show-InputForm -Title "Remove Dependency" -Fields $fields

        if ($null -eq $result) {
            $this.GoBackOr('timelist')
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }
        $dependsId = try { [int]$result['dependsId'] } catch { 0 }

        if ($taskId -le 0 -or $dependsId -le 0) {
            Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
            $this.GoBackOr('tasklist')
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $task.PSObject.Properties['depends'] -or -not $task.depends) {
                Show-InfoMessage -Message "Task has no dependencies!" -Title "Warning" -Color "Yellow"
            } else {
                $task.depends = @($task.depends | Where-Object { $_ -ne $dependsId })

                # Clean up empty depends array
                if ($task.depends.Count -eq 0) {
                    $task.PSObject.Properties.Remove('depends')
                }

                # Update blocked status
                Update-PmcBlockedStatus -data $data

                Save-PmcData -Data $data -Action "Removed dependency: $taskId no longer depends on $dependsId"
                Show-InfoMessage -Message "Dependency removed successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to remove dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawDepShowForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Show Task Dependencies "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterIDCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleDepShowForm() {
        # Unified input for task id
        $fields = @(
            @{Name='taskId'; Label='Task ID to show dependencies'; Required=$true}
        )
        $form = Show-InputForm -Title "Show Task Dependencies" -Fields $fields
        if ($null -eq $form) { $this.GoBackOr('tasklist'); return }
        $taskId = try { [int]$form['taskId'] } catch { 0 }
        if ($taskId -le 0) { Show-InfoMessage -Message "Invalid task ID" -Title "Validation" -Color "Red"; $this.GoBackOr('tasklist'); return }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message ("Task {0} not found" -f $taskId) -Title "Error" -Color "Red"
                $this.GoBackOr('tasklist'); return
            }

            $this.terminal.Clear()
            $this.menuSystem.DrawMenuBar()
            $title = " Show Task Dependencies "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            $this.terminal.WriteAtColor(4, 9, "Task:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(10, 9, $task.text.Substring(0, [Math]::Min(60, $task.text.Length)))

            $depends = if ($task.PSObject.Properties['depends'] -and $task.depends) { $task.depends } else { @() }
            if ($depends.Count -eq 0) {
                $this.terminal.WriteAt(4, 11, "No dependencies")
            } else {
                $this.terminal.WriteAtColor(4, 11, "Dependencies:", [PmcVT100]::Yellow(), "")
                $y = 13
                foreach ($depId in $depends) {
                    $depTask = $data.tasks | Where-Object { $_.id -eq $depId }
                    if ($depTask) {
                        $statusIcon = if ($depTask.status -eq 'completed') { 'X' } else { 'o' }
                        $statusColor = if ($depTask.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Red() }
                        $this.terminal.WriteAtColor(6, $y, $statusIcon, $statusColor, "")
                        $this.terminal.WriteAt(8, $y, "#$depId")
                        $this.terminal.WriteAt(15, $y, $depTask.text.Substring(0, [Math]::Min(50, $depTask.text.Length)))
                        $y++
                    }
                    if ($y -ge $this.terminal.Height - 5) { break }
                }
                if ($task.PSObject.Properties['blocked'] -and $task.blocked) {
                    $this.terminal.WriteAtColor(4, $y + 1, "WARNING: Task is BLOCKED", [PmcVT100]::Red(), "")
                } else {
                    $this.terminal.WriteAtColor(4, $y + 1, "Task is ready", [PmcVT100]::Green(), "")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        [Console]::ReadKey($true) | Out-Null
        $this.GoBackOr('tasklist')
    }

    [void] DrawDepGraph() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Dependency Graph "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $tasksWithDeps = @($data.tasks | Where-Object {
                $_.PSObject.Properties['depends'] -and $_.depends -and $_.depends.Count -gt 0
            })

            if ($tasksWithDeps.Count -eq 0) {
                $this.terminal.WriteAt(4, 6, "No task dependencies found")
            } else {
                $headerY = 5
                $this.terminal.WriteAt(2, $headerY, "Task")
                $this.terminal.WriteAt(10, $headerY, "Depends On")
                $this.terminal.WriteAt(26, $headerY, "Status")
                $this.terminal.WriteAt(40, $headerY, "Description")
                $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

                $y = $headerY + 2
                foreach ($task in $tasksWithDeps) {
                    if ($y -ge $this.terminal.Height - 5) { break }

                    $dependsText = ($task.depends -join ', ')
                    $statusText = if ($task.PSObject.Properties['blocked'] -and $task.blocked) { "BLOCKED" } else { "Ready" }
                    $statusColor = if ($task.PSObject.Properties['blocked'] -and $task.blocked) { [PmcVT100]::Red() } else { [PmcVT100]::Green() }

                    $this.terminal.WriteAt(2, $y, "#$($task.id)")
                    $this.terminal.WriteAt(10, $y, $dependsText.Substring(0, [Math]::Min(14, $dependsText.Length)))
                    $this.terminal.WriteAtColor(26, $y, $statusText, $statusColor, "")
                    $this.terminal.WriteAt(40, $y, $task.text.Substring(0, [Math]::Min(38, $task.text.Length)))
                    $y++
                }

                # Summary
                $blockedCount = @($data.tasks | Where-Object { $_.PSObject.Properties['blocked'] -and $_.blocked }).Count
                $y += 2
                $this.terminal.WriteAtColor(4, $y, "Tasks with dependencies:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(30, $y, $tasksWithDeps.Count.ToString())
                $y++
                $this.terminal.WriteAtColor(4, $y, "Currently blocked:", [PmcVT100]::Yellow(), "")
                $blockedColor = if ($blockedCount -gt 0) { [PmcVT100]::Red() } else { [PmcVT100]::Green() }
                $this.terminal.WriteAtColor(30, $y, $blockedCount.ToString(), $blockedColor, "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading dependency graph: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    # File Management Methods
    [void] DrawFileRestoreForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Restore Data from Backup "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $allBackups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }

            if ($allBackups.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "Available backups:", [PmcVT100]::Yellow(), "")
                $y = 8
                foreach ($backup in $allBackups) {
                    $sizeKB = [math]::Round($backup.Size / 1KB, 2)
                    $typeLabel = if ($backup.Type -eq "auto") { "[Auto]" } else { "[Manual]" }
                    $line = "$($backup.Number). $typeLabel $($backup.Name) - $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss')) ($sizeKB KB)"
                    $this.terminal.WriteAt(4, $y++, $line)
                }
                $this.terminal.WriteAtColor(4, $y + 1, "Enter backup number to restore:", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No backups found", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error listing backups: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Enter number or Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleFileRestoreForm() {
        try {
            $file = Get-PmcTaskFilePath
            $allBackups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }

            if ($allBackups.Count -eq 0) { Show-InfoMessage -Message "No backups found" -Title "Restore" -Color "Yellow"; $this.GoBackOr('tasklist'); return }

            # Build options for select list
            $options = @()
            foreach ($b in $allBackups) {
                $sizeKB = [math]::Round($b.Size / 1KB, 2)
                $typeLabel = if ($b.Type -eq 'auto') { '[Auto]' } else { '[Manual]' }
                $options += ("{0} {1}  {2}  ({3} KB)" -f $typeLabel, $b.Name, $b.Modified.ToString('yyyy-MM-dd HH:mm'), $sizeKB)
            }

            $selected = Show-SelectList -Title "Select Backup to Restore" -Options $options
            if (-not $selected) { $this.GoBackOr('tasklist'); return }
            $idx = [Array]::IndexOf(@($options), $selected)
            if ($idx -lt 0) { $this.GoBackOr('tasklist'); return }
            $backup = $allBackups[$idx]

            $confirmed = Show-ConfirmDialog -Message ("Restore from {0}? This overwrites current data." -f $backup.Name) -Title "Confirm Restore"
            if ($confirmed) {
                try {
                    $data = Get-Content $backup.Path -Raw | ConvertFrom-Json
                    Save-PmcData -Data $data -Action ("Restored from backup: {0}" -f $backup.Name)
                    $this.LoadTasks()
                    Show-InfoMessage -Message "Data restored successfully" -Title "Success" -Color "Green"
                } catch {
                    Show-InfoMessage -Message ("Error restoring backup: {0}" -f $_) -Title "Error" -Color "Red"
                }
            } else {
                Show-InfoMessage -Message "Restore cancelled" -Title "Cancelled" -Color "Yellow"
            }
        } catch {
            Show-InfoMessage -Message ("Error restoring backup: {0}" -f $_) -Title "Error" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    

    [void] DrawProjectArchiveForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Archive Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.DrawFooter("Enter project name | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleProjectArchiveForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='projectName'; Label='Project Name to archive'; Required=$true}
        )

        $result = Show-InputForm -Title "Archive Project" -Fields $fields

        if ($null -eq $result) { $this.GoBackOr('projectlist'); return }

        $projectName = $result['projectName']

        try {
            $data = Get-PmcAllData
            $exists = @($data.projects | Where-Object { ($_ -is [string] -and $_ -eq $projectName) -or ($_.PSObject.Properties['name'] -and $_.name -eq $projectName) }).Count -gt 0
            if (-not $exists) {
                Show-InfoMessage -Message "Project '$projectName' not found!" -Title "Error" -Color "Red"
            } else {
                if (-not $data.PSObject.Properties['archivedProjects']) { $data | Add-Member -NotePropertyName 'archivedProjects' -NotePropertyValue @() }
                $data.archivedProjects += $projectName
                $data.projects = @(
                    $data.projects | Where-Object {
                        $pName = if ($_ -is [string]) { $_ } else { $_.name }
                        $pName -ne $projectName
                    }
                )
                Save-PmcData -Data $data -Action "Archived project: $projectName"
                Show-InfoMessage -Message "Project '$projectName' archived successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to archive project: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.GoBackOr('projectlist')
    }

    [void] DrawProjectDeleteForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Delete Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "WARNING: This will NOT delete tasks!", [PmcVT100]::Red(), "")
        $this.terminal.DrawFooter("Enter project name | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleProjectDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='projectName'; Label='Project Name to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Project" -Fields $fields

        if ($null -eq $result) { $this.GoBackOr('projectlist'); return }

        $projectName = $result['projectName']

        try {
            $data = Get-PmcAllData
            $exists = @($data.projects | Where-Object { ($_ -is [string] -and $_ -eq $projectName) -or ($_.PSObject.Properties['name'] -and $_.name -eq $projectName) }).Count -gt 0
            if (-not $exists) {
                Show-InfoMessage -Message "Project '$projectName' not found!" -Title "Error" -Color "Red"
            } else {
                $confirmed = Show-ConfirmDialog -Message "Delete project '$projectName'? (Tasks will remain in inbox)" -Title "Confirm Deletion"
                if ($confirmed) {
                    $data.projects = @(
                        $data.projects | Where-Object {
                            $pName = if ($_ -is [string]) { $_ } else { $_.name }
                            $pName -ne $projectName
                        }
                    )
                    Save-PmcData -Data $data -Action "Deleted project: $projectName"
                    Show-InfoMessage -Message "Project '$projectName' deleted successfully!" -Title "Success" -Color "Green"
                } else {
                    Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete project: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.GoBackOr('projectlist')
    }

    [void] DrawProjectStatsForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Project Statistics "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.DrawFooter("Enter project name | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleProjectStatsView() {
        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ })
            $selected = Show-SelectList -Title "Project for Stats" -Options $projectList
            if (-not $selected) { $this.GoBackOr('projectlist'); return }
            $projectName = $selected
            $this.terminal.Clear()
            $this.menuSystem.DrawMenuBar()
            $title = " Project Statistics "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(19, 6, $projectName)
        } catch {
            $this.GoBackOr('projectlist')
            return
        }
        try {
            $data = Get-PmcAllData
            $exists = @($data.projects | Where-Object { ($_ -is [string] -and $_ -eq $projectName) -or ($_.PSObject.Properties['name'] -and $_.name -eq $projectName) }).Count -gt 0
            if (-not $exists) {
                $this.terminal.WriteAtColor(4, 9, "Project '$projectName' not found!", [PmcVT100]::Red(), "")
            } else {
                $projTasks = @($data.tasks | Where-Object { $_.project -eq $projectName })
                $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                $overdue = @($projTasks | Where-Object {
                    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
                    $d = Get-ConsoleUIDateOrNull $_.due
                    if ($d) { return ($d.Date -lt (Get-Date).Date) } else { return $false }
                }).Count

                $projTimelogs = if ($data.PSObject.Properties['timelogs']) { @($data.timelogs | Where-Object { $_.project -eq $projectName }) } else { @() }
                $totalMinutes = if ($projTimelogs.Count -gt 0) { ($projTimelogs | Measure-Object -Property minutes -Sum).Sum } else { 0 }
                $totalHours = [Math]::Round($totalMinutes / 60, 1)

                $this.terminal.WriteAtColor(4, 9, "Project:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(13, 9, $projectName)

                $this.terminal.WriteAtColor(4, 11, "Total Tasks:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 11, $projTasks.Count.ToString())

                $this.terminal.WriteAtColor(4, 12, "Active:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(18, 12, $active.ToString(), [PmcVT100]::Cyan(), "")

                $this.terminal.WriteAtColor(4, 13, "Completed:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(18, 13, $completed.ToString(), [PmcVT100]::Green(), "")

                if ($overdue -gt 0) {
                    $this.terminal.WriteAtColor(4, 14, "Overdue:", [PmcVT100]::Yellow(), "")
                    $this.terminal.WriteAtColor(18, 14, $overdue.ToString(), [PmcVT100]::Red(), "")
                }

                $this.terminal.WriteAtColor(4, 16, "Time Logged:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 16, "$totalHours hours ($totalMinutes minutes)")

                $this.terminal.WriteAtColor(4, 17, "Time Entries:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 17, $projTimelogs.Count.ToString())
            }
        } catch {
            $this.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
        }
        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        [Console]::ReadKey($true) | Out-Null
        $this.GoBackOr('projectlist')
    }

    # Time Management Methods
    [void] DrawTimeEditForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Edit Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Time Entry ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "New Minutes:", [PmcVT100]::Yellow(), "")
        $this.terminal.DrawFooter("Enter ID and minutes | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTimeEditForm() {
        # Determine target entry
        $id = 0
        if ($this.timelogs -and $this.selectedTimeIndex -ge 0 -and $this.selectedTimeIndex -lt $this.timelogs.Count) {
            $id = try { [int]$this.timelogs[$this.selectedTimeIndex].id } catch { 0 }
        }
        if ($id -le 0) {
            $fields = @(@{Name='id'; Label='Time Entry ID'; Required=$true})
            $result = Show-InputForm -Title "Edit Time Entry" -Fields $fields
            if ($null -eq $result) { $this.GoBackOr('timelist'); return }
            $id = try { [int]$result['id'] } catch { 0 }
            if ($id -le 0) { Show-InfoMessage -Message "Invalid time entry ID" -Title "Error" -Color "Red"; $this.GoBackOr('timelist'); return }
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) { Show-InfoMessage -Message "No time logs found!" -Title "Error" -Color "Red"; $this.GoBackOr('timelist'); return }
            $entry = $data.timelogs | Where-Object { $_.id -eq $id } | Select-Object -First 1
            if (-not $entry) { Show-InfoMessage -Message "Time entry $id not found!" -Title "Error" -Color "Red"; $this.GoBackOr('timelist'); return }

            # Draw form
            $this.terminal.Clear(); $this.menuSystem.DrawMenuBar()
            $title = " Edit Time Entry #$id "; $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            $yStart = 6
            $minVal = try { [string]$entry.minutes } catch { '' }
            $descVal = if ($entry.PSObject.Properties['description']) { [string]$entry.description } else { '' }
            $fields = @(
                @{ Name='minutes'; Label='Minutes:'; Value=$minVal; X=14; Y=$yStart }
                @{ Name='description'; Label='Description:'; Value=$descVal; X=16; Y=($yStart+3) }
            )
            foreach ($f in $fields) { $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::Yellow(), ""); $this.terminal.WriteAt($f['X'], $f['Y'], [string]$f['Value']) }
            $this.terminal.DrawFooter("Tab/Shift+Tab navigate | Enter saves | Esc cancels")

            $active = 0
            $prevActive = -1
            while ($true) {
                $f = $fields[$active]
                if ($prevActive -ne $active) {
                    if ($prevActive -ge 0) { $pf = $fields[$prevActive]; $this.terminal.WriteAtColor(4, $pf['Y'], $pf['Label'], [PmcVT100]::Yellow(), "") }
                    $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::BgBlue(), [PmcVT100]::White())
                    $prevActive = $active
                }
                $buf = [string]($f['Value'] ?? '')
                $col = [int]$f['X']; $row = [int]$f['Y']
                [Console]::SetCursorPosition($col + $buf.Length, $row)
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq 'Enter') { break }
                elseif ($k.Key -eq 'Escape') { $this.GoBackOr('timelist'); return }
                elseif ($k.Key -eq 'Tab') {
                    $isShift = ("" + $k.Modifiers) -match 'Shift'
                    if ($isShift) { $active = ($active - 1); if ($active -lt 0) { $active = $fields.Count - 1 } } else { $active = ($active + 1) % $fields.Count }
                } elseif ($k.Key -eq 'Backspace') {
                    if ($buf.Length -gt 0) { $buf = $buf.Substring(0, $buf.Length - 1); $fields[$active]['Value'] = $buf; $this.terminal.FillArea($col, $row, $this.terminal.Width - $col - 1, 1, ' '); $this.terminal.WriteAt($col, $row, $buf) }
                } else {
                    $ch = $k.KeyChar; if ($ch -and $ch -ne "`0") { $buf += $ch; $fields[$active]['Value'] = $buf; $this.terminal.WriteAt($col + $buf.Length - 1, $row, $ch.ToString()) }
                }
            }

            $newMinutes = [string]$fields | Where-Object { $_.Name -eq 'minutes' } | ForEach-Object { $_.Value }
            $newDesc = [string]$fields | Where-Object { $_.Name -eq 'description' } | ForEach-Object { $_.Value }
            $mInt = 0; try { $mInt = [int]$newMinutes } catch { $mInt = 0 }
            if ($mInt -le 0) { Show-InfoMessage -Message "Minutes must be a positive number" -Title "Error" -Color "Red"; $this.GoBackOr('timelist'); return }
            $entry.minutes = $mInt
            if ($entry.PSObject.Properties['description']) { $entry.description = $newDesc }
            Save-PmcData -Data $data -Action "Updated time entry $id"
            $this.GoBackOr('timelist')
        } catch {
            Show-InfoMessage -Message "Failed to update time entry: $_" -Title "SAVE ERROR" -Color "Red"; $this.GoBackOr('timelist')
        }
    }

    [void] DrawTimeDeleteForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Delete Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Time Entry ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.DrawFooter("Enter ID | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTimeDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='id'; Label='Time Entry ID to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Time Entry" -Fields $fields

        if ($null -eq $result) {
            $this.GoBackOr('timelist')
            return
        }

        $id = try { [int]$result['id'] } catch { 0 }

        if ($id -le 0) {
            Show-InfoMessage -Message "Invalid time entry ID" -Title "Error" -Color "Red"
            $this.GoBackOr('timelist')
            return
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) {
                Show-InfoMessage -Message "No time logs found!" -Title "Error" -Color "Red"
            } else {
                $entry = $data.timelogs | Where-Object { $_.id -eq $id }
                if (-not $entry) {
                    Show-InfoMessage -Message "Time entry $id not found!" -Title "Error" -Color "Red"
                } else {
                    # Use Show-ConfirmDialog for confirmation
                    $confirmed = Show-ConfirmDialog -Message "Delete time entry #$($id)? This cannot be undone." -Title "Confirm Deletion"

                    if ($confirmed) {
                        $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $id })
                        Save-PmcData -Data $data -Action "Deleted time entry $id"
                        Show-InfoMessage -Message "Time entry deleted successfully!" -Title "Success" -Color "Green"
                    } else {
                        Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                    }
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete time entry: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.GoBackOr('timelist')
    }

    # Task Import/Export Methods
    [void] DrawTaskImportForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Import Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Import File Path:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "(Must be JSON format compatible with PMC)")
        $this.terminal.DrawFooter("Enter file path | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTaskImportForm() {
        # Unified input
        $fields = @(
            @{Name='path'; Label='Import file path (JSON)'; Required=$true}
        )
        $result = Show-InputForm -Title "Import Tasks" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('main'); return }
        $filePath = [string]$result['path']
        if ([string]::IsNullOrWhiteSpace($filePath)) { $this.GoBackOr('main'); return }
        try {
            if (-not (Test-Path $filePath)) {
                $this.terminal.WriteAtColor(4, 11, "File not found: $filePath", [PmcVT100]::Red(), "")
            } else {
                $importData = Get-Content $filePath -Raw | ConvertFrom-Json
                $data = Get-PmcAllData
                $newTasks = 0
                foreach ($task in $importData.tasks) {
                    if (-not ($data.tasks | Where-Object { $_.id -eq $task.id })) {
                        $data.tasks += $task
                        $newTasks++
                    }
                }
                Save-PmcData -Data $data -Action "Imported $newTasks tasks from $filePath"
                $this.terminal.WriteAtColor(4, 11, "Imported $newTasks tasks!", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 11, "Error: $_", [PmcVT100]::Red(), "")
        }
        $this.GoBackOr('main')
    }

    [void] DrawTaskExportForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Export Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Export File Path:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "(Will export all tasks as JSON)")
        $this.terminal.DrawFooter("Enter file path | Esc=Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleTaskExportForm() {
        # Unified input
        $fields = @(
            @{Name='path'; Label='Export file path (JSON)'; Required=$true}
        )
        $result = Show-InputForm -Title "Export Tasks" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('main'); return }
        $filePath = [string]$result['path']
        if ([string]::IsNullOrWhiteSpace($filePath)) { $this.GoBackOr('main'); return }
        try {
            $data = Get-PmcAllData
            $exportData = @{ tasks = $data.tasks; projects = $data.projects }
            $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8
            $this.terminal.WriteAtColor(4, 11, "Exported $($data.tasks.Count) tasks to $filePath", [PmcVT100]::Green(), "")
        } catch {
            $this.terminal.WriteAtColor(4, 11, "Error: $_", [PmcVT100]::Red(), "")
        }
        $this.GoBackOr('main')
    }

    [void] DrawThemeEditor() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Theme Editor "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Current color scheme:", [PmcVT100]::Cyan(), "")
        $y++

        # Show current colors in use
        $this.terminal.WriteAt(4, $y++, "Primary colors:")
        $this.terminal.WriteAtColor(6, $y++, "• Success/Completed", [PmcVT100]::Green(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Errors/Warnings", [PmcVT100]::Red(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Information", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Highlights", [PmcVT100]::Yellow(), "")
        $y++

        $this.terminal.WriteAt(4, $y++, "Available themes:")
        $y++
        $this.terminal.WriteAtColor(6, $y++, "1. Default - Standard color scheme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "2. Dark - High contrast dark theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "3. Light - Light background theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "4. Solarized - Solarized color palette", [PmcVT100]::White(), "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Press number key to preview theme", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, $y, "Press 'A' to apply selected theme", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter("1-4:Select | A:Apply | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawApplyTheme() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Apply Theme "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Select a theme to apply:", [PmcVT100]::Cyan(), "")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "1. Default Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Standard colors optimized for dark terminals")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "2. Dark Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "High contrast with bright highlights")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "3. Light Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Designed for light terminal backgrounds")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "4. Solarized Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Popular Solarized color palette")
        $y++
        $y++

        $this.terminal.WriteAtColor(4, $y, "Press number to apply theme (changes take effect immediately)", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter("1-4:Apply Theme | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] DrawCopyTaskForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Copy/Duplicate Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID to copy:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "This will create an exact duplicate of the task")

        $this.terminal.DrawFooter("Enter task ID | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleCopyTaskForm() {
        $fields = @(
            @{Name='taskId'; Label='Task ID to copy'; Required=$true}
        )
        $res = Show-InputForm -Title "Copy Task" -Fields $fields
        if ($null -eq $res) { $this.GoBackOr('tasklist'); return }
        $taskId = [string]$res['taskId']
        if ([string]::IsNullOrWhiteSpace($taskId)) { $this.GoBackOr('tasklist'); return }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $clone = $task.PSObject.Copy()
                $clone.id = ($data.tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
                $data.tasks += $clone
                Set-PmcAllData $data
                Show-InfoMessage -Message ("Task {0} duplicated as task {1}" -f $taskId, $clone.id) -Title "Success" -Color "Green"
                $this.LoadTasks()
            } else {
                Show-InfoMessage -Message ("Task {0} not found" -f $taskId) -Title "Error" -Color "Red"
            }
        } catch {
            Show-InfoMessage -Message ("Error: {0}" -f $_) -Title "Error" -Color "Red"
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawMoveTaskForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Move Task to Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Project Name:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterFieldsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleMoveTaskForm() {
        $data = Get-PmcAllData
        $projectList = @('inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)
        $fields = @(
            @{Name='taskId'; Label='Task ID to move'; Required=$true}
            @{Name='project'; Label='Target Project'; Required=$true; Type='select'; Options=$projectList}
        )
        $res = Show-InputForm -Title "Move Task to Project" -Fields $fields
        if ($null -eq $res) { $this.GoBackOr('tasklist'); return }
        $taskId = [string]$res['taskId']
        $project = [string]$res['project']
        if ([string]::IsNullOrWhiteSpace($taskId) -or [string]::IsNullOrWhiteSpace($project)) { $this.GoBackOr('tasklist'); return }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $task.project = $project
                Set-PmcAllData $data
                Show-InfoMessage -Message ("Moved task {0} to @{1}" -f $taskId, $project) -Title "Success" -Color "Green"
                $this.LoadTasks()
            } else {
                Show-InfoMessage -Message ("Task {0} not found" -f $taskId) -Title "Error" -Color "Red"
            }
        } catch {
            Show-InfoMessage -Message ("Error: {0}" -f $_) -Title "Error" -Color "Red"
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawSetPriorityForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Set Task Priority "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Priority (high/medium/low):", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterFieldsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleSetPriorityForm() {
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true; Type='text'}
            @{Name='priority'; Label='Priority'; Required=$true; Type='select'; Options=@('high','medium','low','none')}
        )
        $result = Show-InputForm -Title "Set Task Priority" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('tasklist'); return }
        $taskIdStr = [string]$result['taskId']
        $priority = [string]$result['priority']
        $tid = 0; try { $tid = [int]$taskIdStr } catch { $tid = 0 }
        if ($tid -le 0 -or [string]::IsNullOrWhiteSpace($priority)) { Show-InfoMessage -Message "Invalid inputs" -Title "Validation" -Color "Red"; $this.GoBackOr('tasklist'); return }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
            if ($task) {
                $task.priority = if ($priority -eq 'none') { $null } else { $priority.ToLower() }
                Set-PmcAllData $data
                Show-InfoMessage -Message ("Set task {0} priority to {1}" -f $tid, ($priority)) -Title "Success" -Color "Green"
                $this.LoadTasks()
            } else {
                Show-InfoMessage -Message ("Task {0} not found" -f $tid) -Title "Error" -Color "Red"
            }
        } catch {
            Show-InfoMessage -Message ("Failed to set priority: {0}" -f $_) -Title "Error" -Color "Red"
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawPostponeTaskForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Postpone Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Days to postpone (default: 1):", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterFieldsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandlePostponeTaskForm() {
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true; Type='text'}
            @{Name='days'; Label='Days to postpone (default 1)'; Required=$false; Type='text'}
        )
        $result = Show-InputForm -Title "Postpone Task" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('tasklist'); return }
        $taskIdStr = [string]$result['taskId']
        $daysStr = [string]$result['days']
        $tid = 0; try { $tid = [int]$taskIdStr } catch { $tid = 0 }
        if ($tid -le 0) { Show-InfoMessage -Message "Invalid task ID" -Title "Validation" -Color "Red"; $this.GoBackOr('tasklist'); return }
        $days = 1; try { if (-not [string]::IsNullOrWhiteSpace($daysStr)) { $days = [int]$daysStr } } catch { $days = 1 }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
            if ($task) {
                $currentDue = if ($task.due) { (Get-ConsoleUIDateOrNull $task.due) } else { Get-Date }
                if (-not $currentDue) { $currentDue = Get-Date }
                $task.due = $currentDue.AddDays($days).ToString('yyyy-MM-dd')
                Set-PmcAllData $data
                Show-InfoMessage -Message ("Postponed task {0} by {1} day(s) to {2}" -f $tid,$days,$task.due) -Title "Success" -Color "Green"
                $this.LoadTasks()
            } else {
                Show-InfoMessage -Message ("Task {0} not found" -f $tid) -Title "Error" -Color "Red"
            }
        } catch {
            Show-InfoMessage -Message ("Failed to postpone: {0}" -f $_) -Title "Error" -Color "Red"
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawAddNoteForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Note to Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Note:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterEnterFieldsCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleAddNoteForm() {
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true; Type='text'}
            @{Name='note'; Label='Note'; Required=$true; Type='text'}
        )
        $result = Show-InputForm -Title "Add Note to Task" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('tasklist'); return }
        $taskIdStr = [string]$result['taskId']
        $note = [string]$result['note']
        $tid = 0; try { $tid = [int]$taskIdStr } catch { $tid = 0 }
        if ($tid -le 0 -or [string]::IsNullOrWhiteSpace($note)) { Show-InfoMessage -Message "Invalid inputs" -Title "Validation" -Color "Red"; $this.GoBackOr('tasklist'); return }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
            if ($task) {
                if (-not $task.notes) { $task.notes = @() }
                $task.notes += $note
                Set-PmcAllData $data
                Show-InfoMessage -Message ("Added note to task {0}" -f $tid) -Title "Success" -Color "Green"
                $this.LoadTasks()
            } else {
                Show-InfoMessage -Message ("Task {0} not found" -f $tid) -Title "Error" -Color "Red"
            }
        } catch {
            Show-InfoMessage -Message ("Failed to add note: {0}" -f $_) -Title "Error" -Color "Red"
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawEditProjectForm() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Edit Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Edit fields; Tab/Shift+Tab navigate; F2 picks path; Enter saves; Esc cancels.", [PmcVT100]::Yellow(), "")
        $this.terminal.DrawFooter([PmcUIStringCache]::FooterTabNav)
        $this.terminal.EndFrame()
    }

    [void] HandleEditProjectForm() {
        # Determine target project
        $projectName = ''
        if ($this.PSObject.Properties['selectedProjectName'] -and $this.selectedProjectName) { $projectName = [string]$this.selectedProjectName }
        if (-not $projectName) {
            try {
                $data = Get-PmcAllData
                $projectNames = @($data.projects | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ })
                $sel = Show-SelectList -Title "Select Project to Edit" -Options $projectNames
                if (-not $sel) { $this.GoBackOr('projectlist'); return }
                $projectName = $sel
            } catch { $this.GoBackOr('projectlist'); return }
        }

        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object { ($_.PSObject.Properties['name'] -and $_.name -eq $projectName) -or ($_ -is [string] -and $_ -eq $projectName) } | Select-Object -First 1
            if ($project -is [string]) { $project = [pscustomobject]@{ name = $project } }

            $this.DrawEditProjectForm()

            $rowStart = 6
            $defaultRoot = $Script:DefaultPickerRoot
            # Build fields with current values (avoid inline if in hashtable values)
            $nameVal       = [string]$project.name
            $descVal       = if ($project.PSObject.Properties['description']) { [string]$project.description } else { '' }
            $statusVal     = if ($project.PSObject.Properties['status']) { [string]$project.status } else { '' }
            $tagsVal       = if ($project.PSObject.Properties['tags']) { [string]::Join(', ', $project.tags) } else { '' }
            $id1Val        = if ($project.PSObject.Properties['ID1']) { [string]$project.ID1 } else { '' }
            $id2Val        = if ($project.PSObject.Properties['ID2']) { [string]$project.ID2 } else { '' }
            $projFolderVal = if ($project.PSObject.Properties['ProjFolder']) { [string]$project.ProjFolder } else { '' }
            $caaVal        = if ($project.PSObject.Properties['CAAName']) { [string]$project.CAAName } else { '' }
            $reqVal        = if ($project.PSObject.Properties['RequestName']) { [string]$project.RequestName } else { '' }
            $t2020Val      = if ($project.PSObject.Properties['T2020']) { [string]$project.T2020 } else { '' }
            $assignedVal   = if ($project.PSObject.Properties['AssignedDate']) { [string]$project.AssignedDate } else { '' }
            $dueVal        = if ($project.PSObject.Properties['DueDate']) { [string]$project.DueDate } else { '' }
            $bfVal         = if ($project.PSObject.Properties['BFDate']) { [string]$project.BFDate } else { '' }

            $fields = @(
                @{ Name='Name';        Label='Project Name:';                      X=16; Y=($rowStart + 1);  Value=$nameVal }
                @{ Name='Description'; Label='Description:';                        X=16; Y=($rowStart + 2);  Value=$descVal }
                @{ Name='Status';      Label='Status:';                             X=12; Y=($rowStart + 3);  Value=$statusVal }
                @{ Name='Tags';        Label='Tags (comma-separated):';             X=30; Y=($rowStart + 4);  Value=$tagsVal }
                @{ Name='ID1';         Label='ID1:';                                X=9;  Y=($rowStart + 5);  Value=$id1Val }
                @{ Name='ID2';         Label='ID2:';                                X=9;  Y=($rowStart + 6);  Value=$id2Val }
                @{ Name='ProjFolder';  Label='Project Folder:';                     X=20; Y=($rowStart + 7);  Value=$projFolderVal }
                @{ Name='CAAName';     Label='CAA Name:';                           X=14; Y=($rowStart + 8);  Value=$caaVal }
                @{ Name='RequestName'; Label='Request Name:';                       X=17; Y=($rowStart + 9);  Value=$reqVal }
                @{ Name='T2020';       Label='T2020:';                              X=11; Y=($rowStart + 10); Value=$t2020Val }
                @{ Name='AssignedDate';Label='Assigned Date (yyyy-MM-dd):';         X=32; Y=($rowStart + 11); Value=$assignedVal }
                @{ Name='DueDate';     Label='Due Date (yyyy-MM-dd):';              X=27; Y=($rowStart + 12); Value=$dueVal }
                @{ Name='BFDate';      Label='BF Date (yyyy-MM-dd):';               X=26; Y=($rowStart + 13); Value=$bfVal }
            )

            # Draw labels/values
            foreach ($f in $fields) { $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::Yellow(), ""); $this.terminal.WriteAt($f['X'], $f['Y'], [string]$f['Value']) }
            $this.terminal.DrawFooter([PmcUIStringCache]::FooterTabNav)

            # In-form editor with F2 pickers and active label highlight
            $active = 0
            $prevActive = -1
            while ($true) {
                $f = $fields[$active]
                if ($prevActive -ne $active) {
                    if ($prevActive -ge 0) { $pf = $fields[$prevActive]; $this.terminal.WriteAtColor(4, $pf['Y'], $pf['Label'], [PmcVT100]::Yellow(), "") }
                    $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::BgBlue(), [PmcVT100]::White())
                    $prevActive = $active
                }
                $buf = [string]($f['Value'] ?? '')
                $col = [int]$f['X']; $row = [int]$f['Y']
                [Console]::SetCursorPosition($col + $buf.Length, $row)
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq 'Enter') { break }
                elseif ($k.Key -eq 'Escape') { $this.GoBackOr('projectlist'); return }
                elseif ($k.Key -eq 'F2') {
                    $fname = [string]$f['Name']
                    if ($fname -in @('ProjFolder','CAAName','RequestName','T2020')) {
                        $dirsOnly = ($fname -eq 'ProjFolder')
                        $hint = "Pick $fname"
                        $picked = Select-ConsoleUIPathAt -app $this -Hint $hint -Col $col -Row $row -StartPath $defaultRoot -DirectoriesOnly:$dirsOnly
                        if ($null -ne $picked) {
                            $fields[$active]['Value'] = $picked
                            $this.terminal.FillArea($col, $row, $this.terminal.Width - $col - 2, 1, ' ')
                            $this.terminal.WriteAt($col, $row, [string]$picked)
                        }
                    }
                    continue
                }
                elseif ($k.Key -eq 'Tab') {
                    $isShift = ("" + $k.Modifiers) -match 'Shift'
                    if ($isShift) { $active = ($active - 1); if ($active -lt 0) { $active = $fields.Count - 1 } } else { $active = ($active + 1) % $fields.Count }
                    continue
                } elseif ($k.Key -eq 'Backspace') {
                    if ($buf.Length -gt 0) {
                        $buf = $buf.Substring(0, $buf.Length - 1)
                        $fields[$active]['Value'] = $buf
                        $this.terminal.FillArea($col, $row, $this.terminal.Width - $col - 2, 1, ' ')
                        $this.terminal.WriteAt($col, $row, $buf)
                    }
                    continue
                } else {
                    $ch = $k.KeyChar
                    if ($ch -and $ch -ne "`0") {
                        $buf += $ch
                        $fields[$active]['Value'] = $buf
                        $this.terminal.WriteAt($col + $buf.Length - 1, $row, $ch.ToString())
                    }
                }
            }

            # Collect new values
            $vals = @{}
            foreach ($f in $fields) { $vals[$f['Name']] = [string]$f['Value'] }

            foreach ($d in @('AssignedDate','DueDate','BFDate')) {
                $norm = Normalize-ConsoleUIDate $vals[$d]
                if ($null -eq $norm -and -not [string]::IsNullOrWhiteSpace([string]$vals[$d])) {
                    Show-InfoMessage -Message ("Invalid {0}. Use yyyymmdd, mmdd, +/-N, today/tomorrow/yesterday, or yyyy-MM-dd." -f $d) -Title "Validation" -Color "Red"
                    $this.GoBackOr('projectlist'); return
                }
                $vals[$d] = $norm
            }

            # Track if any changes occur
            $changed = $false
            # Handle project name change first (rename)
            $newName = ([string]$vals['Name']).Trim()
            if ([string]::IsNullOrWhiteSpace($newName)) { $newName = $projectName }
            if ($newName -ne $projectName) {
                # Validate duplicate
                $hasNew = @($data.projects | Where-Object { ($_ -is [string] -and $_ -eq $newName) -or ($_.PSObject.Properties['name'] -and $_.name -eq $newName) }).Count -gt 0
                if ($hasNew) {
                    Show-InfoMessage -Message ("Project '{0}' already exists" -f $newName) -Title "Error" -Color "Red"
                    $this.GoBackOr('projectlist'); return
                }
                # Apply rename across projects, tasks, and timelogs
                $newProjects = @()
                foreach ($p in @($data.projects)) {
                    if ($p -is [string]) {
                        $newProjects += if ($p -eq $projectName) { $newName } else { $p }
                    } else {
                        if ($p.name -eq $projectName) { $p.name = $newName }
                        $newProjects += $p
                    }
                }
                $data.projects = $newProjects
                foreach ($t in $data.tasks) { if ($t.project -eq $projectName) { $t.project = $newName } }
                if ($data.PSObject.Properties['timelogs']) { foreach ($log in $data.timelogs) { if ($log.project -eq $projectName) { $log.project = $newName } } }
                $this.selectedProjectName = $newName
                $projectName = $newName
                $changed = $true
            }

            # Apply other field updates
            foreach ($key in @('Description','Status','ID1','ID2','ProjFolder','CAAName','RequestName','T2020','AssignedDate','DueDate','BFDate','Tags')) {
                $newVal = $vals[$key]
                if ($key -eq 'Tags') {
                    $oldTags = if ($project.PSObject.Properties['tags']) { [string]::Join(', ', $project.tags) } else { '' }
                    if ($newVal -ne $oldTags) { $project | Add-Member -MemberType NoteProperty -Name 'tags' -Value (@($newVal -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) -Force; $changed = $true }
                } elseif ($key -eq 'Status') {
                    $old = if ($project.PSObject.Properties['status']) { [string]$project.status } else { '' }
                    if ($newVal -ne $old) { $project | Add-Member -MemberType NoteProperty -Name 'status' -Value $newVal -Force; $changed = $true }
                } else {
                    $old = if ($project.PSObject.Properties[$key]) { [string]$project.$key } else { '' }
                    if ($newVal -ne $old) { $project | Add-Member -MemberType NoteProperty -Name $key -Value $newVal -Force; $changed = $true }
                }
            }

            if ($changed) { Set-PmcAllData $data }
            $this.GoBackOr('projectlist')
        } catch {
        }
    }

    [void] DrawProjectInfoView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Project Info "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterProjectNameCancel)
        $this.terminal.EndFrame()
    }

    [void] HandleProjectInfoView() {
        try {
            $data = Get-PmcAllData
            $projectNames = @($data.projects | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ })
            $projectName = Show-SelectList -Title "Select Project" -Options $projectNames
            if (-not $projectName) { $this.GoBackOr('projectlist'); return }
        } catch { $this.GoBackOr('projectlist'); return }

        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object { $_.name -eq $projectName } | Select-Object -First 1
            if ($project) {
                $y = 8
                $this.terminal.WriteAtColor(4, $y++, "Project: $($project.name)", [PmcVT100]::Cyan(), "")
                $y++
                $this.terminal.WriteAt(4, $y++, "ID: $($project.id)")
                $this.terminal.WriteAt(4, $y++, "Description: $($project.description)")
                $this.terminal.WriteAt(4, $y++, "Status: $($project.status)")
                $this.terminal.WriteAt(4, $y++, "Created: $($project.created)")
                if ($project.tags) {
                    $this.terminal.WriteAt(4, $y++, "Tags: $($project.tags -join ', ')")
                }
                $y++

                # Count tasks
                $taskCount = @($data.tasks | Where-Object { $_.project -eq $projectName }).Count
                $completedCount = @($data.tasks | Where-Object { $_.project -eq $projectName -and $_.status -eq 'completed' }).Count
                $this.terminal.WriteAtColor(4, $y++, "Tasks: $taskCount total, $completedCount completed", [PmcVT100]::Green(), "")
            } else {
                $this.terminal.WriteAtColor(4, 8, "Project '$projectName' not found", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        [Console]::ReadKey($true) | Out-Null
        $this.GoBackOr('tasklist')
    }

    [void] DrawProjectDetailView([string]$ProjectName) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Project Detail "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $proj = $data.projects | Where-Object { ($_ -is [string] -and $_ -eq $ProjectName) -or ($_.PSObject.Properties['name'] -and $_.name -eq $ProjectName) } | Select-Object -First 1
            if (-not $proj) { $this.terminal.WriteAtColor(4, 6, "Project '$ProjectName' not found", [PmcVT100]::Red(), ""); return }

            $name = if ($proj -is [string]) { $proj } else { [string]$proj.name }
            $desc = if ($proj -is [string]) { '' } else { [string]$proj.description }
            $status = if ($proj -is [string]) { '' } else { [string]$proj.status }
            $created = if ($proj -is [string]) { '' } else { [string]$proj.created }

            $y = 6
            $this.terminal.WriteAtColor(4, $y++, "Name: $name", [PmcVT100]::Cyan(), "")
            if ($desc) { $this.terminal.WriteAt(4, $y++, "Description: $desc") }
            if ($status) { $this.terminal.WriteAt(4, $y++, "Status: $status") }
            if ($created) { $this.terminal.WriteAt(4, $y++, "Created: $created") }

            # Extended fields if present
            foreach ($pair in @('ID1','ID2','ProjFolder','CAAName','RequestName','T2020','AssignedDate','DueDate','BFDate')) {
                if ($proj.PSObject.Properties[$pair] -and $proj.$pair) {
                    $this.terminal.WriteAt(4, $y++, ("{0}: {1}" -f $pair, [string]$proj.$pair))
                }
            }

            # Excel/T2020 Data if present
            if ($proj.PSObject.Properties['excelData'] -and $proj.excelData) {
                $y++
                $this.terminal.WriteAtColor(4, $y++, "Excel/T2020 Data:", [PmcVT100]::Cyan(), "")
                $excelData = $proj.excelData
                if ($excelData.imported) { $this.terminal.WriteAt(6, $y++, "Imported: $($excelData.imported)") }
                if ($excelData.source) { $this.terminal.WriteAt(6, $y++, "Source: $($excelData.source)") }
                if ($excelData.sourceSheet) { $this.terminal.WriteAt(6, $y++, "Source Sheet: $($excelData.sourceSheet)") }
                if ($excelData.txtExport) { $this.terminal.WriteAt(6, $y++, "Txt Export: $($excelData.txtExport)") }

                # Show key fields
                if ($excelData.fields) {
                    $y++
                    $this.terminal.WriteAtColor(6, $y++, "Key Fields:", [PmcVT100]::Yellow(), "")
                    $keyFields = @('RequestDate','AuditType','TPName','TaxID','CASNumber','Status','DueDate')
                    foreach ($fieldName in $keyFields) {
                        if ($excelData.fields.PSObject.Properties[$fieldName] -and $excelData.fields.$fieldName) {
                            if ($y -ge $this.terminal.Height - 8) { break }
                            $value = [string]$excelData.fields.$fieldName
                            if ($value.Length -gt 40) { $value = $value.Substring(0, 37) + "..." }
                            $this.terminal.WriteAt(8, $y++, "$fieldName`: $value")
                        }
                    }
                }
            }

            # Show first 15 tasks for this project
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Tasks (first 15):", [PmcVT100]::Yellow(), "")
            $projTasks = @($data.tasks | Where-Object { $_.project -eq $name })
            $shown = 0
            foreach ($t in $projTasks) {
                if ($y -ge $this.terminal.Height - 4) { break }
                $statusIcon = if ($t.status -eq 'completed') { 'X' } else { 'o' }
                $line = ("[{0}] #{1} {2}" -f $statusIcon, $t.id, $t.text)
                $this.terminal.WriteAt(4, $y++, $line.Substring(0, [Math]::Min($line.Length, $this.terminal.Width - 6)))
                $shown++
                if ($shown -ge 15) { break }
            }
            if ($projTasks.Count -gt $shown) { $this.terminal.WriteAt(4, $y++, ("... and {0} more" -f ($projTasks.Count - $shown))) }

        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("F10/Alt:Menus  V:View Tasks  E:Edit  Esc:Back")
    }

    [void] HandleProjectDetailView() {
        # Expect $this.selectedProjectName set by caller
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'projectdetail') {
            $projName = ''
            if ($this.PSObject.Properties['selectedProjectName'] -and $this.selectedProjectName) { $projName = [string]$this.selectedProjectName } else { $active = $false; break }
            $this.DrawProjectDetailView($projName)
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'projectdetail') { return }
                continue
            }
            switch ($key.Key) {
                'V' {
                    $this.filterProject = $projName
                    $this.previousView = 'projectdetail'
                    $this.currentView = 'tasklist'
                    $this.LoadTasks()
                    return
                }
                'E' {
                    $this.previousView = 'projectdetail'
                    $this.currentView = 'projectedit'
                    return
                }
                # 'Y' (legacy rename) removed; use E to edit name
                'Escape' { $active = $false }
                default {}
            }
        }
        $this.GoBackOr('projectlist')
    }

    [void] DrawRecentProjectsView() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Recent Projects "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            # Get recent tasks and extract unique projects
            $recentTasks = @($data.tasks | Where-Object { $_.project } | Sort-Object { if ($_.modified) { [DateTime]$_.modified } else { [DateTime]::MinValue } } -Descending | Select-Object -First 50)
            $recentProjects = @($recentTasks | Select-Object -ExpandProperty project -Unique | Select-Object -First 10)

            if ($recentProjects.Count -gt 0) {
                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Recently Used Projects:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($projectName in $recentProjects) {
                    $project = $data.projects | Where-Object { $_.name -eq $projectName } | Select-Object -First 1
                    $taskCount = @($data.tasks | Where-Object { $_.project -eq $projectName -and $_.status -ne 'completed' }).Count
                    if ($project) {
                        $this.terminal.WriteAtColor(4, $y++, "• $projectName", [PmcVT100]::Yellow(), "")
                        $this.terminal.WriteAt(6, $y++, "  $($project.description) ($taskCount active tasks)")
                    } else {
                        $this.terminal.WriteAt(4, $y++, "• $projectName ($taskCount active tasks)")
                    }
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "No recent projects found", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleRecentProjectsView() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'projectrecent') {
            $this.DrawRecentProjectsView()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'projectrecent') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawHelpBrowser() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Browser "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "PMC Task Management System - Help", [PmcVT100]::Cyan(), "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Navigation:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "F10 or Alt+Letter  - Open menus")
        $this.terminal.WriteAt(6, $y++, "Arrow Keys         - Navigate menus/lists")
        $this.terminal.WriteAt(6, $y++, "Enter              - Select item")
        $this.terminal.WriteAt(6, $y++, "Esc                - Cancel/Go back")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Quick Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "Alt+T  - Task menu")
        $this.terminal.WriteAt(6, $y++, "Alt+P  - Project menu")
        $this.terminal.WriteAt(6, $y++, "Alt+V  - View menu")
        $this.terminal.WriteAt(6, $y++, "Alt+M  - Time menu")
        $this.terminal.WriteAt(6, $y++, "Alt+O  - Tools menu")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "For more help:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "Use Get-Command *Pmc* to see all available PowerShell commands")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleHelpBrowser() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'helpbrowser') {
            $this.DrawHelpBrowser()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'helpbrowser') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawHelpCategories() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Categories "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Available Help Topics:", [PmcVT100]::Cyan(), "")
        $y++

        $categories = @(
            @{Name="Tasks"; Desc="Creating, editing, and managing tasks"}
            @{Name="Projects"; Desc="Project organization and tracking"}
            @{Name="Time Tracking"; Desc="Time logging and timer functions"}
            @{Name="Views"; Desc="Different task views (Agenda, Kanban, etc.)"}
            @{Name="Focus"; Desc="Focus mode for concentrated work"}
            @{Name="Dependencies"; Desc="Task dependencies and relationships"}
            @{Name="Backup/Restore"; Desc="Data backup and recovery"}
        )

        foreach ($cat in $categories) {
            $this.terminal.WriteAtColor(4, $y++, "• $($cat.Name)", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(6, $y++, "  $($cat.Desc)")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleHelpCategories() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'helpcategories') {
            $this.DrawHelpCategories()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'helpcategories') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    [void] DrawHelpSearch() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Search "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Search for:", [PmcVT100]::Yellow(), "")

        $this.terminal.DrawFooter("Enter search term | Esc:Cancel")
        $this.terminal.EndFrame()
    }

    [void] HandleHelpSearch() {
        $fields = @(
            @{Name='q'; Label='Search term'; Required=$true}
        )
        $res = Show-InputForm -Title "Help Search" -Fields $fields
        if ($null -eq $res) { $this.GoBackOr('tasklist'); return }
        $searchTerm = [string]$res['q']
        if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
            $y = 8
            $this.terminal.WriteAtColor(4, $y++, "Search results for '$searchTerm':", [PmcVT100]::Cyan(), "")
            $y++

            # Enhanced keyword matching
            $helpTopics = @{
                'task|todo|add|create' = "Task Management - Add, edit, complete, delete tasks (Alt+T)"
                'project|organize' = "Project Organization - Create and manage projects (Alt+P)"
                'time|timer|track|log' = "Time Tracking - Track time on tasks, view reports (Alt+M)"
                'view|agenda|kanban|burndown' = "Views - Agenda, Kanban, Burndown charts (Alt+V)"
                'focus|concentrate' = "Focus Mode - Set focus for concentrated work (Alt+C)"
                'backup|restore|data' = "File Operations - Backup and restore data (Alt+F)"
                'undo|redo|revert' = "Edit Operations - Undo/redo changes (Alt+E)"
                'dependency|depends|block' = "Dependencies - Manage task dependencies (Alt+D)"
                'priority|urgent|high|low' = "Priority - Set task priority (P key in task list)"
                'due|date|deadline' = "Due Dates - Set task due dates (T key in task detail)"
                'search|find|filter' = "Search - Find tasks by text (/ key in task list)"
                'sort|order' = "Sorting - Sort tasks by various criteria (S key in task list)"
                'multi|bulk|batch' = "Multi-Select - Bulk operations on tasks (M key in task list)"
                'complete|done|finish' = "Complete Tasks - Mark tasks as done (D key or Space)"
                'delete|remove' = "Delete Tasks - Remove tasks (Delete key)"
                'help|keys|shortcuts' = "Keyboard Shortcuts - Press H for help browser"
            }

            $matches = @()
            $lowerSearch = $searchTerm.ToLower()
            foreach ($pattern in $helpTopics.Keys) {
                if ($lowerSearch -match $pattern) {
                    $matches += $helpTopics[$pattern]
                }
            }

            if ($matches.Count -gt 0) {
                foreach ($match in $matches) {
                    $this.terminal.WriteAt(4, $y++, "• $match")
                }
            } else {
                $this.terminal.WriteAtColor(4, $y, "No help topics found for '$searchTerm'", [PmcVT100]::Yellow(), "")
            }

            $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
            $k = [Console]::ReadKey($true)
            $ga = $this.CheckGlobalKeys($k)
            if ($ga) {
                if ($ga -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($ga)
                if ($this.currentView -ne 'helpsearch') { return }
            }
        }

        $this.GoBackOr('tasklist')
    }

    [void] DrawAboutPMC() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " About PMC "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "PMC - PowerShell Project Management Console", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "A comprehensive task and project management system")
        $this.terminal.WriteAt(4, $y++, "built entirely in PowerShell")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Features:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "• Task management with priorities and due dates")
        $this.terminal.WriteAt(6, $y++, "• Project organization")
        $this.terminal.WriteAt(6, $y++, "• Time tracking and reporting")
        $this.terminal.WriteAt(6, $y++, "• Multiple views (Agenda, Kanban, etc.)")
        $this.terminal.WriteAt(6, $y++, "• Focus mode")
        $this.terminal.WriteAt(6, $y++, "• Task dependencies")
        $this.terminal.WriteAt(6, $y++, "• Automatic backups")
        $this.terminal.WriteAt(6, $y++, "• Undo/Redo support")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Version:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "TUI Interface - October 2025")

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleAboutPMC() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'helpabout') {
            $this.DrawAboutPMC()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'helpabout') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Dependency Graph
    [void] DrawDependencyGraph() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Dependency Graph "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $tasksWithDeps = $data.tasks | Where-Object { $_.dependencies -and $_.dependencies.Count -gt 0 }

            if ($tasksWithDeps.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No task dependencies found", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, $y++, "Task Dependencies:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($task in $tasksWithDeps) {
                    $textOrTitle = if ($task.text) { $task.text } else { $task.title }
                    $this.terminal.WriteAtColor(4, $y++, "Task #$($task.id): $textOrTitle", [PmcVT100]::White(), "")
                    $this.terminal.WriteAt(6, $y++, "└─> Depends on:")

                    $depCount = $task.dependencies.Count
                    for ($i = 0; $i -lt $depCount; $i++) {
                        $depId = $task.dependencies[$i]
                        $isLast = ($i -eq $depCount - 1)
                        $prefix = if ($isLast) { "    └─> " } else { "    ├─> " }

                        $depTask = $data.tasks | Where-Object { $_.id -eq $depId } | Select-Object -First 1
                        if ($depTask) {
                            $depStatus = $depTask.status
                            $statusIcon = switch ($depStatus) {
                                'done' { 'X' }
                                'completed' { 'X' }
                                'in-progress' { '...' }
                                'blocked' { 'BLOCKED' }
                                default { '-' }
                            }
                            $color = switch ($depStatus) {
                                'done' { [PmcVT100]::Green() }
                                'completed' { [PmcVT100]::Green() }
                                'in-progress' { [PmcVT100]::Yellow() }
                                'blocked' { [PmcVT100]::Red() }
                                default { [PmcVT100]::White() }
                            }
                            $depTextTitle = if ($depTask.text) { $depTask.text } else { $depTask.title }
                            $depText = "$prefix Task #${depId}: $depTextTitle $statusIcon"
                            $this.terminal.WriteAtColor(8, $y++, $depText, $color, "")
                        } else {
                            $this.terminal.WriteAtColor(8, $y++, "$prefix Task #${depId}: [Missing task] ERROR", [PmcVT100]::Red(), "")
                        }
                    }
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error loading dependencies: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleDependencyGraph() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'depgraph') {
            $this.DrawDependencyGraph()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'depgraph') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Burndown Chart
    [void] DrawBurndownChart() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Burndown Chart "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $currentProject = if ($this.filterProject) { $this.filterProject } else { $null }

            # Filter tasks by project if needed
            $projectTasks = if ($currentProject) {
                $data.tasks | Where-Object { $_.project -eq $currentProject }
            } else {
                $data.tasks
            }

            # Calculate burndown metrics
            $totalTasks = $projectTasks.Count
            $completedTasks = ($projectTasks | Where-Object { $_.status -eq 'done' -or $_.status -eq 'completed' }).Count
            $inProgressTasks = ($projectTasks | Where-Object { $_.status -eq 'in-progress' }).Count
            $blockedTasks = ($projectTasks | Where-Object { $_.status -eq 'blocked' }).Count
            $todoTasks = ($projectTasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' -or -not $_.status }).Count

            $projectTitle = if ($currentProject) { "Project: $currentProject" } else { "All Projects" }
            $this.terminal.WriteAtColor(4, $y++, $projectTitle, [PmcVT100]::Cyan(), "")
            $y++

            $this.terminal.WriteAtColor(4, $y++, "Task Summary:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Total Tasks:      $totalTasks", [PmcVT100]::White(), "")
            $this.terminal.WriteAtColor(6, $y++, "Completed:        $completedTasks", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(6, $y++, "In Progress:      $inProgressTasks", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Blocked:          $blockedTasks", [PmcVT100]::Red(), "")
            $this.terminal.WriteAtColor(6, $y++, "To Do:            $todoTasks", [PmcVT100]::White(), "")
            $y++

            # Calculate completion percentage
            $completionPct = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 1) } else { 0 }
            $this.terminal.WriteAtColor(4, $y++, "Completion: $completionPct%", [PmcVT100]::Cyan(), "")
            $y++

            # Draw simple bar chart
            $barWidth = 50
            $completedWidth = if ($totalTasks -gt 0) { [math]::Floor(($completedTasks / $totalTasks) * $barWidth) } else { 0 }
            $inProgressWidth = if ($totalTasks -gt 0) { [math]::Floor(($inProgressTasks / $totalTasks) * $barWidth) } else { 0 }
            $remainingWidth = $barWidth - $completedWidth - $inProgressWidth

            $bar = ""
            if ($completedWidth -gt 0) { $bar += [string]::new('█', $completedWidth) }
            if ($inProgressWidth -gt 0) { $bar += [string]::new('▒', $inProgressWidth) }
            if ($remainingWidth -gt 0) { $bar += [string]::new('░', $remainingWidth) }

            $this.terminal.WriteAt(4, $y++, "Progress:")
            $this.terminal.WriteAt(4, $y++, "[$bar]")
            $y++

            # Legend
            $this.terminal.WriteAtColor(4, $y++, "Legend:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "█ Completed", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(6, $y++, "▒ In Progress", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "░ To Do", [PmcVT100]::White(), "")

        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error generating burndown chart: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleBurndownChart() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'burndownview') {
            $this.DrawBurndownChart()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'burndownview') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Tools Menu - Start Review
    [void] DrawStartReview() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()

        $title = " Start Review "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $reviewableTasks = $data.tasks | Where-Object {
                $_.status -eq 'review' -or $_.status -eq 'done'
            } | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, due

            if ($reviewableTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No tasks available for review", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, $y++, "Tasks for Review:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($task in $reviewableTasks) {
                    $status = $task.status
                    $color = switch ($status) {
                        'done' { [PmcVT100]::Green() }
                        'review' { [PmcVT100]::Yellow() }
                        default { [PmcVT100]::White() }
                    }

                    $dueStr = if ($task.due) { " (Due: $($task.due))" } else { "" }
                    $projectStr = if ($task.project) { " [$($task.project)]" } else { "" }

                    $this.terminal.WriteAtColor(4, $y++, "#$($task.id): $($task.title)$projectStr$dueStr", $color, "")

                    if ($y -gt $this.terminal.Height - 4) { break }
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error loading review tasks: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleStartReview() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'toolsreview') {
            $this.DrawStartReview()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'toolsreview') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Tools Menu - Project Wizard (expanded to collect full project fields)
    [void] DrawProjectWizard() {
        $this.terminal.BeginFrame()
        # Reuse the project create form layout for consistency
        $this.DrawProjectCreateForm(0)
        $this.terminal.EndFrame()
    }

    [void] HandleProjectWizard() {
        $this.DrawProjectWizard()

        $inputs = @{}
        $rowStart = 6
        $defaultRoot = $Script:DefaultPickerRoot
        $app = $this

        function Read-LineAt([int]$col, [int]$row, [bool]$required=$false) {
            [Console]::SetCursorPosition($col, $row)
            [Console]::Write([PmcVT100]::Yellow())
            $buf = ''
            while ($true) {
                $k = [Console]::ReadKey($true)
                switch ($k.Key) {
                    'Escape' { [Console]::Write([PmcVT100]::Reset()); return $null }
                    'Enter' {
                        [Console]::Write([PmcVT100]::Reset())
                        if ($required -and [string]::IsNullOrWhiteSpace($buf)) { return $null }
                        return $buf.Trim()
                    }
                    'Backspace' {
                        if ($buf.Length -gt 0) {
                            $buf = $buf.Substring(0, $buf.Length - 1)
                            [Console]::SetCursorPosition($col, $row)
                            [Console]::Write((' ' * ($buf.Length + 1)))
                            [Console]::SetCursorPosition($col, $row)
                            [Console]::Write($buf)
                        }
                    }
                    default {
                        $ch = $k.KeyChar
                        if ($ch -and $ch -ne "`0") { $buf += $ch; [Console]::Write($ch) }
                    }
                }
            }
        }

        # Step 1: Name (required)
        $inputs.Name = Read-LineAt 28 ($rowStart + 0) $true
        if ([string]::IsNullOrWhiteSpace($inputs.Name)) { $this.GoBackOr('tasklist'); return }

        # Step 2: Description
        $inputs.Description = Read-LineAt 16 ($rowStart + 1)
        if ($null -eq $inputs.Description) { $this.GoBackOr('tasklist'); return }
        $this.DrawProjectCreateForm(2); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs

        # Step 3: IDs
        $inputs.ID1 = Read-LineAt 9 ($rowStart + 2)
        if ($null -eq $inputs.ID1) { $this.GoBackOr('tasklist'); return }
        $this.DrawProjectCreateForm(3); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs
        $inputs.ID2 = Read-LineAt 9 ($rowStart + 3)
        if ($null -eq $inputs.ID2) { $this.GoBackOr('tasklist'); return }
        $this.DrawProjectCreateForm(4); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs

        # Step 4: Paths (with pickers)
        $inputs.ProjFolder = Select-ConsoleUIPathAt -app $app -Hint "Project Folder (Enter to pick)" -Col 20 -Row ($rowStart + 4) -StartPath $defaultRoot -DirectoriesOnly:$true
        $this.DrawProjectCreateForm(5); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs
        $inputs.CAAName = Select-ConsoleUIPathAt -app $app -Hint "CAA (Enter to pick)" -Col 14 -Row ($rowStart + 5) -StartPath $defaultRoot -DirectoriesOnly:$false
        $this.DrawProjectCreateForm(6); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs
        $inputs.RequestName = Select-ConsoleUIPathAt -app $app -Hint "Request (Enter to pick)" -Col 17 -Row ($rowStart + 6) -StartPath $defaultRoot -DirectoriesOnly:$false
        $this.DrawProjectCreateForm(7); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs
        $inputs.T2020 = Select-ConsoleUIPathAt -app $app -Hint "T2020 (Enter to pick)" -Col 11 -Row ($rowStart + 7) -StartPath $defaultRoot -DirectoriesOnly:$false
        $this.DrawProjectCreateForm(8); Draw-ConsoleUIProjectFormValues -app $app -RowStart $rowStart -Inputs $inputs

        # Step 5: Dates (validate yyyy-MM-dd)
        $inputs.AssignedDate = Read-LineAt 32 ($rowStart + 8); if ($null -eq $inputs.AssignedDate) { $this.GoBackOr('tasklist'); return }
        $inputs.DueDate      = Read-LineAt 27 ($rowStart + 9); if ($null -eq $inputs.DueDate)      { $this.GoBackOr('tasklist'); return }
        $inputs.BFDate       = Read-LineAt 26 ($rowStart + 10); if ($null -eq $inputs.BFDate)       { $this.GoBackOr('tasklist'); return }

        foreach ($pair in @(@{k='AssignedDate'; v=$inputs.AssignedDate}, @{k='DueDate'; v=$inputs.DueDate}, @{k='BFDate'; v=$inputs.BFDate})) {
            $norm = Normalize-ConsoleUIDate $pair.v
            if ($null -eq $norm -and -not [string]::IsNullOrWhiteSpace([string]$pair.v)) {
                Show-InfoMessage -Message ("Invalid {0}. Use yyyymmdd, mmdd, +/-N, today/tomorrow/yesterday, or yyyy-MM-dd." -f $pair.k) -Title "Validation" -Color "Red"
                $this.GoBackOr('tasklist')
                return
            }
            switch ($pair.k) {
                'AssignedDate' { $inputs.AssignedDate = $norm }
                'DueDate'      { $inputs.DueDate = $norm }
                'BFDate'       { $inputs.BFDate = $norm }
            }
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.projects) { $data.projects = @() }

            # Normalize any legacy entries
            try {
                $normalized = @()
                foreach ($p in @($data.projects)) {
                    if ($p -is [string]) {
                        $normalized += [pscustomobject]@{
                            id = [guid]::NewGuid().ToString()
                            name = $p
                            description = ''
                            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                            status = 'active'
                            tags = @()
                        }
                    } else { $normalized += $p }
                }
                $data.projects = $normalized
            } catch {}

            # Duplicate project name check
            $exists = @($data.projects | Where-Object { $_.PSObject.Properties['name'] -and $_.name -eq $inputs.Name })
            if ($exists.Count -gt 0) {
                Show-InfoMessage -Message ("Project '{0}' already exists" -f $inputs.Name) -Title "Error" -Color "Red"
                $this.GoBackOr('tasklist')
                return
            }

            # Build project object using extended fields schema
            $newProject = [pscustomobject]@{
                id = [guid]::NewGuid().ToString()
                name = $inputs.Name
                description = $inputs.Description
                ID1 = $inputs.ID1
                ID2 = $inputs.ID2
                ProjFolder = $inputs.ProjFolder
                AssignedDate = $inputs.AssignedDate
                DueDate = $inputs.DueDate
                BFDate = $inputs.BFDate
                CAAName = $inputs.CAAName
                RequestName = $inputs.RequestName
                T2020 = $inputs.T2020
                icon = ''
                color = 'Gray'
                sortOrder = 0
                aliases = @()
                isArchived = $false
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = 'active'
                tags = @()
            }

            $data.projects += $newProject
            Set-PmcAllData $data
            Show-InfoMessage -Message ("Project '{0}' created" -f $inputs.Name) -Title "Success" -Color "Green"
        } catch {
            Show-InfoMessage -Message ("Failed to create project: {0}" -f $_) -Title "Error" -Color "Red"
        }

        $this.GoBackOr('projectlist')
        $this.DrawLayout()
    }

    # (removed) Tools - Templates

    # Tools - Statistics
    [void] DrawStatistics() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Statistics "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        try {
            $data = Get-PmcAllData
            $total = $data.tasks.Count
            $completed = ($data.tasks | Where-Object { $_.status -eq 'done' -or $_.status -eq 'completed' }).Count
            $inProgress = ($data.tasks | Where-Object { $_.status -eq 'in-progress' }).Count
            $blocked = ($data.tasks | Where-Object { $_.status -eq 'blocked' }).Count
            $todo = ($data.tasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' -or (-not $_.status) }).Count

            $this.terminal.WriteAtColor(4, $y++, "Task Statistics:", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAt(4, $y++, "Total Tasks:      $total")
            $this.terminal.WriteAtColor(4, $y++, "Completed:        $completed", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(4, $y++, "In Progress:      $inProgress", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(4, $y++, "To Do:            $todo", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(4, $y++, "Blocked:          $blocked", [PmcVT100]::Red(), "")
            $y++
            $completionRate = if ($total -gt 0) { [math]::Round(($completed / $total) * 100, 1) } else { 0 }
            $this.terminal.WriteAtColor(4, $y++, "Completion Rate: $completionRate%", [PmcVT100]::Cyan(), "")

            # Validation check
            $sum = $completed + $inProgress + $todo + $blocked
            if ($sum -ne $total) {
                $other = $total - $sum
                $this.terminal.WriteAtColor(4, $y++, "Other:            $other", [PmcVT100]::Gray(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }
        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleStatistics() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'toolsstatistics') {
            $this.DrawStatistics()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'toolsstatistics') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Tools - Velocity
    [void] DrawVelocity() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Team Velocity "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        try {
            $data = Get-PmcAllData
            $now = Get-Date
            $lastWeek = $now.AddDays(-7)
            $recentCompleted = ($data.tasks | Where-Object {
                ($_.status -eq 'done' -or $_.status -eq 'completed') -and $_.completed -and ([DateTime]$_.completed) -gt $lastWeek
            }).Count
            $this.terminal.WriteAtColor(4, $y++, "Velocity Metrics (Last 7 Days):", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Tasks Completed:  $recentCompleted", [PmcVT100]::Green(), "")
            $avgPerDay = [math]::Round($recentCompleted / 7, 1)
            $this.terminal.WriteAt(4, $y++, "Avg Per Day:      $avgPerDay")
            $projectedWeek = [math]::Round($avgPerDay * 7, 0)
            $this.terminal.WriteAt(4, $y++, "Projected/Week:   $projectedWeek")
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }
        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleVelocity() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'toolsvelocity') {
            $this.DrawVelocity()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'toolsvelocity') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # Tools - Preferences
    [void] DrawPreferences() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Preferences "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        try {
            $cfg = Get-PmcConfig
            $defView = try { [string]$cfg.Behavior.DefaultView } catch { 'tasklist' }
            $autoSave = try { [bool]$cfg.Behavior.AutoSave } catch { $true }
            $showCompleted = try { [bool]$cfg.Behavior.ShowCompleted } catch { $true }
            $dateFmt = try { [string]$cfg.Behavior.DateFormat } catch { 'yyyy-MM-dd' }
            $this.terminal.WriteAtColor(4, $y++, "PMC Preferences:", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAt(4, $y++, ("1. Default view:         {0}" -f $defView))
            $autoSaveStr = 'Disabled'; if ($autoSave) { $autoSaveStr = 'Enabled' }
            $showCompletedStr = 'No'; if ($showCompleted) { $showCompletedStr = 'Yes' }
            $this.terminal.WriteAt(4, $y++, ("2. Auto-save:            {0}" -f $autoSaveStr))
            $this.terminal.WriteAt(4, $y++, ("3. Show completed:       {0}" -f $showCompletedStr))
            $this.terminal.WriteAt(4, $y++, ("4. Date format:          {0}" -f $dateFmt))
            $this.terminal.DrawFooter("Any key: Edit  F10/Alt:Menus  Esc:Back")
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error loading preferences: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }
        $this.terminal.EndFrame()
    }

    [void] HandlePreferences() {
        # Show current
        $this.DrawPreferences()
        $key = [Console]::ReadKey($true)
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            if ($globalAction -eq 'app:exit') { $this.running = $false; return }
            $this.ProcessMenuAction($globalAction)
            return
        }
        if ($key.Key -eq 'Escape') { $this.GoBackOr('tasklist'); return }

        # Edit via form (no initial values supported; blanks keep current)
        $cfg = Get-PmcConfig
        $defView = try { [string]$cfg.Behavior.DefaultView } catch { 'tasklist' }
        $autoSave = try { [bool]$cfg.Behavior.AutoSave } catch { $true }
        $showCompleted = try { [bool]$cfg.Behavior.ShowCompleted } catch { $true }
        $dateFmt = try { [string]$cfg.Behavior.DateFormat } catch { 'yyyy-MM-dd' }

        $views = @('tasklist','todayview','agendaview')
        $fields = @(
            @{Name='defaultView'; Label=("Default view (current: {0})" -f $defView); Required=$false; Type='text'}
            @{Name='autoSave'; Label=("Auto-save (true/false) (current: {0})" -f ($autoSave.ToString().ToLower())); Required=$false; Type='text'}
            @{Name='showCompleted'; Label=("Show completed (true/false) (current: {0})" -f ($showCompleted.ToString().ToLower())); Required=$false; Type='text'}
            @{Name='dateFormat'; Label=("Date format (current: {0})" -f $dateFmt); Required=$false; Type='text'}
        )

        $result = Show-InputForm -Title "Edit Preferences" -Fields $fields
        if ($null -eq $result) { $this.GoBackOr('tasklist'); return }

        try {
            if (-not $cfg.ContainsKey('Behavior')) { $cfg['Behavior'] = @{} }

            # Validate defaultView
            $newView = $defView
            if ($result['defaultView']) {
                if ($views -contains $result['defaultView']) { $newView = $result['defaultView'] }
                else { Show-InfoMessage -Message "Invalid default view; keeping $defView" -Title "Validation" -Color "Yellow" }
            }
            $cfg.Behavior.DefaultView = $newView

            # Validate booleans
            function Parse-Bool([string]$s, [bool]$fallback) {
                if ([string]::IsNullOrWhiteSpace($s)) { return $fallback }
                $sl = $s.ToLower()
                if ($sl -eq 'true' -or $sl -eq 'false') { return ($sl -eq 'true') }
                Show-InfoMessage -Message ("Invalid boolean: '{0}'" -f $s) -Title "Validation" -Color "Yellow"
                return $fallback
            }
            $cfg.Behavior.AutoSave = Parse-Bool ($result['autoSave'] + '') $autoSave
            $cfg.Behavior.ShowCompleted = Parse-Bool ($result['showCompleted'] + '') $showCompleted

            # Date format: accept non-empty; else keep
            if ($result['dateFormat']) { $cfg.Behavior.DateFormat = ($result['dateFormat'] + '') }
            else { $cfg.Behavior.DateFormat = $dateFmt }

            Save-PmcConfig $cfg
            Show-InfoMessage -Message "Preferences updated" -Title "Success" -Color "Green"
        } catch {
            Show-InfoMessage -Message "Failed to save preferences: $_" -Title "Error" -Color "Red"
        }

        $this.GoBackOr('tasklist')
    }

    # Tools - Manage Aliases
    [void] DrawManageAliases() {
        $this.terminal.BeginFrame()
        $this.menuSystem.DrawMenuBar()
        $title = " Manage Aliases "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Command Aliases:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "ls     = List tasks")
        $this.terminal.WriteAt(4, $y++, "add    = Add task")
        $this.terminal.WriteAt(4, $y++, "done   = Complete task")
        $this.terminal.WriteAt(4, $y++, "rm     = Delete task")
        $this.terminal.DrawFooter([PmcUIStringCache]::FooterMenusEscBack)
        $this.terminal.EndFrame()
    }

    [void] HandleManageAliases() {
        $active = $true
        while ($active -and $this.running -and $this.currentView -eq 'toolsaliases') {
            $this.DrawManageAliases()
            $key = [Console]::ReadKey($true)
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                if ($globalAction -eq 'app:exit') { $this.running = $false; return }
                $this.ProcessMenuAction($globalAction)
                if ($this.currentView -ne 'toolsaliases') { return }
                continue
            }
            if ($key.Key -eq 'Escape') { $active = $false }
        }
        $this.GoBackOr('tasklist')
    }

    # (removed) Tools - Query Browser

    # Tools - Weekly Report
    [void] DrawWeeklyReport([int]$weekOffset = 0) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        try {
            $data = Get-PmcAllData
            $logs = if ($data.PSObject.Properties['timelogs']) { $data.timelogs } else { @() }

            # Calculate week start (Monday)
            $today = Get-Date
            $daysFromMonday = ($today.DayOfWeek.value__ + 6) % 7
            $thisMonday = $today.AddDays(-$daysFromMonday).Date
            $weekStart = $thisMonday.AddDays($weekOffset * 7)
            $weekEnd = $weekStart.AddDays(4)

            $weekHeader = "Week of {0} - {1}" -f $weekStart.ToString('MMM dd'), $weekEnd.ToString('MMM dd, yyyy')

            # Add indicator for current/past/future week
            $weekIndicator = ''
            if ($weekOffset -eq 0) {
                $weekIndicator = ' (This Week)'
            } elseif ($weekOffset -lt 0) {
                $weeks = [Math]::Abs($weekOffset)
                $plural = if ($weeks -gt 1) { 's' } else { '' }
                $weekIndicator = " ($weeks week$plural ago)"
            } else {
                $plural = if ($weekOffset -gt 1) { 's' } else { '' }
                $weekIndicator = " ($weekOffset week$plural from now)"
            }

            $this.terminal.WriteAtColor(4, 4, "TIME REPORT", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(4, 5, "$weekHeader$weekIndicator", [PmcVT100]::Yellow(), "")

            # Filter logs for the week
            $weekLogs = @()
            for ($d = 0; $d -lt 5; $d++) {
                $dayDate = $weekStart.AddDays($d).ToString('yyyy-MM-dd')
                $dayLogs = $logs | Where-Object { $_.date -eq $dayDate }
                $weekLogs += $dayLogs
            }

            if ($weekLogs.Count -eq 0) {
                $this.terminal.WriteAtColor(4, 7, "No time entries for this week", [PmcVT100]::Yellow(), "")
            } else {
                # Group by project/indirect code
                $grouped = @{}
                foreach ($log in $weekLogs) {
                    $key = ''
                    if ($log.id1) {
                        $key = "#$($log.id1)"
                    } else {
                        $name = $log.project
                        if (-not $name) { $name = 'Unknown' }
                        $key = $name
                    }

                    if (-not $grouped.ContainsKey($key)) {
                        $name = ''
                        $id1 = ''
                        if ($log.id1) { $id1 = $log.id1; $name = '' } else { $name = ($log.project); if (-not $name) { $name = 'Unknown' } }
                        $grouped[$key] = @{
                            Name = $name
                            ID1 = $id1
                            Mon = 0; Tue = 0; Wed = 0; Thu = 0; Fri = 0; Total = 0
                        }
                    }

                    $logDate = [datetime]$log.date
                    $dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7
                    $hours = [Math]::Round($log.minutes / 60.0, 1)

                    switch ($dayIndex) {
                        0 { $grouped[$key].Mon += $hours }
                        1 { $grouped[$key].Tue += $hours }
                        2 { $grouped[$key].Wed += $hours }
                        3 { $grouped[$key].Thu += $hours }
                        4 { $grouped[$key].Fri += $hours }
                    }
                    $grouped[$key].Total += $hours
                }

                # Draw table header
                $y = 7
                $header = "Name                 ID1   Mon    Tue    Wed    Thu    Fri    Total"
                $this.terminal.WriteAtColor(4, $y++, $header, [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(4, $y++, "─" * 75, [PmcVT100]::Gray(), "")

                # Draw rows
                $grandTotal = 0
                foreach ($entry in ($grouped.GetEnumerator() | Sort-Object Key)) {
                    $d = $entry.Value
                    $row = "{0,-20} {1,-5} {2,6:F1} {3,6:F1} {4,6:F1} {5,6:F1} {6,6:F1} {7,8:F1}" -f `
                        $d.Name, $d.ID1, $d.Mon, $d.Tue, $d.Wed, $d.Thu, $d.Fri, $d.Total
                    $this.terminal.WriteAtColor(4, $y++, $row, [PmcVT100]::Yellow(), "")
                    $grandTotal += $d.Total
                }

                # Draw footer
                $this.terminal.WriteAtColor(4, $y++, "─" * 75, [PmcVT100]::Gray(), "")
                $totalRow = "                                                          Total: {0,8:F1}" -f $grandTotal
                $this.terminal.WriteAtColor(4, $y++, $totalRow, [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error generating weekly report: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("=:Next Week | -:Previous Week | Any other key to return")
    }

    [void] HandleWeeklyReport() {
        [int]$weekOffset = 0
        $active = $true

        while ($active) {
            $this.DrawWeeklyReport($weekOffset)
            $key = [Console]::ReadKey($true)

            switch ($key.KeyChar) {
                '=' {
                    $weekOffset++
                }
                '-' {
                    $weekOffset--
                }
                default {
                    $active = $false
                }
            }

            if ($key.Key -eq 'Escape') {
                $active = $false
            }
        }

        $this.GoBackOr('timelist')
    }

    [void] Shutdown() {
        $this.terminal.Cleanup()
        # Restore prior error preference
        try { if ($PSBoundParameters -ne $null) { } } catch { }
        try { if ($Script:_PrevErrorActionPreference) { $ErrorActionPreference = $Script:_PrevErrorActionPreference } } catch {}
    }
}

# Theme tools (persistent)
function HandleThemeTool([PmcConsoleUIApp] $this) {
    $active = $true
    while ($active -and $this.running -and $this.currentView -eq 'toolstheme') {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Theme Tools "
        $tx = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$tx, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "A: Apply Theme (picker)", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(4, $y++, "E: Edit/Apply (picker)", [PmcVT100]::Cyan(), "")
        $this.terminal.DrawFooter("A/E:Action  F10/Alt:Menus  Esc:Back")

        $key = [Console]::ReadKey($true)
        $ga = $this.CheckGlobalKeys($key)
        if ($ga) {
            if ($ga -eq 'app:exit') { $this.running = $false; return }
            $this.ProcessMenuAction($ga)
            if ($this.currentView -ne 'toolstheme') { return }
            continue
        }

        switch ($key.Key) {
            'Escape' { $active = $false; break }
            'E' {
                try {
                    $ctx = New-Object PmcCommandContext 'theme','edit'
                    Edit-PmcTheme -Context $ctx
                    Initialize-PmcThemeSystem
                    Show-InfoMessage -Message 'Theme updated' -Title 'Theme' -Color 'Green'
                } catch {
                    Show-InfoMessage -Message ("Theme editor error: {0}" -f $_) -Title 'Theme' -Color 'Red'
                }
            }
            'A' {
                $choices = @('Enter Hex...','default (#33aaff)','ocean','lime','purple','slate','matrix','amber','synthwave','high-contrast')
                $sel = Show-SelectList -Title "Select Theme" -Options $choices -DefaultValue 'default (#33aaff)'
                if (-not $sel) { continue }
                $arg = ''
                if ($sel -eq 'Enter Hex...') {
                    $res = Show-InputForm -Title "Enter Theme Color" -Fields @(@{Name='hex'; Label='#RRGGBB'; Required=$true})
                    if ($res -and $res['hex']) { $arg = [string]$res['hex'] } else { continue }
                } elseif ($sel -like 'default*') {
                    $arg = 'default'
                } else {
                    $arg = $sel
                }
                try {
                    $ctx = New-Object PmcCommandContext 'theme','apply'
                    $ctx.FreeText = @($arg)
                    Apply-PmcTheme -Context $ctx
                    Initialize-PmcThemeSystem
                    Show-InfoMessage -Message ("Theme applied: {0}" -f $arg) -Title 'Theme' -Color 'Green'
                } catch {
                    Show-InfoMessage -Message ("Apply failed: {0}" -f $_) -Title 'Theme' -Color 'Red'
                }
            }
            default {}
        }
    }
    $this.GoBackOr('tasklist')
}


# Initialize performance systems
[PmcStringCache]::Initialize()

# Helper functions
function Get-PmcTerminal { return [PmcSimpleTerminal]::GetInstance() }
function Get-PmcSpaces([int]$count) { return [PmcStringCache]::GetSpaces($count) }
function Get-PmcStringBuilder([int]$capacity = 256) { return [PmcStringBuilderPool]::Get($capacity) }
function Return-PmcStringBuilder([StringBuilder]$sb) { [PmcStringBuilderPool]::Return($sb) }

# Main entry point
function Start-PmcConsoleUI {
    $app = $null
    try {
        Write-Host "Starting PMC ConsoleUI..." -ForegroundColor Green
        $app = [PmcConsoleUIApp]::new()
        $app.Initialize()
        # Exit gracefully in headless/non-interactive environments (CI/sandbox)
        if (-not (Test-ConsoleInteractive)) {
            try { $app.DrawLayout() } catch {}
            $app.Shutdown()
            Write-Host "PMC ConsoleUI exited (non-interactive terminal detected)." -ForegroundColor Yellow
            return
        }
        $app.Run()
        $app.Shutdown()
        Write-Host "PMC ConsoleUI exited." -ForegroundColor Green
    } catch {
        Write-Host "Failed to start PMC ConsoleUI: $($_.Exception.Message)" -ForegroundColor Red
        throw
    } finally {
        # ALWAYS restore cursor, even on crash
        [Console]::CursorVisible = $true
        if ($app) {
            try { $app.Shutdown() } catch {}
        }
    }
}

# Function will be exported by the main module
