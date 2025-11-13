# Common Fixes and Known Issues

This document catalogs recurring issues and their proven solutions.

## Dependency Injection Container Pattern

**Root cause**: Timing and initialization order issues - theme not loading, circular dependencies, widgets caching before theme initialized, type resolution timing conflicts.

**Solution**: ServiceContainer manages all object lifecycle and dependencies.

**Pattern**:
```powershell
# In Start-PmcTUI.ps1 - Register services
$global:PmcContainer = [ServiceContainer]::new()
$global:PmcContainer.Register('Theme', {
    param($container)
    Initialize-PmcThemeSystem
    return Get-PmcState -Section 'Display' | Select-Object -ExpandProperty Theme
})

$global:PmcContainer.Register('TaskStore', {
    param($container)
    $null = $container.Resolve('Theme')  # Ensure theme first
    return [TaskStore]::GetInstance()
})

# Resolve services
$global:PmcApp = $global:PmcContainer.Resolve('Application')
```

**Benefits**:
- Guaranteed initialization order (dependencies resolve before dependents)
- Lazy resolution (only create when needed)
- Circular dependency detection
- Singleton caching for services
- Clear dependency graph

**When to use**:
- All services, application, screens that need theme/config/services
- Any component with initialization order dependencies

---

## ⚠️ CRITICAL: PowerShell Class Methods Don't Support Default Parameters

### Issue: "Cannot find an overload" errors when calling methods with optional parameters
**Symptoms**:
- Error: `Cannot find an overload for "ShowSuccess" and the argument count: "1"`
- Error: `Cannot find an overload for "ShowReady" and the argument count: "0"`
- Method defined with default parameter value but still requires all arguments

**Root cause**: PowerShell classes don't support optional parameters via default values like regular functions do. Default parameter values in class methods are IGNORED during method resolution.

**Example of broken code**:
```powershell
class MyClass {
    [void] MyMethod([string]$arg1, [bool]$arg2 = $false) {
        # Default value $false is IGNORED by PowerShell
    }
}

$obj = [MyClass]::new()
$obj.MyMethod("test")  # ERROR: Cannot find an overload
```

**SEVERITY**: CRITICAL - Affects ALL screens calling ShowSuccess/ShowReady

**Affected Methods in PmcScreen.ps1**:
- `ShowSuccess([string]$message, [bool]$autoSaved = $false)` - line 669
- `ShowReady([string]$itemType = "")` - line 713

**Fix**: Add explicit method overloads instead of default parameters
```powershell
# Single-parameter overload
[void] ShowSuccess([string]$message) {
    $this.ShowSuccess($message, $false)
}

# Two-parameter overload
[void] ShowSuccess([string]$message, [bool]$autoSaved) {
    # Actual implementation
}
```

**Why this matters**:
- PowerShell classes require explicit overloads for optional behavior
- You cannot use `param([bool]$arg = $false)` syntax in class methods
- Method signature must match call site EXACTLY (no default values)

**FIXED**: 2025-11-12 - Added overloads to PmcScreen.ShowSuccess() and ShowReady()

## ⚠️ CRITICAL: Menu Bar Not Accessible (WIDESPREAD ISSUE)

### Issue: Alt+key doesn't work, F10 doesn't activate menu, screen "freezes"
**Symptoms**:
- Cannot access menu bar with Alt+letter hotkeys
- F10 doesn't activate menu
- User feels "stuck" in the screen
- Content widgets may not receive input properly

**Root cause**: HandleKeyPress() override doesn't call parent method first

**SEVERITY**: CRITICAL - Affects 31 out of 33 screens in codebase (as of 2025-11-12)

**Affected Screens** (partial list - see regression checker report):
- ExcelImportScreen.ps1 ✓ FIXED
- FocusSetFormScreen.ps1
- NoteEditorScreen.ps1
- TaskDetailScreen.ps1
- SearchFormScreen.ps1
- ProjectListScreen.ps1
- BurndownChartScreen.ps1
- DepAddFormScreen.ps1
- ... and 23+ more

**Fix**:
```powershell
[bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
    # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
    $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
    if ($handled) { return $true }

    # NOW do custom handling
    // ... your custom key handling ...
}
```

