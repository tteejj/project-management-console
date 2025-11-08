# PMC TUI - Quick Start Guide

**Status:** ✅ Base Infrastructure Complete
**Last Updated:** 2025-11-07

---

## Quick Reference

### Files Created (11 files, 8,469 lines)

**Infrastructure (5 files)**:
- `helpers/ValidationHelper.ps1` - Entity validation
- `infrastructure/ScreenRegistry.ps1` - Screen registration
- `infrastructure/NavigationManager.ps1` - Navigation with history
- `infrastructure/KeyboardManager.ps1` - Keyboard shortcuts
- `infrastructure/ApplicationBootstrapper.ps1` - App initialization

**Tests (5 files, 104 tests)**:
- `tests/TestValidationHelper.ps1`
- `tests/TestScreenRegistry.ps1`
- `tests/TestNavigationManager.ps1`
- `tests/TestKeyboardManager.ps1`
- `tests/TestApplicationBootstrapper.ps1`

**Documentation (1 file, 1,876 lines)**:
- `BASE_ARCHITECTURE.md` - Complete architecture guide

---

## Run Tests

```powershell
cd /home/teej/pmc/module/Pmc.Strict/consoleui

# Run all tests
./tests/TestValidationHelper.ps1
./tests/TestScreenRegistry.ps1
./tests/TestNavigationManager.ps1
./tests/TestKeyboardManager.ps1
./tests/TestApplicationBootstrapper.ps1
```

---

## Bootstrap Application

```powershell
# Load bootstrapper
. ./infrastructure/ApplicationBootstrapper.ps1

# Start application (will fail until screens are registered)
$app = Start-PmcApplication -StartScreen 'TaskList'
```

---

## Create a Screen (Example)

```powershell
# 1. Create screen class (inherit from base class)
class TaskListScreen : StandardListScreen {
    [object]$Store

    TaskListScreen([object]$store) {
        $this.Store = $store
        $this.ScreenTitle = "Task List"
        $this.Store.OnTasksChanged = { $this.RefreshItems() }
    }

    [void] RefreshItems() {
        $this.Items = $this.Store.GetAllTasks()
    }

    [string] RenderItem([hashtable]$item, [int]$index, [bool]$isSelected) {
        $prefix = if ($isSelected) { ">" } else { " " }
        return "$prefix $($item.text)"
    }
}

# 2. Register screen
[ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks', 'Task list')

# 3. Navigate
$nav.NavigateTo('TaskList')
```

---

## Common Patterns

### Validate Data

```powershell
$result = Test-TaskValid @{ text = 'Buy milk'; priority = 3 }
if (-not $result.IsValid) {
    Write-Host "Errors: $($result.Errors -join ', ')"
}
```

### Access TaskStore

```powershell
$store = [TaskStore]::GetInstance()
$tasks = $store.GetAllTasks()
$store.AddTask(@{ text = 'New task'; priority = 3 })
```

### Register Keyboard Shortcuts

```powershell
# Global (always active)
$km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, {
    $app.Stop()
}, "Quit")

# Screen-specific (active on TaskList)
$km.RegisterScreen('TaskList', [ConsoleKey]::A, $null, {
    $nav.NavigateTo('AddTask')
}, "Add task")
```

### Navigate Between Screens

```powershell
# Forward
$nav.NavigateTo('TaskDetail', @{ taskId = '123' })

# Back
$nav.GoBack()

# Replace (no history)
$nav.Replace('Login')
```

---

## Architecture Cheat Sheet

```
TaskStore (Data Layer)
    ↓
NavigationManager → ScreenRegistry → Screen (StandardListScreen/Form/Dashboard)
    ↓                                    ↓
KeyboardManager                    RenderEngine
```

**Event Flow:**
```
TaskStore.OnTaskAdded → Screen refreshes → Screen.RequestRender() → UI updates
```

---

## File Locations

```
/home/teej/pmc/module/Pmc.Strict/consoleui/
├── BASE_ARCHITECTURE.md          (Complete guide)
├── INFRASTRUCTURE_COMPLETE.md    (Completion report)
├── QUICK_START.md                (This file)
├── base/                          (Base screen classes)
│   ├── StandardListScreen.ps1
│   ├── StandardFormScreen.ps1
│   └── StandardDashboard.ps1
├── helpers/                       (Validation, data binding)
│   ├── ValidationHelper.ps1
│   └── DataBindingHelper.ps1
├── infrastructure/                (Navigation, keyboard, registry)
│   ├── ScreenRegistry.ps1
│   ├── NavigationManager.ps1
│   ├── KeyboardManager.ps1
│   └── ApplicationBootstrapper.ps1
├── services/                      (Data layer)
│   └── TaskStore.ps1
└── tests/                         (Test suite)
    ├── TestValidationHelper.ps1
    ├── TestScreenRegistry.ps1
    ├── TestNavigationManager.ps1
    ├── TestKeyboardManager.ps1
    └── TestApplicationBootstrapper.ps1
```

---

## Next Steps

1. **Read BASE_ARCHITECTURE.md** - Complete documentation
2. **Run tests** - Verify infrastructure works
3. **Create screens** - Build TaskListScreen, AddTaskScreen, etc.
4. **Register screens** - Add to ApplicationBootstrapper
5. **Test integration** - Run full application

---

## Need Help?

- **Architecture**: See BASE_ARCHITECTURE.md
- **API Reference**: See BASE_ARCHITECTURE.md → API Reference section
- **Examples**: See BASE_ARCHITECTURE.md → Examples section
- **Troubleshooting**: See BASE_ARCHITECTURE.md → Troubleshooting section
- **Tests**: Run test files for working examples

---

**Quick Start Version:** 1.0
**Status:** Infrastructure Complete - Ready for Screen Development
