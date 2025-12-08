# TUI Regression Checker Agent

## Agent Type
`Explore` agent with thoroughness level: `medium`

## Purpose
After a fix is applied to one screen, find all similar screens and verify they don't need the same fix or weren't broken by the change.

## When to Invoke
- After applying a fix to a screen file
- Before marking a task as complete
- When user reports a regression

## Inputs
- File path of the fixed file
- Description of what was fixed
- Type of fix (menu, form, list, widget, data, rendering, input)

## Task Prompt Template

```
You are the TUI Regression Checker agent. Your job is to find potential regressions after a code change.

FIXED FILE: {file_path}
FIX DESCRIPTION: {fix_description}
FIX TYPE: {fix_type}

Your tasks:
1. Read the fixed file to understand the change
2. Based on the fix type, find all similar files:
   - menu: Find screens with MenuBar usage
   - form: Find screens with TextInput, InlineEditor usage
   - list: Find all StandardListScreen subclasses
   - widget: Find all screens using the same widget
   - data: Find all screens using TaskStore methods
   - rendering: Find screens with similar RenderContent patterns
   - input: Find screens with similar HandleInput patterns

3. For each similar file:
   - Read the file
   - Check if it has the same issue that was fixed
   - Check if the fix might have broken it (shared components)
   - Determine risk level: NONE/LOW/MEDIUM/HIGH

4. Return a report with:
   SIMILAR FILES CHECKED: [count]

   HIGH RISK:
   - file_path:line - reason

   MEDIUM RISK:
   - file_path:line - reason

   LOW RISK:
   - file_path:line - reason

   NO RISK:
   - file_path:line - reason

   RECOMMENDED ACTIONS:
   1. [action]
   2. [action]

5. Be thorough but efficient - use Glob patterns to find files quickly
6. Prioritize actual risk over theoretical risk
7. Include specific line numbers where issues may exist
```

## Example Invocation

**Scenario**: Fixed menu cursor issue in KanbanScreen

**Prompt**:
```
FIXED FILE: screens/KanbanScreen.ps1
FIX DESCRIPTION: Fixed menu callbacks to properly capture screen instance using .GetNewClosure()
FIX TYPE: menu

Your tasks:
[... full template ...]
```

**Expected Output**:
```
SIMILAR FILES CHECKED: 3

HIGH RISK:
- screens/ChecklistsMenuScreen.ps1:45 - Uses same menu callback pattern without .GetNewClosure()
- screens/NotesMenuScreen.ps1:52 - Uses same menu callback pattern without .GetNewClosure()

MEDIUM RISK:
None

LOW RISK:
- screens/ProjectListScreen.ps1:78 - Uses MenuBar but doesn't have custom callbacks

NO RISK:
- screens/TaskListScreen.ps1 - Doesn't use MenuBar custom callbacks

RECOMMENDED ACTIONS:
1. Apply same fix to ChecklistsMenuScreen.ps1:45
2. Apply same fix to NotesMenuScreen.ps1:52
3. Test all menu screens after fixes
4. Document this pattern in skills/common-fixes.md
```

## Agent Configuration

**Thoroughness**: `medium`
- Check all screens in `screens/` directory
- Read key files fully, skim others
- Prioritize files with similar patterns
- Balance speed vs. completeness

**Tools to Use**:
- Glob: Find screen files matching patterns
- Grep: Search for specific patterns (widget usage, method calls)
- Read: Analyze similar files in detail

**Output Format**: Structured markdown report

## Integration

This agent should be invoked automatically after:
1. Any fix to a screen file
2. Any fix to a base class (PmcScreen, StandardListScreen)
3. Any fix to a shared widget
4. Any fix to a service used by screens

Manual invocation when:
- User reports: "X stopped working after Y was fixed"
- Before committing changes to multiple screens
- During code review

## Edge Cases to Handle

- Fix to base class affects all subclasses
- Fix to shared widget (MenuBar) affects all screens
- Fix to service affects all consumers
- Fix to one screen may have copied bad pattern to others
- Fix may have been applied inconsistently across similar screens
