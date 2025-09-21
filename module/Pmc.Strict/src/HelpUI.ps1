function Show-PmcHelpCategories {
    param([PmcCommandContext]$Context)

    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpCategories START'

    # Prefer curated help content if available
    $rows = @()
    $useCurated = ($Script:PmcHelpContent -and $Script:PmcHelpContent.Count -gt 0)
    if ($useCurated) {
        foreach ($entry in $Script:PmcHelpContent.GetEnumerator()) {
            $rows += [pscustomobject]@{
                Category = [string]$entry.Key
                Items    = @($entry.Value.Items).Count
                Description = [string]$entry.Value.Description
            }
        }
        $cols = @{
            Category    = @{ Header='Category';   Width=26; Alignment='Left' }
            Items       = @{ Header='Items';      Width=6;  Alignment='Right' }
            Description = @{ Header='Description';Width=0;  Alignment='Left' }
        }
    } else {
        # Fallback to domain listing
        foreach ($domain in ($Script:PmcCommandMap.Keys | Sort-Object)) {
            $actions = 0; try { $actions = @($Script:PmcCommandMap[$domain].Keys).Count } catch { $actions = 0 }
            $rows += [pscustomobject]@{
                Category = $domain
                Items    = $actions
                Description = ''
            }
        }
        $cols = @{
            Category    = @{ Header='Category';   Width=26; Alignment='Left' }
            Items       = @{ Header='Items';      Width=6;  Alignment='Right' }
            Description = @{ Header='Description';Width=0;  Alignment='Left' }
        }
    }

    # Start interactive grid in NavigationMode
    $renderer = [PmcGridRenderer]::new($cols, @('help-categories'), @{})
    $renderer.EditMode = $false
    $renderer.TitleText = '📚 PMC HELP — CATEGORIES'
    $renderer.OnSelectCallback = {
        param($item,$row)
        if ($item -and $item.PSObject.Properties['Category']) {
            Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Select category' -Data @{ Category = [string]$item.Category }
            $renderer.Interactive = $false
            Show-PmcHelpCommands -Context $Context -Domain ([string]$item.Category)
        }
    }
    # Help navigation key overrides
    # Right/Enter => Select (drill), Left => no-op at root, Tab/Escape/Q => no-op
    $renderer.KeyBindings['RightArrow'] = { try { $renderer.HandleEnterKey() } catch {} }
    $renderer.KeyBindings['LeftArrow']  = { }
    $renderer.KeyBindings['Tab']        = { }
    $renderer.KeyBindings['Shift+Tab']  = { }
    $renderer.KeyBindings['Escape']     = { }
    $renderer.KeyBindings['Q']          = { }
    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Help categories ready' -Data @{ Count = @($rows).Count }
    $renderer.StartInteractive($rows)
}

