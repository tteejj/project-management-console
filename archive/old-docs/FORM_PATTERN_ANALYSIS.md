# Form Pattern Analysis - ConsoleUI.Core.ps1

## Executive Summary

The codebase has **two distinct form patterns**:

1. **Legacy Pattern** - Manual keyboard input handling with direct terminal I/O
   - DrawProjectCreateForm/HandleProjectCreateForm
   - DrawEditProjectForm/HandleEditProjectForm
   - DrawSearchForm/HandleSearchForm
   - Direct Console.ReadKey() loop with character accumulation

2. **Modern Pattern** - Widget-based form abstraction using Show-InputForm
   - DrawTaskAddForm/HandleTaskAddForm
   - HandleTaskEditForm (no matching Draw method)
   - HandleAddSubtaskForm
   - Delegates rendering and input handling to Show-InputForm function

---

## Pattern Comparison

### LEGACY PATTERN (Project Forms)

**Characteristics:**
- Each form manually implements its own input loop
- Direct keyboard event handling
- Character-by-character accumulation
- Field-level rendering and cursor positioning

**Example: DrawProjectCreateForm / HandleProjectCreateForm**

```powershell
# Draw Phase: Just shows labels and empty state
[void] DrawProjectCreateForm([int]$ActiveField = -1) {
    # Renders labels with optional highlight for active field
    # Only shows structure, not actual field data
}

# Handle Phase: Complete input loop and processing
[void] HandleProjectCreateForm() {
    # 1. Define fields array with X,Y positioning
    $fields = @(
        @{ Name='Name'; Label='Project Name (required):'; X=28; Y=6; Value='' }
        @{ Name='Description'; Label='Description:'; X=16; Y=7; Value='' }
        # ... 11 fields total
    )
    
    # 2. Main input loop - field-by-field
    $active = 0
    $prevActive = -1
    while ($true) {
        $f = $fields[$active]
        
        # Highlight active field label
        if ($prevActive -ne $active) {
            # Unhighlight previous
            $this.terminal.WriteAtColor(4, $pf['Y'], $pf['Label'], [PmcVT100]::Yellow(), "")
            # Highlight current
            $this.terminal.WriteAtColor(4, $f['Y'], $f['Label'], [PmcVT100]::BgBlue(), [PmcVT100]::White())
        }
        
        # Position cursor at end of value
        [Console]::SetCursorPosition($col + $buf.Length, $row)
        
        # Read single key
        $k = [Console]::ReadKey($true)
        
        # Handle key events
        if ($k.Key -eq 'Enter') { break }
        elseif ($k.Key -eq 'Tab') { 
            # Navigate forward/backward
            $active = ($active + 1) % $fields.Count
        }
        elseif ($k.Key -eq 'F2') {
            # Special handling: file picker for certain fields
            $picked = Select-ConsoleUIPathAt -app $this ...
        }
        elseif ($k.Key -eq 'Backspace') {
            # Character deletion
            $buf = $buf.Substring(0, $buf.Length - 1)
        }
        else {
            # Accumulate character
            $buf += $k.KeyChar
        }
    }
    
    # 3. Validation and save
    # Validate each field
    # Create/update project object
    # Save via Set-PmcAllData or Save-PmcData
}
```

**Strengths:**
- Fine-grained control over UI positioning
- Direct field access and modification
- F2 key integration for path picking

**Weaknesses:**
- Massive code duplication across forms
- Complex input loop logic repeated everywhere
- Difficult to maintain consistent behavior
- No reusable field components
- Manual cursor positioning and highlighting
- Inconsistent validation logic

---

### MODERN PATTERN (Task Forms)

**Characteristics:**
- Uses centralized Show-InputForm function
- Declarative field definitions
- Consistent rendering and navigation
- Automatic validation

**Example: HandleTaskAddForm / HandleTaskEditForm**

