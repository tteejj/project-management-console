#!/bin/bash
# Capture TUI output to a file so Claude can analyze it

OUTPUT_FILE="/tmp/pmc-tui-screenshot.txt"
LOG_FILE="/tmp/pmc-tui-capture.log"

echo "Starting TUI capture session..." > "$LOG_FILE"
echo "Output will be saved to: $OUTPUT_FILE" >> "$LOG_FILE"

# Use script to create a pseudo-TTY and capture output
# Send some commands after a delay
(
    sleep 0.2
    echo "j"  # Down arrow
    sleep 0.1
    echo "k"  # Up arrow
    sleep 0.1
    printf "\x1b"  # Escape key
    sleep 0.5
) | script -qc "timeout 2 pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1" "$OUTPUT_FILE" 2>&1

echo "Capture complete. Output saved to $OUTPUT_FILE"
echo "File size: $(wc -l < "$OUTPUT_FILE") lines"

# Show a preview
echo ""
echo "=== Preview (last 30 lines) ==="
tail -30 "$OUTPUT_FILE"
