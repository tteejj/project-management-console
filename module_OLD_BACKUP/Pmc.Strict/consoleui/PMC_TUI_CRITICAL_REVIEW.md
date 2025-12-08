# PMC TUI CRITICAL REVIEW & IMPROVEMENT ROADMAP

## Executive Summary

This is a comprehensive critical review of the PMC TUI PowerShell application (68,000+ lines, 140 files). The codebase shows significant architectural issues that impact maintainability, reliability, and performance. While functional, it requires substantial refactoring to become robust.

**Overall Grade: C+ (Functional but Fragile)**

---

## PART 1: CRITICAL ISSUES DISCOVERED

### 1. ARCHITECTURAL SHOWSTOPPERS

#### Fragmented Initialization Hell
- **Location**: Start-PmcTUI.ps1:58-234
- **Issue**: 12+ subsystems load in rigid order with no dependency validation
- **Impact**: Startup failures common, debugging impossible, any reordering breaks everything
- **Evidence**: Circular dependency comments throughout (TaskListScreen.ps1:22-27)

#### Singleton Pandemic
- **Location**: Throughout (TaskStore, MenuRegistry, ThemeManager, etc.)
- **Issue**: 7 different singleton patterns, inconsistent thread-safety, testing nightmare
- **Impact**: Can't mock for tests, memory leaks, tight coupling everywhere
- **Evidence**: Incomplete DI migration (git log: "Migrate GetInstance() batch 1/2/3")

#### Triple-Buffered Rendering Insanity
- **Location**: PmcScreen.ps1:317-564
- **Issue**: Renders to ANSI → Parses ANSI with regex → Converts to engine calls
- **Impact**: 40-50% unnecessary CPU usage (even after recent optimizations)
- **Evidence**: Regex parsing on EVERY FRAME (line 517)

#### No Error Boundaries
- **Location**: PmcApplication.ps1:270-304
- **Issue**: Any render error crashes entire application
- **Impact**: Data loss, poor user experience, no recovery
- **Evidence**: FATAL ERROR dumps stack trace and exits

### 2. CODE QUALITY DISASTERS

#### God Class Syndrome
- **TaskListScreen.ps1**: 1,180 lines, 45+ methods, violates SRP
- **UniversalList.ps1**: 1,200+ lines of tangled UI logic
- **Impact**: Impossible to test, understand, or modify safely

#### Massive Duplication
- **9 redundant view screens** collapsed into 150-line switch statement
- **No composable filters**, everything copy-pasted
- **Impact**: Maintenance nightmare, bugs multiply

#### Three Error Handling Patterns
1. Throw exceptions (crashes app)
2. LastError property (often unchecked)
3. Try-catch-ignore (silent failures)
- **Impact**: Unpredictable behavior, hidden failures, data corruption

### 3. PERFORMANCE ISSUES

#### O(n²) Algorithms (Recently Fixed)
- **Location**: TaskListScreen.ps1:379-430
- **Shows algorithmic naivety** - how many other O(n²) lurk?

#### Excessive Safe Property Access
- **Get-SafeProperty called 5,000+ times per render**
- **PSObject reflection is slow**
- **No caching or type-safe models**

#### Over-Rendering
- **60 FPS target for terminal app** (16ms sleep)
- **Full screen rebuilds on small changes**
- **No dirty region tracking**

### 4. USER EXPERIENCE FAILURES

#### Keyboard Shortcut Chaos
- **20+ shortcuts, no on-screen reference**
- **Ctrl+C = Complete (not Copy!)**
- **Mode confusion** (e works in list, not editor)
- **ShortcutRegistry.ps1 exists but unused**

#### Cryptic Error Messages
- "Get-PmcAllData returned null" shown to users
- Stack traces dumped on crashes
- No recovery hints or user guidance

#### No Undo/Redo
- **Delete = permanent data loss**
- **No command pattern**
- **Backup exists but only for save rollback**

### 5. RELIABILITY NIGHTMARES

#### Race Conditions (Recently Fixed)
- **TaskStore.ps1:337-392** had check-then-act races
- **Manual locking prone to errors**
- **Deadlock risks from nested locks**

#### Silent Callback Failures
- **Exceptions swallowed in event handlers**
- **UI doesn't update, user sees stale data**
- **No error indication**

#### Data Loss on Concurrent Edits
- **No version control or conflict detection**
- **Last write wins**
- **External changes overwritten**

### 6. SECURITY VULNERABILITIES

#### ANSI Injection
- **User input not sanitized**
- **Control sequences could clear screen, hide data**
- **Low severity (local app) but sloppy**

