# PMC ConsoleUI - Feature Requirements & Implementation Plan

**Date**: 2025-11-10
**Status**: Planning Phase

---

## Overview

This document outlines the complete feature set needed for PMC ConsoleUI, including new features and integration work.

---

## Feature 1: Command Library (Text Snippet Manager)

### Purpose
Store and manage text snippets for external program commands (regex patterns, shell commands, etc.).

### Requirements
- **NOT** for executing commands - just text storage and clipboard copy
- Multiline snippet support
- User-defined categories
- Tag-based organization and search
- Copy to clipboard on selection
- Usage tracking (count, last used date)

### Storage
**File**: `~/.config/pmc/commands.json`

```json
{
  "commands": [
    {
      "id": "guid",
      "name": "Email Regex",
      "category": "Regex Patterns",
      "tags": ["email", "validation", "regex"],
      "text": "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
      "description": "RFC 5322 email validation pattern",
      "created": "datetime",
      "modified": "datetime",
      "usage_count": 5,
      "last_used": "datetime"
    }
  ],
  "categories": ["Regex Patterns", "Git Commands", "SQL Snippets"]
}
```

### UI Implementation
**Screen**: `CommandLibraryScreen` (extends `StandardListScreen`)

**Already exists** at `screens/CommandLibraryScreen.ps1` but:
- Storage backend is stubbed (TODO comments)
- Not registered in menu system
- Needs actual implementation

**List View**:
```
┌─ Command Library ────────────────────────────────────┐
│ Name              │ Category      │ Uses │ Modified  │
├───────────────────┼───────────────┼──────┼───────────┤
│ Email Regex       │ Regex         │ 15   │ 2d ago    │
│ Git Reset Hard    │ Git Commands  │ 8    │ 1w ago    │
│ SQL Join Template │ SQL Snippets  │ 23   │ 3d ago    │
└──────────────────────────────────────────────────────┘
  Enter: Copy to Clipboard | E: Edit | A: Add | D: Delete | /: Search
```

**Actions**:
- `Enter`: Copy snippet text to clipboard, increment usage_count
- `E`: Edit snippet (using InlineEditor or TextAreaEditor for multiline)
- `A`: Add new snippet
- `D`: Delete snippet
- `/`: Search by name/category/tags
- `T`: Filter by tag

### Implementation Tasks
1. Create `CommandStore.ps1` service (similar to TaskStore)
2. Implement CRUD operations (Add, Edit, Delete, Load, Save)
3. Register screen in menu system (Tools → Command Library)
4. Wire up keyboard shortcuts
5. Add clipboard integration (`Set-Clipboard`)
6. Implement tag filtering
7. Add category management (add/edit/delete categories)

---

## Feature 2: Notes System (Integrated Multiline Text Editor)

### Purpose
Create, edit, and manage multiline text notes attached to projects, tasks, or standalone.

