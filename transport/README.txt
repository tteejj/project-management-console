PMC TUI Distribution Package
============================
Created: December 11, 2024

PACKAGE CONTENTS:
-----------------
1. pmc-clean-package.ps1  (1.2 MB) - Self-extracting PowerShell installer
2. pmc-clean.zip          (856 KB) - Compressed ZIP archive
3. pmc-clean-base64.txt   (1.2 MB) - Base64 encoded data (embedded in .ps1)

WHAT'S INCLUDED:
----------------
- config.json, tasks.json
- module/Pmc.Strict/      (Complete PowerShell module with all fixes)
  - Pmc.Strict.psd1       (Module manifest)
  - Pmc.Strict.psm1       (Module code)
  - Core/                 (Core engine components)
  - consoleui/            (Full TUI application)
    - widgets/            (UI widgets)
    - screens/            (Screen implementations)
    - services/           (Backend services)
    - helpers/            (Utility functions)
    - base/               (Base classes)
    - theme/              (Theme system)
    - layout/             (Layout manager)
    - deps/               (Dependencies)
    - src/                (Source files)
  - src/                  (Module source code)
- lib/SpeedTUI/           (SpeedTUI framework)
  - Core/                 (Framework core)
  - Components/           (UI components)
  - Services/             (Framework services)
  - Screens/              (Framework screens)
  - Layouts/              (Layout system)
  - Models/               (Data models)
  - Utils/                (Utilities)
- module/notes/           (Notes data)
- module/.pmc-data/       (Application data directory)

WHAT'S EXCLUDED:
----------------
- All .log files
- All .md documentation files
- All .bak* backup files
- All .undo files

RECENT FIXES INCLUDED:
----------------------
- TextAreaEditor fixes (commit 5cdd13c)
- All loader and input handling fixes
- Updated screen implementations

INSTALLATION:
-------------

Option 1: Self-Extracting Script (Recommended)
  .\pmc-clean-package.ps1
  .\pmc-clean-package.ps1 -TargetPath C:\PMC

Option 2: Manual ZIP Extraction
  unzip pmc-clean.zip
  cd pmc-clean

USAGE:
------
After extraction:

  cd pmc-extracted
  Import-Module module/Pmc.Strict/Pmc.Strict.psd1 -Force
  Start-PmcTUI

PACKAGE STATISTICS:
-------------------
  ZIP Size:        856 KB
  Extracted Size:  ~3 MB
  Module Files:    200+ PowerShell files
  Framework:       SpeedTUI v1.0

---
Package created by: Claude Code Agent
Date: December 11, 2024
Branch: claude/create-powershell-package-01FK2fC77jN5Vfh3FnYN7Nir
Source: og_transport/working (with recent fixes)