#### Path Traversal
- **$env:PMC_LOG_PATH not validated**
- **Could write logs outside app directory**
- **Symlink attacks possible**

### 7. MAINTAINABILITY DEBT

#### Technical Debt Explosion
- **118 TODO/FIXME/HACK comments**
- **9 archived redundant screens**
- **Multiple .bak files in git**
- **Every "comprehensive fix" reveals more issues**

#### Testing Impossible
- **Global state everywhere**
- **Console dependencies unmockable**
- **No interfaces for injection**
- **0% automated test coverage**

---

## PART 2: TANGIBLE FEATURE IMPROVEMENTS

### IMMEDIATE VALUE FEATURES (Quick Wins)

#### 1. Smart Command Palette (2-3 days)
**Problem**: 20+ shortcuts impossible to remember
**Solution**:
- Ctrl+P opens fuzzy search command palette
- Shows ALL available actions with descriptions
- Learns from usage (MRU at top)
- Shows keyboard shortcut for each command
```powershell
┌─ Command Palette ─────────────────────┐
│ > compl                               │
│   [c] Complete Task                   │
│   [Ctrl+C] Complete Selected Tasks    │
│   [Tab] Autocomplete                  │
└───────────────────────────────────────┘
```

#### 2. Inline Batch Operations (1 day)
**Problem**: Multi-select exists but limited operations
**Solution**:
- Select multiple → Right-click → Batch menu
- Batch move to project
- Batch change priority
- Batch tag application
- Progress bar for long operations

#### 3. Smart Filters with Natural Language (3-4 days)
**Problem**: Filter is just text search
**Solution**:
```
Filter: "high priority due this week not completed"
        "overdue @home -project:work"
        "#urgent created:today"
```
- Parse natural language queries
- Composable filter tokens
- Save named filters
- Filter history

#### 4. Task Templates (2 days)
**Problem**: Repetitive task creation
**Solution**:
- Save task as template
- Templates include: description pattern, tags, project, priority
- Quick key (T) opens template picker
- Variables in templates: `{today}`, `{tomorrow}`, `{monday}`

### HIGH-VALUE PRODUCTIVITY FEATURES

#### 5. Time Tracking Integration (3-4 days)
**Problem**: No time tracking
**Solution**:
- Start/stop timer on tasks (spacebar when selected)
- Show elapsed time in list
- Daily/weekly time reports
- Pomodoro mode (25min work, 5min break)
- Time estimates vs actual
- NO external integration needed - local only

#### 6. Quick Notes & Attachments (2-3 days)
**Problem**: Tasks have single text field
**Solution**:
- F2 opens quick note editor for task
- Markdown support
- Link local files (drag-drop paths)
- Inline checklist within task
- Show paperclip icon for tasks with notes

#### 7. Smart Scheduling Assistant (4-5 days)
**Problem**: Manual date assignment
**Solution**:
- "Schedule" command analyzes workload
- Suggests optimal due dates based on:
  - Current task load
  - Priority levels
  - Estimated time
  - Dependencies
- Workload visualization (calendar heatmap)
- Rebalance overloaded days

#### 8. Dependency Management (3-4 days)
**Problem**: No task relationships beyond parent/child
**Solution**:
- "Blocks/Blocked by" relationships
- Automatic scheduling based on dependencies
- Critical path highlighting
- Warn when blocking task is overdue
- Gantt chart view (ASCII art)

### POWER USER FEATURES

#### 9. Customizable Dashboards (4-5 days)
**Problem**: Fixed dashboard layout
**Solution**:
- Drag-drop widget arrangement
- Widget types:
  - Stats (customizable metrics)
  - Mini calendar
  - Priority matrix
  - Recent activity
  - Custom queries
- Save multiple dashboard layouts
- Quick switch between dashboards (D key)

#### 10. Smart Autocomplete Everything (3-4 days)
**Problem**: Typing same things repeatedly
**Solution**:
- Learn from user's task history
- Autocomplete:
  - Task descriptions
  - Project names
  - Tags
  - Common phrases
- Snippet expansion: `em*` → "Email * about *"
- Frequency-based suggestions

#### 11. Macro Recording & Playback (2-3 days)
**Problem**: Repetitive operations
**Solution**:
- F9 starts recording keystrokes
- F9 stops and saves macro
- F10 lists saved macros
- Assign macro to key combo
- Edit macros (simple text format)

#### 12. Advanced Bulk Import/Export (2-3 days)
**Problem**: No data portability
**Solution**:
- Import from:
  - CSV with field mapping
  - Markdown task lists
  - Plain text with smart parsing
- Export to:
  - Markdown
  - CSV
  - HTML report
  - JSON
