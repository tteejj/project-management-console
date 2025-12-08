# PMC TUI Portable Package

Package created: 2025-12-04 20:37:57

## Quick Start (Windows)

1. Run the decoder script:
   ```powershell
   .\Extract-PmcTUI.ps1 -EncodedFile pmc-tui-portable-20251204-203753.zip.b64 -DestinationPath C:\pmc-test
   ```

2. Navigate to the TUI:
   ```powershell
   cd C:\pmc-test\module\Pmc.Strict\consoleui
   ```

3. Start the TUI:
   ```powershell
   .\Start-PmcTUI.ps1
   ```

## Package Contents

- **Total Files**: 1887
- **Config Included**: True
- **Tasks Included**: False

## Requirements

- PowerShell 7.0 or later
- Windows Terminal or compatible VT100 terminal
- No external dependencies required

## Directory Structure

```
pmc-test/
├── module/Pmc.Strict/
│   ├── Pmc.Strict.psd1          (Module manifest)
│   ├── Pmc.Strict.psm1          (Module root)
│   ├── consoleui/
│   │   ├── Start-PmcTUI.ps1     (Entry point)
│   │   ├── helpers/             (Utilities)
│   │   ├── services/            (Data services)
│   │   ├── widgets/             (UI components)
│   │   ├── screens/             (TUI screens)
│   │   └── base/                (Base classes)
│   └── src/                     (Core PMC functions)
├── lib/SpeedTUI/                (Rendering framework)
├── config.json                  (Configuration)
└── tasks.json                   (Task data)
```

## Troubleshooting

**Issue**: Script execution disabled
**Fix**: Run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

**Issue**: Module not found
**Fix**: Ensure you're in the correct directory (consoleui/)

**Issue**: Display corruption
**Fix**: Use Windows Terminal or a VT100-compatible terminal

## Support

For issues or questions, see the main PMC repository.
