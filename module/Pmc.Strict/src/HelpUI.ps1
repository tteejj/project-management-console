# HelpUI.ps1 - Rich Help System with Categorized Command Browser
# Enhanced with t2.ps1's sophisticated help experience

Set-StrictMode -Version Latest

# Help system state - now managed by centralized state
# State initialization moved to State.ps1

# Initialize help state variables at module level
$Script:PmcHelpState = @{
    CurrentCategory = 'All'
    SelectedCommand = 0
    ViewMode = 'Categories'
}

# Search results cache for help
$Script:PmcHelpSearchResults = @()
# Command categories for organized browsing - populated from State.ps1
$commandCategories = @{
    'Task Management' = @(
        @{ Command = 'task add'; Desc = 'Add new task with metadata'; Example = 'task add "Fix bug" @project p1 due:tomorrow' },
        @{ Command = 'task list'; Desc = 'List pending tasks'; Example = 'task list' },
        @{ Command = 'task done'; Desc = 'Complete tasks'; Example = 'task done 1,2,3' },
        @{ Command = 'task update'; Desc = 'Update task properties'; Example = 'task update 1 @newproject p2' },
        @{ Command = 'task delete'; Desc = 'Delete tasks'; Example = 'task delete 1,2' },
        @{ Command = 'task move'; Desc = 'Move task to project'; Example = 'task move 1 @newproject' },
        @{ Command = 'task search'; Desc = 'Search tasks by text'; Example = 'task search bug' },
        @{ Command = 'task edit'; Desc = 'Interactive task editor'; Example = 'task edit 1' }
    )
    'Quick Actions' = @(
        @{ Command = 'add'; Desc = 'Quick add task'; Example = 'add "Fix login bug" @web p1' },
        @{ Command = 'done'; Desc = 'Quick complete tasks'; Example = 'done 1,2,3' },
        @{ Command = 'delete'; Desc = 'Quick delete tasks'; Example = 'delete 1' },
        @{ Command = 'list'; Desc = 'Quick list tasks'; Example = 'list' },
        @{ Command = 'agenda'; Desc = 'Show daily agenda'; Example = 'agenda' },
        @{ Command = 'today'; Desc = 'Tasks due today'; Example = 'today' },
        @{ Command = 'tomorrow'; Desc = 'Tasks due tomorrow'; Example = 'tomorrow' },
        @{ Command = 'overdue'; Desc = 'Overdue tasks'; Example = 'overdue' }
    )
    'Project Management' = @(
        @{ Command = 'project add'; Desc = 'Create new project'; Example = 'project add "Website Redesign"' },
        @{ Command = 'project list'; Desc = 'List all projects'; Example = 'project list' },
        @{ Command = 'project view'; Desc = 'View project details'; Example = 'project view web' },
        @{ Command = 'project stats'; Desc = 'Project statistics'; Example = 'project stats web' },
        @{ Command = 'project archive'; Desc = 'Archive completed project'; Example = 'project archive oldproject' },
        @{ Command = 'projects'; Desc = 'Quick project dashboard'; Example = 'projects' }
    )
    'Time Tracking' = @(
        @{ Command = 'time log'; Desc = 'Log time entry'; Example = 'time log @project 2024-01-15 2.5h "Development work"' },
        @{ Command = 'time list'; Desc = 'List time entries'; Example = 'time list' },
        @{ Command = 'time report'; Desc = 'Time reports'; Example = 'time report week' },
        @{ Command = 'timer start'; Desc = 'Start timer'; Example = 'timer start @project' },
        @{ Command = 'timer stop'; Desc = 'Stop timer'; Example = 'timer stop' },
        @{ Command = 'timer status'; Desc = 'Show timer status'; Example = 'timer status' }
    )
    'Views & Filters' = @(
        @{ Command = 'view today'; Desc = 'Tasks due today'; Example = 'view today' },
        @{ Command = 'view overdue'; Desc = 'Overdue tasks'; Example = 'view overdue' },
        @{ Command = 'view blocked'; Desc = 'Tasks with dependencies'; Example = 'view blocked' },
        @{ Command = 'view projects'; Desc = 'Project dashboard'; Example = 'view projects' },
        @{ Command = 'agenda'; Desc = 'Daily agenda view'; Example = 'agenda' },
        @{ Command = 'week'; Desc = 'Weekly view'; Example = 'week' },
        @{ Command = 'month'; Desc = 'Monthly view'; Example = 'month' }
    )
    'Advanced Features' = @(
        @{ Command = 'dep add'; Desc = 'Add task dependency'; Example = 'dep add 1 depends:2' },
        @{ Command = 'focus set'; Desc = 'Set project context'; Example = 'focus set @project' },
        @{ Command = 'system undo'; Desc = 'Undo last action'; Example = 'undo' },
        @{ Command = 'excel import'; Desc = 'Import Excel T2020 data'; Example = 'excel import' },
        @{ Command = 'stats'; Desc = 'Productivity statistics'; Example = 'stats' },
        @{ Command = 'template save'; Desc = 'Save task template'; Example = 'template save bug-report' }
    )
    'Configuration' = @(
        @{ Command = 'config show'; Desc = 'Show configuration'; Example = 'config show' },
        @{ Command = 'config edit'; Desc = 'Interactive config editor'; Example = 'config edit' },
        @{ Command = 'config icons'; Desc = 'Set icon mode'; Example = 'config icons ascii' },
        @{ Command = 'theme reset'; Desc = 'Reset theme to default'; Example = 'theme reset' }
    )
}

