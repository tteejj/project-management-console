# Theme Cache Issue - Complete Impact Report

## Summary
The theme caching issue affects **EVERY location** that calls `Save-PmcConfig` throughout the codebase. This is a **systemic problem** that impacts all configuration changes, not just themes.

---

## Root Cause (Confirmed)

### 1. Save-PmcConfig Never Invalidates Cache
**File**: `/home/teej/pmc/module/Pmc.Strict/src/Config.ps1:58-76`

Every call to `Save-PmcConfig` writes to disk but doesn't invalidate the ConfigCache:
```powershell
function Save-PmcConfig {
    # ... writes to config.json ...
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
    # MISSING: [ConfigCache]::InvalidateCache()
}
```

### 2. Initialize-PmcThemeSystem Returns Early Without -Force
**File**: `/home/teej/pmc/module/Pmc.Strict/src/Theme.ps1:3-13`

```powershell
function Initialize-PmcThemeSystem {
    param([switch]$Force)

    $existingTheme = Get-PmcState -Section 'Display' -Key 'Theme'
    if ($existingTheme -and -not $Force) {
        return  # Exits without reloading from config
    }
    # ... rest of initialization ...
}
```

---

## All Affected Locations (12 Total)

### CATEGORY 1: Theme-Related Config Saves (7 locations)

#### 1. ThemeEditorScreen._ApplyTheme()
**File**: `consoleui/screens/ThemeEditorScreen.ps1:388`
**Context**: User selects theme in TUI theme editor
```powershell
Save-PmcConfig $cfg
Initialize-PmcThemeSystem  # Missing -Force
```
**Impact**: Theme changes don't take effect until restart (and may not persist)

---

#### 2. Set-PmcTheme (CLI command)
**File**: `src/Theme.ps1:85`
**Context**: User runs `theme set <color>` command
```powershell
Save-PmcConfig $cfg
# NO Initialize-PmcThemeSystem call at all!
```
**Impact**: Theme saved but NEVER loaded into state - requires manual restart

---

#### 3. Reset-PmcTheme (CLI command)
**File**: `src/Theme.ps1:101`
**Context**: User runs `theme reset` command
```powershell
Save-PmcConfig $cfg
# NO Initialize-PmcThemeSystem call!
```
**Impact**: Theme saved but NEVER loaded into state

---

#### 4. Edit-PmcTheme (interactive slider)
**File**: `src/Theme.ps1:170`
**Context**: User adjusts RGB sliders and presses Enter
```powershell
Save-PmcConfig $cfg
# NO Initialize-PmcThemeSystem call!
```
**Impact**: Theme saved but NEVER loaded into state

---

#### 5. Show-PmcPreferences (CSV ledger setting)
**File**: `src/Theme.ps1:222`
**Context**: User changes CSV ledger preference
```powershell
Save-PmcConfig $cfg
# This isn't theme-related, but same cache issue
```
**Impact**: Setting saved but not immediately effective

---

#### 6. Apply-PmcTheme (preset themes)
**File**: `src/Theme.ps1:253-254`
**Context**: User applies preset theme (e.g., `theme apply blue`)
```powershell
Save-PmcConfig $cfg
Initialize-PmcThemeSystem  # Missing -Force
```
**Impact**: Theme changes require restart

---

#### 7. PmcThemeManager.SetTheme()
**File**: `consoleui/theme/PmcThemeManager.ps1:412-420`
**Context**: Programmatic theme change via ThemeManager
```powershell
Save-PmcConfig $cfg
[ConfigCache]::InvalidateCache()  # THIS ONE DOES invalidate!
Initialize-PmcThemeSystem  # But missing -Force
```
**Impact**: Partially works (cache invalidated) but state not updated

---

### CATEGORY 2: Icon Mode Changes (2 locations)

#### 8. Set-PmcIconMode (src/Theme.ps1)
**File**: `src/Theme.ps1:120`
**Context**: User runs `config icons ascii/emoji` command
```powershell
Save-PmcConfig $cfg
# NO cache invalidation
```
**Impact**: Icon mode saved but not immediately effective

