#!/bin/bash
# Run the TUI with comprehensive debug logging

# Clear all debug logs
rm -f /tmp/pmc-flow-debug.log
rm -f /tmp/pmc-edit-debug.log
rm -f /tmp/pmc-widget-debug.log
rm -f /tmp/pmc-esc-debug.log
rm -f /tmp/pmc-padding-debug.log
rm -f /tmp/pmc-colors-debug.log

echo "Debug logs cleared. Starting TUI..."
echo "Debug output will be written to:"
echo "  - /tmp/pmc-flow-debug.log (ENTER key and edit flow)"
echo "  - /tmp/pmc-edit-debug.log (Edit mode and row highlight)"
echo "  - /tmp/pmc-widget-debug.log (Widget interactions)"
echo "  - /tmp/pmc-esc-debug.log (ESC and menu handling)"
echo "  - /tmp/pmc-padding-debug.log (Row padding and highlighting)"
echo "  - /tmp/pmc-colors-debug.log (Color debugging)"
echo ""
echo "Press Ctrl-C to exit and capture debug logs."
echo ""

# Run the TUI
pwsh -NoProfile -Command "& '$PSScriptRoot/Start-PmcTUI.ps1'"

echo ""
echo "TUI exited. Debug logs available at:"
echo ""

if [ -f /tmp/pmc-flow-debug.log ]; then
    echo "=== FLOW DEBUG LOG (ENTER key and edit flow) ==="
    cat /tmp/pmc-flow-debug.log
    echo ""
fi

if [ -f /tmp/pmc-edit-debug.log ]; then
    echo "=== EDIT DEBUG LOG (Edit mode and row highlight) ==="
    cat /tmp/pmc-edit-debug.log
    echo ""
fi

if [ -f /tmp/pmc-widget-debug.log ]; then
    echo "=== WIDGET DEBUG LOG (Widget interactions) ==="
    cat /tmp/pmc-widget-debug.log
    echo ""
fi

if [ -f /tmp/pmc-esc-debug.log ]; then
    echo "=== ESC/MENU DEBUG LOG (ESC and menu handling) ==="
    cat /tmp/pmc-esc-debug.log
    echo ""
fi

if [ -f /tmp/pmc-padding-debug.log ]; then
    echo "=== PADDING DEBUG LOG (Row padding and highlighting) ==="
    cat /tmp/pmc-padding-debug.log
    echo ""
fi

if [ -f /tmp/pmc-colors-debug.log ]; then
    echo "=== COLOR DEBUG LOG ==="
    cat /tmp/pmc-colors-debug.log
    echo ""
fi
