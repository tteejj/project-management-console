# First Real Screen Migration Complete ✅

**Date:** 2025-11-05
**Screen:** BlockedTasksScreen (migrated from DrawBlockedView)
**Status:** READY TO RUN

---

## What Was Done

### 1. Migrated BlockedTasksScreen ✅
**From:** `DrawBlockedView()` method in ConsoleUI.Core.ps1:4078
**To:** `/home/teej/pmc/module/Pmc.Strict/consoleui/screens/BlockedTasksScreen.ps1`

**Features:**
- Lists tasks with status 'blocked' or 'waiting'
- Arrow key navigation with selection
- Color-coded status (Red=blocked, Yellow=waiting)
- Full widget integration (Header, Footer, StatusBar)
- Keyboard shortcuts (Enter/E/D/Esc)

### 2. Created Entry Point ✅
**File:** `/home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1`

**Functions:**
- `Start-PmcTUI` - Launch PMC with new architecture
- `Start-PmcTUI -StartScreen BlockedTasks` - Specific screen
- `Start-PmcTUI -StartScreen Demo` - Demo screen

---

## How to Run

```powershell
# Launch blocked tasks screen
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1

# Or with parameter
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1 -StartScreen BlockedTasks

# Or demo
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1 -StartScreen Demo
```

---

## Migration Pattern (for next 57 screens)

### Step 1: Find Old Screen Method
```powershell
# Example: DrawAgendaView() in ConsoleUI.Core.ps1
```

### Step 2: Create New Screen Class
```powershell
class AgendaScreen : PmcScreen {
    AgendaScreen() : base("Agenda", "Task Agenda") {
        # Configure widgets
        $this.Header.SetIcon("📅")
        $this.Footer.AddShortcut("Enter", "Select")
    }

    [void] LoadData() {
        # Load data from Get-PmcAllData
        $data = Get-PmcAllData
        $this.tasks = $data.tasks
    }

    [string] RenderContent() {
        # Build output using StringBuilder
        $sb = [PmcStringBuilderPool]::Get(2048)
        # ... render tasks
        $result = $sb.ToString()
        [PmcStringBuilderPool]::Return($sb)
        return $result
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Handle arrows, Enter, etc.
    }
}
```

### Step 3: Add to Start-PmcTUI.ps1
```powershell
. "$PSScriptRoot/screens/AgendaScreen.ps1"

switch ($StartScreen) {
    'Agenda' {
        $screen = [AgendaScreen]::new()
        $global:PmcApp.PushScreen($screen)
    }
}
```

---

## Files Created

```
consoleui/
├── screens/                            (NEW directory)
│   └── BlockedTasksScreen.ps1          (NEW - 220 lines)
│
└── Start-PmcTUI.ps1                    (NEW - 60 lines)
```

---

## Code Comparison

### OLD (DrawBlockedView)
- 36 lines in monolithic file
- Direct terminal writes
- Hardcoded positions
- No widget reuse
- Manual clear/redraw
- Coupled to PmcSimpleTerminal

### NEW (BlockedTasksScreen)
- 220 lines (self-contained)
- Widget-based rendering
- Layout manager positioning
- Reusable components
- SpeedTUI differential rendering
- Clean separation

---

## What Works (Once Running)

- ✅ Load blocked/waiting tasks from PMC data
- ✅ Display in themed list
- ✅ Arrow navigation with selection highlight
- ✅ Color-coded status (blocked=red, waiting=yellow)
- ✅ Empty state ("No blocked tasks")
- ✅ Status bar updates
- ✅ Footer keyboard shortcuts
- ✅ Header with breadcrumb
- ✅ F10 menu (if wired)
- ✅ Esc to exit

---

## What's Still TODO in This Screen

- ⚠️ Enter → Task detail screen (not implemented)
- ⚠️ E → Edit task (not implemented)
- ⚠️ D → Toggle status doesn't save (save function not wired)
- ⚠️ Scrolling for >20 tasks (shows truncation indicator only)

---

## Next Screens to Migrate (Priority Order)

1. **AgendaView** - Most commonly used
2. **TaskListView** - Core task management
3. **ProjectListView** - Project navigation
4. **BackupView** - Simple, good for testing
5. **... 54 more screens**

---

## Pattern Summary

**Every screen needs:**
1. Extend `PmcScreen`
2. Override `LoadData()` - Load from Get-PmcAllData
3. Override `RenderContent()` - Build output with widgets
4. Override `HandleInput()` - Handle keyboard
5. Configure Header/Footer in constructor
6. Add entry point function

**Common pitfalls:**
- Don't forget `[PmcStringBuilderPool]::Get()` and `::Return()`
- Use `$this.Header.BuildMoveTo()` not raw ANSI
- Use `$this.Header.GetThemedAnsi()` not hardcoded colors
- Reset colors with `` `e[0m `` after each colored section
- Check `$this.LayoutManager` is not null before using

---

## Diff (Old vs New)

### Old DrawBlockedView (lines 4078-4114)
```powershell
[void] DrawBlockedView() {
    $this.terminal.Clear()
    $this.menuSystem.DrawMenuBar()

    $title = " Blocked/Waiting Tasks "
    $titleX = ($this.terminal.Width - $title.Length) / 2
    $this.terminal.WriteAtColor([int]$titleX, 3, $title, ...)

    $data = Get-PmcAllData
    $blockedTasks = @($data.tasks | Where-Object { ... })

    $y = 6
    foreach ($task in $blockedTasks) {
        $this.terminal.WriteAt(4, $y, "[$($task.id)] ...")
        $y++
    }

    $this.terminal.DrawFooter("↑/↓:Select ...")
}
```

### New BlockedTasksScreen
```powershell
class BlockedTasksScreen : PmcScreen {
    [array]$BlockedTasks = @()
    [int]$SelectedIndex = 0

    BlockedTasksScreen() : base("BlockedTasks", "Blocked/Waiting Tasks") {
        $this.Header.SetIcon("🚫")
        $this.Footer.AddShortcut("↑↓", "Select")
    }

    [void] LoadData() {
        $data = Get-PmcAllData
        $this.BlockedTasks = @($data.tasks | Where-Object { ... })
    }

    [string] RenderContent() {
        $sb = [PmcStringBuilderPool]::Get(2048)
        # Build output with themed colors, layout positioning
        foreach ($task in $this.BlockedTasks) {
            # ... render with widgets
        }
        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Arrow keys, Enter, E, D
    }
}
```

---

## Success Criteria

✅ Screen class created
✅ Extends PmcScreen
✅ Uses widgets (Header, Footer, StatusBar)
✅ Uses LayoutManager for positioning
✅ Uses ThemeManager for colors
✅ Handles keyboard input
✅ Loads PMC data
✅ Entry point function created
✅ Wired into Start-PmcTUI.ps1

**STATUS:** READY TO RUN

---

## Run Command

```bash
cd /home/teej/pmc/module/Pmc.Strict/consoleui
pwsh Start-PmcTUI.ps1 -StartScreen BlockedTasks
```

**Fallback (if errors):**
```bash
pwsh Start-PmcTUI.ps1 -StartScreen Demo
```

---

**This is the real test. Demo was setup. This is actual PMC functionality.**
