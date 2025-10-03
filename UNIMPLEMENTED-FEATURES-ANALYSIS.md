# Unimplemented Features - Analysis & Resolution Plan

## ✅ Theme System - FULLY IMPLEMENTED (2025-10-02)

**Status**: ✅ **COMPLETE AND WORKING**

**What Was Done**:
1. ✅ Created `PmcTheme` class with 4 complete themes (Default, Dark, Light, Solarized)
2. ✅ Added theme persistence to `~/.pmc-theme` file
3. ✅ Refactored all color methods to use theme system (indirection pattern)
4. ✅ Updated theme editor to actually apply themes
5. ✅ Added auto-load on app startup

**How It Works**:
```powershell
# All existing color calls unchanged:
$this.terminal.WriteAtColor(4, $y++, "Error:", [PmcVT100]::Red(), "")

# But [PmcVT100]::Red() now returns theme-aware color:
static [string] Red() { return [PmcTheme]::GetColor('Red') }

# Theme changes affect ALL 620+ color calls automatically
[PmcTheme]::SetTheme('Dark')  # Instantly changes all colors
```

**Actual Time**: ~2 hours (not 8-12 hours estimated)

**Key Insight**: Used indirection pattern - changed what the methods return, not the 620+ call sites.

**Result**: Theme system now fully functional with persistence and auto-restore.

**See**: `THEME-SYSTEM-COMPLETE.md` for full implementation details.

---

## Other Unimplemented Features

### 1. ⚠️ **Tag Filtering** (#tag support)

**Current State**: NO IMPLEMENTATION AT ALL

