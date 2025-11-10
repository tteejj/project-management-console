# Archived Redundant View Screens

**Date Archived:** 2025-11-10

## Reason for Archival

These 9 view screen files were archived because they contained massive code duplication (~6,000 lines total). Each screen was essentially identical, differing only in:
- Filter logic (due date comparison)
- Screen title
- Array property name

## Solution Implemented

All functionality has been consolidated into `TaskListScreen.ps1` which now supports multiple view modes:
- `today` - Tasks due today
- `tomorrow` - Tasks due tomorrow
- `week` - Tasks due this week
- `month` - Tasks due this month
- `upcoming` - Tasks due in the future
- `overdue` - Overdue tasks
- `nextactions` - Tasks with no dependencies
- `noduedate` - Tasks without due dates
- `agenda` - All tasks with due dates
- `active` - All active tasks
- `completed` - Completed tasks
- `all` - All tasks

## Files Archived

1. `TodayViewScreen.ps1` (661 lines) → Replaced by `TaskListScreen::new('today')`
2. `TomorrowViewScreen.ps1` (670 lines) → Replaced by `TaskListScreen::new('tomorrow')`
3. `WeekViewScreen.ps1` (698 lines) → Replaced by `TaskListScreen::new('week')`
4. `MonthViewScreen.ps1` (786 lines) → Replaced by `TaskListScreen::new('month')`
5. `UpcomingViewScreen.ps1` (678 lines) → Replaced by `TaskListScreen::new('upcoming')`
6. `OverdueViewScreen.ps1` (672 lines) → Replaced by `TaskListScreen::new('overdue')`
7. `NextActionsViewScreen.ps1` (678 lines) → Replaced by `TaskListScreen::new('nextactions')`
8. `NoDueDateViewScreen.ps1` (658 lines) → Replaced by `TaskListScreen::new('noduedate')`
9. `AgendaViewScreen.ps1` (992 lines) → Replaced by `TaskListScreen::new('agenda')`

**Total lines eliminated:** ~6,093 lines (95% reduction)

## Impact

- **Code maintainability:** Single source of truth for task list views
- **Consistency:** All views now share the same UI, keyboard shortcuts, and behavior
- **Features:** All views now automatically inherit StandardListScreen features (filtering, sorting, inline editing, multi-select)
- **Testing:** Only one component to test instead of nine

## Migration Path

If you need to restore any specific behavior from these screens:
1. Check the git history for the original implementation
2. Add custom logic to `TaskListScreen.LoadData()` for that specific view mode
3. Consider making it configurable rather than creating a new screen file

## Menu Integration

All menu items have been updated to use:
```powershell
$registry.AddMenuItem('Tasks', 'Today', 'Y', {
    . "$PSScriptRoot/TaskListScreen.ps1"
    $global:PmcApp.PushScreen([TaskListScreen]::new('today'))
}, 10)
```

This ensures consistent navigation and menu structure across all task views.
