# TUI Fix Validator Skill

## Purpose
Validate that a fix follows established patterns and check for potential regressions before applying changes.

## When to Invoke
Before making ANY code changes to screen files, invoke this skill to:
1. Understand the correct pattern for the type of fix
2. Identify all similar screens that may need the same fix
3. Generate a checklist of what to verify after the fix

## Inputs Expected
- File path of screen to fix
- Description of the issue/bug
- Proposed fix approach

## Execution Steps

### Step 1: Read the Target File
Read the file that needs fixing to understand current implementation.

### Step 2: Classify the Screen Type
Determine screen type by checking class inheritance:
- Extends `PmcScreen` directly → Custom screen
- Extends `StandardListScreen` → List-based screen
- Check for widget usage (UniversalList, TextInput, InlineEditor, FilterPanel, ProjectPicker)

### Step 3: Validate Against Current Patterns

**For PmcScreen-based screens:**
- Check lifecycle methods exist: `OnEnter()`, `OnExit()`, `LoadData()`
- Check rendering method: `RenderContent()` returns ANSI string
- Check input handling: `HandleKeyPress()` → delegates to `HandleInput()`
- Check widget management: Widgets added to `ContentWidgets` list
- Check parent calls: Methods call parent versions appropriately

**For StandardListScreen-based screens:**
- Check abstract methods implemented: `LoadData()`, `GetColumns()`, `GetEditFields()`
- Check optional overrides if needed: `OnItemSelected()`, `OnItemActivated()`, `GetCustomActions()`, `GetEntityType()`
- Check list configuration: `$this.List` properly configured
- Check column definitions: Proper Name/Label/Width/Align/Format structure
- Check field definitions: Proper Name/Type/Label/Value structure for inline editor

**For Widget Integration:**
- Check widget initialization in `_InitializeComponents()` or `OnEnter()`
- Check event callbacks use `.GetNewClosure()` to capture `$self`
- Check input delegation happens before custom handling
- Check widget rendering integrated in `RenderContent()`

### Step 4: Search for Similar Screens
Use Glob to find screens with similar patterns:
- If fixing menu handling → find screens with menu structures
- If fixing form input → find screens with TextInput usage
- If fixing list operations → find all StandardListScreen subclasses

Generate list of potentially affected screens.

### Step 5: Check Common Issues

**Menu Issues:**
- Missing event callbacks for menu items
- Menu hotkeys conflicting with widget hotkeys

**Form Issues:**
- Missing widget initialization
- Not delegating input to widget first
- Not checking widget's return value from HandleInput()
- Missing validation before submission

**List Issues:**
- Not calling `parent` methods
- Column formatters receiving wrong arguments
- Missing bounds checks on selection
- Not refreshing list after data changes

**Event Handling Issues:**
- Callbacks not using `.GetNewClosure()`
- Callbacks referencing wrong screen instance (use `$self`, not `$this`)
- Not checking `$this.IsActive` before updating

### Step 6: Generate Fix Checklist

Output checklist with:
- [ ] Pattern-specific items (based on screen type)
- [ ] Similar screens to check (from Step 4)
- [ ] Pre-commit verification steps
- [ ] Testing scenarios

### Step 7: Return Validation Report

Return structured report:
```
SCREEN TYPE: [type]
CURRENT ISSUES: [list of issues found]
RECOMMENDED FIX: [pattern-based fix]
SIMILAR SCREENS TO CHECK: [list]
VERIFICATION CHECKLIST: [items]
RISKS: [potential regressions]
```

## Example Usage

**User Request**: "Fix cursor in KanbanScreen"

**Skill Execution**:
1. Read `screens/KanbanScreen.ps1`
2. Classify: Extends PmcScreen, has menu structure
3. Check patterns: Find menu handling in `HandleInput()`
4. Search similar: Find ChecklistsMenuScreen, NotesMenuScreen
5. Check issues: Verify menu callbacks, event handling
6. Generate checklist
7. Return report

**Output**:
```
SCREEN TYPE: Menu Screen (extends PmcScreen)
CURRENT ISSUES:
  - Menu item callbacks may not be properly bound
  - Cursor state may not be managed correctly
RECOMMENDED FIX:
  - Ensure menu items use proper event structure
  - Verify MenuBar widget initialization
  - Check OnEnter() sets up menu state
SIMILAR SCREENS TO CHECK:
  - screens/ChecklistsMenuScreen.ps1
  - screens/NotesMenuScreen.ps1
VERIFICATION CHECKLIST:
  - [ ] MenuBar properly initialized in OnEnter()
  - [ ] Menu hotkeys work (Alt+key)
  - [ ] F10 activates menu
  - [ ] Escape closes menu
  - [ ] Menu callbacks execute correctly
  - [ ] No conflicts with content widget hotkeys
RISKS:
  - Menu hotkey conflicts with inline editor
  - MenuBar shared across screens may affect others
```

## Important Notes

- ALWAYS read the actual file - never assume structure
- ALWAYS search for similar screens - don't guess
- ALWAYS provide specific file paths in output
- NEVER apply fixes without running this validation first
- Patterns may differ from documentation - trust the code

## Integration with Workflow

This skill should be invoked:
1. **Before** making changes (validation)
2. **After** reading user's bug report (understanding)
3. **Before** searching for affected files (planning)

Workflow:
```
User reports bug
  ↓
Invoke tui-fix-validator skill
  ↓
Review validation report
  ↓
Ask user for clarification if needed
  ↓
Apply fix to target screen
  ↓
Check similar screens from report
  ↓
Run verification checklist
  ↓
Report completion
```
