# NoteService.ps1 - Service for managing notes
#
# Provides CRUD operations for notes with file-based storage
# Notes are stored in notes/ subdirectory as .txt files
#
# Usage:
#   $service = [NoteService]::GetInstance()
#   $notes = $service.GetAllNotes()
#   $service.CreateNote("Meeting Notes")
#   $service.DeleteNote($noteId)

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

class NoteService {
    # === Singleton Instance ===
    static hidden [NoteService]$_instance = $null
    static hidden [object]$_instanceLock = [object]::new()

    # === Configuration ===
    hidden [string]$_notesDir
    hidden [string]$_metadataFile

    # === In-memory cache ===
    hidden [hashtable]$_notesCache = @{}
    hidden [datetime]$_cacheLoadTime = [datetime]::MinValue

    # === Event Callbacks ===
    [scriptblock]$OnNoteAdded = {}
    [scriptblock]$OnNoteUpdated = {}
    [scriptblock]$OnNoteDeleted = {}
    [scriptblock]$OnNotesChanged = {}

    # === Singleton Access ===
    static [NoteService] GetInstance() {
        if ([NoteService]::_instance -eq $null) {
            [System.Threading.Monitor]::Enter([NoteService]::_instanceLock)
            try {
                if ([NoteService]::_instance -eq $null) {
                    [NoteService]::_instance = [NoteService]::new()
                }
            } finally {
                [System.Threading.Monitor]::Exit([NoteService]::_instanceLock)
            }
        }
        return [NoteService]::_instance
    }

    # === Constructor (Private - use GetInstance) ===
    NoteService() {
        # Determine notes directory relative to PMC root
        $pmcRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        $this._notesDir = Join-Path $pmcRoot "notes"
        $this._metadataFile = Join-Path $this._notesDir "notes_metadata.json"

        # Ensure notes directory exists
        if (-not (Test-Path $this._notesDir)) {
            New-Item -ItemType Directory -Path $this._notesDir -Force | Out-Null
        }

        # Load metadata
        $this.LoadMetadata()
    }

    # === Metadata Management ===
    hidden [void] LoadMetadata() {
        if (Test-Path $this._metadataFile) {
            try {
                $json = Get-Content $this._metadataFile -Raw | ConvertFrom-Json
                foreach ($note in $json.notes) {
                    $this._notesCache[$note.id] = @{
                        id = $note.id
                        title = $note.title
                        file = $note.file
                        created = [datetime]::Parse($note.created)
                        modified = [datetime]::Parse($note.modified)
                        tags = $note.tags
                        word_count = $note.word_count
                        line_count = $note.line_count
                    }
                }
                $this._cacheLoadTime = [datetime]::Now
            } catch {
                Write-Warning "Failed to load notes metadata: $_"
                $this._notesCache = @{}
            }
        }
    }

    hidden [void] SaveMetadata() {
        try {
            $notes = $this._notesCache.Values | ForEach-Object {
                @{
                    id = $_.id
                    title = $_.title
                    file = $_.file
                    created = $_.created.ToString("o")
                    modified = $_.modified.ToString("o")
                    tags = $_.tags
                    word_count = $_.word_count
                    line_count = $_.line_count
                }
            }

            $metadata = @{
                schema_version = 1
                notes = $notes
            }

            # Atomic save: write to temp file, then rename
            $tempFile = "$($this._metadataFile).tmp"
            $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

            # Backup existing file
            if (Test-Path $this._metadataFile) {
                Copy-Item $this._metadataFile "$($this._metadataFile).bak" -Force
            }

            # Rename temp to actual
            Move-Item -Path $tempFile -Destination $this._metadataFile -Force

        } catch {
            Write-Warning "Failed to save notes metadata: $_"
            throw
        }
    }

    # === CRUD Operations ===

    [array] GetAllNotes() {
        return $this._notesCache.Values | Sort-Object -Property modified -Descending
    }

    [object] GetNote([string]$noteId) {
        if ($this._notesCache.ContainsKey($noteId)) {
            return $this._notesCache[$noteId]
        }
        return $null
    }

