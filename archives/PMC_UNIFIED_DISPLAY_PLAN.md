# PMC Universal Display System - Comprehensive Unification Plan

## EXECUTIVE SUMMARY
Transform PMC's fragmented display functions into a single, unified system that becomes the ONLY display mechanism. This plan systematically replaces ALL 22 existing Show-Pmc* functions with a professional grid-based interface featuring arrow navigation, real-time editing, and comprehensive theming integration.

## CURRENT STATE ANALYSIS

### Fragmented Display Functions (22 functions to replace):
**Core Display Functions:**
- `Show-PmcTodayTasks` → Universal grid
- `Show-PmcOverdueTasks` → Universal grid
- `Show-PmcAgenda` → Universal grid
- `Show-PmcProjects` → Universal grid
- `Show-PmcTimeLog` → Universal grid
- `Show-PmcProjectStats` → Universal grid

**Specialized Display Functions:**
- `Show-PmcHeader`, `Show-PmcTip`, `Show-PmcNotice` → Unified messaging
- `Show-PmcTable` → Enhanced grid renderer
- `Show-PmcSeparator` → Grid section dividers

**Theme/UI Functions:**
- `Write-PmcStyled` → Enhanced with grid integration
- `Get-PmcStyle`, `Get-PmcColorPalette` → Extended theming system

### Core Strengths to Build Upon:
✅ **PmcGridRenderer class** - Already implemented with auto-sizing
✅ **Theme integration** - Style tokens working with hex colors
✅ **VT100 positioning** - Professional terminal control via PmcVT class
✅ **Data integration** - Project resolution, safe property access

### Critical Gaps to Address:
❌ **Arrow navigation** - No keyboard interface for data views
❌ **Inline editing** - No cell-level editing capabilities
❌ **Unified command routing** - Shortcuts ("projects") don't work consistently
❌ **Real-time updates** - Static display, no live data refresh
❌ **Performance optimization** - No differential rendering like Praxis

## PHASE 1: CORE INFRASTRUCTURE (Week 1)

### 1.1: Enhanced PmcGridRenderer Architecture
**File**: `module/Pmc.Strict/src/DataDisplay.ps1`

**New Capabilities:**
```powershell
class PmcGridRenderer {
    # NEW: Navigation state management
    [int] $SelectedRow = 0
    [int] $SelectedColumn = 0
    [string] $NavigationMode = "Row"  # Row, Cell, MultiSelect

    # NEW: Interactive features
    [hashtable] $CellEditCallbacks = @{}
    [hashtable] $KeyBindings = @{}
    [bool] $LiveEditing = $false

    # NEW: Performance optimization
    [hashtable] $RenderCache = @{}
    [bool] $DifferentialMode = $true

    # Enhanced methods
    [void] StartInteractiveMode([hashtable]$Config)
    [void] HandleKeyPress([ConsoleKeyInfo]$Key)
    [void] EnableInlineEditing([string]$Column, [scriptblock]$Validator)
    [void] RefreshData([hashtable]$NewData)
}
```

**Arrow Navigation System:**
- **Row Selection**: Up/Down arrows with visual highlighting
- **Cell Navigation**: Left/Right arrows for column traversal
- **Multi-Select**: Shift+arrows for range selection
- **Page Navigation**: Page Up/Down for large datasets
- **Smart Column Jumping**: Ctrl+Left/Right for column-to-column navigation

### 1.2: Universal Command Integration
**File**: `module/Pmc.Strict/src/Commands.ps1`

**Replace ALL Show-Pmc* functions:**
```powershell
# OLD: 22 separate display functions
Show-PmcTodayTasks, Show-PmcOverdueTasks, Show-PmcProjects...

# NEW: Single universal dispatcher
function Show-PmcData {
    param(
        [string]$DataType,      # "tasks", "projects", "timelog", "stats"
        [hashtable]$Filters = @{},
        [hashtable]$Columns = @{},
        [string]$Title = "",
        [switch]$Interactive
    )

    $grid = [PmcGridRenderer]::new()
    $data = Get-PmcData -Type $DataType -Filters $Filters
    $grid.Render($data, $Columns, $Title)

    if ($Interactive) {
        $grid.StartInteractiveMode(@{
            AllowEditing = $true
            SaveCallback = { param($changes) Save-PmcChanges $changes }
        })
    }
}

# Command shortcuts route to universal system:
function Show-PmcTodayTasks { Show-PmcData -DataType "tasks" -Filters @{due="today"} -Interactive }
function Show-PmcProjects { Show-PmcData -DataType "projects" -Interactive }
```

### 1.3: Enhanced Theme Integration
**File**: `module/Pmc.Strict/src/UI.ps1`

