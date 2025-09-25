# --- Configuration ---
$width = 80  # Width of the drawing canvas in characters
$height = 40 # Height of the canvas

# Sun properties
$sunCenterX = $width / 2
$sunCenterY = $height / 2
$sunRadius = 12

# Gradient Colors (from top to bottom)
$colorTop = [System.Drawing.Color]::FromArgb(255, 220, 30)   # Bright Yellow/Orange
$colorMiddle = [System.Drawing.Color]::FromArgb(255, 40, 120)  # Hot Pink
$colorBottom = [System.Drawing.Color]::FromArgb(200, 20, 100) # Deep Magenta

# --- Rendering ---
$esc = "$([char]27)"
$resetColor = "${esc}[0m"
$blackBG = "${esc}[48;2;5;5;15m" # A very dark blue, not quite black

# Loop through every character cell of our canvas
for ($y = 0; $y -lt $height; $y++) {
    $lineBuilder = New-Object System.Text.StringBuilder

    for ($x = 0; $x -lt $width; $x++) {
        # Calculate the distance of this (x,y) pixel from the sun's center
        $distance = [math]::Sqrt([math]::Pow($x - $sunCenterX, 2) + [math]::Pow($y - $sunCenterY, 2))

        # Is this pixel inside our sun circle?
        if ($distance -lt $sunRadius) {
            # This pixel is part of the sun, so calculate its color

            # Determine how far down the sun we are (0.0 at top, 1.0 at bottom)
            $gradientPosition = ($y - ($sunCenterY - $sunRadius)) / ($sunRadius * 2)

            # Simple two-part gradient (Top -> Middle -> Bottom)
            if ($gradientPosition -lt 0.5) {
                # Interpolate between Top and Middle
                $pos = $gradientPosition * 2
                $r = [int]($colorTop.R * (1 - $pos) + $colorMiddle.R * $pos)
                $g = [int]($colorTop.G * (1 - $pos) + $colorMiddle.G * $pos)
                $b = [int]($colorTop.B * (1 - $pos) + $colorMiddle.B * $pos)
            } else {
                # Interpolate between Middle and Bottom
                $pos = ($gradientPosition - 0.5) * 2
                $r = [int]($colorMiddle.R * (1 - $pos) + $colorBottom.R * $pos)
                $g = [int]($colorMiddle.G * (1 - $pos) + $colorBottom.G * $pos)
                $b = [int]($colorMiddle.B * (1 - $pos) + $colorBottom.B * $pos)
            }

            # Append the calculated color pixel
            $lineBuilder.Append("${esc}[48;2;${r};${g};${b}m ") | Out-Null

        } else {
            # This pixel is the background
            $lineBuilder.Append("${blackBG} ") | Out-Null
        }
    }
    # Print the finished line
    Write-Host ($lineBuilder.ToString() + $resetColor)
}
