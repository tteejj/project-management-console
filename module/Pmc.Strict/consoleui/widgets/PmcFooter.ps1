# PmcFooter - Keyboard shortcuts display
# Shows available keyboard shortcuts for current screen

using namespace System.Text
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Footer widget displaying keyboard shortcuts

.DESCRIPTION
PmcFooter shows available keyboard shortcuts in a consistent format:
- Left-aligned shortcuts
- Separator characters
- Color-coded key labels

.EXAMPLE
$footer = [PmcFooter]::new()
$footer.AddShortcut("Esc", "Back")
$footer.AddShortcut("F10", "Menu")
$footer.AddShortcut("Enter", "Select")
#>
class PmcFooter : PmcWidget {
    # === Properties ===
    [List[hashtable]]$Shortcuts

    # === Constructor ===
    PmcFooter() : base("Footer") {
        $this.Shortcuts = [List[hashtable]]::new()
        $this.Height = 1
        $this.Width = 80
    }

    # === Shortcut Management ===

    <#
    .SYNOPSIS
    Add a keyboard shortcut to display

    .PARAMETER key
    Key name (e.g., "Esc", "F10", "Ctrl+S")

    .PARAMETER description
    Action description (e.g., "Back", "Save", "Exit")

    .EXAMPLE
    $footer.AddShortcut("Esc", "Back")
    #>
    [void] AddShortcut([string]$key, [string]$description) {
        $this.Shortcuts.Add(@{
            Key = $key
            Description = $description
        })
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Clear all shortcuts

    .DESCRIPTION
    Removes all shortcuts from the footer
    #>
    [void] ClearShortcuts() {
        $this.Shortcuts.Clear()
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set shortcuts from array

    .PARAMETER shortcuts
    Array of key-description pairs

    .EXAMPLE
    $footer.SetShortcuts(@(
        @{ Key = "Esc"; Description = "Back" }
        @{ Key = "Enter"; Description = "Select" }
    ))
    #>
    [void] SetShortcuts([array]$shortcuts) {
        $this.Shortcuts.Clear()
        foreach ($shortcut in $shortcuts) {
            $this.Shortcuts.Add($shortcut)
        }
        $this.Invalidate()
    }

    # === Rendering ===

    [string] OnRender() {
        if ($this.Shortcuts.Count -eq 0) {
            return ""
        }

        $sb = [System.Text.StringBuilder]::new(512)

        # Colors
        $keyColor = $this.GetThemedAnsi('Highlight', $false)
        $textColor = $this.GetThemedAnsi('Muted', $false)
        $separatorColor = $this.GetThemedAnsi('Border', $false)
        $reset = "`e[0m"

        # Position
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))

        # Build shortcut string
        $shortcutParts = [List[string]]::new()
        foreach ($shortcut in $this.Shortcuts) {
            $key = $shortcut.Key
            $desc = $shortcut.Description

            $part = "${keyColor}${key}${reset}${textColor}: ${desc}${reset}"
            $shortcutParts.Add($part)
        }

        # Join with separator
        $separator = " ${separatorColor}|${reset} "
        $footerText = $shortcutParts -join $separator

        # Note: This includes ANSI codes, so actual display width will be shorter
        # For now, just output it (proper width calculation would need ANSI stripping)
        $sb.Append($footerText)
        $sb.Append($reset)

        $result = $sb.ToString()

        return $result
    }

    <#
    .SYNOPSIS
    Render directly to engine (new high-performance path)

    .PARAMETER engine
    RenderEngine instance to write to

    .DESCRIPTION
    Writes footer content directly to RenderEngine.WriteAt()
    without building ANSI strings with position markers. Eliminates parsing overhead.
    #>
    [void] RenderToEngine([object]$engine) {
        if ($this.Shortcuts.Count -eq 0) {
            return
        }

        $sb = [System.Text.StringBuilder]::new(512)

        # Colors
        $keyColor = $this.GetThemedAnsi('Highlight', $false)
        $textColor = $this.GetThemedAnsi('Muted', $false)
        $separatorColor = $this.GetThemedAnsi('Border', $false)
        $reset = "`e[0m"

        # Build shortcut string
        $shortcutParts = [List[string]]::new()
        foreach ($shortcut in $this.Shortcuts) {
            $key = $shortcut.Key
            $desc = $shortcut.Description

            $part = "${keyColor}${key}${reset}${textColor}: ${desc}${reset}"
            $shortcutParts.Add($part)
        }

        # Join with separator
        $separator = " ${separatorColor}|${reset} "
        $footerText = $shortcutParts -join $separator

        # Note: This includes ANSI codes, so actual display width will be shorter
        # For now, just output it (proper width calculation would need ANSI stripping)
        $sb.Append($footerText)
        $sb.Append($reset)

        # Write entire footer in one call
        $engine.WriteAt($this.X, $this.Y, $sb.ToString())
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Create footer with standard shortcuts

    .PARAMETER shortcuts
    Array of @{ Key = "..."; Description = "..." }

    .OUTPUTS
    Configured PmcFooter instance

    .EXAMPLE
    $footer = [PmcFooter]::CreateStandard(@(
        @{ Key = "Esc"; Description = "Back" }
        @{ Key = "F10"; Description = "Menu" }
    ))
    #>
    static [PmcFooter] CreateStandard([array]$shortcuts) {
        $footer = [PmcFooter]::new()
        $footer.SetShortcuts($shortcuts)
        return $footer
    }

    <#
    .SYNOPSIS
    Create footer with common navigation shortcuts

    .OUTPUTS
    PmcFooter with standard navigation shortcuts
    #>
    static [PmcFooter] CreateNavigationFooter() {
        $footer = [PmcFooter]::new()
        $footer.AddShortcut("↑↓", "Navigate")
        $footer.AddShortcut("Enter", "Select")
        $footer.AddShortcut("Esc", "Back")
        $footer.AddShortcut("F10", "Menu")
        return $footer
    }

    <#
    .SYNOPSIS
    Create footer with common edit shortcuts

    .OUTPUTS
    PmcFooter with standard edit shortcuts
    #>
    static [PmcFooter] CreateEditFooter() {
        $footer = [PmcFooter]::new()
        $footer.AddShortcut("Enter", "Save")
        $footer.AddShortcut("Esc", "Cancel")
        $footer.AddShortcut("Tab", "Next Field")
        return $footer
    }
}

# Classes exported automatically in PowerShell 5.1+
# Classes exported automatically in PowerShell 5.1+
