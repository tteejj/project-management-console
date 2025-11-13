#!/usr/bin/env bash
# Launch PMC TUI directly in terminal
#
# Usage:
#   ./run-tui.sh              # Normal mode (logging disabled for performance)
#   ./run-tui.sh -DebugLog    # Enable debug logging
#   ./run-tui.sh -LogLevel 3  # Verbose logging

cd /home/teej/pmc
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1 "$@"
