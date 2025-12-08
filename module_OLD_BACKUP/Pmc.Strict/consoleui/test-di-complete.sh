#!/bin/bash
# Test script for complete DI container implementation
# Run this to verify the entire PMC TUI works with dependency injection

cd "$(dirname "$0")"

echo "==================================="
echo "PMC TUI - Complete DI Implementation Test"
echo "==================================="
echo ""
echo "This will start the TUI. Test these features:"
echo ""
echo "1. TUI starts up without errors"
echo "2. Task list displays"
echo "3. F10 opens menu"
echo "4. Alt+O -> Alt+T opens Theme Editor"
echo "5. Select a theme and press Enter to apply"
echo "6. Exit with Ctrl+Q"
echo "7. Restart TUI and verify theme persists"
echo ""
echo "Press Enter to start TUI..."
read

pwsh -NoProfile -Command ". ./Start-PmcTUI.ps1; Start-PmcTUI"

echo ""
echo "==================================="
echo "Check the log file for DI container activity:"
LOG_FILE=$(find /home/teej/pmc/module/.pmc-data/logs -name "pmc-tui-*.log" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
echo "$LOG_FILE"
echo ""
echo "Key indicators of success:"
echo "  - 'ServiceContainer created'"
echo "  - 'Registered X services/screens'"
echo "  - 'Theme resolved: #XXXXXX'"
echo "  - 'Container set for screen'"
echo ""
echo "Run: grep -E '(ServiceContainer|Registered|Resolved|Container set)' \"$LOG_FILE\" | tail -50"
echo "==================================="
