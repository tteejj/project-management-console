using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Dialog system for PMC TUI

.DESCRIPTION
Provides reusable dialog components:
- ConfirmDialog: Yes/No confirmation
- TextInputDialog: Single line text input
- MessageDialog: Display message with OK button
#>

class PmcDialog {
    [string]$Title
    [string]$Message
    [int]$Width
    [int]$Height
    [bool]$IsComplete = $false
    [bool]$Result = $false
    [string]$TextResult = ''

    PmcDialog([string]$title, [string]$message) {
        $this.Title = $title
        $this.Message = $message
        $this.Width = [Math]::Max(60, [Math]::Max($title.Length + 10, $message.Length + 10))
        $this.Height = 10
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $sb = [System.Text.StringBuilder]::new(2048)

        # Calculate centered position
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors from theme
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $borderColor = if ($theme.DialogBorder) { $theme.DialogBorder } else { "`e[38;2;95;107;119m" }
        $highlightColor = if ($theme.Highlight) { $theme.Highlight } else { "`e[38;2;136;153;170m" }
        $reset = "`e[0m"

        # Draw shadow (offset by 1)
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row + 1);$($x + 2)H")
            $sb.Append("`e[48;2;0;0;0m")
            $sb.Append(" " * $this.Width)
        }

        # Draw dialog box
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row);${x}H")
            $sb.Append($bgColor)
            $sb.Append($borderColor)

            if ($row -eq 0) {
                # Top border
                $sb.Append("┌" + ("─" * ($this.Width - 2)) + "┐")
            }
            elseif ($row -eq $this.Height - 1) {
                # Bottom border
                $sb.Append("└" + ("─" * ($this.Width - 2)) + "┘")
            }
            else {
                # Sides
                $sb.Append("│")
                $sb.Append($fgColor)
                $sb.Append(" " * ($this.Width - 2))
                $sb.Append($borderColor)
                $sb.Append("│")
            }
        }

        # Title (centered on row 1)
        $titleX = $x + [Math]::Floor(($this.Width - $this.Title.Length) / 2)
        $sb.Append("`e[$($y + 1);${titleX}H")
        $sb.Append($bgColor)
        $sb.Append($highlightColor)
        $sb.Append($this.Title)

        # Message (centered on row 3)
        $messageX = $x + [Math]::Floor(($this.Width - $this.Message.Length) / 2)
        $sb.Append("`e[$($y + 3);${messageX}H")
        $sb.Append($bgColor)
        $sb.Append($fgColor)
        $sb.Append($this.Message)

        $sb.Append($reset)
        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Override in derived classes
        return $false
    }
}

class ConfirmDialog : PmcDialog {
    [int]$SelectedButton = 0  # 0 = Yes, 1 = No

    ConfirmDialog([string]$title, [string]$message) : base($title, $message) {
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $baseRender = ([PmcDialog]$this).Render($termWidth, $termHeight, $theme)
        $sb = [System.Text.StringBuilder]::new($baseRender)

        # Calculate positions
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $highlightBg = if ($theme.Primary) { $theme.Primary } else { "`e[48;2;95;107;119m" }
        $reset = "`e[0m"

        # Buttons (centered on row 6)
        $yesText = " Yes "
        $noText = " No "
        $buttonGap = 4
        $totalButtonWidth = $yesText.Length + $noText.Length + $buttonGap
        $buttonStartX = $x + [Math]::Floor(($this.Width - $totalButtonWidth) / 2)

        # Yes button
        $sb.Append("`e[$($y + 6);${buttonStartX}H")
        if ($this.SelectedButton -eq 0) {
            $sb.Append($highlightBg)
            $sb.Append($fgColor)
        } else {
            $sb.Append($bgColor)
            $sb.Append($fgColor)
        }
        $sb.Append($yesText)
        $sb.Append($reset)

        # No button
        $noButtonX = $buttonStartX + $yesText.Length + $buttonGap
        $sb.Append("`e[$($y + 6);${noButtonX}H")
        if ($this.SelectedButton -eq 1) {
            $sb.Append($highlightBg)
            $sb.Append($fgColor)
        } else {
            $sb.Append($bgColor)
            $sb.Append($fgColor)
        }
        $sb.Append($noText)
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'LeftArrow' {
                $this.SelectedButton = 0
                return $true
            }
            'RightArrow' {
                $this.SelectedButton = 1
                return $true
            }
            'Tab' {
                $this.SelectedButton = 1 - $this.SelectedButton
                return $true
            }
            'Enter' {
                $this.Result = ($this.SelectedButton -eq 0)
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
            'Y' {
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
            'N' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
        }
        return $false
    }
}

class TextInputDialog : PmcDialog {
    [string]$InputBuffer = ''
    [string]$Prompt

