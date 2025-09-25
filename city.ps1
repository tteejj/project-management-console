# --- Configuration ---
$width = 120 # Width of your terminal canvas. Adjust as needed.
$height = 40 # Height of your terminal canvas.

# --- Color Palette ---
$skyColorTop = [System.Drawing.Color]::FromArgb(20, 10, 40)      # Dark Indigo
$skyColorBottom = [System.Drawing.Color]::FromArgb(40, 10, 60)   # Deep Purple
$buildingColor = [System.Drawing.Color]::FromArgb(15, 15, 25)  # Very Dark Blue/Grey
$windowColor1 = [System.Drawing.Color]::FromArgb(255, 240, 100) # Bright Yellow
$windowColor2 = [System.Drawing.Color]::FromArgb(0, 255, 255)   # Bright Cyan
$gridColor = [System.Drawing.Color]::FromArgb(255, 0, 150)       # Hot Pink

# --- Procedural Generation ---
$horizonY = $height * 0.6 # Where the ground meets the sky

# Generate some random buildings
$numBuildings = 15
$buildings = @()
for ($i = 0; $i -lt $numBuildings; $i++) {
    $bWidth = Get-Random -Minimum 5 -Maximum 15
    $bHeight = Get-Random -Minimum 5 -Maximum ($height - $horizonY - 2)
    $bX = Get-Random -Minimum 0 -Maximum ($width - $bWidth)
    $buildings += [pscustomobject]@{ X = $bX; Y = $horizonY - $bHeight; Width = $bWidth; Height = $bHeight }
}
# Sort buildings by width to create a pseudo-3D effect (smaller buildings can appear in front)
$buildings = $buildings | Sort-Object -Property Width -Descending

# --- Helper Functions ---
$esc = "$([char]27)"
$resetColor = "${esc}[0m"
function Set-BackgroundColor($color) {
    return "${esc}[48;2;$($color.R);$($color.G);$($color.B)m"
}

# --- Rendering ---
Write-Host "Generating synthwave skyline..."

# Loop through every row of the terminal display
for ($y = 0; $y -lt $height; $y++) {
    $lineBuilder = New-Object System.Text.StringBuilder

    for ($x = 0; $x -lt $width; $x++) {
        $pixelColor = $null

        # 1. Check if the pixel is part of a building
        foreach ($building in $buildings) {
            if ($x -ge $building.X -and $x -lt ($building.X + $building.Width) -and $y -ge $building.Y -and $y -lt ($building.Y + $building.Height)) {
                # It's part of a building. Should it be a window?
                if ((Get-Random -Minimum 0 -Maximum 10) -gt 8) {
                     # 1 in 10 chance of being a window
                     $pixelColor = if ((Get-Random) % 2 -eq 0) { $windowColor1 } else { $windowColor2 }
                } else {
                     $pixelColor = $buildingColor
                }
                break # Found the building for this pixel, stop searching
            }
        }

        # 2. If not a building, check what it is
        if ($null -eq $pixelColor) {
            if ($y -eq $horizonY) {
                # It's the horizon line
                $pixelColor = $gridColor
            } elseif ($y -gt $horizonY) {
                # It's the ground grid
                # Draw grid lines with a simple modulo check
                if (($x % 10 -eq 0) -or (($y - $horizonY) % 4 -eq 0)) {
                    $pixelColor = $gridColor
                } else {
                    $pixelColor = [System.Drawing.Color]::FromArgb(0,0,0) # Black for the ground
                }
            } else {
                # It's the sky, calculate gradient
                $gradientPosition = $y / $horizonY
                $r = [int]($skyColorTop.R * (1 - $gradientPosition) + $skyColorBottom.R * $gradientPosition)
                $g = [int]($skyColorTop.G * (1 - $gradientPosition) + $skyColorBottom.G * $gradientPosition)
                $b = [int]($skyColorTop.B * (1 - $gradientPosition) + $skyColorBottom.B * $gradientPosition)
                $pixelColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
            }
        }
        # Append the final colored pixel to our line
        $lineBuilder.Append("$(Set-BackgroundColor $pixelColor) ") | Out-Null
    }
    # Print the fully constructed line to the console
    Write-Host ($lineBuilder.ToString() + $resetColor)
}