---

#### 9. Set-PmcIconMode (src/Config.ps1)
**File**: `src/Config.ps1:177`
**Context**: Duplicate function in Config.ps1 (same purpose)
```powershell
Save-PmcConfig $cfg
# NO cache invalidation
```
**Impact**: Same as above

---

### CATEGORY 3: Reload Commands (2 locations)

#### 10. Reload-PmcConfig (src/Config.ps1)
**File**: `src/Config.ps1:154-160`
**Context**: User runs `config reload` command
```powershell
$Script:PmcConfig = $null  # Clears old script-level cache
$cfg = Get-PmcConfig       # But ConfigCache may return stale data
```
**Impact**: Might not actually reload if ConfigCache is stale

---

#### 11. Reload-PmcConfig (src/Theme.ps1)
**File**: `src/Theme.ps1:264-273`
**Context**: User runs `reload` command
```powershell
Initialize-PmcThemeSystem  # Missing -Force
# NO cache invalidation
```
**Impact**: Reload doesn't actually reload if state already initialized

---

### CATEGORY 4: Startup Initialization (1 location)

#### 12. Start-PmcTUI.ps1 Theme Registration
**File**: `consoleui/Start-PmcTUI.ps1:271-272`
**Context**: TUI startup
```powershell
Initialize-PmcThemeSystem  # No -Force (correct for startup)
```
**Impact**: This one is CORRECT - should not force on startup

---

## Impact Matrix

| Location | Saves Config | Invalidates Cache | Calls Init-Theme | Uses -Force | Severity |
|----------|--------------|-------------------|------------------|-------------|----------|
| ThemeEditorScreen | ✓ | ✗ | ✓ | ✗ | **CRITICAL** |
| Set-PmcTheme | ✓ | ✗ | ✗ | N/A | **CRITICAL** |
| Reset-PmcTheme | ✓ | ✗ | ✗ | N/A | **CRITICAL** |
| Edit-PmcTheme | ✓ | ✗ | ✗ | N/A | **CRITICAL** |
| Show-PmcPreferences | ✓ | ✗ | N/A | N/A | MAJOR |
| Apply-PmcTheme | ✓ | ✗ | ✓ | ✗ | **CRITICAL** |
| PmcThemeManager | ✓ | ✓ | ✓ | ✗ | MODERATE |
| Set-PmcIconMode (Theme) | ✓ | ✗ | N/A | N/A | MAJOR |
| Set-PmcIconMode (Config) | ✓ | ✗ | N/A | N/A | MAJOR |
| Reload-PmcConfig (Config) | ✗ | ✗ | N/A | N/A | MINOR |
| Reload-PmcConfig (Theme) | ✗ | ✗ | ✓ | ✗ | MODERATE |
| Start-PmcTUI | ✗ | N/A | ✓ | ✗ | OK |

---

## Systemic Problems Identified

### Problem 1: No Central Save Function
Every location calls `Save-PmcConfig` directly. There's no central function that ensures:
- Cache invalidation
- State updates
- Consistent error handling

### Problem 2: Three Different Patterns
1. **Save only** (Set-PmcTheme, Reset-PmcTheme, Edit-PmcTheme)
2. **Save + Init** (ThemeEditorScreen, Apply-PmcTheme)
3. **Save + Invalidate + Init** (PmcThemeManager only!)

### Problem 3: Duplicate Functions
- Two `Set-PmcIconMode` functions (Theme.ps1 and Config.ps1)
- Two `Reload-PmcConfig` functions (Theme.ps1 and Config.ps1)

### Problem 4: Missing -Force Everywhere
None of the locations that call `Initialize-PmcThemeSystem` after saving use the `-Force` flag, so state is never updated.

---

## Recommended Fixes

### FIX 1: Update Save-PmcConfig (Affects ALL locations)
**File**: `src/Config.ps1:72`

