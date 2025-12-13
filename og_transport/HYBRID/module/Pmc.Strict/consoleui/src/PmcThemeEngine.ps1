# PmcThemeEngine.ps1 - Core theme system with gradient support
#
# Handles all color resolution for the TUI:
# - Solid colors (single RGB value)
# - Multi-stop gradients (horizontal/vertical transitions)
# - Aggressive caching for performance
# - JSON-based theme configuration

using namespace System.Collections.Generic

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Theme engine singleton - handles all color/gradient computation and caching

.DESCRIPTION
Properties format in config.json:
  Solid:    { "Type": "Solid", "Color": "#ff8833" }
  Gradient: { "Type": "Gradient", "Direction": "Horizontal",
              "Stops": [{"Position": 0.0, "Color": "#ff8833"}, ...] }

Property names: "Background.Field", "Foreground.FieldFocused", etc.
#>
class PmcThemeEngine {
    hidden static [PmcThemeEngine]$_instance = $null

    # Loaded theme properties from config.json
    hidden [hashtable]$_properties = @{}
    hidden [hashtable]$_palette = @{}

    # Cache: key = "PropertyName_Width_Generation", value = string[] of ANSI sequences
    hidden [hashtable]$_gradientCache = @{}
    hidden [hashtable]$_solidCache = @{}
    hidden [int]$_cacheGeneration = 0

    # Singleton access
    static [PmcThemeEngine] GetInstance() {
        if ($null -eq [PmcThemeEngine]::_instance) {
            [PmcThemeEngine]::_instance = [PmcThemeEngine]::new()
        }
        return [PmcThemeEngine]::_instance
    }

    PmcThemeEngine() {
        # Private constructor
    }

    # Load theme from config.json structure
    [void] LoadFromConfig([hashtable]$themeConfig) {
        # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: CALLED with themeConfig.Keys=$($themeConfig.Keys -join ', ')"

        if ($themeConfig.ContainsKey('Palette')) {
            $this._palette = $themeConfig.Palette
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: Loaded Palette with $($this._palette.Count) colors"
        }
        else {
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: NO Palette in config"
        }

        if ($themeConfig.ContainsKey('Properties')) {
            $this._properties = $themeConfig.Properties
            # DEBUG ENABLED
            Write-PmcTuiLog "LoadFromConfig: Loaded Properties with $($this._properties.Count) items" "INFO"
            $propKeys = ($this._properties.Keys | Sort-Object) -join ', '
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: Property keys: [$propKeys]"
        }
        else {
            # Default properties if not defined
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: NO Properties in config, initializing defaults"
            $this._InitializeDefaultProperties()
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: After defaults, _properties.Count=$($this._properties.Count)"
        }

        $this.InvalidateCache()
        # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadFromConfig: COMPLETE, cache invalidated"
    }

    # Get background ANSI - handles solid or gradient
    # For solid: width/charIndex ignored
    # For gradient: returns ANSI for specific character position
    [string] GetBackgroundAnsi([string]$propertyName, [int]$width, [int]$charIndex) {
        # CRITICAL DEBUG: Log property lookup
        $debugMsg = "GetBackgroundAnsi: propertyName='$propertyName' _properties.Count=$($this._properties.Count) ContainsKey=$($this._properties.ContainsKey($propertyName))"
        # DEBUG ENABLED
        if (-not $this._properties.ContainsKey($propertyName)) {
            Write-PmcTuiLog "GetBackgroundAnsi: MISSING '$propertyName'. Keys: $(($this._properties.Keys | Select-Object -First 5) -join ',')" "WARN"
        }

        if ($this._properties.Count -eq 0) {
            # FAIL FAST: Do not load defaults
            # $this._InitializeDefaultProperties()
        }

        if (-not $this._properties.ContainsKey($propertyName)) {
            # Log all available keys for debugging
            $availableKeys = ($this._properties.Keys | Sort-Object) -join ', '
            # PERF: Disabled - Add-Content -Path "$($env:TEMP)\pmc-theme-engine-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') PROPERTY NOT FOUND: '$propertyName' - Available: [$availableKeys]"
            return ''
        }

        $prop = $this._properties[$propertyName]

        if ($prop.Type -eq 'Solid') {
            return $this._GetSolidAnsiCached($prop.Color, $true)
        }
        elseif ($prop.Type -eq 'Gradient') {
            $gradient = $this._GetGradientArrayCached($propertyName, $prop, $width, $true)
            if ($charIndex -ge 0 -and $charIndex -lt $gradient.Count) {
                return $gradient[$charIndex]
            }
            return ''
        }

        return ''
    }

