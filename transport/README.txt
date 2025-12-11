PMC Package - Distribution Files
================================
Created: December 11, 2024

PACKAGE CONTENTS:
-----------------
1. pmc-package.ps1          - Self-extracting PowerShell installer (143 KB)
2. pmc-package.zip          - Compressed package archive (104 KB)
3. pmc-package-base64.txt   - Base64 encoded ZIP (for reference)

WHAT'S INCLUDED:
----------------
Core Application:
  - pmc.ps1, start-pmc.ps1, start.ps1
  - Debug.ps1, DepsLoader.ps1
  - Start-ConsoleUI.ps1, Pack-ConsoleUI.ps1
  - run-tui.sh (Linux/Mac launcher)

Configuration:
  - config.json
  - tasks.json

Dependencies & Modules:
  - deps/     (20+ PowerShell dependency files)
  - tools/    (Utility scripts)
  - ui/       (UI components)
  - screens/  (Screen definitions)
  - Handlers/ (Event handlers)

WHAT'S EXCLUDED:
----------------
  - All .md documentation files
  - All .log files
  - All .bak* backup files
  - All .undo files
  - archive/ directory
  - module_OLD_BACKUP/ directory
  - og_transport/ directory
  - tests/ directory
  - .git/ directory
  - unused_files_backup.zip

INSTALLATION:
-------------

Option 1: Self-Extracting Script (Recommended)
  Windows PowerShell:
    .\pmc-package.ps1
    .\pmc-package.ps1 -TargetPath C:\PMC

Option 2: Manual ZIP Extraction
  unzip pmc-package.zip
  cd pmc-package

USAGE:
------
After extraction:

  Windows:
    cd pmc-extracted
    pwsh .\start-pmc.ps1

  Linux/Mac:
    cd pmc-extracted
    ./run-tui.sh

PACKAGE STATISTICS:
-------------------
  ZIP Size:        104 KB
  Extracted Size:  ~280 KB
  Files Included:  40+ PowerShell files
  Directories:     5 (deps, tools, ui, screens, Handlers)

SHARING:
--------
To share this package via email or other channels, use:
  - pmc-package.ps1 (recommended - self-extracting)
  - pmc-package.zip (alternative - manual extraction)

The base64 file is provided for reference but is already embedded
in the .ps1 self-extracting script.

---
Package created by: Claude Code Agent
Date: December 11, 2024
Branch: claude/create-powershell-package-01FK2fC77jN5Vfh3FnYN7Nir
