# PMC FakeTUI - All-in-one loader to handle PowerShell class dependencies
# Load all classes and functions in proper order for module compatibility

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Text

# === LOAD REQUIRED PMC FUNCTIONS ===
# FakeTUI needs Save-PmcData and other storage functions
# Load dependencies in correct order
$srcDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'src'
$requiredFiles = @('Types.ps1', 'Config.ps1', 'Debug.ps1', 'Security.ps1', 'State.ps1', 'Storage.ps1', 'Time.ps1')
foreach ($file in $requiredFiles) {
    $path = Join-Path $srcDir $file
    if (Test-Path $path) {
        # Suppress Export-ModuleMember errors when sourcing outside module context
        try {
            . $path 2>&1 | Where-Object { $_ -notmatch 'Export-ModuleMember.*can only be called from inside a module' } | Write-Error
        } catch {
            if ($_.Exception.Message -notmatch 'Export-ModuleMember') {
                throw
            }
        }
    }
}

# Initialize security system to set up default allowed paths
Initialize-PmcSecuritySystem

# === PERFORMANCE CORE ===
class PmcStringCache {
    static [hashtable]$_spaces = @{}
    static [hashtable]$_ansiSequences = @{}
    static [hashtable]$_boxDrawing = @{}
    static [int]$_maxCacheSize = 200
    static [bool]$_initialized = $false

    static [void] Initialize() {
        if ([PmcStringCache]::_initialized) { return }

        for ($i = 1; $i -le [PmcStringCache]::_maxCacheSize; $i++) {
            [PmcStringCache]::_spaces[$i] = " " * $i
        }

        [PmcStringCache]::_ansiSequences["reset"] = "`e[0m"
        [PmcStringCache]::_ansiSequences["clear"] = "`e[2J"
        [PmcStringCache]::_ansiSequences["clearline"] = "`e[2K"
        [PmcStringCache]::_ansiSequences["home"] = "`e[H"
        [PmcStringCache]::_ansiSequences["hidecursor"] = "`e[?25l"
        [PmcStringCache]::_ansiSequences["showcursor"] = "`e[?25h"

        [PmcStringCache]::_boxDrawing["horizontal"] = "─"
        [PmcStringCache]::_boxDrawing["vertical"] = "│"
        [PmcStringCache]::_boxDrawing["topleft"] = "┌"
        [PmcStringCache]::_boxDrawing["topright"] = "┐"
        [PmcStringCache]::_boxDrawing["bottomleft"] = "└"
        [PmcStringCache]::_boxDrawing["bottomright"] = "┘"

        [PmcStringCache]::_initialized = $true
    }

    static [string] GetSpaces([int]$count) {
        if ($count -le 0) { return "" }
        if ($count -le [PmcStringCache]::_maxCacheSize) {
            return [PmcStringCache]::_spaces[$count]
        }
        return " " * $count
    }

    static [string] GetAnsiSequence([string]$sequenceName) {
        if ([PmcStringCache]::_ansiSequences.ContainsKey($sequenceName)) {
            return [PmcStringCache]::_ansiSequences[$sequenceName]
        }
        return ""
    }

    static [string] GetBoxDrawing([string]$characterName) {
        if ([PmcStringCache]::_boxDrawing.ContainsKey($characterName)) {
            return [PmcStringCache]::_boxDrawing[$characterName]
        }
        return ""
    }
}

class PmcStringBuilderPool {
    static [ConcurrentQueue[StringBuilder]]$_pool = [ConcurrentQueue[StringBuilder]]::new()
    static [int]$_maxPoolSize = 20
    static [int]$_maxCapacity = 8192

    static [StringBuilder] Get() {
        $sb = $null
        if ([PmcStringBuilderPool]::_pool.TryDequeue([ref]$sb)) {
            $sb.Clear()
        } else {
            $sb = [StringBuilder]::new()
        }
        return $sb
    }

    static [StringBuilder] Get([int]$initialCapacity) {
        $sb = [PmcStringBuilderPool]::Get()
        if ($sb.Capacity -lt $initialCapacity) {
            $sb.Capacity = $initialCapacity
        }
        return $sb
    }

    static [void] Return([StringBuilder]$sb) {
        if (-not $sb) { return }
        if ($sb.Capacity -gt [PmcStringBuilderPool]::_maxCapacity) { return }
        if ([PmcStringBuilderPool]::_pool.Count -ge [PmcStringBuilderPool]::_maxPoolSize) { return }
        $sb.Clear()
        [PmcStringBuilderPool]::_pool.Enqueue($sb)
    }
}

# === THEME SYSTEM ===
class PmcTheme {
    static [string]$CurrentTheme = 'Default'
    static [hashtable]$Themes = @{
        'Default' = @{
            Red = "`e[31m"
            Green = "`e[32m"
            Yellow = "`e[33m"
            Blue = "`e[34m"
            Cyan = "`e[36m"
            White = "`e[37m"
            Gray = "`e[90m"
            Black = "`e[30m"
            BgRed = "`e[41m"
            BgGreen = "`e[42m"
            BgYellow = "`e[43m"
            BgBlue = "`e[44m"
            BgCyan = "`e[46m"
            BgWhite = "`e[47m"
        }
        'Dark' = @{
            Red = "`e[38;2;255;85;85m"
            Green = "`e[38;2;80;250;123m"
            Yellow = "`e[38;2;241;250;140m"
            Blue = "`e[38;2;139;233;253m"
            Cyan = "`e[38;2;128;255;234m"
            White = "`e[38;2;248;248;242m"
            Gray = "`e[38;2;98;114;164m"
            Black = "`e[38;2;40;42;54m"
            BgRed = "`e[48;2;68;10;10m"
            BgGreen = "`e[48;2;10;68;30m"
            BgYellow = "`e[48;2;68;68;10m"
            BgBlue = "`e[48;2;10;30;68m"
            BgCyan = "`e[48;2;10;68;68m"
            BgWhite = "`e[48;2;68;68;68m"
        }
        'Light' = @{
            Red = "`e[38;2;200;40;41m"
            Green = "`e[38;2;64;160;43m"
            Yellow = "`e[38;2;181;137;0m"
            Blue = "`e[38;2;38;139;210m"
            Cyan = "`e[38;2;42;161;152m"
            White = "`e[38;2;88;110;117m"
            Gray = "`e[38;2;147;161;161m"
            Black = "`e[38;2;0;43;54m"
            BgRed = "`e[48;2;253;246;227m"
            BgGreen = "`e[48;2;238;255;238m"
            BgYellow = "`e[48;2;255;255;224m"
            BgBlue = "`e[48;2;230;244;255m"
            BgCyan = "`e[48;2;224;255;255m"
            BgWhite = "`e[48;2;238;232;213m"
        }
        'Solarized' = @{
            Red = "`e[38;2;220;50;47m"
            Green = "`e[38;2;133;153;0m"
            Yellow = "`e[38;2;181;137;0m"
            Blue = "`e[38;2;38;139;210m"
            Cyan = "`e[38;2;42;161;152m"
            White = "`e[38;2;147;161;161m"
            Gray = "`e[38;2;88;110;117m"
            Black = "`e[38;2;7;54;66m"
            BgRed = "`e[48;2;7;54;66m"
            BgGreen = "`e[48;2;7;54;66m"
            BgYellow = "`e[48;2;7;54;66m"
            BgBlue = "`e[48;2;0;43;54m"
            BgCyan = "`e[48;2;7;54;66m"
            BgWhite = "`e[48;2;88;110;117m"
        }
        'Matrix' = @{
            Red = "`e[38;2;0;255;0m"
            Green = "`e[38;2;0;255;0m"
            Yellow = "`e[38;2;0;200;0m"
            Blue = "`e[38;2;0;180;0m"
            Cyan = "`e[38;2;0;220;0m"
            White = "`e[38;2;0;255;0m"
            Gray = "`e[38;2;0;136;0m"
            Black = "`e[38;2;0;0;0m"
            BgRed = "`e[48;2;0;80;0m"
            BgGreen = "`e[48;2;0;100;0m"
            BgYellow = "`e[48;2;0;80;0m"
            BgBlue = "`e[48;2;0;80;0m"
            BgCyan = "`e[48;2;0;100;0m"
            BgWhite = "`e[48;2;0;68;0m"
        }
        'Amber' = @{
            Red = "`e[38;2;255;128;0m"
            Green = "`e[38;2;255;191;0m"
            Yellow = "`e[38;2;255;191;0m"
            Blue = "`e[38;2;255;140;0m"
            Cyan = "`e[38;2;255;165;0m"
            White = "`e[38;2;255;191;0m"
            Gray = "`e[38;2;139;90;0m"
            Black = "`e[38;2;0;0;0m"
            BgRed = "`e[48;2;139;69;0m"
            BgGreen = "`e[48;2;139;90;0m"
            BgYellow = "`e[48;2;184;134;11m"
            BgBlue = "`e[48;2;139;69;0m"
            BgCyan = "`e[48;2;139;90;0m"
            BgWhite = "`e[48;2;101;67;33m"
        }
        'Synthwave' = @{
            Red = "`e[38;2;255;0;128m"         # Hot pink
            Green = "`e[38;2;0;255;255m"       # Cyan
            Yellow = "`e[38;2;255;215;0m"      # Bright gold
            Blue = "`e[38;2;138;43;226m"       # Blue violet
            Cyan = "`e[38;2;0;255;200m"        # Bright cyan
            White = "`e[38;2;255;105;180m"     # Hot pink (lighter)
            Gray = "`e[38;2;148;0;211m"        # Dark violet
            Black = "`e[38;2;25;0;51m"         # Very dark purple
            BgRed = "`e[48;2;75;0;130m"        # Indigo background
            BgGreen = "`e[48;2;25;25;112m"     # Midnight blue background
            BgYellow = "`e[48;2;138;43;226m"   # Blue violet background
            BgBlue = "`e[48;2;72;61;139m"      # Dark slate blue
            BgCyan = "`e[48;2;123;104;238m"    # Medium slate blue
            BgWhite = "`e[48;2;138;43;226m"    # Blue violet
        }
    }

    static [void] SetTheme([string]$themeName) {
        if ([PmcTheme]::Themes.ContainsKey($themeName)) {
            [PmcTheme]::CurrentTheme = $themeName
            # Save to preference file
            $prefPath = Join-Path $env:HOME '.pmc-theme'
            $themeName | Set-Content -Path $prefPath -Force
        }
    }

    static [void] LoadTheme() {
        $prefPath = Join-Path $env:HOME '.pmc-theme'
        if (Test-Path $prefPath) {
            $saved = Get-Content -Path $prefPath -Raw | ForEach-Object { $_.Trim() }
            if ([PmcTheme]::Themes.ContainsKey($saved)) {
                [PmcTheme]::CurrentTheme = $saved
            }
        }
    }

    static [string] GetColor([string]$colorName) {
        $theme = [PmcTheme]::Themes[[PmcTheme]::CurrentTheme]
        if ($theme.ContainsKey($colorName)) {
            return $theme[$colorName]
        }
        return ""
    }
}

class PmcVT100 {
    static [hashtable]$_colorCache = @{}
    static [int]$_maxColorCache = 200

    static [string] MoveTo([int]$x, [int]$y) {
        return "`e[$($y + 1);$($x + 1)H"
    }

    static [string] RGB([int]$r, [int]$g, [int]$b) {
        $key = "fg_${r}_${g}_${b}"
        if ([PmcVT100]::_colorCache.ContainsKey($key)) {
            return [PmcVT100]::_colorCache[$key]
        }
        $sequence = "`e[38;2;$r;$g;${b}m"
        if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) {
            [PmcVT100]::_colorCache[$key] = $sequence
        }
        return $sequence
    }

    static [string] BgRGB([int]$r, [int]$g, [int]$b) {
        $key = "bg_${r}_${g}_${b}"
        if ([PmcVT100]::_colorCache.ContainsKey($key)) {
            return [PmcVT100]::_colorCache[$key]
        }
        $sequence = "`e[48;2;$r;$g;${b}m"
        if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) {
            [PmcVT100]::_colorCache[$key] = $sequence
        }
        return $sequence
    }

    static [string] Reset() { return "`e[0m" }
    static [string] Bold() { return "`e[1m" }
    static [string] Red() { return [PmcTheme]::GetColor('Red') }
    static [string] Green() { return [PmcTheme]::GetColor('Green') }
    static [string] Yellow() { return [PmcTheme]::GetColor('Yellow') }
    static [string] Blue() { return [PmcTheme]::GetColor('Blue') }
    static [string] Cyan() { return [PmcTheme]::GetColor('Cyan') }
    static [string] White() { return [PmcTheme]::GetColor('White') }
    static [string] Gray() { return [PmcTheme]::GetColor('Gray') }
    static [string] Black() { return [PmcTheme]::GetColor('Black') }
    static [string] BgRed() { return [PmcTheme]::GetColor('BgRed') }
    static [string] BgGreen() { return [PmcTheme]::GetColor('BgGreen') }
    static [string] BgYellow() { return [PmcTheme]::GetColor('BgYellow') }
    static [string] BgBlue() { return [PmcTheme]::GetColor('BgBlue') }
    static [string] BgCyan() { return [PmcTheme]::GetColor('BgCyan') }
    static [string] BgWhite() { return [PmcTheme]::GetColor('BgWhite') }
}

# === UI WIDGET FUNCTIONS ===
# Simple, reusable UI components for blocking forms

function Show-InfoMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Title = "Information",
        [string]$Color = "Cyan"
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 8, $boxWidth, 8)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $colorCode = switch ($Color) {
        "Red" { [PmcVT100]::Red() }
        "Green" { [PmcVT100]::Green() }
        "Yellow" { [PmcVT100]::Yellow() }
        default { [PmcVT100]::Cyan() }
    }
    $terminal.WriteAtColor([int]$titleX, 8, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    # Draw message (word wrap)
    $y = 10
    $maxWidth = $boxWidth - 4
    $words = $Message -split '\s+'
    $line = ""
    foreach ($word in $words) {
        if (($line + " " + $word).Length -gt $maxWidth) {
            $terminal.WriteAtColor([int]($boxX + 2), $y++, $line, $colorCode, "")
            $line = $word
        } else {
            $line = if ($line) { "$line $word" } else { $word }
        }
    }
    if ($line) {
        $terminal.WriteAtColor([int]($boxX + 2), $y++, $line, $colorCode, "")
    }

    # Prompt
    $terminal.WriteAt([int]($boxX + 2), $y + 2, "Press any key to continue...")
    [Console]::ReadKey($true) | Out-Null
}

function Show-ConfirmDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Title = "Confirm"
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 8, $boxWidth, 8)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $terminal.WriteAtColor([int]$titleX, 8, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    # Draw message
    $terminal.WriteAtColor([int]($boxX + 2), 10, $Message, [PmcVT100]::Yellow(), "")

    # Prompt
    $terminal.WriteAt([int]($boxX + 2), 13, "Y/N: ")

    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.KeyChar -eq 'y' -or $key.KeyChar -eq 'Y') {
            return $true
        } elseif ($key.KeyChar -eq 'n' -or $key.KeyChar -eq 'N' -or $key.Key -eq 'Escape') {
            return $false
        }
    }
}

function Show-SelectList {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string[]]$Options,
        [string]$DefaultValue = $null
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Find default index
    $selected = 0
    if ($DefaultValue) {
        $idx = $Options.IndexOf($DefaultValue)
        if ($idx -ge 0) { $selected = $idx }
    }

    # Draw box
    $boxWidth = [Math]::Min(60, $terminal.Width - 4)
    $boxHeight = [Math]::Min(20, 8 + $Options.Count)
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 5, $boxWidth, $boxHeight)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $terminal.WriteAtColor([int]$titleX, 5, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $running = $true
    while ($running) {
        # Draw options
        $y = 7
        $maxDisplay = $boxHeight - 5
        $startIdx = [Math]::Max(0, $selected - $maxDisplay + 1)

        for ($i = 0; $i -lt [Math]::Min($Options.Count, $maxDisplay); $i++) {
            $idx = $startIdx + $i
            if ($idx -ge $Options.Count) { break }

            $opt = $Options[$idx]
            if ($idx -eq $selected) {
                $terminal.WriteAtColor([int]($boxX + 2), $y, "> $opt", [PmcVT100]::BgCyan(), [PmcVT100]::Black())
            } else {
                $terminal.WriteAt([int]($boxX + 2), $y, "  $opt")
            }
            $y++
        }

        # Draw footer
        $terminal.WriteAt([int]($boxX + 2), [int](5 + $boxHeight - 2), "↑/↓: Navigate  Enter: Select  Esc: Cancel")

        # Handle input
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' {
                $selected = [Math]::Max(0, $selected - 1)
            }
            'DownArrow' {
                $selected = [Math]::Min($Options.Count - 1, $selected + 1)
            }
            'Enter' {
                return $Options[$selected]
            }
            'Escape' {
                return $null
            }
        }
    }
}

function Show-InputForm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [hashtable[]]$Fields  # Array of @{Name='fieldname'; Label='Display label'; Required=$true; Type='text'|'select'; Options=@()}
    )

    $terminal = [PmcSimpleTerminal]::GetInstance()
    $terminal.Clear()

    # Draw box
    $boxWidth = [Math]::Min(70, $terminal.Width - 4)
    $boxHeight = 10 + $Fields.Count * 2
    $boxX = ($terminal.Width - $boxWidth) / 2
    $terminal.DrawBox($boxX, 5, $boxWidth, $boxHeight)

    # Draw title
    $titleX = ($terminal.Width - $Title.Length) / 2
    $terminal.WriteAtColor([int]$titleX, 5, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

    # Get input for each field
    $results = @{}
    $y = 7

    foreach ($field in $Fields) {
        $label = $field.Label
        $name = $field.Name
        $required = if ($field.Required) { $field.Required } else { $false }
        $type = if ($field.Type) { $field.Type } else { 'text' }

        $terminal.WriteAt([int]($boxX + 2), $y, "${label}:")

        if ($type -eq 'select' -and $field.Options) {
            # Show selection prompt
            $terminal.WriteAt([int]($boxX + 2), $y + 1, "> [Press Enter to select]")
            [Console]::SetCursorPosition([int]($boxX + 4), $y + 1)
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Enter') {
                $value = Show-SelectList -Title $label -Options $field.Options
                if ($null -eq $value) {
                    # User pressed Escape in selection
                    return $null
                }
                $terminal.Clear()
                $terminal.DrawBox($boxX, 5, $boxWidth, $boxHeight)
                $terminal.WriteAtColor([int]$titleX, 5, " $Title ", [PmcVT100]::BgBlue(), [PmcVT100]::White())

                # Redraw previous fields
                $prevY = 7
                foreach ($prevName in $results.Keys) {
                    $prevField = $Fields | Where-Object { $_.Name -eq $prevName } | Select-Object -First 1
                    $terminal.WriteAt([int]($boxX + 2), $prevY, "$($prevField.Label): $($results[$prevName])")
                    $prevY += 2
                }

                # Show selected value
                $terminal.WriteAt([int]($boxX + 2), $y, "${label}: $value")
                $results[$name] = $value
            } elseif ($key.Key -eq 'Escape') {
                # User wants to exit the form
                return $null
            } else {
                $results[$name] = $null
            }
        } else {
            # Text input
            $terminal.WriteAt([int]($boxX + 2), $y + 1, "> ")
            [Console]::SetCursorPosition([int]($boxX + 4), $y + 1)
            $value = [Console]::ReadLine()

            if ($required -and [string]::IsNullOrWhiteSpace($value)) {
                Show-InfoMessage -Message "Field '$label' is required" -Title "Error" -Color "Red"
                return $null
            }

            $results[$name] = $value
        }

        $y += 2
    }

    return $results
}

# === SIMPLE TERMINAL ===
class PmcSimpleTerminal {
    static [PmcSimpleTerminal]$Instance = $null
    [int]$Width
    [int]$Height
    [bool]$CursorVisible = $true

    hidden PmcSimpleTerminal() {
        $this.UpdateDimensions()
    }

    static [PmcSimpleTerminal] GetInstance() {
        if ($null -eq [PmcSimpleTerminal]::Instance) {
            [PmcSimpleTerminal]::Instance = [PmcSimpleTerminal]::new()
        }
        return [PmcSimpleTerminal]::Instance
    }

    [void] Initialize() {
        [Console]::Clear()
        try {
            [Console]::CursorVisible = $false
            $this.CursorVisible = $false
        } catch { }
        $this.UpdateDimensions()
        [Console]::SetCursorPosition(0, 0)
    }

    [void] Cleanup() {
        try {
            [Console]::CursorVisible = $true
            $this.CursorVisible = $true
        } catch { }
        [Console]::Clear()
    }

    [void] UpdateDimensions() {
        try {
            $this.Width = [Console]::WindowWidth
            $this.Height = [Console]::WindowHeight
        } catch {
            $this.Width = 120
            $this.Height = 30
        }
    }

    [void] Clear() {
        [Console]::Clear()
        [Console]::SetCursorPosition(0, 0)
    }

    [void] WriteAt([int]$x, [int]$y, [string]$text) {
        if ([string]::IsNullOrEmpty($text) -or $x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) { $text = $text.Substring(0, $maxLength) }
        [Console]::SetCursorPosition($x, $y)
        [Console]::Write($text)
    }

    [void] WriteAtColor([int]$x, [int]$y, [string]$text, [string]$foreground, [string]$background = "") {
        if ([string]::IsNullOrEmpty($text) -or $x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) { $text = $text.Substring(0, $maxLength) }
        $colored = $foreground
        if (-not [string]::IsNullOrEmpty($background)) { $colored += $background }
        $colored += $text + [PmcVT100]::Reset()
        [Console]::SetCursorPosition($x, $y)
        [Console]::Write($colored)
    }

    [void] FillArea([int]$x, [int]$y, [int]$width, [int]$height, [char]$ch = ' ') {
        if ($width -le 0 -or $height -le 0) { return }
        $line = if ($ch -eq ' ') { [PmcStringCache]::GetSpaces($width) } else { [string]::new($ch, $width) }
        for ($row = 0; $row -lt $height; $row++) {
            $currentY = $y + $row
            if ($currentY -ge $this.Height) { break }
            $this.WriteAt($x, $currentY, $line)
        }
    }

    [void] DrawBox([int]$x, [int]$y, [int]$width, [int]$height) {
        if ($width -lt 2 -or $height -lt 2) { return }
        if ($x + $width -gt $this.Width -or $y + $height -gt $this.Height) { return }

        $tl = [PmcStringCache]::GetBoxDrawing("topleft")
        $tr = [PmcStringCache]::GetBoxDrawing("topright")
        $bl = [PmcStringCache]::GetBoxDrawing("bottomleft")
        $br = [PmcStringCache]::GetBoxDrawing("bottomright")
        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $v = [PmcStringCache]::GetBoxDrawing("vertical")

        $topLine = $tl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $tr
        $bottomLine = $bl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $br

        $this.WriteAtColor($x, $y, $topLine, [PmcVT100]::Cyan(), "")
        for ($row = 1; $row -lt $height - 1; $row++) {
            $this.WriteAtColor($x, $y + $row, $v, [PmcVT100]::Cyan(), "")
            $this.WriteAtColor($x + $width - 1, $y + $row, $v, [PmcVT100]::Cyan(), "")
        }
        $this.WriteAtColor($x, $y + $height - 1, $bottomLine, [PmcVT100]::Cyan(), "")
    }

    [void] DrawFilledBox([int]$x, [int]$y, [int]$width, [int]$height, [bool]$border = $true) {
        $this.FillArea($x, $y, $width, $height, ' ')
        if ($border) { $this.DrawBox($x, $y, $width, $height) }
    }

    [void] DrawHorizontalLine([int]$x, [int]$y, [int]$length) {
        if ($length -le 0) { return }
        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $line = [PmcStringCache]::GetSpaces($length).Replace(' ', $h)
        $this.WriteAtColor($x, $y, $line, [PmcVT100]::Cyan(), "")
    }

    [void] DrawFooter([string]$content) {
        $this.FillArea(0, $this.Height - 1, $this.Width, 1, ' ')
        $this.WriteAtColor(2, $this.Height - 1, $content, [PmcVT100]::Cyan(), "")
    }
}

# === MENU SYSTEM ===
class PmcMenuItem {
    [string]$Label
    [string]$Action
    [char]$Hotkey
    [bool]$Enabled = $true
    [bool]$Separator = $false

    PmcMenuItem([string]$label, [string]$action, [char]$hotkey) {
        $this.Label = $label
        $this.Action = $action
        $this.Hotkey = $hotkey
    }

    static [PmcMenuItem] Separator() {
        $item = [PmcMenuItem]::new("", "", ' ')
        $item.Separator = $true
        return $item
    }
}

class PmcMenuSystem {
    [PmcSimpleTerminal]$terminal
    [hashtable]$menus = @{}
    [string[]]$menuOrder = @()
    [int]$selectedMenu = -1
    [bool]$inMenuMode = $false
    [bool]$showingDropdown = $false

    PmcMenuSystem() {
        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.InitializeDefaultMenus()
    }

    [void] InitializeDefaultMenus() {
        $this.AddMenu('File', 'F', @(
            [PmcMenuItem]::new('Backup Data', 'file:backup', 'B'),
            [PmcMenuItem]::new('Restore Data', 'file:restore', 'R'),
            [PmcMenuItem]::new('Clear Backups', 'file:clearbackups', 'C'),
            [PmcMenuItem]::new('Exit', 'app:exit', 'X')
        ))
        $this.AddMenu('Tasks', 'T', @(
            [PmcMenuItem]::new('Task List', 'task:list', 'L')
        ))
        $this.AddMenu('Projects', 'P', @(
            [PmcMenuItem]::new('Project List', 'project:list', 'L')
        ))
        $this.AddMenu('Time', 'I', @(
            [PmcMenuItem]::new('Time Log', 'time:list', 'L'),
            [PmcMenuItem]::new('Weekly Report', 'tools:weeklyreport', 'W')
        ))
        $this.AddMenu('View', 'V', @(
            [PmcMenuItem]::new('Agenda', 'view:agenda', 'G'),
            [PmcMenuItem]::new('Today', 'view:today', 'T'),
            [PmcMenuItem]::new('Week', 'view:week', 'W'),
            [PmcMenuItem]::new('Month', 'view:month', 'M'),
            [PmcMenuItem]::new('Kanban Board', 'view:kanban', 'K'),
            [PmcMenuItem]::new('Burndown Chart', 'view:burndown', 'C'),
            [PmcMenuItem]::new('Help', 'view:help', 'H')
        ))
        $this.AddMenu('Tools', 'O', @(
            [PmcMenuItem]::new('Theme', 'tools:theme', 'T')
        ))
        $this.AddMenu('Help', 'H', @(
            [PmcMenuItem]::new('Help Browser', 'help:browser', 'B'),
            [PmcMenuItem]::new('About PMC', 'help:about', 'A')
        ))
    }

