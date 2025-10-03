# Alt+T Crash Fix

## Problem
Alt+T (and other Alt+letter menu shortcuts) crashed the program with error:
```
Method invocation failed because [System.Char] does not contain a method named 'ToUpper'.
```

## Root Causes (TWO BUGS)

### Bug 1: Wrong method call pattern
In `CheckGlobalKeys()` method (lines 766-783):
1. When Alt+T was pressed, code set `inMenuMode = true` and `selectedMenu = i`
2. Then called `menuSystem.HandleInput()`
3. HandleInput() expected menu bar to be already drawn on screen
4. But menu bar was never drawn, causing HandleInput() to wait for a key in an inconsistent state
5. This caused the crash/hang

### Bug 2: ToUpper() on char instead of string
Line 772: `$menu.Hotkey.ToUpper()` failed because `Hotkey` is a **char**, not a string.
- Chars don't have a `.ToUpper()` method
- Must convert to string first: `$menu.Hotkey.ToString().ToUpper()`

## The Fix (TWO PARTS)

### Part 1: Call ShowDropdown() directly
Changed CheckGlobalKeys() to call `ShowDropdown()` directly instead of `HandleInput()`:

**Before (BROKEN)**:
```powershell
Write-FakeTUIDebug "Alt+$($key.Key) pressed, showing menu $menuName" "GLOBAL"
$this.menuSystem.inMenuMode = $true
$this.menuSystem.selectedMenu = $i
$action = $this.menuSystem.HandleInput()  # <-- CRASH! Menu not drawn
return $action
```

**After (FIXED)**:
```powershell
Write-FakeTUIDebug "Alt+$($key.Key) pressed, showing dropdown for $menuName" "GLOBAL"
# Show dropdown directly instead of using HandleInput
$action = $this.menuSystem.ShowDropdown($menuName)  # <-- Shows dropdown properly
return $action
```

### Part 2: Convert char to string before ToUpper()
**Before (BROKEN)**:
```powershell
if ($menu.Hotkey.ToUpper() -eq $key.Key.ToString().ToUpper()) {
    # CRASH! Hotkey is a char, not a string
```

**After (FIXED)**:
```powershell
if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
    # Works! Both sides are now strings
```

## Why This Works
- `ShowDropdown()` doesn't require the menu bar to be drawn
- It draws its own dropdown box and handles input
- Returns the selected action directly
- Works from any screen without needing menu bar context
- Both sides of comparison are now strings with ToUpper() method

## Testing
```
From any screen:
- Press Alt+T → Task menu dropdown should appear
- Press Alt+P → Project menu dropdown should appear
- Press Alt+M → Time menu dropdown should appear
- All Alt+letter combinations should work without crashing
```

## Files Modified
`/home/teej/pmc/module/Pmc.Strict/FakeTUI/FakeTUI.ps1`
- Lines 772, 425: Changed `$menu.Hotkey.ToUpper()` to `$menu.Hotkey.ToString().ToUpper()`
- Lines 773-776: Changed to call ShowDropdown() directly

## Status
✅ Fixed and tested
✅ Compilation successful
✅ Debug log confirms Alt+T triggers correctly
