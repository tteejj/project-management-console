# ProjectWizard.ps1 - Guided project creation wizard
# Provides step-by-step project setup with templates and best practices

class PmcProjectWizard {
    [string]$CurrentStep
    [hashtable]$ProjectData
    [string[]]$Steps
    [int]$StepIndex
    [hashtable]$Templates
    [bool]$IsActive

    PmcProjectWizard() {
        $this.InitializeWizard()
    }

    [void] InitializeWizard() {
        $this.Steps = @(
            'welcome',
            'template',
            'basic_info',
            'goals',
            'timeline',
            'resources',
            'review',
            'create'
        )

        $this.StepIndex = 0
        $this.CurrentStep = $this.Steps[0]
        $this.IsActive = $false

        $this.ProjectData = @{
            name = ""
            description = ""
            template = ""
            goals = @()
            timeline = @{
                start = ""
                deadline = ""
                milestones = @()
            }
            resources = @{
                budget = ""
                team = @()
                tools = @()
            }
            tags = @()
            priority = ""
        }

        $this.InitializeTemplates()
    }

    [void] InitializeTemplates() {
        $this.Templates = @{
            'software' = @{
                name = 'Software Development'
                description = 'Full-stack development project with phases'
                goals = @('Requirements Analysis', 'Design & Architecture', 'Development', 'Testing', 'Deployment')
                timeline_weeks = 12
                suggested_tools = @('IDE', 'Version Control', 'Issue Tracker', 'CI/CD')
                default_tags = @('development', 'software')
            }
            'marketing' = @{
                name = 'Marketing Campaign'
                description = 'Comprehensive marketing campaign planning'
                goals = @('Market Research', 'Strategy Development', 'Content Creation', 'Campaign Launch', 'Analytics')
                timeline_weeks = 8
                suggested_tools = @('Analytics', 'Social Media Tools', 'Design Software', 'Email Platform')
                default_tags = @('marketing', 'campaign')
            }
            'research' = @{
                name = 'Research Project'
                description = 'Academic or business research initiative'
                goals = @('Literature Review', 'Methodology Design', 'Data Collection', 'Analysis', 'Report Writing')
                timeline_weeks = 16
                suggested_tools = @('Research Database', 'Survey Tools', 'Statistical Software', 'Writing Tools')
                default_tags = @('research', 'analysis')
            }
            'event' = @{
                name = 'Event Planning'
                description = 'Conference, meeting, or event organization'
                goals = @('Planning & Budget', 'Venue & Logistics', 'Speaker Coordination', 'Marketing', 'Execution')
                timeline_weeks = 6
                suggested_tools = @('Event Platform', 'Registration System', 'Communication Tools', 'Budget Tracker')
                default_tags = @('event', 'planning')
            }
            'custom' = @{
                name = 'Custom Project'
                description = 'Build your project from scratch'
                goals = @()
                timeline_weeks = 4
                suggested_tools = @()
                default_tags = @()
            }
        }
    }

    [void] Start() {
        try {
            $this.IsActive = $true
            [Console]::Clear()

            while ($this.IsActive -and $this.StepIndex -lt $this.Steps.Count) {
                $this.DrawStep()
                $this.HandleStepInput()
            }

        } catch {
            Write-PmcStyled -Style 'Error' -Text ("Wizard error: {0}" -f $_)
        } finally {
            [Console]::Clear()
        }
    }

    [void] DrawStep() {
        [Console]::Clear()
        $this.DrawHeader()

        switch ($this.CurrentStep) {
            'welcome' { $this.DrawWelcomeStep() }
            'template' { $this.DrawTemplateStep() }
            'basic_info' { $this.DrawBasicInfoStep() }
            'goals' { $this.DrawGoalsStep() }
            'timeline' { $this.DrawTimelineStep() }
            'resources' { $this.DrawResourcesStep() }
            'review' { $this.DrawReviewStep() }
            'create' { $this.DrawCreateStep() }
        }

        $this.DrawFooter()
    }

