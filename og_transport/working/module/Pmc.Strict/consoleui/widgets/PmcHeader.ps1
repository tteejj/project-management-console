# PmcHeader - Screen header widget with title, breadcrumb, and context info
# Provides consistent header appearance across all PMC screens

using namespace System.Text

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Header widget for screen titles and navigation context

.DESCRIPTION
PmcHeader displays:
- Screen title (large, themed)
- Optional icon
- Optional breadcrumb trail
- Optional context information
- Horizontal separator line

.EXAMPLE
$header = [PmcHeader]::new("Tasks")
$header.SetBreadcrumb(@("Home", "Projects", "Tasks"))
$header.SetContext("15 active tasks")
#>
class PmcHeader : PmcWidget {
    # === Properties ===
    [string]$Title = ""
    [string]$Icon = ""
    [string[]]$Breadcrumb = @()
    [string]$ContextInfo = ""
    [bool]$ShowSeparator = $true
    [string]$BorderStyle = 'single'  # 'single', 'double', 'heavy'

    # === Constructor ===
    PmcHeader() : base("Header") {
        $this.Height = 3  # Title line + separator line + padding
        $this.Width = 80
    }

    PmcHeader([string]$title) : base("Header") {
        $this.Title = $title
        $this.Height = 3
        $this.Width = 80
    }

    # === Configuration ===

    <#
    .SYNOPSIS
    Set the title text

    .PARAMETER title
    Title to display
    #>
    [void] SetTitle([string]$title) {
        $this.Title = $title
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set the icon character

    .PARAMETER icon
    Icon character or emoji
    #>
    [void] SetIcon([string]$icon) {
        $this.Icon = $icon
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set breadcrumb trail

    .PARAMETER breadcrumb
    Array of breadcrumb segments (e.g., @("Home", "Projects", "My Project"))
    #>
    [void] SetBreadcrumb([string[]]$breadcrumb) {
        $this.Breadcrumb = $breadcrumb
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set context information (right-aligned)

    .PARAMETER contextInfo
    Context text (e.g., "15 items", "Last updated: 2024-01-15")
    #>
    [void] SetContext([string]$contextInfo) {
        $this.ContextInfo = $contextInfo
        $this.Invalidate()
    }

    # === Rendering ===

    [string] OnRender() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Colors
        $titleColor = $this.GetThemedFg('Foreground.Title')
        $mutedColor = $this.GetThemedFg('Foreground.Muted')
        $borderColor = $this.GetThemedFg('Border.Widget')
        $reset = "`e[0m"

        # Line 1: Title (with optional icon and context)
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($titleColor)

        $titleText = ""
        if ($this.Icon) {
            $titleText = "$($this.Icon) "
        }
        $titleText += $this.Title

        # If context info exists, show it right-aligned
        if ($this.ContextInfo) {
            $contextText = " [$($this.ContextInfo)]"
            $availableWidth = $this.Width - $titleText.Length - $contextText.Length
            if ($availableWidth -gt 0) {
                $sb.Append($titleText)
                $sb.Append($this.GetSpaces($availableWidth))
                $sb.Append($mutedColor)
                $sb.Append($contextText)
                $sb.Append($reset)
            } else {
                # Not enough room, just show title
                $sb.Append($this.TruncateText($titleText, $this.Width))
                $sb.Append($reset)
            }
        } else {
            $sb.Append($titleText)
            $sb.Append($reset)
        }

        # Line 2: Blank line for visual space
        # (intentionally blank)

        # Line 3: Breadcrumb (if present)
        if ($this.Breadcrumb -and $this.Breadcrumb.Count -gt 0) {
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + 2))
            $sb.Append($mutedColor)

            $breadcrumbText = $this.Breadcrumb -join " → "
            $sb.Append($this.TruncateText($breadcrumbText, $this.Width))
            $sb.Append($reset)
        }

        # Line 4: Column headers will be rendered by TaskListScreen here
        # Line 5: Separator (if enabled)
        if ($this.ShowSeparator) {
            $separatorY = $(if ($this.Breadcrumb -and $this.Breadcrumb.Count -gt 0) { $this.Y + 4 } else { $this.Y + 2 })
            $sb.Append($this.BuildMoveTo($this.X, $separatorY))
            $sb.Append($borderColor)
            $sb.Append($this.BuildHorizontalLine($this.Width, $this.BorderStyle))
            $sb.Append($reset)
        }

        $result = $sb.ToString()

        return $result
    }

