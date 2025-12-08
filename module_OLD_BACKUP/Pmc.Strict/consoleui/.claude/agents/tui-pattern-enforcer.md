# TUI Pattern Enforcer Agent

## Agent Type
`Explore` agent with thoroughness level: `quick`

## Purpose
Compare a screen implementation against established patterns and report violations.

## When to Invoke
- Before applying a fix (validate current state)
- After applying a fix (validate new state)
- During code review
- When learning patterns for new feature

## Inputs
- File path of screen to check
- Pattern type to validate against (menu/form/list/detail/custom)

## Task Prompt Template

```
You are the TUI Pattern Enforcer agent. Your job is to validate screen implementations against established patterns.

SCREEN FILE: {file_path}
EXPECTED PATTERN: {pattern_type}

Your tasks:

1. Read the screen file

2. Read the pattern documentation:
   - .claude/docs/SCREEN_PATTERNS.md
   - .claude/docs/ARCHITECTURE.md (for lifecycle methods)
   - .claude/docs/WIDGET_CONTRACTS.md (if widgets used)

3. Validate the screen against the pattern:

   LIFECYCLE METHODS:
   - [ ] OnEnter() exists and calls parent
   - [ ] OnExit() exists and calls parent
   - [ ] LoadData() exists (if data-driven)
   - [ ] Proper initialization order

   RENDERING:
   - [ ] RenderContent() returns ANSI string
   - [ ] Widget rendering integrated correctly
   - [ ] No hard-coded positions (use layout or widget positions)

   INPUT HANDLING:
   - [ ] HandleKeyPress() delegates to widgets first
   - [ ] HandleInput() checks return values
   - [ ] Parent methods called appropriately
   - [ ] No input handler conflicts

   WIDGET INTEGRATION (if applicable):
   - [ ] Widgets initialized in correct lifecycle method
   - [ ] Event callbacks use .GetNewClosure()
   - [ ] Correct variable capture ($self, not $this)
   - [ ] Widget input delegation order correct
   - [ ] Widget state managed correctly

   DATA OPERATIONS (if applicable):
   - [ ] TaskStore accessed via $this.Store or service reference
   - [ ] .Save() called after mutations
   - [ ] Event subscriptions cleaned up in OnExit()
   - [ ] Proper error handling

   PATTERN-SPECIFIC (based on expected pattern):

   If MENU pattern:
   - [ ] MenuBar widget configured
   - [ ] Menu items have proper structure
   - [ ] Menu callbacks properly bound
   - [ ] Menu hotkeys don't conflict

   If FORM pattern:
   - [ ] Input widget initialized
   - [ ] Input delegated to widget
   - [ ] Validation before submission
   - [ ] Submit action calls service

   If LIST pattern:
   - [ ] Extends StandardListScreen
   - [ ] GetColumns() implemented
   - [ ] GetEditFields() implemented
   - [ ] LoadData() loads into List widget
   - [ ] Actions configured if needed

4. Generate report:

   PATTERN: {pattern_type}
   COMPLIANCE: PASS/FAIL/PARTIAL
   SCORE: {passed_checks}/{total_checks}

   VIOLATIONS:
   CRITICAL: [violations that will cause bugs]
   - file:line - description

   WARNINGS: [violations that may cause issues]
   - file:line - description

   SUGGESTIONS: [improvements for better pattern adherence]
   - file:line - description

   CORRECT PATTERNS:
   [list aspects that follow the pattern well]

5. If violations found, provide corrected code examples

6. Return report
```

## Example Invocation

**Scenario**: Validate TaskListScreen against list pattern

**Prompt**:
```
SCREEN FILE: screens/TaskListScreen.ps1
EXPECTED PATTERN: list

Your tasks:
[... full template ...]
```

**Expected Output**:
```
PATTERN: list
COMPLIANCE: PASS
SCORE: 18/18

VIOLATIONS:
CRITICAL: None

WARNINGS: None

SUGGESTIONS:
- TaskListScreen.ps1:45 - Consider adding custom action for batch operations
- TaskListScreen.ps1:78 - Could cache filtered results for performance

CORRECT PATTERNS:
- Properly extends StandardListScreen
- GetColumns() provides complete column definitions with formatters
- GetEditFields() provides proper field structure
- LoadData() correctly loads and filters tasks
- Event callbacks properly use .GetNewClosure()
- OnExit() cleans up event subscriptions
- Input handling follows delegation pattern
```

