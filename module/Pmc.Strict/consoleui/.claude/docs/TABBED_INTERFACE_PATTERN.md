# Tabbed Interface Pattern

## Overview

The Tabbed Interface Pattern provides a clean way to organize many fields (20+) into logical groups using tabs. This pattern is ideal for detail/info/settings screens that would otherwise require scrolling or complex grid layouts.

## When to Use

**Use Tabbed Interface when:**
- Screen has 15+ fields to display/edit
- Fields naturally group into 3-6 logical categories
- Users need to see field labels and values together
- Editing should be inline or in popup
- Navigation should be keyboard-driven

**Examples:**
- ProjectInfoScreen (57 fields → 6 tabs)
- SettingsScreen (30+ settings → 4 tabs)
- UserProfileScreen (25 fields → 5 tabs)

**Don't use when:**
- Only 5-10 fields (use simple vertical list)
- Fields need to be compared across groups (use two-column layout)
- Data is list of items (use StandardListScreen)

## Architecture

```
PmcScreen (base)
  ↓
TabbedScreen (base class)
  ├── TabPanel widget - Tab navigation and field display
  ├── InlineEditor widget - Field editing (popup mode)
  └── Event handlers

YourScreen : TabbedScreen
  ├── LoadData() - Load data from store
  ├── SaveChanges() - Persist changes
  └── Optional event handlers
```

## Components

### 1. TabPanel Widget

**Location:** `widgets/TabPanel.ps1`

**Responsibilities:**
- Render tab bar with labels
- Render fields for current tab
- Handle tab navigation (Tab/Shift+Tab, 1-9 keys)
- Handle field navigation (Up/Down arrows)
- Highlight selected field
- Auto-scroll if too many fields

**Key Methods:**
```powershell
$panel = [TabPanel]::new()
$panel.AddTab('General', $fields)
$panel.NextTab()
$panel.PrevTab()
$panel.SelectTab(2)
$panel.NextField()
$panel.PrevField()
$field = $panel.GetCurrentField()
$values = $panel.GetAllValues()
```

**Events:**
- `OnTabChanged` - Tab selection changed
- `OnFieldSelected` - Field selection changed
- `OnFieldEdit` - Field value edited

### 2. TabbedScreen Base Class

**Location:** `base/TabbedScreen.ps1`

**Responsibilities:**
- Manage TabPanel lifecycle
- Integrate InlineEditor for field editing
- Route keyboard input
- Provide template methods for subclasses

**Abstract Methods (must override):**
```powershell
[void] LoadData() {
    # Load data from store and build tabs
}

[void] SaveChanges() {
    # Get values from TabPanel and save
}
```

**Optional Overrides:**
```powershell
[void] OnTabChanged([int]$tabIndex) {
    # Custom logic when tab changes
}

[void] OnFieldSelected($field) {
    # Custom logic when field selected
}

[void] OnFieldEdited($field, $newValue) {
    # Custom logic after field edited
}
```

## Implementation Guide

### Step 1: Create Screen Class

```powershell
class MyScreen : TabbedScreen {
    [string]$EntityName = ""
    [hashtable]$Data = @{}
    [object]$Store = $null

    MyScreen([string]$name) : base("MyScreen", "My Title") {
        $this.EntityName = $name
        $this.Store = [TaskStore]::GetInstance()
    }
}
```

### Step 2: Implement LoadData()

```powershell
[void] LoadData() {
    # Load data from store
    $entity = $this.Store.GetEntity($this.EntityName)
    if ($null -eq $entity) {
        $this.StatusBar.SetRightText("Entity not found")
        return
    }

    $this.Data = $entity

    # Build tabs
    $this._BuildTabs()
}
```

### Step 3: Build Tabs

```powershell
hidden [void] _BuildTabs() {
    # Clear existing tabs
    $this.TabPanel.Tabs.Clear()

    # Tab 1: General
    $this.TabPanel.AddTab('General', @(
        @{Name='name'; Label='Name'; Value=$this.Data.name; Type='text'; Required=$true}
        @{Name='email'; Label='Email'; Value=$this.Data.email; Type='text'}
        @{Name='phone'; Label='Phone'; Value=$this.Data.phone; Type='text'}
    ))

    # Tab 2: Details
    $this.TabPanel.AddTab('Details', @(
        @{Name='address'; Label='Address'; Value=$this.Data.address; Type='text'}
        @{Name='city'; Label='City'; Value=$this.Data.city; Type='text'}
        @{Name='zip'; Label='ZIP Code'; Value=$this.Data.zip; Type='text'}
    ))

    # Tab 3: Settings
    $this.TabPanel.AddTab('Settings', @(
        @{Name='active'; Label='Active'; Value=$this.Data.active; Type='boolean'}
        @{Name='theme'; Label='Theme'; Value=$this.Data.theme; Type='choice'; Choices=@('light','dark')}
    ))
}
```

