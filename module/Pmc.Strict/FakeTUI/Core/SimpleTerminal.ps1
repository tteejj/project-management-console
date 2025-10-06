# PMC FakeTUI Simple Terminal - Minimal terminal control for static UI
# Based on SpeedTUI SimplifiedTerminal but adapted for PMC's needs

. "$PSScriptRoot/PerformanceCore.ps1"

class PmcSimpleTerminal {
    static [PmcSimpleTerminal]$Instance = $null
    [int]$Width
    [int]$Height
    [bool]$CursorVisible = $true

    hidden PmcSimpleTerminal() { $this.UpdateDimensions() }
    static [PmcSimpleTerminal] GetInstance() { if ($null -eq [PmcSimpleTerminal]::Instance) { [PmcSimpleTerminal]::Instance = [PmcSimpleTerminal]::new() } return [PmcSimpleTerminal]::Instance }
    [void] Initialize() { [Console]::Clear(); try { [Console]::CursorVisible = $false; $this.CursorVisible = $false } catch {}; $this.UpdateDimensions(); [Console]::SetCursorPosition(0,0) }
    [void] Cleanup() { try { [Console]::CursorVisible = $true; $this.CursorVisible = $true } catch {}; [Console]::Clear() }
    [void] UpdateDimensions() { try { $this.Width=[Console]::WindowWidth; $this.Height=[Console]::WindowHeight } catch { $this.Width=120; $this.Height=30 } }
    [void] Clear() { [Console]::Clear(); [Console]::SetCursorPosition(0,0) }
    [void] WriteAt([int]$x,[int]$y,[string]$text) { if ([string]::IsNullOrEmpty($text)) { return }; if ($x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }; $maxLength=$this.Width-$x; if ($text.Length -gt $maxLength) { $text = $text.Substring(0,$maxLength) }; [Console]::SetCursorPosition($x,$y); [Console]::Write($text) }
    [void] WriteAtColor([int]$x,[int]$y,[string]$text,[string]$foreground,[string]$background="") { if ([string]::IsNullOrEmpty($text)) { return }; if ($x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) { return }; $maxLength=$this.Width-$x; if ($text.Length -gt $maxLength) { $text = $text.Substring(0,$maxLength) }; $colored=$foreground; if (-not [string]::IsNullOrEmpty($background)) { $colored+=$background }; $colored += $text + [PmcVT100]::Reset(); [Console]::SetCursorPosition($x,$y); [Console]::Write($colored) }
    [void] WriteAtRGB([int]$x,[int]$y,[string]$text,[int]$r,[int]$g,[int]$b) { $color=[PmcVT100]::RGB($r,$g,$b); $this.WriteAtColor($x,$y,$text,$color,"") }
    [void] WriteAtRGBBg([int]$x,[int]$y,[string]$text,[int]$fgR,[int]$fgG,[int]$fgB,[int]$bgR,[int]$bgG,[int]$bgB) { $fgColor=[PmcVT100]::RGB($fgR,$fgG,$fgB); $bgColor=[PmcVT100]::BgRGB($bgR,$bgG,$bgB); $this.WriteAtColor($x,$y,$text,$fgColor,$bgColor) }
    [void] FillArea([int]$x,[int]$y,[int]$width,[int]$height,[char]$ch=' ') { if ($width -le 0 -or $height -le 0) { return }; $line = if ($ch -eq ' ') { [PmcStringCache]::GetSpaces($width) } else { [string]::new($ch,$width) }; for($row=0;$row -lt $height;$row++){ $currentY=$y+$row; if ($currentY -ge $this.Height) { break }; $this.WriteAt($x,$currentY,$line) } }
    [void] DrawBox([int]$x,[int]$y,[int]$width,[int]$height) { if ($width -lt 2 -or $height -lt 2) { return }; if ($x + $width -gt $this.Width -or $y + $height -gt $this.Height) { return }; $tl=[PmcStringCache]::GetBoxDrawing("topleft"); $tr=[PmcStringCache]::GetBoxDrawing("topright"); $bl=[PmcStringCache]::GetBoxDrawing("bottomleft"); $br=[PmcStringCache]::GetBoxDrawing("bottomright"); $h=[PmcStringCache]::GetBoxDrawing("horizontal"); $v=[PmcStringCache]::GetBoxDrawing("vertical"); $topLine=$tl + ([PmcStringCache]::GetSpaces($width-2).Replace(' ',$h)) + $tr; $bottomLine=$bl + ([PmcStringCache]::GetSpaces($width-2).Replace(' ',$h)) + $br; $this.WriteAt($x,$y,$topLine); for($row=1;$row -lt $height-1;$row++){ $this.WriteAt($x,$y+$row,$v); $this.WriteAt($x+$width-1,$y+$row,$v) }; $this.WriteAt($x,$y+$height-1,$bottomLine) }
    [void] DrawFilledBox([int]$x,[int]$y,[int]$width,[int]$height,[bool]$border=$true){ $this.FillArea($x,$y,$width,$height,' '); if ($border){ $this.DrawBox($x,$y,$width,$height) } }
    [void] ClearRegion([int]$x,[int]$y,[int]$width,[int]$height){ $this.FillArea($x,$y,$width,$height,' ') }
    [void] SetCursorPosition([int]$x,[int]$y){ if ($x -ge 0 -and $y -ge 0 -and $x -lt $this.Width -and $y -lt $this.Height){ [Console]::SetCursorPosition($x,$y) } }
    [void] ShowCursor([bool]$visible){ try { [Console]::CursorVisible=$visible; $this.CursorVisible=$visible } catch {} }
    [void] DrawHorizontalLine([int]$x,[int]$y,[int]$length){ if ($length -le 0){ return }; $h=[PmcStringCache]::GetBoxDrawing("horizontal"); $line=[PmcStringCache]::GetSpaces($length).Replace(' ',$h); $this.WriteAt($x,$y,$line) }
    [void] DrawVerticalLine([int]$x,[int]$y,[int]$length){ if ($length -le 0){ return }; $v=[PmcStringCache]::GetBoxDrawing("vertical"); for($i=0;$i -lt $length;$i++){ $this.WriteAt($x,$y+$i,$v) } }
}

function Get-PmcTerminal { return [PmcSimpleTerminal]::GetInstance() }

