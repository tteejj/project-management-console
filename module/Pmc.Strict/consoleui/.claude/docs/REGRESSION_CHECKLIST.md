# Regression Prevention Checklist

This document maps changes to potential side effects across the codebase.

---

## Change Impact Matrix

### If you modify: `PmcScreen.ps1` (Base Class)

**Potential impact**: ALL screens

**Must verify**:
- [ ] All screens still call `parent::Initialize()`
- [ ] All screens still call `parent::Show()`
- [ ] All screens still call `parent::ProcessInput($key)`
- [ ] Escape key still works for navigation back
- [ ] No breaking changes to State property
- [ ] No breaking changes to NavigateTo/NavigateBack

**Test screens**:
- At least one of each type: menu, form, list
- Example: ChecklistsMenuScreen, FocusSetFormScreen, TaskListScreen

---

### If you modify: `StandardListScreen.ps1` (List Base Class)

**Potential impact**: All list-based screens

**Must verify**:
- [ ] Arrow key scrolling works
- [ ] Page Up/Down works
- [ ] Item selection works
- [ ] Multi-select mode works (if enabled)
- [ ] LoadData pattern still functional
- [ ] OnItemSelected still called

**Affected screens**:
- TaskListScreen
- ProjectListScreen
- TimeListScreen
- ChecklistTemplatesScreen
- CommandLibraryScreen
- RestoreBackupScreen
- WeeklyTimeReportScreen
- BurndownChartScreen (if list-based)

**Test by**: Running each screen, navigating list, selecting items

---

### If you modify: `UniversalList.ps1` (Widget)

**Potential impact**: All screens using list widget

**Must verify**:
- [ ] List scrolling works
- [ ] Item selection works
- [ ] Multi-select works
- [ ] Filter integration works (if applicable)
- [ ] HandleInput returns correct boolean
- [ ] Render doesn't break layout

**Affected screens**: Same as StandardListScreen + any custom screens using UniversalList directly

**Test by**:
- Scroll through long lists
- Select items with Enter
- Multi-select with Space
- Navigate with arrows, Page Up/Down

---

### If you modify: `TextInput.ps1` (Widget)

**Potential impact**: All form screens

**Must verify**:
- [ ] Text entry works
- [ ] Cursor movement works (arrows, Home/End)
- [ ] Backspace/Delete works
- [ ] Character insertion at cursor works
- [ ] HandleInput returns correct boolean

**Affected screens**:
- FocusSetFormScreen
- SearchFormScreen
- DepAddFormScreen
- DepRemoveFormScreen
- DepShowFormScreen
- TimeDeleteFormScreen
- TimerStartScreen
- Any screen with text input

**Test by**:
- Type text
- Move cursor with arrows
- Insert text in middle
- Delete characters
- Use Backspace at start/end

---

### If you modify: Menu handling in any screen

**Check similar screens for same issue**:

Menu screens (all share similar cursor patterns):
- ChecklistsMenuScreen
- NotesMenuScreen
- KanbanScreen
- Any screen with menuItems array

**Verify pattern**:
```powershell
[int]$selectedIndex = 0  # Initialized to 0
[array]$menuItems

[void]ProcessInput($key) {
    parent::ProcessInput($key)  # First

    # Arrow up with bounds check
    if ($key.VirtualKeyCode -eq 38 -and $this.selectedIndex -gt 0) {
        $this.selectedIndex--
    }

    # Arrow down with bounds check
    if ($key.VirtualKeyCode -eq 40 -and $this.selectedIndex -lt ($this.menuItems.Count - 1)) {
        $this.selectedIndex++
    }

    # Enter to invoke
    if ($key.VirtualKeyCode -eq 13) {
        & $this.menuItems[$this.selectedIndex].Action
    }
}
```

---

### If you modify: Form submission in any screen

**Check similar screens**:

Form screens (all share similar submission patterns):
- FocusSetFormScreen
- SearchFormScreen
- DepAddFormScreen
- DepRemoveFormScreen
- TimeDeleteFormScreen

**Verify pattern**:
```powershell
[void]ProcessInput($key) {
    parent::ProcessInput($key)

    # Widget handles input first
    if ($this.widget.HandleInput($key)) {
        return
    }

    # Enter to submit
    if ($key.VirtualKeyCode -eq 13) {
        $value = $this.widget.Value
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $this.OnSubmit($value)
        }
    }
}

[void]OnSubmit($value) {
    # Mutate data
    $this.app.taskStore.SomeMethod($value)
    $this.app.taskStore.Save()  # CRITICAL
    $this.NavigateBack()
}
```

---

### If you modify: TaskStore methods

**Potential impact**: Any screen that calls the modified method

**Common callers by method**:

`GetAllTasks()`:
- TaskListScreen
- SearchFormScreen
- BurndownChartScreen
- KanbanScreen
- ProjectStatsScreen
- MultiSelectModeScreen

`GetTaskById()`:
- TaskDetailScreen
- Any screen editing specific task

`UpdateTask()` / `AddTask()`:
- Form screens that create/edit tasks
- FocusSetFormScreen
- Any mutation screen

`Save()`:
- Every screen that mutates data (see form screens list)

**Must verify**:
- [ ] Return type unchanged or compatible
- [ ] No breaking changes to task object structure
- [ ] Save() still works
- [ ] Load() properly reloads data

---

### If you modify: Navigation logic

**Potential impact**: All screens