### Step 4: Implement SaveChanges()

```powershell
[void] SaveChanges() {
    # Get all field values
    $values = $this.TabPanel.GetAllValues()

    # Validate (optional)
    if (-not $values['name']) {
        $this.StatusBar.SetRightText("Name is required")
        return
    }

    # Save to store
    $success = $this.Store.UpdateEntity($this.EntityName, $values)

    if ($success) {
        $this.StatusBar.SetRightText("Saved successfully")
        # Reload to reflect changes
        $this.LoadData()
    } else {
        $this.StatusBar.SetRightText("Save failed: $($this.Store.LastError)")
    }
}
```

### Step 5: Optional Event Handlers

```powershell
[void] OnTabChanged([int]$tabIndex) {
    # Call base
    ([TabbedScreen]$this).OnTabChanged($tabIndex)

    # Custom logic
    $tab = $this.TabPanel.GetCurrentTab()
    Write-PmcTuiLog "Switched to tab: $($tab.Name)" "DEBUG"
}

[void] OnFieldEdited($field, $newValue) {
    # Auto-save on each edit (optional)
    $this.SaveChanges()

    # Or validate specific fields
    if ($field.Name -eq 'email') {
        if ($newValue -notmatch '^[\w.+-]+@[\w.-]+\.\w+$') {
            $this.StatusBar.SetRightText("Invalid email format")
        }
    }
}
```

## Field Definition

Each field is a hashtable with these properties:

```powershell
@{
    Name = 'fieldName'          # Unique field identifier (required)
    Label = 'Display Label'     # Human-readable label (required)
    Value = $currentValue       # Current field value (required)
    Type = 'text'               # Field type: text|number|date|boolean|choice (optional, default: text)
    Required = $true            # Is field required? (optional, default: false)

    # Type-specific properties:
    # For 'number':
    Min = 0                     # Minimum value
    Max = 100                   # Maximum value

    # For 'choice':
    Choices = @('opt1','opt2')  # Available choices

    # For 'date':
    # (uses standard date parsing)
}
```

## Navigation Shortcuts

**Tab Navigation:**
- `Tab` - Next tab
- `Shift+Tab` - Previous tab
- `1-9` - Jump to tab by number

**Field Navigation:**
- `↑` - Previous field
- `↓` - Next field
- `Home` - First field in tab
- `End` - Last field in tab
- `Page Up` - Jump up 10 fields
- `Page Down` - Jump down 10 fields

**Actions:**
- `Enter` - Edit current field (opens popup)
- `S` - Save all changes
- `Esc` - Close editor / Go back

## Visual Design

```
┌─ Screen Title ──────────────────────────────────────────┐
│ Header / Breadcrumb                                      │
├──────────────────────────────────────────────────────────┤
│ [1] General  [2] Details  [3] Settings                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                           │
│   Name:                John Doe                          │
│   Email:               john@example.com                  │
│   Phone:               555-1234                          │
│   > Address:           123 Main St                    ←  │
│   City:                Springfield                       │
│   ZIP Code:            12345                             │
│                                                        ↓  │
│                                                           │
│                                                           │
│ Tab│↑↓ Navigate│Enter Edit│S Save│Esc Back              │
└──────────────────────────────────────────────────────────┘

Legend:
- Tabs at top show all available tabs
- Active tab is highlighted
- > indicates selected field
- ↑↓ arrows indicate scroll position
```

## Example: ProjectInfoScreenV4

**Problem:** 57 fields in a flat grid was unmanageable

**Solution:** 6 tabs organizing fields logically

**Code Reduction:**
- V2: 927 lines (custom grid rendering)
- V4: 223 lines (using TabbedScreen)
- **76% reduction**

**Tabs:**
1. **Identity** (4 fields) - IDs, folder, name
2. **Request** (6 fields) - Request details
3. **Audit** (8 fields) - Auditor info
4. **Location** (7 fields) - Address
5. **Periods** (12 fields) - Date ranges
6. **More** (20 fields) - Contacts, software

**Implementation:**
```powershell
class ProjectInfoScreenV4 : TabbedScreen {
    ProjectInfoScreenV4([string]$name) : base("ProjectInfo", "Project Information") {
        $this.ProjectName = $name
        $this.Store = [TaskStore]::GetInstance()
    }

    [void] LoadData() {
        $project = $this.Store.GetProject($this.ProjectName)
        $this.ProjectData = $project
        $this._BuildTabs()  # Build 6 tabs
    }

    [void] SaveChanges() {
        $values = $this.TabPanel.GetAllValues()
        $this.Store.UpdateProject($this.ProjectName, $values)
    }
}
```