**Why this matters**:
- Parent handles MenuBar hotkey detection (Alt+key)
- Parent handles F10 menu activation
- Parent delegates to content widgets first (prevents conflicts)
- Custom handling should only run if parent didn't handle the key

**Pattern Explanation**:
The base PmcScreen.HandleKeyPress() method:
1. Checks if MenuBar is active → routes to MenuBar
2. Checks F10 → activates MenuBar
3. Checks content widgets → delegates input
4. Checks Alt+key → activates MenuBar
5. Finally calls HandleInput() for custom handling

When you override HandleKeyPress without calling parent, ALL of this is bypassed!

**Related Files to Update**:
When fixing this issue, also update:
- `.claude/docs/SCREEN_PATTERNS.md` - Add HandleKeyPress pattern
- `.claude/agents/tui-pattern-enforcer.md` - Add this to validation checklist

**Historical Note**:
This issue has been "fixed many times" because it was fixed per-screen rather than systematically across all screens. The root cause is likely a missing pattern in original screen templates/documentation.

---

## ⚠️ CRITICAL: OnEnter() Lifecycle Pattern Violation

### Issue: Screen overrides OnEnter() but doesn't call parent
**Symptoms**:
- Data doesn't load on screen navigation
- OnEnterHandler callbacks never execute
- IsActive flag not set properly
- Screen state inconsistent

**Root cause**: OnEnter() override doesn't call parent method

**SEVERITY**: CRITICAL - Breaks screen lifecycle contract

**Affected Screens**:
- ChecklistEditorScreen.ps1 ❌ BROKEN
- NoteEditorScreen.ps1 ❌ BROKEN (also has double LoadData)
- TimeReportScreen.ps1 ✓ FIXED
- WeeklyTimeReportScreen.ps1 ✓ FIXED

**CORRECT Pattern**:
```powershell
[void] OnEnter() {
    # ALWAYS call parent first - it handles IsActive, LoadData, and OnEnterHandler
    ([PmcScreen]$this).OnEnter()

    # Add any additional screen-specific logic here (rare)
}
```

