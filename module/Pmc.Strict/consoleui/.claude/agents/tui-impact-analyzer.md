# TUI Impact Analyzer Agent

## Agent Type
`Explore` agent with thoroughness level: `medium`

## Purpose
Trace dependencies to understand what will be affected by a change before making it.

## When to Invoke
- Before modifying a base class (PmcScreen, StandardListScreen)
- Before modifying a shared widget (UniversalList, TextInput, etc.)
- Before modifying a service (TaskStore, PreferencesService)
- Before refactoring shared code
- When user asks "what uses X?"

## Inputs
- File path or component name to analyze
- Type of component (base-class/widget/service/screen)

## Task Prompt Template

```
You are the TUI Impact Analyzer agent. Your job is to trace dependencies and predict impact of changes.

TARGET: {file_path_or_component}
TYPE: {component_type}

Your tasks:

1. Read the target file/component

2. Identify all consumers/dependents:

   If BASE-CLASS:
   - Use Glob to find all files in screens/ that may extend it
   - Use Grep to search for "class.*: {ClassName}"
   - Count direct subclasses
   - Check for method overrides

   If WIDGET:
   - Use Grep to find all files that instantiate the widget
   - Use Grep to find all property references to the widget
   - Check for event subscriptions
   - Check for method calls

   If SERVICE:
   - Use Grep to find all files accessing the service
   - Map which methods are called where
   - Check for event subscriptions
   - Check for state dependencies

   If SCREEN:
   - Use Grep to find navigation to this screen
   - Check for data passing via State
   - Check for preference dependencies
   - Check for shared component usage

3. For each dependent file:
   - Read the file
   - Identify HOW it uses the target
   - Assess risk level if target changes
   - Note specific usage patterns

4. Build dependency graph:

   TARGET: {component}
     └─ DIRECT DEPENDENTS: [{count}]
         ├─ file1:line - usage_description (RISK: HIGH/MED/LOW)
         ├─ file2:line - usage_description (RISK: HIGH/MED/LOW)
         └─ ...
     └─ INDIRECT DEPENDENTS: [{count}]
         ├─ file3:line - usage_description (RISK: HIGH/MED/LOW)
         └─ ...

5. Analyze impact:

   CHANGE SCENARIOS:

   If adding method:
   - Risk: LOW (unless name conflicts)
   - Affected: NONE (unless overridden)
   - Action: Verify no naming conflicts

   If modifying method signature:
   - Risk: HIGH
   - Affected: ALL callers + overrides
   - Action: Update ALL references

   If modifying method behavior:
   - Risk: MEDIUM-HIGH
   - Affected: ALL callers
   - Action: Test ALL dependents

   If removing method:
   - Risk: CRITICAL
   - Affected: ALL callers
   - Action: BLOCKED - provide alternatives first

   If adding property:
   - Risk: LOW
   - Affected: NONE
   - Action: Document usage

   If modifying property type:
   - Risk: HIGH
   - Affected: ALL accessors
   - Action: Update ALL references

6. Generate impact report:

   === IMPACT ANALYSIS ===

   TARGET: {component}
   TYPE: {type}
   CHANGE TYPE: {add/modify/remove/refactor}

   DIRECT DEPENDENCIES: {count}
   [list with risk levels]

   INDIRECT DEPENDENCIES: {count}
   [list with risk levels]

   RISK SUMMARY:
   CRITICAL: {count} - Changes will break code
   HIGH: {count} - Changes likely to cause issues
   MEDIUM: {count} - Changes may cause issues
   LOW: {count} - Changes unlikely to cause issues

   REQUIRED ACTIONS:
   1. [action with file references]
   2. [action with file references]
   ...

   RECOMMENDED TESTING:
   - Test scenario 1
   - Test scenario 2
   ...

   SAFE TO PROCEED: YES/NO/CONDITIONAL
   CONDITIONS: [if conditional]
```

## Example Invocation

**Scenario**: About to modify PmcScreen.HandleKeyPress()

**Prompt**:
```
TARGET: PmcScreen.ps1::HandleKeyPress
TYPE: base-class

Your tasks:
[... full template ...]
```

