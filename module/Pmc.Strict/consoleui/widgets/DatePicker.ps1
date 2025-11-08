# DatePicker.ps1 - Production-ready date picker widget for PMC TUI
# Supports both text input (smart date parsing) and calendar mode (visual month grid)
#
# Usage:
#   $picker = [DatePicker]::new()
#   $picker.SetPosition(10, 5)
#   $picker.SetSize(35, 14)
#   $picker.SetDate([DateTime]::Today)
#
#   # Render
#   $ansiOutput = $picker.Render()
#   Write-Host $ansiOutput -NoNewline
#
#   # Handle input
#   $key = [Console]::ReadKey($true)
#   $handled = $picker.HandleInput($key)
#
#   # Get result
#   if ($picker.IsConfirmed) {
#       $selected = $picker.GetSelectedDate()
#   }

using namespace System
using namespace System.Collections.Generic
using namespace System.Text
using namespace System.Globalization

Set-StrictMode -Version Latest

# Load PmcWidget base class if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

<#
.SYNOPSIS
Production-ready DatePicker widget with text and calendar modes

.DESCRIPTION
Features:
- Text mode: Smart date parsing (today, tomorrow, next friday, +7, eom, ISO dates)
- Calendar mode: Visual month grid with arrow navigation
- Full keyboard navigation
- Theme integration
- Event callbacks for date changes, confirmation, cancellation
- Automatic bounds clamping and validation

.EXAMPLE
$picker = [DatePicker]::new()
$picker.SetPosition(10, 5)
$picker.SetSize(35, 14)
$picker.SetDate([DateTime]::Today)
$picker.OnDateChanged = { param($newDate) Write-Host "Date changed to: $newDate" }
$picker.OnConfirmed = { param($date) Write-Host "Confirmed: $date" }
$ansiOutput = $picker.Render()
#>
class DatePicker : PmcWidget {
    # === Public Properties ===
    [bool]$IsConfirmed = $false      # True when user presses Enter
    [bool]$IsCancelled = $false      # True when user presses Esc

    # === Event Callbacks ===
    [scriptblock]$OnDateChanged = {}  # Called when date changes: param($newDate)
    [scriptblock]$OnConfirmed = {}    # Called when Enter pressed: param($finalDate)
    [scriptblock]$OnCancelled = {}    # Called when Esc pressed

    # === Private State ===
    hidden [DateTime]$_selectedDate = [DateTime]::Today
    hidden [DateTime]$_calendarMonth = [DateTime]::Today  # Month being displayed in calendar
    hidden [bool]$_isCalendarMode = $false                # False = text mode, True = calendar mode
    hidden [string]$_textInput = ""                       # Text mode input buffer
    hidden [string]$_errorMessage = ""                    # Error message to display
    hidden [int]$_cursorPosition = 0                      # Text cursor position

    # === Constructor ===
    DatePicker() : base("DatePicker") {
        $this.Width = 35
        $this.Height = 14
        $this._selectedDate = [DateTime]::Today
        $this._calendarMonth = [DateTime]::Today
        $this._textInput = $this._selectedDate.ToString("yyyy-MM-dd")
        $this.CanFocus = $true
    }

    # === Public API Methods ===

    <#
    .SYNOPSIS
    Set the currently selected date

    .PARAMETER date
    DateTime to set as selected
    #>
    [void] SetDate([DateTime]$date) {
        $this._selectedDate = $date
        $this._calendarMonth = $date
        $this._textInput = $date.ToString("yyyy-MM-dd")
        $this._errorMessage = ""
        $this._InvokeCallback($this.OnDateChanged, $date)
    }

    <#
    .SYNOPSIS
    Get the currently selected date

    .OUTPUTS
    DateTime object
    #>
    [DateTime] GetSelectedDate() {
        return $this._selectedDate
    }

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    ConsoleKeyInfo from [Console]::ReadKey($true)