# Initialize Script-level command categories
$Script:PmcCommandCategories = $commandCategories

function Show-PmcSmartHelp {
    <#
    .SYNOPSIS
    Display smart help system with categorized command browser

    .DESCRIPTION
    Rich interactive help system based on t2.ps1's help experience:
    - Categorized command browser
    - Interactive navigation with arrow keys
    - Search and filter capabilities
    - Command examples and usage patterns
    - Context-sensitive help
    #>

    Clear-Host

    # Initialize help state
    if (-not $Script:PmcHelpState) {
        $Script:PmcHelpState = @{
            CurrentCategory = 'All'
            SelectedCommand = 0
            ViewMode = 'Categories'
        }
    } else {
        $Script:PmcHelpState.CurrentCategory = 'All'
        $Script:PmcHelpState.SelectedCommand = 0
        $Script:PmcHelpState.ViewMode = 'Categories'
    }

    # Initialize command categories if not set
    if (-not $Script:PmcCommandCategories) {
        $Script:PmcCommandCategories = $commandCategories
    }

    try {
        $render = {
            Clear-Host
            Show-PmcHelpHeader
            Show-PmcHelpNavigation
            Show-PmcHelpContent
            Write-Host ""
            Write-PmcStyled -Style 'Muted' -Text "  Navigation: ↑/↓ browse, Enter select, B back, C categories, S search, Q quit"
            Write-Host ""
        }

        & $render

        while ($true) {
            try {
                $key = [Console]::ReadKey($true)
            } catch {
                break
            }

            switch ($key.Key) {
                'UpArrow' {
                    if ($Script:PmcHelpState.SelectedCommand -gt 0) { $Script:PmcHelpState.SelectedCommand-- }
                    & $render; continue
                }
                'DownArrow' {
                    $max = 0
                    if ($Script:PmcHelpState.ViewMode -eq 'Categories') {
                        $max = (@($Script:PmcCommandCategories.Keys)).Count - 1
                    } elseif ($Script:PmcHelpState.ViewMode -eq 'Commands' -or $Script:PmcHelpState.ViewMode -eq 'Examples') {
                        $cmds = if ($Script:PmcHelpState.CurrentCategory -eq 'All') { $all=@(); foreach ($v in $Script:PmcCommandCategories.Values) { $all += $v }; $all } else { $Script:PmcCommandCategories[$Script:PmcHelpState.CurrentCategory] }
                        $max = $cmds.Count - 1
                    }
                    if ($Script:PmcHelpState.SelectedCommand -lt $max) { $Script:PmcHelpState.SelectedCommand++ }
                    & $render; continue
                }
                'Enter' {
                    if ($Script:PmcHelpState.ViewMode -eq 'Categories') {
                        $keys = @($Script:PmcCommandCategories.Keys)
                        if ($keys.Count -gt 0) {
                            $idx = [Math]::Max(0, [Math]::Min($Script:PmcHelpState.SelectedCommand, $keys.Count-1))
                            $Script:PmcHelpState.CurrentCategory = $keys[$idx]
                            $Script:PmcHelpState.ViewMode = 'Commands'
                            $Script:PmcHelpState.SelectedCommand = 0
                        }
                    } elseif ($Script:PmcHelpState.ViewMode -eq 'Commands') {
                        $Script:PmcHelpState.ViewMode = 'Examples'
                    } else {
                        $Script:PmcHelpState.ViewMode = 'Categories'
                    }
                    & $render; continue
                }
                'LeftArrow' { $Script:PmcHelpState.ViewMode = 'Categories'; $Script:PmcHelpState.SelectedCommand = 0; & $render; continue }
                'RightArrow' {
                    if ($Script:PmcHelpState.ViewMode -eq 'Categories') {
                        $keys = @($Script:PmcCommandCategories.Keys)
                        if ($keys.Count -gt 0) {
                            $idx = [Math]::Max(0, [Math]::Min($Script:PmcHelpState.SelectedCommand, $keys.Count-1))
                            $Script:PmcHelpState.CurrentCategory = $keys[$idx]
                            $Script:PmcHelpState.ViewMode = 'Commands'
                            $Script:PmcHelpState.SelectedCommand = 0
                            & $render; continue
                        }
                    } elseif ($Script:PmcHelpState.ViewMode -eq 'Commands') {
                        $Script:PmcHelpState.ViewMode = 'Examples'; & $render; continue
                    } else { continue }
                }
                'S' {
                    Show-PmcHelpSearch
                    & $render; continue
                }
                'B' { $Script:PmcHelpState.ViewMode = 'Categories'; $Script:PmcHelpState.SelectedCommand = 0; & $render; continue }
                'C' { $Script:PmcHelpState.ViewMode = 'Categories'; $Script:PmcHelpState.SelectedCommand = 0; & $render; continue }
                'Q' { return }
                'Escape' { return }
                default { continue }
            }
        }

    } catch {
        Write-PmcDebug -Level 1 -Category 'HELP' -Message "Smart help error: $_"
        Write-PmcStyled -Style 'Error' -Text ("Help system error: {0}" -f $_)
    }
}

