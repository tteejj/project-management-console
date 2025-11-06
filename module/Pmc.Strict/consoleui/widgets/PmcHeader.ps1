# PmcHeader - Screen header widget with title, breadcrumb, and context info
# Provides consistent header appearance across all PMC screens

using namespace System.Text

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
        $titleColor = $this.GetThemedAnsi('Title', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $borderColor = $this.GetThemedAnsi('Border', $false)
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
            $separatorY = if ($this.Breadcrumb -and $this.Breadcrumb.Count -gt 0) { $this.Y + 4 } else { $this.Y + 2 }
            $sb.Append($this.BuildMoveTo($this.X, $separatorY))
            $sb.Append($borderColor)
            $sb.Append($this.BuildHorizontalLine($this.Width, $this.BorderStyle))
            $sb.Append($reset)
        }

        $result = $sb.ToString()
        
        return $result
    }

    # === Pre-computation ===

    [void] PrecomputeRenderData() {
        # Pre-compute layout based on current size
        # Called by base class when bounds change
    }
}

# Classes exported automatically in PowerShell 5.1+
# Classes exported automatically in PowerShell 5.1+