    .OUTPUTS
    True if input was handled, False otherwise
    #>
    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Mode switching (F2 or Tab toggles mode)
        if ($keyInfo.Key -eq 'F2' -or ($keyInfo.Key -eq 'Tab' -and -not $this._isCalendarMode)) {
            $this._ToggleMode()
            return $true
        }

        # Global keys
        if ($keyInfo.Key -eq 'Enter') {
            # Try to parse text input if in text mode
            if (-not $this._isCalendarMode) {
                $parsed = $this._ParseTextInput()
                if ($parsed) {
                    $this._selectedDate = $parsed
                    $this._calendarMonth = $parsed
                    $this._errorMessage = ""
                } else {
                    # Don't confirm if parse failed
                    return $true
                }
            }

            $this.IsConfirmed = $true
            $this._InvokeCallback($this.OnConfirmed, $this._selectedDate)
            return $true
        }

        if ($keyInfo.Key -eq 'Escape') {
            $this.IsCancelled = $true
            $this._InvokeCallback($this.OnCancelled, $null)
            return $true
        }

        # Mode-specific input handling
        if ($this._isCalendarMode) {
            return $this._HandleCalendarInput($keyInfo)
        } else {
            return $this._HandleTextInput($keyInfo)
        }
    }

    <#
    .SYNOPSIS
    Render the date picker widget

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] Render() {
        $sb = [StringBuilder]::new(2048)

        # Colors from theme
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $textColor = $this.GetThemedAnsi('Text', $false)
        $primaryColor = $this.GetThemedAnsi('Primary', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $errorColor = $this.GetThemedAnsi('Error', $false)
        $successColor = $this.GetThemedAnsi('Success', $false)
        $reset = "`e[0m"

        # Title
        $title = "Select Date"

        # Draw border and title
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'top', 'single'))

        # Title centered in top border
        $titlePos = [Math]::Floor(($this.Width - $title.Length) / 2)
        $sb.Append($this.BuildMoveTo($this.X + $titlePos, $this.Y))
        $sb.Append($primaryColor)
        $sb.Append($title)

        # Mode indicator
        $mode = if ($this._isCalendarMode) { "Calendar" } else { "Text" }
        $modeText = "[$mode]"
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - $modeText.Length - 1, $this.Y))
        $sb.Append($mutedColor)
        $sb.Append($modeText)

        # Current value display (row 1)
        $currentValue = "Current: " + $this._selectedDate.ToString("yyyy-MM-dd (ddd)")
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 1))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($textColor)
        $sb.Append(" " + $this.PadText($currentValue, $this.Width - 3, 'left'))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Content area (rows 2-10)
        if ($this._isCalendarMode) {
            $this._RenderCalendar($sb, $borderColor, $textColor, $primaryColor, $mutedColor, $successColor, $reset)
        } else {
            $this._RenderTextMode($sb, $borderColor, $textColor, $primaryColor, $errorColor, $reset)
        }

        # Help text (row 11)
        $helpText = "Tab: Toggle mode | Enter: Confirm | Esc: Cancel"
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 11))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($mutedColor)
        $sb.Append(" " + $this.TruncateText($helpText, $this.Width - 3))
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 11))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Error message (row 12) if present
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 12))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        if ($this._errorMessage) {
            $sb.Append($errorColor)
            $sb.Append(" " + $this.TruncateText($this._errorMessage, $this.Width - 3))
        } else {
            $sb.Append(" " * ($this.Width - 2))
        }
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 12))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Bottom border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 13))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'bottom', 'single'))

        $sb.Append($reset)
        return $sb.ToString()
    }

    # === Private Helper Methods ===

    hidden [void] _ToggleMode() {
        $this._isCalendarMode = -not $this._isCalendarMode
        $this._errorMessage = ""

        # When switching to calendar mode, parse text input first
        if ($this._isCalendarMode) {
            $parsed = $this._ParseTextInput()
            if ($parsed) {
                $this._selectedDate = $parsed
                $this._calendarMonth = $parsed
            }
        } else {
            # Switching to text mode - populate with current selected date
            $this._textInput = $this._selectedDate.ToString("yyyy-MM-dd")
            $this._cursorPosition = $this._textInput.Length
        }
    }

    hidden [void] _RenderTextMode([StringBuilder]$sb, [string]$borderColor, [string]$textColor, [string]$primaryColor, [string]$errorColor, [string]$reset) {
        # Instructions (row 2)
        $instructions = "Type: today, tomorrow, next fri, +7, eom, YYYY-MM-DD"
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 2))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($textColor)
        $sb.Append(" " + $this.TruncateText($instructions, $this.Width - 3))
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 2))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Input field (row 4)
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 4))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($primaryColor)
        $sb.Append(" Input: ")
        $sb.Append($textColor)

        # Show input with cursor
        $displayInput = $this._textInput
        $maxInputWidth = $this.Width - 11
        if ($displayInput.Length -gt $maxInputWidth) {
            $displayInput = $displayInput.Substring($displayInput.Length - $maxInputWidth)
        }
        $sb.Append($displayInput)
        $sb.Append("_")  # Cursor
        $sb.Append(" " * [Math]::Max(0, $maxInputWidth - $displayInput.Length - 1))

        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 4))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Examples (rows 6-10)
        $examples = @(
            "Examples:",
            "  today, tomorrow",
            "  next monday, next fri",
            "  +7 (7 days from now)",
            "  eom (end of month)",
            "  2025-03-15"
        )

        for ($i = 0; $i -lt $examples.Count; $i++) {
            $row = $this.Y + 6 + $i
            $sb.Append($this.BuildMoveTo($this.X, $row))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))
            $sb.Append($textColor)
            $sb.Append(" " + $this.PadText($examples[$i], $this.Width - 3, 'left'))
            $sb.Append($borderColor)
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $row))
            $sb.Append($this.GetBoxChar('single_vertical'))
        }
    }

    hidden [void] _RenderCalendar([StringBuilder]$sb, [string]$borderColor, [string]$textColor, [string]$primaryColor, [string]$mutedColor, [string]$successColor, [string]$reset) {
        # Month/Year header (row 2)
        $monthYear = $this._calendarMonth.ToString("MMMM yyyy")
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 2))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($primaryColor)
        $sb.Append(" " + $this.PadText($monthYear, $this.Width - 3, 'center'))
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 2))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Day names (row 3)
        $dayNames = "Su Mo Tu We Th Fr Sa"
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 3))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($primaryColor)
        $sb.Append(" " + $this.PadText($dayNames, $this.Width - 3, 'center'))
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 3))
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Calendar grid (rows 4-9, 6 weeks max)
        $firstDay = [DateTime]::new($this._calendarMonth.Year, $this._calendarMonth.Month, 1)
        $daysInMonth = [DateTime]::DaysInMonth($this._calendarMonth.Year, $this._calendarMonth.Month)
        $startDayOfWeek = [int]$firstDay.DayOfWeek  # 0 = Sunday

        $today = [DateTime]::Today

        for ($week = 0; $week -lt 6; $week++) {
            $row = $this.Y + 4 + $week
            $sb.Append($this.BuildMoveTo($this.X, $row))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $line = " "
            for ($dow = 0; $dow -lt 7; $dow++) {
                $dayNum = ($week * 7 + $dow) - $startDayOfWeek + 1

                if ($dayNum -ge 1 -and $dayNum -le $daysInMonth) {
                    $thisDate = [DateTime]::new($this._calendarMonth.Year, $this._calendarMonth.Month, $dayNum)
                    $dayStr = $dayNum.ToString().PadLeft(2)

                    # Highlight logic
                    $isSelected = ($thisDate.Date -eq $this._selectedDate.Date)
                    $isToday = ($thisDate.Date -eq $today)

                    if ($isSelected) {
                        $line += $successColor + "[$dayStr]" + $textColor
                    } elseif ($isToday) {
                        $line += $primaryColor + " $dayStr " + $textColor
                    } else {
                        $line += " $dayStr "
                    }
                } else {
                    $line += "    "
                }
            }

            $sb.Append($textColor)
            # Don't pad/truncate calendar lines - they contain ANSI codes that confuse length calculation
            $sb.Append($line)
            # Pad with spaces to fill remaining width (calendar is fixed format, no ANSI in padding)
            $visibleLength = ($line -replace '\e\[[0-9;]*m', '').Length
            $padding = [Math]::Max(0, $this.Width - 3 - $visibleLength)
            $sb.Append(' ' * $padding)
            $sb.Append($borderColor)
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $row))
            $sb.Append($this.GetBoxChar('single_vertical'))
        }

        # Navigation hints (row 10)
        $hints = "Arrows: Navigate | PgUp/Dn: Month | Home/End: Month edges"
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 10))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($mutedColor)
        $sb.Append(" " + $this.TruncateText($hints, $this.Width - 3))
        $sb.Append($borderColor)
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + 10))
        $sb.Append($this.GetBoxChar('single_vertical'))
    }

    hidden [bool] _HandleTextInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Backspace' {
                if ($this._textInput.Length -gt 0) {
                    $this._textInput = $this._textInput.Substring(0, $this._textInput.Length - 1)
                    $this._errorMessage = ""
                }
                return $true
            }
            'Delete' {
                # Clear entire input
                $this._textInput = ""
                $this._errorMessage = ""
                return $true
            }
            default {
                # Add printable characters
                if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
                    $this._textInput += $keyInfo.KeyChar
                    $this._errorMessage = ""
                }
                return $true
            }
        }
        return $false
    }

    hidden [bool] _HandleCalendarInput([ConsoleKeyInfo]$keyInfo) {
        $changed = $false

        switch ($keyInfo.Key) {
            'LeftArrow' {
                $this._selectedDate = $this._selectedDate.AddDays(-1)
                $changed = $true
            }
            'RightArrow' {
                $this._selectedDate = $this._selectedDate.AddDays(1)
                $changed = $true
            }
            'UpArrow' {
                $this._selectedDate = $this._selectedDate.AddDays(-7)
                $changed = $true
            }
            'DownArrow' {
                $this._selectedDate = $this._selectedDate.AddDays(7)
                $changed = $true
            }
            'PageUp' {
                $this._selectedDate = $this._selectedDate.AddMonths(-1)
                $this._calendarMonth = $this._selectedDate
                $changed = $true
            }
            'PageDown' {
                $this._selectedDate = $this._selectedDate.AddMonths(1)
                $this._calendarMonth = $this._selectedDate
                $changed = $true
            }
            'Home' {
                # Start of month
                $this._selectedDate = [DateTime]::new($this._selectedDate.Year, $this._selectedDate.Month, 1)
                $changed = $true
            }
            'End' {
                # End of month
                $daysInMonth = [DateTime]::DaysInMonth($this._selectedDate.Year, $this._selectedDate.Month)
                $this._selectedDate = [DateTime]::new($this._selectedDate.Year, $this._selectedDate.Month, $daysInMonth)
                $changed = $true
            }
        }

        # Update calendar month if selected date moved to different month
        if ($changed) {
            if ($this._selectedDate.Month -ne $this._calendarMonth.Month -or
                $this._selectedDate.Year -ne $this._calendarMonth.Year) {
                $this._calendarMonth = $this._selectedDate
            }
            $this._InvokeCallback($this.OnDateChanged, $this._selectedDate)
        }

        return $changed
    }

    hidden [object] _ParseTextInput() {
        $input = $this._textInput.Trim().ToLower()

        if ([string]::IsNullOrWhiteSpace($input)) {
            $this._errorMessage = "Empty input"
            return $null
        }

        try {
            # Today
            if ($input -eq 'today') {
                return [DateTime]::Today
            }

            # Tomorrow
            if ($input -eq 'tomorrow') {
                return [DateTime]::Today.AddDays(1)
            }

            # Relative days (+N or -N)
            if ($input -match '^([+-]?\d+)$') {
                $days = [int]$Matches[1]
                return [DateTime]::Today.AddDays($days)
            }

            # End of month
            if ($input -eq 'eom') {
                $today = [DateTime]::Today
                $daysInMonth = [DateTime]::DaysInMonth($today.Year, $today.Month)
                return [DateTime]::new($today.Year, $today.Month, $daysInMonth)
            }

            # Next [day of week]
            if ($input -match '^next\s+(\w+)') {
                $dayName = $Matches[1]
                $targetDay = $this._ParseDayOfWeek($dayName)

                if ($targetDay -ne $null) {
                    $today = [DateTime]::Today
                    $daysUntil = (([int]$targetDay - [int]$today.DayOfWeek + 7) % 7)
                    if ($daysUntil -eq 0) { $daysUntil = 7 }  # Next week if today
                    return $today.AddDays($daysUntil)
                }
            }

            # Just day of week (next occurrence)
            $targetDay = $this._ParseDayOfWeek($input)
            if ($targetDay -ne $null) {
                $today = [DateTime]::Today
                $daysUntil = (([int]$targetDay - [int]$today.DayOfWeek + 7) % 7)
                if ($daysUntil -eq 0) { $daysUntil = 7 }  # Next week if today
                return $today.AddDays($daysUntil)
            }

            # Month day (e.g., "jan 15", "march 3")
            if ($input -match '^(\w+)\s+(\d+)') {
                $monthName = $Matches[1]
                $day = [int]$Matches[2]
                $month = $this._ParseMonth($monthName)

                if ($month -gt 0 -and $day -ge 1 -and $day -le 31) {
                    $year = [DateTime]::Today.Year
                    # If date has passed this year, use next year
                    $testDate = [DateTime]::new($year, $month, $day)
                    if ($testDate -lt [DateTime]::Today) {
                        $year++
                    }
                    return [DateTime]::new($year, $month, $day)
                }
            }

            # ISO date format (YYYY-MM-DD)
            if ($input -match '^\d{4}-\d{2}-\d{2}$') {
                $parsed = [DateTime]::ParseExact($input, 'yyyy-MM-dd', [CultureInfo]::InvariantCulture)
                return $parsed
            }

            # Try general DateTime parse
            $parsed = [DateTime]::Parse($input, [CultureInfo]::InvariantCulture)
            return $parsed

        } catch {
            $this._errorMessage = "Invalid date: $input"
            return $null
        }

        $this._errorMessage = "Unrecognized format: $input"
        return $null
    }

    hidden [object] _ParseDayOfWeek([string]$name) {
        $name = $name.ToLower()

        switch -Regex ($name) {
            '^su(n|nday)?$' { return [DayOfWeek]::Sunday }
            '^mo(n|nday)?$' { return [DayOfWeek]::Monday }
            '^tu(e|es|esday)?$' { return [DayOfWeek]::Tuesday }
            '^we(d|dnesday)?$' { return [DayOfWeek]::Wednesday }
            '^th(u|ursday)?$' { return [DayOfWeek]::Thursday }
            '^fr(i|iday)?$' { return [DayOfWeek]::Friday }
            '^sa(t|turday)?$' { return [DayOfWeek]::Saturday }
        }

        return $null
    }

    hidden [int] _ParseMonth([string]$name) {
        $name = $name.ToLower()

        switch -Regex ($name) {
            '^jan(uary)?$' { return 1 }
            '^feb(ruary)?$' { return 2 }
            '^mar(ch)?$' { return 3 }
            '^apr(il)?$' { return 4 }
            '^may$' { return 5 }
            '^jun(e)?$' { return 6 }
            '^jul(y)?$' { return 7 }
            '^aug(ust)?$' { return 8 }
            '^sep(tember)?$' { return 9 }
            '^oct(ober)?$' { return 10 }
            '^nov(ember)?$' { return 11 }
            '^dec(ember)?$' { return 12 }
        }

        return 0
    }

    hidden [void] _InvokeCallback([scriptblock]$callback, $arg) {
        if ($callback -and $callback -ne {}) {
            try {
                if ($arg -ne $null) {
                    & $callback $arg
                } else {
                    & $callback
                }
            } catch {
                # Silently ignore callback errors
            }
        }
    }
}
