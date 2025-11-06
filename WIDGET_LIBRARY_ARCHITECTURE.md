# PMC Widget Library Architecture
**Complete UI Component System Design**
**Version:** 1.0
**Date:** 2025-11-05

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Widget Inventory](#widget-inventory)
3. [Layout System](#layout-system)
4. [Theming Architecture](#theming-architecture)
5. [Component Specifications](#component-specifications)
6. [Implementation Strategy](#implementation-strategy)

---

## Executive Summary

### What We're Building

A **complete widget library** for PMC that provides:
- ✅ **Reusable UI components** (menus, headers, footers, panels, dialogs)
- ✅ **Layout system** (positioning, sizing, constraints)
- ✅ **Border/frame management** (box drawing with full character set)
- ✅ **Theming integration** (centralized styling, runtime switching)
- ✅ **Screen templates** (standardized layouts for consistency)

### Current State

**What PMC Already Has:**
- Sophisticated theme system (single hex → full palette)
- Menu system (needs extraction)
- Dialog functions (needs widget-ification)
- Box drawing (limited character set)
- Performance optimizations (caching, pooling)

**What SpeedTUI Provides:**
- Button, Label, List, Table, Input widgets
- GridLayout and StackLayout
- Theme manager (4 built-in themes)
- Focus/event management
- Render caching

### Our Strategy

1. **Use SpeedTUI widgets** where possible (Button, List, Table, Input)
2. **Build PMC-specific widgets** for missing pieces (MenuBar, StatusBar, Panel)
3. **Create layout templates** for consistent screens
4. **Integrate PMC's theme system** with SpeedTUI
5. **Centralize all UI code** in widget library

---

## Widget Inventory

### Component Hierarchy

```
PmcWidget (base class)
│
├─── Layout Widgets (containers)
│    ├─── PmcPanel
│    ├─── PmcSplitView
│    ├─── PmcTabView
│    └─── PmcDialog
│
├─── Navigation Widgets
│    ├─── PmcMenuBar
│    ├─── PmcMenuItem
│    ├─── PmcBreadcrumb
│    └─── PmcHeader
│
├─── Status Widgets
│    ├─── PmcStatusBar
│    ├─── PmcFooter
│    └─── PmcProgressBar
│
├─── Data Widgets (from SpeedTUI)
│    ├─── Button
│    ├─── Label
│    ├─── List
│    ├─── Table
│    ├─── InputField
│    └─── FormManager
│
└─── Utility Widgets
     ├─── PmcSeparator
     ├─── PmcSpinner
     └─── PmcTooltip
```

### Priority Matrix

| Widget | Priority | Source | Status |
|--------|----------|--------|--------|
| **PmcMenuBar** | 🔴 CRITICAL | Build new | Design phase |
| **PmcHeader** | 🔴 CRITICAL | Build new | Design phase |
| **PmcFooter** | 🔴 CRITICAL | Build new | Design phase |
| **PmcStatusBar** | 🔴 CRITICAL | Build new | Design phase |
| **PmcPanel** | 🟡 HIGH | Build new | Design phase |
| **PmcDialog** | 🟡 HIGH | Extract from PMC | Exists (needs refactor) |
| **PmcSeparator** | 🟡 HIGH | Build new | Simple |
| **PmcProgressBar** | 🟢 MEDIUM | Build new | Design phase |
| **PmcSpinner** | 🟢 MEDIUM | Build new | Simple |
| **PmcSplitView** | 🟢 MEDIUM | Build new | Design phase |
| **PmcTabView** | 🔵 LOW | Build new | Future |
| **PmcBreadcrumb** | 🔵 LOW | Build new | Future |
| **PmcTooltip** | 🔵 LOW | Build new | Future |

---

## Layout System

### The Problem with Current Approach

**Current PMC code:**
```powershell
# Magic numbers everywhere
$this.terminal.DrawBox(4, 6, $this.terminal.Width - 8, $this.terminal.Height - 12)
$titleX = ($this.terminal.Width - $title.Length) / 2
$this.terminal.WriteAt($titleX, 8, $title)
```

**Problems:**
- ❌ Hardcoded positions (X=4, Y=6)
- ❌ Arbitrary math (Width-8, Height-12)
- ❌ No resize handling
- ❌ No spacing consistency
- ❌ Copy-paste positioning

### Proposed Layout System

#### **1. Named Regions**

```powershell
class PmcLayoutManager {
    [hashtable]$Regions = @{
        'MenuBar' = @{ X=0; Y=0; Width='100%'; Height=1 }
        'MenuSeparator' = @{ X=0; Y=1; Width='100%'; Height=1 }
        'Header' = @{ X='2%'; Y=3; Width='96%'; Height=3 }
        'Content' = @{ X='2%'; Y=7; Width='96%'; Height='FILL' }
        'Footer' = @{ X='2%'; Y='BOTTOM-2'; Width='96%'; Height=1 }
        'StatusBar' = @{ X=0; Y='BOTTOM'; Width='100%'; Height=1 }
    }

    [PmcRect] GetRegion([string]$name, [int]$termWidth, [int]$termHeight) {
        $def = $this.Regions[$name]
        return $this._CalculateRect($def, $termWidth, $termHeight)
    }
}
```

**Usage:**
```powershell
# Instead of magic numbers:
$layout = [PmcLayoutManager]::GetInstance()
$contentRect = $layout.GetRegion('Content', $terminal.Width, $terminal.Height)
$myWidget.SetBounds($contentRect)
```

#### **2. Constraint-Based Positioning**

```powershell
class PmcConstraints {
    [string]$Top      # "0", "50%", "BOTTOM-10"
    [string]$Left     # "0", "25%", "CENTER"
    [string]$Width    # "100", "50%", "FILL"
    [string]$Height   # "5", "30%", "FILL"

    # Anchoring
    [string]$AnchorX  # "left", "center", "right"
    [string]$AnchorY  # "top", "middle", "bottom"

    # Margins
    [int]$MarginTop = 0
    [int]$MarginRight = 0
    [int]$MarginBottom = 0
    [int]$MarginLeft = 0
}

# Example usage:
$panel = [PmcPanel]::new()
$panel.Constraints = @{
    Top = "10%"
    Left = "CENTER"
    Width = "80%"
    Height = "FILL"
    AnchorX = "center"
    MarginTop = 2
}
```

#### **3. Standard Margins**

```powershell
class PmcStandardLayout {
    static [int]$MarginOuter = 2      # Screen edge margin
    static [int]$MarginInner = 1      # Between widgets
    static [int]$PaddingSmall = 1     # Inside widget padding
    static [int]$PaddingMedium = 2
    static [int]$PaddingLarge = 3

    static [int]$HeaderHeight = 3
    static [int]$FooterHeight = 1
    static [int]$StatusBarHeight = 1
    static [int]$MenuBarHeight = 1
}
```

#### **4. Resize Handling**

```powershell
class PmcWidget {
    [void] OnTerminalResize([int]$newWidth, [int]$newHeight) {
        # Recalculate position based on constraints
        $this._ApplyConstraints($newWidth, $newHeight)

        # Notify children
        foreach ($child in $this.Children) {
            $child.OnTerminalResize($newWidth, $newHeight)
        }

        # Invalidate render
        $this.Invalidate()
    }
}
```

---

## Theming Architecture

### Integration Strategy: PMC Theme System + SpeedTUI

#### **Problem:**
- PMC has sophisticated theme system (single hex → palette derivation)
- SpeedTUI has its own theme system (predefined themes)
- Need unified approach

#### **Solution: Hybrid System**

```powershell
class PmcThemeManager {
    # PMC's theme engine (keep as-is)
    [hashtable]$PmcTheme           # From Get-PmcColorPalette()
    [hashtable]$StyleTokens        # From Initialize-PmcThemeSystem()

    # SpeedTUI's theme manager
    [ThemeManager]$SpeedTUITheme   # From SpeedTUI

    # Unified API
    [void] SetTheme([string]$themeName) {
        # Set both systems
        $this._SetPmcTheme($themeName)
        $this._SetSpeedTUITheme($themeName)

        # Sync color mappings
        $this._SyncThemes()
    }

    [string] GetColor([string]$role) {
        # Unified color retrieval
        # Prefer PMC theme, fallback to SpeedTUI
        if ($this.StyleTokens.ContainsKey($role)) {
            return $this.StyleTokens[$role].Fg
        }
        return $this.SpeedTUITheme.GetColor($role)
    }

    hidden [void] _SyncThemes() {
        # Map PMC colors to SpeedTUI roles
        $this.SpeedTUITheme.SetCustomColor('primary', $this.PmcTheme.Primary)
        $this.SpeedTUITheme.SetCustomColor('text', $this.PmcTheme.Text)
        $this.SpeedTUITheme.SetCustomColor('success', $this.PmcTheme.Success)
        $this.SpeedTUITheme.SetCustomColor('warning', $this.PmcTheme.Warning)
        $this.SpeedTUITheme.SetCustomColor('error', $this.PmcTheme.Error)
        # ... etc
    }
}
```

### Color Role Mapping

| PMC Style Token | SpeedTUI Role | Widget Usage |
|----------------|---------------|--------------|
| `Title` | `primary` | Headers, emphasized text |
| `Header` | `primary` | Section headers |
| `Body` | `text` | Normal text content |
| `Muted` | `textDim` | Hints, secondary text |
| `Success` | `success` | Success messages, checkmarks |
| `Warning` | `warning` | Warnings, attention needed |
| `Error` | `error` | Error messages, validation |
| `Info` | `info` | Informational text |
| `Border` | `border` | Box borders, separators |
| `Highlight` | `focus` | Selected items, focused widgets |
| `Selected` | `selection` | Selected rows, active items |

### Widget Theme Integration

```powershell
class PmcWidget : Component {
    [PmcThemeManager]$ThemeManager

    PmcWidget() : base() {
        $this.ThemeManager = [PmcThemeManager]::GetInstance()
    }

    [string] GetThemedColor([string]$role) {
        return $this.ThemeManager.GetColor($role)
    }

    [string] OnRender() {
        # Use themed colors
        $primaryColor = $this.GetThemedColor('primary')
        $borderColor = $this.GetThemedColor('border')
        $textColor = $this.GetThemedColor('text')

        # Build output with colors...
    }
}
```

---

## Component Specifications

### 1. PmcMenuBar

#### **Purpose:**
Top-level navigation menu with dropdown support

#### **Visual:**
```
┌────────────────────────────────────────────────────────┐
│ File(F) Tasks(T) Projects(P) View(V) Tools(O) Help(H) │  ← Menu Bar
└────────────────────────────────────────────────────────┘
     │
     ▼ (When File menu activated)
┌──────────────────┐
│ Backup Data   (B)│  ← Dropdown
│ Restore Data  (R)│
│ ──────────────── │
│ Exit          (X)│
└──────────────────┘
```

#### **API:**
```powershell
class PmcMenuBar : PmcWidget {
    [List[PmcMenu]]$Menus
    [int]$SelectedMenuIndex = -1
    [bool]$IsActive = $false
    [bool]$DropdownVisible = $false

    # Builder API
    [PmcMenuBar] AddMenu([string]$title, [char]$hotkey, [array]$items) {
        $menu = [PmcMenu]::new($title, $hotkey, $items)
        $this.Menus.Add($menu)
        return $this
    }

    # Event handlers
    [scriptblock]$OnMenuItemSelected  # param($menuTitle, $itemLabel)

    # Methods
    [void] Activate()              # F10 or Alt+key
    [void] ShowDropdown([int]$menuIndex)
    [void] HideDropdown()
    [void] SelectNextMenu()        # Right arrow
    [void] SelectPreviousMenu()    # Left arrow
}

class PmcMenu {
    [string]$Title
    [char]$Hotkey
    [List[PmcMenuItem]]$Items
}

class PmcMenuItem {
    [string]$Label
    [char]$Hotkey
    [bool]$IsSeparator = $false
    [scriptblock]$Action
    [bool]$Enabled = $true
}
```

#### **Usage:**
```powershell
$menuBar = [PmcMenuBar]::new()
$menuBar.AddMenu("File", 'F', @(
    @{ Label="Backup Data"; Hotkey='B'; Action={ Invoke-Backup } }
    @{ Label="Restore Data"; Hotkey='R'; Action={ Invoke-Restore } }
    @{ IsSeparator=$true }
    @{ Label="Exit"; Hotkey='X'; Action={ Exit } }
))
$menuBar.AddMenu("Tasks", 'T', @(
    @{ Label="Task List"; Hotkey='L'; Action={ Show-TaskList } }
    @{ Label="Add Task"; Hotkey='A'; Action={ Show-TaskAdd } }
))
# ... etc
```

#### **Keyboard Handling:**
- `F10` → Activate menu bar (select first menu)
- `Alt+[Hotkey]` → Direct menu activation with dropdown
- `Left/Right` → Navigate menus (when active)
- `Up/Down` → Navigate dropdown items
- `Enter` → Select item
- `Esc` → Close dropdown / deactivate menu bar
- `Letter` → Select item by hotkey in dropdown

---

### 2. PmcHeader

#### **Purpose:**
Standardized screen title display

#### **Variants:**

**Simple (underline style):**
```
 Project Management
──────────────────────
```

**Box style (centered):**
```
┌──────────────────────────────────────┐
│       Create New Project             │
└──────────────────────────────────────┘
```

**Embedded in border:**
```
┌─────────────── All Tasks ───────────────┐
│                                          │
```

#### **API:**
```powershell
class PmcHeader : PmcWidget {
    [string]$Title
    [string]$Icon = ""
    [PmcHeaderStyle]$Style = [PmcHeaderStyle]::Simple
    [PmcAlignment]$Alignment = [PmcAlignment]::Center

    PmcHeader([string]$title) : base() {
        $this.Title = $title
        $this.Height = 3  # Title + separator + blank
    }

    [string] OnRender() {
        switch ($this.Style) {
            'Simple' { return $this._RenderSimple() }
            'Box' { return $this._RenderBox() }
            'EmbeddedTop' { return $this._RenderEmbedded() }
        }
    }
}

enum PmcHeaderStyle {
    Simple          # Just text + underline
    Box             # Full box around title
    EmbeddedTop     # Title embedded in top border
}

enum PmcAlignment {
    Left
    Center
    Right
}
```

#### **Usage:**
```powershell
# Simple header
$header = [PmcHeader]::new("Task List")
$header.Style = [PmcHeaderStyle]::Simple

# Box header with icon
$header = [PmcHeader]::new("Create Project")
$header.Style = [PmcHeaderStyle]::Box
$header.Icon = "📁"

# Embedded in screen border
$header = [PmcHeader]::new("Kanban Board")
$header.Style = [PmcHeaderStyle]::EmbeddedTop
```

---

### 3. PmcFooter

#### **Purpose:**
Display keyboard shortcuts and hints

#### **Visual:**
```
──────────────────────────────────────────────────────────────
 ↑↓: Navigate | Enter: Select | F: Filter | S: Sort | Esc: Back
```

#### **API:**
```powershell
class PmcFooter : PmcWidget {
    [List[PmcShortcut]]$Shortcuts
    [string]$CustomText = ""

    PmcFooter() : base() {
        $this.Height = 2  # Separator + text
    }

    [PmcFooter] AddShortcut([string]$keys, [string]$description) {
        $this.Shortcuts.Add(@{ Keys=$keys; Description=$description })
        return $this
    }

    [PmcFooter] SetText([string]$text) {
        $this.CustomText = $text
        return $this
    }

    [PmcFooter] Clear() {
        $this.Shortcuts.Clear()
        $this.CustomText = ""
        return $this
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 512

        # Separator line
        $borderColor = $this.GetThemedColor('border')
        $sb.Append([InternalVT100]::MoveTo(0, $this.Y))
        $sb.Append($borderColor)
        $sb.Append("─" * $this.Width)
        $sb.Append([InternalVT100]::Reset())

        # Shortcut text
        if ($this.CustomText) {
            $text = $this.CustomText
        } else {
            $text = $this._BuildShortcutText()
        }

        $mutedColor = $this.GetThemedColor('muted')
        $sb.Append([InternalVT100]::MoveTo(2, $this.Y + 1))
        $sb.Append($mutedColor)
        $sb.Append($text)
        $sb.Append([InternalVT100]::Reset())

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }

    hidden [string] _BuildShortcutText() {
        $parts = @()
        foreach ($shortcut in $this.Shortcuts) {
            $parts += "$($shortcut.Keys): $($shortcut.Description)"
        }
        return $parts -join " | "
    }
}
```

#### **Usage:**
```powershell
$footer = [PmcFooter]::new()
$footer.
    AddShortcut("↑↓", "Navigate").
    AddShortcut("Enter", "Select").
    AddShortcut("F", "Filter").
    AddShortcut("S", "Sort").
    AddShortcut("Esc", "Back")

# Or custom text:
$footer.SetText("Processing... Press Esc to cancel")
```

---

### 4. PmcStatusBar

#### **Purpose:**
Persistent status information at screen bottom

#### **Visual:**
```
┌────────────────────────────────────────────────────────────┐
│ PMC Ready │ 124 tasks │ 8 projects │ Theme: ocean │ 14:32 │
└────────────────────────────────────────────────────────────┘
```

#### **API:**
```powershell
class PmcStatusBar : PmcWidget {
    [List[PmcStatusSection]]$Sections

    PmcStatusBar() : base() {
        $this.Height = 1
    }

    [void] SetSection([string]$name, [string]$text, [PmcAlignment]$align) {
        $existing = $this.Sections | Where-Object { $_.Name -eq $name }
        if ($existing) {
            $existing.Text = $text
        } else {
            $this.Sections.Add(@{ Name=$name; Text=$text; Alignment=$align })
        }
        $this.Invalidate()
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 256

        # Background
        $bgColor = $this.GetThemedColor('statusBarBg')
        $textColor = $this.GetThemedColor('muted')

        $sb.Append([InternalVT100]::MoveTo(0, $this.Y))
        $sb.Append($bgColor)
        $sb.Append($textColor)

        # Render sections
        $leftText = $this._GetSectionText([PmcAlignment]::Left)
        $centerText = $this._GetSectionText([PmcAlignment]::Center)
        $rightText = $this._GetSectionText([PmcAlignment]::Right)

        # Left section
        $sb.Append($leftText)

        # Center section
        $centerX = ($this.Width - $centerText.Length) / 2
        $sb.Append([InternalStringCache]::GetSpaces($centerX - $leftText.Length))
        $sb.Append($centerText)

        # Right section
        $rightX = $this.Width - $rightText.Length
        $sb.Append([InternalStringCache]::GetSpaces($rightX - $centerX - $centerText.Length))
        $sb.Append($rightText)

        $sb.Append([InternalVT100]::Reset())

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }
}
```

#### **Usage:**
```powershell
$statusBar = [PmcStatusBar]::new()
$statusBar.SetSection("status", "PMC Ready", [PmcAlignment]::Left)
$statusBar.SetSection("tasks", "124 tasks", [PmcAlignment]::Left)
$statusBar.SetSection("time", "14:32", [PmcAlignment]::Right)
$statusBar.SetSection("theme", "Theme: ocean", [PmcAlignment]::Right)
```

---

### 5. PmcPanel

#### **Purpose:**
Container with border and optional title

#### **Visual:**
```
┌───────── Recent Tasks ─────────┐
│                                │
│  - Task 1                      │
│  - Task 2                      │
│  - Task 3                      │
│                                │
└────────────────────────────────┘
```

#### **API:**
```powershell
class PmcPanel : PmcWidget {
    [string]$Title = ""
    [PmcBorderStyle]$BorderStyle = [PmcBorderStyle]::Single
    [bool]$ShowBorder = $true
    [int]$PaddingTop = 1
    [int]$PaddingRight = 2
    [int]$PaddingBottom = 1
    [int]$PaddingLeft = 2

    PmcPanel([string]$title) : base() {
        $this.Title = $title
    }

    [PmcRect] GetContentRect() {
        # Calculate inner content area (after border + padding)
        $x = $this.X + ($this.ShowBorder ? 1 : 0) + $this.PaddingLeft
        $y = $this.Y + ($this.ShowBorder ? 1 : 0) + $this.PaddingTop
        $w = $this.Width - ($this.ShowBorder ? 2 : 0) - $this.PaddingLeft - $this.PaddingRight
        $h = $this.Height - ($this.ShowBorder ? 2 : 0) - $this.PaddingTop - $this.PaddingBottom
        return [PmcRect]@{ X=$x; Y=$y; Width=$w; Height=$h }
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 1024

        if ($this.ShowBorder) {
            $borderColor = $this.GetThemedColor('border')
            $sb.Append($borderColor)

            # Draw border with optional title
            $this._DrawBorder($sb)

            $sb.Append([InternalVT100]::Reset())
        }

        # Children render in content area
        # (Component base class handles children)

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }

    hidden [void] _DrawBorder([StringBuilder]$sb) {
        $chars = $this._GetBorderChars($this.BorderStyle)

        # Top border
        $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y))
        if ($this.Title) {
            # Title embedded in top border
            $titleText = " $($this.Title) "
            $leftWidth = 4
            $rightWidth = $this.Width - $leftWidth - $titleText.Length - 2

            $sb.Append($chars.TL)
            $sb.Append($chars.H * $leftWidth)
            $sb.Append($titleText)
            $sb.Append($chars.H * $rightWidth)
            $sb.Append($chars.TR)
        } else {
            # Simple top border
            $sb.Append($chars.TL)
            $sb.Append($chars.H * ($this.Width - 2))
            $sb.Append($chars.TR)
        }

        # Side borders
        for ($y = 1; $y -lt $this.Height - 1; $y++) {
            $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y + $y))
            $sb.Append($chars.V)
            $sb.Append([InternalVT100]::MoveTo($this.X + $this.Width - 1, $this.Y + $y))
            $sb.Append($chars.V)
        }

        # Bottom border
        $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y + $this.Height - 1))
        $sb.Append($chars.BL)
        $sb.Append($chars.H * ($this.Width - 2))
        $sb.Append($chars.BR)
    }
}

enum PmcBorderStyle {
    Single    # ┌─┐
    Double    # ╔═╗
    Rounded   # ╭─╮
    Heavy     # ┏━┓
}
```

#### **Usage:**
```powershell
$panel = [PmcPanel]::new("Recent Tasks")
$panel.BorderStyle = [PmcBorderStyle]::Single
$panel.SetPosition(10, 5)
$panel.SetSize(40, 10)

# Add children in content area
$list = [List]::new()
$list.AddItems($recentTasks)
$contentRect = $panel.GetContentRect()
$list.SetBounds($contentRect)
$panel.AddChild($list)
```

---

### 6. PmcDialog

#### **Purpose:**
Modal dialog overlay

#### **Visual:**
```
┌────────────────────────────────────┐
│           CONFIRMATION             │  ← Title
├────────────────────────────────────┤
│                                    │
│  Are you sure you want to delete?  │  ← Message
│                                    │
│         [ Yes ]    [ No ]          │  ← Buttons
│                                    │
└────────────────────────────────────┘
```

#### **API:**
```powershell
class PmcDialog : PmcPanel {
    [PmcDialogType]$DialogType
    [string]$Message
    [List[Button]]$Buttons
    [scriptblock]$OnResult  # param([string]$buttonLabel)

    PmcDialog([string]$title, [string]$message) : base($title) {
        $this.Message = $message
        $this._CalculateSize()
        $this._CenterOnScreen()
    }

    # Factory methods
    static [PmcDialog] Info([string]$title, [string]$message) {
        $dialog = [PmcDialog]::new($title, $message)
        $dialog.DialogType = [PmcDialogType]::Info
        $dialog.AddButton("OK", $true)
        return $dialog
    }

    static [PmcDialog] Confirm([string]$title, [string]$message) {
        $dialog = [PmcDialog]::new($title, $message)
        $dialog.DialogType = [PmcDialogType]::Confirm
        $dialog.AddButton("Yes", $true)
        $dialog.AddButton("No", $false)
        return $dialog
    }

    static [PmcDialog] YesNoCancel([string]$title, [string]$message) {
        $dialog = [PmcDialog]::new($title, $message)
        $dialog.DialogType = [PmcDialogType]::YesNoCancel
        $dialog.AddButton("Yes")
        $dialog.AddButton("No")
        $dialog.AddButton("Cancel", $false, $true)  # isCancel
        return $dialog
    }

    [void] AddButton([string]$label, [bool]$isDefault=$false, [bool]$isCancel=$false) {
        $button = [Button]::new($label)
        $button.IsDefault = $isDefault
        $button.IsCancel = $isCancel
        $button.OnClick = {
            if ($this.OnResult) {
                & $this.OnResult $label
            }
        }
        $this.Buttons.Add($button)
    }

    [string] Show() {
        # Block and show dialog
        # Handle input until button pressed
        # Return button label
    }
}

enum PmcDialogType {
    Info
    Confirm
    YesNoCancel
    Custom
}
```

#### **Usage:**
```powershell
# Info dialog
$dialog = [PmcDialog]::Info("Success", "Task added successfully")
$dialog.Show()

# Confirm dialog
$dialog = [PmcDialog]::Confirm("Delete", "Are you sure?")
$result = $dialog.Show()
if ($result -eq "Yes") {
    # Delete
}

# Custom dialog
$dialog = [PmcDialog]::new("Select", "Choose an option")
$dialog.AddButton("Option 1")
$dialog.AddButton("Option 2")
$dialog.AddButton("Option 3")
$result = $dialog.Show()
```

---

### 7. PmcSeparator

#### **Purpose:**
Visual divider between sections

#### **Visual:**
```
────────────────────────────────
```

Or with text:
```
─────────── SECTION ───────────
```

#### **API:**
```powershell
class PmcSeparator : PmcWidget {
    [string]$Text = ""
    [PmcAlignment]$TextAlignment = [PmcAlignment]::Center
    [char]$LineChar = '─'

    PmcSeparator() : base() {
        $this.Height = 1
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 256

        $borderColor = $this.GetThemedColor('border')
        $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y))
        $sb.Append($borderColor)

        if ($this.Text) {
            # Separator with embedded text
            $text = " $($this.Text) "
            $textLen = $text.Length

            switch ($this.TextAlignment) {
                'Center' {
                    $leftLen = ($this.Width - $textLen) / 2
                    $rightLen = $this.Width - $leftLen - $textLen
                    $sb.Append($this.LineChar * $leftLen)
                    $sb.Append($text)
                    $sb.Append($this.LineChar * $rightLen)
                }
                'Left' {
                    $sb.Append($text)
                    $sb.Append($this.LineChar * ($this.Width - $textLen))
                }
                'Right' {
                    $sb.Append($this.LineChar * ($this.Width - $textLen))
                    $sb.Append($text)
                }
            }
        } else {
            # Simple line
            $sb.Append($this.LineChar * $this.Width)
        }

        $sb.Append([InternalVT100]::Reset())

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }
}
```

#### **Usage:**
```powershell
# Simple separator
$sep = [PmcSeparator]::new()

# Separator with text
$sep = [PmcSeparator]::new()
$sep.Text = "SECTION NAME"
$sep.TextAlignment = [PmcAlignment]::Center
```

---

### 8. PmcProgressBar

#### **Purpose:**
Show progress of long operations

#### **Visual:**
```
Progress: [█████████████░░░░░░░] 65%
```

Or compact:
```
[██████████████████████░░░░░░░░] 75%
```

#### **API:**
```powershell
class PmcProgressBar : PmcWidget {
    [int]$Current = 0
    [int]$Total = 100
    [bool]$ShowPercentage = $true
    [bool]$ShowLabel = $true
    [string]$Label = "Progress"

    [char]$FilledChar = '█'
    [char]$EmptyChar = '░'

    PmcProgressBar() : base() {
        $this.Height = 1
    }

    [void] SetProgress([int]$current, [int]$total) {
        $this.Current = $current
        $this.Total = $total
        $this.Invalidate()
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 256

        $percentage = if ($this.Total -gt 0) {
            ($this.Current / $this.Total) * 100
        } else { 0 }

        # Calculate bar width
        $labelWidth = if ($this.ShowLabel) { $this.Label.Length + 2 } else { 0 }
        $percentWidth = if ($this.ShowPercentage) { 5 } else { 0 }  # " 100%"
        $barWidth = $this.Width - $labelWidth - $percentWidth - 3  # [ and ]

        # Label
        if ($this.ShowLabel) {
            $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y))
            $sb.Append("$($this.Label): ")
        }

        # Bar
        $filledWidth = [Math]::Floor($barWidth * ($percentage / 100))
        $emptyWidth = $barWidth - $filledWidth

        $successColor = $this.GetThemedColor('success')
        $mutedColor = $this.GetThemedColor('muted')

        $sb.Append("[")
        $sb.Append($successColor)
        $sb.Append($this.FilledChar * $filledWidth)
        $sb.Append($mutedColor)
        $sb.Append($this.EmptyChar * $emptyWidth)
        $sb.Append([InternalVT100]::Reset())
        $sb.Append("]")

        # Percentage
        if ($this.ShowPercentage) {
            $sb.Append(" $([Math]::Round($percentage))%")
        }

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }
}
```

#### **Usage:**
```powershell
$progress = [PmcProgressBar]::new()
$progress.Label = "Importing tasks"
$progress.SetProgress(65, 100)

# Update in loop
for ($i = 0; $i -lt $total; $i++) {
    # Do work
    $progress.SetProgress($i + 1, $total)
}
```

---

### 9. PmcSpinner

#### **Purpose:**
Animated loading indicator

#### **Visual:**
```
Loading... ⠋
```

Frames: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (Braille pattern)

Or simpler: `| / - \`

#### **API:**
```powershell
class PmcSpinner : PmcWidget {
    [string]$Text = "Loading..."
    [array]$Frames = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
    [int]$CurrentFrame = 0
    [int]$FrameDelay = 100  # milliseconds

    PmcSpinner() : base() {
        $this.Height = 1
    }

    [void] NextFrame() {
        $this.CurrentFrame = ($this.CurrentFrame + 1) % $this.Frames.Count
        $this.Invalidate()
    }

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 128

        $infoColor = $this.GetThemedColor('info')
        $sb.Append([InternalVT100]::MoveTo($this.X, $this.Y))
        $sb.Append($infoColor)
        $sb.Append("$($this.Text) $($this.Frames[$this.CurrentFrame])")
        $sb.Append([InternalVT100]::Reset())

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }
}
```

#### **Usage:**
```powershell
$spinner = [PmcSpinner]::new()
$spinner.Text = "Processing..."

# Update in background timer
$timer = New-Object System.Timers.Timer
$timer.Interval = 100
$timer.Add_Elapsed({
    $spinner.NextFrame()
})
$timer.Start()

# Or manual update
while ($processing) {
    $spinner.NextFrame()
    Start-Sleep -Milliseconds 100
}
```

---

## Implementation Strategy

### Phase 1: Core Widget Library (Week 1)

**Goal:** Build essential widgets for all screens

**Tasks:**
1. Create `/module/Pmc.Strict/consoleui/widgets/` directory
2. Implement `PmcWidget` base class
3. Implement `PmcMenuBar` (extract from existing)
4. Implement `PmcHeader` (standardize existing patterns)
5. Implement `PmcFooter` (standardize existing patterns)
6. Implement `PmcStatusBar` (new)
7. Implement `PmcPanel` (new)
8. Implement `PmcSeparator` (simple)

**Testing:** Create test screen using all widgets

### Phase 2: Layout System (Week 2)

**Goal:** Eliminate magic numbers, enable resize

**Tasks:**
1. Implement `PmcLayoutManager` with named regions
2. Implement `PmcConstraints` system
3. Define `PmcStandardLayout` constants
4. Add resize handling to all widgets
5. Refactor test screen to use layout system

**Testing:** Resize terminal, verify all widgets reposition correctly

### Phase 3: Theme Integration (Week 2)

**Goal:** Unified theme system

**Tasks:**
1. Implement `PmcThemeManager` (bridge PMC + SpeedTUI)
2. Map color roles between systems
3. Ensure all widgets use themed colors
4. Test theme switching at runtime
5. Create PMC theme presets (ocean, lime, purple, etc.)

**Testing:** Switch themes, verify all widgets update

### Phase 4: Additional Widgets (Week 3)

**Goal:** Complete widget library

**Tasks:**
1. Implement `PmcDialog` (extract from existing)
2. Implement `PmcProgressBar` (new)
3. Implement `PmcSpinner` (new)
4. Implement `PmcSplitView` (new)
5. Implement `PmcBreadcrumb` (new, if needed)

**Testing:** Create complex test screen with all widgets

### Phase 5: Screen Templates (Week 4)

**Goal:** Standardized screen layouts

**Tasks:**
1. Create screen template classes
2. Implement standard layouts (list, form, detail, dashboard)
3. Convert 2-3 example screens to use templates
4. Document template usage

**Testing:** Verify templates work for different screen types

### Phase 6: Documentation (Week 4)

**Goal:** Developer documentation

**Tasks:**
1. Create widget catalog with examples
2. Create layout system guide
3. Create theme customization guide
4. Create screen template guide

---

## File Organization

```
/home/teej/pmc/module/Pmc.Strict/consoleui/
│
├── widgets/
│   ├── PmcWidget.ps1           # Base class
│   ├── PmcMenuBar.ps1          # Menu bar + dropdowns
│   ├── PmcHeader.ps1           # Screen headers
│   ├── PmcFooter.ps1           # Keyboard shortcuts
│   ├── PmcStatusBar.ps1        # Status information
│   ├── PmcPanel.ps1            # Container with border
│   ├── PmcDialog.ps1           # Modal dialogs
│   ├── PmcSeparator.ps1        # Horizontal dividers
│   ├── PmcProgressBar.ps1      # Progress indicators
│   ├── PmcSpinner.ps1          # Loading spinners
│   ├── PmcSplitView.ps1        # Split panes
│   ├── PmcTabView.ps1          # Tabbed views (future)
│   └── PmcBreadcrumb.ps1       # Navigation breadcrumbs (future)
│
├── layout/
│   ├── PmcLayoutManager.ps1    # Named regions
│   ├── PmcConstraints.ps1      # Constraint system
│   └── PmcStandardLayout.ps1   # Standard constants
│
├── theme/
│   ├── PmcThemeManager.ps1     # Unified theme system
│   └── PmcThemePresets.ps1     # Theme definitions
│
├── templates/
│   ├── PmcScreenTemplate.ps1   # Base template
│   ├── ListScreenTemplate.ps1  # List view template
│   ├── FormScreenTemplate.ps1  # Form template
│   └── DetailScreenTemplate.ps1 # Detail view template
│
└── docs/
    ├── WidgetCatalog.md        # All widgets with examples
    ├── LayoutGuide.md          # Layout system usage
    ├── ThemeGuide.md           # Theme customization
    └── TemplateGuide.md        # Screen templates
```

---

## Summary

### What We're Building

A **complete widget library** that provides:

✅ **Navigation**: MenuBar with dropdowns
✅ **Structure**: Headers, Footers, StatusBar, Panels
✅ **Layout**: Constraint-based positioning, named regions
✅ **Borders**: Full box-drawing character set
✅ **Theme**: Unified PMC + SpeedTUI system
✅ **Feedback**: Progress bars, spinners, dialogs
✅ **Templates**: Standardized screen layouts

### Key Benefits

1. **Consistency**: All screens use same widgets
2. **Maintainability**: Change widget, all screens update
3. **No Magic Numbers**: Layout system handles positioning
4. **Theme Aware**: All widgets respect theme
5. **Resize Handling**: Automatic repositioning
6. **Reusability**: Build once, use everywhere

### Implementation Timeline

- **Week 1**: Core widgets (MenuBar, Header, Footer, StatusBar, Panel)
- **Week 2**: Layout system + theme integration
- **Week 3**: Additional widgets (Dialog, Progress, Spinner, SplitView)
- **Week 4**: Templates + documentation

**Total: 4 weeks for complete widget library**

---

## Next Steps

1. **Review this document** - Ensure all requirements covered
2. **Prioritize widgets** - Which are most critical?
3. **Approve architecture** - Layout system, theme integration
4. **Start implementation** - Phase 1 (Core widgets)

**Questions to answer:**
- Do we need TabView now or later?
- Do we need mouse support? (affects Dialog, Menu)
- Any widget requirements missed?
- Layout system sufficient or need more features?

---

**END OF WIDGET LIBRARY ARCHITECTURE**