**Must verify**:
- [ ] NavigateTo pushes to stack correctly
- [ ] NavigateBack pops from stack
- [ ] Screen stack doesn't grow unbounded
- [ ] State passing between screens works
- [ ] Can navigate deep and back out
- [ ] Escape key works in all screens

**Test by**:
- Navigate deep: Main → Menu → List → Detail → Form
- Navigate back with Escape repeatedly
- Pass data between screens
- Verify no memory leaks from screen stack

---

### If you modify: Widget initialization

**Must verify across all widget usages**:
- [ ] Constructor still works
- [ ] Initialize() still required
- [ ] Properties accessible after init
- [ ] HandleInput contract unchanged
- [ ] Render contract unchanged

**Test by**: Run screens using the modified widget

---

## Screen Groupings for Testing

### Menu Screens
- ChecklistsMenuScreen
- NotesMenuScreen
- KanbanScreen

**Shared behavior**: Arrow navigation, Enter to select, cursor highlighting

### Form Screens
- FocusSetFormScreen
- SearchFormScreen
- DepAddFormScreen
- DepRemoveFormScreen
- DepShowFormScreen
- TimeDeleteFormScreen
- TimerStartScreen

**Shared behavior**: Widget input delegation, Enter to submit, validation

### List Screens
- TaskListScreen
- ProjectListScreen
- TimeListScreen
- ChecklistTemplatesScreen
- CommandLibraryScreen
- RestoreBackupScreen
- WeeklyTimeReportScreen

**Shared behavior**: UniversalList widget, scrolling, selection, filtering

### Detail/View Screens
- TaskDetailScreen
- ProjectInfoScreen
- FocusStatusScreen
- ProjectStatsScreen

**Shared behavior**: Read-only data display, navigation to edit forms

### Complex Screens (multi-widget)
- NoteEditorScreen (InlineEditor)
- ExcelImportScreen (file picker + mapping)
- ExcelMappingEditorScreen (complex forms)
- ExcelProfileManagerScreen (list + forms)
- MultiSelectModeScreen (UniversalList in multi-select)

**Shared behavior**: Multiple widget coordination, complex state

---

## Pre-Commit Checklist

Before considering a fix complete:

### Code Review
- [ ] Parent method calls present in all overrides
- [ ] Widget HandleInput checked before custom input handling
- [ ] Bounds checking on array access
- [ ] TaskStore.Save() after mutations
- [ ] No null reference opportunities
- [ ] Consistent with established patterns

### Testing
- [ ] Fix applied to the reported screen
- [ ] Similar screens checked (use groupings above)
- [ ] Can navigate to and from the screen
- [ ] Escape key works
- [ ] No console errors
- [ ] Data persists after restart (if applicable)

### Documentation
- [ ] Pattern documented if new
- [ ] Common fix added if recurring issue
- [ ] Comments added for non-obvious code

---

## Regression Testing Scenarios

### Scenario 1: Menu Navigation
1. Navigate to a menu screen
2. Press Arrow Down multiple times
3. Press Arrow Up multiple times
4. Press Arrow Down until end of list
5. Press Arrow Down again (should stay at end)
6. Press Arrow Up until start
7. Press Arrow Up again (should stay at start)
8. Press Enter on each menu item
9. Press Escape to go back

**Expected**: No crashes, cursor stays in bounds, all options work

### Scenario 2: Form Input
1. Navigate to a form screen
2. Type text
3. Move cursor with arrow keys
4. Insert text in middle
5. Delete characters with Backspace
6. Delete characters with Delete
7. Press Enter with empty input (should reject or prompt)
8. Type valid input and press Enter (should submit)
9. Verify data saved (restart app, check data)

**Expected**: Input works smoothly, submission works, data persists

### Scenario 3: List Interaction
1. Navigate to a list screen
2. Scroll with Arrow Down through multiple pages
3. Press Page Down
4. Press Page Up
5. Press Home (if supported)
6. Press End (if supported)
7. Select item with Enter
8. Navigate back
9. Verify selection was processed

**Expected**: Smooth scrolling, selection works, no crashes

### Scenario 4: Data Mutation
1. Navigate to a form that creates/edits data
2. Enter data and submit
3. Navigate to list/view showing that data
4. Verify data appears
5. Restart application
6. Verify data still present

**Expected**: Data persists across sessions

### Scenario 5: Deep Navigation
1. Start at main screen
2. Navigate through: Menu → List → Detail → Form
3. Press Escape repeatedly to back out
4. Verify you return to start
5. Repeat navigation to different screens
6. Verify no memory leak (check process memory)

**Expected**: Navigation stack works correctly, no leaks

---

## Known Fragile Areas

### High Risk of Regression
1. **Menu cursor management** - Many screens duplicate this logic
2. **Widget input delegation** - Easy to forget HandleInput check
3. **TaskStore.Save() calls** - Often forgotten after mutations
4. **Bounds checking** - Array access without validation

### Medium Risk
1. **Parent method calls** - New developers may forget
2. **State passing** - Complex screens may miss state properties
3. **Widget initialization** - Initialize() sometimes forgotten

### Low Risk (well-encapsulated)
1. **Rendering** - SpeedTUI handles most issues
2. **Service initialization** - Done once in PmcApplication
3. **Basic navigation** - Handled by base classes

---

## To Be Documented
- Automated regression test suite
- Performance regression detection
- Visual regression testing
- Integration test scenarios
