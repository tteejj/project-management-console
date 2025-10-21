# ConsoleUI Review & Improvement Recommendations

**Date:** 2025-10-17
**Reviewed:** ConsoleUI system in `/home/teej/pmc/`
**Reference:** Praxis TUI framework at `~/_tui/praxis-main/`

## Executive Summary

Your ConsoleUI is a functional TUI with good bones, but it suffers from several architectural and rendering issues that cause flicker, improper redraws, menu sizing problems, and general instability. By adopting patterns from the Praxis framework (which is a well-architected, production-quality TUI), you can significantly improve performance, eliminate flicker, and create a much more polished experience.

---

## 🔴 Critical Issues Found

### 1. **Double BeginFrame() Calls - CRITICAL BUG**

**Location:** `ConsoleUI.Core.ps1:1287-1288` and `1338-1339`

```powershell
[void] DrawLayout() {
    $this.terminal.BeginFrame()
    $this.terminal.BeginFrame()  # ❌ DUPLICATE CALL
    # ...
    $this.terminal.EndFrame()
    $this.terminal.EndFrame()     # ❌ DUPLICATE CALL
}
```

**Impact:** This completely breaks your buffering system and causes massive flicker. Each `BeginFrame()` clears the buffer, so the second call wipes out the first one's work.

**Fix:** Remove all duplicate calls throughout the codebase.

---

### 2. **No Proper Screen Manager / Render Loop**

**Current State:** Each view calls `DrawXXX()` repeatedly in tight loops without coordination.

**Problems:**
- Multiple redraws per keystroke
- No centralized invalidation tracking
- Each screen implements its own event loop
- Inconsistent redraw behavior

**Praxis Solution:** `Core/ScreenManager.ps1` demonstrates the proper pattern:
- Single `Run()` loop with centralized input handling
- Render-on-demand with `_needsRender` flag
- Screen stack management (Push/Pop/Replace)
- Consistent lifecycle (Initialize → Activate → Render → HandleInput → Deactivate)

---

### 3. **Inconsistent Buffering Strategy**

**Current Issues:**
- `BeginFrame()/EndFrame()` exists but is used inconsistently
- Some methods call `terminal.Clear()` directly (bypassing buffer)
- Menu dropdown renders directly without buffering (`ShowDropdown()` at line 877)
- No dirty region tracking

**Praxis Approach:**
- **Always** use buffering: `BeginFrame() → write to buffer → EndFrame()`
- StringBuilder pooling for memory efficiency (`StringBuilderPool` class)
- VT100 cursor hiding inside the buffer itself (not separate console calls)
- Cached ANSI sequences (`StringCache` for spaces, colors, box drawing)

---

### 4. **Menu System Rendering Problems**

**Issues:**
- Dropdown menu (`ShowDropdown()`) doesn't properly clear/restore background
- Fixed dropdown position (`$dropdownX = 2`) doesn't align with menu bar items
- No calculation of actual menu bar positions
- Dropdown width hardcoded to 20 characters
- Menu items can overflow window bounds

**Praxis Pattern:** `Screens/UnifiedMainScreen.ps1` shows clean menu rendering:
- Menus are components with proper bounds
- Background restoration through full-frame redraws
- Dynamic positioning based on actual menu locations
- Proper focus management

---

### 5. **No Clipping or Bounds Checking**

**Problem:** Text can render outside dialog/window bounds, causing visual corruption.

**Current Code:**
```powershell
[void] WriteAt([int]$x, [int]$y, [string]$text) {
    if ([string]::IsNullOrEmpty($text) -or $x -lt 0 -or $y -lt 0
        -or $x -ge $this.Width -or $y -ge $this.Height) { return }
    # Basic check but no text truncation for width
}
```

**Praxis Solution:** `Core/RenderHelper.ps1` provides:
- Safe padding calculation (prevents negative padding crashes)
- Automatic text truncation with ellipsis
- Clip bounds tracking
- Proper boundary validation

---

### 6. **Color/Theme Management is Ad-Hoc**