**What's Missing**:
- No tag parsing from task text
- No tag data model (tasks don't have .tags array in TUI context)
- No tag filter UI
- No tag search/filter logic

**Why Not Implemented**:
- Requires data model change (PMC core would need to support tags)
- Task text parsing would need enhancement
- Filter UI would need complete redesign
- Backend doesn't have tag support

**What Happens Now**:
- Users can type `#tag` in task text but it's just text, not functional
- No way to filter by tags
- No tag extraction or display

**Resolution Options**:
1. **Add Basic Tag Support** (4-6 hours):
   - Parse `#tag` from task text using regex
   - Extract to virtual .tags property
   - Add "T" key to filter by tag
   - Show tags in task detail

2. **Wait for Backend** (proper solution):
   - PMC core needs native tag support
   - Then TUI can use it properly

3. **Document as "Not Supported"**:
   - Remove from feature list
   - Add to "Future Enhancements"

**Current User Experience**:
- Tags don't work, will confuse users if they try
- Should either implement or clearly document as unavailable

---

### 2. ⚠️ **Recurring Tasks**

**Current State**: NO IMPLEMENTATION

**What's Missing**:
- No recurrence field in task data model
- No UI to set recurrence pattern
- No logic to auto-create next instance on completion
- No recurrence display

**Complexity**:
- Needs recurrence pattern parsing (daily/weekly/monthly)
- Needs date calculation logic
- Needs task cloning on completion
- Needs recurrence display in task detail

**What Happens Now**:
- No way to create recurring tasks
- Users must manually recreate tasks

**Resolution Options**:
1. **Full Implementation** (12-16 hours):
   - Add recurrence field to data model
   - Build recurrence pattern UI
   - Implement auto-create logic
   - Add to task detail display

2. **Simple Daily Repeat** (2-3 hours):
   - Just add "Repeat Daily" checkbox
   - On complete, create copy with tomorrow's date
   - Limited but functional

3. **Document as Future Feature**:
   - Clear "not supported" message
   - Workaround: use templates for repeated tasks

**Current User Experience**:
- No recurring tasks available
- Not mentioned in UI, so no confusion

---

### 3. ⚠️ **Task Archiving**

**Current State**: NO IMPLEMENTATION

**What's Missing**:
- No "Archive" function in menus
- No archived status
- No archive view
- No way to hide archived tasks
- Completed tasks stay in list forever

**What Happens Now**:
- Completed tasks accumulate in task list
- Can filter them out by status but they're still there
- No way to "put away" old completed tasks

**Resolution Options**:
1. **Simple Archive** (2-3 hours):
   - Add `archived: true` property to tasks
   - Add "Archive" menu item and 'A' key in task detail
   - Filter out archived tasks by default
   - Add "View Archives" option

2. **Archive to Separate File** (4-5 hours):
   - Move archived tasks to `tasks.archive.json`
   - Cleaner but more complex
   - Requires backup/restore support

3. **Use Existing Status** (30 minutes):
   - Just rename 'completed' to include archiving concept
   - Add filter to hide old completed tasks (>30 days)
   - Quick fix but not ideal

**Current User Experience**:
- Tasks accumulate forever
- List gets cluttered over time
- Users will eventually want this feature

**Recommendation**: Implement Simple Archive (#1) - it's easy and valuable

---

### 4. ⚠️ **Calendar Export (.ics)**

**Current State**: NO IMPLEMENTATION

**What's Missing**:
- No .ics file generation
- No export menu
- No date formatting for iCalendar format

**What Happens Now**:
- No way to export tasks to calendar apps
- Users can't sync with Outlook/Google Calendar

**Resolution Options**:
1. **Full iCalendar Export** (6-8 hours):
   - Generate RFC 5545 compliant .ics file
   - Include all tasks with due dates
   - Add VEVENT blocks with DTSTART, DTEND, SUMMARY
   - Save to user-specified location

2. **Simple CSV Export** (1-2 hours):
   - Export to CSV with: Title, Due Date, Project, Priority
   - Users can import to Excel/Calendar manually
   - Much easier to implement

3. **Don't Implement**:
   - Low priority for CLI tool
   - Document as "use CSV export instead"

**Current User Experience**:
- No calendar integration
- Not a critical feature for CLI users

**Recommendation**: Skip for now, add CSV export instead (more useful)

---

### 5. ⚠️ **Task Time Estimates**

**Current State**: NO IMPLEMENTATION

**What's Missing**:
- No 'estimate' field in data model
- No UI to set estimates
- No estimate display
- No estimate vs. actual time comparison

**What Happens Now**:
- Can track actual time spent (working)
- Can't estimate how long task will take
- No burn-down by hours

**Resolution Options**:
1. **Add Estimate Field** (2-3 hours):
   - Add estimate property to tasks
   - Add "Set Estimate" option in task detail (E key when in detail)
   - Show in task detail: "Estimate: 4h | Actual: 2.5h"
   - Show progress bar if actual time logged

2. **Skip It**:
   - Time tracking is already working
   - Estimates are optional
   - Users can add to task notes

**Current User Experience**:
- No estimates available
- Time tracking works but no comparison

**Recommendation**: Easy to add, moderate value - implement if time allows

---

### 6. ⚠️ **Focus Mode Special Display**

**Current State**: PARTIALLY IMPLEMENTED

**What Works**:
- Focus mode exists functionally
- Can set/clear focus
- Focus affects task filtering

**What's Missing**:
- No special "focus view" with large task display
- No distraction-free mode
- No full-screen task detail

**What Happens Now**:
- Focus works but looks same as filtered view
- No visual distinction

**Resolution Options**:
1. **Full-Screen Task Detail** (1-2 hours):
   - When focused, press 'F' to enter focus display
   - Show only focused task in large format
   - Hide menu bar, maximize content
   - Esc to exit focus display

2. **Just Visual Indicator** (30 minutes):
   - Add "🎯 FOCUSED:" to title bar when focused
   - Different background color when focused
   - Simple but effective

3. **Keep Current**:
   - Focus works functionally
   - Visual enhancement not critical

**Current User Experience**:
- Focus works but not visually distinct
- Could be better but functional

**Recommendation**: Add visual indicator (#2) - quick win

---

### 7. ⚠️ **Preferences Editable**

**Current State**: READ-ONLY DISPLAY

**What Works**:
- Shows preferences/config values
- Displays current settings

**What's Missing**:
- No way to edit preferences in TUI
- No save mechanism
- No validation

**What Happens Now**:
- Users can VIEW preferences
- Must edit JSON/config file manually to change
- TUI is read-only

**Resolution Options**:
1. **Full Preference Editor** (6-8 hours):
   - Navigate preferences with ↑↓
   - Edit values with Enter
   - Validate input
   - Save to config file
   - Requires knowing all preference types/formats

2. **Config File Launch** (30 minutes):
   - Add "Edit in $EDITOR" option
   - Opens config file in user's editor
   - Simple and works

3. **Keep Read-Only**:
   - Document: "View preferences here, edit config file to change"
   - Clear user expectations

**Current User Experience**:
- Can see settings
- Must manually edit files to change
- Not intuitive but works

**Recommendation**: Add "Edit in Editor" option (#2) - simple and effective

---

## Summary Table

| Feature | Current State | Impact | Complexity | Recommendation |
|---------|---------------|--------|------------|----------------|
| **Theme Switching** | ✅ **FULLY IMPLEMENTED** | Medium | ✅ Solved with indirection | ✅ **COMPLETE** - See THEME-SYSTEM-COMPLETE.md |
| **Tag Filtering** | Not implemented | Medium | High (data model) | Document as unavailable, plan for v2 |
| **Recurring Tasks** | Not implemented | Medium | Very High | Document as future, use templates as workaround |
| **Task Archiving** | Not implemented | High | Low | **IMPLEMENT** - easy & valuable |
| **Calendar Export** | Not implemented | Low | Medium | Skip, add CSV export instead |
| **Time Estimates** | Not implemented | Medium | Low | **IMPLEMENT** if time allows |
| **Focus Mode Display** | Partial | Low | Low | **ADD** visual indicator - quick win |
| **Preferences Edit** | Read-only | Medium | Low | **ADD** "Edit in $EDITOR" - easy |

---

## Recommended Actions

### ✅ Completed
1. ✅ **Theme System**: Fully implemented with persistence and 4 themes

### High Value (Next 2-3 hours)
4. **Implement Task Archiving**: Simple `archived: true` flag + filter
5. **Add Time Estimates**: Estimate field + display in task detail

### Document as Unavailable
6. **Tag Filtering**: "Not supported - use project filtering instead"
7. **Recurring Tasks**: "Not supported - use templates for repeated tasks"
8. **Calendar Export**: "Not supported - manual entry or CSV export available"

---

## What Users Should Expect

### ✅ **Working Features**
- All task management (CRUD)
- Projects, time tracking, dependencies
- Search, filter, sort
- Bulk operations
- Undo/redo
- Multiple views
- Help system
- Templates, queries
- **Theme switching (4 themes with persistence)** ✨ NEW

### ❌ **Not Available**
- Tag filtering
- Recurring tasks
- Calendar export
- Full preference editing

### 🔧 **Workarounds Available**
- Tags → Use projects instead
- Recurring → Use templates
- Preferences → Edit config file directly
- Calendar → Manual entry or use time tracking reports

---

## Conclusion

### ✅ Theme Issue RESOLVED (2025-10-02)

**The theme system was the main "fake" feature** - it showed themes but didn't apply them.

**NOW FIXED**: Theme switching is fully implemented with:
- 4 professionally designed themes (Default, Dark, Light, Solarized)
- Persistence to ~/.pmc-theme file
- Auto-restore on startup
- Instant color updates across all 620+ UI elements
- Only took ~2 hours using clever indirection pattern

**Other features are simply not implemented**, which is fine as long as users know they're not available. The key is **honest communication**:
- Don't show features that don't work ✅ (theme now works!)
- Document what's available vs. coming later ✅
- Provide workarounds where possible ✅

**Remaining Quick Wins** (total ~3-4 hours):
- Add task archiving
- Add time estimates
- Add focus visual indicator
- Add "edit preferences in editor" option

These would round out the TUI nicely and address the remaining gaps.
