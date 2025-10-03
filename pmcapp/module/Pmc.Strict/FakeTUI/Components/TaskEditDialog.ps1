# Task Edit Dialog - Modal dialog for editing tasks
# Provides forms for creating and editing PMC tasks

class PmcTaskEditDialog {
    [object]$Terminal
    [object]$Task
    [bool]$IsNewTask
    [hashtable]$Fields
    [array]$FieldOrder
    [int]$CurrentField = 0
    [bool]$IsActive = $false
    [string]$Result = 'cancel'

    PmcTaskEditDialog([object]$terminal, [object]$task = $null) {
        $this.Terminal = $terminal
        $this.IsNewTask = ($task -eq $null)
        $this.InitializeFields($task)
    }

    [void] InitializeFields([object]$task) {
        # Initialize form fields
        $this.Fields = @{
            text = @{ Label = 'Task Description'; Value = ''; Type = 'text'; Required = $true }
            project = @{ Label = 'Project'; Value = ''; Type = 'text'; Required = $false }
            priority = @{ Label = 'Priority'; Value = 'medium'; Type = 'select'; Options = @('low', 'medium', 'high'); Required = $false }
            status = @{ Label = 'Status'; Value = 'active'; Type = 'select'; Options = @('active', 'waiting', 'completed'); Required = $false }
            tags = @{ Label = 'Tags'; Value = ''; Type = 'text'; Required = $false; Help = 'Comma-separated tags' }
            notes = @{ Label = 'Notes'; Value = ''; Type = 'textarea'; Required = $false }
        }

        $this.FieldOrder = @('text', 'project', 'priority', 'status', 'tags', 'notes')

        # Populate with existing task data
        if ($task -and -not $this.IsNewTask) {
            if ($task.text) { $this.Fields.text.Value = $task.text }
            if ($task.project) { $this.Fields.project.Value = $task.project }
            if ($task.priority) { $this.Fields.priority.Value = $task.priority }
            if ($task.status) { $this.Fields.status.Value = $task.status }
            if ($task.tags -and $task.tags.Count -gt 0) {
                $this.Fields.tags.Value = ($task.tags -join ', ')
            }
            if ($task.notes -and $task.notes.Count -gt 0) {
                $this.Fields.notes.Value = ($task.notes -join "`n")
            }
        }
    }

    [string] Show() {
        $this.IsActive = $true
        $this.Result = 'cancel'

        # Save current screen
        $this.SaveScreen()

        try {
            while ($this.IsActive) {
                $this.Draw()
                $key = [Console]::ReadKey($true)
                $this.HandleKey($key)
            }
        } finally {
            # Restore screen
            $this.RestoreScreen()
        }

        return $this.Result
    }

    [void] Draw() {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight

        # Calculate dialog dimensions
        $dialogWidth = [Math]::Min(60, $width - 4)
        $dialogHeight = [Math]::Min(20, $height - 4)
        $dialogX = ($width - $dialogWidth) / 2
        $dialogY = ($height - $dialogHeight) / 2

        # Draw dialog box
        $this.Terminal.DrawBox($dialogX, $dialogY, $dialogWidth, $dialogHeight)

        # Draw title
        $title = if ($this.IsNewTask) { " New Task " } else { " Edit Task " }
        $titleX = $dialogX + ($dialogWidth - $title.Length) / 2
        $this.Terminal.WriteAt($titleX, $dialogY, $title)

        # Draw fields
        $fieldY = $dialogY + 2
        for ($i = 0; $i -lt $this.FieldOrder.Count; $i++) {
            $fieldName = $this.FieldOrder[$i]
            $field = $this.Fields[$fieldName]
            $isCurrentField = ($i -eq $this.CurrentField)

            # Draw field label
            $labelText = $field.Label + ":"
            if ($field.Required) { $labelText += " *" }

            if ($isCurrentField) {
                $this.Terminal.WriteAt($dialogX + 2, $fieldY, "`e[7m") # Reverse video
            }

            $this.Terminal.WriteAt($dialogX + 2, $fieldY, $labelText.PadRight(15))

            # Draw field value
            $valueX = $dialogX + 18
            $valueWidth = $dialogWidth - 20

            switch ($field.Type) {
                'text' {
                    $displayValue = $field.Value
                    if ($displayValue.Length -gt $valueWidth) {
                        $displayValue = $displayValue.Substring(0, $valueWidth - 3) + "..."
                    }
                    $this.Terminal.WriteAt($valueX, $fieldY, $displayValue.PadRight($valueWidth))
                }
                'select' {
                    $displayValue = "< $($field.Value) >"
                    $this.Terminal.WriteAt($valueX, $fieldY, $displayValue.PadRight($valueWidth))
                }
                'textarea' {
                    $lines = $field.Value -split "`n"
                    $displayValue = if ($lines.Count -gt 1) { "$($lines[0])... ($($lines.Count) lines)" } else { $lines[0] }
                    if ($displayValue.Length -gt $valueWidth) {
                        $displayValue = $displayValue.Substring(0, $valueWidth - 3) + "..."
                    }
                    $this.Terminal.WriteAt($valueX, $fieldY, $displayValue.PadRight($valueWidth))
                }
            }

            if ($isCurrentField) {
                $this.Terminal.WriteAt($valueX + $valueWidth, $fieldY, "`e[0m") # Reset formatting
            }

            # Show help text for current field
            if ($isCurrentField -and $field.Help) {
                $helpY = $dialogY + $dialogHeight - 4
                $this.Terminal.WriteAt($dialogX + 2, $helpY, (' ' * ($dialogWidth - 4)))
                $this.Terminal.WriteAt($dialogX + 2, $helpY, "`e[90m$($field.Help)`e[0m")
            }

            $fieldY++
        }

        # Draw buttons
        $buttonY = $dialogY + $dialogHeight - 2
        $buttonText = if ($this.IsNewTask) { " [S]ave   [C]ancel " } else { " [S]ave   [C]ancel   [D]elete " }
        $buttonX = $dialogX + ($dialogWidth - $buttonText.Length) / 2
        $this.Terminal.WriteAt($buttonX, $buttonY, $buttonText)

        # Draw instructions
        $instrY = $dialogY + $dialogHeight - 3
        $instructions = "↑↓: Navigate   Enter: Edit   Tab: Next   Esc: Cancel"
        if ($instructions.Length -gt ($dialogWidth - 4)) {
            $instructions = "↑↓: Nav   Enter: Edit   Esc: Cancel"
        }
        $instrX = $dialogX + ($dialogWidth - $instructions.Length) / 2
        $this.Terminal.WriteAt($instrX, $instrY, "`e[90m$instructions`e[0m")
    }