function Show-PmcHelpHeader {
    Write-Host ""
    $title = "  PMC COMMAND REFERENCE"
    $width = [Math]::Max(70, $title.Length + 4)
    $border = '+' + ('-' * ($width - 2)) + '+'
    Write-PmcStyled -Style 'Border' -Text $border
    Write-PmcStyled -Style 'Title'  -Text ('| ' + $title.PadRight($width - 4) + ' |')
    Write-PmcStyled -Style 'Border' -Text $border
    Write-Host ""
}

function Show-PmcHelpNavigation {
    $categoryCount = $Script:PmcCommandCategories.Count
    $totalCommands = ($Script:PmcCommandCategories.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum

    Write-PmcStyled -Style 'Info' -Text "  📚 Categories: $categoryCount" -NoNewline
    Write-PmcStyled -Style 'Success' -Text "  |  📝 Commands: $totalCommands" -NoNewline
    Write-PmcStyled -Style 'Warning' -Text "  |  🔍 Mode: $($Script:PmcHelpState.ViewMode)"
    Write-Host ""
}

function Show-PmcHelpContent {
    switch ($Script:PmcHelpState.ViewMode) {
        'Categories' { Show-PmcHelpCategories }
        'Commands' { Show-PmcHelpCommands }
        'Examples' { Show-PmcHelpExamples }
        'Search' { Show-PmcHelpSearch }
        default { Show-PmcHelpCategories }
    }
}

function Show-PmcHelpCategories {
    Write-PmcStyled -Style 'Warning' -Text "  Command Categories:"
    Write-PmcStyled -Style 'Border' -Text "  ─────────────────"

    $categoryIndex = 0
    foreach ($category in $Script:PmcCommandCategories.GetEnumerator()) {
        $commandCount = $category.Value.Count
        $isSelected = ($categoryIndex -eq $Script:PmcHelpState.SelectedCommand)

        $prefix = "    "
        if ($isSelected) { $prefix = "  ► " }
        $color = "Gray"
        if ($isSelected) { $color = "White" }
        $bgColor = $null
        if ($isSelected) { $bgColor = "DarkBlue" }

        $displayText = "$($category.Key) ($commandCount commands)"

        $style = 'Body'
        if ($isSelected) { $style = 'Header' }
        Write-PmcStyled -Style $style -Text ("$prefix$displayText")

        $categoryIndex++
    }

    Write-Host ""
    Write-PmcStyled -Style 'Muted' -Text "  💡 Press Enter to view commands in selected category"
}

function Show-PmcHelpCommands {
    if ($Script:PmcHelpState.CurrentCategory -eq '__SEARCH__') {
        $commands = @($Script:PmcHelpSearchResults)
    }
    elseif ($Script:PmcHelpState.CurrentCategory -eq 'All') {
        $commands = @()
        foreach ($category in $Script:PmcCommandCategories.Values) {
            $commands += $category
        }
    } else {
        $commands = $Script:PmcCommandCategories[$Script:PmcHelpState.CurrentCategory]
    }

    if (-not $commands) {
        Write-PmcStyled -Style 'Warning' -Text "  No commands found"
        return
    }

    $categoryText = "All Commands"
    if ($Script:PmcHelpState.CurrentCategory -eq '__SEARCH__') { $categoryText = 'Search Results' }
    elseif ($Script:PmcHelpState.CurrentCategory -ne 'All') { $categoryText = $Script:PmcHelpState.CurrentCategory }
    Write-PmcStyled -Style 'Warning' -Text "  ${categoryText}:"
    Write-PmcStyled -Style 'Border' -Text "  $('─' * ($categoryText.Length + 1))"

    for ($i = 0; $i -lt $commands.Count; $i++) {
        $cmd = $commands[$i]
        $isSelected = ($i -eq $Script:PmcHelpState.SelectedCommand)

        $prefix = "    "
        if ($isSelected) { $prefix = "  ► " }
        $color = "Cyan"
        if ($isSelected) { $color = "White" }
        $bgColor = $null
        if ($isSelected) { $bgColor = "DarkBlue" }

        $displayText = "{0,-18} {1}" -f $cmd.Command, $cmd.Desc

        $style2 = 'Info'
        if ($isSelected) { $style2 = 'Header' }
        Write-PmcStyled -Style $style2 -Text ("$prefix$displayText")
    }

    Write-Host ""
    Write-PmcStyled -Style 'Muted' -Text "  💡 Press Enter to view examples for selected command"
    Write-PmcStyled -Style 'Muted' -Text "  💡 Press B to go back to categories"
}

function Show-PmcHelpSearch {
    try {
        $query = Read-Host "  Search commands (text)"
        if (-not $query) { return }

        $all = @()
        foreach ($category in $Script:PmcCommandCategories.Values) { $all += $category }
        $q = $query.ToLowerInvariant()
        $Script:PmcHelpSearchResults = @(
            $all | Where-Object {
                try {
                    $_.Command.ToLower().Contains($q) -or ($_.Desc -and $_.Desc.ToLower().Contains($q))
                } catch { $false }
            }
        )

        $Script:PmcHelpState.CurrentCategory = '__SEARCH__'
        $Script:PmcHelpState.ViewMode = 'Commands'
        $Script:PmcHelpState.SelectedCommand = 0
    } catch {
        Write-PmcDebug -Level 1 -Category 'HELP' -Message ("Search failed: {0}" -f $_)
    }
}

function Show-PmcHelpExamples {
    if ($Script:PmcHelpState.CurrentCategory -eq 'All') {
        $commands = @()
        foreach ($category in $Script:PmcCommandCategories.Values) {
            $commands += $category
        }
    } else {
        $commands = $Script:PmcCommandCategories[$Script:PmcHelpState.CurrentCategory]
    }

    if (-not $commands -or $Script:PmcHelpState.SelectedCommand -ge $commands.Count) {
        Write-PmcStyled -Style 'Warning' -Text "  Command not found"
        return
    }

    $cmd = $commands[$Script:PmcHelpState.SelectedCommand]

    Write-PmcStyled -Style 'Warning' -Text "  Command: $($cmd.Command)"
    Write-PmcStyled -Style 'Border' -Text ("  $('─' * ("Command: " + $($cmd.Command)).Length)")
    Write-Host ""
    Write-PmcStyled -Style 'Body' -Text "  Description: $($cmd.Desc)"
    Write-Host ""
    Write-PmcStyled -Style 'Success' -Text "  Example:"
    Write-PmcStyled -Style 'Info' -Text ("    {0}" -f $cmd.Example)
    Write-Host ""

    # Add syntax help for the command
    $syntaxHints = Get-PmcCommandSyntax -Command $cmd.Command
    if ($syntaxHints) {
        Write-PmcStyled -Style 'Success' -Text "  Syntax:"
        foreach ($hint in $syntaxHints) {
            Write-PmcStyled -Style 'Info' -Text ("    {0}" -f $hint)
        }
        Write-Host ""
    }

    Write-PmcStyled -Style 'Muted' -Text "  💡 Press B to go back to command list"
}

function Get-PmcCommandSyntax {
    param([string]$Command)

    $syntax = @()

    switch ($Command.ToLower()) {
        'task add' {
            $syntax = @(
                'task add "<description>" [@project] [p1-p3] [due:date] [#tags]',
                '  @project    - Assign to project (e.g., @web, @mobile)',
                '  p1-p3 / !!! - Set priority (p1=high, p3=low)',
                '  due:date    - Set due date (due:today, due:+1w, due:2024-12-25)',
                '  #tags       - Add tags (#bug, #feature, #urgent)'
            )
        }
        'add' {
            $syntax = @(
                'add "<description>" [@project] [p1-p3] [due:date] [#tags]',
                'Quick shortcut for task add with same parameters'
            )
        }
        'time log' {
            $syntax = @(
                'time log @project [date] [hours] ["description"]',
                '  @project     - Project to log time against',
                '  date         - Date in YYYY-MM-DD format (default: today)',
                '  hours        - Hours worked (e.g., 2.5h, 90m)',
                '  description  - Work description in quotes'
            )
        }
        'focus set' {
            $syntax = @(
                'focus set @project',
                'Sets project context for subsequent commands'
            )
        }
        default {
            # Generic syntax for most commands
            if ($Command.Contains(' ')) {
                $parts = $Command -split ' ', 2
                $syntax = @("$($parts[0]) $($parts[1]) [arguments...]")
            } else {
                $syntax = @("$Command [arguments...]")
            }
        }
    }

    return $syntax
}

function Show-PmcHelpAllView {
    <#
    .SYNOPSIS
    Show comprehensive help listing all commands with descriptions

    .DESCRIPTION
    Display all available PMC commands organized by category
    Similar to t2.ps1's 'help all' command
    #>

    Clear-Host
    Show-PmcHelpHeader

    Write-PmcStyled -Style 'Warning' -Text "  All PMC Commands by Category:"
    Write-PmcStyled -Style 'Border' -Text "  --------------------------------"
    Write-Host ""

    foreach ($category in $Script:PmcCommandCategories.GetEnumerator()) {
        Write-PmcStyled -Style 'Info' -Text ("  [$($category.Key)]")
        Write-Host ""

        foreach ($cmd in $category.Value) {
            Write-PmcStyled -Style 'Muted' -Text ("    {0,-20} {1}" -f $cmd.Command, $cmd.Desc)
        }
        Write-Host ""
    }

    # Add metadata syntax reference
    Write-PmcStyled -Style 'Warning' -Text "  Metadata Syntax:"
    Write-Host ""
    Write-PmcStyled -Style 'Muted' -Text "    @project      Assign to project"
    Write-PmcStyled -Style 'Muted' -Text "    p1, p2, p3    Set priority (high to low)"
    Write-PmcStyled -Style 'Muted' -Text "    due:date      Set due date (today, +1w, 2024-12-25)"
    Write-PmcStyled -Style 'Muted' -Text "    #tag          Add tags"
    Write-Host ""

    Write-Host "  💡 Use 'help' for interactive browser" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-PmcCommandByName {
    param([string]$CommandName)

    foreach ($category in $Script:PmcCommandCategories.Values) {
        $found = $category | Where-Object { $_.Command -eq $CommandName }
        if ($found) { return $found }
    }
    return $null
}

function Search-PmcCommands {
    param([string]$SearchTerm)

    $results = @()

    foreach ($categoryEntry in $Script:PmcCommandCategories.GetEnumerator()) {
        foreach ($cmd in $categoryEntry.Value) {
            if ($cmd.Command.Contains($SearchTerm) -or $cmd.Desc.Contains($SearchTerm)) {
                $results += [PSCustomObject]@{
                    Command = $cmd.Command
                    Description = $cmd.Desc
                    Category = $categoryEntry.Key
                    Example = $cmd.Example
                }
            }
        }
    }

    return $results
}

function Show-PmcQuickHelp {
    <#
    .SYNOPSIS
    Show quick reference of most common commands

    .DESCRIPTION
    Display essential commands for new users
    Similar to t2.ps1's basic help output
    #>

    Write-Host ""
    Write-Host "  📚 Quick Command Reference" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Essential Commands:" -ForegroundColor Yellow
    Write-Host "    add <task>           Add a new task" -ForegroundColor White
    Write-Host "    done <ids>           Complete tasks" -ForegroundColor White
    Write-Host "    list                 Show all tasks" -ForegroundColor White
    Write-Host "    agenda               Show daily agenda" -ForegroundColor White
    Write-Host "    projects             Show project dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "  Metadata Examples:" -ForegroundColor Yellow
    Write-Host "    add \"Fix bug\" @web p1 due:tomorrow #urgent" -ForegroundColor Cyan
    Write-Host "    time log @project 2h \"Development work\"" -ForegroundColor Cyan
    Write-Host ""
    Write-PmcStyled -Style 'Muted' -Text "  💡 Use 'help all' for complete command list"
    Write-PmcStyled -Style 'Muted' -Text "  💡 Use 'help' for interactive command browser"
    Write-Host ""
}

# Command implementations that integrate with PMC's command system
function Show-PmcHelpAll {
    [CmdletBinding()]
    param([PmcCommandContext]$Context)
    Show-PmcHelpAllView
}

function Show-PmcCommandList {
    [CmdletBinding()]
    param([PmcCommandContext]$Context)
    Show-PmcHelpAllView
}