    [void] AddMenu([string]$name, [char]$hotkey, [PmcMenuItem[]]$items) {
        $this.menus[$name] = @{ Name = $name; Hotkey = $hotkey; Items = $items }
        $this.menuOrder += $name
    }

    [void] DrawMenuBar() {
        $this.terminal.UpdateDimensions()
        $this.terminal.FillArea(0, 0, $this.terminal.Width, 1, ' ')

        $x = 2
        for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
            $menuName = $this.menuOrder[$i]
            $menu = $this.menus[$menuName]
            $hotkey = $menu.Hotkey

            if ($this.inMenuMode -and $i -eq $this.selectedMenu) {
                $this.terminal.WriteAtColor($x, 0, $menuName, [PmcVT100]::BgWhite(), [PmcVT100]::Blue())
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor($x, 0, $menuName, [PmcVT100]::White(), "")
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Gray(), "")
            }
            $x += $menuName.Length + 6
        }

        $this.terminal.DrawHorizontalLine(0, 1, $this.terminal.Width)
    }

    [string] HandleInput() {
        while ($true) {
            $this.DrawMenuBar()
            $key = [Console]::ReadKey($true)

            if (-not $this.inMenuMode) {
                # Check Alt+letter menu activations FIRST (before generic Alt check)
                if ($key.Modifiers -eq 'Alt') {
                    # Check for Alt+menu hotkey (F, E, T, P, M, V, C, D, O, H)
                    $menuActivated = $false
                    for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                        $menuName = $this.menuOrder[$i]
                        $menu = $this.menus[$menuName]
                        if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                            $this.inMenuMode = $true
                            $this.selectedMenu = $i
                            $menuActivated = $true
                            break
                        }
                    }
                    if ($menuActivated) {
                        Write-FakeTUIDebug "Alt+$($key.Key) activated menu $($this.menuOrder[$this.selectedMenu])" "MENU"
                        # Show dropdown immediately instead of waiting for Enter
                        return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                    }
                    # Alt+X to exit
                    if ($key.Key -eq 'X') {
                        return "app:exit"
                    }
                }
                # F10 activates menu bar at position 0
                if ($key.Key -eq 'F10') {
                    $this.inMenuMode = $true
                    $this.selectedMenu = 0
                    continue
                }
                # Escape to exit
                if ($key.Key -eq 'Escape') {
                    return "app:exit"
                }
                return ""
            } else {
                switch ($key.Key) {
                    'LeftArrow' { if ($this.selectedMenu -gt 0) { $this.selectedMenu-- } else { $this.selectedMenu = $this.menuOrder.Count - 1 } }
                    'RightArrow' { if ($this.selectedMenu -lt $this.menuOrder.Count - 1) { $this.selectedMenu++ } else { $this.selectedMenu = 0 } }
                    'Enter' {
                        if ($this.selectedMenu -ge 0 -and $this.selectedMenu -lt $this.menuOrder.Count) {
                            return $this.ShowDropdown($this.menuOrder[$this.selectedMenu])
                        }
                    }
                    'Escape' { $this.inMenuMode = $false; $this.selectedMenu = -1 }
                }
            }
        }
        return ""
    }

    [string] ShowDropdown([string]$menuName) {
        $menu = $this.menus[$menuName]
        if (-not $menu) { return "" }
        $items = $menu.Items
        $dropdownX = 2; $dropdownY = 2; $maxWidth = 20
        $this.terminal.DrawFilledBox($dropdownX, $dropdownY, $maxWidth, $items.Count + 2, $true)

        $selectedItem = 0
        while ($true) {
            for ($i = 0; $i -lt $items.Count; $i++) {
                $item = $items[$i]
                $itemY = $dropdownY + 1 + $i
                $itemText = " {0}({1}) " -f $item.Label, $item.Hotkey
                if ($i -eq $selectedItem) {
                    $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2), [PmcVT100]::BgBlue(), [PmcVT100]::White())
                } else {
                    $this.terminal.WriteAt($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2))
                }
            }
            $key = [Console]::ReadKey($true)

            # Check for letter hotkeys
            $hotkeyPressed = $false
            for ($i = 0; $i -lt $items.Count; $i++) {
                if ($items[$i].Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                    $this.inMenuMode = $false
                    $this.selectedMenu = -1
                    $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $items.Count + 2, ' ')
                    return $items[$i].Action
                }
            }

            switch ($key.Key) {
                'UpArrow' { if ($selectedItem -gt 0) { $selectedItem-- } }
                'DownArrow' { if ($selectedItem -lt $items.Count - 1) { $selectedItem++ } }
                'Enter' {
                    $this.inMenuMode = $false
                    $this.selectedMenu = -1
                    $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $items.Count + 2, ' ')
                    return $items[$selectedItem].Action
                }
                'Escape' {
                    $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $items.Count + 2, ' ')
                    return ""
                }
            }
        }
        return ""
    }

    [string] GetActionDescription([string]$action) { return $action }
}

# === CLI ADAPTER ===
class PmcCLIAdapter {
    [hashtable] ExecuteAction([string]$action) {
        $parts = $action.Split(':')
        if ($parts.Count -ne 2) { return @{Type='error'; Message="Invalid action: $action"} }

        $domain = $parts[0]; $command = $parts[1]
        switch ($domain) {
            'app' { if ($command -eq 'exit') { return @{Type='exit'; Message='Exiting PMC...'} } }
            'task' {
                switch ($command) {
                    'add' { return @{Type='info'; Message='Task add - use CLI: task add <text>'} }
                    'list' {
                        try {
                            $data = Get-PmcAllData
                            $taskCount = $data.tasks.Count
                            $activeCount = @($data.tasks | Where-Object { $_.status -ne 'completed' }).Count
                            $text = "Total: $taskCount tasks | Active: $activeCount"
                            if ($taskCount -gt 0) {
                                $text += "`n`nRecent tasks:"
                                $recent = $data.tasks | Select-Object -First 5
                                foreach ($t in $recent) {
                                    $status = if ($t.status -eq 'completed') { '✓' } else { '○' }
                                    $text += "`n  $status [$($t.id)] $($t.text)"
                                }
                            }
                            return @{Type='success'; Message='PMC Tasks'; Data=$text}
                        } catch {
                            return @{Type='error'; Message="Failed to load tasks: $_"}
                        }
                    }
                }
            }
            'project' {
                switch ($command) {
                    'list' {
                        try {
                            $data = Get-PmcAllData
                            $projectCount = $data.projects.Count
                            $text = "Total: $projectCount projects"
                            if ($projectCount -gt 0) {
                                $text += "`n`nProjects:"
                                foreach ($p in $data.projects) {
                                    $text += "`n  • $($p.name)"
                                    if ($p.description) { $text += " - $($p.description)" }
                                }
                            }
                            return @{Type='success'; Message='PMC Projects'; Data=$text}
                        } catch {
                            return @{Type='error'; Message="Failed to load projects: $_"}
                        }
                    }
                }
            }
            'help' {
                $helpText = "PMC FakeTUI - Task Management Interface`n`n"
                $helpText += "Keybindings:`n"
                $helpText += "  F10      - Open menu bar`n"
                $helpText += "  Esc      - Exit / Close menu`n"
                $helpText += "  Alt+X    - Quick exit`n"
                $helpText += "`nUse CLI mode (./pmc.ps1 -CLI) for full commands"
                return @{Type='info'; Message='PMC Help'; Data=$helpText}
            }
        }
        return @{Type='error'; Message="Unknown action: $action"}
    }
}

# === MAIN APP ===
class PmcFakeTUIApp {
    [PmcSimpleTerminal]$terminal
    [PmcMenuSystem]$menuSystem
    [PmcCLIAdapter]$cliAdapter
    [bool]$running = $true
    [string]$statusMessage = ""
    [string]$currentView = 'main'  # main, tasklist, taskdetail
    [array]$tasks = @()
    [int]$selectedTaskIndex = 0
    [int]$scrollOffset = 0
    [object]$selectedTask = $null
    [string]$filterProject = ''  # Empty means show all
    [string]$searchText = ''  # Empty means no search
    [string]$sortBy = 'id'  # id, priority, status, created, due
    [hashtable]$stats = @{} # Performance stats
    [hashtable]$multiSelect = @{} # Task ID -> selected boolean
    [array]$projects = @()  # Project list
    [int]$selectedProjectIndex = 0  # Selected project in list
    [array]$timelogs = @()  # Time log entries
    [int]$selectedTimeIndex = 0  # Selected time entry in list

    PmcFakeTUIApp() {
        # Load saved theme preference first
        [PmcTheme]::LoadTheme()

        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.menuSystem = [PmcMenuSystem]::new()
        $this.cliAdapter = [PmcCLIAdapter]::new()
        $this.LoadTasks()
    }

    [void] LoadTasks() {
        try {
            $data = Get-PmcAllData
            $allTasks = @($data.tasks | Where-Object { $_ -ne $null })

            # Calculate stats
            $this.stats = @{
                total = $allTasks.Count
                active = @($allTasks | Where-Object { $_.status -ne 'completed' }).Count
                completed = @($allTasks | Where-Object { $_.status -eq 'completed' }).Count
                overdue = @($allTasks | Where-Object {
                    $_.due -and $_.status -ne 'completed' -and
                    ([DateTime]::Parse($_.due).Date -lt (Get-Date).Date)
                }).Count
            }

            if ($this.filterProject) {
                $allTasks = @($allTasks | Where-Object { $_.project -eq $this.filterProject })
            }

            if ($this.searchText) {
                $search = $this.searchText.ToLower()
                $allTasks = @($allTasks | Where-Object {
                    ($_.text -and $_.text.ToLower().Contains($search)) -or
                    ($_.project -and $_.project.ToLower().Contains($search)) -or
                    ($_.id -and $_.id.ToString().Contains($search))
                })
            }

            # Apply sorting
            switch ($this.sortBy) {
                'priority' {
                    $priorityOrder = @{ 'high' = 1; 'medium' = 2; 'low' = 3; 'none' = 4; $null = 5 }
                    $this.tasks = @($allTasks | Sort-Object { $priorityOrder[$_.priority] })
                }
                'status' {
                    $this.tasks = @($allTasks | Sort-Object status)
                }
                'created' {
                    $this.tasks = @($allTasks | Sort-Object created -Descending)
                }
                'due' {
                    # Sort by due date - overdue first (red), then upcoming, then none
                    $this.tasks = @($allTasks | Sort-Object {
                        if (-not $_.due) {
                            return [DateTime]::MaxValue
                        }
                        try {
                            return [DateTime]::Parse($_.due)
                        } catch {
                            return [DateTime]::MaxValue
                        }
                    })
                }
                default {
                    $this.tasks = @($allTasks | Sort-Object { [int]$_.id })
                }
            }
        } catch {
            $this.tasks = @()
        }
    }

    [void] LoadProjects() {
        try {
            $data = Get-PmcAllData
            $this.projects = if ($data.PSObject.Properties['projects']) {
                @($data.projects | Where-Object { $_ -ne $null })
            } else {
                @()
            }
        } catch {
            $this.projects = @()
        }
    }

    [void] LoadTimeLogs() {
        try {
            $data = Get-PmcAllData
            $this.timelogs = if ($data.PSObject.Properties['timelogs']) {
                @($data.timelogs | Where-Object { $_ -ne $null } | Sort-Object { $_.date } -Descending)
            } else {
                @()
            }
        } catch {
            $this.timelogs = @()
        }
    }

    [void] Initialize() {
        $this.terminal.Initialize()
        $this.DrawLayout()
        $this.statusMessage = "PMC Ready - F10 for menus, Esc to exit"
    }

    [void] DrawLayout() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.DrawBox(1, 3, $this.terminal.Width - 2, $this.terminal.Height - 6)
        $title = " PMC - Project Management Console "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        # Load and display quick stats
        try {
            $data = Get-PmcAllData
            $taskCount = $data.tasks.Count
            $activeCount = @($data.tasks | Where-Object { $_.status -ne 'completed' }).Count
            $projectCount = $data.projects.Count

            $this.terminal.WriteAtColor(4, 6, "Tasks: $taskCount total | Active: $activeCount | Completed: $($this.stats.completed)", [PmcVT100]::White(), "")
            if ($this.stats.overdue -gt 0) {
                $this.terminal.WriteAtColor(4, 7, "Overdue: ", [PmcVT100]::White(), "")
                $this.terminal.WriteAtColor(13, 7, "$($this.stats.overdue)", [PmcVT100]::Red(), "")
                $this.terminal.WriteAtColor(16, 7, " | Projects: $projectCount", [PmcVT100]::White(), "")
            } else {
                $this.terminal.WriteAtColor(4, 7, "Projects: $projectCount", [PmcVT100]::White(), "")
            }

            # Display recent tasks
            $this.terminal.WriteAtColor(4, 9, "Recent Tasks:", [PmcVT100]::Yellow(), "")
            $recentTasks = @($data.tasks | Sort-Object created -Descending | Select-Object -First 5)
            $y = 10
            foreach ($task in $recentTasks) {
                $statusIcon = if ($task.status -eq 'completed') { '✓' } else { '○' }
                $statusColor = if ($task.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Cyan() }
                $text = $task.text
                if ($text.Length -gt 40) { $text = $text.Substring(0, 37) + "..." }
                $this.terminal.WriteAtColor(4, $y, $statusIcon, $statusColor, "")
                $this.terminal.WriteAtColor(6, $y, "$($task.id): $text", [PmcVT100]::White(), "")
                $y++
            }

            $y++
            $this.terminal.WriteAtColor(4, $y++, "Quick Keys:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+T - Task list", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+A - Add task", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "Alt+P - Projects", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(6, $y++, "F10   - Menu bar", [PmcVT100]::Cyan(), "")
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading PMC data: $_", [PmcVT100]::Red(), "")
            Write-Host "DrawLayout error: $_" -ForegroundColor Red
            Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
        }
        $this.UpdateStatus()
    }

    [void] UpdateStatus() {
        $statusY = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')
        if ($this.statusMessage) { $this.terminal.WriteAtColor(2, $statusY, $this.statusMessage, [PmcVT100]::Cyan(), "") }
    }

