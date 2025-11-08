# DatePicker Widget - Usage Guide

## Overview

The DatePicker widget is a production-ready, fully-featured date selection component for the PMC TUI application. It supports both smart text input and visual calendar navigation.

## Quick Start

```powershell
# Load the widget
. "$PSScriptRoot/DatePicker.ps1"

# Create instance
$picker = [DatePicker]::new()
$picker.SetPosition(10, 5)
$picker.SetSize(35, 14)
$picker.SetDate([DateTime]::Today)

# Render and display
$output = $picker.Render()
Write-Host $output -NoNewline

# Handle input loop
while (-not $picker.IsConfirmed -and -not $picker.IsCancelled) {
    $key = [Console]::ReadKey($true)
    $handled = $picker.HandleInput($key)

    if ($handled) {
        # Re-render
        Write-Host "`e[2J`e[H" -NoNewline  # Clear screen
        $output = $picker.Render()
        Write-Host $output -NoNewline
    }
}

# Get result
if ($picker.IsConfirmed) {
    $selectedDate = $picker.GetSelectedDate()
    Write-Host "Selected: $($selectedDate.ToString('yyyy-MM-dd'))"
}
```

## Features

### Two Input Modes

#### Text Mode (Default)
Smart date parsing with natural language support:

| Input | Result |
|-------|--------|
| `today` | Current date |
| `tomorrow` | Next day |
| `+7` | 7 days from now |
| `-3` | 3 days ago |
| `next friday` | Next Friday's date |
| `friday` | Next Friday (same as above) |
| `jan 15` | January 15 this year (or next if passed) |
| `eom` | End of current month |
| `2025-03-15` | Exact ISO date |

Abbreviations supported:
- Days: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`
- Months: `jan`, `feb`, `mar`, `apr`, `jun`, `jul`, `aug`, `sep`, `oct`, `nov`, `dec`

#### Calendar Mode (F2 or Tab)
Visual month grid with keyboard navigation:

- **Arrow keys**: Navigate days
- **Page Up/Down**: Change months
- **Home**: Jump to start of month
- **End**: Jump to end of month
- **Selected date**: Highlighted with `[DD]`
- **Today's date**: Highlighted in primary color

### Keyboard Controls

| Key | Action |
|-----|--------|
| **Tab** / **F2** | Toggle between text and calendar mode |
| **Enter** | Confirm selection (parse text if in text mode) |
| **Escape** | Cancel selection |
| **Arrows** | Navigate calendar (calendar mode) |
| **Page Up/Down** | Change months (calendar mode) |
| **Home/End** | Jump to month edges (calendar mode) |
| **Backspace** | Delete character (text mode) |
| **Delete** | Clear input (text mode) |
| **Printable chars** | Type in text field (text mode) |

## API Reference

### Constructor

```powershell
$picker = [DatePicker]::new()
```

Creates a new DatePicker with default size (35x14) and today's date selected.

### Methods

#### SetDate([DateTime]$date)
Set the currently selected date.

```powershell
$picker.SetDate([DateTime]::new(2025, 3, 15))
```

#### GetSelectedDate() : DateTime
Get the currently selected date.

```powershell
$selectedDate = $picker.GetSelectedDate()
```

#### HandleInput([ConsoleKeyInfo]$keyInfo) : bool
Handle keyboard input. Returns `$true` if input was handled and widget needs re-render.

```powershell
$key = [Console]::ReadKey($true)
$needsRedraw = $picker.HandleInput($key)
```

#### Render() : string
Render the widget to an ANSI string.

```powershell
$ansiOutput = $picker.Render()
Write-Host $ansiOutput -NoNewline
```

### Properties

#### IsConfirmed : bool
Set to `$true` when user presses Enter. Check this to exit input loop.

#### IsCancelled : bool
Set to `$true` when user presses Escape. Check this to exit input loop.

### Event Callbacks

#### OnDateChanged
Called whenever the selected date changes.

```powershell
$picker.OnDateChanged = {
    param([DateTime]$newDate)
    Write-Host "Date changed to: $($newDate.ToString('yyyy-MM-dd'))"
}
```

#### OnConfirmed
Called when user presses Enter to confirm selection.

```powershell
$picker.OnConfirmed = {
    param([DateTime]$finalDate)
    Write-Host "User confirmed: $($finalDate.ToString('yyyy-MM-dd'))"
}
```

#### OnCancelled
Called when user presses Escape to cancel.

```powershell
$picker.OnCancelled = {
    Write-Host "User cancelled selection"
}
```

## Integration Example

### Task Due Date Selection

```powershell
function Get-TaskDueDate {
    param([DateTime]$currentDueDate = [DateTime]::Today)

    # Clear screen
    Write-Host "`e[2J`e[H" -NoNewline

    # Create picker
    $picker = [DatePicker]::new()
    $picker.SetPosition(5, 3)
    $picker.SetDate($currentDueDate)

    # Event handlers
    $picker.OnConfirmed = {
        param($date)
        Write-Host "`e[H`e[2J" -NoNewline
        Write-Host "Due date set to: $($date.ToString('yyyy-MM-dd (dddd)'))" -ForegroundColor Green
    }

    # Input loop
    while (-not $picker.IsConfirmed -and -not $picker.IsCancelled) {
        Write-Host "`e[2J`e[H" -NoNewline
        Write-Host $picker.Render() -NoNewline

        $key = [Console]::ReadKey($true)
        $picker.HandleInput($key) | Out-Null
    }

    # Return selected date or null if cancelled
    if ($picker.IsConfirmed) {
        return $picker.GetSelectedDate()
    } else {
        return $null
    }
}

# Usage
$dueDate = Get-TaskDueDate
if ($dueDate) {
    Write-Host "Selected due date: $dueDate"
} else {
    Write-Host "Selection cancelled"
}
```

## Visual Design

### Text Mode Layout
```
┌───────────────────────────────┐
│        Select Date     [Text] │
│ Current: 2025-03-15 (Sat)    │
│ Type: today, tomorrow, +7...  │
│                               │
│ Input: tomorrow_              │
│                               │
│ Examples:                     │
│   today, tomorrow             │
│   next monday, next fri       │
│   +7 (7 days from now)        │
│   eom (end of month)          │
│   2025-03-15                  │
│ Tab: Toggle mode | Enter:...  │
│                               │
└───────────────────────────────┘
```

### Calendar Mode Layout
```
┌───────────────────────────────┐
│     Select Date   [Calendar]  │
│ Current: 2025-03-15 (Sat)    │
│        March 2025             │
│   Su Mo Tu We Th Fr Sa        │
│                        01 02  │
│    03 04 05 06 07 08 09       │
│    10 11 12 13 14[15]16       │
│    17 18 19 20 21 22 23       │
│    24 25 26 27 28 29 30       │
│    31                          │
│ Arrows: Nav | PgUp/Dn: Month  │
│                               │
└───────────────────────────────┘
```

Legend:
- `[15]` - Selected date (green highlight)
- `15` (no brackets) - Today's date (primary color highlight)
- Regular dates - Muted color

## Error Handling

### Invalid Text Input
When invalid input is entered in text mode, an error message appears at the bottom:

```
┌───────────────────────────────┐
│ ...                           │
│ Invalid date: notadate        │
└───────────────────────────────┘
```

Errors are cleared when:
- User types new input
- User switches modes
- User successfully parses valid input

### Date Bounds
- All dates are automatically clamped to valid .NET DateTime range
- Month navigation handles edge cases (Jan 31 → Feb 28/29)
- Leap years are properly handled

## Theme Integration

DatePicker uses PmcWidget's theme system:

| Color Role | Usage |
|-----------|-------|
| `Border` | Box borders, grid lines |
| `Text` | Regular text |
| `Primary` | Title, today's date highlight |
| `Muted` | Help text, mode indicator |
| `Success` | Selected date in calendar |
| `Error` | Error messages |

Colors automatically adapt to the current PMC theme.

## Performance

- Efficient rendering using StringBuilder
- ANSI escape sequences for positioning
- No unnecessary allocations
- Typical render time: < 5ms
- Suitable for 60 FPS interactive UI

## Testing

Run comprehensive tests:

```bash
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/widgets/TestDatePicker.ps1
```

Tests cover:
1. Smart date parsing (15+ patterns)
2. Invalid input rejection
3. Calendar navigation (arrows, page up/down, home/end)
4. Edge cases (leap years, month/year boundaries)
5. Event callbacks
6. Mode switching
7. Visual rendering

## Known Limitations

1. **Terminal Width**: Minimum width of 35 characters required for proper rendering
2. **Color Support**: Requires TrueColor (24-bit) terminal for proper theme colors
3. **Date Range**: Limited to .NET DateTime range (0001-01-01 to 9999-12-31)
4. **Text Parsing**: English language only for day/month names
5. **Time Component**: Only supports date selection (time is always midnight)

## Future Enhancements

Potential improvements (not currently implemented):
- Time picker integration
- Date range selection
- Custom format strings
- Locale support (i18n)
- Month/year quick jump
- Keyboard shortcuts for common dates (T=today, Y=yesterday, etc.)
- Multi-date selection mode

## License

Part of the PMC (Project Management Console) application.

## See Also

- `PmcWidget.ps1` - Base widget class
- `PmcDialog.ps1` - Dialog system examples
- `PmcFilePicker.ps1` - File picker widget
