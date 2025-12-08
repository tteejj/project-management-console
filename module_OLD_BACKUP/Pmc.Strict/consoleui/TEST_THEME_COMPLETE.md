# COMPLETE THEME CHANGE TEST PROCEDURE

## What We Fixed
1. ✅ Config.ps1 Get-PmcConfig path (line 22) - reads from /home/teej/pmc/config.json
2. ✅ Config.ps1 Save-PmcConfig path (line 70) - writes to /home/teej/pmc/config.json
3. ✅ DI Container registers Theme service correctly
4. ✅ ThemeEditor has _ApplyTheme() method that calls Save-PmcConfig

## Test Procedure

### Step 1: Verify Current Theme
```bash
cat /home/teej/pmc/config.json
```
Should show current theme hex.

### Step 2: Start TUI
```bash
cd /home/teej/pmc/module/Pmc.Strict/consoleui
pwsh -NoProfile -Command ". ./Start-PmcTUI.ps1; Start-PmcTUI"
```

### Step 3: Open Theme Editor
- Press **F10** (opens menu)
- Press **O** (Options menu)
- Press **T** (Theme Editor)

You should see a list of themes:
- Default (blue)
- Ocean (blue)
- Lime (GREEN #33cc66)
- Purple
- Slate
- Forest (GREEN #228844)
- Sunset (orange)
- Rose (pink)
- Sky (light blue)
- Gold (yellow/orange)

### Step 4: Select Green Theme
- Use **Down Arrow** to select "Lime" (green #33cc66)
- Press **Enter**

You should see: "Theme saved! Restart TUI to see changes: Ctrl+Q then run again"

### Step 5: Exit TUI
- Press **Ctrl+Q**

### Step 6: Check Config Was Updated
```bash
cat /home/teej/pmc/config.json
```
Should show:
```json
{
  "Display": {
    "Theme": {
      "Hex": "#33cc66",
      "Enabled": true
    }
  }
}
```

### Step 7: Restart TUI
```bash
pwsh -NoProfile -Command ". ./Start-PmcTUI.ps1; Start-PmcTUI"
```

### Step 8: Verify Green Theme Applied
Check the header/menu bar colors - they should be GREEN.

## If It Still Doesn't Work

### Check Logs
```bash
LOG=$(find /home/teej/pmc/module/.pmc-data/logs -name "pmc-tui-*.log" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
echo "Latest log: $LOG"

# Check if theme was saved
grep "ApplyTheme" "$LOG"
grep "Save-PmcConfig" "$LOG"

# Check what theme was loaded
grep "Theme resolved:" "$LOG"
```

### Verify Files
```bash
# Show both config files with timestamps
ls -lh /home/teej/pmc/config.json
ls -lh /home/teej/pmc/module/config.json

# Show contents
echo "=== /home/teej/pmc/config.json ==="
cat /home/teej/pmc/config.json
echo ""
echo "=== /home/teej/pmc/module/config.json ==="
cat /home/teej/pmc/module/config.json
```

### Common Issues

1. **Enter key not working in ThemeEditor**
   - Check HandleKeyPress logs
   - Verify parent HandleKeyPress is called first

2. **Save-PmcConfig silently failing**
   - Check for write permissions on /home/teej/pmc/config.json
   - Check logs for Save-PmcConfig errors

3. **Config not reloading on restart**
   - Verify Initialize-PmcThemeSystem is called
   - Check "Theme resolved:" line in log

4. **Module not reloaded**
   - Make sure to exit pwsh completely
   - Don't use cached module session