**Current Issues:**
- Direct VT100 color calls throughout code (`[PmcVT100]::Cyan()`)
- No consistent focus indicators
- Theme changes require code modifications
- Inconsistent highlighting (some places use background, some don't)

**Praxis Approach:**
- Centralized `ThemeManager` with semantic color keys
- Theme files define all colors (see `Themes/ThemeSynthwave.ps1`)
- Components request colors by semantic name: `$theme.GetColor('text.primary')`
- Consistent focus rendering via `CleanRender.ps1` helper

---

## 🟡 Major Issues

### 7. **String Cache Not Used Effectively**

You have a `PmcStringCache` class (line 105) but:
- Only caches up to 200 characters of spaces
- Not used consistently (many `" " * $count` calls remain)
- Box drawing characters cached but rarely used

**Recommendation:** Use `StringCache::GetSpaces()` everywhere instead of string multiplication.

---

### 8. **Redundant Clear() Calls**

**Pattern found:**
```powershell
[void] DrawTaskList() {
    $this.terminal.BeginFrame()
    $this.terminal.Clear()  # ❌ Unnecessary - BeginFrame should handle this
    # ...
}
```

**Impact:** Extra clearing causes flicker and wastes cycles.

**Praxis Pattern:** Clear is only called:
1. On initial screen load
2. When switching screens (in ScreenManager)
3. Never inside a buffered frame

---

### 9. **No Component Lifecycle Management**

**Current:** Each view is a big procedural function with manual state management.

**Problems:**
- State scattered across class properties
- No cleanup on view change
- Event handlers not unregistered
- Memory leaks from abandoned objects

**Praxis Model:**
- Base `Screen` class with lifecycle: `Initialize() → OnActivated() → OnDeactivated()`
- Base `UIElement` class with proper initialization
- Component registration and cleanup
- Proper focus chain management

---

### 10. **Dialog/Modal Issues**

**Problems:**
- Dialogs like `Show-SelectList()` don't save/restore background
- Positioned absolutely (not centered dynamically)
- No backdrop/overlay to indicate modal state
- Can't handle terminal resize during dialog display

**Praxis Solution:** `Base/CleanDialog.ps1` shows proper pattern:
- Background fill before rendering
- Dynamic centering based on terminal size
- Single-line borders using proper Unicode characters
- Clean restoration through full redraw

---

## 🟢 Strengths (Keep These!)

1. **Good separation** between `PmcSimpleTerminal` and application logic
2. **Menu system structure** is sound (just needs better rendering)
3. **StringBuilderPool** concept is excellent (just needs more usage)
4. **VT100 abstraction** via `PmcVT100` class is good design
5. **Multi-select functionality** in task list is well-implemented

---

## 📋 Recommended Improvements (Prioritized)

### Priority 1: Fix Critical Rendering Bugs

**Action Items:**

1. **Remove all duplicate BeginFrame/EndFrame calls**
   - Search: `BeginFrame.*BeginFrame`
   - Fix: Remove duplicates in `DrawLayout()`, `DrawTaskList()`, etc.

2. **Implement consistent buffering**
   ```powershell
   [void] DrawAnything() {
       $this.terminal.BeginFrame()
       # ALL drawing here
       $this.terminal.EndFrame()
   }
   ```

3. **Fix menu dropdown rendering**
   - Calculate dropdown X position based on menu item location
   - Use `BeginFrame()/EndFrame()` for dropdown
   - Make width dynamic based on longest item

4. **Add proper bounds checking to all text rendering**
   ```powershell
   # Truncate text that exceeds width
   if ($text.Length -gt $maxLength) {
       $text = $text.Substring(0, $maxLength - 1) + '…'
   }
   ```

---

### Priority 2: Adopt ScreenManager Pattern

**Changes Needed:**

1. **Create a proper ScreenManager** (model after Praxis `Core/ScreenManager.ps1`)
   - Single `Run()` loop
   - Render only when `_needsRender` flag is set
   - Handle input centrally
   - Manage screen stack for view navigation

2. **Refactor views to inherit from base Screen class**
   ```powershell
   class TaskListScreen : PmcScreen {
       [void] OnActivated() {
           $this.LoadTasks()
       }

       [string] Render() {
           $sb = [StringBuilder]::new()
           # Build entire screen output
           return $sb.ToString()
       }

       [bool] HandleInput([ConsoleKeyInfo]$key) {
           # Process input, return true if handled
       }
   }
   ```

3. **Eliminate tight loops in favor of event-driven model**
   - No more `while ($active) { Draw; ReadKey }` patterns
   - ScreenManager calls `Render()` when needed
   - Input handlers set `_needsRender = $true` to trigger redraw

---

### Priority 3: Improve UI Rendering Quality

**Adopt from Praxis:**

1. **Use CleanRender helper** (see `Core/CleanRender.ps1`)
   ```powershell
   # Clean dialog with proper borders
   $dialog = [CleanRender]::Dialog($x, $y, $w, $h, "Title", $theme)

   # Clean list item with focus state
   $item = [CleanRender]::ListItem($x, $y, $width, $text, $selected, $focused, $theme)
   ```

2. **Implement RenderHelper utilities**
   - Safe padding calculation
   - Themed text rendering
   - Focus state management
   - Consistent border drawing

3. **Use single-line borders** (from `CleanRender`)
   ```powershell
   static [hashtable]$BoxChars = @{
       TL = '╭'  # Top left
       TR = '╮'  # Top right
       BL = '╰'  # Bottom left
       BR = '╯'  # Bottom right
       H = '─'   # Horizontal
       V = '│'   # Vertical
   }
   ```

---

### Priority 4: Centralize Theme Management

**Implementation:**

1. **Create ThemeManager class** (reference: `Services/ThemeManager.ps1`)
   ```powershell
   class PmcThemeManager {
       [hashtable]$_currentTheme

       [string] GetColor([string]$key) {
           # Return VT100 sequence for color
       }

       [string] GetBgColor([string]$key) {
           # Return VT100 sequence for background
       }

       [void] LoadTheme([string]$name) {
           # Load theme from file
       }
   }
   ```

2. **Define semantic color keys**
   ```powershell
   @{
       'text.primary' = '#E0E0E0'
       'text.secondary' = '#808080'
       'border.normal' = '#404040'
       'border.focused' = '#00FFFF'
       'state.selected' = '#2A2A2A'
       'state.focused' = '#1A4A5A'
   }
   ```

3. **Replace all hardcoded colors**
   ```powershell
   # Before
   $this.terminal.WriteAtColor($x, $y, $text, [PmcVT100]::Cyan(), "")

   # After
   $fg = $this.theme.GetColor('text.primary')
   $this.terminal.WriteAtColor($x, $y, $text, $fg, "")
   ```

---

### Priority 5: Implement Proper Component Architecture

**Model After Praxis Components:**

1. **Base UIElement class**
   ```powershell
   class PmcUIElement {
       [int]$X
       [int]$Y
       [int]$Width
       [int]$Height
       [bool]$IsFocused
       [bool]$IsVisible

       [void] SetBounds([int]$x, [int]$y, [int]$w, [int]$h) {}
       [string] Render() { return "" }
       [bool] HandleInput([ConsoleKeyInfo]$key) { return $false }
   }
   ```

2. **Specific components inherit from base**
   - `PmcListBox : PmcUIElement`
   - `PmcTextBox : PmcUIElement`
   - `PmcButton : PmcUIElement`

3. **Containers manage child components**
   ```powershell
   class PmcContainer : PmcUIElement {
       [List[PmcUIElement]]$Children

       [string] Render() {
           $sb = [StringBuilder]::new()
           foreach ($child in $this.Children) {
               $sb.Append($child.Render())
           }
           return $sb.ToString()
       }
   }
   ```

---

## 🎯 Quick Wins (Implement These First)

### 1. Fix Double BeginFrame() Bug (5 minutes)
Search and remove duplicate calls in `DrawLayout()` and similar methods.

### 2. Add Text Truncation Helper (10 minutes)
```powershell
function Truncate-ConsoleUIText {
    param([string]$text, [int]$maxWidth)
    if ($text.Length -gt $maxWidth) {
        return $text.Substring(0, $maxWidth - 1) + '…'
    }
    return $text.PadRight($maxWidth)
}
```

### 3. Fix Menu Dropdown Positioning (15 minutes)
Calculate X position based on menu bar item locations instead of hardcoding to 2.

### 4. Eliminate Redundant Clear() Calls (10 minutes)
Remove all `terminal.Clear()` calls inside `BeginFrame()/EndFrame()` blocks.

### 5. Add Consistent Footer Rendering (10 minutes)
```powershell
[void] DrawFooter([string]$text) {
    $this.terminal.BeginFrame()
    $y = $this.terminal.Height - 1
    $this.terminal.FillArea(0, $y, $this.terminal.Width, 1, ' ')
    $this.terminal.WriteAtColor(2, $y, $text, [PmcVT100]::Cyan(), "")
    $this.terminal.EndFrame()
}
```

---

## 📊 Architecture Comparison

| Aspect | Current ConsoleUI | Praxis Framework |
|--------|------------------|------------------|
| **Render Loop** | Scattered per-view loops | Centralized ScreenManager |
| **Buffering** | Inconsistent | Always buffered |
| **Screen Management** | View string + switch | Screen stack (Push/Pop) |
| **Component Model** | Procedural functions | Class-based inheritance |
| **Theme System** | Hardcoded colors | ThemeManager + semantic keys |
| **Input Handling** | Per-view custom code | Unified input chain |
| **Focus Management** | Manual tracking | FocusManager service |
| **Lifecycle** | None | Init → Activate → Deactivate |
| **Dirty Tracking** | Redraw everything | Invalidation flags |
| **Memory Management** | Ad-hoc | Object pooling (StringBuilder) |

---

## 🛠️ Implementation Roadmap

### Phase 1: Stabilization (Week 1)
- [ ] Fix double BeginFrame() bug
- [ ] Remove redundant Clear() calls
- [ ] Add text truncation everywhere
- [ ] Fix menu dropdown positioning
- [ ] Consistent buffering in all draw methods

### Phase 2: Architecture (Week 2-3)
- [ ] Create ScreenManager class
- [ ] Implement base Screen class
- [ ] Refactor TaskList to use Screen base
- [ ] Refactor ProjectList to use Screen base
- [ ] Implement proper view lifecycle

### Phase 3: Component System (Week 4)
- [ ] Create base UIElement class
- [ ] Implement PmcListBox component
- [ ] Implement PmcTextBox component
- [ ] Implement PmcButton component
- [ ] Create Container class

### Phase 4: Polish (Week 5)
- [ ] Implement ThemeManager
- [ ] Create RenderHelper utilities
- [ ] Adopt CleanRender for borders/dialogs
- [ ] Add focus indicators throughout
- [ ] Performance optimization pass

---

## 📝 Specific Code Examples

### Example: Proper Task List Rendering

**Before (Current - has issues):**
```powershell
[void] DrawTaskList() {
    $this.terminal.BeginFrame()
    $this.terminal.BeginFrame()  # ❌ BUG
    $this.terminal.Clear()        # ❌ Redundant
    # ... drawing code ...
    $this.terminal.EndFrame()
    $this.terminal.EndFrame()     # ❌ BUG
}

[void] HandleTaskListView() {
    while ($active) {
        $this.DrawTaskList()     # ❌ Draws on every loop iteration
        $key = [Console]::ReadKey($true)
        # ... handle key ...
    }
}
```

**After (Praxis Pattern - clean):**
```powershell
class TaskListScreen : PmcScreen {
    [array]$tasks = @()
    [int]$selectedIndex = 0
    [bool]$needsRedraw = $true

    [void] OnActivated() {
        $this.LoadTasks()
        $this.needsRedraw = $true
    }

    [string] Render() {
        if (-not $this.needsRedraw) { return "" }

        $sb = [PmcStringBuilderPool]::Get(8192)

        # Draw title
        $sb.Append([CleanRender]::Dialog($this.X, $this.Y, $this.Width, $this.Height, "Task List", $this.theme))

        # Draw task items
        $y = $this.Y + 2
        foreach ($i = 0; $i -lt $this.tasks.Count; $i++) {
            $task = $this.tasks[$i]
            $selected = ($i -eq $this.selectedIndex)
            $sb.Append([CleanRender]::ListItem($this.X + 2, $y, $this.Width - 4, $task.text, $selected, $this.IsFocused, $this.theme))
            $y++
        }

        $result = $sb.ToString()
        [PmcStringBuilderPool]::Return($sb)
        $this.needsRedraw = $false
        return $result
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedIndex -gt 0) {
                    $this.selectedIndex--
                    $this.needsRedraw = $true
                    return $true
                }
            }
            'DownArrow' {
                if ($this.selectedIndex -lt $this.tasks.Count - 1) {
                    $this.selectedIndex++
                    $this.needsRedraw = $true
                    return $true
                }
            }
            'Enter' {
                $this.OpenTaskDetail($this.tasks[$this.selectedIndex])
                return $true
            }
        }
        return $false
    }
}
```

---

## 🎓 Key Lessons from Praxis

### 1. **Separation of Concerns**
- **Rendering:** Screen.Render() returns string
- **Logic:** Screen.HandleInput() processes keys
- **State:** Screen properties track data
- **Display:** ScreenManager writes output

### 2. **Render Once Per Frame**
```powershell
# ScreenManager Run() loop
while ($this._activeScreen.Active) {
    if ($this._needsRender) {
        $content = $this._activeScreen.Render()
        [Console]::SetCursorPosition(0, 0)
        [Console]::Write($content)
        $this._needsRender = $false
    }

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        $handled = $this._activeScreen.HandleInput($key)
        if ($handled) {
            $this._needsRender = $true
        }
    }
}
```

### 3. **Always Use StringBuilder Pooling**
```powershell
$sb = [PmcStringBuilderPool]::Get(initialCapacity)
# ... build string ...
$result = $sb.ToString()
[PmcStringBuilderPool]::Return($sb)  # ✅ Reuse object
return $result
```

### 4. **VT100 Sequences in Buffer**
```powershell
[void] BeginFrame() {
    $this.buffer.Clear()
    $this.buffer.Append("`e[?25l")  # Hide cursor IN buffer
}

[void] EndFrame() {
    $this.buffer.Append("`e[?25h")  # Show cursor IN buffer
    [Console]::Write($this.buffer.ToString())  # Single write
}
```

### 5. **Theme Semantic Keys Over Raw Colors**
```powershell
# ❌ Bad
$color = "`e[38;2;0;255;255m"

# ✅ Good
$color = $theme.GetColor('text.primary')
```

---

## 🎨 Visual Quality Improvements

### Current Issues:
1. **Thick double borders** look dated (┌─┐ vs ╭─╮)
2. **Inconsistent spacing** between elements
3. **Background color bleed** on unselected items
4. **No visual focus indicators** (which element is active?)
5. **Overlapping borders** when dialogs appear

### Praxis Solutions:
1. **Single-line rounded borders** (╭─╮ ╰─╯) via CleanRender
2. **Consistent 2-space padding** via SpacingSystem
3. **NO background on normal items**, only on selected
4. **Reverse video highlight** for focused elements
5. **Full screen redraw** on dialog show/hide

---

## 🔍 Testing Recommendations

### 1. Terminal Resize Handling
- **Test:** Resize terminal while app is running
- **Expected:** Clean redraw, no corruption
- **Current:** Likely breaks layout

### 2. Rapid Input
- **Test:** Hold down arrow key
- **Expected:** Smooth scrolling, no flicker
- **Current:** Likely flickers heavily

### 3. Dialog Over Content
- **Test:** Open dialog, close dialog
- **Expected:** Clean restore of background
- **Current:** Likely leaves artifacts

### 4. Menu Navigation
- **Test:** Alt+key to open menu, arrow through items
- **Expected:** Menu stays properly aligned
- **Current:** Dropdown may misalign

---

## 📚 Files to Study from Praxis

1. **Core/ScreenManager.ps1** (lines 1-467)
   - Centralized render loop
   - Screen stack management
   - Input processing chain

2. **Core/CleanRender.ps1** (lines 1-170)
   - Clean border rendering
   - Focus-aware styling
   - Proper list items

3. **Base/Screen.ps1**
   - Base class for all screens
   - Lifecycle methods
   - Render contract

4. **Services/ThemeManager.ps1**
   - Theme loading and management
   - Color key resolution
   - Theme switching

5. **Core/StringCache.ps1** and **Core/StringBuilderPool.ps1**
   - Performance optimizations
   - Object reuse patterns

---

## ✅ Summary

Your ConsoleUI has good structure but suffers from:
1. Critical rendering bugs (double BeginFrame)
2. Lack of centralized screen management
3. Inconsistent buffering strategy
4. No component architecture
5. Theme management chaos

By adopting patterns from Praxis:
- ✅ Eliminate flicker through proper buffering
- ✅ Fix menu sizing via proper bounds calculation
- ✅ Enable smooth redraws through invalidation flags
- ✅ Create maintainable code via component architecture
- ✅ Support theming via semantic color keys

**Start with Quick Wins, then tackle architecture in phases.**

Good luck! The foundation is there—just needs polish and proper rendering discipline. 🚀