**Cell-Level Theming:**
```powershell
function Get-PmcCellStyle {
    param([object]$RowData, [string]$Column, [object]$Value)

    # Priority-based coloring for tasks
    if ($Column -eq "priority" -and $RowData.priority) {
        switch ($RowData.priority) {
            "1" { return @{ Fg = "Red"; Bold = $true } }
            "2" { return @{ Fg = "Yellow" } }
            "3" { return @{ Fg = "Green" } }
        }
    }

    # Due date warnings
    if ($Column -eq "due" -and $RowData.due) {
        $dueDate = [DateTime]$RowData.due
        if ($dueDate -lt (Get-Date)) {
            return @{ Fg = "Red"; Bold = $true }  # Overdue
        } elseif ($dueDate -le (Get-Date).AddDays(1)) {
            return @{ Fg = "Yellow"; Bold = $true }  # Due soon
        }
    }

    # Project-specific colors
    if ($Column -eq "project" -and $RowData.project) {
        $projectColor = Get-PmcProjectColor $RowData.project
        return @{ Fg = $projectColor }
    }

    return Get-PmcStyle "Body"  # Default styling
}
```

## PHASE 2: INTERACTIVE FEATURES (Week 2)

### 2.1: Professional Keyboard Interface
**File**: `module/Pmc.Strict/src/Navigation.ps1`

**Key Binding System:**
```powershell
$DefaultKeyBindings = @{
    # Navigation
    "UpArrow"    = { $this.MoveUp() }
    "DownArrow"  = { $this.MoveDown() }
    "LeftArrow"  = { $this.MoveLeft() }
    "RightArrow" = { $this.MoveRight() }
    "PageUp"     = { $this.PageUp() }
    "PageDown"   = { $this.PageDown() }
    "Home"       = { $this.MoveToStart() }
    "End"        = { $this.MoveToEnd() }

    # Selection
    "Shift+UpArrow"   = { $this.ExtendSelectionUp() }
    "Shift+DownArrow" = { $this.ExtendSelectionDown() }
    "Ctrl+A"          = { $this.SelectAll() }

    # Editing
    "Enter"      = { $this.StartCellEdit() }
    "F2"         = { $this.StartCellEdit() }
    "Escape"     = { $this.CancelEdit() }
    "Delete"     = { $this.DeleteSelected() }

    # Actions
    "Ctrl+S"     = { $this.SaveChanges() }
    "Ctrl+Z"     = { $this.Undo() }
    "Ctrl+R"     = { $this.RefreshData() }
    "F5"         = { $this.RefreshData() }
}
```

### 2.2: Inline Editing System
**Implementation Pattern:**
1. **Enter Edit Mode**: Press Enter on selected cell
2. **Visual Feedback**: Cell border changes, cursor appears
3. **Validation**: Real-time validation with color feedback
4. **Auto-Save**: Changes saved on Enter/Tab, cancelled on Escape
5. **Conflict Resolution**: Handle concurrent edits gracefully

### 2.3: Search and Filter Integration
**Live Search Features:**
- **Type-to-Filter**: Start typing to filter rows
- **Column Headers**: Click headers for sort/filter options
- **Saved Views**: Store common filter combinations
- **Regex Support**: Advanced pattern matching

## PHASE 3: PERFORMANCE & POLISH (Week 3)

### 3.1: Praxis-Inspired Rendering Architecture
**Adopt from**: `/home/teej/_tui/praxis-main/standalone/test/Core/RegionManager.ps1`

**Differential Rendering System:**
```powershell
class PmcDisplayRegion {
    [hashtable] $LastRenderState = @{}
    [string] $CachedOutput = ""
    [bool] $IsDirty = $true

    [void] UpdateRegion([hashtable]$NewData) {
        if ($this.HasChanged($NewData)) {
            $this.CachedOutput = $this.RenderContent($NewData)
            $this.LastRenderState = $NewData.Clone()
            $this.IsDirty = $true
        }
    }

    [bool] HasChanged([hashtable]$NewData) {
        # Smart comparison logic - only rerender if data actually changed
        return -not ($this.LastRenderState | Compare-Object $NewData -Quiet)
    }
}
```

### 3.2: Screen Layout System
**Inspired by**: `/home/teej/_tui/praxis-main/standalone/test/Core/VT100.ps1`

**Multi-Region Layout:**
```
┌─ HEADER REGION (rows 0-2) ──────────────────────┐
│ === PMC PROJECT MANAGEMENT ===                  │
│ Arrow keys: Navigate | Enter: Edit | F5: Refresh│
├─ DATA GRID REGION (rows 3-28) ─────────────────┤
│ # │ Task                    │ Project │ Due     │
│ ──┼─────────────────────────┼─────────┼────────│
│ 1 │► Fix authentication bug │ webapp  │ 09/18  │ ← Selected row
│ 2 │  Update documentation   │ docs    │ 09/20  │
│ 3 │  Code review session    │ webapp  │ 09/19  │
├─ STATUS REGION (rows 29-30) ───────────────────┤
│ Editing: Task Description | Ctrl+S: Save | Esc: Cancel
├─ INPUT REGION (rows 31-32) ────────────────────┤
│ PMC> _                                          │
└─────────────────────────────────────────────────┘
```

