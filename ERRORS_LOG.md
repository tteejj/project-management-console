# PMC TUI Integration Errors Log

## Current Status
Multiple parser errors due to:
1. Using statements after script statements
2. Type casts failing at parse time  
3. Missing/wrong types (Pmc StringBuilderPool, PmcStringCache)
4. Syntax errors in migrated screen

## Errors Fixed
- PmcApplication: using statements moved to top, types changed to [object]
- PmcWidget: using statements moved to top, PmcStringCache removed, return paths fixed
- SpeedTUILoader: Write-ConsoleUIDebug removed

## Current Errors in BlockedTasksScreen.ps1
- Using statements need to be at top
- Typo: `-<` should be `-lt`
- PmcStringBuilderPool doesn't exist - use [System.Text.StringBuilder]
- Screen is too complex for first migration

## Recommendation
The architecture is sound but PowerShell's parse-time type checking makes dynamic loading difficult.
Real screen (BlockedTasksScreen) has too many dependencies for first test.
Suggest running DemoScreen which has all types already loaded.

## Commands to Run
```bash
# Run demo (should work)
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1 -StartScreen Demo

# Check logs
tail -50 /tmp/pmc-tui-*.log
```