function Show-PmcHelpCommands {
    param([PmcCommandContext]$Context,[string]$Domain)

    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpCommands START' -Data @{ Domain = $Domain }

    if ([string]::IsNullOrWhiteSpace($Domain)) { return }

    # Build rows from curated help when available, else domain actions
    $rows = @()
    $isCurated = ($Script:PmcHelpContent -and $Script:PmcHelpContent.ContainsKey($Domain))
    if ($isCurated) {
        foreach ($it in $Script:PmcHelpContent[$Domain].Items) {
            $rows += [pscustomobject]@{
                Type        = [string]$it.Type
                Command     = [string]$it.Command
                Description = [string]$it.Description
            }
        }
        $cols = @{
            Type        = @{ Header='Type';        Width=12; Alignment='Left' }
            Command     = @{ Header='Command';     Width=32; Alignment='Left' }
            Description = @{ Header='Description'; Width=0;  Alignment='Left' }
        }
    } else {
        $map = $null; try { $map = $Script:PmcCommandMap[$Domain] } catch { $map = $null }
        if ($map) {
            foreach ($action in ($map.Keys | Sort-Object)) {
                $full = ("{0} {1}" -f $Domain, $action)
                $desc = ''
                try { if ($Script:PmcCommandMeta.ContainsKey($full)) { $desc = [string]$Script:PmcCommandMeta[$full].Desc } } catch {}
                $rows += [pscustomobject]@{ Action=$action; Description=$desc; Command=$full }
            }
        }
        $cols = @{
            Action      = @{ Header='Command';     Width=18; Alignment='Left' }
            Description = @{ Header='Description'; Width=0;  Alignment='Left' }
        }
    }

    $renderer = [PmcGridRenderer]::new($cols, @('help-commands'), @{})
    $renderer.EditMode = $false
    $renderer.TitleText = ("📚 PMC HELP — {0}" -f $Domain.ToUpper())
    $renderer.OnSelectCallback = {
        param($item,$row)
        if ($item -and $item.PSObject.Properties['Command']) {
            $cmd = [string]$item.Command
            Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Select command' -Data @{ Command = $cmd }

            $renderer.Interactive = $false
            if ($isCurated -and $cmd -match '^(?i)help\s+') {
                # Inline help topic (keeps navigator flow)
                Show-PmcHelpTopic -Context $Context -Topic ($cmd.Substring(5)) -ParentCategory $Domain
                return
            }

            # Heuristic: execute known view-like commands; otherwise insert
            $shouldExecute = $false
            try {
                $parts = $cmd.Split(' ',2)
                $dom = $parts[0].ToLower()
                $act = if ($parts.Length -gt 1) { $parts[1].ToLower() } else { '' }
                if ($dom -in @('view','projects','tasks','today','overdue','agenda','tomorrow','upcoming','blocked','noduedate','next')) { $shouldExecute = $true }
                if ($dom -eq 'project' -and $act -eq 'list') { $shouldExecute = $true }
                if ($dom -eq 'task' -and $act -eq 'list') { $shouldExecute = $true }
            } catch { $shouldExecute = $false }

            if ($shouldExecute) {
                try { Invoke-PmcCommand -Buffer $cmd } catch { Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Execute failed' -Data @{ Error = $_.Exception.Message } }
            } else {
                try { Pmc-InsertAtCursor ($cmd + ' ') } catch { Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Insert failed' -Data @{ Error = $_.Exception.Message } }
            }
        }
    }
    # Help navigation key overrides: Right/Enter select, Left goes back, Tab/Escape/Q do nothing
    $renderer.KeyBindings['RightArrow'] = { try { $renderer.HandleEnterKey() } catch {} }
    $renderer.KeyBindings['LeftArrow']  = { Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Back from commands to categories'; $renderer.Interactive = $false; Show-PmcHelpCategories -Context $Context }
    $renderer.KeyBindings['Tab']        = { }
    $renderer.KeyBindings['Shift+Tab']  = { }
    $renderer.KeyBindings['Escape']     = { }
    $renderer.KeyBindings['Q']          = { }
    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Help commands ready' -Data @{ Count = @($rows).Count }
    $renderer.StartInteractive($rows)
}

# Render an inline help topic (scrollable) and allow Back to previous list
function Show-PmcHelpTopic {
    param([PmcCommandContext]$Context,[string]$Topic,[string]$ParentCategory)
    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpTopic START' -Data @{ Topic=$Topic }

    $lines = @()
    $topicLC = ($Topic + '').ToLower().Trim()
    try {
        if ($topicLC -like 'query*') {
            $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
            $ref = Join-Path $root 'PMC_QUERY_LANGUAGE_REFERENCE.md'
            if (Test-Path $ref) {
                $raw = Get-Content $ref -Raw
                $rawLines = $raw -split "`n"
                foreach ($ln in $rawLines) {
                    # Strip code fences and shell prompts; keep prose and examples
                    if ($ln -match '^```') { continue }
                    if ($ln -match '^(\$ |pwsh>|bash-\d|PS>)') { continue }
                    $lines += [pscustomobject]@{ Text = ($ln.TrimEnd()) }
                }
            } else { $lines += [pscustomobject]@{ Text = 'Query reference not found.' } }
        } else {
            $lines += [pscustomobject]@{ Text = ("No detailed topic renderer for '{0}'" -f $Topic) }
        }
    } catch { $lines += [pscustomobject]@{ Text = ("Error loading topic: {0}" -f $_) } }

    $cols = @{ Text = @{ Header=''; Width=0; Alignment='Left' } }
    $renderer = [PmcGridRenderer]::new($cols, @('help-topic'), @{})
    $renderer.EditMode = $false
    $renderer.TitleText = ("📚 HELP — {0}" -f $Topic.ToUpper())
    $renderer.OnSelectCallback = {
        param($item,$row)
        if ($item -and $item.PSObject.Properties['Text']) {
            $text = [string]$item.Text
            if ($text -match '^(?i)(pmc|task|project|view|time|timer)\s+') {
                try { Pmc-InsertAtCursor ($text.Trim() + ' ') } catch {}
            }
        }
    }
    # Left = back to previous list of commands in category
    $renderer.KeyBindings['LeftArrow']  = { $renderer.Interactive = $false; Show-PmcHelpCommands -Context $Context -Domain $ParentCategory }
    $renderer.KeyBindings['RightArrow'] = { try { $renderer.HandleEnterKey() } catch {} }
    $renderer.KeyBindings['Tab']        = { }
    $renderer.KeyBindings['Shift+Tab']  = { }
    $renderer.KeyBindings['Escape']     = { }
    $renderer.KeyBindings['Q']          = { }
    $renderer.StartInteractive($lines)
}

function Show-PmcSmartHelp {
    param([PmcCommandContext]$Context)
    # Use the dedicated help navigator with proper back/forward keys
    Show-PmcHelpCategories -Context $Context
}

Export-ModuleMember -Function Show-PmcSmartHelp, Show-PmcHelpCategories, Show-PmcHelpCommands
