# PMC TUI Debug System

## Overview
Comprehensive debugging and logging system for diagnosing rendering, lifecycle, and widget issues in the PMC TUI.

## Debug Logging

### Automatic Activation
Debug logging is **ALWAYS ENABLED** in Start-PmcTUI.ps1 until rendering issues are resolved.
- Log Level: 3 (Maximum verbosity)
- Location: `.pmc-data/logs/pmc-tui-YYYYMMDD-HHmmss.log`

### Log Categories
Logs are tagged by category for easy filtering:

| Tag | Category | Description |
|-----|----------|-------------|
| `[RENDER]` | Rendering | Render engine BeginFrame, WriteAt, EndFrame calls |
| `[LIFECYCLE]` | Screen Lifecycle | OnEnter, OnExit, LoadData events |
| `[DEBUG]` | Widget Debug | Widget-specific debug traces |
| `[ERROR]` | Errors | Exceptions and error conditions |
| `[INFO]` | Info | General information messages |

### Key Log Points

#### Rendering Pipeline (OptimizedRenderEngine.ps1)
- `BeginFrame()` - Start of render frame
- `WriteAt(x, y, content)` - Content positioning and caching
- `EndFrame()` - Frame completion and output

#### Screen Lifecycle (PmcScreen.ps1)
- `OnEnter()` - Screen activation
- `OnExit()` - Screen deactivation
- `LoadData()` - Data loading
- `RenderToEngine()` - Screen rendering

#### Widget Rendering (UniversalList.ps1, etc.)
- List rendering loop
- Row highlighting
- Column formatting
- Edit mode handling

## Debug Analysis Tool

### dump-debug-state.ps1
Analyzes log files and provides diagnostic summary:

```bash
pwsh dump-debug-state.ps1
```

**Output includes:**
- Latest log file location and size
- Last 100 log lines (color-coded)
- Event counts:
  - BeginFrame calls
  - WriteAt calls
  - Errors
  - Lifecycle events
- Common issues detection:
  - No render calls
  - No write calls
  - Null content
  - Excessive caching
- Terminal information

### Common Issues Detected

| Issue | Symptom | Likely Cause |
|-------|---------|--------------|
| NO RENDER CALLS | BeginFrame count = 0 | Render engine not initialized |
| NO WRITE CALLS | WriteAt count = 0 | Widgets not generating content |
| NULL CONTENT | "content is null/empty" in logs | Widget Render() returning empty |
| EMPTY RENDER | "RenderContent() returned null/empty" | Screen RenderContent() broken |
| EXCESSIVE CACHING | More cached than writes | Content not changing, cache working correctly |

## Live Debugging

### Tail logs in real-time
```bash
tail -f /home/teej/pmc/module/.pmc-data/logs/pmc-tui-*.log
```

### Filter by category
```bash
tail -f /path/to/log | grep '\[RENDER\]'
tail -f /path/to/log | grep '\[ERROR\]'
```

### View rendering pipeline only
```bash
tail -f /path/to/log | grep -E '\[RENDER\]|WriteAt|BeginFrame|EndFrame'
```

## Disabling Debug Logging

To disable after issues are resolved, edit Start-PmcTUI.ps1:

```powershell
# Change these lines:
$DebugLog = $true          # -> $false
$LogLevel = 3              # -> 0
```

## Debug Log Locations

| Log | Location | Purpose |
|-----|----------|---------|
| Main TUI Log | `.pmc-data/logs/pmc-tui-*.log` | All TUI events |
| Edit Debug | `/tmp/pmc-edit-debug.log` | Inline editor details |
| Colors Debug | `/tmp/pmc-colors-debug.log` | Theme color values |
| List Render Error | `/tmp/pmc-list-render-error.log` | List widget errors |

## Performance Impact

Debug logging has minimal performance impact:
- File I/O is asynchronous (Add-Content)
- Level 3 logging adds ~5-10ms per render frame
- Caching reduces repeated checks

For production use, set `$LogLevel = 0` to disable.

## Troubleshooting Guide

### Issue: Screen is blank
1. Run `dump-debug-state.ps1`
2. Check for "NO RENDER CALLS" or "NO WRITE CALLS"
3. Look for exceptions in `[ERROR]` tags
4. Verify screen lifecycle (OnEnter called?)

### Issue: Row highlighting not working
1. Check `/tmp/pmc-colors-debug.log` for theme values
2. Grep logs for "HIGHLIGHT" messages
3. Look for SkipRowHighlight conditions
4. Verify WriteAt calls for selected rows

### Issue: Content not updating
1. Count WriteAt calls vs cached entries
2. Check if IsDirty flag is being set
3. Look for RequestRender() calls
4. Verify data is actually changing

### Issue: Widgets not rendering
1. Check for widget Render() exceptions
2. Look for "_HandleWidgetRenderError" messages
3. Verify widget initialization
4. Check widget position/size values

## Example Debug Session

```bash
# 1. Start TUI (debug logging automatic)
pwsh Start-PmcTUI.ps1

# 2. In another terminal, tail logs
tail -f /home/teej/pmc/module/.pmc-data/logs/pmc-tui-*.log

# 3. After reproducing issue, analyze
pwsh dump-debug-state.ps1

# 4. Examine specific section
grep -A 5 -B 5 "ERROR" /home/teej/pmc/module/.pmc-data/logs/pmc-tui-*.log
```

## Key Files Modified

- `Start-PmcTUI.ps1` - Force debug logging enabled
- `lib/SpeedTUI/Core/OptimizedRenderEngine.ps1` - Render pipeline logging
- `PmcScreen.ps1` - Lifecycle logging
- `widgets/UniversalList.ps1` - Widget rendering traces
- `dump-debug-state.ps1` - Debug analysis tool (NEW)
- `DEBUG_SYSTEM.md` - This file (NEW)

## Next Steps

After resolving rendering issues:
1. Set `$DebugLog = $false` in Start-PmcTUI.ps1
2. Remove or comment out excessive debug logging
3. Keep error logging (`[ERROR]` tags)
4. Archive debug logs
