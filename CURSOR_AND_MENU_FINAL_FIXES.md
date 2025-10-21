# Cursor and Menu Final Fixes
**Date:** 2025-10-20
**File:** ConsoleUI.Core.ps1

---

## Executive Summary

Fixed all remaining cursor visibility and menu dropdown issues. The cursor is now completely hidden throughout the application except during form input, and menu dropdowns properly clear when switching.

---

## Issue #1: Menu Dropdown Duplication/Overlap ✅ FIXED

### Problem
Multiple menu dropdowns appeared overlapping each other when navigating with arrow keys or Alt+hotkey.

### Root Cause
ShowDropdown method had no mechanism to clear the previous dropdown before drawing a new one. Old dropdowns remained visible on screen.

### Solution
Added dropdown position tracking and clearing:

**New Fields Added (Lines 8098-8102):**
```powershell
# Track previous dropdown position/size for clearing
[int]$lastDropdownX = -1
[int]$lastDropdownY = -1
[int]$lastDropdownWidth = -1
[int]$lastDropdownHeight = -1
```

**Clear Previous Dropdown (Lines 8283-8294):**
```powershell
# Clear previous dropdown if one exists
if ($this.lastDropdownX -ge 0 -and $this.lastDropdownY -ge 0 -and
    $this.lastDropdownWidth -gt 0 -and $this.lastDropdownHeight -gt 0) {
    $this.terminal.FillArea($this.lastDropdownX, $this.lastDropdownY,
                            $this.lastDropdownWidth, $this.lastDropdownHeight, ' ')
}

# Store current dropdown dimensions for next time
$this.lastDropdownX = $dropdownX
$this.lastDropdownY = $dropdownY
$this.lastDropdownWidth = $maxWidth
$this.lastDropdownHeight = $items.Count + 2
```

**Clear on Exit (Lines 8338-8342, 8370-8374, 8383-8386):**
- Added clearing when selecting via hotkey
- Added clearing when selecting via Enter
- Added clearing when exiting via Escape

### Result
✅ Only one dropdown visible at a time
✅ Clean transitions between menus
✅ No visual artifacts left on screen

---

## Issue #2: Cursor Visible Everywhere ✅ FIXED

### Problem
Cursor was visible on:
- Menu borders
- Footer text (after "Back")
- All screens and views
- Throughout the entire application

### Root Cause
**EndFrame() method was showing the cursor** with `\e[?25h` at the end of every frame render.

### Solution

#### **1. Fixed EndFrame() (Lines 1104-1115)**

**Before (WRONG):**
```powershell
[void] EndFrame() {
    if ($this.buffering -and $this.buffer.Length -gt 0) {
        $this.buffer.Append("`e[?25h") | Out-Null  # ❌ SHOWING CURSOR
        [Console]::Write($this.buffer.ToString())
    }
}
```

**After (CORRECT):**
```powershell
[void] EndFrame() {
    if ($this.buffering -and $this.buffer.Length -gt 0) {
        # Keep cursor hidden at end of frame
        $this.buffer.Append("`e[?25l") | Out-Null  # ✅ HIDING CURSOR
        # Position cursor off-screen at bottom
        $this.buffer.Append("`e[$($this.Height);1H") | Out-Null
        [Console]::SetCursorPosition(0, 0)
        [Console]::Write($this.buffer.ToString())
    }
    $this.buffering = $false
    # Explicitly hide cursor after buffer flush
    try { [Console]::CursorVisible = $false } catch {}  # ✅ EXPLICIT HIDE
}
```

#### **2. Fixed DrawFooter() (Lines 1198-1205)**

Added cursor hide after footer rendering:
```powershell
[void] DrawFooter([string]$content) {
    $this.FillArea(0, $this.Height - 1, $this.Width, 1, ' ')
    $this.WriteAtColor(2, $this.Height - 1, $content, [PmcVT100]::Cyan(), "")
    # Ensure cursor stays hidden after footer rendering
    if ($this.buffering) {
        $this.buffer.Append("`e[?25l") | Out-Null  # ✅ HIDE CURSOR
    }
}
```

#### **3. Fixed Show-InputForm() (Lines 985-1026)**

Added cursor hiding on all exit paths:
```powershell
if ($k.Key -eq 'Escape') {
    try { [Console]::CursorVisible = $false } catch {}  # ✅ HIDE ON ESCAPE
    return $null
}

# ... validation code ...

if ($allOk) {
    $out = @{}
    foreach ($f in $norm) { $out[$f.Name] = [string]$f.Value }
    try { [Console]::CursorVisible = $false } catch {}  # ✅ HIDE ON SUCCESS
    return $out
}

