# NoteEditorScreen.ps1 - Screen wrapper for TextAreaEditor
#
# Provides a full-screen note editing experience with:
# - TextAreaEditor widget for content editing
# - Breadcrumb header showing note title
# - Status bar showing stats and keyboard shortcuts
# - Auto-save on exit
#
# Usage:
#   $screen = [NoteEditorScreen]::new($noteId)
#   $global:PmcApp.PushScreen($screen)

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

class NoteEditorScreen : PmcScreen {
    # === Configuration ===
    hidden [string]$_noteId = ""
    hidden [object]$_note = $null
    hidden [NoteService]$_noteService = $null
    hidden [TextAreaEditor]$_editor = $null
    hidden [bool]$_saveOnExit = $true

    # === Constructor ===
    NoteEditorScreen([string]$noteId) : base("NoteEditor", "Note Editor") {
        $this._noteId = $noteId
        $this._noteService = [NoteService]::GetInstance()

        # Load note metadata
        $this._note = $this._noteService.GetNote($noteId)
        if (-not $this._note) {
            throw "Note not found: $noteId"
        }

        # Update screen title
        $this.ScreenTitle = $this._note.title

        # Create TextAreaEditor widget
        $this._editor = [TextAreaEditor]::new()

        # Configure footer shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Ctrl+S", "Save")
        $this.Footer.AddShortcut("Esc", "Back (Save)")
        $this.Footer.AddShortcut("Ctrl+Z", "Undo")
        $this.Footer.AddShortcut("Ctrl+Y", "Redo")
    }

    # === Lifecycle Methods ===

    [void] Initialize([object]$renderEngine) {
        $this.RenderEngine = $renderEngine

        # Get terminal size
        $this.TermWidth = $renderEngine.Width
        $this.TermHeight = $renderEngine.Height

        # Update header breadcrumb
        $this.Header.SetBreadcrumb(@("Notes", $this._note.title))

        # Initialize layout manager
        if (-not $this.LayoutManager) {
            $this.LayoutManager = [PmcLayoutManager]::new($this.TermWidth, $this.TermHeight)
        }

        # Calculate editor bounds
        # Layout: MenuBar (1) + Header (3) + Editor (remaining) + Footer (1)
        $editorY = 4  # After menubar (1) and header (3)
        $editorHeight = $this.TermHeight - 5  # Subtract menubar, header, footer
        $editorX = 0
        $editorWidth = $this.TermWidth

        $this._editor.SetBounds($editorX, $editorY, $editorWidth, $editorHeight)

        # Load note content
        $this.LoadData()
    }

    [void] LoadData() {
        Write-PmcTuiLog "NoteEditorScreen.LoadData: Loading note $($this._noteId)" "DEBUG"

        try {
            # Load content from file
            $content = $this._noteService.LoadNoteContent($this._noteId)

            # Set in editor
            $this._editor.SetText($content)

            Write-PmcTuiLog "NoteEditorScreen.LoadData: Loaded $($content.Length) characters" "DEBUG"

        } catch {
            Write-PmcTuiLog "NoteEditorScreen.LoadData: Error - $_" "ERROR"
            $this._editor.SetText("")
        }
    }

    [void] OnEnter() {
        $this.IsActive = $true
        $this.LoadData()
        $this.UpdateStatusBar()
    }

    [void] OnExit() {
        $this.IsActive = $false

        # Save on exit if modified
        if ($this._saveOnExit -and $this._editor.Modified) {
            $this.SaveNote()
        }
    }

    # === Rendering ===

    [string] Render() {
        $output = [System.Text.StringBuilder]::new()

        # Render MenuBar
        if ($this.MenuBar) {
            $menuOutput = $this.MenuBar.Render($this.TermWidth)
            [void]$output.Append($menuOutput)
        }

        # Render Header
        if ($this.Header) {
            $headerOutput = $this.Header.Render($this.TermWidth)
            [void]$output.Append($headerOutput)
        }

        # Render Editor
        $editorOutput = $this._editor.Render()
        [void]$output.Append($editorOutput)

        # Render Footer
        if ($this.Footer) {
            $footerOutput = $this.Footer.Render($this.TermWidth)
            [void]$output.Append($footerOutput)
        }

        return $output.ToString()
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$key) {
        # Handle screen-level shortcuts first
        $ctrl = $key.Modifiers -band [ConsoleModifiers]::Control

        # Ctrl+S - Save
        if ($ctrl -and $key.Key -eq [ConsoleKey]::S) {
            $this.SaveNote()
            return $true
        }

        # Escape - Go back (with save prompt if modified)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            if ($this._editor.Modified) {
                # For now, just save and exit
                # TODO: Add confirmation dialog
                $this.SaveNote()
            }
            $global:PmcApp.PopScreen()
            return $true
        }

        # F10 - Menu
        if ($key.Key -eq [ConsoleKey]::F10) {
            if ($this.MenuBar) {
                $this.MenuBar.Activate()
                return $true
            }
        }

        # Delegate to editor
        $handled = $this._editor.HandleKeyPress($key)

        # Update status bar after editor handles input
        if ($handled) {
            $this.UpdateStatusBar()
        }

        return $handled
    }

    # === Helper Methods ===

    hidden [void] SaveNote() {
        Write-PmcTuiLog "NoteEditorScreen.SaveNote: Saving note $($this._noteId)" "DEBUG"

        try {
            $content = $this._editor.GetText()
            $this._noteService.SaveNoteContent($this._noteId, $content)

            # Mark as not modified
            $this._editor.Modified = $false

            # Update status bar
            $this.UpdateStatusBar()

            Write-PmcTuiLog "NoteEditorScreen.SaveNote: Saved successfully" "INFO"

        } catch {
            Write-PmcTuiLog "NoteEditorScreen.SaveNote: Error - $_" "ERROR"
            # TODO: Show error to user
        }
    }

    hidden [void] UpdateStatusBar() {
        if (-not $this.StatusBar) {
            return
        }

        # Get editor stats
        $text = $this._editor.GetText()
        $lines = ($text -split "`n").Count
        $words = ($text -split '\s+' | Where-Object { $_ -ne '' }).Count
        $chars = $text.Length

        # Build status message
        $modifiedFlag = if ($this._editor.Modified) { "*" } else { "" }
        $cursorPos = "Ln $($this._editor.CursorY + 1), Col $($this._editor.CursorX + 1)"
        $stats = "$lines lines, $words words, $chars chars"

        $this.StatusBar.SetLeftText("$modifiedFlag$cursorPos")
        $this.StatusBar.SetRightText($stats)
    }
}
