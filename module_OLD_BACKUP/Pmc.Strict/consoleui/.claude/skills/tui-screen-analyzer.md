# TUI Screen Analyzer Skill

## Purpose
Analyze a screen file to understand its structure, patterns, dependencies, and potential issues.

## When to Invoke
- Before fixing a bug in a screen
- When understanding how a feature works
- When refactoring code
- When documenting patterns

## Inputs Expected
- File path to screen file

## Execution Steps

### Step 1: Read the Screen File
Read the complete screen file.

### Step 2: Extract Basic Information

**Class Information:**
- Class name
- Base class (PmcScreen, StandardListScreen, or other)
- Constructor parameters
- Constructor call to parent

**Properties:**
- Widget properties (List, FilterPanel, InlineEditor, TextInput, etc.)
- State properties
- Configuration flags (AllowAdd, AllowEdit, AllowDelete, etc.)

### Step 3: Analyze Lifecycle Methods

**Check for:**
- `OnEnter()` - What it initializes, what data it loads
- `OnExit()` - What it cleans up
- `LoadData()` - Where data comes from, how it's processed

**Identify:**
- Missing lifecycle methods
- Parent method calls
- Data loading patterns
- State initialization

### Step 4: Analyze Rendering

**RenderContent() Analysis:**
- What widgets are rendered
- ANSI string construction
- Conditional rendering (editors, panels, etc.)
- Layout calculations

**RenderToEngine() Analysis (if exists):**
- Direct engine calls
- Performance optimizations

### Step 5: Analyze Input Handling

**HandleKeyPress() / HandleInput():**
- Widget input delegation order
- Menu bar handling
- Content widget handling
- Custom key handling
- Parent delegation

**Check for:**
- Proper delegation order
- Return value checking from widgets
- Input consumed vs. passed through
- Hotkey conflicts

### Step 6: Analyze Widget Integration

**For each widget used:**
- Initialization location and method
- Event callback registration
- Use of `.GetNewClosure()`
- Variable capture (`$self` vs `$this`)
- Rendering integration
- Input delegation

### Step 7: Analyze Data Operations

**TaskStore Usage:**
- Which methods called
- Where `.Save()` is called
- Data mutation patterns
- Event subscriptions

**PreferencesService Usage:**
- Preferences read/written
- Save patterns

### Step 8: Identify Patterns

**Pattern Classification:**
- Menu screen pattern
- Form screen pattern
- List screen pattern
- Detail/view screen pattern
- Complex multi-widget pattern

**Pattern Adherence:**
- Follows standard pattern: YES/NO
- Deviations from pattern: [list]
- Pattern-specific issues: [list]

### Step 9: Identify Issues and Risks

**Common Issues:**
- Missing parent calls
- Widget initialization issues
- Event callback issues (closure, variable capture)
- Input delegation order wrong
- Missing bounds checks
- Missing .Save() calls
- Memory leaks (event handlers not cleaned up)

**Code Smells:**
- Duplicate logic
- Hard-coded values
- Missing error handling
- Overly complex methods
- Magic numbers

### Step 10: Analyze Dependencies

**Widget Dependencies:**
- UniversalList
- TextInput
- InlineEditor
- FilterPanel
- ProjectPicker
- Custom widgets

**Service Dependencies:**
- TaskStore
- PreferencesService
- ExcelComReader
- Custom services

**Screen Dependencies:**
- Navigation to other screens
- Data passed to other screens

### Step 11: Generate Analysis Report

Return structured report:
```
=== SCREEN ANALYSIS ===

CLASS: [name]
TYPE: [Menu/Form/List/Detail/Complex]
BASE: [parent class]

LIFECYCLE:
  OnEnter(): [implemented YES/NO] [summary]
  OnExit(): [implemented YES/NO] [summary]
  LoadData(): [implemented YES/NO] [summary]

WIDGETS:
  - [widget name]: [initialization OK/ISSUE] [events OK/ISSUE]
  - ...

RENDERING:
  RenderContent(): [summary of what's rendered]
  [any issues]

INPUT HANDLING:
  Delegation Order: [correct/incorrect]
  Parent Calls: [present/missing]
  [any issues]

DATA OPERATIONS:
  TaskStore: [methods used]
  Save() Calls: [locations]
  [any issues]

PATTERN ADHERENCE:
  Pattern: [name]
  Adherence: [good/partial/poor]
  Issues: [list]

ISSUES FOUND:
  CRITICAL: [list]
  HIGH: [list]
  MEDIUM: [list]
  LOW: [list]

DEPENDENCIES:
  Widgets: [list]
  Services: [list]
  Screens: [list]

RECOMMENDATIONS:
  1. [recommendation]
  2. [recommendation]
  ...
```

## Example Usage

**Input**: `screens/TaskListScreen.ps1`

**Output**:
```
=== SCREEN ANALYSIS ===

CLASS: TaskListScreen
TYPE: List
BASE: StandardListScreen

LIFECYCLE:
  OnEnter(): YES - Calls parent, sets breadcrumb
  OnExit(): YES - Calls parent, cleans event handlers
  LoadData(): YES - Loads tasks from TaskStore, filters, sets to List

WIDGETS:
  - UniversalList: OK - Initialized in parent, events configured
  - FilterPanel: OK - Initialized in parent
  - InlineEditor: OK - Initialized in parent

RENDERING:
  RenderContent(): Delegates to List.Render() or InlineEditor.Render()
  No issues found

INPUT HANDLING:
  Delegation Order: CORRECT - InlineEditor → FilterPanel → List
  Parent Calls: PRESENT
  No issues found

DATA OPERATIONS:
  TaskStore: GetAllTasks(), UpdateTask(), DeleteTask(), Save()
  Save() Calls: After UpdateTask() in OnItemUpdated()
  No issues found

PATTERN ADHERENCE:
  Pattern: StandardListScreen
  Adherence: GOOD
  Issues: None

ISSUES FOUND:
  CRITICAL: None
  HIGH: None
  MEDIUM: None
  LOW: None

DEPENDENCIES:
  Widgets: UniversalList, FilterPanel, InlineEditor
  Services: TaskStore
  Screens: TaskDetailScreen (navigation on item activation)

RECOMMENDATIONS:
  1. Consider caching loaded tasks if performance becomes issue
  2. Add error handling for TaskStore failures
```

## Important Notes

- Read the ENTIRE file before analyzing
- Don't assume patterns - verify from code
- Look for subtle issues (variable capture, closure issues)
- Check both explicit and implicit dependencies
- Consider screen interaction patterns, not just isolated logic

## Integration Points

This skill feeds into:
- `tui-fix-validator` (provides context for validation)
- `tui-pattern-enforcer` (identifies pattern violations)
- Documentation updates (accurate pattern examples)