**INCORRECT Pattern** (DON'T DO THIS):
```powershell
[void] OnEnter() {
    $this.IsActive = $true  # ❌ Parent should do this
    $this.LoadData()        # ❌ Parent should do this
    # ❌ OnEnterHandler never executes!
}
```

**What Parent OnEnter() Does** (PmcScreen.ps1:117-124):
```powershell
[void] OnEnter() {
    $this.IsActive = $true           # Sets active flag
    $this.LoadData()                 # Loads data
    if ($this.OnEnterHandler) {      # Executes custom handler
        & $this.OnEnterHandler $this
    }
}
```

**When to Override OnEnter()**:
- RARELY - most screens should NOT override it
- Only if you need additional logic BEYOND what parent provides
- ALWAYS call parent first if you do override

**Alternative Pattern** (Initialize vs OnEnter):
```powershell
# ❌ INCORRECT: Using Initialize() for data loading
[void] Initialize([object]$renderEngine) {
    ([PmcScreen]$this).Initialize($renderEngine)
    $this.LoadData()  # Wrong lifecycle - called once, not on every enter
}

# ✓ CORRECT: Use OnEnter() for data loading
[void] OnEnter() {
    ([PmcScreen]$this).OnEnter()  # Parent calls LoadData() on every enter
}
```

**Key Differences**:
- `Initialize()` - Called ONCE when screen first created
- `OnEnter()` - Called EVERY TIME screen becomes active (on navigation back)
- For data that needs refreshing: Use OnEnter() (via parent)
- For one-time setup: Use Initialize()

**Related Issue**: Some screens call LoadData() in both Initialize() AND OnEnter(), causing duplicate loading.

---

## ⚠️ CRITICAL: _SetupMenus() in Constructor Breaking Screens

### Issue: Screen constructor tries to access MenuBar before it exists
**Symptoms**:
- Screen appears but content is empty
- LoadData() has data but nothing renders
- Constructor crashes silently
- No error in logs but screen broken

**Root cause**: Constructor calls `$this._SetupMenus()` which tries to access `$this.MenuBar.Menus[0]` before parent constructor creates MenuBar

**SEVERITY**: CRITICAL - Breaks screen functionality silently

**PowerShell Constructor Execution Order**:
1. `: base(...)` calls parent constructor
2. Parent PmcScreen constructor creates MenuBar via `_CreateDefaultWidgets()`
3. Child constructor body executes
4. **If child constructor calls `_SetupMenus()` BEFORE step 2 completes → NULL REFERENCE**

**Why This Breaks**:
```powershell
ThemeEditorScreen() : base("ThemeEditor", "Theme Editor") {
    $this._SetupMenus()  # ❌ MenuBar doesn't exist yet!
}

hidden [void] _SetupMenus() {
    $tasksMenu = $this.MenuBar.Menus[0]  # ❌ NULL - parent hasn't created MenuBar yet
}
```

**Affected Screens** (FIXED 2025-11-12):
- ThemeEditorScreen.ps1 ✓ FIXED
- BackupViewScreen.ps1 ✓ FIXED
- TaskDetailScreen.ps1 ✓ FIXED
- KanbanScreen.ps1 ✓ FIXED
- BurndownChartScreen.ps1 ✓ FIXED
- ProjectInfoScreen.ps1 ✓ FIXED
- TimeDeleteFormScreen.ps1 ✓ FIXED
- TimerStartScreen.ps1 ✓ FIXED
- ProjectStatsScreen.ps1 ✓ FIXED
- RestoreBackupScreen.ps1 ✓ FIXED
- BlockedTasksScreen.ps1 ✓ FIXED
- ClearBackupsScreen.ps1 ✓ FIXED
- NoteEditorScreen.ps1 ✓ FIXED

**Special Case**:
- TaskListScreen.ps1 ✓ CORRECT (initializes MenuRegistry, MUST keep _SetupMenus)

**Problem Pattern**:
```powershell
class MyScreen : PmcScreen {
    # ✓ CORRECT: Static registration for global menu
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Tools', 'My Screen', 'M', { ... })
    }

    MyScreen() : base(...) {
        # ❌ WRONG: Also calling _SetupMenus
        $this._SetupMenus()  # This adds duplicate items!
    }

    hidden [void] _SetupMenus() {
        # ❌ WRONG: Manually adding items that RegisterMenuItems already added
        $toolsMenu = $this.MenuBar.Menus[3]
        $toolsMenu.Items.Add([PmcMenuItem]::new("My Screen", 'M', { ... }))
    }
}
```

**How Menu Registration Works (NEW ARCHITECTURE 2025-11-12)**:
1. **MenuRegistry.LoadFromManifest()** - Called once at app startup
2. Reads screens/MenuItems.psd1 manifest
3. Creates scriptblocks for lazy loading (NO screen files loaded)
4. Populates menus from manifest
5. **Then** when user clicks menu item, scriptblock executes and loads screen

**CORRECT Pattern (Post-Manifest)**:
```powershell
class MyScreen : PmcScreen {
    MyScreen() : base("ScreenKey", "Screen Title") {
        # Configure header/footer
        $this.Header.SetBreadcrumb(@("Home", "Category"))

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
        # Old pattern was adding duplicate/misplaced menu items AND breaking constructor
    }

    # NO _SetupMenus() method
    # NO static RegisterMenuItems() method (deprecated - use manifest)
}
```

**Exception - Screen-Specific Menu Items**:
```powershell
# Only use _SetupMenus() if you need items specific to THIS screen instance
# Example: TaskListScreen might add view-specific filters

MyScreen() : base(...) {
    $this._SetupScreenSpecificMenus()  # Different name for clarity
}

hidden [void] _SetupScreenSpecificMenus() {
    # Only add items relevant when THIS screen is active
    # NOT items that should be in global menu
}
```

**Fix**:
Remove _SetupMenus() method and its call from constructor if screen has static RegisterMenuItems().

---

## Menu Cursor Issues

### Issue: Cursor not moving in menu
**Symptoms**: Arrow keys don't change selected menu item

**Root cause**: Usually one of:
1. Missing `parent::ProcessInput($key)` call
2. `$this.selectedIndex` not initialized (null instead of 0)
3. Not re-rendering after cursor move

**Fix**:
```powershell
[void]Initialize() {
    parent::Initialize()
    $this.selectedIndex = 0  # Explicitly initialize
    $this.menuItems = @(...)
}

[void]ProcessInput($key) {
    parent::ProcessInput($key)  # Must be first

    if ($key.VirtualKeyCode -eq 38 -and $this.selectedIndex -gt 0) {
        $this.selectedIndex--
    }
    if ($key.VirtualKeyCode -eq 40 -and $this.selectedIndex -lt ($this.menuItems.Count - 1)) {
        $this.selectedIndex++
    }
}
```

**Affected screens historically**:
- KanbanScreen
- ChecklistsMenuScreen
- NotesMenuScreen

---

### Issue: Cursor goes out of bounds
**Symptoms**: IndexOutOfRangeException or cursor disappears

**Root cause**: No bounds checking on cursor increment/decrement

**Fix**:
```powershell
# WRONG
if ($key.VirtualKeyCode -eq 40) {
    $this.selectedIndex++
}

# RIGHT
if ($key.VirtualKeyCode -eq 40) {
    if ($this.selectedIndex -lt ($this.menuItems.Count - 1)) {
        $this.selectedIndex++
    }
}
```

---

## Form Input Issues

### Issue: Widget not receiving input
**Symptoms**: Typing doesn't update text field

**Root cause**: Screen not delegating to widget's HandleInput method

**Fix**:
```powershell
[void]ProcessInput($key) {
    parent::ProcessInput($key)

    # Let widget handle input first
    if ($this.myWidget.HandleInput($key)) {
        return  # Widget consumed it, don't process further
    }

    # Handle other keys (Enter for submit, etc.)
    if ($key.VirtualKeyCode -eq 13) {
        $this.OnSubmit()
    }
}
```

---

### Issue: Widget not initialized
**Symptoms**: NullReferenceException when trying to interact with widget

**Root cause**: Forgot to call widget's `Initialize()` method

**Fix**:
```powershell
[void]Initialize() {
    parent::Initialize()

    $this.textInput = [TextInput]::new()
    $this.textInput.Initialize()  # MUST CALL
    $this.textInput.Value = ""
}
```

---

## Data Persistence Issues

### Issue: Changes not saved
**Symptoms**: Task updates lost after restart

**Root cause**: Forgetting to call `TaskStore.Save()`

**Fix**:
```powershell
# After any mutation
$task.Status = "Done"
$this.app.taskStore.UpdateTask($task)
$this.app.taskStore.Save()  # REQUIRED
```

**Checklist for all data mutations**:
- [ ] Called appropriate TaskStore method (AddTask, UpdateTask, DeleteTask)
- [ ] Called `$this.app.taskStore.Save()`
- [ ] Handled any error cases

---

## Navigation Issues

### Issue: Can't go back with Escape
**Symptoms**: Escape key doesn't navigate back

**Root cause**: Not calling `parent::ProcessInput($key)` first

**Fix**:
```powershell
[void]ProcessInput($key) {
    parent::ProcessInput($key)  # Handles Escape
    # Your logic
}
```

---

### Issue: Screen shows stale data after navigation
**Symptoms**: List shows old tasks after adding new one

**Root cause**: Not reloading data in `Initialize()`

**Fix**:
```powershell
[void]Initialize() {
    parent::Initialize()
    $this.LoadData()  # Reload on every Initialize
}

[void]LoadData() {
    $this.items = $this.app.taskStore.GetAllTasks()
}
```

**Note**: `Initialize()` is called every time screen is shown, so always reload data there.

---

## Rendering Issues

### Issue: Screen flickers or shows artifacts
**Symptoms**: Visual glitches, overlapping text

**Root cause**: Usually one of:
1. Not clearing screen before render
2. Writing beyond terminal boundaries
3. Not managing cursor position correctly

**Fix**:
```powershell
[void]Show() {
    parent::Show()
    $this.speedTUI.Clear()  # Clear before drawing
    $this.speedTUI.MoveCursor(0, 0)  # Start at top
    # Your rendering
}
```

---

### Issue: Text not appearing
**Symptoms**: Screen blank or partially rendered

**Root cause**: SpeedTUI buffer not flushing (usually framework handles this)

**Check**:
1. Verify `$this.speedTUI` is not null
2. Verify SpeedTUI instance passed correctly in constructor
3. Check console output for errors

---

## List/UniversalList Issues

### Issue: List not scrolling
**Symptoms**: Arrow keys don't scroll list

**Root cause**: For StandardListScreen subclasses, usually:
1. Overriding ProcessInput without calling parent
2. Widget not properly initialized

**Fix**:
```powershell
class MyListScreen : StandardListScreen {
    [void]ProcessInput($key) {
        parent::ProcessInput($key)  # StandardListScreen handles scrolling

        # Additional keys if needed (but not arrow keys)
        if ($key.VirtualKeyCode -eq 13) {
            $item = $this.universalList.GetSelectedItem()
            $this.OnItemSelected($item)
        }
    }
}
```

---

### Issue: Multi-select mode not working
**Symptoms**: Space key doesn't toggle selection

**Root cause**: Multi-select not enabled or handled

**Fix**:
```powershell
[void]Initialize() {
    parent::Initialize()
    $this.universalList.MultiSelectEnabled = $true
}
```

---

## Common Code Smells

### Smell: Duplicate cursor handling across multiple screens
**Problem**: Same arrow key code copied across 10 menu screens

**Solution**: Ensure all menu screens follow MenuScreen pattern, consider creating MenuScreen base class if not exists

---

### Smell: Inconsistent initialization patterns
**Problem**: Some screens initialize widgets in constructor, some in Initialize()

**Solution**: ALWAYS initialize widgets in Initialize() method, not constructor

**Why**: Initialize() is called when screen is shown, constructor only once

---

### Smell: Direct field access instead of widget properties
**Problem**: Manually managing cursor position instead of using widget

**Solution**: Use widget's properties and methods, don't reinvent

---

## Regression Prevention Checklist

Before marking a fix complete, verify:
- [ ] Parent methods called (Initialize, Show, ProcessInput)
- [ ] Widget delegation happens before custom input handling
- [ ] Cursor movements have bounds checks
- [ ] TaskStore.Save() called after mutations
- [ ] Similar screens also fixed (if pattern issue)
- [ ] No console errors when testing
- [ ] Can navigate back with Escape
- [ ] Can navigate forward with expected keys

---

## Known Limitations

### PowerShell Class Limitations
- Can't use `base::Method()` - must use `parent::Method()` syntax
- Constructor inheritance requires explicit parameter passing
- No abstract classes - must use comments to indicate required overrides

### SpeedTUI Limitations
- VT100 only, no mouse support
- Terminal size changes not auto-detected
- Some terminal emulators have escape sequence quirks

---

## ⚠️ CRITICAL: PowerShell Type Resolution - New-Object vs Bracket Notation

### Issue: Cannot find type [ScreenName] error during MenuRegistry.DiscoverScreens()
**Symptoms**:
- Error: "Cannot find type [ScreenName]: verify that the assembly containing this type is loaded"
- Occurs during app startup when MenuRegistry loads screen files
- Menu items disappear
- Settings/Help/other screens missing from menus

**Root cause**: PowerShell resolves types at DIFFERENT times for different syntax

**SEVERITY**: CRITICAL - Breaks entire menu system

### The Type Resolution Problem

**PowerShell has TWO type resolution times:**

1. **PARSE TIME** (when file is loaded/dot-sourced):
   - Bracket notation `[ClassName]::new()` requires type to exist NOW
   - PowerShell validates all type references in class bodies during parsing
   - Files load in arbitrary order (alphabetical)
   - If type doesn't exist yet → PARSE ERROR

2. **EXECUTION TIME** (when code actually runs):
   - `New-Object ClassName` resolves type when line executes
   - Type can be loaded after file parses
   - Allows forward references

### The Menu Discovery Problem

MenuRegistry.DiscoverScreens() (now deprecated) used to:
1. Loop through all screen files
2. Dot-source each file (causes PARSE)
3. Call RegisterMenuItems()

When it dot-sourced BackupViewScreen.ps1:
```powershell
# Inside BackupViewScreen.ps1 method body
. "$PSScriptRoot/RestoreBackupScreen.ps1"
$screen = [RestoreBackupScreen]::new()  # ❌ PARSE ERROR
```

PowerShell parses the entire class, sees `[RestoreBackupScreen]::new()`, tries to resolve type during PARSE, but RestoreBackupScreen hasn't been loaded yet → FILE FAILS TO LOAD → RegisterMenuItems never runs → Menu items disappear

### THE SOLUTION: Manifest-Based Menu Loading

**NEW ARCHITECTURE** (as of 2025-11-12):
- Menu items defined in `screens/MenuItems.psd1` manifest
- MenuRegistry.LoadFromManifest() reads manifest, builds scriptblocks
- NO screen files loaded at startup
- Screens load lazily when clicked

**screens/MenuItems.psd1**:
```powershell
@{
    'SettingsScreen' = @{
        Menu = 'Options'
        Label = 'Settings'
        Hotkey = 'S'
        Order = 20
        ScreenFile = 'SettingsScreen.ps1'
    }
}
```

**MenuRegistry creates scriptblocks dynamically** (scriptblocks don't parse until executed):
```powershell
$scriptblock = [scriptblock]::Create(@"
. "$screenPath"
`$screen = New-Object SettingsScreen
`$global:PmcApp.PushScreen(`$screen)
"@)
```

### RULES FOR TYPE INSTANTIATION

**Rule 1: For screen-to-screen navigation in method bodies → MUST use `New-Object`**
```powershell
# ✓ CORRECT
hidden [void] _LaunchSettings() {
    . "$PSScriptRoot/SettingsScreen.ps1"
    $screen = New-Object SettingsScreen  # Resolves at EXECUTION time
    $global:PmcApp.PushScreen($screen)
}

# ❌ WRONG
hidden [void] _LaunchSettings() {
    . "$PSScriptRoot/SettingsScreen.ps1"
    $screen = [SettingsScreen]::new()  # Resolves at PARSE time
    $global:PmcApp.PushScreen($screen)
}
```

**Rule 2: For widgets/services already loaded → Can use either**
```powershell
# Both work (widget files loaded before screens)
$this.textInput = [TextInput]::new()
$this.textInput = New-Object TextInput
```

**Rule 3: In scriptblocks (menu items, callbacks) → Use `New-Object`**
```powershell
# ✓ CORRECT (scriptblocks don't parse until executed)
$this.AddMenuItem('Options', 'Settings', 'S', {
    . "$PSScriptRoot/SettingsScreen.ps1"
    $screen = New-Object SettingsScreen
    $global:PmcApp.PushScreen($screen)
})
```

### Why We Can't Use Bracket Notation Everywhere

**Bracket notation benefits**:
- Modern PowerShell syntax
- Clearer intent
- Better for IntelliSense

**BUT it breaks when**:
- Type defined in same module loading in arbitrary order
- Circular dependencies between screens
- Classes reference each other in method bodies
- MenuRegistry discovery pattern (now deprecated)

**New-Object benefits**:
- Defers type resolution until execution
- Allows forward references
- Works with arbitrary load order
- Compatible with lazy loading architecture

### Files Fixed (2025-11-12)

**Reverted to New-Object** (parse-time type resolution was breaking):
- SettingsScreen.ps1 (line 265): ThemeEditorScreen
- ProjectListScreen.ps1 (lines 501, 572): ProjectInfoScreen
- ChecklistsMenuScreen.ps1 (lines 179, 187): ChecklistEditorScreen, ChecklistTemplatesScreen
- ExcelProfileManagerScreen.ps1 (line 190): ExcelMappingEditorScreen
- NotesMenuScreen.ps1 (line 220): NoteEditorScreen
- SearchFormScreen.ps1 (line 283): TaskDetailScreen
- BackupViewScreen.ps1 (line 400): RestoreBackupScreen

**Architecture Changed**:
- Created screens/MenuItems.psd1 manifest
- MenuRegistry.LoadFromManifest() replaces DiscoverScreens()
- TaskListScreen._SetupMenus() now calls LoadFromManifest()
- Zero screen files loaded at startup

### Migration Guide

**Adding a new screen with menu item**:

1. Create ScreenName.ps1 with your screen class
2. Add entry to screens/MenuItems.psd1:
```powershell
'ScreenName' = @{
    Menu = 'MenuName'
    Label = 'Display Label'
    Hotkey = 'X'
    Order = 30
    ScreenFile = 'ScreenName.ps1'
}
```
3. If your screen launches other screens, use `New-Object`

**DO NOT**:
- Add static RegisterMenuItems() methods to screens (deprecated)
- Use bracket notation for screen-to-screen navigation
- Call MenuRegistry.DiscoverScreens() (deprecated)

---

## To Be Documented
- Performance issues and optimization patterns
- Testing patterns
- Debugging techniques
- Error handling patterns
- Complex widget interaction patterns
