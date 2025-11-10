# Menu Update Progress

## Date
2025-11-05

## Task
Update all screen menus from CRUD operations to NAVIGATION pattern

## Problem Fixed
- Menus were calling non-existent CRUD methods (_StartAdd, _EditTask, etc.)
- Scriptblock scope issue: `$this` in menu scriptblocks referred to PmcMenuBar instead of screen
- Dropdown menus not clearing properly when navigating between items

## Solution Pattern
```powershell
hidden [void] _SetupMenus() {
    # Capture $this in a variable so scriptblocks can access it
    $screen = $this

    # Tasks menu - Navigate to different task views
    $tasksMenu = $this.MenuBar.Menus[0]
    $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { Write-Host "No Due Date view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::Separator())
    $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
    $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

    # Projects menu
    $projectsMenu = $this.MenuBar.Menus[1]
    $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { Write-Host "Project list not implemented" }))
    $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
    $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { Write-Host "Project info not implemented" }))

    # Options menu
    $optionsMenu = $this.MenuBar.Menus[2]
    $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
    $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

    # Help menu
    $helpMenu = $this.MenuBar.Menus[3]
    $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
    $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
}
```

NOTE: For the menu item that matches the current screen, use: `{ $screen.LoadData() }.GetNewClosure()` instead of Write-Host

## Files COMPLETED (5)
✅ TaskListScreen.ps1
✅ NextActionsViewScreen.ps1
✅ UpcomingViewScreen.ps1
✅ NoDueDateViewScreen.ps1
✅ TomorrowViewScreen.ps1

## Files REMAINING (32)
- BlockedTasksScreen.ps1
- OverdueViewScreen.ps1
- TodayViewScreen.ps1
- WeekViewScreen.ps1
- KanbanScreen.ps1
- TaskDetailScreen.ps1
- ProjectListScreen.ps1
- MonthViewScreen.ps1
- BurndownChartScreen.ps1
- AgendaViewScreen.ps1
- ThemeEditorScreen.ps1
- ProjectStatsScreen.ps1
- ProjectInfoScreen.ps1
- HelpViewScreen.ps1
- TimerStopScreen.ps1
- FocusSetFormScreen.ps1
- BackupViewScreen.ps1
- TimerStatusScreen.ps1
- FocusClearScreen.ps1
- RestoreBackupScreen.ps1
- FocusStatusScreen.ps1
- DepAddFormScreen.ps1
- ClearBackupsScreen.ps1
- DepRemoveFormScreen.ps1
- SearchFormScreen.ps1
- MultiSelectModeScreen.ps1
- DepShowFormScreen.ps1
- TimeListScreen.ps1
- UndoViewScreen.ps1
- TimeDeleteFormScreen.ps1
- RedoViewScreen.ps1
- TimeReportScreen.ps1
- TimerStartScreen.ps1

## Directory
All files in: /home/teej/pmc/module/Pmc.Strict/consoleui/screens/

## Additional Fixes Applied
- PmcMenuBar.ps1: Added dropdown clearing mechanism to fix visual artifacts
  - Added _prevDropdownX, _prevDropdownY, _prevDropdownWidth, _prevDropdownHeight tracking
  - Added _ClearPreviousDropdown() method
  - Modified OnRender() to clear before rendering new dropdown
