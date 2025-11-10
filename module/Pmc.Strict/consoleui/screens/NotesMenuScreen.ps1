# NotesMenuScreen.ps1 - List all notes with add/edit/delete capabilities
#
# Displays a list of all notes using StandardListScreen base class
# Allows creating new notes, editing existing notes, and deleting notes
#
# Usage:
#   $screen = [NotesMenuScreen]::new()
#   $global:PmcApp.PushScreen($screen)

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

class NotesMenuScreen : StandardListScreen {
    # === Configuration ===
    hidden [NoteService]$_noteService = $null

    # === Constructor ===
    NotesMenuScreen() : base("NotesList", "Notes") {
        # Get note service instance
        $this._noteService = [NoteService]::GetInstance()

        # Subscribe to note changes
        $this._noteService.OnNotesChanged = {
            $this.LoadData()
        }.GetNewClosure()

        # Configure screen
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true
        $this.AllowSearch = $true
    }

    # === Abstract Methods Implementation ===

    <#
    .SYNOPSIS
    Load notes data into the list
    #>
    [void] LoadData() {
        Write-PmcTuiLog "NotesMenuScreen.LoadData: Loading notes" "DEBUG"

        try {
            # Get all notes from service
            $notes = $this._noteService.GetAllNotes()

            Write-PmcTuiLog "NotesMenuScreen.LoadData: Loaded $($notes.Count) notes" "DEBUG"

            # Set data in list
            $this.List.SetData($notes)

        } catch {
            Write-PmcTuiLog "NotesMenuScreen.LoadData: Error - $_" "ERROR"
            $this.List.SetData(@())
        }
    }

    <#
    .SYNOPSIS
    Define columns for the notes list
    #>
    [array] GetColumns() {
        return @(
            @{
                Name = 'title'
                Label = 'Title'
                Width = 40
                Sortable = $true
                Searchable = $true
            }
            @{
                Name = 'modified'
                Label = 'Modified'
                Width = 20
                Sortable = $true
                Formatter = {
                    param($value)
                    if ($value -is [datetime]) {
                        return $value.ToString("yyyy-MM-dd HH:mm")
                    }
                    return ""
                }
            }
            @{
                Name = 'line_count'
                Label = 'Lines'
                Width = 8
                Sortable = $true
                Align = 'right'
            }
            @{
                Name = 'word_count'
                Label = 'Words'
                Width = 8
                Sortable = $true
                Align = 'right'
            }
            @{
                Name = 'tags'
                Label = 'Tags'
                Width = 20
                Formatter = {
                    param($value)
                    if ($value -and $value.Count -gt 0) {
                        return ($value -join ", ")
                    }
                    return ""
                }
            }
        )
    }

    <#
    .SYNOPSIS
    Define fields for the add/edit inline editor
    #>
    [array] GetEditFields($item) {
        $title = if ($item) { $item.title } else { "" }
        $tags = if ($item -and $item.tags) { ($item.tags -join ", ") } else { "" }

        return @(
            @{
                Name = 'title'
                Type = 'text'
                Label = 'Title'
                Value = $title
                Required = $true
                MaxLength = 100
            }
            @{
                Name = 'tags'
                Type = 'text'
                Label = 'Tags (comma-separated)'
                Value = $tags
                Required = $false
                MaxLength = 200
            }
        )
    }

    # === Event Handlers ===

    <#
    .SYNOPSIS
    Handle item activation (Enter key) - open note editor
    #>
    [void] OnItemActivated($item) {
        if ($item -and $item.id) {
            Write-PmcTuiLog "NotesMenuScreen.OnItemActivated: Opening note $($item.id)" "DEBUG"

            # Load NoteEditorScreen
            $editorScreenPath = Join-Path $PSScriptRoot "NoteEditorScreen.ps1"
            if (Test-Path $editorScreenPath) {
                . $editorScreenPath
                $editorScreen = [NoteEditorScreen]::new($item.id)
                $global:PmcApp.PushScreen($editorScreen)
            } else {
                Write-PmcTuiLog "NotesMenuScreen.OnItemActivated: NoteEditorScreen.ps1 not found" "ERROR"
            }
        }
    }

    <#
    .SYNOPSIS
    Handle add new note
    #>
    [void] OnAddItem([hashtable]$data) {
        Write-PmcTuiLog "NotesMenuScreen.OnAddItem: Creating note '$($data.title)'" "DEBUG"

        try {
            # Parse tags
            $tags = @()
            if ($data.tags -and $data.tags.Trim() -ne "") {
                $tags = $data.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            }

            # Create note
            $note = $this._noteService.CreateNote($data.title, $tags)

            Write-PmcTuiLog "NotesMenuScreen.OnAddItem: Created note $($note.id)" "INFO"

            # Refresh list (will happen automatically via event callback)
            # Open the new note in editor
            $this.OnItemActivated($note)

        } catch {
            Write-PmcTuiLog "NotesMenuScreen.OnAddItem: Error - $_" "ERROR"
            # TODO: Show error message to user
        }
    }

    <#
    .SYNOPSIS
    Handle edit note metadata
    #>
    [void] OnEditItem($item, [hashtable]$data) {
        Write-PmcTuiLog "NotesMenuScreen.OnEditItem: Updating note $($item.id)" "DEBUG"

        try {
            # Parse tags
            $tags = @()
            if ($data.tags -and $data.tags.Trim() -ne "") {
                $tags = $data.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            }

            # Update note metadata
            $changes = @{
                title = $data.title
                tags = $tags
            }

            $this._noteService.UpdateNoteMetadata($item.id, $changes)

            Write-PmcTuiLog "NotesMenuScreen.OnEditItem: Updated note $($item.id)" "INFO"

            # Refresh list (will happen automatically via event callback)

        } catch {
            Write-PmcTuiLog "NotesMenuScreen.OnEditItem: Error - $_" "ERROR"
            # TODO: Show error message to user
        }
    }

    <#
    .SYNOPSIS
    Handle delete note
    #>
    [void] OnDeleteItem($item) {
        Write-PmcTuiLog "NotesMenuScreen.OnDeleteItem: Deleting note $($item.id)" "DEBUG"

        try {
            $this._noteService.DeleteNote($item.id)

            Write-PmcTuiLog "NotesMenuScreen.OnDeleteItem: Deleted note $($item.id)" "INFO"

            # Refresh list (will happen automatically via event callback)

        } catch {
            Write-PmcTuiLog "NotesMenuScreen.OnDeleteItem: Error - $_" "ERROR"
            # TODO: Show error message to user
        }
    }

    # === Custom Actions ===

    <#
    .SYNOPSIS
    Add custom keyboard shortcuts
    #>
    [array] GetCustomActions() {
        return @(
            @{
                Key = 'O'
                Label = 'Open'
                Description = 'Open selected note in editor'
                Handler = {
                    $selected = $this.List.GetSelectedItem()
                    if ($selected) {
                        $this.OnItemActivated($selected)
                    }
                }
            }
        )
    }

    # === Menu Registration ===

    <#
    .SYNOPSIS
    Register menu items for this screen
    #>
    static [void] RegisterMenuItems() {
        $registry = [MenuRegistry]::GetInstance()

        $registry.AddMenuItem('Tools', 'Notes', 'N', {
            # Load and push screen
            $screenPath = Join-Path $PSScriptRoot "NotesMenuScreen.ps1"
            if (Test-Path $screenPath) {
                . $screenPath
                $screen = [NotesMenuScreen]::new()
                $global:PmcApp.PushScreen($screen)
            }
        })
    }
}