    # Get foreground ANSI - usually solid
    [string] GetForegroundAnsi([string]$propertyName) {
        if ($this._properties.Count -eq 0) {
            # FAIL FAST
            # $this._InitializeDefaultProperties()
        }

        if (-not $this._properties.ContainsKey($propertyName)) {
            # DEBUG: Log missing property
            Write-PmcTuiLog "MISSING THEME PROPERTY: $propertyName" "ERROR"
            return ''
        }

        $prop = $this._properties[$propertyName]

        if ($prop.Type -eq 'Solid') {
            $ansi = $this._GetSolidAnsiCached($prop.Color, $false)
            # DEBUG
            if ([string]::IsNullOrEmpty($ansi)) {
                # Write-Host "THEME SOLID FAILED: $propertyName -> $($prop.Color)" -ForegroundColor Red
            }
            return $ansi
        }

        return ''
    }

    # Get integer color value for HybridRenderEngine
    # Returns packed RGB int (0x00RRGGBB)
    [int] GetThemeColorInt([string]$propertyName) {
        if (-not $this._properties.ContainsKey($propertyName)) {
            Write-PmcTuiLog "GetThemeColorInt: Property '$propertyName' not found" "ERROR"
            return 0
        }

        $prop = $this._properties[$propertyName]
        $hex = ""
        
        if ($prop.Type -eq 'Solid') {
            $hex = $prop.Color
        }
        elseif ($prop.Type -eq 'Gradient') {
            # Use first stop color for gradient fallback
            if ($prop.Stops -and $prop.Stops.Count -gt 0) {
                $hex = $prop.Stops[0].Color
            }
        }

        if ([string]::IsNullOrEmpty($hex)) { return 0 }

        $hex = $hex.TrimStart('#')
        if ($hex.Length -ne 6) { return 0 }

        try {
            $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
            $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
            $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
            
            # Pack RGB: (R << 16) | (G << 8) | B
            return ($r -shl 16) -bor ($g -shl 8) -bor $b
        }
        catch {
            return 0
        }
    }

    # Cached solid color ANSI
    hidden [string] _GetSolidAnsiCached([string]$color, [bool]$background) {
        $cacheKey = "${color}_${background}_$($this._cacheGeneration)"

        if ($this._solidCache.ContainsKey($cacheKey)) {
            return $this._solidCache[$cacheKey]
        }

        $ansi = $this._ColorToAnsi($color, $background)
        $this._solidCache[$cacheKey] = $ansi
        return $ansi
    }

    # Cached gradient array
    hidden [string[]] _GetGradientArrayCached([string]$propertyName, [hashtable]$gradient, [int]$width, [bool]$background) {
        $cacheKey = "${propertyName}_${width}_${background}_$($this._cacheGeneration)"

        if ($this._gradientCache.ContainsKey($cacheKey)) {
            return $this._gradientCache[$cacheKey]
        }

        $array = $this._ComputeGradient($gradient, $width, $background)
        $this._gradientCache[$cacheKey] = $array
        return $array
    }

    # Compute gradient as array of ANSI sequences
    hidden [string[]] _ComputeGradient([hashtable]$gradient, [int]$length, [bool]$background) {
        $result = [List[string]]::new($length)
        $stops = $gradient.Stops | Sort-Object Position

        for ($i = 0; $i -lt $length; $i++) {
            $ratio = $(if ($length -eq 1) { 0.0 } else { $i / ($length - 1) })

            # Find surrounding stops
            $beforeStop = $stops[0]
            $afterStop = $stops[-1]

            for ($s = 0; $s -lt $stops.Count - 1; $s++) {
                if ($ratio -ge $stops[$s].Position -and $ratio -le $stops[$s + 1].Position) {
                    $beforeStop = $stops[$s]
                    $afterStop = $stops[$s + 1]
                    break
                }
            }

            # Local interpolation between the two stops
            $localRatio = $(if ($afterStop.Position -eq $beforeStop.Position) {
                    0.0
                }
                else {
                    ($ratio - $beforeStop.Position) / ($afterStop.Position - $beforeStop.Position)
                })

            $color = $this._InterpolateColor($beforeStop.Color, $afterStop.Color, $localRatio)
            $result.Add($this._ColorToAnsi($color, $background))
        }

        return $result.ToArray()
    }