```powershell
function Save-PmcConfig {
    param($cfg)
    $providers = Get-PmcConfigProviders
    if ($providers.Set) {
        try {
            & $providers.Set $cfg
            # Invalidate cache after custom provider save
            if (Get-Command -Name ConfigCache -Type Type -ErrorAction SilentlyContinue) {
                [ConfigCache]::InvalidateCache()
            }
            return
        } catch {
            # Custom config provider failed - fall back to default
        }
    }
    # Default: write to pmc/config.json near module root
    try {
        $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $path = Join-Path $root 'config.json'
        $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8

        # CRITICAL FIX: Invalidate config cache after save
        if (Get-Command -Name ConfigCache -Type Type -ErrorAction SilentlyContinue) {
            [ConfigCache]::InvalidateCache()
        }
    } catch {
        # Default config file save failed - settings not persisted
    }
}
```

**Impact**: Fixes ALL 12 locations automatically for cache invalidation.

---

### FIX 2: Add -Force to All Theme Initialization Calls
Update these 7 locations:

1. **ThemeEditorScreen.ps1:407**
```powershell
Initialize-PmcThemeSystem -Force
```

2. **Theme.ps1:85** (after Save-PmcConfig in Set-PmcTheme)
```powershell
Save-PmcConfig $cfg
Initialize-PmcThemeSystem -Force  # ADD THIS LINE
```

3. **Theme.ps1:101** (after Save-PmcConfig in Reset-PmcTheme)
```powershell
Save-PmcConfig $cfg
Initialize-PmcThemeSystem -Force  # ADD THIS LINE
```

4. **Theme.ps1:170** (after Save-PmcConfig in Edit-PmcTheme)
```powershell
Save-PmcConfig $cfg
Initialize-PmcThemeSystem -Force  # ADD THIS LINE
```

5. **Theme.ps1:254** (in Apply-PmcTheme)
```powershell
Initialize-PmcThemeSystem -Force
```

6. **PmcThemeManager.ps1:420** (in SetTheme)
```powershell
Initialize-PmcThemeSystem -Force
```

7. **Theme.ps1:270** (in Reload-PmcConfig)
```powershell
Initialize-PmcThemeSystem -Force
```

---

### FIX 3: Consolidate Duplicate Functions
Remove duplicates:
- Keep `Set-PmcIconMode` in `Theme.ps1`, remove from `Config.ps1`
- Keep `Reload-PmcConfig` in `Theme.ps1`, remove from `Config.ps1`

Or at minimum, document which one should be used.

---

## Testing Plan

### Test 1: Theme Changes in TUI
1. Start TUI
2. Change theme in theme editor
3. **Expected**: Theme applies immediately without restart
4. Restart TUI
5. **Expected**: Theme persists

### Test 2: CLI Theme Commands
1. Run `theme set #FF0000`
2. **Expected**: Theme applies immediately
3. Start TUI
4. **Expected**: TUI shows red theme

### Test 3: Icon Mode Changes
1. Run `config icons ascii`
2. **Expected**: Icons change immediately
3. Restart
4. **Expected**: ASCII icons still active

### Test 4: Slider Theme Editor
1. Run `theme adjust`
2. Adjust RGB sliders
3. Press Enter
4. **Expected**: Theme applies immediately

---

## Impact Summary

**Total Locations Affected**: 12
**Critical Severity**: 6 locations (theme changes completely broken)
**Major Severity**: 3 locations (icon/preference changes not effective)
**Moderate Severity**: 2 locations (partial functionality)
**Minor Severity**: 1 location

**Estimated Fix Time**:
- FIX 1 (Save-PmcConfig): 5 minutes - **Fixes 90% of issues**
- FIX 2 (Add -Force flags): 15 minutes - **Fixes remaining 10%**
- FIX 3 (Consolidate): 10 minutes - **Cleanup**
- Testing: 30 minutes

**Total**: ~1 hour to fix completely

---

## Conclusion

This is a **systemic architectural issue** affecting ALL configuration persistence, not just themes. The fix is straightforward:

1. **One-line change to Save-PmcConfig** fixes cache invalidation for ALL locations
2. **Add -Force flag** to 7 locations to ensure state updates
3. **Consolidate duplicate functions** for maintainability

With these fixes, ALL configuration changes will persist correctly and apply immediately.