    [object] CreateNote([string]$title) {
        return $this.CreateNote($title, @())
    }

    [object] CreateNote([string]$title, [array]$tags) {
        # Generate unique ID
        $noteId = [guid]::NewGuid().ToString()

        # Create note file
        $fileName = "$noteId.txt"
        $filePath = Join-Path $this._notesDir $fileName

        # Create initial empty note
        Set-Content -Path $filePath -Value "" -Encoding UTF8

        # Create metadata entry
        $note = @{
            id = $noteId
            title = $title
            file = $filePath
            created = [datetime]::Now
            modified = [datetime]::Now
            tags = $tags
            word_count = 0
            line_count = 0
        }

        # Add to cache
        $this._notesCache[$noteId] = $note

        # Persist metadata
        $this.SaveMetadata()

        # Fire event
        if ($this.OnNoteAdded) {
            & $this.OnNoteAdded $note
        }
        if ($this.OnNotesChanged) {
            & $this.OnNotesChanged
        }

        return $note
    }

    [void] UpdateNoteMetadata([string]$noteId, [hashtable]$changes) {
        if (-not $this._notesCache.ContainsKey($noteId)) {
            throw "Note not found: $noteId"
        }

        $note = $this._notesCache[$noteId]

        # Apply changes
        foreach ($key in $changes.Keys) {
            if ($note.ContainsKey($key)) {
                $note[$key] = $changes[$key]
            }
        }

        # Update modified timestamp
        $note.modified = [datetime]::Now

        # Persist
        $this.SaveMetadata()

        # Fire event
        if ($this.OnNoteUpdated) {
            & $this.OnNoteUpdated $note
        }
        if ($this.OnNotesChanged) {
            & $this.OnNotesChanged
        }
    }

    [void] UpdateNoteStats([string]$noteId, [int]$wordCount, [int]$lineCount) {
        $this.UpdateNoteMetadata($noteId, @{
            word_count = $wordCount
            line_count = $lineCount
        })
    }

    [void] DeleteNote([string]$noteId) {
        if (-not $this._notesCache.ContainsKey($noteId)) {
            throw "Note not found: $noteId"
        }

        $note = $this._notesCache[$noteId]

        # Delete file
        if (Test-Path $note.file) {
            Remove-Item $note.file -Force
        }

        # Remove from cache
        $this._notesCache.Remove($noteId)

        # Persist
        $this.SaveMetadata()

        # Fire event
        if ($this.OnNoteDeleted) {
            & $this.OnNoteDeleted $noteId
        }
        if ($this.OnNotesChanged) {
            & $this.OnNotesChanged
        }
    }

    [string] LoadNoteContent([string]$noteId) {
        if (-not $this._notesCache.ContainsKey($noteId)) {
            throw "Note not found: $noteId"
        }

        $note = $this._notesCache[$noteId]

        if (Test-Path $note.file) {
            return Get-Content -Path $note.file -Raw
        }

        return ""
    }

    [void] SaveNoteContent([string]$noteId, [string]$content) {
        if (-not $this._notesCache.ContainsKey($noteId)) {
            throw "Note not found: $noteId"
        }

        $note = $this._notesCache[$noteId]

        # Atomic save: write to temp file, then rename
        $tempFile = "$($note.file).tmp"

        try {
            Set-Content -Path $tempFile -Value $content -Encoding UTF8

            # Backup existing file
            if (Test-Path $note.file) {
                Copy-Item $note.file "$($note.file).bak" -Force
            }

            # Rename temp to actual
            Move-Item -Path $tempFile -Destination $note.file -Force

            # Calculate stats
            $lines = $content -split "`n"
            $lineCount = $lines.Count
            $words = ($content -split '\s+' | Where-Object { $_ -ne '' })
            $wordCount = $words.Count

            # Update metadata
            $this.UpdateNoteStats($noteId, $wordCount, $lineCount)

        } catch {
            # Clean up temp file if it exists
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
            throw
        }
    }
}