```powershell
[void] HandleTaskAddForm() {
    # 1. Simple field definition
    $input = Show-InputForm -Title "Add New Task" -Fields @(
        @{Name='text'; Label='Task description'; Required=$true; Type='text'}
        @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList}
        @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low')}
        @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'}
    )
    
    # 2. Check for cancellation
    if ($null -eq $input) {
        $this.GoBackOr('tasklist')
        return
    }
    
    # 3. Extract and validate values
    $taskText = $input['text']
    if ($taskText.Length -lt 3) {
        Show-InfoMessage -Message "Task description must be at least 3 characters" ...
        return
    }
    
    # 4. Process field data (parsing, normalization)
    $priority = 'medium'
    if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
        $priority = switch -Regex ($input['priority'].Trim().ToLower()) {
            '^h(igh)?$' { 'high' }
            '^l(ow)?$' { 'low' }
            '^m(edium)?$' { 'medium' }
            default { 'medium' }
        }
    }
    
    # 5. Create object and save
    $newTask = [PSCustomObject]@{
        id = $newId
        text = $taskText.Trim()
        status = 'active'
        priority = $priority
        # ... other fields
    }
    $data.tasks += $newTask
    Save-PmcData -Data $data -Action "Added task $newId"
}

[void] HandleTaskEditForm() {
    # Key difference: Prepopulate fields with current values
    $input = Show-InputForm -Title "Edit Task #$taskId" -Fields @(
        @{Name='text'; Label='Task description'; Required=$true; Type='text'; Value=$currentText}
        @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList; Value=$currentProject}
        @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low'); Value=$currentPriority}
        @{Name='due'; Label='Due date'; Required=$false; Type='text'; Value=$currentDue}
    )
    
    # Track changes and only save if modified
    $changed = $false
    if ($input['text'] -ne $currentText) {
        $task.text = $input['text'].Trim()
        $changed = $true
    }
    # ... check other fields for changes
    
    if ($changed) {
        $task | Add-Member -MemberType NoteProperty -Name 'modified' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force
        Save-PmcData -Data $data -Action "Edited task $taskId"
    }
}
```

**Strengths:**
- DRY principle - single Show-InputForm implementation
- Declarative field definitions
- Consistent UX across all forms using it
- Built-in navigation (Tab, Shift+Tab)
- Automatic required field validation
- Cleaner separation: data vs. presentation

**Weaknesses:**
- Less control over layout (fixed box rendering)
- No F2 picker integration yet
- Limited to simple field types (text, select)

---

## Field Types Analysis

### Supported Field Types

| Type | Pattern | Usage | Value Format |
|------|---------|-------|--------------|
| **text** | Both | Single-line text input | String, free-form |
| **select** | Modern | Dropdown list selection | String, must match option |
| **date** (implicit) | Legacy | Date fields parsed post-input | String, various formats (yyyy-MM-dd, today, +N) |
| **path** (implicit) | Legacy | File/folder picker via F2 | String, absolute path |

### Field Collection Examples

**Task Add/Edit Form:**
- text (required)
- project (optional, select from list)
- priority (optional, select: high/medium/low)
- due (optional, text with parsing)

**Project Create Form:**
- Name (required)
- Description (optional)
- ID1, ID2 (optional metadata)
- ProjFolder, CAAName, RequestName, T2020 (optional with F2 picker)
- AssignedDate, DueDate, BFDate (optional dates)

**Subtask Add Form:**
- text (required, single field)

---

## Navigation Logic

### Keyboard Events

#### Tab Navigation (Both Patterns)

**Legacy (Project Forms):**
```powershell
elseif ($k.Key -eq 'Tab') {
    $isShift = ("" + $k.Modifiers) -match 'Shift'
    if ($isShift) { 
        $active = ($active - 1); 
        if ($active -lt 0) { $active = $fields.Count - 1 } 
    } else { 
        $active = ($active + 1) % $fields.Count 
    }
    continue
}
```

**Modern (Show-InputForm):**
```powershell
elseif ($k.Key -eq 'Tab') {
    $isShift = ("" + $k.Modifiers) -match 'Shift'
    if ($isShift) { $active = ($active - 1); if ($active -lt 0) { $active = $norm.Count - 1 } }
    else { $active = ($active + 1) % $norm.Count }
    continue
}
```

Both: Circular tab navigation, forward with Tab, backward with Shift+Tab

#### Text Input (Manual Pattern)