    # Linear color interpolation
    hidden [string] _InterpolateColor([string]$start, [string]$end, [double]$ratio) {
        $startHex = $start.TrimStart('#')
        $endHex = $end.TrimStart('#')

        $startR = [Convert]::ToInt32($startHex.Substring(0, 2), 16)
        $startG = [Convert]::ToInt32($startHex.Substring(2, 2), 16)
        $startB = [Convert]::ToInt32($startHex.Substring(4, 2), 16)

        $endR = [Convert]::ToInt32($endHex.Substring(0, 2), 16)
        $endG = [Convert]::ToInt32($endHex.Substring(2, 2), 16)
        $endB = [Convert]::ToInt32($endHex.Substring(4, 2), 16)

        $r = [int]($startR + ($endR - $startR) * $ratio)
        $g = [int]($startG + ($endG - $startG) * $ratio)
        $b = [int]($startB + ($endB - $startB) * $ratio)

        return "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b
    }

    # Convert hex color to ANSI escape sequence
    hidden [string] _ColorToAnsi([string]$hex, [bool]$background) {
        $hex = $hex.TrimStart('#')

        if ($hex.Length -ne 6) {
            return ''
        }

        try {
            $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
            $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
            $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)

            if ($background) {
                return "`e[48;2;${r};${g};${b}m"
            }
            else {
                return "`e[38;2;${r};${g};${b}m"
            }
        }
        catch {
            # DEBUG
            Write-Host "ANSI CONVERSION FAILED: '$hex' - $_" -ForegroundColor Red
            return ''
        }
    }

    # Initialize sensible defaults if config doesn't have Properties
    hidden [void] _InitializeDefaultProperties() {
        # Get theme hex from palette or use default
        $primaryHex = $(if ($this._palette.ContainsKey('Primary')) {
                $this._palette.Primary
            }
            else {
                '#ff8833'
            })

        $textHex = $(if ($this._palette.ContainsKey('Text')) {
                $this._palette.Text
            }
            else {
                '#ffe8c8'
            })

        $mutedHex = $(if ($this._palette.ContainsKey('TextDim')) {
                $this._palette.TextDim
            }
            else {
                '#888888'
            })

        $warningHex = $(if ($this._palette.ContainsKey('Warning')) {
                $this._palette.Warning
            }
            else {
                '#ffaa00'
            })

        $errorHex = $(if ($this._palette.ContainsKey('Error')) {
                $this._palette.Error
            }
            else {
                '#ff3333'
            })

        $successHex = $(if ($this._palette.ContainsKey('Success')) {
                $this._palette.Success
            }
            else {
                '#33ff33'
            })

        $borderHex = $(if ($this._palette.ContainsKey('Border')) {
                $this._palette.Border
            }
            else {
                '#b25f24'
            })

        $this._properties = @{
            'Background.Field'        = @{ Type = 'Solid'; Color = '#000000' }
            'Background.FieldFocused' = @{ Type = 'Solid'; Color = $primaryHex }
            'Background.Row'          = @{ Type = 'Solid'; Color = '#000000' }
            'Background.RowSelected'  = @{ Type = 'Solid'; Color = $primaryHex }
            'Background.Warning'      = @{ Type = 'Solid'; Color = $warningHex }
            'Background.MenuBar'      = @{ Type = 'Solid'; Color = $borderHex }
            'Foreground.Field'        = @{ Type = 'Solid'; Color = $textHex }
            'Foreground.FieldFocused' = @{ Type = 'Solid'; Color = '#FFFFFF' }
            'Foreground.Row'          = @{ Type = 'Solid'; Color = $textHex }
            'Foreground.RowSelected'  = @{ Type = 'Solid'; Color = '#FFFFFF' }
            'Foreground.Title'        = @{ Type = 'Solid'; Color = $primaryHex }
            'Foreground.Muted'        = @{ Type = 'Solid'; Color = $mutedHex }
            'Foreground.Warning'      = @{ Type = 'Solid'; Color = $warningHex }
            'Foreground.Error'        = @{ Type = 'Solid'; Color = $errorHex }
            'Foreground.Success'      = @{ Type = 'Solid'; Color = $successHex }
            'Border.Widget'           = @{ Type = 'Solid'; Color = $borderHex }
        }
    }

    # Clear all caches (call on theme reload)
    [void] InvalidateCache() {
        $this._cacheGeneration++
        $this._gradientCache.Clear()
        $this._solidCache.Clear()
    }
}