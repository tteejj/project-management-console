using namespace System.Collections.Generic
using namespace System.Text

# CommandLibraryScreen - Command library management using StandardListScreen
# Allows users to save, manage, and execute frequently used PowerShell commands

Set-StrictMode -Version Latest

. "$PSScriptRoot/../base/StandardListScreen.ps1"

<#
.SYNOPSIS
Command library management screen

.DESCRIPTION
Manage a library of saved PowerShell commands:
- Add/Edit/Delete commands
- Execute saved commands
- Track usage statistics
- Search and filter commands
#>
class CommandLibraryScreen : StandardListScreen {

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Tools', 'Command Library', 'C', {
            . "$PSScriptRoot/CommandLibraryScreen.ps1"
            $global:PmcApp.PushScreen([CommandLibraryScreen]::new())
        }, 10)
    }

    # Constructor
    CommandLibraryScreen() : base("CommandLibrary", "Command Library") {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tools", "Command Library"))
    }

    # === Abstract Method Implementations ===

    # Get entity type for store operations
    [string] GetEntityType() {
        return 'command'
    }

    # Define columns for list display
    [array] GetColumns() {
        return @(
            @{ Name='name'; Label='Name'; Width=25 }
            @{ Name='category'; Label='Category'; Width=15 }
            @{ Name='usage_count'; Label='Uses'; Width=6 }
            @{ Name='last_used'; Label='Last Used'; Width=12 }
            @{ Name='description'; Label='Description'; Width=45 }
        )
    }

    # Load data and refresh list
    [void] LoadData() {
        $items = $this.LoadItems()
        $this.List.SetData($items)
    }

    # Load items from data store
    [array] LoadItems() {
        # For now, return empty array - will be implemented with command storage
        # TODO: Implement Get-PmcCommands or similar
        $commands = @()

        # Format for display
        foreach ($cmd in $commands) {
            if (-not $cmd.ContainsKey('usage_count')) {
                $cmd['usage_count'] = 0
            }
            if ($cmd.ContainsKey('last_used') -and $cmd.last_used -is [DateTime]) {
                $cmd['last_used_display'] = $cmd.last_used.ToString('yyyy-MM-dd')
            } else {
                $cmd['last_used_display'] = 'Never'
            }
        }

        return $commands | Sort-Object -Property last_used -Descending
    }

    # Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New command - empty fields
            return @(
                @{ Name='name'; Type='text'; Label='Command Name'; Required=$true; Value='' }
                @{ Name='category'; Type='text'; Label='Category'; Value='General' }
                @{ Name='command_text'; Type='text'; Label='PowerShell Command'; Required=$true; Value=''; MaxLength=500 }
                @{ Name='description'; Type='text'; Label='Description'; Value='' }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value='' }
            )
        } else {
            # Existing command - populate from item
            return @(
                @{ Name='name'; Type='text'; Label='Command Name'; Required=$true; Value=$item.name }
                @{ Name='category'; Type='text'; Label='Category'; Value=$item.category }
                @{ Name='command_text'; Type='text'; Label='PowerShell Command'; Required=$true; Value=$item.command_text; MaxLength=500 }
                @{ Name='description'; Type='text'; Label='Description'; Value=$item.description }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=$item.tags }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        $commandData = @{
            name = $values.name
            category = $values.category
            command_text = $values.command_text
            description = $values.description
            tags = $values.tags
            usage_count = 0
            created = [DateTime]::Now
        }

        # TODO: Store.AddCommand($commandData)
        $this.SetStatusMessage("Command '$($values.name)' saved", "success")
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        $changes = @{
            name = $values.name
            category = $values.category
            command_text = $values.command_text
            description = $values.description
            tags = $values.tags
            modified = [DateTime]::Now
        }

        # TODO: Store.UpdateCommand($item.id, $changes)
        $this.SetStatusMessage("Command '$($values.name)' updated", "success")
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        if ($item.ContainsKey('id')) {
            # TODO: Store.DeleteCommand($item.id)
            $this.SetStatusMessage("Command '$($item.name)' deleted", "success")
        } else {
            $this.SetStatusMessage("Cannot delete command without ID", "error")
        }
    }

    # === Custom Actions ===

    # Execute the selected command
    [void] ExecuteCommand() {
        $selectedItem = $this.List.GetSelectedItem()
        if ($null -eq $selectedItem) {
            $this.SetStatusMessage("No command selected", "error")
            return
        }

        if (-not $selectedItem.ContainsKey('command_text')) {
            $this.SetStatusMessage("Command has no command_text", "error")
            return
        }

        try {
            # Execute the command
            $result = Invoke-Expression $selectedItem.command_text

            # Update usage statistics
            # TODO: Update usage_count and last_used in store

            $this.SetStatusMessage("Command executed successfully", "success")

            # Show result if any
            if ($null -ne $result) {
                Write-Host "`nCommand Output:" -ForegroundColor Cyan
                Write-Host $result
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = [Console]::ReadKey($true)
            }
        } catch {
            $this.SetStatusMessage("Error executing command: $($_.Exception.Message)", "error")
        }
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Call parent handler first (handles list navigation, add/edit/delete)
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key: X = Execute command
        if ($keyInfo.Key -eq 'X') {
            $this.ExecuteCommand()
            return $true
        }

        return $false
    }
}
