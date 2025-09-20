# PMC Technical Debt Analysis

**Generated**: 2025-01-27
**Codebase Size**: 39 PowerShell files, ~14,666 lines of code, ~366 functions/classes
**Status**: Complex but generally well-structured with several areas needing consolidation

---

## 🚨 Critical Issues Found

### 1. **Dead/Unused Code**
- **HelpUI.ps1 orphaned functions**:
  - `Show-PmcHelpAllView`, `Show-PmcQuickHelp`, `Show-PmcHelpHeader`, `Show-PmcHelpNavigation` (HelpUI.ps1:429-544)
  - These are only called within HelpUI.ps1 but `Show-PmcSmartHelp` now uses universal display
- **Duplicate help implementations**: Both HelpUI.ps1 and Help.ps1 have overlapping functionality
- **Views.ps1 legacy functions**: 9 old-style view functions (Show-PmcTodayTasks, Show-PmcTomorrowTasks, etc.) that duplicate UniversalDisplay.ps1 functionality

### 2. **Display System Fragmentation**
- **Three competing grid systems**:
  - `Show-PmcDataGrid` (DataDisplay.ps1:1635) - Universal system
  - `Show-PmcCustomGrid` (DataDisplay.ps1:1793) - Wrapper function
  - Legacy view functions in Views.ps1
- **40+ calls to Show-PmcCustomGrid** across 10 files vs **12 calls to Show-PmcDataGrid** across 3 files
- **Inconsistent styling**: 213 direct `Write-Host` calls with colors instead of PMC's style system

### 3. **Incomplete Integrations**
- **UniversalDisplay.ps1**: Register-PmcUniversalCommands called only in CommandMap.ps1:258-262, not fully integrated
- **TerminalDimensions.ps1**: New service created but 7 remaining `try { [Console]::WindowWidth } catch` patterns not converted
- **Missing exports**: TerminalDimensions.ps1 functions not referenced elsewhere

---

## 📊 Technical Debt Analysis

### File Size Issues (>50KB files need splitting):
1. **Help.ps1** (109KB) - Massive file with 99 functions
2. **DataDisplay.ps1** (83KB) - Core display logic
3. **Interactive.ps1** (63KB) - Interactive mode handling

### Styling Inconsistencies:
- **410 raw Write-Host/Write-Output calls** instead of Write-PmcStyled
- **19 manual border drawing** patterns instead of consistent theming
- **18 Clear-Host calls** without VT100 integration

### Pattern Inconsistencies:
- **Mixed grid instantiation**: `[PmcGridRenderer]::new()` in 4 files vs function calls
- **Inconsistent error handling**: Some files use try-catch, others don't
- **No standardized module exports**: Only 7 files have Export-ModuleMember

---

## 🔧 Consolidation Opportunities

### 1. **Display System Unification**
**Eliminate**: Views.ps1 legacy functions → Replace with UniversalDisplay calls
**Standardize**: All grid usage → Show-PmcDataGrid only
**Remove**: Show-PmcCustomGrid wrapper function

### 2. **Help System Consolidation**
**Keep**: Help.ps1 core functionality + new Show-PmcSmartHelp
**Remove**: HelpUI.ps1 orphaned functions
**Integrate**: Remaining HelpUI.ps1 utilities into Help.ps1

### 3. **Styling Standardization**
**Replace**: 213 colored Write-Host calls → Write-PmcStyled
**Standardize**: Manual border patterns → Consistent theme system
**Integrate**: Remaining console calls → TerminalDimensions service

### 4. **File Structure Optimization**
**Split Help.ps1**: Core (commands) vs UI (display) vs Utils (helpers)
**Merge small files**: Some single-class files could be consolidated
**Add exports**: Standardize Export-ModuleMember across all modules

---

## 🎯 Priority Recommendations

### **HIGH PRIORITY** (Immediate)
1. **Remove dead code** from HelpUI.ps1 (functions 429-544)
2. **Replace Show-PmcCustomGrid calls** with Show-PmcDataGrid
3. **Convert remaining 7 console dimension calls** to TerminalDimensions service
4. **Deprecate Views.ps1 legacy functions** → Use UniversalDisplay equivalents

### **MEDIUM PRIORITY** (Next sprint)
1. **Split Help.ps1** into logical modules (99 functions is excessive)
2. **Standardize 213 colored Write-Host calls** → Write-PmcStyled
3. **Add Export-ModuleMember** to all 32 files missing it
4. **Integrate Register-PmcUniversalCommands** into main initialization

### **LOW PRIORITY** (Technical debt)
1. **Consolidate manual border drawing** patterns (19 instances)
2. **Replace Clear-Host calls** with VT100 sequences (18 instances)
3. **Standardize error handling** patterns across modules
4. **Add comprehensive module documentation**

---

## 📈 Code Quality Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|---------|
| Dead Functions | ~20 | 0 | 🔴 High |
| Display Systems | 3 | 1 | 🔴 High |
| Styling Inconsistency | 213 | <50 | 🔴 High |
| File Size (>50KB) | 3 | 0 | 🟡 Medium |
| Module Exports | 7/39 | 39/39 | 🟡 Medium |

**Overall Assessment**: The codebase shows signs of rapid evolution with multiple competing patterns. Core functionality is solid but needs architectural cleanup to prevent further fragmentation.

## Resolution Plan

### Phase 1: Critical Cleanup (HIGH PRIORITY) ✅ COMPLETED
- [x] Remove dead code from HelpUI.ps1 (functions 429-544)
- [x] Replace 40+ Show-PmcCustomGrid calls with Show-PmcDataGrid (converted to compatibility wrapper)
- [x] Convert remaining 7 console dimension calls to TerminalDimensions service
- [x] Remove legacy Views.ps1 functions and update references (moved to Views.ps1.backup)

### Phase 2: System Consolidation (MEDIUM PRIORITY)
- [ ] Split Help.ps1 into HelpCore.ps1, HelpUI.ps1, HelpUtils.ps1
- [ ] Replace 213 colored Write-Host calls with Write-PmcStyled
- [ ] Add Export-ModuleMember to all modules
- [ ] Fully integrate UniversalDisplay system

### Phase 3: Technical Debt (LOW PRIORITY)
- [ ] Consolidate border drawing patterns
- [ ] Replace Clear-Host with VT100 sequences
- [ ] Standardize error handling patterns
- [ ] Add comprehensive documentation

## Success Criteria
- ✅ Zero dead functions
- ✅ Single unified display system
- ✅ Consistent styling throughout
- ✅ All files <50KB
- ✅ 100% module exports
- ✅ <50 styling inconsistencies