### 3.3: Real-Time Data Integration
**Background Updates:**
- **Live Refresh**: Data changes reflected immediately
- **Conflict Detection**: Warn if data changed externally
- **Auto-Save**: Periodic background saves
- **Performance Monitoring**: Track render times, optimize bottlenecks

Implementation status:
- Differential rendering implemented: only changed lines update using VT100.
- Virtual scrolling implemented: grid shows a window of rows with up/down indicators.
- Resize-aware rendering: terminal size changes trigger re-measure and redraw.
- Optional timed refresh: `-RefreshIntervalMs` in interactive mode enables periodic RefreshData without blocking input.

## IMPLEMENTATION ROADMAP

### Week 1: Foundation
**Day 1-2**: Enhanced PmcGridRenderer with navigation
**Day 3-4**: Universal command routing system
**Day 5-7**: Theme integration and testing

### Week 2: Interaction
**Day 1-3**: Keyboard interface and key bindings
**Day 4-5**: Inline editing system
**Day 6-7**: Search and filter features

### Week 3: Performance
**Day 1-3**: Differential rendering system
**Day 4-5**: Multi-region layout implementation
**Day 6-7**: Real-time updates and polish

## SUCCESS CRITERIA

### Functional Requirements
✅ **Single Display System**: All 22 Show-Pmc* functions replaced
✅ **Arrow Navigation**: Professional keyboard interface working
✅ **Inline Editing**: Cell-level editing with validation
✅ **Theme Integration**: Hex colors and style tokens applied universally
✅ **Command Shortcuts**: All shortcuts ("projects", "tasks") work consistently

### Performance Requirements
✅ **Sub-100ms Rendering**: For datasets under 1000 items
✅ **Flicker-Free Updates**: Only changed regions redraw
✅ **Memory Efficiency**: Cached rendering under 50MB
✅ **Responsive Layout**: Adapts to terminal resize

### User Experience Requirements
✅ **Professional UX**: Comparable to commercial CLI tools
✅ **Intuitive Navigation**: Standard keyboard shortcuts work
✅ **Visual Feedback**: Clear selection, editing, status indicators
✅ **Error Handling**: Graceful degradation, helpful error messages

## RISK MITIGATION

### Technical Risks
- **PowerShell Constraints**: Use tested patterns from Praxis architecture
- **Performance Issues**: Implement caching and differential rendering early
- **Theme Conflicts**: Maintain backward compatibility with existing style tokens

### User Experience Risks
- **Learning Curve**: Provide clear visual cues and help system
- **Data Loss**: Implement robust auto-save and undo systems
- **Accessibility**: Ensure color themes work with various terminal configurations

## CONCLUSION

This plan transforms PMC from a collection of display functions into a unified, professional data management interface. By building on the existing PmcGridRenderer foundation and integrating proven patterns from Praxis, we create a system that:

1. **Eliminates Fragmentation**: Single display system for all data
2. **Enhances Productivity**: Professional keyboard interface
3. **Improves Performance**: Differential rendering and caching
4. **Maintains Compatibility**: Existing commands work better than before

The result will be a PMC system that rivals commercial CLI tools while maintaining its PowerShell-based simplicity and modularity.

## ADDENDUM: Implementation Notes and Out‑of‑Scope Items

- Command shortcuts are auto‑registered at module load via `Register-PmcUniversalCommands`. If a host overrides `$Script:PmcShortcutMap` after import, it will supersede these.
- Cell‑level theming hook `Get-PmcCellStyle` is provided (priority and due rules). Project‑specific color mapping is not included; if needed, add a `Get-PmcProjectColor` helper.
- Inline editing is implemented as a bottom‑line prompt for common columns (`text`, `priority`, `due`, `project`) with validation. Changes persist through `Save-PmcData`. A simple optimistic conflict check is performed; multi‑row edits are not implemented.
- Type‑to‑filter is supported in interactive mode (filters on text/project/due fields). Header click sorting and saved views are not implemented.
- Sorting is keyboard‑driven: press `F3` to cycle Asc/Desc/None on the current column in Cell mode; indicator shown in header/status line.
- Saved views are supported in‑session via F6 (save), F7 (load), F8 (list). Persistent saved views can be added later if needed.
- Saved views now persist to config under `Display.GridViews` and load on startup.
- Differential rendering fields exist on the renderer, but the actual diff/region system is deferred to Phase 3 as planned.
  - Implemented initial differential rendering for interactive mode: only changed lines are redrawn using VT100 positioning.
- Real‑time updates and background refresh timers are not implemented; manual refresh is available via `F5`/`Ctrl+R`.
  - Added optional `-RefreshIntervalMs` for interactive grids to enable periodic refresh without blocking input.
