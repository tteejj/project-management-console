function Show-PmcHelpCategories {
    param([PmcCommandContext]$Context)

    # Build category rows from live command map
    $rows = @()
    foreach ($domain in ($Script:PmcCommandMap.Keys | Sort-Object)) {
        $actions = 0; try { $actions = @($Script:PmcCommandMap[$domain].Keys).Count } catch { $actions = 0 }
        # Domain descriptions (lightweight)
        $descMap = @{
            config      = 'Settings and customization'
            project     = 'Project creation and organization'
            task        = 'Creating, editing, organizing tasks'
            view        = 'Predefined views and filters'
            help        = 'Help and guides'
            time        = 'Time logging and reports'
            timer       = 'Timers and tracking'
            theme       = 'Themes and appearance'
            system      = 'System and maintenance'
            excel       = 'Excel I/O'
            xflow       = 'Excel flow shortcuts'
        }
        $desc = if ($descMap.ContainsKey($domain)) { $descMap[$domain] } else { '' }
        $rows += [pscustomobject]@{
            Domain = $domain
            Actions = $actions
            Description = $desc
        }
    }

    # Define columns
    $cols = @{
        Domain      = @{ Header='Category';   Width=20; Alignment='Left' }
        Actions     = @{ Header='Actions';    Width=8;  Alignment='Right' }
        Description = @{ Header='Description';Width=0;  Alignment='Left' }
    }

    # Start interactive grid in NavigationMode
    $renderer = [PmcGridRenderer]::new($cols, @('help-categories'), @{})
    $renderer.EditMode = $false
    $renderer.TitleText = '📚 PMC HELP — CATEGORIES'
    $renderer.OnSelectCallback = {
        param($item,$row)
        if ($item -and $item.PSObject.Properties['Domain']) {
            $renderer.Interactive = $false
            Show-PmcHelpCommands -Context $Context -Domain ([string]$item.Domain)
        }
    }
    $renderer.StartInteractive($rows)
}

function Show-PmcHelpCommands {
    param([PmcCommandContext]$Context,[string]$Domain)

    if ([string]::IsNullOrWhiteSpace($Domain)) { return }

    # Build command rows for the selected domain
    $rows = @()
    $map = $null; try { $map = $Script:PmcCommandMap[$Domain] } catch { $map = $null }
    if ($map) {
        foreach ($action in ($map.Keys | Sort-Object)) {
            $full = ("{0} {1}" -f $Domain, $action)
            $desc = ''
            try { if ($Script:PmcCommandMeta.ContainsKey($full)) { $desc = [string]$Script:PmcCommandMeta[$full].Desc } } catch {}
            $rows += [pscustomobject]@{
                Action = $action
                Description = $desc
                Command = $full
            }
        }
    }

    $cols = @{
        Action      = @{ Header='Command';     Width=18; Alignment='Left' }
        Description = @{ Header='Description'; Width=0;  Alignment='Left' }
    }

    $renderer = [PmcGridRenderer]::new($cols, @('help-commands'), @{})
    $renderer.EditMode = $false
    $renderer.TitleText = ("📚 PMC HELP — {0}" -f $Domain.ToUpper())
    $renderer.OnSelectCallback = {
        param($item,$row)
        if ($item -and $item.PSObject.Properties['Command']) {
            try { Pmc-InsertAtCursor (([string]$item.Command) + ' ') } catch {}
            $renderer.Interactive = $false
        }
    }
    $renderer.StartInteractive($rows)
}

function Show-PmcSmartHelp {
    param([PmcCommandContext]$Context)
    Show-PmcHelpCategories -Context $Context
}

Export-ModuleMember -Function Show-PmcSmartHelp, Show-PmcHelpCategories, Show-PmcHelpCommands