## Best Practices

### Tab Organization

**DO:**
- Group related fields logically
- Keep 4-12 fields per tab
- Name tabs clearly (avoid abbreviations)
- Order tabs by importance/frequency

**DON'T:**
- Put unrelated fields in same tab
- Create tabs with 1-2 fields
- Use more than 9 tabs (number keys)
- Make tabs too generic ("Misc", "Other")

### Field Definitions

**DO:**
- Use descriptive labels
- Set appropriate field types
- Mark required fields
- Provide validation

**DON'T:**
- Use field names as labels
- Treat all fields as text
- Skip type definitions
- Allow invalid data

### Performance

**DO:**
- Cache field definitions
- Only rebuild tabs when data changes
- Use auto-save sparingly

**DON'T:**
- Rebuild tabs on every render
- Save on every keystroke
- Load data repeatedly

### User Experience

**DO:**
- Show tab numbers for quick access
- Highlight selected field clearly
- Provide keyboard shortcuts
- Show save confirmation

**DON'T:**
- Hide active tab indicator
- Use unclear field names
- Require mouse interaction
- Auto-save without feedback

## Testing Checklist

- [ ] Tabs render correctly
- [ ] Tab navigation works (Tab, Shift+Tab, 1-9)
- [ ] Field navigation works (arrows, Home, End)
- [ ] Selected field is highlighted
- [ ] Enter key opens editor
- [ ] Editor shows current value
- [ ] Save updates all fields
- [ ] Changes persist after reload
- [ ] Scroll indicators appear when needed
- [ ] Status bar shows feedback
- [ ] Escape key closes editor
- [ ] Escape key exits screen
- [ ] Theme colors applied correctly
- [ ] Terminal resize handled

## Migration from Grid/List

**From Grid Layout:**
1. Identify logical field groups
2. Create tab per group
3. Convert field positions to field definitions
4. Remove custom rendering code
5. Use TabbedScreen base class

**From StandardListScreen:**
1. Keep using StandardListScreen for list view
2. Create TabbedScreen for detail view
3. Navigate from list to detail on Enter
4. Pass entity name/ID to detail screen

## Common Patterns

### Auto-save on Field Edit

```powershell
[void] OnFieldEdited($field, $newValue) {
    # Save immediately
    $this.SaveChanges()
}
```

### Validation Before Save

```powershell
[void] SaveChanges() {
    $values = $this.TabPanel.GetAllValues()

    # Validate
    $errors = @()
    if (-not $values['name']) {
        $errors += "Name is required"
    }
    if ($values['email'] -notmatch '@') {
        $errors += "Invalid email"
    }

    if ($errors.Count -gt 0) {
        $this.StatusBar.SetRightText($errors -join '; ')
        return
    }

    # Save
    $this.Store.Update($values)
}
```

### Conditional Fields

```powershell
hidden [void] _BuildTabs() {
    # Different tabs based on user role
    if ($this.UserRole -eq 'admin') {
        $this.TabPanel.AddTab('Admin', $this._GetAdminFields())
    }
}
```

### Field Dependencies

```powershell
[void] OnFieldEdited($field, $newValue) {
    # Update dependent fields
    if ($field.Name -eq 'country') {
        # Reload province choices
        $this._UpdateProvinceChoices($newValue)
        $this._BuildTabs()
    }
}
```

## Troubleshooting

**Tabs not showing:**
- Check `TabPanel.Tabs.Count` > 0
- Verify `LoadData()` is called
- Check `_BuildTabs()` is executed

**Fields not editable:**
- Verify `ShowEditor` is set to `true`
- Check `InlineEditor` is initialized
- Confirm `HandleKeyPress` routes Enter key

**Values not saving:**
- Add debug logging to `SaveChanges()`
- Check `GetAllValues()` returns data
- Verify store `Update()` succeeds

**Navigation not working:**
- Check `HandleKeyPress` is called
- Verify `TabPanel.HandleInput()` is invoked
- Confirm focus is on TabPanel

## Future Enhancements

**Possible additions:**
- Tab icons/glyphs
- Collapsible sections within tabs
- Field groups with headers
- Inline help text per field
- Undo/redo support
- Dirty field tracking
- Field history
- Bulk edit mode

## Summary

The Tabbed Interface Pattern provides:
- ✅ Clean organization of many fields
- ✅ Intuitive keyboard navigation
- ✅ 70-80% code reduction vs custom layouts
- ✅ Consistent UX across screens
- ✅ Reusable base class and widget
- ✅ Easy to extend and customize

**When you have 15+ fields to display, use TabbedScreen.**