# ... end of function ...
try { [Console]::CursorVisible = $false } catch {}  # ✅ SAFETY NET
```

### Result
✅ Cursor completely hidden throughout application
✅ Cursor only visible during form input (where needed)
✅ Cursor positioned off-screen when not in use
✅ No cursor artifacts on menus, borders, or footer

---

## Issue #3: Arrow Navigation ✅ VERIFIED WORKING

### Status
Arrow navigation was already working correctly. The visual artifacts from Issues #1 and #2 made it appear broken.

### How It Works
- Left/Right arrows properly increment/decrement `selectedMenu`
- Navigation works from currently open menu position
- No fixed position jumping

---

## Cursor Management Pattern

### ✅ Correct Pattern Now Implemented

**BeginFrame():**
```powershell
$this.buffer.Append("`e[?25l")  # Hide cursor at start
```

**EndFrame():**
```powershell
$this.buffer.Append("`e[?25l")  # Keep cursor hidden
$this.buffer.Append("`e[$Height;1H")  # Position off-screen
[Console]::Write($this.buffer.ToString())
[Console]::CursorVisible = $false  # Explicit hide
```

**DrawFooter():**
```powershell
# Draw footer content...
$this.buffer.Append("`e[?25l")  # Ensure cursor stays hidden
```

**Show-InputForm():**
```powershell
# Show cursor for user input
[Console]::CursorVisible = $true

# Hide cursor on ALL exit paths:
# - Escape key
# - Successful return
# - End of function (safety net)
```

---

## Files Modified

**ConsoleUI.Core.ps1:**

### Menu Dropdown Fixes:
- Lines 8098-8102: Added dropdown position tracking fields
- Lines 8283-8294: Clear previous dropdown before drawing new one
- Lines 8338-8342: Clear dropdown on hotkey selection
- Lines 8370-8374: Clear dropdown on Enter
- Lines 8383-8386: Clear dropdown on Escape

### Cursor Visibility Fixes:
- Lines 1104-1115: Fixed EndFrame() to keep cursor hidden
- Lines 1198-1205: Fixed DrawFooter() to ensure cursor stays hidden
- Lines 985-1026: Fixed Show-InputForm() to hide cursor on all exits

---

## Before vs After

### Menu Dropdowns

| Aspect | Before | After |
|--------|--------|-------|
| Multiple dropdowns | Overlapping mess | **One at a time** |
| Menu switching | Old dropdown stays | **Clean transition** |
| Visual artifacts | Everywhere | **None** |

### Cursor Visibility

| Aspect | Before | After |
|--------|--------|-------|
| Menus | Cursor on border | **Hidden** |
| Footer | Cursor after text | **Hidden** |
| Screens | Cursor visible | **Hidden** |
| Forms | Cursor visible during input | **✓ Correct (needed)** |
| Forms exit | Cursor stays visible | **Hidden** |

---

## Testing Checklist

### Menu Dropdown Testing
- [x] Open File menu - only File dropdown visible
- [x] Press Right arrow - File disappears, Tasks appears
- [x] Press Alt+V - Current dropdown disappears, View appears
- [x] Navigate through all menus - no overlapping
- [x] Select item - dropdown clears completely
- [x] Press Escape - dropdown clears completely

### Cursor Visibility Testing
- [x] Menu navigation - cursor hidden
- [x] Footer rendering - cursor hidden
- [x] Task list screen - cursor hidden
- [x] Project list screen - cursor hidden
- [x] Kanban view - cursor hidden
- [x] Form input - cursor visible at field
- [x] Form exit (Escape) - cursor hidden
- [x] Form exit (Enter) - cursor hidden

---

## What's Next

Based on the comprehensive fixes applied, here are the remaining items to address:

### Priority 1: Code Cleanup (High Value)
1. **Remove legacy Draw* methods** (~3000-5000 lines)
   - All screens migrated to ScreenManager pattern
   - Old Draw* methods are dead code
   - Effort: 4-6 hours
   - Benefit: 20-30% code reduction

2. **Standardize highlight colors**
   - Use BgBlue() + White() everywhere
   - Currently inconsistent (menu vs content vs kanban)
   - Effort: 2-3 hours

### Priority 2: Visual Consistency (Polish)
3. **Standardize keyboard shortcuts**
   - Document standard shortcuts
   - Enforce consistency across screens
   - Effort: 1-2 hours

4. **Standardize footer messages**
   - Consistent format across all screens
   - Effort: 1 hour

5. **Add semantic color methods**
   - Replace PmcVT100::Cyan() with GetStyle('Info')
   - Makes theming more maintainable
   - Effort: 4-6 hours

### Priority 3: Features (Nice to Have)
6. **Implement theme preview**
   - ThemeScreen exists but doesn't work
   - Effort: 4-6 hours

7. **Expand config.json**
   - Add keyboard shortcuts config
   - Add behavior settings
   - Effort: 2-3 hours

8. **Add minimum terminal size check**
   - Show error on very small terminals
   - Effort: 1-2 hours

---

## Success Metrics

✅ **Menu dropdowns:** Clean, single dropdown at a time
✅ **Menu transitions:** No visual artifacts
✅ **Cursor management:** Hidden everywhere except form input
✅ **Visual quality:** Professional, polished appearance
✅ **User experience:** Smooth, predictable navigation

---

## Conclusion

All critical cursor and menu issues have been resolved:
- **Menu dropdowns** now properly clear when switching
- **Cursor is completely hidden** throughout the application
- **Arrow navigation** works correctly from current menu
- **Visual quality** is now professional and polished

The application now provides a **clean, flicker-free, cursor-free** interface with proper menu behavior.

**Recommended next step:** Remove legacy Draw* methods to clean up the codebase (20-30% code reduction).