**Character Accumulation:**
```powershell
$ch = $k.KeyChar
if ($ch -and $ch -ne "`0") {
    $buf += $ch
    $fields[$active]['Value'] = $buf
    $this.terminal.WriteAt($col + $buf.Length - 1, $row, $ch.ToString())
}
```

**Backspace:**
```powershell
elseif ($k.Key -eq 'Backspace') {
    if ($buf.Length -gt 0) {
        $buf = $buf.Substring(0, $buf.Length - 1)
        # Redraw field
    }
}
```

**Enter:** Either submit or navigate in modern pattern

#### Special Keys

| Key | Behavior |
|-----|----------|
| **Enter** | Modern: Submit (if all required fields filled) or select item for 'select' fields |
| | Legacy: End field input loop; continue to validation |
| **Escape** | Both: Cancel operation, return to previous view |
| **F2** | Legacy only: File/folder picker for specific fields |
| **Arrow Keys** | Used in selection lists (Show-SelectList), not in form fields |

---

## Rendering

### Legacy Form Rendering (Draw + Handle Combined)

1. **Initial DrawProjectCreateForm() call:**
   - Clear and setup layout
   - Draw labels with yellow highlight
   - Show empty input lines

2. **During HandleProjectCreateForm() loop:**
   - Highlight active field label (blue background)
   - Cursor positioned at end of current input
   - Character-by-character echo to field location
   - Active field label toggles between yellow and blue

**Color Scheme (Legacy):**
- Yellow: Inactive labels, default text
- Blue (BgBlue + White): Active field label highlight
- Cyan: Box borders, instructions

### Modern Form Rendering (Show-InputForm)

1. **Setup Phase:**
   - Calculate centered box dimensions
   - Draw box border (cyan)
   - Render title (blue background, white text)

2. **Field Rendering Loop:**
   ```powershell
   for ($i=0; $i -lt $norm.Count; $i++) {
       $isActive = ($i -eq $active)
       $labelColor = if ($isActive) { [PmcVT100]::Yellow() } else { [PmcVT100]::Cyan() }
       
       # Label row
       $terminal.WriteAtColor(..., $labelText, $labelColor, "")
       
       # Value row (with required indicator)
       $val = [string]$f.Value
       if ($f.Type -eq 'select' -and $val -eq '') { $val = '(choose)' }
       
       if ($isActive) {
           $terminal.FillArea(..., ' ')  # Clear previous value
           $terminal.WriteAtColor(..., $val, [PmcVT100]::White(), "")
       } else {
           $terminal.WriteAt(..., $val)  # Normal text
       }
   }
   ```

3. **Navigation Rendering:**
   - Cursor positioned at end of active field value
   - Active field value in white
   - Inactive field values in default color
   - Required fields marked with asterisk

**Color Scheme (Modern):**
- Cyan: Inactive labels, box border, instructions
- Yellow: Active label
- White: Active field value
- Default: Inactive field values

---

## Validation

### Add vs. Edit Validation

**Add Form (Task/Project):**
1. **Basic checks** - Required fields present
2. **Format validation** - Length, date format, enum values
3. **Uniqueness** - Project name doesn't exist
4. **Post-processing** - Normalize dates, parse special syntax

**Example - Task Add:**
```powershell
if ($taskText.Length -lt 3) {
    Show-InfoMessage -Message "Task description must be at least 3 characters" ...
    return
}