### Requirements
- **Plain text** (.txt files, NOT markdown)
- **Multiline editor** (notepad-like, not single-line input)
- Notes **owned by** projects/tasks (direct attachment)
- Access through parent screens (ProjectInfoScreen → Notes Menu → Editor)
- Multiple notes per project/task
- Standalone notes (global, not attached to anything)
- Tags for organization (optional)
- Quick switcher (Obsidian-style Ctrl+O)
- Daily note automation (Ctrl+D creates/opens today's note)

### Data Model

**Enhanced tasks.json**:
```json
{
  "projects": [
    {
      "id": "proj-guid",
      "name": "Project Alpha",
      "notes": [
        {
          "id": "note-guid-1",
          "title": "Requirements Discussion",
          "file": "projects/proj-guid/note-guid-1.txt",
          "created": "datetime",
          "modified": "datetime",
          "word_count": 250,
          "line_count": 45,
          "tags": ["requirements", "planning"]
        }
      ]
    }
  ],
  "tasks": [
    {
      "id": "task-guid",
      "text": "Implement authentication",
      "notes": [
        {
          "id": "note-guid",
          "title": "Implementation Notes",
          "file": "tasks/task-guid/note-guid.txt",
          "created": "datetime",
          "modified": "datetime"
        }
      ]
    }
  ],
  "standalone_notes": [
    {
      "id": "note-guid",
      "title": "Random Ideas",
      "file": "global/note-guid.txt",
      "created": "datetime",
      "modified": "datetime",
      "tags": ["ideas", "brainstorm"]
    }
  ]
}
```

**File Structure**:
```
~/.config/pmc/notes/
  projects/
    {project-id}/
      {note-id}.txt
  tasks/
    {task-id}/
      {note-id}.txt
  global/
    {note-id}.txt
```

### Core Component: TextAreaEditor Widget

**Class**: `TextAreaEditor` (extends `PmcWidget`)

**Features**:
- Line-based or character-based editing (TBD)
- Arrow key navigation
- Insert/delete characters and lines
- Word wrap or horizontal scroll
- Undo/redo buffer
- Copy/paste via clipboard
- Status bar (line count, word count, cursor position)
- Auto-save or Ctrl+S save
- File I/O (load/save .txt files)

**Properties**:
```powershell
[string[]]$Lines           # Text content as array of lines
[int]$CursorLine          # Current line (0-indexed)
[int]$CursorCol           # Current column (0-indexed)
[int]$ViewportTop         # First visible line (for scrolling)
[bool]$WordWrap           # Enable word wrapping
[bool]$Modified           # Track changes
[string]$FilePath         # Associated file path
```

**Methods**:
```powershell
[void] InsertChar([char]$c)
[void] InsertLine()
[void] DeleteChar()
[void] MoveCursor([int]$dx, [int]$dy)
[void] SaveToFile()
[void] LoadFromFile([string]$path)
[void] Copy()
[void] Paste()
[void] Undo()
```

### UI Screens

#### 1. ProjectInfoScreen (Enhanced)
**Current**: Shows project details only
**Enhancement**: Add notes and checklists sections

```
┌─ Project: Alpha ─────────────────────────────────────┐
│ ID1: 001                    Status: Active           │
│ ID2: PROJ-ALPHA             Due: 2025-12-31          │
│                                                       │
│ Description:                                         │
│ Large enterprise project...                          │
│                                                       │
├─ Notes (3) ──────────────────────────────────────────┤
│ • Requirements Discussion        [250 words, 2d ago] │
│ • Risk Analysis                  [120 words, 5d ago] │
│ • Meeting Notes 2025-11-10       [85 words, 1w ago]  │
│                                                       │
├─ Checklists (2) ─────────────────────────────────────┤
│ ☑ Project Setup                  [8/8 items - 100%]  │
│ ☐ Project Closure                [3/10 items - 30%]  │
│                                                       │
└──────────────────────────────────────────────────────┘
  E: Edit | N: Notes Menu | C: Checklists Menu | B: Back
```

#### 2. NotesMenuScreen
**Purpose**: List all notes for a project/task

```
┌─ Project: Alpha - Notes ─────────────────────────────┐
│                                                       │
│  1. Requirements Discussion        [250 words, 2d]   │
│  2. Risk Analysis                  [120 words, 5d]   │
│  3. Meeting Notes 2025-11-10       [85 words, 1w]    │
│                                                       │
└──────────────────────────────────────────────────────┘
  1-9: Open | A: Add Note | D: Delete | Esc: Back
```

#### 3. NoteEditorScreen
**Purpose**: Edit individual note with TextAreaEditor

```
┌─ Note: Requirements Discussion [Project: Alpha] ─────┐
│ The client requires OAuth2 authentication with       │
│ support for multiple identity providers.             │
│                                                       │
│ Key requirements:                                    │
│ - Google OAuth                                       │
│ - GitHub OAuth                                       │
│ - Azure AD                                           │
│                                                       │
│ Security considerations:                             │
│ - Token rotation every 24h█                         │
│                                                       │
│ [Ln 10, Col 26] [250 words] [Modified]              │
└──────────────────────────────────────────────────────┘
  Ctrl+S: Save | Esc: Back
```

#### 4. Global Notes Screen
**Purpose**: View all notes across all projects/tasks

```
┌─ All Notes ──────────────────────────────────────────┐
│ Projects (15 notes)                                  │
│  Project Alpha                                       │
│    • Requirements Discussion                         │
│    • Risk Analysis                                   │
│  Project Beta                                        │
│    • Meeting Notes                                   │
│                                                       │
│ Tasks (8 notes)                                      │
│  Task: Implement auth                                │
│    • Implementation Notes                            │
│                                                       │
│ Standalone (3 notes)                                 │
│  • Random Ideas                                      │
│  • Daily Note 2025-11-10                            │
└──────────────────────────────────────────────────────┘
  Enter: Open | /: Search | T: Filter by Tag | N: New Standalone
```

#### 5. Quick Switcher (Ctrl+O)
**Purpose**: Fuzzy search across all notes, tasks, projects

```
┌─ Quick Switcher ─────────────────────────────────────┐
│ Search: auth_                                        │
├──────────────────────────────────────────────────────┤
│ > Task: Implement authentication                     │
│   Note: Requirements Discussion (Project: Alpha)     │
│   Note: Implementation Notes (Task: auth...)         │
│   Project: Authentication Service                    │
└──────────────────────────────────────────────────────┘
  ↑↓: Navigate | Enter: Open | Esc: Cancel
```

### Implementation Tasks
1. Create `TextAreaEditor.ps1` widget (multiline text editor component)
2. Create `NoteService.ps1` service (CRUD operations)
3. Enhance `ProjectInfoScreen.ps1` (add notes/checklists sections)
4. Create `NotesMenuScreen.ps1` (list notes for parent)
5. Create `NoteEditorScreen.ps1` (edit individual note)
6. Create `TaskInfoScreen.ps1` (task detail view with notes)
7. Create global notes menu screen
8. Implement Quick Switcher (Ctrl+O)
9. Add Daily Note automation (Ctrl+D)
10. Add note templates (optional)

---

## Feature 3: Checklist System (Templates & Instances)

### Purpose
Create reusable checklist templates and attach instances to projects/tasks.

### Requirements
- Reusable templates (global)
- Create instances from templates (copy with progress tracking)
- Attach to projects, tasks, or standalone
- Track completion per instance
- Inline editing of checklist items
- Progress indicators

### Data Model

**Enhanced tasks.json**:
```json
{
  "projects": [
    {
      "id": "proj-guid",
      "checklists": [
        {
          "id": "checklist-guid",
          "title": "Project Closure Checklist",
          "template_id": "template-guid",
          "created": "datetime",
          "modified": "datetime",
          "items": [
            {
              "text": "Complete all tasks",
              "completed": true,
              "completed_date": "datetime",
              "order": 1
            },
            {
              "text": "Generate reports",
              "completed": false,
              "order": 2
            }
          ],
          "completed_count": 3,
          "total_count": 10,
          "percent_complete": 30
        }
      ]
    }
  ],
  "checklist_templates": [
    {
      "id": "template-guid",
      "name": "Code Review Checklist",
      "description": "Standard code review process",
      "category": "Development",
      "items": [
        {"text": "Check security vulnerabilities", "order": 1},
        {"text": "Verify test coverage", "order": 2},
        {"text": "Review error handling", "order": 3}
      ],
      "created": "datetime",
      "modified": "datetime"
    }
  ]
}
```

### Storage Options

**Option A**: Store checklist items in tasks.json (as shown above)
**Option B**: Store in separate files like notes

```
~/.config/pmc/checklists/
  projects/{project-id}/{checklist-id}.json
  tasks/{task-id}/{checklist-id}.json
```

**Recommendation**: Option A (embedded in tasks.json) for simplicity

### UI Screens

#### 1. ChecklistsMenuScreen
**Purpose**: List checklists for a project/task

```
┌─ Project: Alpha - Checklists ────────────────────────┐
│                                                       │
│  1. ☑ Project Setup              [8/8 - 100%]        │
│  2. ☐ Project Closure            [3/10 - 30%]        │
│                                                       │
└──────────────────────────────────────────────────────┘
  1-9: Open | A: Add from Template | N: New Blank | D: Delete | Esc: Back
```

#### 2. ChecklistEditorScreen
**Purpose**: Edit checklist items and toggle completion

```
┌─ Checklist: Project Closure [Project: Alpha] ────────┐
│                                                       │
│ [x] 1. Complete all outstanding tasks                │
│ [x] 2. Generate final reports                        │
│ [x] 3. Archive project files                         │
│ [ ] 4. Client sign-off                               │
│ [ ] 5. Close financial records█                      │
│ [ ] 6. Update portfolio                              │
│ [ ] 7. Conduct retrospective                         │
│ [ ] 8. Document lessons learned                      │
│ [ ] 9. Release team members                          │
│ [ ] 10. Celebrate success!                           │
│                                                       │
│ [Progress: 30% - 3/10 complete]                      │
└──────────────────────────────────────────────────────┘
  Space: Toggle | E: Edit Item | A: Add Item | D: Delete | Esc: Back
```

#### 3. ChecklistTemplateManagerScreen
**Purpose**: Manage global checklist templates

```
┌─ Checklist Templates ────────────────────────────────┐
│ Name                     │ Items │ Used              │
├──────────────────────────┼───────┼───────────────────┤
│ Code Review              │ 12    │ 15 projects       │
│ Project Closure          │ 10    │ 8 projects        │
│ Bug Investigation        │ 6     │ 23 tasks          │
│ Testing Checklist        │ 8     │ 45 tasks          │
└──────────────────────────────────────────────────────┘
  N: New | E: Edit | D: Delete | Enter: View Instances
```

#### 4. ChecklistTemplateEditorScreen
**Purpose**: Edit template items

```
┌─ Template: Code Review Checklist ────────────────────┐
│ Category: [Development_]                             │
│ Description: [Standard code review process_______]   │
│                                                       │
│ Items:                                               │
│  1. Check for security vulnerabilities               │
│  2. Verify test coverage                             │
│  3. Review error handling                            │
│  4. Check documentation█                             │
│                                                       │
│                                                       │
│ [4 items]                                            │
└──────────────────────────────────────────────────────┘
  E: Edit Item | A: Add Item | D: Delete | ↑↓: Reorder | Ctrl+S: Save
```

### Implementation Tasks
1. Create `ChecklistService.ps1` service
2. Create `ChecklistsMenuScreen.ps1` (list for parent)
3. Create `ChecklistEditorScreen.ps1` (edit instance)
4. Create `ChecklistTemplateManagerScreen.ps1` (manage templates)
5. Create `ChecklistTemplateEditorScreen.ps1` (edit template)
6. Add template instantiation logic (copy template → instance)
7. Add progress calculation
8. Integrate with ProjectInfoScreen
9. Integrate with TaskInfoScreen (when created)

---

## Feature 4: Excel Integration (COM Automation)

### Purpose
Import project data from Excel files automatically using COM automation.

### Requirements
- **NO manual copy/paste** workflow
- Use PowerShell COM interop (`New-Object -ComObject Excel.Application`)
- Read from running Excel instance OR open file programmatically
- Profile-based field mapping (configurable)
- Map Excel cells to Project properties
- Display entirely in ConsoleUI (NO WPF)

### Architecture (from SuperTUI)

**Key Components**:
1. **ExcelComReader**: COM interop to read cells
2. **ExcelMappingService**: Manage profiles and mappings
3. **ExcelMappingProfile**: Configuration for field mappings
4. **Screens**: Profile manager, mapping editor, import wizard

### PowerShell COM Approach

```powershell
# Option 1: Attach to running Excel
$excel = [System.Runtime.InteropServices.Marshal]::GetActiveObject("Excel.Application")

# Option 2: Open file programmatically
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Open("C:\path\to\file.xlsx")
$worksheet = $workbook.Worksheets.Item(1)

# Read single cell
$value = $worksheet.Range("W3").Value2

# Read range
$range = $worksheet.Range("W3:W130")
$cellData = @{}
foreach ($cell in $range) {
    $cellRef = $cell.Address($false, $false)  # e.g., "W3"
    $cellData[$cellRef] = $cell.Value2
}

# Cleanup
$workbook.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
```

### Data Model

**Storage**: `~/.config/pmc/excel_profiles.json`

```json
{
  "profiles": [
    {
      "id": "guid",
      "name": "SVI-CAS Standard",
      "description": "48-field government audit form",
      "start_cell": "W3",
      "mappings": [
        {
          "id": "guid",
          "display_name": "Project Name",
          "excel_cell": "W3",
          "project_property": "name",
          "required": true,
          "data_type": "string",
          "include_in_export": true,
          "sort_order": 1
        },
        {
          "id": "guid",
          "display_name": "Due Date",
          "excel_cell": "W16",
          "project_property": "DueDate",
          "required": false,
          "data_type": "date",
          "include_in_export": true,
          "sort_order": 2
        }
      ],
      "created": "datetime",
      "modified": "datetime"
    }
  ],
  "active_profile_id": "guid"
}
```

### UI Screens

#### 1. ExcelImportScreen (StandardFormScreen)
**Purpose**: Import project from Excel

```
┌─ Excel Import ───────────────────────────────────────┐
│                                                       │
│ Source:                                              │
│   ( ) Running Excel (active selection)               │
│   (•) File Path                                      │
│                                                       │
│ File: [/home/teej/projects/data.xlsx________] Browse │
│                                                       │
│ Profile: [SVI-CAS Standard ▼]                        │
│                                                       │
│ Start Cell: [W3___]                                  │
│                                                       │
│                                                       │
│                                                       │
└──────────────────────────────────────────────────────┘
  Enter: Import | M: Manage Profiles | Esc: Cancel
```

**Actions**:
- Select source (running Excel or file)
- If file: use PmcFilePicker to browse
- Select profile from dropdown
- Specify start cell
- Press Enter: Read data, map fields, create/update project

#### 2. ExcelProfileManagerScreen (StandardListScreen)
**Purpose**: Manage Excel mapping profiles

```
┌─ Excel Profiles ─────────────────────────────────────┐
│ Name                 │ Mappings │ Modified           │
├──────────────────────┼──────────┼────────────────────┤
│ SVI-CAS Standard     │ 48       │ 2025-11-01         │
│ T2020 Minimal        │ 8        │ 2025-10-15         │
│ Quick Import         │ 12       │ 2025-09-20         │
└──────────────────────────────────────────────────────┘
  N: New | E: Edit Mappings | D: Delete | C: Clone | Enter: Set Active
```

#### 3. ExcelMappingEditorScreen (custom)
**Purpose**: Edit field mappings for a profile

```
┌─ Profile: SVI-CAS Standard - Mappings ───────────────┐
│ Display Name      │ Cell │ Property    │ Export      │
├───────────────────┼──────┼─────────────┼─────────────┤
│ Project Name      │ W3   │ name        │ [x]         │
│ Client ID         │ W18  │ ClientID    │ [x]         │
│ Due Date          │ W16  │ DueDate     │ [x]         │
│ Audit Type        │ W23  │ AuditType   │ [x]         │
│ Comments          │ W100 │ Comments    │ [ ]         │
└──────────────────────────────────────────────────────┘
  A: Add Mapping | E: Edit | D: Delete | Space: Toggle Export | Ctrl+S: Save
```

**Edit mapping dialog**:
```
┌─ Edit Mapping ───────────────────────────────────────┐
│ Display Name: [Project Name___________________]      │
│ Excel Cell:   [W3_____]                              │
│ Property:     [name________________________]         │
│ Data Type:    [String ▼]                             │
│ Required:     [x]                                    │
│ Export:       [x]                                    │
│ Default:      [_______________________________]      │
└──────────────────────────────────────────────────────┘
  Enter: Save | Esc: Cancel
```

### Implementation Tasks
1. Create `ExcelComReader.ps1` (PowerShell COM wrapper)
2. Create `ExcelMappingService.ps1` (profile management)
3. Create `ExcelImportScreen.ps1` (import wizard)
4. Create `ExcelProfileManagerScreen.ps1` (manage profiles)
5. Create `ExcelMappingEditorScreen.ps1` (edit mappings)
6. Add property discovery (use `Get-Member` on Project objects)
7. Add data type conversion (string → date, int, etc.)
8. Test with real Excel files
9. Add error handling (file not found, COM errors, etc.)
10. Register in menu system (Tools → Excel Import)

---

## Implementation Priority

### Phase 1: Foundation Components
1. **TextAreaEditor widget** (required for notes/checklists)
2. **NoteService** (required for notes feature)
3. **ChecklistService** (required for checklists feature)
4. **CommandStore** (required for command library)

### Phase 2: Command Library (Quick Win)
1. Implement CommandStore CRUD operations
2. Register CommandLibraryScreen in menu
3. Test add/edit/delete/copy operations

### Phase 3: Notes System (High Priority)
1. Implement TextAreaEditor widget
2. Enhance ProjectInfoScreen (add notes section)
3. Create NotesMenuScreen
4. Create NoteEditorScreen
5. Add TaskInfoScreen with notes
6. Global notes menu
7. Quick switcher (Ctrl+O)

### Phase 4: Checklists (Medium Priority)
1. Implement ChecklistService
2. Create ChecklistsMenuScreen
3. Create ChecklistEditorScreen
4. Create template manager screens
5. Integrate with ProjectInfoScreen
6. Integrate with TaskInfoScreen

### Phase 5: Excel Integration (Medium Priority)
1. Create ExcelComReader (COM wrapper)
2. Create ExcelMappingService
3. Create import/profile screens
4. Test with real data
5. Create default profiles

### Phase 6: Polish & Integration
1. Quick switcher refinements
2. Daily notes automation
3. Note/checklist templates
4. Search improvements
5. Performance optimization

---

## Next Steps

1. ✅ Document requirements (this file)
2. 🔄 Search for existing notes screen implementations in ~/
3. ⏳ Analyze found implementations
4. ⏳ Choose best approach for TextAreaEditor
5. ⏳ Begin Phase 1 implementation

---

**End of Requirements Document**
