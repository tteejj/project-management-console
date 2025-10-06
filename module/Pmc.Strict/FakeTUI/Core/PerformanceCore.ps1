# PMC FakeTUI Performance Core - Extracted from SpeedTUI
# Lightweight performance optimizations without framework complexity

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Text

<#
.SYNOPSIS
String caching system for maximum performance in FakeTUI
.DESCRIPTION
Provides transparent caching of commonly used strings like spaces,
ANSI sequences, and box drawing characters for PMC's FakeTUI components.
#>
class PmcStringCache {
    # Pre-cached common strings
    static [hashtable]$_spaces = @{}
    static [hashtable]$_ansiSequences = @{}
    static [hashtable]$_boxDrawing = @{}
    static [int]$_maxCacheSize = 200
    static [bool]$_initialized = $false

    # Initialize the cache with common strings
    static [void] Initialize() {
        if ([PmcStringCache]::_initialized) { return }

        # Pre-cache common space strings (1-200 characters)
        for ($i = 1; $i -le [PmcStringCache]::_maxCacheSize; $i++) {
            [PmcStringCache]::_spaces[$i] = " " * $i
        }

        # Pre-cache common ANSI sequences
        [PmcStringCache]::_ansiSequences["reset"] = "`e[0m"
        [PmcStringCache]::_ansiSequences["clear"] = "`e[2J"
        [PmcStringCache]::_ansiSequences["clearline"] = "`e[2K"
        [PmcStringCache]::_ansiSequences["home"] = "`e[H"
        [PmcStringCache]::_ansiSequences["hidecursor"] = "`e[?25l"
        [PmcStringCache]::_ansiSequences["showcursor"] = "`e[?25h"

        # Pre-cache box drawing characters
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

        # For very large strings, build dynamically
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

<#
.SYNOPSIS
StringBuilder pooling for memory efficiency in FakeTUI
.DESCRIPTION
Manages a pool of StringBuilder objects to reduce memory allocation
for PMC's string building operations.
#>
class PmcStringBuilderPool {
    static [ConcurrentQueue[StringBuilder]]$_pool = [ConcurrentQueue[StringBuilder]]::new()
    static [int]$_maxPoolSize = 20
    static [int]$_maxCapacity = 8192  # 8KB max

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

        # Don't pool if too large (prevents memory bloat)
        if ($sb.Capacity -gt [PmcStringBuilderPool]::_maxCapacity) {
            return
        }

        # Don't pool if we're at max capacity
        if ([PmcStringBuilderPool]::_pool.Count -ge [PmcStringBuilderPool]::_maxPoolSize) {
            return
        }

        $sb.Clear()
        [PmcStringBuilderPool]::_pool.Enqueue($sb)
    }
}

<#
.SYNOPSIS
Optimized VT100/ANSI sequence generation for FakeTUI
.DESCRIPTION
Provides optimized VT100/ANSI escape sequence generation with caching
and true color support for PMC's FakeTUI components.
#>
class PmcVT100 {
    # Color cache for RGB sequences
    static [hashtable]$_colorCache = @{}
    static [int]$_maxColorCache = 200

    static [string] MoveTo([int]$x, [int]$y) {
        # Convert to 1-based for ANSI (terminals use 1-based coordinates)
        return "`e[$($y + 1);$($x + 1)H"
    }

    static [string] RGB([int]$r, [int]$g, [int]$b) {
        $key = "fg_${r}_${g}_${b}"

        if ([PmcVT100]::_colorCache.ContainsKey($key)) {
            return [PmcVT100]::_colorCache[$key]
        }

        $sequence = "`e[38;2;$r;$g;${b}m"

        # Cache if we have room
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

        # Cache if we have room
        if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) {
            [PmcVT100]::_colorCache[$key] = $sequence
        }

        return $sequence
    }

    # Common color shortcuts
    static [string] Reset() { return "`e[0m" }
    static [string] Bold() { return "`e[1m" }
    static [string] Red() { return "`e[31m" }
    static [string] Green() { return "`e[32m" }
    static [string] Yellow() { return "`e[33m" }
    static [string] Blue() { return "`e[34m" }
    static [string] Cyan() { return "`e[36m" }
    static [string] White() { return "`e[37m" }
    static [string] BgWhite() { return "`e[47m" }
    static [string] BgBlue() { return "`e[44m" }
}

# Auto-initialize the performance systems
[PmcStringCache]::Initialize()

# Helper functions for easy access
function Get-PmcSpaces([int]$count) { return [PmcStringCache]::GetSpaces($count) }
function Get-PmcStringBuilder([int]$capacity = 256) { return [PmcStringBuilderPool]::Get($capacity) }
function Return-PmcStringBuilder([StringBuilder]$sb) { [PmcStringBuilderPool]::Return($sb) }