    [void] ShowSuccessMessage([string]$message) {
        $statusY = $this.terminal.Height - 1
        $this.terminal.FillArea(0, $statusY, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAtColor(2, $statusY, "✓ $message", [PmcVT100]::Green(), "")
        Start-Sleep -Milliseconds 800
    }

    # Check for global menu/hotkeys - returns action string or empty if not a global key
    [string] CheckGlobalKeys([System.ConsoleKeyInfo]$key) {
        # F10 activates menu
        if ($key.Key -eq 'F10') {
            Write-FakeTUIDebug "F10 pressed, showing menu" "GLOBAL"
            $action = $this.menuSystem.HandleInput()
            return $action
        }

        # Ctrl+N for Quick Add (from anywhere)
        if ($key.Modifiers -eq 'Control' -and $key.Key -eq 'N') {
            Write-FakeTUIDebug "Ctrl+N pressed, opening Quick Add" "GLOBAL"
            return "task:add"
        }

        # Alt+letter activates specific menu
        if ($key.Modifiers -eq 'Alt') {
            # Check for Alt+menu hotkey
            for ($i = 0; $i -lt $this.menuSystem.menuOrder.Count; $i++) {
                $menuName = $this.menuSystem.menuOrder[$i]
                $menu = $this.menuSystem.menus[$menuName]
                if ($menu.Hotkey.ToString().ToUpper() -eq $key.Key.ToString().ToUpper()) {
                    Write-FakeTUIDebug "Alt+$($key.Key) pressed, showing dropdown for $menuName" "GLOBAL"
                    # Show dropdown directly instead of using HandleInput
                    $action = $this.menuSystem.ShowDropdown($menuName)
                    return $action
                }
            }
            # Alt+X to exit
            if ($key.Key -eq 'X') {
                return "app:exit"
            }
        }

        return ""
    }

    # Process menu action from any screen
    [void] ProcessMenuAction([string]$action) {
        Write-FakeTUIDebug "ProcessMenuAction: $action" "ACTION"

        # Try extended handlers first
        $handled = $false
        if ($this.PSObject.Methods['ProcessExtendedActions']) {
            $handled = $this.ProcessExtendedActions($action)
        }

        # Built-in handlers - ONLY set currentView, do NOT call Draw methods!
        if (-not $handled) {
            switch ($action) {
                # File menu
                'file:backup' { $this.currentView = 'filebackup' }
                'file:restore' { $this.currentView = 'filerestore' }
                'file:clearbackups' { $this.currentView = 'fileclearbackups' }
                'app:exit' { $this.running = $false }

                # Edit menu
                'edit:undo' { $this.currentView = 'editundo' }
                'edit:redo' { $this.currentView = 'editredo' }

                # Task menu
                'task:add' { $this.currentView = 'taskadd' }
                'task:list' { $this.currentView = 'tasklist' }
                'task:edit' { $this.currentView = 'taskedit' }
                'task:complete' { $this.currentView = 'taskcomplete' }
                'task:delete' { $this.currentView = 'taskdelete' }
                'task:copy' { $this.currentView = 'taskcopy' }
                'task:move' { $this.currentView = 'taskmove' }
                'task:find' { $this.currentView = 'search' }
                'task:priority' { $this.currentView = 'taskpriority' }
                'task:postpone' { $this.currentView = 'taskpostpone' }
                'task:note' { $this.currentView = 'tasknote' }
                'task:import' { $this.currentView = 'taskimport' }
                'task:export' { $this.currentView = 'taskexport' }

                # Project menu
                'project:list' { $this.currentView = 'projectlist' }
                'project:create' { $this.currentView = 'projectcreate' }
                'project:edit' { $this.currentView = 'projectedit' }
                'project:rename' { $this.currentView = 'projectrename' }
                'project:archive' { $this.currentView = 'projectarchive' }
                'project:delete' { $this.currentView = 'projectdelete' }
                'project:stats' { $this.currentView = 'projectstats' }
                'project:info' { $this.currentView = 'projectinfo' }
                'project:recent' { $this.currentView = 'projectrecent' }

                # Time menu
                'time:add' { $this.currentView = 'timeadd' }
                'time:list' { $this.currentView = 'timelist' }
                'time:edit' { $this.currentView = 'timeedit' }
                'time:delete' { $this.currentView = 'timedelete' }
                'time:report' { $this.currentView = 'timereport' }
                'timer:start' { $this.currentView = 'timerstart' }
                'timer:stop' { $this.currentView = 'timerstop' }
                'timer:status' { $this.currentView = 'timerstatus' }

                # View menu
                'view:agenda' { $this.currentView = 'agendaview' }
                'view:all' { $this.currentView = 'tasklist' }
                'view:today' {
                    $this.filterProject = ''
                    $this.searchText = ''
                    $this.currentView = 'todayview'
                }
                'view:tomorrow' { $this.currentView = 'tomorrowview' }
                'view:week' { $this.currentView = 'weekview' }
                'view:month' { $this.currentView = 'monthview' }
                'view:overdue' { $this.currentView = 'overdueview' }
                'view:upcoming' { $this.currentView = 'upcomingview' }
                'view:blocked' { $this.currentView = 'blockedview' }
                'view:noduedate' { $this.currentView = 'noduedateview' }
                'view:nextactions' { $this.currentView = 'nextactionsview' }
                'view:kanban' { $this.currentView = 'kanbanview' }
                'view:burndown' { $this.currentView = 'burndownview' }
                'view:help' { $this.currentView = 'help' }

                # Focus menu
                'focus:set' { $this.currentView = 'focusset' }
                'focus:clear' { $this.currentView = 'focusclear' }
                'focus:status' { $this.currentView = 'focusstatus' }

                # Dependencies menu
                'dep:add' { $this.currentView = 'depadd' }
                'dep:remove' { $this.currentView = 'depremove' }
                'dep:show' { $this.currentView = 'depshow' }
                'dep:graph' { $this.currentView = 'depgraph' }

                # Tools menu
                'tools:review' { $this.currentView = 'toolsreview' }
                'tools:wizard' { $this.currentView = 'toolswizard' }
                'tools:templates' { $this.currentView = 'toolstemplates' }
                'tools:statistics' { $this.currentView = 'toolsstatistics' }
                'tools:velocity' { $this.currentView = 'toolsvelocity' }
                'tools:preferences' { $this.currentView = 'toolspreferences' }
                'tools:config' { $this.currentView = 'toolsconfig' }
                'tools:theme' { $this.currentView = 'toolstheme' }
                'tools:aliases' { $this.currentView = 'toolsaliases' }
                'tools:query' { $this.currentView = 'toolsquery' }
                'tools:weeklyreport' { $this.currentView = 'toolsweeklyreport' }

                # Help menu
                'help:browser' { $this.currentView = 'helpbrowser' }
                'help:categories' { $this.currentView = 'helpcategories' }
                'help:search' { $this.currentView = 'helpsearch' }
                'help:about' { $this.currentView = 'helpabout' }
            }
        }
    }

    [void] DisplayResult([hashtable]$result) {
        $contentY = 5
        $this.terminal.FillArea(2, $contentY, $this.terminal.Width - 4, $this.terminal.Height - 8, ' ')
        switch ($result.Type) {
            'success' { $this.terminal.WriteAtColor(4, $contentY, "✓ SUCCESS: " + $result.Message, [PmcVT100]::Green(), "") }
            'error' { $this.terminal.WriteAtColor(4, $contentY, "✗ ERROR: " + $result.Message, [PmcVT100]::Red(), "") }
            'info' { $this.terminal.WriteAtColor(4, $contentY, "ℹ INFO: " + $result.Message, [PmcVT100]::Cyan(), "") }
            'exit' { $this.running = $false; return }
        }
        if ($result.Data) { $this.terminal.WriteAt(4, $contentY + 2, [string]$result.Data) }
        $this.statusMessage = "$($result.Type.ToUpper()): $($result.Message)"
        $this.UpdateStatus()
    }

    [void] Run() {
        while ($this.running) {
            if ($this.currentView -eq 'tasklist') {
                $this.HandleTaskListView()
            } elseif ($this.currentView -eq 'taskdetail') {
                $this.HandleTaskDetailView()
            } elseif ($this.currentView -eq 'taskadd') {
                $this.HandleTaskAddForm()
            } elseif ($this.currentView -eq 'taskedit') {
                # Already handled in HandleTaskDetailView
            } elseif ($this.currentView -eq 'projectfilter') {
                $this.HandleProjectFilter()
            } elseif ($this.currentView -eq 'search') {
                $this.HandleSearchForm()
            } elseif ($this.currentView -eq 'help') {
                $this.HandleHelpView()
            } elseif ($this.currentView -eq 'projectselect') {
                # Already handled in HandleTaskDetailView
            } elseif ($this.currentView -eq 'duedateedit') {
                # Already handled in HandleTaskDetailView
            } elseif ($this.currentView -eq 'multiselect') {
                # Already handled in HandleTaskListView
            } elseif ($this.currentView -eq 'multipriority') {
                # Already handled in HandleMultiSelectMode
            } elseif ($this.currentView -eq 'todayview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'overdueview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'upcomingview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'blockedview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'focusstatus') {
                $this.HandleFocusStatusView()
            } elseif ($this.currentView -eq 'timeadd') {
                $this.HandleTimeAddForm()
            } elseif ($this.currentView -eq 'timelist') {
                $this.HandleTimeListView()
            } elseif ($this.currentView -eq 'timereport') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'projectlist') {
                $this.HandleProjectListView()
            } elseif ($this.currentView -eq 'projectcreate') {
                $this.HandleProjectCreateForm()
            } elseif ($this.currentView -eq 'projectrename') {
                $this.HandleProjectRenameForm()
            } elseif ($this.currentView -eq 'projectarchive') {
                $this.HandleProjectArchiveForm()
            } elseif ($this.currentView -eq 'projectdelete') {
                $this.HandleProjectDeleteForm()
            } elseif ($this.currentView -eq 'projectstats') {
                $this.HandleProjectStatsView()
            } elseif ($this.currentView -eq 'timeedit') {
                $this.HandleTimeEditForm()
            } elseif ($this.currentView -eq 'timedelete') {
                $this.HandleTimeDeleteForm()
            } elseif ($this.currentView -eq 'taskimport') {
                $this.HandleTaskImportForm()
            } elseif ($this.currentView -eq 'taskexport') {
                $this.HandleTaskExportForm()
            } elseif ($this.currentView -eq 'timerstatus') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'taskedit') {
                $this.HandleTaskEditForm()
            } elseif ($this.currentView -eq 'taskcomplete') {
                $this.HandleTaskCompleteForm()
            } elseif ($this.currentView -eq 'taskdelete') {
                $this.HandleTaskDeleteForm()
            } elseif ($this.currentView -eq 'depadd') {
                $this.HandleDepAddForm()
            } elseif ($this.currentView -eq 'depremove') {
                $this.HandleDepRemoveForm()
            } elseif ($this.currentView -eq 'depshow') {
                $this.HandleDepShowForm()
            } elseif ($this.currentView -eq 'depgraph') {
                $this.HandleDependencyGraph()
            } elseif ($this.currentView -eq 'filerestore') {
                $this.HandleFileRestoreForm()
            } elseif ($this.currentView -eq 'editundo') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'editredo') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'tomorrowview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'weekview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'monthview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'noduedateview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'nextactionsview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'kanbanview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'burndownview') {
                $this.HandleBurndownChart()
            } elseif ($this.currentView -eq 'toolsreview') {
                $this.HandleStartReview()
            } elseif ($this.currentView -eq 'toolswizard') {
                $this.HandleProjectWizard()
            } elseif ($this.currentView -eq 'toolsconfig') {
                $this.HandleConfigEditor()
            } elseif ($this.currentView -eq 'toolstheme') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'toolsaliases') {
                $this.HandleManageAliases()
            } elseif ($this.currentView -eq 'toolsweeklyreport') {
                $this.HandleWeeklyReport()
            } elseif ($this.currentView -eq 'agendaview') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'taskcopy') {
                $this.HandleCopyTaskForm()
            } elseif ($this.currentView -eq 'taskmove') {
                $this.HandleMoveTaskForm()
            } elseif ($this.currentView -eq 'taskpriority') {
                $this.HandleSetPriorityForm()
            } elseif ($this.currentView -eq 'taskpostpone') {
                $this.HandlePostponeTaskForm()
            } elseif ($this.currentView -eq 'tasknote') {
                $this.HandleAddNoteForm()
            } elseif ($this.currentView -eq 'projectedit') {
                $this.HandleEditProjectForm()
            } elseif ($this.currentView -eq 'projectinfo') {
                $this.HandleProjectInfoView()
            } elseif ($this.currentView -eq 'projectrecent') {
                $this.HandleRecentProjectsView()
            } elseif ($this.currentView -eq 'timerstart') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'timerstop') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'focusclear') {
                $this.HandleSpecialView()
            } elseif ($this.currentView -eq 'toolstemplates') {
                $this.HandleTemplates()
            } elseif ($this.currentView -eq 'toolsstatistics') {
                $this.HandleStatistics()
            } elseif ($this.currentView -eq 'toolsvelocity') {
                $this.HandleVelocity()
            } elseif ($this.currentView -eq 'toolspreferences') {
                $this.HandlePreferences()
            } elseif ($this.currentView -eq 'toolsquery') {
                $this.HandleQueryBrowser()
            } elseif ($this.currentView -eq 'helpbrowser') {
                $this.HandleHelpBrowser()
            } elseif ($this.currentView -eq 'helpcategories') {
                $this.HandleHelpCategories()
            } elseif ($this.currentView -eq 'helpsearch') {
                $this.HandleHelpSearch()
            } elseif ($this.currentView -eq 'helpabout') {
                $this.HandleAboutPMC()
            } elseif ($this.currentView -eq 'filebackup') {
                $this.HandleBackupView()
            } elseif ($this.currentView -eq 'fileclearbackups') {
                $this.HandleClearBackupsView()
            } elseif ($this.currentView -eq 'focusset') {
                $this.HandleFocusSetForm()
            } else {
                # Fallback: show menu and process action
                $action = $this.menuSystem.HandleInput()
                if ($action) {
                    # Use centralized action routing
                    $this.ProcessMenuAction($action)
                }
            }
        }
    }

    [void] DrawTaskList() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Task List ($($this.tasks.Count) tasks) [Sort: $($this.sortBy)] "
        if ($this.searchText) {
            $title = " Search: '$($this.searchText)' ($($this.tasks.Count) tasks) [Sort: $($this.sortBy)] "
        } elseif ($this.filterProject) {
            $title = " Project: $($this.filterProject) ($($this.tasks.Count) tasks) [Sort: $($this.sortBy)] "
        }
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $headerY = 5
        $this.terminal.WriteAtColor(2, $headerY, "ID", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(8, $headerY, "Status", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(18, $headerY, "Pri", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(24, $headerY, "Task", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(76, $headerY, "Project", [PmcVT100]::Cyan(), "")
        $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

        $startY = $headerY + 2
        $maxRows = $this.terminal.Height - $startY - 3

        # Show empty state if no tasks
        if ($this.tasks.Count -eq 0) {
            $emptyY = $startY + 3
            $this.terminal.WriteAtColor(4, $emptyY++, "No tasks to display", [PmcVT100]::Yellow(), "")
            $emptyY++
            $this.terminal.WriteAtColor(4, $emptyY++, "Press 'A' to add your first task", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAt(4, $emptyY++, "Press '/' to search for tasks")
            $this.terminal.WriteAt(4, $emptyY++, "Press 'C' to clear filters")
        }

        for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.tasks.Count; $i++) {
            $taskIdx = $i + $this.scrollOffset
            $task = $this.tasks[$taskIdx]
            $y = $startY + $i
            $isSelected = ($taskIdx -eq $this.selectedTaskIndex)

            if ($isSelected) {
                $this.terminal.FillArea(0, $y, $this.terminal.Width, 1, ' ')
                $this.terminal.WriteAtColor(0, $y, ">", [PmcVT100]::Yellow(), "")
            }

            $statusIcon = if ($task.status -eq 'completed') { '✓' } else { '○' }
            $statusColor = if ($task.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Cyan() }

            $priSymbol = switch ($task.priority) {
                'high' { '!!!' }
                'medium' { '!!' }
                'low' { '!' }
                default { '-' }
            }
            $priColor = switch ($task.priority) {
                'high' { [PmcVT100]::Red() }
                'medium' { [PmcVT100]::Yellow() }
                'low' { [PmcVT100]::Green() }
                default { "" }
            }

            $this.terminal.WriteAt(2, $y, $task.id.ToString())
            $this.terminal.WriteAtColor(8, $y, $statusIcon, $statusColor, "")
            if ($priColor) {
                $this.terminal.WriteAtColor(18, $y, $priSymbol, $priColor, "")
            } else {
                $this.terminal.WriteAt(18, $y, $priSymbol)
            }

            $text = $task.text ?? ""
            $truncated = $false
            if ($text.Length -gt 50) {
                $text = $text.Substring(0, 47) + "..."
                $truncated = $true
            }
            $this.terminal.WriteAtColor(24, $y, $text, [PmcVT100]::White(), "")

            # Show full title in status bar if this task is selected and truncated
            if ($isSelected -and $truncated -and $task.text) {
                $this.terminal.FillArea(0, $this.terminal.Height - 2, $this.terminal.Width, 1, ' ')
                $fullText = "Full: $($task.text)"
                if ($fullText.Length -gt $this.terminal.Width - 4) {
                    $fullText = $fullText.Substring(0, $this.terminal.Width - 7) + "..."
                }
                $this.terminal.WriteAtColor(2, $this.terminal.Height - 2, $fullText, [PmcVT100]::Cyan(), "")
            }

            $project = $task.project ?? "none"
            if ($project.Length -gt 15) { $project = $project.Substring(0, 12) + "..." }
            $this.terminal.WriteAtColor(76, $y, $project, [PmcVT100]::Gray(), "")

            # Show overdue indicator
            if ($task.due) {
                try {
                    $dueDate = [DateTime]::Parse($task.due)
                    $today = Get-Date
                    if ($dueDate.Date -lt $today.Date -and $task.status -ne 'completed') {
                        $this.terminal.WriteAtColor(93, $y, "⚠", [PmcVT100]::Red(), "")
                    }
                } catch {}
            }
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $statusBar = "↑↓:Nav | Enter:Detail | A:Add | E:Edit | Del:Delete | M:Multi | D:Done | S:Sort | F:Filter | C:Clear"
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, $statusBar)
    }

    [void] HandleTaskListView() {
        $this.DrawTaskList()
        $key = [Console]::ReadKey($true)

        # Check for global menu keys first
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            Write-FakeTUIDebug "Global action from task list: $globalAction" "TASKLIST"
            # Process the action
            if ($globalAction -eq 'app:exit') {
                $this.running = $false
                return
            }
            # For other actions, set view and let Run() loop handle it
            $this.ProcessMenuAction($globalAction)
            return
        }

        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedTaskIndex -gt 0) {
                    $this.selectedTaskIndex--
                    if ($this.selectedTaskIndex -lt $this.scrollOffset) {
                        $this.scrollOffset = $this.selectedTaskIndex
                    }
                }

            }
            'DownArrow' {
                if ($this.selectedTaskIndex -lt $this.tasks.Count - 1) {
                    $this.selectedTaskIndex++
                    $maxRows = $this.terminal.Height - 10
                    if ($this.selectedTaskIndex -ge $this.scrollOffset + $maxRows) {
                        $this.scrollOffset = $this.selectedTaskIndex - $maxRows + 1
                    }
                }

            }
            'Enter' {
                if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                    $this.selectedTask = $this.tasks[$this.selectedTaskIndex]
                    $this.currentView = 'taskdetail'

                }
            }
            'D' {
                if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                    $task = $this.tasks[$this.selectedTaskIndex]
                    $task.status = 'completed'
                    try {
                        $data = Get-PmcAllData
                        Save-PmcData -Data $data -Action "Completed task $($task.id)"
                        $this.LoadTasks()
                        $this.DrawTaskList()
                        $this.ShowSuccessMessage("Task #$($task.id) completed")
                    } catch {}
                }
            }
            'A' {
                $this.currentView = 'taskadd'
            }
            'E' {
                # Edit selected task directly (not via task detail)
                if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                    $this.selectedTask = $this.tasks[$this.selectedTaskIndex]
                    $this.currentView = 'taskdetail'
                }
            }
            'Delete' {
                # Delete selected task with confirmation
                if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                    $task = $this.tasks[$this.selectedTaskIndex]
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "Delete task #$($task.id)? (y/N): ", [PmcVT100]::Yellow(), "")
                    $confirm = [Console]::ReadKey($true)
                    if ($confirm.Key -eq 'Y') {
                        try {
                            $taskId = $task.id
                            $data = Get-PmcAllData
                            $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                            Save-PmcData -Data $data -Action "Deleted task $taskId"
                            $this.LoadTasks()
                            if ($this.selectedTaskIndex -ge $this.tasks.Count -and $this.selectedTaskIndex -gt 0) {
                                $this.selectedTaskIndex--
                            }
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Task #$taskId deleted")
                        } catch {
                            Write-FakeTUIDebug "Delete task error: $($_.Exception.Message)" "ERROR"
                        }
                    }

                }
            }
            'C' {
                # Clear filters
                $this.searchText = ''
                $this.filterProject = ''
                $this.LoadTasks()
                $this.selectedTaskIndex = 0
                $this.scrollOffset = 0

            }
            'S' {
                $sortOptions = @('id', 'priority', 'status', 'created', 'due')
                $currentIdx = $sortOptions.IndexOf($this.sortBy)
                $newIdx = ($currentIdx + 1) % $sortOptions.Count
                $this.sortBy = $sortOptions[$newIdx]
                $this.LoadTasks()

            }
            'F' {
                $this.currentView = 'projectfilter'

            }
            'Divide' {  # Forward slash key
                $this.currentView = 'search'
                $this.DrawSearchForm()
            }
            'Spacebar' {
                if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                    $task = $this.tasks[$this.selectedTaskIndex]
                    $task.status = if ($task.status -eq 'completed') { 'active' } else { 'completed' }
                    try {
                        $data = Get-PmcAllData
                        Save-PmcData -Data $data -Action "Toggled task $($task.id)"
                        $this.LoadTasks()

                    } catch {}
                }
            }
            'H' {
                $this.currentView = 'help'
                $this.DrawHelpView()
            }
            'F1' {
                $this.currentView = 'help'
                $this.DrawHelpView()
            }
            'M' {
                # Multi-select mode toggle
                $this.currentView = 'multiselect'
                $this.DrawMultiSelectMode()
                $this.HandleMultiSelectMode()
            }
            'Escape' {
                $this.currentView = 'main'
                $this.DrawLayout()
            }
            'F10' {
                $this.currentView = 'main'
                $this.DrawLayout()
            }
        }
    }

    [void] DrawTaskDetail() {
        $this.terminal.Clear()
        $task = $this.selectedTask

        $title = " Task #$($task.id) "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 4
        $this.terminal.WriteAt(4, $y++, "Text: $($task.text)")
        $this.terminal.WriteAt(4, $y++, "Status: $($task.status ?? 'none')")
        $this.terminal.WriteAt(4, $y++, "Priority: $($task.priority ?? 'none')")
        $this.terminal.WriteAt(4, $y++, "Project: $($task.project ?? 'none')")

        if ($task.due) {
            $dueDisplay = $task.due
            try {
                $dueDate = [DateTime]::Parse($task.due)
                $today = Get-Date
                $daysUntil = ($dueDate.Date - $today.Date).Days

                if ($task.status -ne 'completed') {
                    if ($daysUntil -lt 0) {
                        $this.terminal.WriteAt(4, $y, "Due: ")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (OVERDUE by $([Math]::Abs($daysUntil)) days)", [PmcVT100]::Red(), "")
                        $y++
                    } elseif ($daysUntil -eq 0) {
                        $this.terminal.WriteAt(4, $y, "Due: ")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (TODAY)", [PmcVT100]::Yellow(), "")
                        $y++
                    } elseif ($daysUntil -eq 1) {
                        $this.terminal.WriteAt(4, $y, "Due: ")
                        $this.terminal.WriteAtColor(9, $y, "$dueDisplay (tomorrow)", [PmcVT100]::Cyan(), "")
                        $y++
                    } else {
                        $this.terminal.WriteAt(4, $y++, "Due: $dueDisplay (in $daysUntil days)")
                    }
                } else {
                    $this.terminal.WriteAt(4, $y++, "Due: $dueDisplay")
                }
            } catch {
                $this.terminal.WriteAt(4, $y++, "Due: $dueDisplay")
            }
        }

        if ($task.created) { $this.terminal.WriteAt(4, $y++, "Created: $($task.created)") }
        if ($task.modified) { $this.terminal.WriteAt(4, $y++, "Modified: $($task.modified)") }
        if ($task.completed -and ($task.status -eq 'completed' -or $task.status -eq 'done')) {
            $this.terminal.WriteAtColor(4, $y++, "Completed: $($task.completed)", [PmcVT100]::Green(), "")
        }

        # Display time logs if they exist
        try {
            $data = Get-PmcAllData
            if ($data.timelogs) {
                $taskLogs = @($data.timelogs | Where-Object { $_.taskId -eq $task.id -or $_.task -eq $task.id })
                if ($taskLogs.Count -gt 0) {
                    $totalMinutes = ($taskLogs | ForEach-Object { $_.minutes ?? 0 } | Measure-Object -Sum).Sum
                    $hours = [Math]::Floor($totalMinutes / 60)
                    $mins = $totalMinutes % 60
                    $y++
                    $this.terminal.WriteAtColor(4, $y++, "Time Logged: ${hours}h ${mins}m ($($taskLogs.Count) entries)", [PmcVT100]::Yellow(), "")
                }
            }
        } catch {}

        # Display notes if they exist
        if ($task.notes -and $task.notes.Count -gt 0) {
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Notes:", [PmcVT100]::Yellow(), "")
            foreach ($note in $task.notes) {
                $noteText = if ($note.text) { $note.text } elseif ($note -is [string]) { $note } else { $note.ToString() }
                $noteDate = if ($note.date) { $note.date } else { "" }
                if ($noteDate) {
                    $this.terminal.WriteAtColor(6, $y++, "• [$noteDate] $noteText", [PmcVT100]::Cyan(), "")
                } else {
                    $this.terminal.WriteAtColor(6, $y++, "• $noteText", [PmcVT100]::Cyan(), "")
                }
            }
        }

        $this.terminal.DrawFooter("↑↓:Nav | E:Edit | J:Project | T:Due | D:Done | P:Priority | Del:Delete | Esc:Back")
    }

    [void] HandleTaskDetailView() {
        $this.DrawTaskDetail()
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'E' {
                $this.currentView = 'taskedit'
            }
            'J' {
                $this.currentView = 'projectselect'
            }
            'T' {
                $this.currentView = 'duedateedit'
            }
            'D' {
                $this.selectedTask.status = 'completed'
                try {
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Completed task $($this.selectedTask.id)"
                    $this.LoadTasks()
                    $this.currentView = 'tasklist'
                } catch {}
            }
            'P' {
                $priorities = @('high', 'medium', 'low', 'none')
                $currentIdx = $priorities.IndexOf($this.selectedTask.priority ?? 'none')
                $newIdx = ($currentIdx + 1) % $priorities.Count
                $this.selectedTask.priority = if ($priorities[$newIdx] -eq 'none') { $null } else { $priorities[$newIdx] }
                try {
                    $data = Get-PmcAllData
                    Save-PmcData -Data $data -Action "Changed priority for task $($this.selectedTask.id)"
                    $this.LoadTasks()

                } catch {}
            }
            'X' {
                try {
                    $taskId = $this.selectedTask.id
                    $data = Get-PmcAllData
                    $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                    Save-PmcData -Data $data -Action "Deleted task $taskId"
                    $this.LoadTasks()
                    $this.currentView = 'tasklist'
                    if ($this.selectedTaskIndex -ge $this.tasks.Count) {
                        $this.selectedTaskIndex = [Math]::Max(0, $this.tasks.Count - 1)
                    }

                } catch {}
            }
            'Escape' {
                $this.currentView = 'tasklist'

            }
        }
    }

    [void] DrawTaskAddForm() {
        $this.terminal.Clear()

        $title = " Add New Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Task text:")
        $this.terminal.WriteAt(4, 6, "> ")

        $this.terminal.WriteAtColor(4, 8, "Quick Add Syntax:", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAt(6, 9, "@project  - Set project (e.g., @work)")
        $this.terminal.WriteAt(6, 10, "#priority - Set priority: #high #medium #low or #h #m #l")
        $this.terminal.WriteAt(6, 11, "!due      - Set due: !today !tomorrow !+7 (days)")
        $this.terminal.WriteAt(4, 13, "Example: Fix bug @myapp #high !tomorrow")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Type task with quick add syntax, Enter to save, Esc to cancel")
    }

    [void] HandleTaskAddForm() {
        # Get available projects
        $data = Get-PmcAllData
        $projectList = @('inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        # Use new widget-based approach with separate fields
        $input = Show-InputForm -Title "Add New Task" -Fields @(
            @{Name='text'; Label='Task description'; Required=$true; Type='text'}
            @{Name='project'; Label='Project'; Required=$false; Type='select'; Options=$projectList}
            @{Name='priority'; Label='Priority'; Required=$false; Type='select'; Options=@('high', 'medium', 'low')}
            @{Name='due'; Label='Due date (YYYY-MM-DD or today/tomorrow)'; Required=$false; Type='text'}
        )

        if ($null -eq $input) {
            $this.currentView = 'tasklist'
            return
        }

        $taskText = $input['text']
        if ($taskText.Length -lt 3) {
            Show-InfoMessage -Message "Task description must be at least 3 characters" -Title "Error" -Color "Red"
            $this.currentView = 'tasklist'
            return
        }

        try {
            $data = Get-PmcAllData
            $newId = if ($data.tasks.Count -gt 0) {
                ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
            } else { 1 }

            # Get values from form fields
            $project = if ([string]::IsNullOrWhiteSpace($input['project'])) { 'inbox' } else { $input['project'].Trim() }

            $priority = 'medium'
            if (-not [string]::IsNullOrWhiteSpace($input['priority'])) {
                $priInput = $input['priority'].Trim().ToLower()
                $priority = switch -Regex ($priInput) {
                    '^h(igh)?$' { 'high' }
                    '^l(ow)?$' { 'low' }
                    '^m(edium)?$' { 'medium' }
                    default { 'medium' }
                }
            }

            $due = $null
            if (-not [string]::IsNullOrWhiteSpace($input['due'])) {
                $dueInput = $input['due'].Trim().ToLower()
                $due = switch ($dueInput) {
                    'today' { (Get-Date).ToString('yyyy-MM-dd') }
                    'tomorrow' { (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
                    default {
                        # Try to parse as date
                        try {
                            $parsedDate = [DateTime]::Parse($dueInput)
                            $parsedDate.ToString('yyyy-MM-dd')
                        } catch {
                            $null
                        }
                    }
                }
            }

            $newTask = [PSCustomObject]@{
                id = $newId
                text = $taskText.Trim()
                status = 'active'
                priority = $priority
                project = $project
                due = $due
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            $data.tasks += $newTask

            # CRITICAL: Save with error handling that BLOCKS
            Save-PmcData -Data $data -Action "Added task $newId"

            # Only continue if save succeeded
            $this.LoadTasks()
            Show-InfoMessage -Message "Task #$newId added successfully: $($taskText.Trim())" -Title "Success" -Color "Green"

        } catch {
            # CRITICAL: Show error and BLOCK until user acknowledges
            Show-InfoMessage -Message "FAILED TO SAVE TASK: $_`n`nYour task was NOT saved. Please try again." -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'tasklist'
    }

    [void] DrawProjectFilter() {
        $this.terminal.Clear()

        $title = " Filter by Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { $_.name })
            $projectList = @('All') + $projectList

            $y = 5
            for ($i = 0; $i -lt $projectList.Count; $i++) {
                $project = $projectList[$i]
                $isSelected = if ($project -eq 'All') {
                    -not $this.filterProject
                } else {
                    $this.filterProject -eq $project
                }

                if ($isSelected) {
                    $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "  $project")
                }
            }
        } catch {}

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Back")
    }

    [void] HandleProjectFilter() {
        $this.DrawProjectFilter()
        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { $_.name })
            $projectList = @('All') + $projectList
            $selectedIdx = 0

            if ($this.filterProject) {
                $selectedIdx = $projectList.IndexOf($this.filterProject)
                if ($selectedIdx -lt 0) { $selectedIdx = 0 }
            }

            while ($true) {
                $this.terminal.Clear()
                $title = " Filter by Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 5
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $project = $projectList[$i]
                    if ($i -eq $selectedIdx) {
                        $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                    } else {
                        $this.terminal.WriteAt(4, $y + $i, "  $project")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Back")

                $key = [Console]::ReadKey($true)

                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $selected = $projectList[$selectedIdx]
                        if ($selected -eq 'All') {
                            $this.filterProject = ''
                        } else {
                            $this.filterProject = $selected
                        }
                        $this.LoadTasks()
                        $this.currentView = 'tasklist'
                        $this.selectedTaskIndex = 0
                        $this.scrollOffset = 0

                        break
                    }
                    'Escape' {
                        $this.currentView = 'tasklist'

                        break
                    }
                }
            }
        } catch {
            $this.currentView = 'tasklist'

        }
    }

    [void] DrawSearchForm() {
        $this.terminal.Clear()

        $title = " Search Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Search for:")
        $this.terminal.WriteAt(4, 6, "> ")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Type search term, Enter to search, Esc to cancel")
    }

    [void] HandleSearchForm() {
        $this.DrawSearchForm()
        $this.terminal.WriteAt(6, 6, "")
        $searchInput = ""
        $cursorX = 6

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Enter') {
                $this.searchText = $searchInput.Trim()
                $this.LoadTasks()
                $this.currentView = 'tasklist'
                $this.selectedTaskIndex = 0
                $this.scrollOffset = 0

                break
            } elseif ($key.Key -eq 'Escape') {
                $this.currentView = 'tasklist'

                break
            } elseif ($key.Key -eq 'Backspace') {
                if ($searchInput.Length -gt 0) {
                    $searchInput = $searchInput.Substring(0, $searchInput.Length - 1)
                    $cursorX = 6 + $searchInput.Length
                    $this.terminal.FillArea(6, 6, $this.terminal.Width - 7, 1, ' ')
                    $this.terminal.WriteAt(6, 6, $searchInput)
                }
            } else {
                $char = $key.KeyChar
                if ($char -and $char -ne "`0") {
                    $searchInput += $char
                    $this.terminal.WriteAt($cursorX, 6, $char.ToString())
                    $cursorX++
                }
            }
        }
    }

    [void] DrawHelpView() {
        $this.terminal.Clear()

        $title = " PMC FakeTUI - Keybindings & Help "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 4
        $this.terminal.WriteAtColor(4, $y++, "Global Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "F10       - Open menu bar")
        $this.terminal.WriteAt(6, $y++, "Esc       - Back / Close menus / Exit")
        $this.terminal.WriteAt(6, $y++, "Alt+X     - Quick exit PMC")
        $this.terminal.WriteAt(6, $y++, "Alt+T     - Open task list")
        $this.terminal.WriteAt(6, $y++, "Alt+A     - Add new task")
        $this.terminal.WriteAt(6, $y++, "Alt+P     - Project list")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Task List Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "↑↓        - Navigate tasks")
        $this.terminal.WriteAt(6, $y++, "Enter     - View task details")
        $this.terminal.WriteAt(6, $y++, "A         - Add new task")
        $this.terminal.WriteAt(6, $y++, "M         - Multi-select mode (bulk operations)")
        $this.terminal.WriteAt(6, $y++, "D         - Mark task complete")
        $this.terminal.WriteAt(6, $y++, "S         - Cycle sort order (id/priority/status/created/due)")
        $this.terminal.WriteAt(6, $y++, "F         - Filter by project")
        $this.terminal.WriteAt(6, $y++, "C         - Clear all filters")
        $this.terminal.WriteAt(6, $y++, "/         - Search tasks")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Multi-Select Mode Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "Space     - Toggle task selection")
        $this.terminal.WriteAt(6, $y++, "A         - Select all visible tasks")
        $this.terminal.WriteAt(6, $y++, "N         - Clear all selections")
        $this.terminal.WriteAt(6, $y++, "D         - Complete selected tasks")
        $this.terminal.WriteAt(6, $y++, "X         - Delete selected tasks")
        $this.terminal.WriteAt(6, $y++, "P         - Set priority for selected tasks")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Task Detail Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "E         - Edit task text")
        $this.terminal.WriteAt(6, $y++, "J         - Change project")
        $this.terminal.WriteAt(6, $y++, "T         - Set due date")
        $this.terminal.WriteAt(6, $y++, "D         - Mark as complete")
        $this.terminal.WriteAt(6, $y++, "P         - Cycle priority (high/medium/low/none)")
        $this.terminal.WriteAt(6, $y++, "X         - Delete task")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Quick Add Syntax:", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAt(6, $y++, "@project  - Set project (e.g., 'Fix bug @work')")
        $this.terminal.WriteAt(6, $y++, "#priority - Set priority: #high #medium #low or #h #m #l")
        $this.terminal.WriteAt(6, $y++, "!due      - Set due: !today !tomorrow !+7 (days)")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Features:", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAt(6, $y++, "• Real-time PMC data integration with persistent storage")
        $this.terminal.WriteAt(6, $y++, "• Quick add syntax for fast task creation (@project #priority !due)")
        $this.terminal.WriteAt(6, $y++, "• Multi-select mode for bulk operations (complete/delete/priority)")
        $this.terminal.WriteAt(6, $y++, "• Color-coded priorities and overdue warnings")
        $this.terminal.WriteAt(6, $y++, "• Project filtering, task search, and 5-way sorting")
        $this.terminal.WriteAt(6, $y++, "• Due date management with relative dates and smart indicators")
        $this.terminal.WriteAt(6, $y++, "• Scrollable lists, inline editing, full CRUD operations")

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleHelpView() {
        $this.DrawHelpView()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawProjectSelect() {
        $this.terminal.Clear()

        $title = " Change Task Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { $_.name })

            $y = 5
            for ($i = 0; $i -lt $projectList.Count; $i++) {
                $project = $projectList[$i]
                $isSelected = ($this.selectedTask.project -eq $project)

                if ($isSelected) {
                    $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "  $project")
                }
            }
        } catch {}

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
    }

    [void] HandleProjectSelect() {
        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | ForEach-Object { $_.name })
            $selectedIdx = $projectList.IndexOf($this.selectedTask.project)
            if ($selectedIdx -lt 0) { $selectedIdx = 0 }

            while ($true) {
                $this.terminal.Clear()
                $title = " Change Task Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 5
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $project = $projectList[$i]
                    if ($i -eq $selectedIdx) {
                        $this.terminal.WriteAtColor(4, $y + $i, "> $project", [PmcVT100]::Yellow(), "")
                    } else {
                        $this.terminal.WriteAt(4, $y + $i, "  $project")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $selected = $projectList[$selectedIdx]
                        try {
                            $data = Get-PmcAllData
                            $task = $data.tasks | Where-Object { $_.id -eq $this.selectedTask.id } | Select-Object -First 1
                            if ($task) {
                                $task.project = $selected
                                Save-PmcData -Data $data -Action "Changed project for task $($task.id) to $selected"
                                $this.LoadTasks()
                                $this.selectedTask = $task
                                $this.currentView = 'taskdetail'

                            }
                        } catch {}
                        break
                    }
                    'Escape' {
                        $this.currentView = 'taskdetail'

                        break
                    }
                }
            }
        } catch {
            $this.currentView = 'taskdetail'

        }
    }

    [void] DrawDueDateEdit() {
        $this.terminal.Clear()

        $title = " Set Due Date "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Current due date: $($this.selectedTask.due ?? 'none')")
        $this.terminal.WriteAt(4, 7, "Enter new due date (YYYY-MM-DD):")
        $this.terminal.WriteAt(4, 8, "> ")
        $this.terminal.WriteAt(4, 10, "Or press:")
        $this.terminal.WriteAt(6, 11, "1 - Today")
        $this.terminal.WriteAt(6, 12, "2 - Tomorrow")
        $this.terminal.WriteAt(6, 13, "3 - Next week (+7 days)")
        $this.terminal.WriteAt(6, 14, "C - Clear due date")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Type date or shortcut, Enter to save, Esc to cancel")
    }

    [void] HandleDueDateEdit() {
        $this.terminal.WriteAt(6, 8, "")
        $dateInput = ""
        $cursorX = 6

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Enter') {
                try {
                    $newDate = $null
                    if ($dateInput.Trim()) {
                        # Try to parse as date
                        try {
                            $newDate = [DateTime]::ParseExact($dateInput.Trim(), 'yyyy-MM-dd', $null).ToString('yyyy-MM-dd')
                        } catch {
                            # Invalid format
                            $this.terminal.WriteAtColor(4, 16, "Invalid date format! Use YYYY-MM-DD", [PmcVT100]::Red(), "")
                            Start-Sleep -Seconds 2
                            $this.DrawDueDateEdit()
                            $dateInput = ""
                            $cursorX = 6
                            continue
                        }
                    }

                    $data = Get-PmcAllData
                    $task = $data.tasks | Where-Object { $_.id -eq $this.selectedTask.id } | Select-Object -First 1
                    if ($task) {
                        $task.due = $newDate
                        Save-PmcData -Data $data -Action "Set due date for task $($task.id)"
                        $this.LoadTasks()
                        $this.selectedTask = $task
                        $this.currentView = 'taskdetail'

                    }
                } catch {
                    $this.terminal.WriteAtColor(4, 16, "Error: $_", [PmcVT100]::Red(), "")
                    Start-Sleep -Seconds 2
                }
                break
            } elseif ($key.Key -eq 'Escape') {
                $this.currentView = 'taskdetail'

                break
            } elseif ($key.KeyChar -eq '1') {
                $dateInput = (Get-Date).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq '2') {
                $dateInput = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq '3') {
                $dateInput = (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $this.terminal.WriteAt(6, 8, $dateInput)
                $cursorX = 6 + $dateInput.Length
            } elseif ($key.KeyChar -eq 'c' -or $key.KeyChar -eq 'C') {
                $dateInput = ""
                $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                $cursorX = 6
            } elseif ($key.Key -eq 'Backspace') {
                if ($dateInput.Length -gt 0) {
                    $dateInput = $dateInput.Substring(0, $dateInput.Length - 1)
                    $cursorX = 6 + $dateInput.Length
                    $this.terminal.FillArea(6, 8, $this.terminal.Width - 7, 1, ' ')
                    $this.terminal.WriteAt(6, 8, $dateInput)
                }
            } else {
                $char = $key.KeyChar
                if ($char -and $char -ne "`0" -and ($char -match '[0-9\-]')) {
                    $dateInput += $char
                    $this.terminal.WriteAt($cursorX, 8, $char.ToString())
                    $cursorX++
                }
            }
        }
    }

    [void] DrawMultiSelectMode() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $selectedCount = ($this.multiSelect.Values | Where-Object { $_ -eq $true }).Count
        $title = " Multi-Select Mode ($selectedCount selected) "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        $headerY = 5
        $this.terminal.WriteAt(2, $headerY, "Sel")
        $this.terminal.WriteAt(8, $headerY, "ID")
        $this.terminal.WriteAt(14, $headerY, "Status")
        $this.terminal.WriteAt(24, $headerY, "Pri")
        $this.terminal.WriteAt(30, $headerY, "Task")
        $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

        $startY = $headerY + 2
        $maxRows = $this.terminal.Height - $startY - 3

        for ($i = 0; $i -lt $maxRows -and ($i + $this.scrollOffset) -lt $this.tasks.Count; $i++) {
            $taskIdx = $i + $this.scrollOffset
            $task = $this.tasks[$taskIdx]
            $y = $startY + $i
            $isSelected = ($taskIdx -eq $this.selectedTaskIndex)
            $isMarked = $this.multiSelect[$task.id]

            if ($isSelected) {
                $this.terminal.FillArea(0, $y, $this.terminal.Width, 1, ' ')
                $this.terminal.WriteAtColor(0, $y, ">", [PmcVT100]::Yellow(), "")
            }

            $marker = if ($isMarked) { '[X]' } else { '[ ]' }
            $markerColor = if ($isMarked) { [PmcVT100]::Green() } else { "" }
            if ($markerColor) {
                $this.terminal.WriteAtColor(2, $y, $marker, $markerColor, "")
            } else {
                $this.terminal.WriteAt(2, $y, $marker)
            }

            $statusIcon = if ($task.status -eq 'completed') { '✓' } else { '○' }
            $this.terminal.WriteAt(8, $y, $task.id.ToString())
            $this.terminal.WriteAt(14, $y, $statusIcon)

            $priChar = ($task.priority ?? 'none').Substring(0,1).ToUpper()
            $this.terminal.WriteAt(24, $y, $priChar)

            $text = $task.text ?? ""
            if ($text.Length -gt 45) { $text = $text.Substring(0, 42) + "..." }
            $this.terminal.WriteAt(30, $y, $text)
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Space:Toggle | A:All | N:None | C:Complete | X:Delete | P:Priority | M:Move | Esc:Exit")
    }

    [void] HandleMultiSelectMode() {
        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow' {
                    if ($this.selectedTaskIndex -gt 0) {
                        $this.selectedTaskIndex--
                        if ($this.selectedTaskIndex -lt $this.scrollOffset) {
                            $this.scrollOffset = $this.selectedTaskIndex
                        }
                    }
                    $this.DrawMultiSelectMode()
                }
                'DownArrow' {
                    if ($this.selectedTaskIndex -lt $this.tasks.Count - 1) {
                        $this.selectedTaskIndex++
                        $maxRows = $this.terminal.Height - 10
                        if ($this.selectedTaskIndex -ge $this.scrollOffset + $maxRows) {
                            $this.scrollOffset = $this.selectedTaskIndex - $maxRows + 1
                        }
                    }
                    $this.DrawMultiSelectMode()
                }
                'Spacebar' {
                    if ($this.selectedTaskIndex -lt $this.tasks.Count) {
                        $task = $this.tasks[$this.selectedTaskIndex]
                        $this.multiSelect[$task.id] = -not $this.multiSelect[$task.id]
                        $this.DrawMultiSelectMode()
                    }
                }
                'A' {
                    foreach ($task in $this.tasks) {
                        $this.multiSelect[$task.id] = $true
                    }
                    $this.DrawMultiSelectMode()
                }
                'N' {
                    $this.multiSelect.Clear()
                    $this.DrawMultiSelectMode()
                }
                'C' {
                    # Complete selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        try {
                            $count = $selectedIds.Count
                            $data = Get-PmcAllData
                            foreach ($id in $selectedIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.status = 'completed'
                                    $task.completed = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                                }
                            }
                            Save-PmcData -Data $data -Action "Completed $count tasks"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.currentView = 'tasklist'
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Completed $count tasks")
                        } catch {}
                    }
                    break
                }
                'X' {
                    # Delete selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        try {
                            $count = $selectedIds.Count
                            $data = Get-PmcAllData
                            $data.tasks = @($data.tasks | Where-Object { $selectedIds -notcontains $_.id })
                            Save-PmcData -Data $data -Action "Deleted $count tasks"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.currentView = 'tasklist'
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Deleted $count tasks")
                        } catch {}
                    }
                    break
                }
                'P' {
                    # Set priority for selected tasks
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        $this.currentView = 'multipriority'
                        $this.DrawMultiPrioritySelect($selectedIds)
                        $this.HandleMultiPrioritySelect($selectedIds)
                    }
                    break
                }
                'M' {
                    # Move selected tasks to project
                    $selectedIds = @($this.multiSelect.Keys | Where-Object { $this.multiSelect[$_] })
                    if ($selectedIds.Count -gt 0) {
                        $this.currentView = 'multiproject'
                        $this.DrawMultiProjectSelect($selectedIds)
                        $this.HandleMultiProjectSelect($selectedIds)
                    }
                    break
                }
                'Escape' {
                    $this.multiSelect.Clear()
                    $this.currentView = 'tasklist'
                    $this.DrawTaskList()
                    break
                }
            }
        }
    }

    [void] DrawMultiPrioritySelect([array]$taskIds) {
        $this.terminal.Clear()

        $title = " Set Priority for $($taskIds.Count) tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $priorities = @('high', 'medium', 'low', 'none')
        $y = 5
        for ($i = 0; $i -lt $priorities.Count; $i++) {
            $pri = $priorities[$i]
            $color = switch ($pri) {
                'high' { [PmcVT100]::Red() }
                'medium' { [PmcVT100]::Yellow() }
                'low' { [PmcVT100]::Green() }
                default { "" }
            }
            if ($color) {
                $this.terminal.WriteAtColor(4, $y + $i, "  $pri", $color, "")
            } else {
                $this.terminal.WriteAt(4, $y + $i, "  $pri")
            }
        }

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
    }

    [void] HandleMultiPrioritySelect([array]$taskIds) {
        $priorities = @('high', 'medium', 'low', 'none')
        $selectedIdx = 1  # Default to medium

        while ($true) {
            $this.terminal.Clear()
            $title = " Set Priority for $($taskIds.Count) tasks "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            $y = 5
            for ($i = 0; $i -lt $priorities.Count; $i++) {
                $pri = $priorities[$i]
                $prefix = if ($i -eq $selectedIdx) { "> " } else { "  " }
                $color = switch ($pri) {
                    'high' { [PmcVT100]::Red() }
                    'medium' { [PmcVT100]::Yellow() }
                    'low' { [PmcVT100]::Green() }
                    default { "" }
                }
                if ($color) {
                    $this.terminal.WriteAtColor(4, $y + $i, "$prefix$pri", $color, "")
                } else {
                    $this.terminal.WriteAt(4, $y + $i, "$prefix$pri")
                }
            }

            $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
            $this.terminal.WriteAt(2, $this.terminal.Height - 1, "↑↓:Navigate | Enter:Select | Esc:Cancel")

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedIdx -gt 0) { $selectedIdx-- }
                }
                'DownArrow' {
                    if ($selectedIdx -lt $priorities.Count - 1) { $selectedIdx++ }
                }
                'Enter' {
                    $selectedPri = $priorities[$selectedIdx]
                    try {
                        $count = $taskIds.Count
                        $data = Get-PmcAllData
                        foreach ($id in $taskIds) {
                            $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                            if ($task) {
                                $task.priority = if ($selectedPri -eq 'none') { $null } else { $selectedPri }
                            }
                        }
                        Save-PmcData -Data $data -Action "Set priority to $selectedPri for $count tasks"
                        $this.multiSelect.Clear()
                        $this.LoadTasks()
                        $this.currentView = 'tasklist'
                        $this.DrawTaskList()
                        $this.ShowSuccessMessage("Set priority to $selectedPri for $count tasks")
                    } catch {}
                    break
                }
                'Escape' {
                    $this.currentView = 'multiselect'
                    $this.DrawMultiSelectMode()
                    $this.HandleMultiSelectMode()
                    break
                }
            }
        }
    }

    [void] DrawMultiProjectSelect([array]$taskIds) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Move $($taskIds.Count) tasks to Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | Select-Object -ExpandProperty name)

            if ($projectList.Count -eq 0) {
                $this.terminal.WriteAtColor(4, 6, "No projects available", [PmcVT100]::Yellow(), "")
            } else {
                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Select Project:", [PmcVT100]::Cyan(), "")
                $y++
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $this.terminal.WriteAt(4, $y++, "  $($projectList[$i])")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading projects: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")
    }

    [void] HandleMultiProjectSelect([array]$taskIds) {
        try {
            $data = Get-PmcAllData
            $projectList = @($data.projects | Select-Object -ExpandProperty name)

            if ($projectList.Count -eq 0) {
                [Console]::ReadKey($true) | Out-Null
                $this.currentView = 'multiselect'
                $this.DrawMultiSelectMode()
                $this.HandleMultiSelectMode()
                return
            }

            $selectedIdx = 0

            while ($true) {
                $this.terminal.Clear()
                $this.menuSystem.DrawMenuBar()

                $title = " Move $($taskIds.Count) tasks to Project "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Select Project:", [PmcVT100]::Cyan(), "")
                $y++
                for ($i = 0; $i -lt $projectList.Count; $i++) {
                    $prefix = if ($i -eq $selectedIdx) { "> " } else { "  " }
                    $color = if ($i -eq $selectedIdx) { [PmcVT100]::Yellow() } else { "" }
                    if ($color) {
                        $this.terminal.WriteAtColor(4, $y++, "$prefix$($projectList[$i])", $color, "")
                    } else {
                        $this.terminal.WriteAt(4, $y++, "$prefix$($projectList[$i])")
                    }
                }

                $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | Esc:Cancel")

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    'UpArrow' {
                        if ($selectedIdx -gt 0) { $selectedIdx-- }
                    }
                    'DownArrow' {
                        if ($selectedIdx -lt $projectList.Count - 1) { $selectedIdx++ }
                    }
                    'Enter' {
                        $selectedProject = $projectList[$selectedIdx]
                        try {
                            $count = $taskIds.Count
                            $data = Get-PmcAllData
                            foreach ($id in $taskIds) {
                                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                                if ($task) {
                                    $task.project = $selectedProject
                                }
                            }
                            Save-PmcData -Data $data -Action "Moved $count tasks to project $selectedProject"
                            $this.multiSelect.Clear()
                            $this.LoadTasks()
                            $this.currentView = 'tasklist'
                            $this.DrawTaskList()
                            $this.ShowSuccessMessage("Moved $count tasks to $selectedProject")
                        } catch {}
                        break
                    }
                    'Escape' {
                        $this.currentView = 'multiselect'
                        $this.DrawMultiSelectMode()
                        $this.HandleMultiSelectMode()
                        break
                    }
                }
            }
        } catch {
            [Console]::ReadKey($true) | Out-Null
            $this.currentView = 'multiselect'
            $this.DrawMultiSelectMode()
            $this.HandleMultiSelectMode()
        }
    }

    [void] DrawTomorrowView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Tomorrow's Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgCyan(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $tomorrow = (Get-Date).AddDays(1).Date
            $taskList = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and
                ([DateTime]::Parse($_.due).Date -eq $tomorrow)
            })

            if ($taskList.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "$($taskList.Count) task(s) due tomorrow:", [PmcVT100]::Cyan(), "")
                $y = 8
                foreach ($task in $taskList) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $pri = if ($task.priority) { "[$($task.priority)]" } else { "" }
                    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $pri $($task.text)")
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "No tasks due tomorrow", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawWeekView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " This Week's Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $weekEnd = $today.AddDays(7)

            # Get overdue tasks
            $overdue = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and ([DateTime]::Parse($_.due).Date -lt $today)
            } | Sort-Object { [DateTime]::Parse($_.due) })

            # Get tasks due this week
            $thisWeek = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and
                ([DateTime]::Parse($_.due).Date -ge $today -and [DateTime]::Parse($_.due).Date -le $weekEnd)
            } | Sort-Object { [DateTime]::Parse($_.due) })

            $y = 6

            # Show overdue tasks first
            if ($overdue.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== OVERDUE ($($overdue.Count)) ===", [PmcVT100]::BgRed(), [PmcVT100]::White())
                $y++
                foreach ($task in $overdue) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysOverdue = ($today - $dueDate.Date).Days
                    $this.terminal.WriteAtColor(4, $y++, "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)", [PmcVT100]::Red(), "")
                }
                $y++
            }

            # Show this week's tasks
            if ($thisWeek.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== DUE THIS WEEK ($($thisWeek.Count)) ===", [PmcVT100]::Green(), "")
                $y++
                foreach ($task in $thisWeek) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $dueDate = [DateTime]::Parse($task.due)
                    $dayName = $dueDate.ToString('ddd MMM dd')
                    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $dayName - $($task.text)")
                }
            }

            if ($overdue.Count -eq 0 -and $thisWeek.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No tasks due this week", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawMonthView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " This Month's Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $monthEnd = $today.AddDays(30)

            # Get overdue tasks
            $overdue = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and ([DateTime]::Parse($_.due).Date -lt $today)
            } | Sort-Object { [DateTime]::Parse($_.due) })

            # Get tasks due this month
            $thisMonth = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and
                ([DateTime]::Parse($_.due).Date -ge $today -and [DateTime]::Parse($_.due).Date -le $monthEnd)
            } | Sort-Object { [DateTime]::Parse($_.due) })

            # Get undated tasks
            $undated = @($data.tasks | Where-Object { $_.status -ne 'completed' -and -not $_.due })

            $y = 6

            # Show overdue tasks first
            if ($overdue.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== OVERDUE ($($overdue.Count)) ===", [PmcVT100]::BgRed(), [PmcVT100]::White())
                $y++
                foreach ($task in $overdue) {
                    if ($y -ge $this.terminal.Height - 5) { break }
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysOverdue = ($today - $dueDate.Date).Days
                    $this.terminal.WriteAtColor(4, $y++, "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)", [PmcVT100]::Red(), "")
                }
                $y++
            }

            # Show this month's tasks
            if ($thisMonth.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== DUE THIS MONTH ($($thisMonth.Count)) ===", [PmcVT100]::Cyan(), "")
                $y++
                foreach ($task in $thisMonth) {
                    if ($y -ge $this.terminal.Height - 5) { break }
                    $dueDate = [DateTime]::Parse($task.due)
                    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $($dueDate.ToString('MMM dd')) - $($task.text)")
                }
                $y++
            }

            # Show undated tasks
            if ($undated.Count -gt 0 -and $y -lt $this.terminal.Height - 5) {
                $this.terminal.WriteAtColor(4, $y++, "=== NO DUE DATE ($($undated.Count)) ===", [PmcVT100]::Yellow(), "")
                $y++
                foreach ($task in $undated) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $this.terminal.WriteAtColor(4, $y++, "[$($task.id)] $($task.text)", [PmcVT100]::Yellow(), "")
                }
            }

            if ($overdue.Count -eq 0 -and $thisMonth.Count -eq 0 -and $undated.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No active tasks", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawNoDueDateView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Tasks Without Due Date "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        try {
            $data = Get-PmcAllData
            $taskList = @($data.tasks | Where-Object { $_.status -ne 'completed' -and -not $_.due })

            if ($taskList.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "$($taskList.Count) task(s) without due date:", [PmcVT100]::Yellow(), "")
                $y = 8
                foreach ($task in $taskList) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $proj = if ($task.project) { "@$($task.project)" } else { "" }
                    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $($task.text) $proj")
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "All tasks have due dates!", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawNextActionsView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Next Actions "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            # Next actions: high priority, not blocked, active status
            $taskList = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and
                $_.status -ne 'blocked' -and
                $_.status -ne 'waiting' -and
                ($_.priority -eq 'high' -or -not $_.due -or ([DateTime]::Parse($_.due).Date -le (Get-Date).AddDays(7)))
            } | Sort-Object {
                if ($_.priority -eq 'high') { 0 }
                elseif ($_.priority -eq 'medium') { 1 }
                else { 2 }
            } | Select-Object -First 20)

            if ($taskList.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "$($taskList.Count) next action(s):", [PmcVT100]::Green(), "")
                $y = 8
                foreach ($task in $taskList) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $pri = if ($task.priority -eq 'high') { "[!]" } elseif ($task.priority -eq 'medium') { "[*]" } else { "[ ]" }
                    $due = if ($task.due) { " ($(([DateTime]::Parse($task.due)).ToString('MMM dd')))" } else { "" }
                    $this.terminal.WriteAt(4, $y++, "$pri [$($task.id)] $($task.text)$due")
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "No next actions found", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawTodayView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Today's Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $today = (Get-Date).Date

            # Get overdue tasks
            $overdue = @($data.tasks | Where-Object {
                $_.status -ne 'completed' -and $_.due -and ([DateTime]::Parse($_.due).Date -lt $today)
            } | Sort-Object { [DateTime]::Parse($_.due) })

            # Get today's tasks
            $todayTasks = @($data.tasks | Where-Object {
                $_.due -and ([DateTime]::Parse($_.due).Date -eq $today) -and $_.status -ne 'completed'
            })

            $y = 6

            # Show overdue tasks first
            if ($overdue.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== OVERDUE ($($overdue.Count)) ===", [PmcVT100]::BgRed(), [PmcVT100]::White())
                $y++
                foreach ($task in $overdue) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysOverdue = ($today - $dueDate.Date).Days
                    $this.terminal.WriteAtColor(4, $y++, "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)", [PmcVT100]::Red(), "")
                }
                $y++
            }

            # Show today's tasks
            if ($todayTasks.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "=== DUE TODAY ($($todayTasks.Count)) ===", [PmcVT100]::Cyan(), "")
                $y++
                foreach ($task in $todayTasks) {
                    if ($y -ge $this.terminal.Height - 3) { break }
                    $priColor = switch ($task.priority) {
                        'high' { [PmcVT100]::Red() }
                        'medium' { [PmcVT100]::Yellow() }
                        'low' { [PmcVT100]::Green() }
                        default { "" }
                    }
                    $pri = if ($task.priority) { "[$($task.priority.Substring(0,1).ToUpper())] " } else { "" }
                    if ($priColor) {
                        $this.terminal.WriteAtColor(4, $y++, "$pri[$($task.id)] $($task.text)", $priColor, "")
                    } else {
                        $this.terminal.WriteAt(4, $y++, "[$($task.id)] $($task.text)")
                    }
                }
            }

            if ($overdue.Count -eq 0 -and $todayTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No tasks due today", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading today's tasks: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawOverdueView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Overdue Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgRed(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $overdueTasks = @($data.tasks | Where-Object {
                $_.due -and ([DateTime]::Parse($_.due).Date -lt $today) -and $_.status -ne 'completed'
            })

            $y = 6
            if ($overdueTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No overdue tasks! 🎉", [PmcVT100]::Green(), "")
            } else {
                foreach ($task in $overdueTasks) {
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysOverdue = ($today - $dueDate.Date).Days
                    $this.terminal.WriteAtColor(4, $y, "[$($task.id)] ", [PmcVT100]::Red(), "")
                    $this.terminal.WriteAt(10, $y, "$($task.text) ")
                    $this.terminal.WriteAtColor(70, $y, "($daysOverdue days overdue)", [PmcVT100]::Red(), "")
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading overdue tasks: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawUpcomingView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Upcoming Tasks (Next 7 Days) "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $nextWeek = $today.AddDays(7)
            $upcomingTasks = @($data.tasks | Where-Object {
                $_.due -and ([DateTime]::Parse($_.due).Date -gt $today) -and
                ([DateTime]::Parse($_.due).Date -le $nextWeek) -and $_.status -ne 'completed'
            } | Sort-Object due)

            $y = 6
            if ($upcomingTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No upcoming tasks in the next 7 days", [PmcVT100]::Cyan(), "")
            } else {
                foreach ($task in $upcomingTasks) {
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysUntil = ($dueDate.Date - $today).Days
                    $this.terminal.WriteAt(4, $y, "[$($task.id)] $($task.text) ")
                    $this.terminal.WriteAtColor(70, $y, "(in $daysUntil days)", [PmcVT100]::Cyan(), "")
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading upcoming tasks: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawKanbanView() {
        $selectedCol = 0
        $selectedRow = 0
        $kanbanActive = $true

        # Initialize variables outside the loop to avoid scope issues
        $data = $null
        $columns = @()

        while ($kanbanActive) {
            $this.terminal.Clear()
            $this.menuSystem.DrawMenuBar()

            $title = " Interactive Kanban Board "
            $titleX = ($this.terminal.Width - $title.Length) / 2
            $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

            try {
                $data = Get-PmcAllData

                # Group by status with DONE column
                $columns = @(
                    @{Name='TODO'; Status=@('active', 'todo', ''); Color=[PmcVT100]::BgYellow(); TextColor=[PmcVT100]::Black(); Tasks=@()}
                    @{Name='IN PROGRESS'; Status=@('in-progress', 'started'); Color=[PmcVT100]::BgCyan(); TextColor=[PmcVT100]::Black(); Tasks=@()}
                    @{Name='BLOCKED'; Status=@('blocked', 'waiting'); Color=[PmcVT100]::BgRed(); TextColor=[PmcVT100]::White(); Tasks=@()}
                    @{Name='REVIEW'; Status=@('review'); Color=[PmcVT100]::BgGreen(); TextColor=[PmcVT100]::Black(); Tasks=@()}
                    @{Name='DONE'; Status=@('completed', 'done'); Color=[PmcVT100]::BgGreen(); TextColor=[PmcVT100]::White(); Tasks=@()}
                )

                # Populate columns
                foreach ($task in $data.tasks) {
                    $taskStatus = if ($task.status) { $task.status } else { '' }
                    for ($i = 0; $i -lt $columns.Count; $i++) {
                        if ($columns[$i].Status -contains $taskStatus) {
                            $columns[$i].Tasks += $task
                            break
                        }
                    }
                }

                # Limit DONE to last 10 tasks
                if ($columns[4].Tasks.Count -gt 10) {
                    $columns[4].Tasks = @($columns[4].Tasks | Select-Object -Last 10)
                }

                $colWidth = [math]::Floor(($this.terminal.Width - 12) / 5)
                $y = 5

                # Draw column title headers
                for ($i = 0; $i -lt $columns.Count; $i++) {
                    $col = $columns[$i]
                    $x = 2 + ($colWidth + 2) * $i
                    $titleText = "[$($i + 1)] $($col.Name)".PadRight($colWidth)
                    $this.terminal.WriteAtColor($x, $y, $titleText, [PmcVT100]::BgBlue(), [PmcVT100]::White())
                }

                $y++

                # Draw count headers
                for ($i = 0; $i -lt $columns.Count; $i++) {
                    $col = $columns[$i]
                    $x = 2 + ($colWidth + 2) * $i
                    $header = "($($col.Tasks.Count) tasks)".PadRight($colWidth)
                    $this.terminal.WriteAtColor($x, $y, $header, $col.Color, $col.TextColor)
                }

                $y += 2
                $maxRows = $this.terminal.Height - $y - 3

                # Draw separator lines between columns
                for ($i = 0; $i -lt $maxRows; $i++) {
                    for ($c = 1; $c -lt $columns.Count; $c++) {
                        $x = 2 + ($colWidth + 2) * $c - 1
                        $this.terminal.WriteAt($x, $y + $i, "│")
                    }
                }

                # Draw tasks
                for ($i = 0; $i -lt $maxRows; $i++) {
                    for ($c = 0; $c -lt $columns.Count; $c++) {
                        $col = $columns[$c]
                        if ($i -lt $col.Tasks.Count) {
                            $task = $col.Tasks[$i]
                            $x = 2 + ($colWidth + 2) * $c
                            $row = $y + $i

                            # Build task display text
                            $pri = if ($task.priority -eq 'high') { "[!]" } elseif ($task.priority -eq 'medium') { "[*]" } else { "" }
                            $due = if ($task.due) { " $((Get-Date -Date $task.due).ToString('MM/dd'))" } else { "" }
                            $text = "$pri[$($task.id)] $($task.text)$due"

                            if ($text.Length -gt $colWidth - 1) {
                                $text = $text.Substring(0, $colWidth - 4) + "..."
                            }

                            # Highlight if selected
                            if ($c -eq $selectedCol -and $i -eq $selectedRow) {
                                $this.terminal.WriteAtColor($x, $row, $text.PadRight($colWidth), [PmcVT100]::BgBlue(), [PmcVT100]::White())
                            } else {
                                # Color by priority
                                $taskColor = switch ($task.priority) {
                                    'high' { [PmcVT100]::Red() }
                                    'medium' { [PmcVT100]::Yellow() }
                                    default { "" }
                                }
                                if ($taskColor) {
                                    $this.terminal.WriteAtColor($x, $row, $text, $taskColor, "")
                                } else {
                                    $this.terminal.WriteAt($x, $row, $text)
                                }
                            }
                        }
                    }
                }

                $this.terminal.DrawFooter("←→:Column | ↑↓:Task | 1-5:Move To Column | Enter:Edit | D:Done | Esc:Exit")

            } catch {
                $this.terminal.WriteAtColor(4, 6, "Error loading kanban: $_", [PmcVT100]::Red(), "")
            }

            # Handle input
            $key = [Console]::ReadKey($true)

            # Check for global keys first
            $globalAction = $this.CheckGlobalKeys($key)
            if ($globalAction) {
                $this.ProcessMenuAction($globalAction)
                return
            }

            switch ($key.Key) {
                'LeftArrow' {
                    if ($selectedCol -gt 0) {
                        $selectedCol--
                        $selectedRow = 0
                    }
                }
                'RightArrow' {
                    if ($selectedCol -lt 4) {
                        $selectedCol++
                        $selectedRow = 0
                    }
                }
                'UpArrow' {
                    if ($selectedRow -gt 0) {
                        $selectedRow--
                    }
                }
                'DownArrow' {
                    $maxRow = $columns[$selectedCol].Tasks.Count - 1
                    if ($selectedRow -lt $maxRow) {
                        $selectedRow++
                    }
                }
                'D' {
                    # Mark task as done
                    if ($columns[$selectedCol].Tasks.Count -gt $selectedRow) {
                        $task = $columns[$selectedCol].Tasks[$selectedRow]
                        try {
                            $task.status = 'done'
                            Save-PmcData -Data $data -Action "Marked task $($task.id) as done"
                            Show-InfoMessage -Message "Task marked as done!" -Title "Success" -Color "Green"
                            $selectedRow = 0
                        } catch {
                            Show-InfoMessage -Message "Failed to update task: $_" -Title "Error" -Color "Red"
                        }
                    }
                }
                'Escape' {
                    $kanbanActive = $false
                    $this.currentView = 'tasklist'
                }
            }

            # Number keys 1-5 to move task to column
            if ($key.KeyChar -ge '1' -and $key.KeyChar -le '5') {
                $targetCol = [int]$key.KeyChar.ToString() - 1
                if ($columns[$selectedCol].Tasks.Count -gt $selectedRow) {
                    $task = $columns[$selectedCol].Tasks[$selectedRow]
                    $newStatus = $columns[$targetCol].Status[0]

                    try {
                        $task.status = $newStatus
                        Save-PmcData -Data $data -Action "Moved task $($task.id) to $($columns[$targetCol].Name)"
                        $selectedRow = 0
                    } catch {
                        Show-InfoMessage -Message "Failed to move task: $_" -Title "Error" -Color "Red"
                    }
                }
            }
        }
    }

    [void] DrawAgendaView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Agenda View "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $activeTasks = @($data.tasks | Where-Object { $_.status -ne 'completed' })

            # Group tasks by date
            $overdue = @()
            $today = @()
            $tomorrow = @()
            $thisWeek = @()
            $later = @()
            $noDue = @()

            $nowDate = Get-Date
            $todayDate = $nowDate.Date
            $tomorrowDate = $todayDate.AddDays(1)
            $weekEndDate = $todayDate.AddDays(7)

            foreach ($task in $activeTasks) {
                if ($task.due) {
                    try {
                        $dueDate = [DateTime]::Parse($task.due).Date
                        if ($dueDate -lt $todayDate) {
                            $overdue += $task
                        } elseif ($dueDate -eq $todayDate) {
                            $today += $task
                        } elseif ($dueDate -eq $tomorrowDate) {
                            $tomorrow += $task
                        } elseif ($dueDate -le $weekEndDate) {
                            $thisWeek += $task
                        } else {
                            $later += $task
                        }
                    } catch {
                        $noDue += $task
                    }
                } else {
                    $noDue += $task
                }
            }

            $y = 6

            if ($overdue.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "OVERDUE ($($overdue.Count)):", [PmcVT100]::Red(), "")
                foreach ($task in ($overdue | Select-Object -First 5)) {
                    $dueDate = [DateTime]::Parse($task.due)
                    $daysOverdue = ($todayDate - $dueDate.Date).Days
                    $this.terminal.WriteAtColor(6, $y++, "[$($task.id)] $($task.text) (-$daysOverdue days)", [PmcVT100]::Red(), "")
                }
                if ($overdue.Count -gt 5) {
                    $this.terminal.WriteAt(6, $y++, "... and $($overdue.Count - 5) more")
                }
                $y++
            }

            if ($today.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "TODAY ($($today.Count)):", [PmcVT100]::Yellow(), "")
                foreach ($task in ($today | Select-Object -First 5)) {
                    $this.terminal.WriteAt(6, $y++, "[$($task.id)] $($task.text)")
                }
                if ($today.Count -gt 5) {
                    $this.terminal.WriteAt(6, $y++, "... and $($today.Count - 5) more")
                }
                $y++
            }

            if ($tomorrow.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "TOMORROW ($($tomorrow.Count)):", [PmcVT100]::Cyan(), "")
                foreach ($task in ($tomorrow | Select-Object -First 3)) {
                    $this.terminal.WriteAt(6, $y++, "[$($task.id)] $($task.text)")
                }
                if ($tomorrow.Count -gt 3) {
                    $this.terminal.WriteAt(6, $y++, "... and $($tomorrow.Count - 3) more")
                }
                $y++
            }

            if ($thisWeek.Count -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "THIS WEEK ($($thisWeek.Count)):", [PmcVT100]::Green(), "")
                foreach ($task in ($thisWeek | Select-Object -First 3)) {
                    $dueDate = [DateTime]::Parse($task.due)
                    $this.terminal.WriteAt(6, $y++, "[$($task.id)] $($task.text) ($($dueDate.ToString('ddd MMM dd')))")
                }
                if ($thisWeek.Count -gt 3) {
                    $this.terminal.WriteAt(6, $y++, "... and $($thisWeek.Count - 3) more")
                }
                $y++
            }

            if ($later.Count -gt 0) {
                $this.terminal.WriteAt(4, $y++, "LATER ($($later.Count))")
                $y++
            }

            if ($noDue.Count -gt 0) {
                $this.terminal.WriteAt(4, $y++, "NO DUE DATE ($($noDue.Count))")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading agenda: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawBlockedView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Blocked/Waiting Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgYellow(), [PmcVT100]::Black())

        try {
            $data = Get-PmcAllData
            $blockedTasks = @($data.tasks | Where-Object {
                $_.status -eq 'blocked' -or $_.status -eq 'waiting'
            })

            $y = 6
            if ($blockedTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No blocked tasks", [PmcVT100]::Green(), "")
            } else {
                foreach ($task in $blockedTasks) {
                    $this.terminal.WriteAt(4, $y, "[$($task.id)] $($task.text) ")
                    $statusColor = if ($task.status -eq 'blocked') { [PmcVT100]::Red() } else { [PmcVT100]::Yellow() }
                    $this.terminal.WriteAtColor(70, $y, "($($task.status))", $statusColor, "")
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading blocked tasks: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleSpecialView() {
        # Draw the appropriate view based on currentView
        switch ($this.currentView) {
            'todayview' { $this.DrawTodayView() }
            'tomorrowview' { $this.DrawTomorrowView() }
            'weekview' { $this.DrawWeekView() }
            'monthview' { $this.DrawMonthView() }
            'overdueview' { $this.DrawOverdueView() }
            'upcomingview' { $this.DrawUpcomingView() }
            'blockedview' { $this.DrawBlockedView() }
            'noduedateview' { $this.DrawNoDueDateView() }
            'nextactionsview' { $this.DrawNextActionsView() }
            'kanbanview' { $this.DrawKanbanView() }
            'agendaview' { $this.DrawAgendaView() }
            'timereport' { $this.DrawTimeReport() }
            'timerstatus' { $this.DrawTimerStatus() }
            'timerstart' {
                $this.DrawTimerStart()
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'S') {
                    try {
                        Start-PmcTimer
                        Show-InfoMessage -Message "Timer started successfully" -Title "Success" -Color "Green"
                    } catch {
                        Show-InfoMessage -Message "Failed to start timer: $_" -Title "Error" -Color "Red"
                    }
                }
                $this.currentView = 'tasklist'
                return
            }
            'timerstop' {
                $this.DrawTimerStop()
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'S') {
                    try {
                        $result = Stop-PmcTimer
                        Show-InfoMessage -Message "Timer stopped. Elapsed: $($result.Elapsed) hours" -Title "Success" -Color "Green"
                    } catch {
                        Show-InfoMessage -Message "Failed to stop timer: $_" -Title "Error" -Color "Red"
                    }
                }
                $this.currentView = 'tasklist'
                return
            }
            'editundo' {
                $this.DrawUndoView()
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'U') {
                    try {
                        $status = Get-PmcUndoStatus
                        $action = if ($status.LastAction) { $status.LastAction } else { "last change" }
                        Invoke-PmcUndo
                        $this.LoadTasks()
                        Show-InfoMessage -Message "Undone: $action" -Title "Success" -Color "Green"
                    } catch {
                        Show-InfoMessage -Message "Failed to undo: $_" -Title "Error" -Color "Red"
                    }
                }
                $this.currentView = 'tasklist'
                return
            }
            'editredo' {
                $this.DrawRedoView()
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'R') {
                    try {
                        Invoke-PmcRedo
                        $this.LoadTasks()
                        Show-InfoMessage -Message "Redone: last undone change" -Title "Success" -Color "Green"
                    } catch {
                        Show-InfoMessage -Message "Failed to redo: $_" -Title "Error" -Color "Red"
                    }
                }
                $this.currentView = 'tasklist'
                return
            }
            'focusclear' {
                $this.terminal.Clear()
                $this.menuSystem.DrawMenuBar()
                $title = " Clear Focus "
                $titleX = ($this.terminal.Width - $title.Length) / 2
                $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                try {
                    Clear-PmcFocus
                    $this.terminal.WriteAtColor(4, 6, "✓ Focus cleared successfully", [PmcVT100]::Green(), "")
                } catch {
                    $this.terminal.WriteAtColor(4, 6, "✗ Error: $_", [PmcVT100]::Red(), "")
                }

                $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
                $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
                [Console]::ReadKey($true) | Out-Null
                $this.currentView = 'tasklist'
                return
            }
            'toolstheme' {
                $selectedTheme = 1
                $themeActive = $true
                while ($themeActive) {
                    # Draw the theme selection screen
                    $this.terminal.Clear()
                    $this.menuSystem.DrawMenuBar()

                    $title = " Theme Editor "
                    $titleX = ($this.terminal.Width - $title.Length) / 2
                    $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

                    $y = 6
                    $this.terminal.WriteAtColor(4, $y++, "Select theme to preview:", [PmcVT100]::Cyan(), "")
                    $y++

                    # Draw theme options with selection indicator
                    $themes = @(
                        @{Num=1; Name="Default"; Desc="Standard color scheme"}
                        @{Num=2; Name="Dark"; Desc="High contrast dark theme"}
                        @{Num=3; Name="Light"; Desc="Light background theme"}
                        @{Num=4; Name="Solarized"; Desc="Solarized color palette"}
                        @{Num=5; Name="Matrix"; Desc="Green terminal/Matrix style"}
                        @{Num=6; Name="Amber"; Desc="Amber monochrome/retro CRT"}
                        @{Num=7; Name="Synthwave"; Desc="80s neon/synthwave aesthetic"}
                    )

                    foreach ($theme in $themes) {
                        $indicator = if ($theme.Num -eq $selectedTheme) { "▶ " } else { "  " }
                        $color = if ($theme.Num -eq $selectedTheme) { [PmcVT100]::Yellow() } else { [PmcVT100]::White() }
                        $this.terminal.WriteAtColor(4, $y++, "$indicator$($theme.Num). $($theme.Name) - $($theme.Desc)", $color, "")
                    }
                    $y++

                    # Show color preview for selected theme
                    $themeName = $themes[$selectedTheme - 1].Name
                    [PmcTheme]::SetTheme($themeName)  # Temporarily set for preview

                    $this.terminal.WriteAtColor(4, $y++, "Preview of selected theme:", [PmcVT100]::Cyan(), "")
                    $y++
                    $this.terminal.WriteAtColor(6, $y++, "• Success/Completed", [PmcVT100]::Green(), "")
                    $this.terminal.WriteAtColor(6, $y++, "• Errors/Warnings", [PmcVT100]::Red(), "")
                    $this.terminal.WriteAtColor(6, $y++, "• Information", [PmcVT100]::Cyan(), "")
                    $this.terminal.WriteAtColor(6, $y++, "• Highlights", [PmcVT100]::Yellow(), "")
                    $this.terminal.WriteAtColor(6, $y++, "• Normal Text", [PmcVT100]::White(), "")
                    $this.terminal.WriteAtColor(6, $y++, "• Dimmed Text", [PmcVT100]::Gray(), "")

                    $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
                    $this.terminal.WriteAt(2, $this.terminal.Height - 1, "1-7:Select | Enter:Apply | Esc:Cancel")

                    $key = [Console]::ReadKey($true)

                    if ($key.KeyChar -ge '1' -and $key.KeyChar -le '7') {
                        $selectedTheme = [int]$key.KeyChar.ToString()
                    } elseif ($key.Key -eq 'Enter') {
                        $themeName = $themes[$selectedTheme - 1].Name
                        try {
                            # Actually apply the theme
                            [PmcTheme]::SetTheme($themeName)
                            Show-InfoMessage -Message "Applied $themeName theme and saved preference" -Title "Success" -Color "Green"
                            $themeActive = $false
                        } catch {
                            Show-InfoMessage -Message "Failed to apply theme: $_" -Title "Error" -Color "Red"
                        }
                    } elseif ($key.Key -eq 'Escape') {
                        $themeActive = $false
                    }
                }
                $this.currentView = 'tasklist'
                return
            }
            'fileclearbackups' { $this.DrawClearBackupsView() }
        }
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    [void] DrawBackupView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Backup Data "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $backups = @()
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $backups += [PSCustomObject]@{
                        Number = $i
                        File = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                    }
                }
            }

            if ($backups.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "Existing Backups:", [PmcVT100]::Cyan(), "")
                $y = 8
                foreach ($backup in $backups) {
                    $sizeKB = [math]::Round($backup.Size / 1KB, 2)
                    $line = "  .bak$($backup.Number)  -  $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB"
                    $this.terminal.WriteAt(4, $y++, $line)
                }

                $y++
                $this.terminal.WriteAtColor(4, $y, "Main data file:", [PmcVT100]::Cyan(), "")
                $y++
                if (Test-Path $file) {
                    $mainInfo = Get-Item $file
                    $sizeKB = [math]::Round($mainInfo.Length / 1KB, 2)
                    $this.terminal.WriteAt(4, $y++, "  $file")
                    $this.terminal.WriteAt(4, $y++, "  Modified: $($mainInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  -  $sizeKB KB")
                }

                $y += 2
                $this.terminal.WriteAtColor(4, $y++, "Press 'C' to create manual backup now", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, $y, "Backups are automatically created on every save (up to 9 retained)")
            } else {
                $this.terminal.WriteAtColor(4, 8, "No backups found.", [PmcVT100]::Yellow(), "")
                $y = 10
                $this.terminal.WriteAt(4, $y++, "Backups are automatically created when data is saved.")
                $this.terminal.WriteAt(4, $y++, "Up to 9 backups are retained (.bak1 through .bak9)")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'C' to create manual backup now", [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error loading backup info: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "C:Create Backup | Esc:Back")
    }

    [void] HandleBackupView() {
        $this.DrawBackupView()
        $key = [Console]::ReadKey($true)

        if ($key.Key -eq 'C') {
            try {
                $file = Get-PmcTaskFilePath
                if (Test-Path $file) {
                    # Rotate backups
                    for ($i = 8; $i -ge 1; $i--) {
                        $src = "$file.bak$i"
                        $dst = "$file.bak$($i+1)"
                        if (Test-Path $src) {
                            Move-Item -Force $src $dst
                        }
                    }
                    Copy-Item $file "$file.bak1" -Force

                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "✓ Backup created successfully!", [PmcVT100]::Green(), "")
                    Start-Sleep -Seconds 1
                    # Redraw to show updated backup list
                    $this.HandleBackupView()
                    return
                }
            } catch {
                $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "✗ Error creating backup: $_", [PmcVT100]::Red(), "")
                Start-Sleep -Seconds 2
            }
        }

        $this.currentView = 'tasklist'
    }

    [void] DrawTimerStatus() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Timer Status "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is RUNNING", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAt(4, $y++, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, $y++, "Elapsed: $($status.Elapsed)h")
                if ($status.Task) {
                    $y++
                    $this.terminal.WriteAt(4, $y++, "Task: $($status.Task)")
                }
                if ($status.Project) {
                    $this.terminal.WriteAt(4, $y++, "Project: $($status.Project)")
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "Timer is not running", [PmcVT100]::Yellow(), "")
                if ($status.LastElapsed) {
                    $this.terminal.WriteAt(4, 8, "Last session: $($status.LastElapsed)h")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawTimerStart() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Start Timer "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgGreen(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is already running!", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(4, 8, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, 9, "Elapsed: $($status.Elapsed)h")
            } else {
                $this.terminal.WriteAtColor(4, 6, "Press 'S' to start the timer", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, 8, "This will track your work time for logging.")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "S:Start | Esc:Cancel")
    }

    [void] DrawTimerStop() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Stop Timer "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgRed(), [PmcVT100]::White())

        try {
            $status = Get-PmcTimerStatus
            if ($status.Running) {
                $this.terminal.WriteAtColor(4, 6, "Timer is running", [PmcVT100]::Green(), "")
                $this.terminal.WriteAt(4, 8, "Started: $($status.StartTime)")
                $this.terminal.WriteAt(4, 9, "Elapsed: $($status.Elapsed)h")
                $y = 11
                $this.terminal.WriteAtColor(4, $y, "Press 'S' to stop and log this time", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "Timer is not running", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(4, 8, "There is nothing to stop.")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "S:Stop | Esc:Cancel")
    }

    [void] DrawUndoView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Undo Last Change "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcUndoStatus
            if ($status.UndoAvailable) {
                $this.terminal.WriteAtColor(4, 6, "Undo stack has $($status.UndoCount) change(s) available", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAt(4, $y++, "Last action: $($status.LastAction)")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'U' to undo the last change", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No changes available to undo", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "U:Undo | Esc:Cancel")
    }

    [void] DrawRedoView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Redo Last Undone Change "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $status = Get-PmcUndoStatus
            if ($status.RedoAvailable) {
                $this.terminal.WriteAtColor(4, 6, "Redo stack has $($status.RedoCount) change(s) available", [PmcVT100]::Green(), "")
                $y = 8
                $this.terminal.WriteAtColor(4, $y, "Press 'R' to redo the last undone change", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No changes available to redo", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "R:Redo | Esc:Cancel")
    }

    [void] DrawClearBackupsView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Clear Backup Files "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $backupCount = 0
            $totalSize = 0

            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $backupCount++
                    $totalSize += (Get-Item $bakFile).Length
                }
            }

            $this.terminal.WriteAtColor(4, 6, "Automatic backups (.bak1 - .bak9):", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAt(4, 8, "  Count: $backupCount files")
            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            $this.terminal.WriteAt(4, 9, "  Total size: $sizeMB MB")

            $y = 11
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json")
                $manualCount = $manualBackups.Count
                $manualSize = ($manualBackups | Measure-Object -Property Length -Sum).Sum
                $manualSizeMB = [math]::Round($manualSize / 1MB, 2)

                $this.terminal.WriteAtColor(4, $y++, "Manual backups (backups directory):", [PmcVT100]::Cyan(), "")
                $y++
                $this.terminal.WriteAt(4, $y++, "  Count: $manualCount files")
                $this.terminal.WriteAt(4, $y++, "  Total size: $manualSizeMB MB")
            }

            $y += 2
            if ($backupCount -gt 0) {
                $this.terminal.WriteAtColor(4, $y++, "Press 'A' to clear automatic backups (.bak files)", [PmcVT100]::Yellow(), "")
            }
            if (Test-Path $backupDir) {
                $this.terminal.WriteAtColor(4, $y++, "Press 'M' to clear manual backups (backups directory)", [PmcVT100]::Yellow(), "")
                $y++
                $this.terminal.WriteAtColor(4, $y, "Press 'B' to clear BOTH", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "A:Auto | M:Manual | B:Both | Esc:Cancel")
    }

    [void] HandleClearBackupsView() {
        $this.DrawClearBackupsView()
        $key = [Console]::ReadKey($true)

        if ($key.Key -eq 'A') {
            $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Clear automatic backups? Type 'YES':", [PmcVT100]::Red(), "")
            $this.terminal.WriteAt(45, $this.terminal.Height - 3, "")
            [Console]::SetCursorPosition(45, $this.terminal.Height - 3)
            $confirm = [Console]::ReadLine()
            if ($confirm -eq 'YES') {
                try {
                    $file = Get-PmcTaskFilePath
                    $count = 0
                    for ($i = 1; $i -le 9; $i++) {
                        $bakFile = "$file.bak$i"
                        if (Test-Path $bakFile) {
                            Remove-Item $bakFile -Force
                            $count++
                        }
                    }
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✓ Cleared $count automatic backup files", [PmcVT100]::Green(), "")
                    Start-Sleep -Seconds 2
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✗ Error: $_", [PmcVT100]::Red(), "")
                    Start-Sleep -Seconds 2
                }
            }
            $this.currentView = 'tasklist'
        } elseif ($key.Key -eq 'M') {
            $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Clear manual backups? Type 'YES':", [PmcVT100]::Red(), "")
            $this.terminal.WriteAt(42, $this.terminal.Height - 3, "")
            [Console]::SetCursorPosition(42, $this.terminal.Height - 3)
            $confirm = [Console]::ReadLine()
            if ($confirm -eq 'YES') {
                try {
                    $backupDir = Join-Path (Get-PmcRootPath) "backups"
                    if (Test-Path $backupDir) {
                        $files = Get-ChildItem $backupDir -Filter "*.json"
                        $count = $files.Count
                        Remove-Item "$backupDir/*.json" -Force
                        $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✓ Cleared $count manual backup files", [PmcVT100]::Green(), "")
                        Start-Sleep -Seconds 2
                    }
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✗ Error: $_", [PmcVT100]::Red(), "")
                    Start-Sleep -Seconds 2
                }
            }
            $this.currentView = 'tasklist'
        } elseif ($key.Key -eq 'B') {
            $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Clear ALL backups? Type 'YES':", [PmcVT100]::Red(), "")
            $this.terminal.WriteAt(36, $this.terminal.Height - 3, "")
            [Console]::SetCursorPosition(36, $this.terminal.Height - 3)
            $confirm = [Console]::ReadLine()
            if ($confirm -eq 'YES') {
                try {
                    $file = Get-PmcTaskFilePath
                    $autoCount = 0
                    for ($i = 1; $i -le 9; $i++) {
                        $bakFile = "$file.bak$i"
                        if (Test-Path $bakFile) {
                            Remove-Item $bakFile -Force
                            $autoCount++
                        }
                    }
                    $manualCount = 0
                    $backupDir = Join-Path (Get-PmcRootPath) "backups"
                    if (Test-Path $backupDir) {
                        $files = Get-ChildItem $backupDir -Filter "*.json"
                        $manualCount = $files.Count
                        Remove-Item "$backupDir/*.json" -Force
                    }
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✓ Cleared $autoCount auto + $manualCount manual backups", [PmcVT100]::Green(), "")
                    Start-Sleep -Seconds 2
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 2, "✗ Error: $_", [PmcVT100]::Red(), "")
                    Start-Sleep -Seconds 2
                }
            }
            $this.currentView = 'tasklist'
        } elseif ($key.Key -eq 'Escape') {
            $this.currentView = 'tasklist'
        } else {
            $this.currentView = 'fileclearbackups'  # Refresh
        }
    }

    [void] DrawPlaceholder([string]$featureName) {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " $featureName "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $message = "This feature is not yet implemented in the TUI."
        $messageX = ($this.terminal.Width - $message.Length) / 2
        $this.terminal.WriteAtColor([int]$messageX, 8, $message, [PmcVT100]::Yellow(), "")

        $hint = "Use the PowerShell commands instead (Get-Command *Pmc*)"
        $hintX = ($this.terminal.Width - $hint.Length) / 2
        $this.terminal.WriteAt([int]$hintX, 10, $hint)

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawFocusSetForm() {
        $this.terminal.Clear()

        $title = " Set Focus Context "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 2, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAt(4, 5, "Project name:")
        $this.terminal.WriteAt(4, 6, "> ")

        try {
            $data = Get-PmcAllData
            $this.terminal.WriteAtColor(4, 8, "Available projects:", [PmcVT100]::Cyan(), "")
            $y = 9
            foreach ($proj in $data.projects) {
                $this.terminal.WriteAt(6, $y++, "• $($proj.name)")
            }
        } catch {}

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Type project name, Enter to set, Esc to cancel")
    }

    [void] HandleFocusSetForm() {
        # Get available projects
        $data = Get-PmcAllData
        $projectList = @('inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

        # Get current context as default
        $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

        # Show selection list
        $selected = Show-SelectList -Title "Select Focus Context" -Options $projectList -DefaultValue $currentContext

        if ($selected) {
            try {
                if (-not $data.PSObject.Properties['currentContext']) {
                    $data | Add-Member -NotePropertyName currentContext -NotePropertyValue $selected -Force
                } else {
                    $data.currentContext = $selected
                }
                Save-PmcData -Data $data -Action "Set focus to $selected"
                Show-InfoMessage -Message "Focus set to: $selected" -Title "Success" -Color "Green"
            } catch {
                Show-InfoMessage -Message "Failed to set focus: $_" -Title "Error" -Color "Red"
            }
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawFocusStatus() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Focus Status "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $currentContext = if ($data.PSObject.Properties['currentContext']) { $data.currentContext } else { 'inbox' }

            $this.terminal.WriteAtColor(4, 6, "Current Focus:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(20, 6, $currentContext)

            if ($currentContext -and $currentContext -ne 'inbox') {
                $contextTasks = @($data.tasks | Where-Object {
                    $_.project -eq $currentContext -and $_.status -ne 'completed'
                })

                $this.terminal.WriteAtColor(4, 8, "Active Tasks:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 8, "$($contextTasks.Count)")

                $overdue = @($contextTasks | Where-Object {
                    $_.due -and ([DateTime]::Parse($_.due).Date -lt (Get-Date).Date)
                })

                if ($overdue.Count -gt 0) {
                    $this.terminal.WriteAtColor(4, 9, "Overdue:", [PmcVT100]::Red(), "")
                    $this.terminal.WriteAt(18, 9, "$($overdue.Count)")
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading focus status: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleFocusStatusView() {
        $this.DrawFocusStatus()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTimeAddForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "Task ID (optional):")
        $this.terminal.WriteAtColor(4, 10, "Minutes:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 12, "Description:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 14, "Date (YYYY-MM-DD, default today):")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc=Cancel")
    }

    [void] HandleTimeAddForm() {
        # First ask: Project or Generic Time Code?
        $choice = Show-SelectList -Title "Time Entry Type" -Options @('Project', 'Generic Time Code (ID1)')

        if (-not $choice) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $project = $null
        $id1 = $null

        if ($choice -eq 'Project') {
            # Get available projects
            $data = Get-PmcAllData
            $projectList = @('inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

            $project = Show-SelectList -Title "Select Project" -Options $projectList
            if (-not $project) {
                $this.currentView = 'main'
                $this.DrawLayout()
                return
            }

            # Ask if they want to add id1 with the project
            $addId1 = Show-ConfirmDialog -Message "Add ID1 (generic time code)?" -Title "Optional ID1"
            if ($addId1) {
                $this.terminal.Clear()
                $this.menuSystem.DrawMenuBar()
                $this.terminal.WriteAtColor(4, 5, "ID1 (generic time code):", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(30, 5, "")
                [Console]::SetCursorPosition(30, 5)
                $id1 = [Console]::ReadLine()
                if ([string]::IsNullOrWhiteSpace($id1)) { $id1 = $null }
            }
        } else {
            # Generic Time Code only
            $this.terminal.Clear()
            $this.menuSystem.DrawMenuBar()
            $this.terminal.WriteAtColor(4, 5, "ID1 (generic time code):", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(30, 5, "")
            [Console]::SetCursorPosition(30, 5)
            $id1 = [Console]::ReadLine()

            if ([string]::IsNullOrWhiteSpace($id1)) {
                Show-InfoMessage -Message "ID1 is required for generic time code" -Title "Error" -Color "Red"
                $this.currentView = 'main'
                $this.DrawLayout()
                return
            }
        }

        # Now get hours, description, date
        $fields = @(
            @{Name='hours'; Label='Hours (e.g. 1.25)'; Required=$true; Type='text'}
            @{Name='description'; Label='Description'; Required=$false; Type='text'}
            @{Name='date'; Label='Date (YYYY-MM-DD, default=today)'; Required=$false; Type='text'}
        )

        $result = Show-InputForm -Title "Add Time Entry" -Fields $fields

        # User cancelled
        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        # Validate and parse inputs
        $hours = try { [double]$result['hours'] } catch { 0.0 }
        $minutes = [int]($hours * 60)
        $description = $result['description']
        $dateInput = $result['date']

        # Parse date - handle 'today', 'tomorrow', or actual date
        if ([string]::IsNullOrWhiteSpace($dateInput)) {
            $date = (Get-Date).ToString("yyyy-MM-dd")
        } elseif ($dateInput -eq 'today') {
            $date = (Get-Date).ToString("yyyy-MM-dd")
        } elseif ($dateInput -eq 'tomorrow') {
            $date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
        } else {
            $date = $dateInput
        }

        if ($hours -le 0) {
            Show-InfoMessage -Message "Hours must be a positive number" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) {
                $data | Add-Member -NotePropertyName 'timelogs' -NotePropertyValue @()
            }

            $newId = if ($data.timelogs.Count -gt 0) {
                ($data.timelogs | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
            } else { 1 }

            $entry = [PSCustomObject]@{
                id = $newId
                project = $project
                id1 = if ([string]::IsNullOrWhiteSpace($id1)) { $null } else { $id1 }
                id2 = $null
                date = $date
                minutes = $minutes
                description = $description
                created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }

            $data.timelogs += $entry

            $hoursDisplay = [math]::Round($hours, 2)
            Save-PmcData -Data $data -Action "Added time entry: $hoursDisplay hours for $project"

            # Success - use Show-InfoMessage to ensure user sees confirmation
            Show-InfoMessage -Message "Time entry added successfully! $hoursDisplay hours logged to $project." -Title "Success" -Color "Green"
        } catch {
            # CRITICAL FIX: Show persistent error message that user must acknowledge
            Show-InfoMessage -Message "Failed to save time entry: $_" -Title "Error" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTimeList() {
        $this.LoadTimeLogs()
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Time Log "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            if (-not $this.timelogs -or $this.timelogs.Count -eq 0) {
                $emptyY = 8
                $this.terminal.WriteAtColor(4, $emptyY++, "No time entries yet", [PmcVT100]::Yellow(), "")
                $emptyY++
                $this.terminal.WriteAtColor(4, $emptyY++, "Press 'A' to add your first time entry", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(4, $emptyY++, "Or press Alt+I then L to view this screen", [PmcVT100]::Gray(), "")
            } else {
                $headerY = 5
                $this.terminal.WriteAtColor(2, $headerY, "ID", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(7, $headerY, "Date", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(20, $headerY, "Project", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(38, $headerY, "Mins", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(46, $headerY, "Description", [PmcVT100]::Cyan(), "")
                $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

                $startY = $headerY + 2
                $y = $startY

                for ($i = 0; $i -lt $this.timelogs.Count; $i++) {
                    if ($y -ge $this.terminal.Height - 3) { break }

                    $log = $this.timelogs[$i]

                    # Highlight selected entry
                    $prefix = if ($i -eq $this.selectedTimeIndex) { ">" } else { " " }
                    $bg = if ($i -eq $this.selectedTimeIndex) { [PmcVT100]::BgBlue() } else { "" }
                    $fg = if ($i -eq $this.selectedTimeIndex) { [PmcVT100]::White() } else { "" }

                    if ($bg) {
                        $this.terminal.WriteAtColor(2, $y, ($prefix + $log.id.ToString()).PadRight(4), $bg, $fg)
                        $this.terminal.WriteAtColor(7, $y, $log.date.Substring(0, [Math]::Min(10, $log.date.Length)).PadRight(12), $bg, $fg)
                        $this.terminal.WriteAtColor(20, $y, $log.project.Substring(0, [Math]::Min(16, $log.project.Length)).PadRight(17), $bg, $fg)
                        $this.terminal.WriteAtColor(38, $y, $log.minutes.ToString().PadRight(6), $bg, [PmcVT100]::Cyan())
                        if ($log.PSObject.Properties['description'] -and $log.description) {
                            $desc = $log.description.Substring(0, [Math]::Min(30, $log.description.Length))
                            $this.terminal.WriteAtColor(46, $y, $desc, $bg, $fg)
                        }
                    } else {
                        $this.terminal.WriteAtColor(2, $y, $prefix + $log.id.ToString(), [PmcVT100]::White(), "")
                        $this.terminal.WriteAtColor(7, $y, $log.date.Substring(0, [Math]::Min(10, $log.date.Length)), [PmcVT100]::White(), "")
                        $this.terminal.WriteAtColor(20, $y, $log.project.Substring(0, [Math]::Min(16, $log.project.Length)), [PmcVT100]::Gray(), "")
                        $this.terminal.WriteAtColor(38, $y, $log.minutes.ToString(), [PmcVT100]::Cyan(), "")
                        if ($log.PSObject.Properties['description'] -and $log.description) {
                            $desc = $log.description.Substring(0, [Math]::Min(30, $log.description.Length))
                            $this.terminal.WriteAtColor(46, $y, $desc, [PmcVT100]::White(), "")
                        }
                    }
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading time log: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("↑↓:Nav | A:Add | E:Edit | Del:Delete | R:Report | Esc:Back")
    }

    [void] HandleTimeListView() {
        $this.DrawTimeList()
        $key = [Console]::ReadKey($true)

        # Check for global menu keys first
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            Write-FakeTUIDebug "Global action from time list: $globalAction" "TIMELIST"
            if ($globalAction -eq 'app:exit') {
                $this.running = $false
                return
            }
            $this.ProcessMenuAction($globalAction)
            return
        }

        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedTimeIndex -gt 0) {
                    $this.selectedTimeIndex--
                }
                $this.DrawTimeList()
            }
            'DownArrow' {
                if ($this.selectedTimeIndex -lt $this.timelogs.Count - 1) {
                    $this.selectedTimeIndex++
                }
                $this.DrawTimeList()
            }
            'A' {
                $this.currentView = 'timeadd'
            }
            'E' {
                $this.currentView = 'timeedit'
            }
            'Delete' {
                # Delete time entry with confirmation
                if ($this.selectedTimeIndex -lt $this.timelogs.Count) {
                    $log = $this.timelogs[$this.selectedTimeIndex]

                    $confirmed = Show-ConfirmDialog -Message "Delete time entry #$($log.id) ($($log.minutes) min on $($log.project))?" -Title "Confirm Delete"
                    if ($confirmed) {
                        try {
                            $data = Get-PmcAllData
                            $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $log.id })
                            Save-PmcData -Data $data -Action "Deleted time entry #$($log.id)"
                            $this.LoadTimeLogs()
                            if ($this.selectedTimeIndex -ge $this.timelogs.Count -and $this.selectedTimeIndex -gt 0) {
                                $this.selectedTimeIndex--
                            }
                            Show-InfoMessage -Message "Time entry #$($log.id) deleted successfully" -Title "Success" -Color "Green"
                        } catch {
                            Show-InfoMessage -Message "Failed to delete time entry: $_" -Title "Error" -Color "Red"
                        }
                    }
                    $this.DrawTimeList()
                }
            }
            'R' {
                $this.currentView = 'timereport'
            }
            'Escape' {
                $this.currentView = 'main'
            }
        }
    }

    [void] DrawTimeReport() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Time Report "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $timelogList = if ($data.PSObject.Properties['timelogs']) { $data.timelogs } else { @() }

            if ($timelogList.Count -eq 0) {
                $this.terminal.WriteAt(4, 6, "No time entries to report")
            } else {
                # Group by project
                $byProject = $timelogList | Group-Object -Property project | Sort-Object Name

                $this.terminal.WriteAtColor(4, 5, "Time Summary by Project:", [PmcVT100]::Yellow(), "")

                $headerY = 7
                $this.terminal.WriteAt(4, $headerY, "Project")
                $this.terminal.WriteAt(30, $headerY, "Entries")
                $this.terminal.WriteAt(42, $headerY, "Total Minutes")
                $this.terminal.WriteAt(60, $headerY, "Hours")
                $this.terminal.DrawHorizontalLine(2, $headerY + 1, $this.terminal.Width - 4)

                $y = $headerY + 2
                $totalMinutes = 0
                foreach ($group in $byProject) {
                    $minutes = ($group.Group | Measure-Object -Property minutes -Sum).Sum
                    $hours = [Math]::Round($minutes / 60, 1)
                    $totalMinutes += $minutes

                    $this.terminal.WriteAt(4, $y, $group.Name.Substring(0, [Math]::Min(24, $group.Name.Length)))
                    $this.terminal.WriteAt(30, $y, $group.Count.ToString())
                    $this.terminal.WriteAtColor(42, $y, $minutes.ToString(), [PmcVT100]::Cyan(), "")
                    $this.terminal.WriteAtColor(60, $y, $hours.ToString(), [PmcVT100]::Green(), "")
                    $y++

                    if ($y -ge $this.terminal.Height - 5) { break }
                }

                $totalHours = [Math]::Round($totalMinutes / 60, 1)
                $this.terminal.DrawHorizontalLine(2, $y, $this.terminal.Width - 4)
                $y++
                $this.terminal.WriteAtColor(4, $y, "TOTAL:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(42, $y, $totalMinutes.ToString(), [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAtColor(60, $y, $totalHours.ToString(), [PmcVT100]::Green(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error generating report: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] DrawProjectList() {
        $this.LoadProjects()
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Project List "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData

            if ($this.projects.Count -eq 0) {
                $emptyY = 8
                $this.terminal.WriteAtColor(4, $emptyY++, "No projects yet", [PmcVT100]::Yellow(), "")
                $emptyY++
                $this.terminal.WriteAtColor(4, $emptyY++, "Press 'A' to create your first project", [PmcVT100]::Cyan(), "")
                $this.terminal.WriteAt(4, $emptyY++, "Or press Alt+P then L to view this screen")
            } else {
                $headerY = 5
                $this.terminal.WriteAt(2, $headerY, "Project")
                $this.terminal.WriteAt(30, $headerY, "Active")
                $this.terminal.WriteAt(42, $headerY, "Done")
                $this.terminal.WriteAt(52, $headerY, "Total")
                $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

                $startY = $headerY + 2
                $y = $startY

                for ($i = 0; $i -lt $this.projects.Count; $i++) {
                    if ($y -ge $this.terminal.Height - 3) { break }

                    $proj = $this.projects[$i]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }

                    $projTasks = @($data.tasks | Where-Object { $_.project -eq $projName })
                    $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                    $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                    $total = $projTasks.Count

                    # Highlight selected project
                    $prefix = if ($i -eq $this.selectedProjectIndex) { "> " } else { "  " }
                    $bg = if ($i -eq $this.selectedProjectIndex) { [PmcVT100]::BgBlue() } else { "" }
                    $fg = if ($i -eq $this.selectedProjectIndex) { [PmcVT100]::White() } else { "" }

                    $projDisplay = $projName.Substring(0, [Math]::Min(24, $projName.Length))
                    if ($bg) {
                        $this.terminal.WriteAtColor(2, $y, ($prefix + $projDisplay).PadRight(28), $bg, $fg)
                        $this.terminal.WriteAtColor(30, $y, $active.ToString().PadRight(10), $bg, [PmcVT100]::Cyan())
                        $this.terminal.WriteAtColor(42, $y, $completed.ToString().PadRight(8), $bg, [PmcVT100]::Green())
                        $this.terminal.WriteAtColor(52, $y, $total.ToString(), $bg, $fg)
                    } else {
                        $this.terminal.WriteAt(2, $y, $prefix + $projDisplay)
                        $this.terminal.WriteAtColor(30, $y, $active.ToString(), [PmcVT100]::Cyan(), "")
                        $this.terminal.WriteAtColor(42, $y, $completed.ToString(), [PmcVT100]::Green(), "")
                        $this.terminal.WriteAt(52, $y, $total.ToString())
                    }
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading projects: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("↑↓:Nav | Enter:Select | A:Add | E:Edit | R:Rename | Del:Delete | I:Info | Esc:Back")
    }

    [void] HandleProjectListView() {
        $this.DrawProjectList()
        $key = [Console]::ReadKey($true)

        # Check for global menu keys first
        $globalAction = $this.CheckGlobalKeys($key)
        if ($globalAction) {
            Write-FakeTUIDebug "Global action from project list: $globalAction" "PROJECTLIST"
            if ($globalAction -eq 'app:exit') {
                $this.running = $false
                return
            }
            $this.ProcessMenuAction($globalAction)
            return
        }

        switch ($key.Key) {
            'UpArrow' {
                if ($this.selectedProjectIndex -gt 0) {
                    $this.selectedProjectIndex--
                }
                $this.DrawProjectList()
            }
            'DownArrow' {
                if ($this.selectedProjectIndex -lt $this.projects.Count - 1) {
                    $this.selectedProjectIndex++
                }
                $this.DrawProjectList()
            }
            'Enter' {
                # Select project - filter tasks by this project
                if ($this.selectedProjectIndex -lt $this.projects.Count) {
                    $proj = $this.projects[$this.selectedProjectIndex]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }
                    $this.filterProject = $projName
                    $this.currentView = 'tasklist'
                    $this.LoadTasks()
                }
            }
            'A' {
                $this.currentView = 'projectcreate'
            }
            'E' {
                # Edit project - use existing form
                if ($this.selectedProjectIndex -lt $this.projects.Count) {
                    $proj = $this.projects[$this.selectedProjectIndex]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }
                    # Store selected project for edit form to use
                    $this.selectedProject = $projName
                    $this.currentView = 'projectedit'
                }
            }
            'R' {
                $this.currentView = 'projectrename'
            }
            'Delete' {
                # Delete project with confirmation
                if ($this.selectedProjectIndex -lt $this.projects.Count) {
                    $proj = $this.projects[$this.selectedProjectIndex]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }

                    $confirmed = Show-ConfirmDialog -Message "Delete project '$projName'? This will NOT delete tasks in this project." -Title "Confirm Delete"
                    if ($confirmed) {
                        try {
                            $data = Get-PmcAllData
                            $data.projects = @($data.projects | Where-Object {
                                $pName = if ($_ -is [string]) { $_ } else { $_.name }
                                $pName -ne $projName
                            })
                            Save-PmcData -Data $data -Action "Deleted project '$projName'"
                            $this.LoadProjects()
                            if ($this.selectedProjectIndex -ge $this.projects.Count -and $this.selectedProjectIndex -gt 0) {
                                $this.selectedProjectIndex--
                            }
                            Show-InfoMessage -Message "Project '$projName' deleted successfully" -Title "Success" -Color "Green"
                        } catch {
                            Show-InfoMessage -Message "Failed to delete project: $_" -Title "Error" -Color "Red"
                        }
                    }
                    $this.DrawProjectList()
                }
            }
            'I' {
                # Show project info
                if ($this.selectedProjectIndex -lt $this.projects.Count) {
                    $proj = $this.projects[$this.selectedProjectIndex]
                    $projName = if ($proj -is [string]) { $proj } else { $proj.name }
                    $this.currentView = 'projectstats'
                    # Set selected project for stats view (would need to add this property)
                }
            }
            'Escape' {
                $this.currentView = 'main'
            }
        }
    }

    [void] DrawProjectCreateForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Create New Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter project name | Esc=Cancel")
    }

    [void] HandleProjectCreateForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='projectName'; Label='Project Name'; Required=$true}
        )

        $result = Show-InputForm -Title "Create New Project" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $projectName = $result['projectName']

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['projects']) {
                $data | Add-Member -NotePropertyName 'projects' -NotePropertyValue @()
            }

            if ($data.projects -contains $projectName) {
                Show-InfoMessage -Message "Project '$projectName' already exists!" -Title "Error" -Color "Red"
            } else {
                $data.projects += $projectName
                Save-PmcData -Data $data -Action "Created project: $projectName"
                Show-InfoMessage -Message "Project '$projectName' created successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to create project: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTaskEditForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Edit Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "Field (text/priority/project/due):")
        $this.terminal.WriteAtColor(4, 10, "New Value:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc=Cancel")
    }

    [void] HandleTaskEditForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true}
            @{Name='field'; Label='Field (text/priority/project/due/status)'; Required=$true}
            @{Name='value'; Label='New Value'; Required=$false}
        )

        $result = Show-InputForm -Title "Edit Task" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }
        $field = $result['field']
        $value = $result['value']

        if ($taskId -le 0) {
            Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } else {
                $validFields = @('text', 'priority', 'project', 'due', 'status')
                if ($field.ToLower() -notin $validFields) {
                    Show-InfoMessage -Message "Unknown field: $field. Valid fields: text, priority, project, due, status" -Title "Error" -Color "Red"
                    $this.currentView = 'main'
                    $this.DrawLayout()
                    return
                }

                switch ($field.ToLower()) {
                    'text' { $task.text = $value }
                    'priority' { $task.priority = $value }
                    'project' { $task.project = $value }
                    'due' { $task.due = $value }
                    'status' { $task.status = $value }
                }

                Save-PmcData -Data $data -Action "Updated task $taskId field $field"
                Show-InfoMessage -Message "Task $taskId updated successfully! $field = $value" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to save task edit: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTaskCompleteForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Complete Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter task ID | Esc=Cancel")
    }

    [void] HandleTaskCompleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID to complete'; Required=$true}
        )

        $result = Show-InputForm -Title "Complete Task" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }

        if ($taskId -le 0) {
            Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } else {
                $task.status = 'completed'
                $task.completed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Save-PmcData -Data $data -Action "Completed task $taskId"
                Show-InfoMessage -Message "Task $taskId completed successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to complete task: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTaskDeleteForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Delete Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "WARNING: This will permanently delete the task!", [PmcVT100]::Red(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter task ID | Esc=Cancel")
    }

    [void] HandleTaskDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Task" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }

        if ($taskId -le 0) {
            Show-InfoMessage -Message "Invalid task ID" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } else {
                # Use Show-ConfirmDialog for deletion confirmation
                $confirmed = Show-ConfirmDialog -Message "Delete task '$($task.text)'? This cannot be undone." -Title "Confirm Deletion"

                if ($confirmed) {
                    $data.tasks = @($data.tasks | Where-Object { $_.id -ne $taskId })
                    Save-PmcData -Data $data -Action "Deleted task $taskId"
                    Show-InfoMessage -Message "Task $taskId deleted successfully!" -Title "Success" -Color "Green"
                } else {
                    Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete task: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawDepAddForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Dependency "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Depends on Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 10, "(Task will be blocked until dependency is completed)")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter IDs | Esc=Cancel")
    }

    [void] HandleDepAddForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true}
            @{Name='dependsId'; Label='Depends on Task ID'; Required=$true}
        )

        $result = Show-InputForm -Title "Add Dependency" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }
        $dependsId = try { [int]$result['dependsId'] } catch { 0 }

        if ($taskId -le 0 -or $dependsId -le 0) {
            Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }
            $dependsTask = $data.tasks | Where-Object { $_.id -eq $dependsId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $dependsTask) {
                Show-InfoMessage -Message "Task $dependsId not found!" -Title "Error" -Color "Red"
            } else {
                # Initialize depends array if needed
                if (-not $task.PSObject.Properties['depends']) {
                    $task | Add-Member -NotePropertyName depends -NotePropertyValue @()
                }

                # Check if dependency already exists
                if ($task.depends -contains $dependsId) {
                    Show-InfoMessage -Message "Dependency already exists!" -Title "Warning" -Color "Yellow"
                } else {
                    $task.depends = @($task.depends + $dependsId)

                    # Update blocked status
                    Update-PmcBlockedStatus -data $data

                    Save-PmcData -Data $data -Action "Added dependency: $taskId depends on $dependsId"
                    Show-InfoMessage -Message "Dependency added successfully! Task $taskId now depends on task $dependsId." -Title "Success" -Color "Green"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to add dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawDepRemoveForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Remove Dependency "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Remove dependency on Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter IDs | Esc=Cancel")
    }

    [void] HandleDepRemoveForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='taskId'; Label='Task ID'; Required=$true}
            @{Name='dependsId'; Label='Remove dependency on Task ID'; Required=$true}
        )

        $result = Show-InputForm -Title "Remove Dependency" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $taskId = try { [int]$result['taskId'] } catch { 0 }
        $dependsId = try { [int]$result['dependsId'] } catch { 0 }

        if ($taskId -le 0 -or $dependsId -le 0) {
            Show-InfoMessage -Message "Invalid task IDs" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                Show-InfoMessage -Message "Task $taskId not found!" -Title "Error" -Color "Red"
            } elseif (-not $task.PSObject.Properties['depends'] -or -not $task.depends) {
                Show-InfoMessage -Message "Task has no dependencies!" -Title "Warning" -Color "Yellow"
            } else {
                $task.depends = @($task.depends | Where-Object { $_ -ne $dependsId })

                # Clean up empty depends array
                if ($task.depends.Count -eq 0) {
                    $task.PSObject.Properties.Remove('depends')
                }

                # Update blocked status
                Update-PmcBlockedStatus -data $data

                Save-PmcData -Data $data -Action "Removed dependency: $taskId no longer depends on $dependsId"
                Show-InfoMessage -Message "Dependency removed successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to remove dependency: $_" -Title "SAVE ERROR" -Color "Red"
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawDepShowForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Show Task Dependencies "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter task ID | Esc=Cancel")
    }

    [void] HandleDepShowForm() {
        $this.DrawDepShowForm()

        $this.terminal.WriteAt(14, 6, "")
        [Console]::SetCursorPosition(14, 6)
        $taskIdStr = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskIdStr)) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }
        $taskId = try { [int]$taskIdStr } catch { 0 }

        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq $taskId }

            if (-not $task) {
                $this.terminal.WriteAtColor(4, 9, "Task $taskId not found!", [PmcVT100]::Red(), "")
                Start-Sleep -Milliseconds 2000
            } else {
                $this.terminal.WriteAtColor(4, 9, "Task:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(10, 9, $task.text.Substring(0, [Math]::Min(60, $task.text.Length)))

                $depends = if ($task.PSObject.Properties['depends'] -and $task.depends) { $task.depends } else { @() }

                if ($depends.Count -eq 0) {
                    $this.terminal.WriteAt(4, 11, "No dependencies")
                } else {
                    $this.terminal.WriteAtColor(4, 11, "Dependencies:", [PmcVT100]::Yellow(), "")

                    $y = 13
                    foreach ($depId in $depends) {
                        $depTask = $data.tasks | Where-Object { $_.id -eq $depId }
                        if ($depTask) {
                            $statusIcon = if ($depTask.status -eq 'completed') { '✓' } else { '○' }
                            $statusColor = if ($depTask.status -eq 'completed') { [PmcVT100]::Green() } else { [PmcVT100]::Red() }

                            $this.terminal.WriteAtColor(6, $y, $statusIcon, $statusColor, "")
                            $this.terminal.WriteAt(8, $y, "#$depId")
                            $this.terminal.WriteAt(15, $y, $depTask.text.Substring(0, [Math]::Min(50, $depTask.text.Length)))
                            $y++
                        }
                        if ($y -ge $this.terminal.Height - 5) { break }
                    }

                    if ($task.PSObject.Properties['blocked'] -and $task.blocked) {
                        $this.terminal.WriteAtColor(4, $y + 1, "⚠️  Task is BLOCKED", [PmcVT100]::Red(), "")
                    } else {
                        $this.terminal.WriteAtColor(4, $y + 1, "✅ Task is ready", [PmcVT100]::Green(), "")
                    }
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawDepGraph() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Dependency Graph "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            $tasksWithDeps = @($data.tasks | Where-Object {
                $_.PSObject.Properties['depends'] -and $_.depends -and $_.depends.Count -gt 0
            })

            if ($tasksWithDeps.Count -eq 0) {
                $this.terminal.WriteAt(4, 6, "No task dependencies found")
            } else {
                $headerY = 5
                $this.terminal.WriteAt(2, $headerY, "Task")
                $this.terminal.WriteAt(10, $headerY, "Depends On")
                $this.terminal.WriteAt(26, $headerY, "Status")
                $this.terminal.WriteAt(40, $headerY, "Description")
                $this.terminal.DrawHorizontalLine(0, $headerY + 1, $this.terminal.Width)

                $y = $headerY + 2
                foreach ($task in $tasksWithDeps) {
                    if ($y -ge $this.terminal.Height - 5) { break }

                    $dependsText = ($task.depends -join ', ')
                    $statusText = if ($task.PSObject.Properties['blocked'] -and $task.blocked) { "🔒 BLOCKED" } else { "✅ Ready" }
                    $statusColor = if ($task.PSObject.Properties['blocked'] -and $task.blocked) { [PmcVT100]::Red() } else { [PmcVT100]::Green() }

                    $this.terminal.WriteAt(2, $y, "#$($task.id)")
                    $this.terminal.WriteAt(10, $y, $dependsText.Substring(0, [Math]::Min(14, $dependsText.Length)))
                    $this.terminal.WriteAtColor(26, $y, $statusText, $statusColor, "")
                    $this.terminal.WriteAt(40, $y, $task.text.Substring(0, [Math]::Min(38, $task.text.Length)))
                    $y++
                }

                # Summary
                $blockedCount = @($data.tasks | Where-Object { $_.PSObject.Properties['blocked'] -and $_.blocked }).Count
                $y += 2
                $this.terminal.WriteAtColor(4, $y, "Tasks with dependencies:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(30, $y, $tasksWithDeps.Count.ToString())
                $y++
                $this.terminal.WriteAtColor(4, $y, "Currently blocked:", [PmcVT100]::Yellow(), "")
                $blockedColor = if ($blockedCount -gt 0) { [PmcVT100]::Red() } else { [PmcVT100]::Green() }
                $this.terminal.WriteAtColor(30, $y, $blockedCount.ToString(), $blockedColor, "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error loading dependency graph: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    # File Management Methods
    [void] DrawFileRestoreForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Restore Data from Backup "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $file = Get-PmcTaskFilePath
            $allBackups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }

            if ($allBackups.Count -gt 0) {
                $this.terminal.WriteAtColor(4, 6, "Available backups:", [PmcVT100]::Yellow(), "")
                $y = 8
                foreach ($backup in $allBackups) {
                    $sizeKB = [math]::Round($backup.Size / 1KB, 2)
                    $typeLabel = if ($backup.Type -eq "auto") { "[Auto]" } else { "[Manual]" }
                    $line = "$($backup.Number). $typeLabel $($backup.Name) - $($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss')) ($sizeKB KB)"
                    $this.terminal.WriteAt(4, $y++, $line)
                }
                $this.terminal.WriteAtColor(4, $y + 1, "Enter backup number to restore:", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, 6, "No backups found", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error listing backups: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter number or Esc=Cancel")
    }

    [void] HandleFileRestoreForm() {
        $this.DrawFileRestoreForm()

        try {
            $file = Get-PmcTaskFilePath
            $allBackups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $allBackups += [PSCustomObject]@{
                        Number = $allBackups.Count + 1
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }

            if ($allBackups.Count -eq 0) {
                Start-Sleep -Milliseconds 2000
                $this.currentView = 'tasklist'
                return
            }

            $y = 8 + $allBackups.Count + 1
            $this.terminal.WriteAt(33, $y, "")
            [Console]::SetCursorPosition(33, $y)
            $choice = [Console]::ReadLine()

            if ([string]::IsNullOrWhiteSpace($choice)) {
                $this.currentView = 'tasklist'
                return
            }

            $num = 0
            if ([int]::TryParse($choice, [ref]$num) -and $num -ge 1 -and $num -le $allBackups.Count) {
                $selectedBackup = $allBackups[$num - 1]
                $this.terminal.WriteAtColor(4, $y + 2, "WARNING: This will overwrite current data! Type 'YES' to confirm:", [PmcVT100]::Red(), "")
                $this.terminal.WriteAt(70, $y + 2, "")
                [Console]::SetCursorPosition(70, $y + 2)
                $confirm = [Console]::ReadLine()

                if ($confirm -eq 'YES') {
                    $data = Get-Content $selectedBackup.Path -Raw | ConvertFrom-Json
                    Save-PmcData -Data $data -Action "Restored from backup: $($selectedBackup.Name)"
                    $this.LoadTasks()
                    $this.terminal.WriteAtColor(4, $y + 4, "Data restored successfully!", [PmcVT100]::Green(), "")
                    Start-Sleep -Milliseconds 2000
                } else {
                    $this.terminal.WriteAtColor(4, $y + 4, "Restore cancelled", [PmcVT100]::Yellow(), "")
                    Start-Sleep -Milliseconds 1500
                }
            } else {
                $this.terminal.WriteAtColor(4, $y + 2, "Invalid choice", [PmcVT100]::Red(), "")
                Start-Sleep -Milliseconds 1500
            }
        } catch {
            $this.terminal.WriteAtColor(4, 10, "Error restoring backup: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Milliseconds 2000
        }

        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawProjectRenameForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Rename Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Current Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "New Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter names | Esc=Cancel")
    }

    [void] HandleProjectRenameForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='oldName'; Label='Current Project Name'; Required=$true}
            @{Name='newName'; Label='New Project Name'; Required=$true}
        )

        $result = Show-InputForm -Title "Rename Project" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $oldName = $result['oldName']
        $newName = $result['newName']

        try {
            $data = Get-PmcAllData
            if ($data.projects -notcontains $oldName) {
                Show-InfoMessage -Message "Project '$oldName' not found!" -Title "Error" -Color "Red"
            } elseif ($data.projects -contains $newName) {
                Show-InfoMessage -Message "Project '$newName' already exists!" -Title "Error" -Color "Red"
            } else {
                $data.projects = @($data.projects | ForEach-Object { if ($_ -eq $oldName) { $newName } else { $_ } })
                foreach ($task in $data.tasks) {
                    if ($task.project -eq $oldName) { $task.project = $newName }
                }
                if ($data.PSObject.Properties['timelogs']) {
                    foreach ($log in $data.timelogs) {
                        if ($log.project -eq $oldName) { $log.project = $newName }
                    }
                }
                Save-PmcData -Data $data -Action "Renamed project: $oldName -> $newName"
                Show-InfoMessage -Message "Project renamed successfully! All tasks and time logs updated." -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to rename project: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawProjectArchiveForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Archive Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter project name | Esc=Cancel")
    }

    [void] HandleProjectArchiveForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='projectName'; Label='Project Name to archive'; Required=$true}
        )

        $result = Show-InputForm -Title "Archive Project" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $projectName = $result['projectName']

        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object { $_ -eq $projectName }
            if (-not $project) {
                Show-InfoMessage -Message "Project '$projectName' not found!" -Title "Error" -Color "Red"
            } else {
                if (-not $data.PSObject.Properties['archivedProjects']) {
                    $data | Add-Member -NotePropertyName 'archivedProjects' -NotePropertyValue @()
                }
                $data.archivedProjects += $projectName
                $data.projects = @($data.projects | Where-Object { $_ -ne $projectName })
                Save-PmcData -Data $data -Action "Archived project: $projectName"
                Show-InfoMessage -Message "Project '$projectName' archived successfully!" -Title "Success" -Color "Green"
            }
        } catch {
            Show-InfoMessage -Message "Failed to archive project: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawProjectDeleteForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Delete Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "WARNING: This will NOT delete tasks!", [PmcVT100]::Red(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter project name | Esc=Cancel")
    }

    [void] HandleProjectDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='projectName'; Label='Project Name to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Project" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $projectName = $result['projectName']

        try {
            $data = Get-PmcAllData
            if ($data.projects -notcontains $projectName) {
                Show-InfoMessage -Message "Project '$projectName' not found!" -Title "Error" -Color "Red"
            } else {
                # Use Show-ConfirmDialog for confirmation
                $confirmed = Show-ConfirmDialog -Message "Delete project '$projectName'? (Tasks will remain in inbox)" -Title "Confirm Deletion"

                if ($confirmed) {
                    $data.projects = @($data.projects | Where-Object { $_ -ne $projectName })
                    Save-PmcData -Data $data -Action "Deleted project: $projectName"
                    Show-InfoMessage -Message "Project '$projectName' deleted successfully!" -Title "Success" -Color "Green"
                } else {
                    Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete project: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawProjectStatsForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Project Statistics "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter project name | Esc=Cancel")
    }

    [void] HandleProjectStatsView() {
        $this.DrawProjectStatsForm()
        $this.terminal.WriteAt(19, 6, "")
        [Console]::SetCursorPosition(19, 6)
        $projectName = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }
        try {
            $data = Get-PmcAllData
            if ($data.projects -notcontains $projectName) {
                $this.terminal.WriteAtColor(4, 9, "Project '$projectName' not found!", [PmcVT100]::Red(), "")
            } else {
                $projTasks = @($data.tasks | Where-Object { $_.project -eq $projectName })
                $completed = @($projTasks | Where-Object { $_.status -eq 'completed' }).Count
                $active = @($projTasks | Where-Object { $_.status -ne 'completed' }).Count
                $overdue = @($projTasks | Where-Object { $_.due -and $_.status -ne 'completed' -and ([DateTime]::Parse($_.due).Date -lt (Get-Date).Date) }).Count

                $projTimelogs = if ($data.PSObject.Properties['timelogs']) { @($data.timelogs | Where-Object { $_.project -eq $projectName }) } else { @() }
                $totalMinutes = if ($projTimelogs.Count -gt 0) { ($projTimelogs | Measure-Object -Property minutes -Sum).Sum } else { 0 }
                $totalHours = [Math]::Round($totalMinutes / 60, 1)

                $this.terminal.WriteAtColor(4, 9, "Project:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(13, 9, $projectName)

                $this.terminal.WriteAtColor(4, 11, "Total Tasks:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 11, $projTasks.Count.ToString())

                $this.terminal.WriteAtColor(4, 12, "Active:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(18, 12, $active.ToString(), [PmcVT100]::Cyan(), "")

                $this.terminal.WriteAtColor(4, 13, "Completed:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAtColor(18, 13, $completed.ToString(), [PmcVT100]::Green(), "")

                if ($overdue -gt 0) {
                    $this.terminal.WriteAtColor(4, 14, "Overdue:", [PmcVT100]::Yellow(), "")
                    $this.terminal.WriteAtColor(18, 14, $overdue.ToString(), [PmcVT100]::Red(), "")
                }

                $this.terminal.WriteAtColor(4, 16, "Time Logged:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 16, "$totalHours hours ($totalMinutes minutes)")

                $this.terminal.WriteAtColor(4, 17, "Time Entries:", [PmcVT100]::Yellow(), "")
                $this.terminal.WriteAt(18, 17, $projTimelogs.Count.ToString())
            }
        } catch {
            $this.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
        }
        $this.terminal.DrawFooter("Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    # Time Management Methods
    [void] DrawTimeEditForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Edit Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Time Entry ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "New Minutes:", [PmcVT100]::Yellow(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter ID and minutes | Esc=Cancel")
    }

    [void] HandleTimeEditForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='id'; Label='Time Entry ID'; Required=$true}
            @{Name='minutes'; Label='New Minutes'; Required=$true}
        )

        $result = Show-InputForm -Title "Edit Time Entry" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $id = try { [int]$result['id'] } catch { 0 }
        $minutes = try { [int]$result['minutes'] } catch { 0 }

        if ($id -le 0) {
            Show-InfoMessage -Message "Invalid time entry ID" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        if ($minutes -le 0) {
            Show-InfoMessage -Message "Minutes must be a positive number" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) {
                Show-InfoMessage -Message "No time logs found!" -Title "Error" -Color "Red"
            } else {
                $entry = $data.timelogs | Where-Object { $_.id -eq $id }
                if (-not $entry) {
                    Show-InfoMessage -Message "Time entry $id not found!" -Title "Error" -Color "Red"
                } else {
                    $entry.minutes = $minutes
                    Save-PmcData -Data $data -Action "Updated time entry $id"
                    Show-InfoMessage -Message "Time entry updated successfully! New minutes: $minutes" -Title "Success" -Color "Green"
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to update time entry: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTimeDeleteForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Delete Time Entry "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Time Entry ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter ID | Esc=Cancel")
    }

    [void] HandleTimeDeleteForm() {
        # Use Show-InputForm widget
        $fields = @(
            @{Name='id'; Label='Time Entry ID to delete'; Required=$true}
        )

        $result = Show-InputForm -Title "Delete Time Entry" -Fields $fields

        if ($null -eq $result) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        $id = try { [int]$result['id'] } catch { 0 }

        if ($id -le 0) {
            Show-InfoMessage -Message "Invalid time entry ID" -Title "Error" -Color "Red"
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }

        try {
            $data = Get-PmcAllData
            if (-not $data.PSObject.Properties['timelogs']) {
                Show-InfoMessage -Message "No time logs found!" -Title "Error" -Color "Red"
            } else {
                $entry = $data.timelogs | Where-Object { $_.id -eq $id }
                if (-not $entry) {
                    Show-InfoMessage -Message "Time entry $id not found!" -Title "Error" -Color "Red"
                } else {
                    # Use Show-ConfirmDialog for confirmation
                    $confirmed = Show-ConfirmDialog -Message "Delete time entry #$($id)? This cannot be undone." -Title "Confirm Deletion"

                    if ($confirmed) {
                        $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $id })
                        Save-PmcData -Data $data -Action "Deleted time entry $id"
                        Show-InfoMessage -Message "Time entry deleted successfully!" -Title "Success" -Color "Green"
                    } else {
                        Show-InfoMessage -Message "Deletion cancelled" -Title "Cancelled" -Color "Yellow"
                    }
                }
            }
        } catch {
            Show-InfoMessage -Message "Failed to delete time entry: $_" -Title "SAVE ERROR" -Color "Red"
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    # Task Import/Export Methods
    [void] DrawTaskImportForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Import Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Import File Path:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "(Must be JSON format compatible with PMC)")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter file path | Esc=Cancel")
    }

    [void] HandleTaskImportForm() {
        $this.DrawTaskImportForm()
        $this.terminal.WriteAt(23, 6, "")
        [Console]::SetCursorPosition(23, 6)
        $filePath = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }
        try {
            if (-not (Test-Path $filePath)) {
                $this.terminal.WriteAtColor(4, 11, "File not found: $filePath", [PmcVT100]::Red(), "")
                Start-Sleep -Milliseconds 2000
            } else {
                $importData = Get-Content $filePath -Raw | ConvertFrom-Json
                $data = Get-PmcAllData
                $newTasks = 0
                foreach ($task in $importData.tasks) {
                    if (-not ($data.tasks | Where-Object { $_.id -eq $task.id })) {
                        $data.tasks += $task
                        $newTasks++
                    }
                }
                Save-PmcData -Data $data -Action "Imported $newTasks tasks from $filePath"
                $this.terminal.WriteAtColor(4, 11, "Imported $newTasks tasks!", [PmcVT100]::Green(), "")
                Start-Sleep -Milliseconds 2000
            }
        } catch {
            $this.terminal.WriteAtColor(4, 11, "Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Milliseconds 2000
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawTaskExportForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Export Tasks "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $this.terminal.WriteAtColor(4, 6, "Export File Path:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "(Will export all tasks as JSON)")
        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter file path | Esc=Cancel")
    }

    [void] HandleTaskExportForm() {
        $this.DrawTaskExportForm()
        $this.terminal.WriteAt(23, 6, "")
        [Console]::SetCursorPosition(23, 6)
        $filePath = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            $this.currentView = 'main'
            $this.DrawLayout()
            return
        }
        try {
            $data = Get-PmcAllData
            $exportData = @{ tasks = $data.tasks; projects = $data.projects }
            $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8
            $this.terminal.WriteAtColor(4, 11, "Exported $($data.tasks.Count) tasks to $filePath", [PmcVT100]::Green(), "")
            Start-Sleep -Milliseconds 2000
        } catch {
            $this.terminal.WriteAtColor(4, 11, "Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Milliseconds 2000
        }
        $this.currentView = 'main'
        $this.DrawLayout()
    }

    [void] DrawThemeEditor() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Theme Editor "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Current color scheme:", [PmcVT100]::Cyan(), "")
        $y++

        # Show current colors in use
        $this.terminal.WriteAt(4, $y++, "Primary colors:")
        $this.terminal.WriteAtColor(6, $y++, "• Success/Completed", [PmcVT100]::Green(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Errors/Warnings", [PmcVT100]::Red(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Information", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAtColor(6, $y++, "• Highlights", [PmcVT100]::Yellow(), "")
        $y++

        $this.terminal.WriteAt(4, $y++, "Available themes:")
        $y++
        $this.terminal.WriteAtColor(6, $y++, "1. Default - Standard color scheme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "2. Dark - High contrast dark theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "3. Light - Light background theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAtColor(6, $y++, "4. Solarized - Solarized color palette", [PmcVT100]::White(), "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Press number key to preview theme", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, $y, "Press 'A' to apply selected theme", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "1-4:Select | A:Apply | Esc:Cancel")
    }

    [void] DrawApplyTheme() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Apply Theme "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Select a theme to apply:", [PmcVT100]::Cyan(), "")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "1. Default Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Standard colors optimized for dark terminals")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "2. Dark Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "High contrast with bright highlights")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "3. Light Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Designed for light terminal backgrounds")
        $y++

        $this.terminal.WriteAtColor(6, $y++, "4. Solarized Theme", [PmcVT100]::White(), "")
        $this.terminal.WriteAt(8, $y++, "Popular Solarized color palette")
        $y++
        $y++

        $this.terminal.WriteAtColor(4, $y, "Press number to apply theme (changes take effect immediately)", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "1-4:Apply Theme | Esc:Cancel")
    }

    [void] DrawCopyTaskForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Copy/Duplicate Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID to copy:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, 8, "This will create an exact duplicate of the task")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter task ID | Esc:Cancel")
    }

    [void] HandleCopyTaskForm() {
        $this.DrawCopyTaskForm()
        $this.terminal.WriteAt(22, 6, "")
        [Console]::SetCursorPosition(22, 6)
        $taskId = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            $this.currentView = 'tasklist'
            return
        }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $clone = $task.PSObject.Copy()
                $clone.id = ($data.tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
                $data.tasks += $clone
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 10, "✓ Task $taskId duplicated as task $($clone.id)", [PmcVT100]::Green(), "")
                $this.LoadTasks()
            } else {
                $this.terminal.WriteAtColor(4, 10, "✗ Task $taskId not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 10, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawMoveTaskForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Move Task to Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Project Name:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc:Cancel")
    }

    [void] HandleMoveTaskForm() {
        $this.DrawMoveTaskForm()
        $this.terminal.WriteAt(14, 6, "")
        [Console]::SetCursorPosition(14, 6)
        $taskId = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            $this.currentView = 'tasklist'
            return
        }
        $this.terminal.WriteAt(19, 8, "")
        [Console]::SetCursorPosition(19, 8)
        $project = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($project)) {
            $this.currentView = 'tasklist'
            return
        }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $task.project = $project
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 10, "✓ Moved task $taskId to @$project", [PmcVT100]::Green(), "")
                $this.LoadTasks()
            } else {
                $this.terminal.WriteAtColor(4, 10, "✗ Task $taskId not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 10, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawSetPriorityForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Set Task Priority "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Priority (high/medium/low):", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc:Cancel")
    }

    [void] HandleSetPriorityForm() {
        $this.DrawSetPriorityForm()
        $this.terminal.WriteAt(14, 6, "")
        [Console]::SetCursorPosition(14, 6)
        $taskId = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            $this.currentView = 'tasklist'
            return
        }
        $this.terminal.WriteAt(33, 8, "")
        [Console]::SetCursorPosition(33, 8)
        $priority = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($priority)) {
            $this.currentView = 'tasklist'
            return
        }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $task.priority = $priority.ToLower()
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 10, "✓ Set task $taskId priority to $priority", [PmcVT100]::Green(), "")
                $this.LoadTasks()
            } else {
                $this.terminal.WriteAtColor(4, 10, "✗ Task $taskId not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 10, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawPostponeTaskForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Postpone Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Days to postpone (default: 1):", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc:Cancel")
    }

    [void] HandlePostponeTaskForm() {
        $this.DrawPostponeTaskForm()
        $this.terminal.WriteAt(14, 6, "")
        [Console]::SetCursorPosition(14, 6)
        $taskId = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            $this.currentView = 'tasklist'
            return
        }
        $this.terminal.WriteAt(36, 8, "")
        [Console]::SetCursorPosition(36, 8)
        $daysInput = [Console]::ReadLine()
        $days = if ([string]::IsNullOrWhiteSpace($daysInput)) { 1 } else { [int]$daysInput }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                $currentDue = if ($task.due) { [DateTime]::Parse($task.due) } else { Get-Date }
                $task.due = $currentDue.AddDays($days).ToString('yyyy-MM-dd')
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 10, "✓ Postponed task $taskId by $days day(s) to $($task.due)", [PmcVT100]::Green(), "")
                $this.LoadTasks()
            } else {
                $this.terminal.WriteAtColor(4, 10, "✗ Task $taskId not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 10, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawAddNoteForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Add Note to Task "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Task ID:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Note:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc:Cancel")
    }

    [void] HandleAddNoteForm() {
        $this.DrawAddNoteForm()
        $this.terminal.WriteAt(14, 6, "")
        [Console]::SetCursorPosition(14, 6)
        $taskId = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            $this.currentView = 'tasklist'
            return
        }
        $this.terminal.WriteAt(11, 8, "")
        [Console]::SetCursorPosition(11, 8)
        $note = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($note)) {
            $this.currentView = 'tasklist'
            return
        }
        try {
            $data = Get-PmcAllData
            $task = $data.tasks | Where-Object { $_.id -eq [int]$taskId } | Select-Object -First 1
            if ($task) {
                if (-not $task.notes) { $task.notes = @() }
                $task.notes += $note
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 10, "✓ Added note to task $taskId", [PmcVT100]::Green(), "")
                $this.LoadTasks()
            } else {
                $this.terminal.WriteAtColor(4, 10, "✗ Task $taskId not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 10, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawEditProjectForm() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Edit Project "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 8, "Field (description/status/tags):", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAtColor(4, 10, "New Value:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter fields | Esc:Cancel")
    }

    [void] HandleEditProjectForm() {
        $this.DrawEditProjectForm()
        $this.terminal.WriteAt(19, 6, "")
        [Console]::SetCursorPosition(19, 6)
        $projectName = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $this.currentView = 'tasklist'
            return
        }

        $this.terminal.WriteAt(39, 8, "")
        [Console]::SetCursorPosition(39, 8)
        $field = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($field)) {
            $this.currentView = 'tasklist'
            return
        }

        $this.terminal.WriteAt(16, 10, "")
        [Console]::SetCursorPosition(16, 10)
        $value = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($value)) {
            $this.currentView = 'tasklist'
            return
        }

        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object { $_.name -eq $projectName } | Select-Object -First 1
            if ($project) {
                switch ($field.ToLower()) {
                    'description' { $project.description = $value }
                    'status' { $project.status = $value }
                    'tags' { $project.tags = $value -split ',' | ForEach-Object { $_.Trim() } }
                    default {
                        $this.terminal.WriteAtColor(4, 12, "✗ Unknown field: $field", [PmcVT100]::Red(), "")
                        Start-Sleep -Seconds 2
                        $this.currentView = 'tasklist'
                        return
                    }
                }
                Save-PmcAllData -Data $data
                $this.terminal.WriteAtColor(4, 12, "✓ Updated project '$projectName' $field", [PmcVT100]::Green(), "")
            } else {
                $this.terminal.WriteAtColor(4, 12, "✗ Project '$projectName' not found", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Seconds 2
        } catch {
            $this.terminal.WriteAtColor(4, 12, "✗ Error: $_", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }
        $this.currentView = 'tasklist'
    }

    [void] DrawProjectInfoView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Project Info "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Project Name:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter project name | Esc:Cancel")
    }

    [void] HandleProjectInfoView() {
        $this.DrawProjectInfoView()
        $this.terminal.WriteAt(19, 6, "")
        [Console]::SetCursorPosition(19, 6)
        $projectName = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $this.currentView = 'tasklist'
            return
        }

        try {
            $data = Get-PmcAllData
            $project = $data.projects | Where-Object { $_.name -eq $projectName } | Select-Object -First 1
            if ($project) {
                $y = 8
                $this.terminal.WriteAtColor(4, $y++, "Project: $($project.name)", [PmcVT100]::Cyan(), "")
                $y++
                $this.terminal.WriteAt(4, $y++, "ID: $($project.id)")
                $this.terminal.WriteAt(4, $y++, "Description: $($project.description)")
                $this.terminal.WriteAt(4, $y++, "Status: $($project.status)")
                $this.terminal.WriteAt(4, $y++, "Created: $($project.created)")
                if ($project.tags) {
                    $this.terminal.WriteAt(4, $y++, "Tags: $($project.tags -join ', ')")
                }
                $y++

                # Count tasks
                $taskCount = @($data.tasks | Where-Object { $_.project -eq $projectName }).Count
                $completedCount = @($data.tasks | Where-Object { $_.project -eq $projectName -and $_.status -eq 'completed' }).Count
                $this.terminal.WriteAtColor(4, $y++, "Tasks: $taskCount total, $completedCount completed", [PmcVT100]::Green(), "")
            } else {
                $this.terminal.WriteAtColor(4, 8, "✗ Project '$projectName' not found", [PmcVT100]::Red(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 8, "✗ Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    [void] DrawRecentProjectsView() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Recent Projects "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        try {
            $data = Get-PmcAllData
            # Get recent tasks and extract unique projects
            $recentTasks = @($data.tasks | Where-Object { $_.project } | Sort-Object { if ($_.modified) { [DateTime]$_.modified } else { [DateTime]::MinValue } } -Descending | Select-Object -First 50)
            $recentProjects = @($recentTasks | Select-Object -ExpandProperty project -Unique | Select-Object -First 10)

            if ($recentProjects.Count -gt 0) {
                $y = 6
                $this.terminal.WriteAtColor(4, $y++, "Recently Used Projects:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($projectName in $recentProjects) {
                    $project = $data.projects | Where-Object { $_.name -eq $projectName } | Select-Object -First 1
                    $taskCount = @($data.tasks | Where-Object { $_.project -eq $projectName -and $_.status -ne 'completed' }).Count
                    if ($project) {
                        $this.terminal.WriteAtColor(4, $y++, "• $projectName", [PmcVT100]::Yellow(), "")
                        $this.terminal.WriteAt(6, $y++, "  $($project.description) ($taskCount active tasks)")
                    } else {
                        $this.terminal.WriteAt(4, $y++, "• $projectName ($taskCount active tasks)")
                    }
                }
            } else {
                $this.terminal.WriteAtColor(4, 6, "No recent projects found", [PmcVT100]::Yellow(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleRecentProjectsView() {
        $this.DrawRecentProjectsView()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    [void] DrawHelpBrowser() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Browser "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "PMC Task Management System - Help", [PmcVT100]::Cyan(), "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Navigation:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "F10 or Alt+Letter  - Open menus")
        $this.terminal.WriteAt(6, $y++, "Arrow Keys         - Navigate menus/lists")
        $this.terminal.WriteAt(6, $y++, "Enter              - Select item")
        $this.terminal.WriteAt(6, $y++, "Esc                - Cancel/Go back")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Quick Keys:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "Alt+T  - Task menu")
        $this.terminal.WriteAt(6, $y++, "Alt+P  - Project menu")
        $this.terminal.WriteAt(6, $y++, "Alt+V  - View menu")
        $this.terminal.WriteAt(6, $y++, "Alt+M  - Time menu")
        $this.terminal.WriteAt(6, $y++, "Alt+O  - Tools menu")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "For more help:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "Use Get-Command *Pmc* to see all available PowerShell commands")

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleHelpBrowser() {
        $this.DrawHelpBrowser()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    [void] DrawHelpCategories() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Categories "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Available Help Topics:", [PmcVT100]::Cyan(), "")
        $y++

        $categories = @(
            @{Name="Tasks"; Desc="Creating, editing, and managing tasks"}
            @{Name="Projects"; Desc="Project organization and tracking"}
            @{Name="Time Tracking"; Desc="Time logging and timer functions"}
            @{Name="Views"; Desc="Different task views (Agenda, Kanban, etc.)"}
            @{Name="Focus"; Desc="Focus mode for concentrated work"}
            @{Name="Dependencies"; Desc="Task dependencies and relationships"}
            @{Name="Backup/Restore"; Desc="Data backup and recovery"}
        )

        foreach ($cat in $categories) {
            $this.terminal.WriteAtColor(4, $y++, "• $($cat.Name)", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAt(6, $y++, "  $($cat.Desc)")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleHelpCategories() {
        $this.DrawHelpCategories()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    [void] DrawHelpSearch() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Help Search "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $this.terminal.WriteAtColor(4, 6, "Search for:", [PmcVT100]::Yellow(), "")

        $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Enter search term | Esc:Cancel")
    }

    [void] HandleHelpSearch() {
        $this.DrawHelpSearch()
        $this.terminal.WriteAt(17, 6, "")
        [Console]::SetCursorPosition(17, 6)
        $searchTerm = [Console]::ReadLine()

        if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
            $y = 8
            $this.terminal.WriteAtColor(4, $y++, "Search results for '$searchTerm':", [PmcVT100]::Cyan(), "")
            $y++

            # Enhanced keyword matching
            $helpTopics = @{
                'task|todo|add|create' = "Task Management - Add, edit, complete, delete tasks (Alt+T)"
                'project|organize' = "Project Organization - Create and manage projects (Alt+P)"
                'time|timer|track|log' = "Time Tracking - Track time on tasks, view reports (Alt+M)"
                'view|agenda|kanban|burndown' = "Views - Agenda, Kanban, Burndown charts (Alt+V)"
                'focus|concentrate' = "Focus Mode - Set focus for concentrated work (Alt+C)"
                'backup|restore|data' = "File Operations - Backup and restore data (Alt+F)"
                'undo|redo|revert' = "Edit Operations - Undo/redo changes (Alt+E)"
                'dependency|depends|block' = "Dependencies - Manage task dependencies (Alt+D)"
                'priority|urgent|high|low' = "Priority - Set task priority (P key in task list)"
                'due|date|deadline' = "Due Dates - Set task due dates (T key in task detail)"
                'search|find|filter' = "Search - Find tasks by text (/ key in task list)"
                'sort|order' = "Sorting - Sort tasks by various criteria (S key in task list)"
                'multi|bulk|batch' = "Multi-Select - Bulk operations on tasks (M key in task list)"
                'complete|done|finish' = "Complete Tasks - Mark tasks as done (D key or Space)"
                'delete|remove' = "Delete Tasks - Remove tasks (Delete key)"
                'help|keys|shortcuts' = "Keyboard Shortcuts - Press H for help browser"
            }

            $matches = @()
            $lowerSearch = $searchTerm.ToLower()
            foreach ($pattern in $helpTopics.Keys) {
                if ($lowerSearch -match $pattern) {
                    $matches += $helpTopics[$pattern]
                }
            }

            if ($matches.Count -gt 0) {
                foreach ($match in $matches) {
                    $this.terminal.WriteAt(4, $y++, "• $match")
                }
            } else {
                $this.terminal.WriteAtColor(4, $y, "No help topics found for '$searchTerm'", [PmcVT100]::Yellow(), "")
            }

            $this.terminal.FillArea(0, $this.terminal.Height - 1, $this.terminal.Width, 1, ' ')
            $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
            [Console]::ReadKey($true) | Out-Null
        }

        $this.currentView = 'tasklist'
    }

    [void] DrawAboutPMC() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " About PMC "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "PMC - PowerShell Project Management Console", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "A comprehensive task and project management system")
        $this.terminal.WriteAt(4, $y++, "built entirely in PowerShell")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Features:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "• Task management with priorities and due dates")
        $this.terminal.WriteAt(6, $y++, "• Project organization")
        $this.terminal.WriteAt(6, $y++, "• Time tracking and reporting")
        $this.terminal.WriteAt(6, $y++, "• Multiple views (Agenda, Kanban, etc.)")
        $this.terminal.WriteAt(6, $y++, "• Focus mode")
        $this.terminal.WriteAt(6, $y++, "• Task dependencies")
        $this.terminal.WriteAt(6, $y++, "• Automatic backups")
        $this.terminal.WriteAt(6, $y++, "• Undo/Redo support")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Version:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(6, $y++, "TUI Interface - October 2025")

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleAboutPMC() {
        $this.DrawAboutPMC()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Dependency Graph
    [void] DrawDependencyGraph() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Dependency Graph "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $tasksWithDeps = $data.tasks | Where-Object { $_.dependencies -and $_.dependencies.Count -gt 0 }

            if ($tasksWithDeps.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No task dependencies found", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, $y++, "Task Dependencies:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($task in $tasksWithDeps) {
                    $this.terminal.WriteAtColor(4, $y++, "Task #$($task.id): $($task.text ?? $task.title)", [PmcVT100]::White(), "")
                    $this.terminal.WriteAt(6, $y++, "└─> Depends on:")

                    $depCount = $task.dependencies.Count
                    for ($i = 0; $i -lt $depCount; $i++) {
                        $depId = $task.dependencies[$i]
                        $isLast = ($i -eq $depCount - 1)
                        $prefix = if ($isLast) { "    └─> " } else { "    ├─> " }

                        $depTask = $data.tasks | Where-Object { $_.id -eq $depId } | Select-Object -First 1
                        if ($depTask) {
                            $depStatus = $depTask.status
                            $statusIcon = switch ($depStatus) {
                                'done' { '✓' }
                                'completed' { '✓' }
                                'in-progress' { '⏳' }
                                'blocked' { '🚫' }
                                default { '○' }
                            }
                            $color = switch ($depStatus) {
                                'done' { [PmcVT100]::Green() }
                                'completed' { [PmcVT100]::Green() }
                                'in-progress' { [PmcVT100]::Yellow() }
                                'blocked' { [PmcVT100]::Red() }
                                default { [PmcVT100]::White() }
                            }
                            $depText = "$prefix Task #${depId}: $($depTask.text ?? $depTask.title) $statusIcon"
                            $this.terminal.WriteAtColor(8, $y++, $depText, $color, "")
                        } else {
                            $this.terminal.WriteAtColor(8, $y++, "$prefix Task #${depId}: [Missing task] ✗", [PmcVT100]::Red(), "")
                        }
                    }
                    $y++
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error loading dependencies: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleDependencyGraph() {
        $this.DrawDependencyGraph()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Burndown Chart
    [void] DrawBurndownChart() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Burndown Chart "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $currentProject = if ($this.filterProject) { $this.filterProject } else { $null }

            # Filter tasks by project if needed
            $projectTasks = if ($currentProject) {
                $data.tasks | Where-Object { $_.project -eq $currentProject }
            } else {
                $data.tasks
            }

            # Calculate burndown metrics
            $totalTasks = $projectTasks.Count
            $completedTasks = ($projectTasks | Where-Object { $_.status -eq 'done' -or $_.status -eq 'completed' }).Count
            $inProgressTasks = ($projectTasks | Where-Object { $_.status -eq 'in-progress' }).Count
            $blockedTasks = ($projectTasks | Where-Object { $_.status -eq 'blocked' }).Count
            $todoTasks = ($projectTasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' -or -not $_.status }).Count

            $projectTitle = if ($currentProject) { "Project: $currentProject" } else { "All Projects" }
            $this.terminal.WriteAtColor(4, $y++, $projectTitle, [PmcVT100]::Cyan(), "")
            $y++

            $this.terminal.WriteAtColor(4, $y++, "Task Summary:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Total Tasks:      $totalTasks", [PmcVT100]::White(), "")
            $this.terminal.WriteAtColor(6, $y++, "Completed:        $completedTasks", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(6, $y++, "In Progress:      $inProgressTasks", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "Blocked:          $blockedTasks", [PmcVT100]::Red(), "")
            $this.terminal.WriteAtColor(6, $y++, "To Do:            $todoTasks", [PmcVT100]::White(), "")
            $y++

            # Calculate completion percentage
            $completionPct = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 1) } else { 0 }
            $this.terminal.WriteAtColor(4, $y++, "Completion: $completionPct%", [PmcVT100]::Cyan(), "")
            $y++

            # Draw simple bar chart
            $barWidth = 50
            $completedWidth = if ($totalTasks -gt 0) { [math]::Floor(($completedTasks / $totalTasks) * $barWidth) } else { 0 }
            $inProgressWidth = if ($totalTasks -gt 0) { [math]::Floor(($inProgressTasks / $totalTasks) * $barWidth) } else { 0 }
            $remainingWidth = $barWidth - $completedWidth - $inProgressWidth

            $bar = ""
            if ($completedWidth -gt 0) { $bar += [string]::new('█', $completedWidth) }
            if ($inProgressWidth -gt 0) { $bar += [string]::new('▒', $inProgressWidth) }
            if ($remainingWidth -gt 0) { $bar += [string]::new('░', $remainingWidth) }

            $this.terminal.WriteAt(4, $y++, "Progress:")
            $this.terminal.WriteAt(4, $y++, "[$bar]")
            $y++

            # Legend
            $this.terminal.WriteAtColor(4, $y++, "Legend:", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "█ Completed", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(6, $y++, "▒ In Progress", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(6, $y++, "░ To Do", [PmcVT100]::White(), "")

        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error generating burndown chart: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleBurndownChart() {
        $this.DrawBurndownChart()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools Menu - Start Review
    [void] DrawStartReview() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Start Review "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        try {
            $data = Get-PmcAllData
            $reviewableTasks = $data.tasks | Where-Object {
                $_.status -eq 'review' -or $_.status -eq 'done'
            } | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, due

            if ($reviewableTasks.Count -eq 0) {
                $this.terminal.WriteAtColor(4, $y, "No tasks available for review", [PmcVT100]::Yellow(), "")
            } else {
                $this.terminal.WriteAtColor(4, $y++, "Tasks for Review:", [PmcVT100]::Cyan(), "")
                $y++

                foreach ($task in $reviewableTasks) {
                    $status = $task.status
                    $color = switch ($status) {
                        'done' { [PmcVT100]::Green() }
                        'review' { [PmcVT100]::Yellow() }
                        default { [PmcVT100]::White() }
                    }

                    $dueStr = if ($task.due) { " (Due: $($task.due))" } else { "" }
                    $projectStr = if ($task.project) { " [$($task.project)]" } else { "" }

                    $this.terminal.WriteAtColor(4, $y++, "#$($task.id): $($task.title)$projectStr$dueStr", $color, "")

                    if ($y -gt $this.terminal.Height - 4) { break }
                }
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error loading review tasks: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }

        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleStartReview() {
        $this.DrawStartReview()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools Menu - Project Wizard
    [void] DrawProjectWizard() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        $title = " Project Wizard "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Create New Project", [PmcVT100]::Cyan(), "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Project Name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, $y++, "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Description:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, $y++, "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Status (active/archived/planning):", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, $y++, "")
        $y++

        $this.terminal.WriteAtColor(4, $y++, "Tags (comma-separated):", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(4, $y++, "")

        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Esc=Cancel")
    }

    [void] HandleProjectWizard() {
        $this.DrawProjectWizard()

        # Get project name
        $this.terminal.WriteAt(18, 8, "")
        [Console]::SetCursorPosition(18, 8)
        $projName = [Console]::ReadLine()

        if ([string]::IsNullOrWhiteSpace($projName)) {
            $this.currentView = 'tasklist'
            return
        }

        # Get description
        $this.terminal.WriteAt(16, 11, "")
        [Console]::SetCursorPosition(16, 11)
        $description = [Console]::ReadLine()

        # Get status
        $this.terminal.WriteAt(36, 14, "")
        [Console]::SetCursorPosition(36, 14)
        $statusInput = [Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($statusInput)) { $statusInput = "active" }

        # Get tags
        $this.terminal.WriteAt(25, 17, "")
        [Console]::SetCursorPosition(25, 17)
        $tagsInput = [Console]::ReadLine()

        try {
            $data = Get-PmcAllData
            if (-not $data.projects) { $data.projects = @() }

            # Validate: check for duplicate project names
            $existing = $data.projects | Where-Object { $_.name -eq $projName }
            if ($existing) {
                $this.terminal.WriteAtColor(4, 20, "Error: Project '$projName' already exists!", [PmcVT100]::Red(), "")
                Start-Sleep -Seconds 2
                $this.currentView = 'tasklist'
                return
            }

            # Validate status
            $validStatuses = @('active', 'inactive', 'archived', 'completed')
            if ($statusInput -notin $validStatuses) {
                $this.terminal.WriteAtColor(4, 20, "Warning: Invalid status '$statusInput', using 'active'", [PmcVT100]::Yellow(), "")
                $statusInput = 'active'
                Start-Sleep -Seconds 1
            }

            $newProject = @{
                name = $projName
                description = $description
                status = $statusInput
                tags = if ($tagsInput) { $tagsInput -split ',' | ForEach-Object { $_.Trim() } } else { @() }
                created = (Get-Date).ToString('yyyy-MM-dd')
            }

            $data.projects += $newProject
            Save-PmcAllData -Data $data

            $this.terminal.WriteAtColor(4, 20, "✓ Project '$projName' created successfully!", [PmcVT100]::Green(), "")
            Start-Sleep -Seconds 1
        } catch {
            $this.terminal.WriteAtColor(4, 20, "Error creating project: $($_.Exception.Message)", [PmcVT100]::Red(), "")
            Start-Sleep -Seconds 2
        }

        $this.currentView = 'tasklist'
    }

    # Tools - Templates
    [void] DrawTemplates() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Task Templates "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Select a template to create task:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "1. Bug Report - Standard bug tracking template")
        $this.terminal.WriteAt(4, $y++, "2. Feature Request - New feature proposal")
        $this.terminal.WriteAt(4, $y++, "3. Code Review - Review checklist")
        $this.terminal.WriteAt(4, $y++, "4. Meeting Notes - Meeting task template")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press 1-4 to create task from template | Esc to cancel")
    }

    [void] HandleTemplates() {
        $this.DrawTemplates()

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Escape') {
                $this.currentView = 'tasklist'
                return
            }

            $template = $null
            switch ($key.KeyChar) {
                '1' {
                    $template = @{
                        title = "[BUG] "
                        description = "Steps to reproduce:`n1. `n2. `n3. `n`nExpected: `nActual: "
                        project = "bugs"
                        priority = "high"
                    }
                }
                '2' {
                    $template = @{
                        title = "[FEATURE] "
                        description = "Feature description:`n`nUser story:`nAs a [user]`nI want [feature]`nSo that [benefit]"
                        project = "features"
                        priority = "medium"
                    }
                }
                '3' {
                    $template = @{
                        title = "[REVIEW] "
                        description = "Review checklist:`n☐ Code style`n☐ Tests`n☐ Documentation`n☐ Performance`n☐ Security"
                        project = "reviews"
                        priority = "medium"
                    }
                }
                '4' {
                    $template = @{
                        title = "[MEETING] "
                        description = "Meeting notes:`nDate: $((Get-Date).ToString('yyyy-MM-dd'))`nAttendees: `nAgenda:`n- `nAction items:`n- "
                        project = "meetings"
                        priority = "low"
                    }
                }
            }

            if ($template) {
                try {
                    $data = Get-PmcAllData
                    $newId = if ($data.tasks.Count -gt 0) {
                        ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
                    } else { 1 }

                    $newTask = @{
                        id = $newId
                        title = $template.title
                        description = $template.description
                        status = "todo"
                        project = $template.project
                        priority = $template.priority
                        created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                        tags = @("template")
                    }

                    $data.tasks += $newTask
                    Save-PmcAllData -Data $data
                    $this.LoadTasks()

                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "✓ Task created from template! Press any key...", [PmcVT100]::Green(), "")
                    [Console]::ReadKey($true) | Out-Null

                    $this.currentView = 'tasklist'
                    return
                } catch {
                    $this.terminal.WriteAtColor(4, $this.terminal.Height - 3, "Error creating task: $($_.Exception.Message)", [PmcVT100]::Red(), "")
                    Start-Sleep -Seconds 2
                    return
                }
            }
        }
    }

    # Tools - Statistics
    [void] DrawStatistics() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Statistics "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        try {
            $data = Get-PmcAllData
            $total = $data.tasks.Count
            $completed = ($data.tasks | Where-Object { $_.status -eq 'done' -or $_.status -eq 'completed' }).Count
            $inProgress = ($data.tasks | Where-Object { $_.status -eq 'in-progress' }).Count
            $blocked = ($data.tasks | Where-Object { $_.status -eq 'blocked' }).Count
            $todo = ($data.tasks | Where-Object { $_.status -eq 'todo' -or $_.status -eq 'active' -or (-not $_.status) }).Count

            $this.terminal.WriteAtColor(4, $y++, "Task Statistics:", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAt(4, $y++, "Total Tasks:      $total")
            $this.terminal.WriteAtColor(4, $y++, "Completed:        $completed", [PmcVT100]::Green(), "")
            $this.terminal.WriteAtColor(4, $y++, "In Progress:      $inProgress", [PmcVT100]::Yellow(), "")
            $this.terminal.WriteAtColor(4, $y++, "To Do:            $todo", [PmcVT100]::Cyan(), "")
            $this.terminal.WriteAtColor(4, $y++, "Blocked:          $blocked", [PmcVT100]::Red(), "")
            $y++
            $completionRate = if ($total -gt 0) { [math]::Round(($completed / $total) * 100, 1) } else { 0 }
            $this.terminal.WriteAtColor(4, $y++, "Completion Rate: $completionRate%", [PmcVT100]::Cyan(), "")

            # Validation check
            $sum = $completed + $inProgress + $todo + $blocked
            if ($sum -ne $total) {
                $other = $total - $sum
                $this.terminal.WriteAtColor(4, $y++, "Other:            $other", [PmcVT100]::Gray(), "")
            }
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleStatistics() {
        $this.DrawStatistics()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools - Velocity
    [void] DrawVelocity() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Team Velocity "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        try {
            $data = Get-PmcAllData
            $now = Get-Date
            $lastWeek = $now.AddDays(-7)
            $recentCompleted = ($data.tasks | Where-Object {
                ($_.status -eq 'done' -or $_.status -eq 'completed') -and $_.completed -and ([DateTime]$_.completed) -gt $lastWeek
            }).Count
            $this.terminal.WriteAtColor(4, $y++, "Velocity Metrics (Last 7 Days):", [PmcVT100]::Cyan(), "")
            $y++
            $this.terminal.WriteAtColor(4, $y++, "Tasks Completed:  $recentCompleted", [PmcVT100]::Green(), "")
            $avgPerDay = [math]::Round($recentCompleted / 7, 1)
            $this.terminal.WriteAt(4, $y++, "Avg Per Day:      $avgPerDay")
            $projectedWeek = [math]::Round($avgPerDay * 7, 0)
            $this.terminal.WriteAt(4, $y++, "Projected/Week:   $projectedWeek")
        } catch {
            $this.terminal.WriteAtColor(4, $y, "Error: $($_.Exception.Message)", [PmcVT100]::Red(), "")
        }
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleVelocity() {
        $this.DrawVelocity()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools - Preferences
    [void] DrawPreferences() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Preferences "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "PMC Preferences:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "1. Default view:         Tasklist")
        $this.terminal.WriteAt(4, $y++, "2. Auto-save:            Enabled")
        $this.terminal.WriteAt(4, $y++, "3. Show completed:       Yes")
        $this.terminal.WriteAt(4, $y++, "4. Date format:          yyyy-MM-dd")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandlePreferences() {
        $this.DrawPreferences()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools - Config Editor
    [void] DrawConfigEditor() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Config Editor "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Configuration Settings:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "Data Path:       ~/.pmc/data.json")
        $this.terminal.WriteAt(4, $y++, "Backup Path:     ~/.pmc/backups/")
        $this.terminal.WriteAt(4, $y++, "Max Backups:     10")
        $this.terminal.WriteAt(4, $y++, "Theme:           Default")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleConfigEditor() {
        $this.DrawConfigEditor()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools - Manage Aliases
    [void] DrawManageAliases() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Manage Aliases "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Command Aliases:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "ls     = List tasks")
        $this.terminal.WriteAt(4, $y++, "add    = Add task")
        $this.terminal.WriteAt(4, $y++, "done   = Complete task")
        $this.terminal.WriteAt(4, $y++, "rm     = Delete task")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
    }

    [void] HandleManageAliases() {
        $this.DrawManageAliases()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'tasklist'
    }

    # Tools - Query Browser
    [void] DrawQueryBrowser() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $title = " Query Browser "
        $titleX = ($this.terminal.Width - $title.Length) / 2
        $this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $y = 6
        $this.terminal.WriteAtColor(4, $y++, "Saved Queries:", [PmcVT100]::Cyan(), "")
        $y++
        $this.terminal.WriteAt(4, $y++, "1. High Priority Overdue")
        $this.terminal.WriteAt(4, $y++, "2. Blocked Tasks")
        $this.terminal.WriteAt(4, $y++, "3. This Week")
        $this.terminal.WriteAt(4, $y++, "4. No Due Date")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press 1-4 to run query | Esc to return")
    }

    [void] HandleQueryBrowser() {
        $this.DrawQueryBrowser()

        while ($true) {
            $key = [Console]::ReadKey($true)

            if ($key.Key -eq 'Escape') {
                $this.currentView = 'tasklist'
                return
            }

            $data = Get-PmcAllData
            $filterApplied = $false

            switch ($key.KeyChar) {
                '1' {
                    # High Priority Overdue
                    $today = (Get-Date).Date
                    $this.tasks = @($data.tasks | Where-Object {
                        $_.priority -eq 'high' -and
                        $_.due -and
                        ([DateTime]::Parse($_.due)).Date -lt $today -and
                        $_.status -ne 'done' -and
                        $_.status -ne 'completed'
                    })
                    $this.filterStatus = "High Priority Overdue"
                    $filterApplied = $true
                }
                '2' {
                    # Blocked Tasks
                    $this.tasks = @($data.tasks | Where-Object { $_.status -eq 'blocked' })
                    $this.filterStatus = "Blocked Tasks"
                    $filterApplied = $true
                }
                '3' {
                    # This Week
                    $today = Get-Date
                    $weekEnd = $today.AddDays(7)
                    $this.tasks = @($data.tasks | Where-Object {
                        $_.due -and
                        ([DateTime]::Parse($_.due)) -ge $today -and
                        ([DateTime]::Parse($_.due)) -le $weekEnd -and
                        $_.status -ne 'done' -and
                        $_.status -ne 'completed'
                    })
                    $this.filterStatus = "Due This Week"
                    $filterApplied = $true
                }
                '4' {
                    # No Due Date
                    $this.tasks = @($data.tasks | Where-Object {
                        -not $_.due -and
                        $_.status -ne 'done' -and
                        $_.status -ne 'completed'
                    })
                    $this.filterStatus = "No Due Date"
                    $filterApplied = $true
                }
            }

            if ($filterApplied) {
                $this.selectedTaskIndex = 0
                $this.currentView = 'tasklist'
                return
            }
        }
    }

    # Tools - Weekly Report
    [void] DrawWeeklyReport() {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()

        try {
            $data = Get-PmcAllData
            $logs = if ($data.PSObject.Properties['timelogs']) { $data.timelogs } else { @() }
            Show-PmcWeeklyTimeReport -TimeLogs $logs -WeekOffset 0
        } catch {
            $this.terminal.WriteAtColor(4, 6, "Error generating weekly report: $_", [PmcVT100]::Red(), "")
        }

        $this.terminal.DrawFooter("Press any key to return")
    }

    [void] HandleWeeklyReport() {
        $this.DrawWeeklyReport()
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'timelist'
    }

    [void] Shutdown() { $this.terminal.Cleanup() }
}

# Initialize performance systems
[PmcStringCache]::Initialize()

# Helper functions
function Get-PmcTerminal { return [PmcSimpleTerminal]::GetInstance() }
function Get-PmcSpaces([int]$count) { return [PmcStringCache]::GetSpaces($count) }
function Get-PmcStringBuilder([int]$capacity = 256) { return [PmcStringBuilderPool]::Get($capacity) }
function Return-PmcStringBuilder([StringBuilder]$sb) { [PmcStringBuilderPool]::Return($sb) }

# Main entry point
function Start-PmcFakeTUI {
    try {
        Write-Host "Starting PMC FakeTUI..." -ForegroundColor Green
        $app = [PmcFakeTUIApp]::new()
        $app.Initialize()
        $app.Run()
        $app.Shutdown()
        Write-Host "PMC FakeTUI exited." -ForegroundColor Green
    } catch {
        Write-Host "Failed to start PMC FakeTUI: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Function will be exported by the main module