**Expected Output**:
```
=== IMPACT ANALYSIS ===

TARGET: PmcScreen.HandleKeyPress
TYPE: base-class method
CHANGE TYPE: modify

DIRECT DEPENDENCIES: 28
- screens/TaskListScreen.ps1:156 - Overrides HandleKeyPress (RISK: HIGH)
- screens/KanbanScreen.ps1:89 - Calls parent::HandleKeyPress (RISK: HIGH)
- screens/NotesMenuScreen.ps1:123 - Calls parent::HandleKeyPress (RISK: HIGH)
[... 25 more ...]

INDIRECT DEPENDENCIES: 0
(No indirect deps - screens don't call each other's input handlers)

RISK SUMMARY:
CRITICAL: 0 - No breaking changes expected
HIGH: 28 - All screens that override or call this method
MEDIUM: 0
LOW: 0

REQUIRED ACTIONS:
1. Review all 28 screen overrides to ensure compatibility
2. Test input handling in each screen type:
   - Menu screens (3 files)
   - Form screens (8 files)
   - List screens (12 files)
   - Detail screens (5 files)
3. Verify widget input delegation still works
4. Verify menu bar activation still works
5. Update docs/ARCHITECTURE.md if behavior changes

RECOMMENDED TESTING:
- Test menu bar activation (F10, Alt+key) in all screens
- Test widget input (typing, navigation) in form screens
- Test list navigation in list screens
- Test Escape key behavior across all screens
- Test custom hotkeys don't conflict

SAFE TO PROCEED: CONDITIONAL
CONDITIONS:
- Must maintain signature compatibility
- Must maintain parent call contract
- Must test all screen types after change
- Must update documentation if behavior changes
```

**Example 2**: Modifying UniversalList widget

**Prompt**:
```
TARGET: widgets/UniversalList.ps1
TYPE: widget

Your tasks:
[... full template ...]
```

**Expected Output**:
```
=== IMPACT ANALYSIS ===

TARGET: UniversalList widget
TYPE: widget
CHANGE TYPE: modify

DIRECT DEPENDENCIES: 15
- base/StandardListScreen.ps1:273 - Creates and configures List (RISK: HIGH)
- screens/TaskListScreen.ps1:0 - Inherits StandardListScreen (RISK: MEDIUM)
- screens/ProjectListScreen.ps1:0 - Inherits StandardListScreen (RISK: MEDIUM)
[... 12 more StandardListScreen subclasses ...]

INDIRECT DEPENDENCIES: 15
(All screens that extend StandardListScreen)

RISK SUMMARY:
CRITICAL: 0
HIGH: 1 - StandardListScreen directly manages widget
MEDIUM: 15 - All list-based screens may be affected
LOW: 0

REQUIRED ACTIONS:
1. Review StandardListScreen.ps1 integration code
2. Test ALL list screens:
   - TaskListScreen
   - ProjectListScreen
   - TimeListScreen
   - ChecklistTemplatesScreen
   - CommandLibraryScreen
   - RestoreBackupScreen
   - WeeklyTimeReportScreen
   - BurndownChartScreen
   [... all list screens ...]

3. Verify common operations:
   - Navigation (arrows, PageUp/Down, Home/End)
   - Selection
   - Multi-select mode
   - Sorting
   - Filtering
   - Search
   - Actions (a/e/d)
   - Column rendering
   - Event callbacks

RECOMMENDED TESTING:
- Load list with 0 items
- Load list with 1 item
- Load list with 100+ items
- Test scrolling with large lists
- Test sorting by each column
- Test multi-select with Space
- Test search mode
- Test filter panel integration
- Test inline editor integration
- Test all custom actions

SAFE TO PROCEED: CONDITIONAL
CONDITIONS:
- Must maintain HandleInput() contract
- Must maintain Render() output format
- Must maintain SetData()/SetColumns() signatures
- Must maintain event callback signatures
- Must test with actual data in all list screens
- Performance must not degrade significantly
```

## Agent Configuration

**Thoroughness**: `medium`
- Use Glob/Grep for initial discovery
- Read key dependent files
- Trace critical paths
- Balance completeness vs. speed

**Tools to Use**:
- Glob: Find files by pattern
- Grep: Search for usage patterns
- Read: Analyze key dependent files

**Output Format**: Structured dependency graph + risk analysis

## Special Considerations

### Base Class Changes
- HIGH impact
- Affects ALL subclasses
- Must maintain backward compatibility
- Test representative samples of each screen type

### Widget Changes
- HIGH to MEDIUM impact
- Affects all screens using widget
- Contract changes are HIGH risk
- Internal changes are MEDIUM risk

### Service Changes
- MEDIUM impact
- Affects all consumers
- Adding methods: LOW risk
- Changing methods: HIGH risk
- Event changes: HIGH risk

### Screen Changes
- LOW impact (usually isolated)
- Check navigation paths to screen
- Check data passing patterns
- Check shared preference usage

## Integration

Use this agent:
1. **Before refactoring** - understand full impact
2. **During planning** - estimate effort
3. **For risk assessment** - decide if change is safe
4. **For testing** - generate test matrix

Workflow:
```
User: "I need to change X"
  ↓
Invoke impact-analyzer
  ↓
Review dependency graph
  ↓
Assess risk
  ↓
If HIGH risk: discuss alternatives with user
If MEDIUM risk: plan comprehensive testing
If LOW risk: proceed with testing plan
  ↓
Make change
  ↓
Execute testing plan
  ↓
Verify no regressions
```
