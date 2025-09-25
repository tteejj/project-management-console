# --- Configuration ---
# Adjust width and height to fit your terminal.
# Note: Larger sizes will be much slower to render.
$width = 120
$height = 40

# Maximum iterations for the calculation. Higher numbers give more detail but are slower.
$maxIterations = 50

# --- Mandelbrot Set Calculation and Rendering ---

# The escape character (`e) is PowerShell's representation of \x1b
$esc = "$([char]27)"
$resetColor = "${esc}[0m"

# Define the region of the complex plane to view
$realStart = -2.0
$realEnd = 1.0
$imaginaryStart = -1.0
$imaginaryEnd = 1.0

# Pre-calculate the range for mapping
$realRange = $realEnd - $realStart
$imaginaryRange = $imaginaryEnd - $imaginaryStart

# Loop through each row of the terminal display
for ($y = 0; $y -lt $height; $y++) {
    # Use a string builder for much faster string concatenation
    $lineBuilder = New-Object System.Text.StringBuilder

    # Loop through each character in the row
    for ($x = 0; $x -lt $width; $x++) {
        # Map the console coordinate (x, y) to a point (cr, ci) in the complex plane
        $cr = $realStart + ($x / $width) * $realRange
        $ci = $imaginaryStart + ($y / $height) * $imaginaryRange

        # Initialize variables for the Mandelbrot calculation
        $zr = 0.0
        $zi = 0.0
        $iteration = 0

        # The core Mandelbrot calculation loop
        while (($zr * $zr + $zi * $zi) -lt 4 -and $iteration -lt $maxIterations) {
            $zr_temp = $zr * $zr - $zi * $zi + $cr
            $zi = 2 * $zr * $zi + $ci
            $zr = $zr_temp
            $iteration++
        }

        # --- Color Selection ---
        if ($iteration -eq $maxIterations) {
            # Point is likely inside the set: color it black
            $lineBuilder.Append("${esc}[48;2;0;0;0m ") | Out-Null
        } else {
            # Point is outside the set: color it based on how quickly it escaped
            # This is a simple coloring algorithm; many variations are possible.
            $c1 = [math]::Sin($iteration * 0.2 + 2) * 127 + 128
            $c2 = [math]::Sin($iteration * 0.2 + 4) * 127 + 128
            $c3 = [math]::Sin($iteration * 0.2 + 0) * 127 + 128

            # Append the ANSI code and a space character for the pixel
            $lineBuilder.Append("${esc}[48;2;$([int]$c1);$([int]$c2);$([int]$c3)m ") | Out-Null
        }
    }
    # Print the fully constructed line and reset color at the end
    Write-Host ($lineBuilder.ToString() + $resetColor)
}