- Incremental import (merge, don't replace)

### DATA INTELLIGENCE FEATURES

#### 13. Smart Suggestions Engine (5-6 days)
**Problem**: No intelligence in task management
**Solution**:
- Suggest tasks based on patterns:
  - "You usually create 'Weekly report' on Fridays"
  - "This looks similar to [previous task], copy settings?"
  - "5 tasks due tomorrow, consider rescheduling?"
- Learn user patterns
- Configurable suggestion frequency

#### 14. Personal Productivity Analytics (3-4 days)
**Problem**: No insights into productivity
**Solution**:
- Dashboard showing:
  - Completion rate trends
  - Time of day productivity
  - Project time allocation
  - Overdue patterns
  - Task velocity
- Weekly email-style report (rendered in TUI)
- Compare weeks/months

#### 15. Smart Tagging System (2-3 days)
**Problem**: Manual tagging is tedious
**Solution**:
- Auto-suggest tags based on content
- Tag aliases (#urgent = #important)
- Tag groups (nested tags)
- Tag colors in list view
- Quick tag menu (# key)
- Tag cloud visualization

### QUALITY OF LIFE IMPROVEMENTS

#### 16. Instant Search & Preview (2 days)
**Problem**: Finding tasks is slow
**Solution**:
- / key opens instant search
- Results update as you type
- Preview pane shows full task details
- Search history
- Search across all fields

#### 17. Smart Notifications (2-3 days)
**Problem**: No reminders
**Solution**:
- Native terminal notifications (bell + status)
- Smart timing:
  - Morning: "3 tasks due today"
  - End of day: "2 tasks still pending"
- Customizable notification rules
- Snooze notifications

#### 18. Focus Mode (1-2 days)
**Problem**: Too much information
**Solution**:
- F key enters focus mode
- Shows only:
  - Current task (large font)
  - Timer
  - Single-line progress bar
- Blocks navigation until complete/cancel
- Pomodoro integration

#### 19. Quick Capture Buffer (2 days)
**Problem**: Interruptions break flow
**Solution**:
- Ctrl+Space opens capture buffer
- Type multiple tasks (one per line)
- Intelligent parsing:
  - "Call Bob tomorrow #phone @work !!!"
  - Creates task with due date, tag, project, high priority
- Bulk create on Enter

#### 20. Contextual Help System (2-3 days)
**Problem**: No in-app help
**Solution**:
- F1 shows context-sensitive help
- Interactive tutorial mode
- Tip of the day
- Searchable command reference
- Show examples for current screen

---

## PART 3: IMPLEMENTATION PRIORITY MATRIX

### Phase 1: Foundation (Month 1)
**Fix critical issues first:**
1. Add error boundaries (1 day)
2. Fix input validation (2 days)
3. Consolidate error handling (3 days)
4. Add undo/redo (3 days)

### Phase 2: Quick Wins (Month 2)
**High value, low effort:**
1. Command Palette (3 days)
2. Smart Filters (4 days)
3. Task Templates (2 days)
4. Instant Search (2 days)
5. Quick Capture (2 days)

### Phase 3: Productivity (Month 3)
**Core value additions:**
1. Time Tracking (4 days)
2. Smart Autocomplete (4 days)
3. Batch Operations (1 day)
4. Quick Notes (3 days)
5. Focus Mode (2 days)

### Phase 4: Intelligence (Month 4)
**Advanced features:**
1. Smart Scheduling (5 days)
2. Dependency Management (4 days)
3. Productivity Analytics (4 days)
4. Smart Suggestions (6 days)

### Phase 5: Polish (Month 5)
**User experience:**
1. Customizable Dashboards (5 days)
2. Macro System (3 days)
3. Smart Tagging (3 days)
4. Contextual Help (3 days)
5. Import/Export (3 days)

---

## CONCLUSION

The PMC TUI is **ambitious but architecturally flawed**. The critical issues (initialization hell, singleton pandemic, no error boundaries) must be fixed immediately or the application will remain fragile.

The proposed features focus on **actual productivity gains** rather than technology for technology's sake:
- **No cloud integration** (as requested)
- **No external dependencies**
- **All local, fast, keyboard-driven**
- **Progressive enhancement** (app stays usable during development)

**Estimated effort**: 5 months with one developer
**Recommended approach**: Fix critical issues first, then add features incrementally
**Expected outcome**: Transform from "functional but fragile" to "robust and delightful"

The codebase needs discipline and systematic refactoring, but the bones of a good application are there. With focused effort on both fixing issues and adding smart features, PMC TUI could become a best-in-class terminal productivity tool.