    [void] HandleKey([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.CurrentField -gt 0) {
                    $this.CurrentField--
                }
            }
            'DownArrow' {
                if ($this.CurrentField -lt ($this.FieldOrder.Count - 1)) {
                    $this.CurrentField++
                }
            }
            'Tab' {
                $this.CurrentField = ($this.CurrentField + 1) % $this.FieldOrder.Count
            }
            'Enter' {
                $this.EditCurrentField()
            }
            'Escape' {
                $this.IsActive = $false
                $this.Result = 'cancel'
            }
            default {
                # Handle shortcut keys
                $char = $key.KeyChar.ToString().ToLower()
                switch ($char) {
                    's' {
                        if ($this.ValidateFields()) {
                            $this.SaveTask()
                            $this.IsActive = $false
                            $this.Result = 'save'
                        }
                    }
                    'c' {
                        $this.IsActive = $false
                        $this.Result = 'cancel'
                    }
                    'd' {
                        if (-not $this.IsNewTask) {
                            $this.IsActive = $false
                            $this.Result = 'delete'
                        }
                    }
                }
            }
        }
    }

    [void] EditCurrentField() {
        $fieldName = $this.FieldOrder[$this.CurrentField]
        $field = $this.Fields[$fieldName]

        switch ($field.Type) {
            'text' {
                $newValue = $this.GetTextInput($field.Label, $field.Value)
                if ($newValue -ne $null) {
                    $field.Value = $newValue
                }
            }
            'select' {
                $field.Value = $this.GetSelectInput($field.Label, $field.Options, $field.Value)
            }
            'textarea' {
                $newValue = $this.GetTextAreaInput($field.Label, $field.Value)
                if ($newValue -ne $null) {
                    $field.Value = $newValue
                }
            }
        }
    }

    [string] GetTextInput([string]$label, [string]$currentValue) {
        $width = [Console]::WindowWidth
        $inputY = [Console]::WindowHeight - 1
        $inputText = $currentValue
        $cursorPos = $inputText.Length
        $startX = $label.Length + 3

        # Clear input line and show prompt
        $this.Terminal.WriteAt(0, $inputY, (' ' * $width))
        $this.Terminal.WriteAt(0, $inputY, "$($label): ")

        while ($true) {
            # Draw current text and cursor
            $displayText = $inputText
            $maxDisplayWidth = $width - $startX - 2

            if ($displayText.Length -gt $maxDisplayWidth) {
                $offset = [Math]::Max(0, $cursorPos - $maxDisplayWidth + 10)
                $displayText = $displayText.Substring($offset)
                $displayCursorPos = $cursorPos - $offset
            } else {
                $displayCursorPos = $cursorPos
            }

            # Clear input area and redraw
            $this.Terminal.WriteAt($startX, $inputY, (' ' * ($width - $startX)))
            $this.Terminal.WriteAt($startX, $inputY, $displayText)

            # Show cursor
            if ($displayCursorPos -ge 0 -and $displayCursorPos -le $displayText.Length) {
                $cursorX = $startX + $displayCursorPos
                if ($cursorX -lt $width) {
                    $cursorChar = if ($displayCursorPos -lt $displayText.Length) { $displayText[$displayCursorPos] } else { ' ' }
                    $this.Terminal.WriteAt($cursorX, $inputY, "`e[7m$cursorChar`e[0m")
                }
            }

            # Get key input
            try {
                $key = [Console]::ReadKey($true)
            } catch {
                return $currentValue
            }

            switch ($key.Key) {
                'Enter' {
                    return $inputText
                }
                'Escape' {
                    return $currentValue
                }
                'Backspace' {
                    if ($cursorPos -gt 0) {
                        $inputText = $inputText.Remove($cursorPos - 1, 1)
                        $cursorPos--
                    }
                }
                'Delete' {
                    if ($cursorPos -lt $inputText.Length) {
                        $inputText = $inputText.Remove($cursorPos, 1)
                    }
                }
                'LeftArrow' {
                    if ($cursorPos -gt 0) {
                        $cursorPos--
                    }
                }
                'RightArrow' {
                    if ($cursorPos -lt $inputText.Length) {
                        $cursorPos++
                    }
                }
                'Home' {
                    $cursorPos = 0
                }
                'End' {
                    $cursorPos = $inputText.Length
                }
                default {
                    # Handle regular character input
                    if ($key.KeyChar -and [char]::IsControl($key.KeyChar) -eq $false) {
                        $inputText = $inputText.Insert($cursorPos, $key.KeyChar)
                        $cursorPos++
                    }
                }
            }
        }
        return $currentValue
    }

    [string] GetSelectInput([string]$label, [array]$options, [string]$currentValue) {
        $currentIndex = $options.IndexOf($currentValue)
        if ($currentIndex -eq -1) { $currentIndex = 0 }

        $nextIndex = ($currentIndex + 1) % $options.Count
        return $options[$nextIndex]
    }

    [string] GetTextAreaInput([string]$label, [string]$currentValue) {
        # Placeholder for multi-line text input
        Write-Host "`nMulti-line input for '$label'"
        Write-Host "Current value: $currentValue"
        Write-Host "Enter new value (Ctrl+D to finish):"
        return $currentValue
    }

    [bool] ValidateFields() {
        foreach ($fieldName in $this.FieldOrder) {
            $field = $this.Fields[$fieldName]
            if ($field.Required -and [string]::IsNullOrWhiteSpace($field.Value)) {
                Write-Host "Field '$($field.Label)' is required" -ForegroundColor Red
                return $false
            }
        }
        return $true
    }

    [void] SaveTask() {
        try {
            $data = Get-PmcData

            if ($this.IsNewTask) {
                # Create new task
                $newId = if ($data.tasks.Count -gt 0) { ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1 } else { 1 }

                $newTask = @{
                    id = $newId
                    text = $this.Fields.text.Value
                    status = $this.Fields.status.Value
                    priority = $this.Fields.priority.Value
                    project = $this.Fields.project.Value
                    created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                    tags = @()
                    notes = @()
                }

                # Process tags
                if ($this.Fields.tags.Value) {
                    $newTask.tags = @($this.Fields.tags.Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                }

                # Process notes
                if ($this.Fields.notes.Value) {
                    $newTask.notes = @($this.Fields.notes.Value -split "`n" | Where-Object { $_.Trim() })
                }

                $data.tasks += $newTask
            } else {
                # Update existing task
                $t = $data.tasks | Where-Object { $_.id -eq $this.Task.id } | Select-Object -First 1
                if ($t) {
                    $t.text = $this.Fields.text.Value
                    $t.status = $this.Fields.status.Value
                    $t.priority = $this.Fields.priority.Value
                    $t.project = $this.Fields.project.Value
                    $t.modified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

                    # Process tags
                    $t.tags = if ($this.Fields.tags.Value) {
                        @($this.Fields.tags.Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                    } else {
                        @()
                    }

                    # Process notes
                    $t.notes = if ($this.Fields.notes.Value) {
                        @($this.Fields.notes.Value -split "`n" | Where-Object { $_.Trim() })
                    } else {
                        @()
                    }
                }
            }

            # Save data (using PMC's standard save function)
            Save-PmcData -Data $data -Action 'task edit via GUI'

        } catch {
            Write-Host "Failed to save task: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void] SaveScreen() {
        # Placeholder for screen saving
    }

    [void] RestoreScreen() {
        # Placeholder for screen restoration
    }
}

# No function exports here; file defines class only