$due = switch ($dueInput) {
    'today' { (Get-Date).ToString('yyyy-MM-dd') }
    'tomorrow' { (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
    default { $parsedDate = Get-ConsoleUIDateOrNull $dueInput; ... }
}
```

**Edit Form (Task/Project):**
1. **Change detection** - Only validate modified fields
2. **Duplicate checks** - Only if name changed
3. **Cascading updates** - Update references in other entities

**Example - Task Edit:**
```powershell
$changed = $false

if ($input['text'] -ne $currentText) {
    $task.text = $input['text'].Trim()
    $changed = $true
}

if ($newProject -ne $task.project) {
    $task.project = $newProject
    $changed = $true
}

if ($changed) {
    $task | Add-Member -MemberType NoteProperty -Name 'modified' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force
    Save-PmcData ...
}
```

**Example - Project Edit (Complex):**
```powershell
# Check for name change
$newName = ([string]$vals['Name']).Trim()
if ($newName -ne $projectName) {
    # Validate no duplicate
    # Apply rename across projects, tasks, and timelogs
    $data.projects = $newProjects
    foreach ($t in $data.tasks) { if ($t.project -eq $projectName) { $t.project = $newName } }
    foreach ($log in $data.timelogs) { if ($log.project -eq $projectName) { $log.project = $newName } }
    $changed = $true
}
```

---

## Data Persistence

### Save Mechanisms

**Pattern 1: Save-PmcData (for tracking changes)**
```powershell
Save-PmcData -Data $data -Action "Added task $newId"
```
Used for: Task operations (adds, edits)
Includes: Change tracking, undo history, atomic saves

**Pattern 2: Set-PmcAllData (direct save)**
```powershell
Set-PmcAllData $data
```
Used for: Project operations, batch updates
Direct, no change tracking

**Error Handling:**
- Modern task forms have explicit error handling with Show-InfoMessage
- Project forms have try-catch but often silent failures
- Task add form: Blocks user on save error
- Edit forms: Confirm no changes made if nothing modified

---

## Key Differences: Add vs. Edit

| Aspect | Add | Edit |
|--------|-----|------|
| **Prepopulation** | Empty fields, default values | Current entity values via `Value` parameter |
| **Validation** | Check required, format, uniqueness | Check format only, ignore duplicates if unchanged |
| **Change Detection** | N/A - all fields new | Track which fields changed |
| **Timestamps** | `created` set to now | `modified` set to now, `created` unchanged |
| **Cascading Updates** | None needed | May propagate changes (project rename affects tasks) |
| **Feedback** | "Added successfully" | "Updated successfully" or "No changes made" |
| **Navigation** | Return to list/parent | Maintain selection on modified entity |

**Example Structure:**

Add Form:
```
DrawXxxForm()
  └─ Display labels/instructions
     └─ User sees empty form

HandleXxxForm()
  ├─ Show form (Show-InputForm or manual loop)
  ├─ Validate required fields
  ├─ Create new object with generated ID
  ├─ Add to data
  └─ Save with "Added" action
```

Edit Form:
```
DrawXxxForm()
  └─ Display labels/instructions
     └─ User sees empty form (data shown in Handle phase)

HandleXxxForm()
  ├─ Get current object
  ├─ Prepopulate form with current values
  ├─ Show form
  ├─ Detect changes
  ├─ If changed:
  │   ├─ Update object
  │   ├─ Update modified timestamp
  │   ├─ Handle cascading updates
  │   └─ Save with "Edited" action
  └─ Return to previous view with selection maintained
```

---

## Opportunities for Abstraction & Refactoring

### Tier 1: Immediate Consolidation

**1. Migrate Legacy Forms to Show-InputForm**

Status: Partially done
- Modern: Task Add/Edit (using Show-InputForm)
- Legacy: Project Create/Edit (manual loops)

**Action Items:**
1. Extend Show-InputForm with new field types:
   ```powershell
   @{Name='folder'; Label='Project Folder'; Type='path'; DialogsOnly=$true}
   @{Name='date'; Label='Assigned Date'; Type='date'; Format='yyyy-MM-dd'}
   ```

2. Implement F2 picker in Show-InputForm:
   ```powershell
   elseif ($k.Key -eq 'F2' -and $f.Type -eq 'path') {
       $picked = Select-ConsoleUIPathAt -app $this -Hint "Pick $($f.Label)" ...
       if ($null -ne $picked) { $f.Value = $picked }
       continue
   }
   ```

3. Migrate Project Create/Edit to Show-InputForm:
   ```powershell
   # Before: 80 lines of field definitions + 120 lines of input loop
   # After: 20 lines of field definitions + 1 line of Show-InputForm call
   ```

**Refactored Project Create:**
```powershell
[void] HandleProjectCreateForm() {
    $input = Show-InputForm -Title "Create New Project" -Fields @(
        @{Name='Name'; Label='Project Name'; Required=$true; Type='text'}
        @{Name='Description'; Label='Description'; Required=$false; Type='text'}
        @{Name='ID1'; Label='ID1'; Required=$false; Type='text'}
        @{Name='ProjFolder'; Label='Project Folder'; Required=$false; Type='path'; DialogsOnly=$true}
        @{Name='AssignedDate'; Label='Assigned Date (yyyy-MM-dd)'; Required=$false; Type='date'}
        # ... other fields
    )
    
    if ($null -eq $input) { $this.GoBackOr('projectlist'); return }
    
    # Validation
    if ([string]::IsNullOrWhiteSpace($input.Name)) { 
        Show-InfoMessage -Message "Project name is required" ... 
        return 
    }
    
    # Create and save
    $newProject = [pscustomobject]@{ /* ... */ }
    Set-PmcAllData ...
}
```

### Tier 2: Field Abstraction

**Current State:** Each form independently handles field operations

**Goal:** Reusable field components

**Field Types to Create:**
```powershell
class FormField {
    [string]$Name
    [string]$Label
    [bool]$Required
    [string]$Type  # 'text', 'select', 'date', 'path'
    [object]$Value
    [object[]]$Options  # For select
    [string]$Format  # For date
    [string]$HelpText
    
    [bool] Validate() { ... }
    [object] GetValue() { ... }
    [void] SetValue([object]$val) { ... }
}
```

**Form Renderer:**
```powershell
class FormRenderer {
    [void] Render([FormField[]]$fields, [int]$activeIndex) { ... }
    [object] CaptureInput([FormField]$field, [ConsoleKeyInfo]$key) { ... }
    [PSCustomObject] CollectValues([FormField[]]$fields) { ... }
}
```

### Tier 3: Form Builder Pattern

**Goal:** Reduce boilerplate across all forms

```powershell
class FormBuilder {
    hidden [PSCustomObject]$config
    
    [FormBuilder] WithTitle([string]$title) { ... }
    [FormBuilder] WithField([FormField]$field) { ... }
    [FormBuilder] WithValidator([scriptblock]$validator) { ... }
    [FormBuilder] WithSaveAction([scriptblock]$action) { ... }
    
    [PSCustomObject] Build() { ... }
}

# Usage:
$taskForm = [FormBuilder]::new()
    .WithTitle("Add New Task")
    .WithField([FormField]@{ Name='text'; Label='Description'; Required=$true; Type='text' })
    .WithField([FormField]@{ Name='project'; Label='Project'; Type='select'; Options=$projects })
    .WithValidator({ param($values) 
        if ($values['text'].Length -lt 3) { throw "Too short" }
    })
    .WithSaveAction({ param($values)
        $data.tasks += [PSCustomObject]@{ /* ... */ }
        Save-PmcData -Data $data
    })
    .Build()

$result = $taskForm.Show()
```

### Tier 4: Unified Form State Management

**Current State:** Each form manages its own state and navigation

**Goal:** Centralized form state machine

```powershell
enum FormState {
    Rendering
    InputCapture
    Validation
    Processing
    Complete
    Cancelled
}

class FormManager {
    [string]$CurrentForm
    [FormState]$State
    [PSCustomObject]$FormData
    [PSCustomObject]$PreviousView
    
    [void] OpenForm([string]$formName, [hashtable]$context) { ... }
    [void] SubmitForm([PSCustomObject]$values) { ... }
    [void] CancelForm() { ... }
}
```

---

## Current Code Quality Issues

### Duplication
- **Manual input loops:** ~200 lines duplicated across project forms
- **Field rendering:** Similar patterns repeated 5+ times
- **Validation:** Date/text validation logic scattered

### Maintainability
- Changes to UI behavior require updating multiple forms
- Inconsistent behavior between legacy and modern forms
- Difficult to add new field types

### Testing
- Forms tightly coupled to UI and data persistence
- Hard to unit test form logic
- No mock terminal for integration tests

### Documentation
- Minimal inline comments
- Field dependencies not documented
- Special syntax (quick add, date parsing) undocumented in code

---

## Recommendations

### Priority 1 (High Value, Low Effort)
1. **Migrate Project Create/Edit to Show-InputForm**
   - Eliminates ~200 lines of duplicated input loop code
   - Standardizes UI/UX across all forms
   - Effort: 2-3 hours
   - Benefit: 30% code reduction, consistency

2. **Extend Show-InputForm with F2 picker support**
   - Add 'path' field type
   - Integrate Select-ConsoleUIPathAt
   - Effort: 1-2 hours
   - Benefit: Enables full project form migration

### Priority 2 (Medium Value, Medium Effort)
3. **Extract FormField abstraction**
   - Create reusable field component
   - Move validation logic into field
   - Effort: 4-6 hours
   - Benefit: Clearer separation of concerns

4. **Create form builder helper**
   - Reduce boilerplate in Handle methods
   - Standardize field/validation/save flow
   - Effort: 3-4 hours
   - Benefit: Easier to add new forms

### Priority 3 (Lower Effort for Maintenance)
5. **Document form patterns and field types**
   - Add comments explaining each form flow
   - Document special syntax (quick add, dates)
   - Create form extension guide
   - Effort: 2-3 hours
   - Benefit: Easier onboarding, maintenance

---

## Summary Table

| Aspect | Legacy (Project) | Modern (Task) |
|--------|------------------|---------------|
| **Lines per form** | 150-200 | 80-100 |
| **Input handling** | Manual loop | Show-InputForm |
| **Field types** | text, date, path | text, select |
| **Navigation** | Tab/Shift+Tab | Tab/Shift+Tab |
| **Validation** | Post-submission | During submission |
| **Code duplication** | High (200 LOC shared) | Low (reuses Show-InputForm) |
| **Extensibility** | Difficult | Moderate |
| **User experience** | Consistent but verbose | Clean but limited |
| **F2 picker** | Yes | No |
| **Prepopulation** | Post-loop | Via field Value param |
| **Change detection** | None (all written) | Explicit |

---

## File References

- **Main file:** `/home/teej/pmc/ConsoleUI.Core.ps1`
- **Show-InputForm function:** Lines 439-547
- **DrawTaskAddForm:** Line 2491
- **HandleTaskAddForm:** Line 2511
- **HandleTaskEditForm:** Line 5395
- **DrawProjectCreateForm:** Line 5218
- **HandleProjectCreateForm:** Line 5253
- **DrawEditProjectForm:** Line 6719
- **HandleEditProjectForm:** Line 6731