    [void] DrawHeader() {
        $palette = Get-PmcColorPalette
        $headerColor = Get-PmcColorSequence $palette.Header
        $resetColor = [PmcVT]::Reset()

        $progressBar = $this.GenerateProgressBar()
        $stepName = $this.CurrentStep.Replace('_', ' ').ToUpper()

        Write-Host "$headerColor╭─ PMC Project Creation Wizard ─────────────────────────────────╮$resetColor"
        Write-Host "$headerColor│ Step $($this.StepIndex + 1) of $($this.Steps.Count): $stepName$(' ' * (50 - $stepName.Length))│$resetColor"
        Write-Host "$headerColor│ $progressBar │$resetColor"
        Write-Host "$headerColor╰─────────────────────────────────────────────────────────────────╯$resetColor"
        Write-Host ""
    }

    [string] GenerateProgressBar() {
        $width = 60
        $completed = [Math]::Floor($width * $this.StepIndex / $this.Steps.Count)
        $remaining = $width - $completed

        return ('█' * $completed) + ('░' * $remaining)
    }

    [void] DrawWelcomeStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $highlightColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        Write-Host "$textColor Welcome to the PMC Project Creation Wizard!$resetColor"
        Write-Host ""
        Write-Host "$textColor This wizard will guide you through creating a new project with:$resetColor"
        Write-Host "$highlightColor   ✓ Project templates and best practices$resetColor"
        Write-Host "$highlightColor   ✓ Goal setting and milestone planning$resetColor"
        Write-Host "$highlightColor   ✓ Timeline and deadline management$resetColor"
        Write-Host "$highlightColor   ✓ Resource allocation and team setup$resetColor"
        Write-Host ""
        Write-Host "$textColor The wizard takes about 5 minutes and will create a fully$resetColor"
        Write-Host "$textColor structured project ready for immediate use.$resetColor"
        Write-Host ""
        Write-Host "$highlightColor Press Enter to begin or Esc to cancel$resetColor"
    }

    [void] DrawTemplateStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $highlightColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        Write-Host "$textColor Choose a project template to get started quickly:$resetColor"
        Write-Host ""

        $index = 1
        foreach ($templateKey in $this.Templates.Keys) {
            $template = $this.Templates[$templateKey]
            $isSelected = $this.ProjectData.template -eq $templateKey

            $marker = if ($isSelected) { "$highlightColor►$resetColor" } else { " " }
            $nameColor = if ($isSelected) { $highlightColor } else { $textColor }

            Write-Host "$marker $nameColor$index. $($template.name)$resetColor"
            Write-Host "    $($template.description)"
            Write-Host "    Timeline: ~$($template.timeline_weeks) weeks"
            Write-Host ""
            $index++
        }

        Write-Host "$textColor Enter template number (1-$($this.Templates.Count)) or 'c' for custom:$resetColor"
    }

    [void] DrawBasicInfoStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        $selectedTemplate = if ($this.ProjectData.template) {
            $this.Templates[$this.ProjectData.template].name
        } else {
            "None selected"
        }

        Write-Host "$textColor Project Basic Information:$resetColor"
        Write-Host ""
        Write-Host "$labelColor Template:$resetColor $valueColor$selectedTemplate$resetColor"
        Write-Host ""

        Write-Host "$labelColor Project Name:$resetColor"
        if ($this.ProjectData.name) {
            Write-Host "$valueColor$($this.ProjectData.name)$resetColor"
        } else {
            Write-Host "$textColor[Enter project name]$resetColor"
        }
        Write-Host ""

        Write-Host "$labelColor Description:$resetColor"
        if ($this.ProjectData.description) {
            Write-Host "$valueColor$($this.ProjectData.description)$resetColor"
        } else {
            Write-Host "$textColor[Enter project description]$resetColor"
        }
        Write-Host ""

        if (-not $this.ProjectData.name) {
            Write-Host "$textColor Enter project name: $resetColor" -NoNewline
        } elseif (-not $this.ProjectData.description) {
            Write-Host "$textColor Enter project description: $resetColor" -NoNewline
        } else {
            Write-Host "$textColor Press Enter to continue, 'e' to edit name/description$resetColor"
        }
    }

    [void] DrawGoalsStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        Write-Host "$textColor Project Goals and Milestones:$resetColor"
        Write-Host ""

        if ($this.ProjectData.template -and $this.ProjectData.template -ne 'custom') {
            $template = $this.Templates[$this.ProjectData.template]
            Write-Host "$labelColor Template suggests these goals:$resetColor"
            foreach ($goal in $template.goals) {
                Write-Host "$valueColor  ✓ $goal$resetColor"
            }
            Write-Host ""
            Write-Host "$textColor Press 'a' to accept these goals, 'c' to customize, or 's' to skip:$resetColor"
        } else {
            Write-Host "$labelColor Current Goals:$resetColor"
            if ($this.ProjectData.goals.Count -gt 0) {
                foreach ($goal in $this.ProjectData.goals) {
                    Write-Host "$valueColor  ✓ $goal$resetColor"
                }
            } else {
                Write-Host "$textColor  [No goals defined yet]$resetColor"
            }
            Write-Host ""
            Write-Host "$textColor Enter goal (or 'done' to finish): $resetColor" -NoNewline
        }
    }

    [void] DrawTimelineStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        Write-Host "$textColor Project Timeline:$resetColor"
        Write-Host ""

        Write-Host "$labelColor Start Date:$resetColor $valueColor$($this.ProjectData.timeline.start)$resetColor"
        Write-Host "$labelColor Deadline:$resetColor $valueColor$($this.ProjectData.timeline.deadline)$resetColor"
        Write-Host ""

        if ($this.ProjectData.template -and $this.ProjectData.template -ne 'custom') {
            $template = $this.Templates[$this.ProjectData.template]
            $suggestedEnd = (Get-Date).AddDays($template.timeline_weeks * 7).ToString("yyyy-MM-dd")
            Write-Host "$labelColor Template suggests $($template.timeline_weeks) weeks: $resetColor$valueColor$suggestedEnd$resetColor"
        }

        Write-Host ""
        Write-Host "$textColor Enter start date (YYYY-MM-DD) or 'today': $resetColor" -NoNewline
    }

    [void] DrawResourcesStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Highlight
        $resetColor = [PmcVT]::Reset()

        Write-Host "$textColor Project Resources:$resetColor"
        Write-Host ""

        Write-Host "$labelColor Budget:$resetColor $valueColor$($this.ProjectData.resources.budget)$resetColor"
        Write-Host "$labelColor Team Members:$resetColor $valueColor$($this.ProjectData.resources.team -join ', ')$resetColor"
        Write-Host "$labelColor Tools/Technologies:$resetColor $valueColor$($this.ProjectData.resources.tools -join ', ')$resetColor"
        Write-Host ""

        if ($this.ProjectData.template -and $this.ProjectData.template -ne 'custom') {
            $template = $this.Templates[$this.ProjectData.template]
            if ($template.suggested_tools.Count -gt 0) {
                Write-Host "$labelColor Template suggests these tools:$resetColor"
                foreach ($tool in $template.suggested_tools) {
                    Write-Host "$valueColor  • $tool$resetColor"
                }
                Write-Host ""
            }
        }

        Write-Host "$textColor Enter budget (optional) or press Enter to skip: $resetColor" -NoNewline
    }

    [void] DrawReviewStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Highlight
        $headerColor = Get-PmcColorSequence $palette.Header
        $resetColor = [PmcVT]::Reset()

        Write-Host "$headerColor Review Project Configuration:$resetColor"
        Write-Host ""

        Write-Host "$labelColor Name:$resetColor $valueColor$($this.ProjectData.name)$resetColor"
        Write-Host "$labelColor Description:$resetColor $valueColor$($this.ProjectData.description)$resetColor"
        Write-Host "$labelColor Template:$resetColor $valueColor$($this.Templates[$this.ProjectData.template].name)$resetColor"
        Write-Host ""

        Write-Host "$labelColor Goals ($($this.ProjectData.goals.Count)):$resetColor"
        foreach ($goal in $this.ProjectData.goals) {
            Write-Host "$valueColor  ✓ $goal$resetColor"
        }
        Write-Host ""

        Write-Host "$labelColor Timeline:$resetColor"
        Write-Host "$valueColor  Start: $($this.ProjectData.timeline.start)$resetColor"
        Write-Host "$valueColor  End: $($this.ProjectData.timeline.deadline)$resetColor"
        Write-Host ""

        if ($this.ProjectData.resources.budget) {
            Write-Host "$labelColor Budget:$resetColor $valueColor$($this.ProjectData.resources.budget)$resetColor"
        }

        if ($this.ProjectData.resources.tools.Count -gt 0) {
            Write-Host "$labelColor Tools:$resetColor $valueColor$($this.ProjectData.resources.tools -join ', ')$resetColor"
        }

        Write-Host ""
        Write-Host "$textColor Press 'c' to create project, 'b' to go back, or 'e' to edit: $resetColor" -NoNewline
    }

    [void] DrawCreateStep() {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $successColor = Get-PmcColorSequence $palette.Success
        $resetColor = [PmcVT]::Reset()

        Write-Host "$successColor Creating project...$resetColor"
        Write-Host ""

        try {
            $this.CreateProject()
            Write-Host "$successColor✓ Project '$($this.ProjectData.name)' created successfully!$resetColor"
            Write-Host ""
            Write-Host "$textColor Initial tasks have been created based on your goals.$resetColor"
            Write-Host "$textColor Timeline and milestones are set up.$resetColor"
            Write-Host "$textColor You can now start working on your project.$resetColor"
            Write-Host ""
            Write-Host "$textColor Press any key to continue...$resetColor"

        } catch {
            Write-PmcStyled -Style 'Error' -Text "✗ Error creating project: $_"
            Write-Host ""
            Write-PmcStyled -Style 'Warning' -Text "Press any key to continue..."
        }
    }

    [void] DrawFooter() {
        $footerRow = [PmcTerminalService]::GetHeight() - 3
        $palette = Get-PmcColorPalette
        $footerColor = Get-PmcColorSequence $palette.Footer
        $resetColor = [PmcVT]::Reset()

        [Console]::SetCursorPosition(0, $footerRow)
        Write-Host "$footerColor$('─' * [PmcTerminalService]::GetWidth())$resetColor"

        $footerText = switch ($this.CurrentStep) {
            'welcome' { "Enter:Continue  Esc:Cancel" }
            'create' { "Any key to finish" }
            default { "Enter:Next  B:Back  Esc:Cancel" }
        }

        [Console]::SetCursorPosition(0, $footerRow + 1)
        Write-Host "$footerColor $footerText$resetColor"
    }

    [void] HandleStepInput() {
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'Escape' {
                $this.IsActive = $false
                return
            }
            'B' {
                if ($this.StepIndex -gt 0) {
                    $this.StepIndex--
                    $this.CurrentStep = $this.Steps[$this.StepIndex]
                }
                return
            }
            'Enter' {
                if ($this.CurrentStep -eq 'welcome') {
                    $this.NextStep()
                } elseif ($this.CanProceedFromCurrentStep()) {
                    $this.NextStep()
                }
                return
            }
        }

        # Handle step-specific input
        switch ($this.CurrentStep) {
            'template' { $this.HandleTemplateInput($key) }
            'basic_info' { $this.HandleBasicInfoInput($key) }
            'goals' { $this.HandleGoalsInput($key) }
            'timeline' { $this.HandleTimelineInput($key) }
            'resources' { $this.HandleResourcesInput($key) }
            'review' { $this.HandleReviewInput($key) }
            'create' { $this.IsActive = $false }
        }
    }

    [void] HandleTemplateInput([ConsoleKeyInfo]$key) {
        $templateKeys = @($this.Templates.Keys)
        $char = $key.KeyChar.ToString()

        if ($char -match '^[1-5]$') {
            $index = [int]$char - 1
            if ($index -lt $templateKeys.Count) {
                $this.ProjectData.template = $templateKeys[$index]
                $this.NextStep()
            }
        } elseif ($char.ToLower() -eq 'c') {
            $this.ProjectData.template = 'custom'
            $this.NextStep()
        }
    }

    [void] HandleBasicInfoInput([ConsoleKeyInfo]$key) {
        if (-not $this.ProjectData.name) {
            $name = $this.ReadLine("Enter project name: ")
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $this.ProjectData.name = $name.Trim()
            }
        } elseif (-not $this.ProjectData.description) {
            $description = $this.ReadLine("Enter project description: ")
            if (-not [string]::IsNullOrWhiteSpace($description)) {
                $this.ProjectData.description = $description.Trim()
            }
        } elseif ($key.KeyChar.ToString().ToLower() -eq 'e') {
            # Edit mode - allow re-entering values
            $choice = $this.ReadLine("Edit (n)ame or (d)escription? ")
            if ($choice.ToLower() -eq 'n') {
                $this.ProjectData.name = ""
            } elseif ($choice.ToLower() -eq 'd') {
                $this.ProjectData.description = ""
            }
        }
    }

    [void] HandleGoalsInput([ConsoleKeyInfo]$key) {
        $char = $key.KeyChar.ToString().ToLower()

        if ($this.ProjectData.template -and $this.ProjectData.template -ne 'custom' -and $this.ProjectData.goals.Count -eq 0) {
            switch ($char) {
                'a' {
                    # Accept template goals
                    $template = $this.Templates[$this.ProjectData.template]
                    $this.ProjectData.goals = $template.goals
                    $this.NextStep()
                }
                'c' {
                    # Customize goals - fall through to manual entry
                }
                's' {
                    # Skip goals
                    $this.NextStep()
                }
            }
        } else {
            # Manual goal entry
            $goal = $this.ReadLine("Enter goal (or 'done' to finish): ")
            if ($goal.ToLower() -eq 'done') {
                $this.NextStep()
            } elseif (-not [string]::IsNullOrWhiteSpace($goal)) {
                $this.ProjectData.goals += $goal.Trim()
            }
        }
    }

    [void] HandleTimelineInput([ConsoleKeyInfo]$key) {
        if (-not $this.ProjectData.timeline.start) {
            $start = $this.ReadLine("Enter start date (YYYY-MM-DD) or 'today': ")
            if ($start.ToLower() -eq 'today') {
                $this.ProjectData.timeline.start = (Get-Date).ToString("yyyy-MM-dd")
            } elseif ($start -match '^\d{4}-\d{2}-\d{2}$') {
                $this.ProjectData.timeline.start = $start
            }
        } elseif (-not $this.ProjectData.timeline.deadline) {
            $end = $this.ReadLine("Enter deadline (YYYY-MM-DD): ")
            if ($end -match '^\d{4}-\d{2}-\d{2}$') {
                $this.ProjectData.timeline.deadline = $end
                $this.NextStep()
            }
        }
    }

    [void] HandleResourcesInput([ConsoleKeyInfo]$key) {
        if (-not $this.ProjectData.resources.budget) {
            $budget = $this.ReadLine("Enter budget (optional): ")
            $this.ProjectData.resources.budget = $budget.Trim()
        } else {
            $this.NextStep()
        }
    }

    [void] HandleReviewInput([ConsoleKeyInfo]$key) {
        $char = $key.KeyChar.ToString().ToLower()

        switch ($char) {
            'c' { $this.NextStep() }
            'e' {
                # Edit mode - go back to basic info
                $this.StepIndex = 2  # basic_info step
                $this.CurrentStep = $this.Steps[$this.StepIndex]
            }
        }
    }

    [string] ReadLine([string]$prompt) {
        Write-PmcStyled -Style 'Body' -Text $prompt -NoNewline
        return [Console]::ReadLine()
    }

    [bool] CanProceedFromCurrentStep() {
        switch ($this.CurrentStep) {
            'template' {
                return -not [string]::IsNullOrWhiteSpace($this.ProjectData.template)
            }
            'basic_info' {
                return (-not [string]::IsNullOrWhiteSpace($this.ProjectData.name)) -and (-not [string]::IsNullOrWhiteSpace($this.ProjectData.description))
            }
            'goals' {
                return $true  # Goals are optional
            }
            'timeline' {
                return -not [string]::IsNullOrWhiteSpace($this.ProjectData.timeline.start)
            }
            'resources' {
                return $true  # Resources are optional
            }
            'review' {
                return $true
            }
            default {
                return $true
            }
        }
        return $true
    }

    [void] NextStep() {
        if ($this.StepIndex -lt ($this.Steps.Count - 1)) {
            $this.StepIndex++
            $this.CurrentStep = $this.Steps[$this.StepIndex]
        }
    }

    [void] CreateProject() {
        # Build PMC command to create project
        $createCmd = "project add '$($this.ProjectData.name)'"

        if ($this.ProjectData.description) {
            $createCmd += " --description '$($this.ProjectData.description)'"
        }

        # Execute project creation
        Invoke-PmcCommand $createCmd

        # Add initial tasks based on goals
        foreach ($goal in $this.ProjectData.goals) {
            $taskCmd = "task add '$goal' @$($this.ProjectData.name.Replace(' ', '_'))"
            if ($this.ProjectData.timeline.deadline) {
                $taskCmd += " due:$($this.ProjectData.timeline.deadline)"
            }
            Invoke-PmcCommand $taskCmd
        }

        # Set project as current context if supported
        try {
            Invoke-PmcCommand "project focus '$($this.ProjectData.name)'"
        } catch {
            # Focus command might not exist in all PMC versions
        }
    }

    [hashtable] StartUniversal() {
        $this.IsActive = $true
        # 1) Template selection via universal display
        $templateRows = @()
        foreach ($k in $this.Templates.Keys) {
            $t = $this.Templates[$k]
            $templateRows += [pscustomobject]@{ key=$k; name=$t.name; description=$t.description; weeks=$t.timeline_weeks }
        }
        $tplColumns = @{
            'name' = @{ Header='Template'; Width=24; Alignment='Left'; Editable=$false }
            'description' = @{ Header='Description'; Width=40; Alignment='Left'; Editable=$false }
            'weeks' = @{ Header='Weeks'; Width=6; Alignment='Right'; Editable=$false }
        }
        Show-PmcTip "Select a template, then press Q to confirm"
        $sel = Invoke-PmcWizardListSelection -Title 'PROJECT TEMPLATES' -Rows $templateRows -Columns $tplColumns
        if ($sel -ge 0 -and $sel -lt $templateRows.Count) { $this.ProjectData.template = [string]$templateRows[$sel].key } else { $this.ProjectData.template = 'custom' }

        # 2) Basic info form
        $initial = [pscustomobject]@{
            name = $this.ProjectData.name
            description = $this.ProjectData.description
        }
        $formColumns = @{
            'name' = @{ Header='Project Name'; Width=30; Alignment='Left'; Editable=$true }
            'description' = @{ Header='Description'; Width=50; Alignment='Left'; Editable=$true }
        }
        Show-PmcTip "Edit fields. Enter to save a cell. Q to continue"
        $updated = Invoke-PmcWizardForm -Title 'PROJECT DETAILS' -Columns $formColumns -Object $initial
        if ($updated) { $this.ProjectData.name = [string]$updated.name; $this.ProjectData.description = [string]$updated.description }

        # 3) Goals form (semicolon-separated)
        $goalsSeed = ''
        if ($this.ProjectData.template -and $this.Templates.ContainsKey($this.ProjectData.template)) {
            $goalsSeed = ($this.Templates[$this.ProjectData.template].goals -join '; ')
        }
        if (@($this.ProjectData.goals).Count -gt 0) { $goalsSeed = ($this.ProjectData.goals -join '; ') }
        $goalsObj = [pscustomobject]@{ goals = $goalsSeed }
        $goalsCols = @{
            'goals' = @{ Header='Goals (separate with ";")'; Width=70; Alignment='Left'; Editable=$true }
        }
        Show-PmcTip "Enter goals separated by ';'. Q to continue"
        $goalsOut = Invoke-PmcWizardForm -Title 'PROJECT GOALS' -Columns $goalsCols -Object $goalsObj
        if ($goalsOut -and $goalsOut.goals) {
            $this.ProjectData.goals = @(([string]$goalsOut.goals).Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
        }

        # 4) Timeline form
        $suggestedEnd = ''
        if ($this.ProjectData.template -and $this.Templates.ContainsKey($this.ProjectData.template)) {
            $weeks = [int]$this.Templates[$this.ProjectData.template].timeline_weeks
            $suggestedEnd = (Get-Date).AddDays($weeks * 7).ToString('yyyy-MM-dd')
        }
        $timelineObj = [pscustomobject]@{ start = ($this.ProjectData.timeline.start ?? ''); deadline = ($this.ProjectData.timeline.deadline ?? $suggestedEnd) }
        $timeCols = @{
            'start' = @{ Header='Start (YYYY-MM-DD)'; Width=18; Alignment='Left'; Editable=$true }
            'deadline' = @{ Header='Deadline (YYYY-MM-DD)'; Width=22; Alignment='Left'; Editable=$true }
        }
        Show-PmcTip "Edit dates. Q to continue"
        $timeOut = Invoke-PmcWizardForm -Title 'PROJECT TIMELINE' -Columns $timeCols -Object $timelineObj
        if ($timeOut) { $this.ProjectData.timeline.start = [string]$timeOut.start; $this.ProjectData.timeline.deadline = [string]$timeOut.deadline }

        # 5) Resources form
        $resObj = [pscustomobject]@{
            budget = ($this.ProjectData.resources.budget ?? '')
            team = (($this.ProjectData.resources.team ?? @()) -join ', ')
            tools = (($this.ProjectData.resources.tools ?? @()) -join ', ')
        }
        $resCols = @{
            'budget' = @{ Header='Budget'; Width=12; Alignment='Left'; Editable=$true }
            'team' = @{ Header='Team (comma separated)'; Width=40; Alignment='Left'; Editable=$true }
            'tools' = @{ Header='Tools (comma separated)'; Width=40; Alignment='Left'; Editable=$true }
        }
        Show-PmcTip "Edit resources. Q to continue"
        $resOut = Invoke-PmcWizardForm -Title 'PROJECT RESOURCES' -Columns $resCols -Object $resObj
        if ($resOut) {
            $this.ProjectData.resources.budget = [string]$resOut.budget
            $this.ProjectData.resources.team = @(([string]$resOut.team).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
            $this.ProjectData.resources.tools = @(([string]$resOut.tools).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
        }

        # 6) Review summary via universal display
        $summaryRows = @(
            [pscustomobject]@{ Field='Name'; Value=$this.ProjectData.name }
            [pscustomobject]@{ Field='Description'; Value=$this.ProjectData.description }
            [pscustomobject]@{ Field='Template'; Value=($this.Templates[$this.ProjectData.template].name ?? 'Custom') }
            [pscustomobject]@{ Field='Start'; Value=$this.ProjectData.timeline.start }
            [pscustomobject]@{ Field='Deadline'; Value=$this.ProjectData.timeline.deadline }
            [pscustomobject]@{ Field='Goals'; Value=($this.ProjectData.goals -join '; ') }
            [pscustomobject]@{ Field='Team'; Value=($this.ProjectData.resources.team -join ', ') }
            [pscustomobject]@{ Field='Tools'; Value=($this.ProjectData.resources.tools -join ', ') }
        )
        $sumCols = @{
            'Field' = @{ Header='Field'; Width=16; Alignment='Left'; Editable=$false }
            'Value' = @{ Header='Value'; Width=70; Alignment='Left'; Editable=$false }
        }
        Show-PmcCustomGrid -Domain 'wizard' -Columns $sumCols -Data $summaryRows -Title 'REVIEW' -Interactive:$false
        Show-PmcTip "Press Enter to create, or type 'b' to abort"
        return @{}
    }
}

function Invoke-PmcProjectWizard {
    <#
    .SYNOPSIS
    Launches the guided project creation wizard

    .DESCRIPTION
    Opens a full-screen interactive wizard that guides users through
    creating a new project with templates, goals, timelines, and resources.

    .EXAMPLE
    Invoke-PmcProjectWizard
    Launches the project creation wizard
    #>

    try {
        $wizard = [PmcProjectWizard]::new()
        # Use universal display version
        $wizard.StartUniversal() | Out-Null
        # Create project using gathered data
        $wizard.CreateProject()
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Error launching project wizard: {0}" -f $_)
    }
}

# Export for module use
Export-ModuleMember -Function Invoke-PmcProjectWizard

# Helper functions for wizard universal display integration
function Invoke-PmcWizardListSelection {
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [array]$Rows,
        [Parameter(Mandatory)] [hashtable]$Columns
    )
    try {
        $renderer = [PmcGridRenderer]::new($Columns, @('wizard'), @{})
        Write-PmcStyled -Style 'Title' -Text "`n$Title"
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        $renderer.StartInteractive($Rows)
        return [int]$renderer.SelectedRow
    } catch {
        return 0
    }
}

function Invoke-PmcWizardForm {
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [hashtable]$Columns,
        [Parameter(Mandatory)] [pscustomobject]$Object
    )
    try {
        $renderer = [PmcGridRenderer]::new($Columns, @('wizard'), @{})
        Write-PmcStyled -Style 'Title' -Text "`n$Title"
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        $renderer.StartInteractive(@($Object))
        if ($renderer.CurrentData -and @($renderer.CurrentData).Count -gt 0) {
            return $renderer.CurrentData[0]
        }
        return $Object
    } catch {
        return $Object
    }
}