    TextInputDialog([string]$title, [string]$prompt, [string]$defaultValue) : base($title, $prompt) {
        $this.Prompt = $prompt
        $this.InputBuffer = $defaultValue
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $baseRender = ([PmcDialog]$this).Render($termWidth, $termHeight, $theme)
        $sb = [System.Text.StringBuilder]::new($baseRender)

        # Calculate positions
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $inputBg = if ($theme.InputBg) { $theme.InputBg } else { "`e[48;2;30;37;48m" }
        $cursorColor = if ($theme.Accent) { $theme.Accent } else { "`e[38;2;136;153;170m" }
        $reset = "`e[0m"

        # Input field (row 5)
        $inputWidth = $this.Width - 8
        $inputX = $x + 4
        $sb.Append("`e[$($y + 5);${inputX}H")
        $sb.Append($inputBg)
        $sb.Append($fgColor)

        $displayText = $this.InputBuffer
        if ($displayText.Length -gt $inputWidth - 2) {
            $displayText = $displayText.Substring($displayText.Length - $inputWidth + 2)
        }
        $sb.Append(" ")
        $sb.Append($displayText)
        $sb.Append($cursorColor)
        $sb.Append("_")
        $sb.Append($fgColor)
        $sb.Append(" " * [Math]::Max(0, $inputWidth - $displayText.Length - 2))
        $sb.Append($reset)

        # Hint text (row 7)
        $hintText = "Enter: OK | Esc: Cancel"
        $hintX = $x + [Math]::Floor(($this.Width - $hintText.Length) / 2)
        $sb.Append("`e[$($y + 7);${hintX}H")
        $sb.Append($bgColor)
        $sb.Append($cursorColor)
        $sb.Append($hintText)
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Enter' {
                $this.TextResult = $this.InputBuffer
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
            'Backspace' {
                if ($this.InputBuffer.Length > 0) {
                    $this.InputBuffer = $this.InputBuffer.Substring(0, $this.InputBuffer.Length - 1)
                }
                return $true
            }
            default {
                if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
                    $this.InputBuffer += $keyInfo.KeyChar
                }
                return $true
            }
        }
        return $false
    }
}

class MessageDialog : PmcDialog {
    MessageDialog([string]$title, [string]$message) : base($title, $message) {
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $baseRender = ([PmcDialog]$this).Render($termWidth, $termHeight, $theme)
        $sb = [System.Text.StringBuilder]::new($baseRender)

        # Calculate positions
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $highlightBg = if ($theme.Primary) { $theme.Primary } else { "`e[48;2;95;107;119m" }
        $reset = "`e[0m"

        # OK button (centered on row 6)
        $okText = " OK "
        $buttonX = $x + [Math]::Floor(($this.Width - $okText.Length) / 2)

        $sb.Append("`e[$($y + 6);${buttonX}H")
        $sb.Append($highlightBg)
        $sb.Append($fgColor)
        $sb.Append($okText)
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Enter' {
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
        }
        return $false
    }
}

<#
.SYNOPSIS
Multi-field project form dialog

.DESCRIPTION
Modal form for adding/editing projects with all fields visible:
- name
- description
- path
- aliases (comma-separated)

Navigation:
- Tab/Shift+Tab: Move between fields
- Up/Down: Move between fields
- Enter: Save
- Esc: Cancel
#>
class ProjectFormDialog : PmcDialog {
    [hashtable]$Fields = @{
        name = ''
        description = ''
        path = ''
        aliases = ''
    }
    [string]$CurrentField = 'name'
    [array]$FieldOrder = @('name', 'description', 'path', 'aliases')
    [hashtable]$FieldLabels = @{
        name = 'Name'
        description = 'Description'
        path = 'Path'
        aliases = 'Aliases'
    }
    [bool]$IsEditMode = $false
    [string]$OriginalName = ''

    # Constructor for new project
    ProjectFormDialog() : base("Add Project", "Enter project details") {
        $this.Width = 70
        $this.Height = 16
        $this.IsEditMode = $false
    }