**Example with Violations**:
```
PATTERN: form
COMPLIANCE: FAIL
SCORE: 8/12

VIOLATIONS:
CRITICAL:
- FocusSetFormScreen.ps1:32 - Widget not initialized (missing TextInput.Initialize())
- FocusSetFormScreen.ps1:45 - Input not delegated to widget before custom handling
- FocusSetFormScreen.ps1:67 - Missing .Save() call after TaskStore.UpdateTask()

WARNINGS:
- FocusSetFormScreen.ps1:38 - No validation before submission
- FocusSetFormScreen.ps1:71 - Parent.HandleInput() not called

SUGGESTIONS:
- FocusSetFormScreen.ps1:50 - Consider adding loading state indicator

CORRECT PATTERNS:
- Extends PmcScreen correctly
- OnEnter() calls parent
- RenderContent() properly renders widget

CORRECTED CODE EXAMPLES:

Issue: Widget not initialized
Current (line 32):
```powershell
$this.textInput = [TextInput]::new()
```

Correct:
```powershell
$this.textInput = [TextInput]::new()
$this.textInput.Initialize($this.RenderEngine)
```

Issue: Input not delegated to widget
Current (line 45):
```powershell
[bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
    if ($keyInfo.Key -eq 'Enter') {
        $this.OnSubmit()
    }
}
```

Correct:
```powershell
[bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
    if ($this.textInput.HandleInput($keyInfo)) {
        return $true  # Widget consumed input
    }

    if ($keyInfo.Key -eq 'Enter') {
        $this.OnSubmit()
        return $true
    }

    return $false
}
```
```

## Agent Configuration

**Thoroughness**: `quick`
- Read target screen file fully
- Read relevant pattern docs
- Quick validation against checklist
- Provide specific line references
- Fast turnaround (< 30 seconds)

**Tools to Use**:
- Read: Screen file, pattern docs
- Grep: Search for specific patterns if needed

**Output Format**: Structured markdown report with code examples

## Pattern Checklist Details

### Menu Pattern Checklist
```
- [ ] MenuBar widget present
- [ ] Menu items configured in OnEnter()
- [ ] Menu callbacks use .GetNewClosure()
- [ ] F10 activates menu
- [ ] Alt+key hotkeys mapped
- [ ] Menu state managed correctly
- [ ] No conflicts with content widgets
```

### Form Pattern Checklist
```
- [ ] Input widget(s) initialized
- [ ] Widget.Initialize() called
- [ ] Input delegation order correct
- [ ] HandleInput checks widget return value
- [ ] Validation before submission
- [ ] TaskStore.Save() after mutations
- [ ] Error handling for invalid input
```

### List Pattern Checklist
```
- [ ] Extends StandardListScreen
- [ ] GetColumns() returns proper structure
- [ ] GetEditFields() returns proper structure
- [ ] LoadData() populates List.SetData()
- [ ] GetEntityType() returns correct type (if not 'task')
- [ ] Optional overrides implemented if needed
- [ ] Event subscriptions cleaned up
```

### Base Requirements (all patterns)
```
- [ ] OnEnter() exists and calls parent
- [ ] OnExit() exists and calls parent
- [ ] RenderContent() returns ANSI string
- [ ] HandleKeyPress() / HandleInput() present
- [ ] Widget event callbacks use .GetNewClosure()
- [ ] Proper variable capture in closures
- [ ] Parent method calls where required
```

## Integration

Invoke this agent:
1. **Before fixing** - understand current violations
2. **After fixing** - verify fix didn't introduce new violations
3. **During review** - validate patterns across codebase
4. **When learning** - understand how pattern should be implemented

Workflow:
```
User: "Fix X in YScreen"
  ↓
Invoke pattern-enforcer (before)
  ↓
Review violations
  ↓
Apply fix
  ↓
Invoke pattern-enforcer (after)
  ↓
Compare before/after
  ↓
If new violations: fix them
  ↓
If violations resolved: proceed
```

## Note on Pattern Evolution

Patterns may evolve. If the agent finds consistent "violations" across many screens that work correctly, it may indicate:
1. Pattern documentation is outdated
2. A new pattern has emerged
3. Pattern has exceptions

In these cases, update .claude/docs/ with correct patterns.