    <#
    .SYNOPSIS
    Render directly to engine (new high-performance path)

    .PARAMETER engine
    RenderEngine instance to write to

    .DESCRIPTION
    Writes header content directly to RenderEngine.WriteAt()
    without building ANSI strings with position markers. Eliminates parsing overhead.
    #>
    [void] RenderToEngine([object]$engine) {
        # Colors
        $titleColor = $this.GetThemedFg('Foreground.Title')
        $mutedColor = $this.GetThemedFg('Foreground.Muted')
        $borderColor = $this.GetThemedFg('Border.Widget')
        $reset = "`e[0m"

        # Line 1: Title (with optional icon and context)
        $line1 = [System.Text.StringBuilder]::new(256)
        $line1.Append($titleColor)

        $titleText = ""
        if ($this.Icon) {
            $titleText = "$($this.Icon) "
        }
        $titleText += $this.Title

        # If context info exists, show it right-aligned
        if ($this.ContextInfo) {
            $contextText = " [$($this.ContextInfo)]"
            $availableWidth = $this.Width - $titleText.Length - $contextText.Length
            if ($availableWidth -gt 0) {
                $line1.Append($titleText)
                $line1.Append($this.GetSpaces($availableWidth))
                $line1.Append($mutedColor)
                $line1.Append($contextText)
                $line1.Append($reset)
            } else {
                # Not enough room, just show title
                $line1.Append($this.TruncateText($titleText, $this.Width))
                $line1.Append($reset)
            }
        } else {
            $line1.Append($titleText)
            $line1.Append($reset)
        }

        $engine.WriteAt($this.X, $this.Y, $line1.ToString())

        # Line 2: Blank line for visual space
        # (intentionally blank)

        # Line 3: Breadcrumb (if present)
        if ($this.Breadcrumb -and $this.Breadcrumb.Count -gt 0) {
            $line3 = [System.Text.StringBuilder]::new(256)
            $line3.Append($mutedColor)

            $breadcrumbText = $this.Breadcrumb -join " → "
            $line3.Append($this.TruncateText($breadcrumbText, $this.Width))
            $line3.Append($reset)

            $engine.WriteAt($this.X, $this.Y + 2, $line3.ToString())
        }

        # Line 4: Column headers will be rendered by TaskListScreen here
        # Line 5: Separator (if enabled)
        if ($this.ShowSeparator) {
            $hasBreadcrumb = ($this.Breadcrumb -and $this.Breadcrumb.Count -gt 0)
            $separatorY = $(if ($hasBreadcrumb) { $this.Y + 4 } else { $this.Y + 2 })

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcHeader.RenderToEngine: Rendering separator at Y=$separatorY (this.Y=$($this.Y) hasBreadcrumb=$hasBreadcrumb)"
            }

            $separatorLine = [System.Text.StringBuilder]::new(256)
            $separatorLine.Append($borderColor)
            $separatorLine.Append($this.BuildHorizontalLine($this.Width, $this.BorderStyle))
            $separatorLine.Append($reset)

            $engine.WriteAt($this.X, $separatorY, $separatorLine.ToString())
        }
    }

    # === Pre-computation ===

    [void] PrecomputeRenderData() {
        # Pre-compute layout based on current size
        # Called by base class when bounds change
    }
}

# Classes exported automatically in PowerShell 5.1+
# Classes exported automatically in PowerShell 5.1+