    # Constructor for editing existing project
    ProjectFormDialog([hashtable]$existingProject) : base("Edit Project", "Modify project details") {
        $this.Width = 70
        $this.Height = 16
        $this.IsEditMode = $true
        $this.OriginalName = $existingProject.name

        # Populate fields from existing project
        $this.Fields.name = $existingProject.name
        $this.Fields.description = if ($existingProject.description) { $existingProject.description } else { '' }
        $this.Fields.path = if ($existingProject.path) { $existingProject.path } else { '' }
        $this.Fields.aliases = if ($existingProject.aliases -and $existingProject.aliases.Count -gt 0) {
            $existingProject.aliases -join ', '
        } else {
            ''
        }
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $sb = [System.Text.StringBuilder]::new(4096)

        # Calculate centered position
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # High contrast readable colors
        $bgColor = "`e[48;2;30;30;30m"        # Dark background
        $fgColor = "`e[38;2;255;255;255m"     # White text
        $borderColor = "`e[38;2;150;150;150m" # Light gray border
        $highlightColor = "`e[38;2;100;200;255m" # Bright cyan for labels
        $accentBg = "`e[48;2;0;100;180m"      # Blue background for selected field
        $mutedColor = "`e[38;2;180;180;180m"  # Light gray for inactive labels
        $reset = "`e[0m"

        # Draw shadow (offset by 1)
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row + 1);$($x + 2)H")
            $sb.Append("`e[48;2;0;0;0m")
            $sb.Append(" " * $this.Width)
        }

        # Draw dialog box
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row);${x}H")
            $sb.Append($bgColor)
            $sb.Append($borderColor)

            if ($row -eq 0) {
                # Top border
                $sb.Append("┌" + ("─" * ($this.Width - 2)) + "┐")
            }
            elseif ($row -eq $this.Height - 1) {
                # Bottom border
                $sb.Append("└" + ("─" * ($this.Width - 2)) + "┘")
            }
            else {
                # Sides
                $sb.Append("│")
                $sb.Append($fgColor)
                $sb.Append(" " * ($this.Width - 2))
                $sb.Append($borderColor)
                $sb.Append("│")
            }
        }

        # Title (centered on row 1)
        $titleX = $x + [Math]::Floor(($this.Width - $this.Title.Length) / 2)
        $sb.Append("`e[$($y + 1);${titleX}H")
        $sb.Append($bgColor)
        $sb.Append($highlightColor)
        $sb.Append($this.Title)

        # Render form fields starting at row 3
        $fieldY = $y + 3
        $labelX = $x + 4
        $inputX = $x + 18
        $inputWidth = $this.Width - 22

        foreach ($fieldName in $this.FieldOrder) {
            $isCurrentField = ($fieldName -eq $this.CurrentField)
            $label = $this.FieldLabels[$fieldName]
            $value = $this.Fields[$fieldName]

            # Label
            $sb.Append("`e[$fieldY;${labelX}H")
            $sb.Append($bgColor)
            if ($isCurrentField) {
                $sb.Append($highlightColor)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($label.PadRight(12))

            # Input field
            $sb.Append("`e[$fieldY;${inputX}H")
            $sb.Append($bgColor)
            if ($isCurrentField) {
                $sb.Append($accentBg)
                $sb.Append($fgColor)
            } else {
                $sb.Append($fgColor)
            }

            # Truncate value if too long
            $displayValue = $value
            if ($displayValue.Length > $inputWidth) {
                $displayValue = $displayValue.Substring(0, $inputWidth - 3) + "..."
            }
            $sb.Append($displayValue.PadRight($inputWidth))

            # Cursor for current field
            if ($isCurrentField) {
                $cursorX = $inputX + [Math]::Min($value.Length, $inputWidth - 1)
                $sb.Append("`e[$fieldY;${cursorX}H")
                $sb.Append($accentBg)
                $sb.Append($highlightColor)
                $sb.Append("_")
            }

            $fieldY += 2
        }

        # Instructions at bottom
        $instructionsY = $y + $this.Height - 3
        $instructions = "Tab: Next field | Enter: Save | Esc: Cancel"
        $instructionsX = $x + [Math]::Floor(($this.Width - $instructions.Length) / 2)
        $sb.Append("`e[$instructionsY;${instructionsX}H")
        $sb.Append($bgColor)
        $sb.Append($mutedColor)
        $sb.Append($instructions)

        $sb.Append($reset)
        return $sb.ToString()
    }

    # Update just the current field on screen (called after input changes)
    [void] UpdateFieldDisplay([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        # Calculate dialog position
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $highlightColor = if ($theme.Highlight) { $theme.Highlight } else { "`e[38;2;136;153;170m" }
        $accentBg = if ($theme.PrimaryBg) { $theme.PrimaryBg } else { "`e[48;2;64;94;117m" }
        $mutedColor = if ($theme.Muted) { $theme.Muted } else { "`e[38;2;136;153;170m" }
        $reset = "`e[0m"

        # Calculate field positions
        $fieldIndex = $this.FieldOrder.IndexOf($this.CurrentField)
        $fieldY = $y + 3 + ($fieldIndex * 2)
        $labelX = $x + 4
        $inputX = $x + 18
        $inputWidth = $this.Width - 22

        $label = $this.FieldLabels[$this.CurrentField]
        $value = $this.Fields[$this.CurrentField]

        # Render label
        [Console]::Write("`e[$fieldY;${labelX}H")
        [Console]::Write($bgColor)
        [Console]::Write($highlightColor)
        [Console]::Write($label.PadRight(12))

        # Render input field
        [Console]::Write("`e[$fieldY;${inputX}H")
        [Console]::Write($accentBg)
        [Console]::Write($fgColor)
        $displayValue = $value
        if ($displayValue.Length > $inputWidth) {
            $displayValue = $displayValue.Substring(0, $inputWidth - 3) + "..."
        }
        [Console]::Write($displayValue.PadRight($inputWidth))

        # Render cursor
        $cursorX = $inputX + [Math]::Min($value.Length, $inputWidth - 1)
        [Console]::Write("`e[$fieldY;${cursorX}H")
        [Console]::Write($accentBg)
        [Console]::Write($highlightColor)
        [Console]::Write("_")
        [Console]::Write($reset)
    }

    # File picker integration
    [string]$FilePicker = ''  # Signal to caller to show file picker

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Enter' {
                # Check if we're on path field - open file picker
                if ($this.CurrentField -eq 'path') {
                    $this.FilePicker = 'show'
                    return $true
                }

                # Otherwise validate and save
                if ([string]::IsNullOrWhiteSpace($this.Fields.name)) {
                    # Name is required - don't close
                    return $true
                }
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
            'Tab' {
                # Move to next field - NEEDS FULL REDRAW
                $currentIndex = $this.FieldOrder.IndexOf($this.CurrentField)
                if ($keyInfo.Modifiers -eq [ConsoleModifiers]::Shift) {
                    # Shift+Tab: previous field
                    $currentIndex--
                    if ($currentIndex -lt 0) {
                        $currentIndex = $this.FieldOrder.Count - 1
                    }
                } else {
                    # Tab: next field
                    $currentIndex++
                    if ($currentIndex -ge $this.FieldOrder.Count) {
                        $currentIndex = 0
                    }
                }
                $this.CurrentField = $this.FieldOrder[$currentIndex]
                return $true  # Caller must re-render
            }
            'UpArrow' {
                # Move to previous field - NEEDS FULL REDRAW
                $currentIndex = $this.FieldOrder.IndexOf($this.CurrentField)
                $currentIndex--
                if ($currentIndex -lt 0) {
                    $currentIndex = $this.FieldOrder.Count - 1
                }
                $this.CurrentField = $this.FieldOrder[$currentIndex]
                return $true  # Caller must re-render
            }
            'DownArrow' {
                # Move to next field - NEEDS FULL REDRAW
                $currentIndex = $this.FieldOrder.IndexOf($this.CurrentField)
                $currentIndex++
                if ($currentIndex -ge $this.FieldOrder.Count) {
                    $currentIndex = 0
                }
                $this.CurrentField = $this.FieldOrder[$currentIndex]
                return $true  # Caller must re-render
            }
            'Backspace' {
                # Delete character from current field - UPDATE CURRENT FIELD ONLY
                if ($this.Fields[$this.CurrentField].Length -gt 0) {
                    $this.Fields[$this.CurrentField] = $this.Fields[$this.CurrentField].Substring(0, $this.Fields[$this.CurrentField].Length - 1)
                }
                return $false  # No full redraw needed
            }
            default {
                # Add character to current field - UPDATE CURRENT FIELD ONLY
                if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
                    $this.Fields[$this.CurrentField] += $keyInfo.KeyChar
                }
                return $false  # No full redraw needed
            }
        }
        return $false
    }

    # Get the project hashtable result
    [hashtable] GetProject() {
        # Parse aliases from comma-separated string
        $aliasesArray = @()
        if (-not [string]::IsNullOrWhiteSpace($this.Fields.aliases)) {
            $aliasesArray = @($this.Fields.aliases -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }

        return @{
            name = $this.Fields.name
            description = $this.Fields.description
            path = $this.Fields.path
            aliases = $aliasesArray
        }
    }
}
