 Here’s the complete, actionable list of remaining work, grouped by phase and by concrete
  functions/areas to touch. This is a report only — no changes made.

  Phase 1 (Persistent Views + Global Menus)

  - Cleanup (low priority)
      - Remove or dead‑end the old single‑shot HandleSpecialView() to avoid confusion (routing
  already uses the persistent handler, but the legacy function and “Press any key…” footers remain
  in places).
      - Stop using Show-ConsoleUIFooter’s FlushInputBuffer() in contexts where it can drop
  keystrokes.

  Phase 2 (Homogeneous UX: Back, Selection/Edit, Menus Across All Views)

  - Back/Return Behavior (standardize previousView)
      - Ensure every entry into a modal/edit state sets previousView and every exit honors it:
          - Task Detail → Edit
          - Project List → Edit/Create/Rename/Archive/Delete/Info/Stats
          - Time List → Edit/Delete/Add/Report
          - File actions → Backup/Restore/Clear
          - Help → Browser/Categories/Search/About
          - Tools → Preferences/Theme/Weekly Report/Templates/Statistics/Velocity/Config
      - Current gaps: many flows still force currentView = 'tasklist' (search shows dozens of
  hardcoded returns).
  - Selection + Edit on ALL summary/grouped views (selection is working for many; remaining need
  visual highlighting + consistent footers)
      - Tomorrow: DrawTomorrowView (add selection highlight and footer)
      - Week: DrawWeekView (add selection highlight and footer)
      - Month: DrawMonthView (undated section also needs highlight)
      - No Due (standalone): DrawNoDueDateView (add selection highlight and footer)
      - Agenda: DrawAgendaView (grouped sections — either implement per‑section selection or flatten
  to a list for selection; needs highlight and footer)
      - Time Report / Timer Status / Timer Start / Timer Stop / Undo / Redo:
          - Draw functions currently display instructional copy and “Press any key to return”.
  Replace with consistent footer, action keys (e.g., S to start/stop/undo/redo), and keep the
  persistent loop. No blocking ReadKey inside draws.
  - Menus Everywhere (verify + refine)nscript   Ctrl+C quit   698K tokens used   16% context left
      - Verify Alt+letter and F10 access in all the above views after converting their loops.
  Routing now calls the persistent handler, but the Draw methods still say “Press any key to
  return” (cosmetic) and may confuse users.c to interrupt)
  - Footers: Replace “Press any key to return”
      - Replace footers in all Draw functions to show the standard controls for that screen:
          - Summary views: “↑/↓:Select  Enter:Detail  E:Edit  D:Toggle  F10/Alt:Menus  Esc:Back”
          - Action views (Timer/Undo/Redo): “S:Start/Stop/Undo/Redo  F10/Alt:Menus  Esc:Back”
      - Concrete locations (examples): lines near
          - 2484, 3107, 3180, 3259, 3877, 4009, 4242, 4511, 4604, 5011, 5874, 5933, 6321, 7063,
  7104, 7143, 7179, 7250, 7286, 7357, 7436, 7487, 7665, 7699, 7807 in ConsoleUI.Core.ps1.
  - Visual Focus/Highlight Everywhere
      - Already implemented in Task/Project/Time editors and some summary views. Extend selection
  highlighting to Tomorrow/Week/Month/NoDue/Agenda as above so they match.

  Phase 3 (Unify Forms + Input UX)

  - Replace legacy Show-InputForm with the homogenous in‑form editor (Tab/Shift+Tab, highlighted
  labels, visible cursor) for every remaining form:
      - In ConsoleUI.Core.ps1:
          - Add Task: 2176
          - Task Edit (fallback branch): 5386
          - Task Complete: 5555
          - Task Delete: 5613
          - Dependency Add/Remove: 5679, 5755
          - Project Rename/Archive/Delete: 6106, 6167, 6219
          - Time Edit (legacy path) + Time Delete: 6348, 6429
          - Preferences edit: 7755
      - Ensure each of the above honors previousView on exit, and use consistent footers (“Enter:
  Save, Esc: Cancel”).
      - Harmonize prompts to allow Esc and Tab, maintain visible cursor, and active label
  highlighting.
  - Help + Tools
      - Convert Help Browser, Help Categories, Help Search, About to the persistent view framework
  with unified footers + menus.
      - Tools (Preferences/Theme/Weekly Report/Templates/Statistics/Velocity/Config) to use
  consistent forms and/or persistent loops; eliminate single‑shot prompts.
  - Path pickers on other forms (optional, but for homogeneity and discoverability)
      - Project fields already support F2; consider:
          - Task Edit: F2 on Project field to open a project selector.
          - File/Backup/Restore paths: F2 where applicable.

  Phase 4 (Polish/Stability)

  - Remove dead code and consolidate:
      - Eliminate the legacy HandleSpecialView() body after all Draw methods are decoupled from
  single-shot logic.
      - Clean duplicated key handlers and conflicting Esc handling (Task List shows duplicated
  Escape branches).
  - Input buffer safety:
      - Remove/relax FlushInputBuffer() in Show-ConsoleUIFooter to avoid dropped Alt/Shift key
  sequences.
  - Consistent status banners and message placement:
      - Replace ad-hoc “Press any key…” footers with the standardized ones and status lines for
  success/error across all screens.
  - Test interactive loops:
      - Verify repeated Alt+letter menu activations work without losing state inside each persistent
  view.

  Quick Status Snapshot

  - Persistent views + menus: DONE (routing and handler); legacy “Press any key” strings remain and
  should be updated as part of view conversions.
  - Back navigation: Partially completed; primary edit forms (Task/Time) and menu transitions are in
  place, needs full sweep.
  - Selection + edit on summary views: Implemented for Today/Overdue/Upcoming/Blocked/Next Actions;
  remaining include Tomorrow/Week/Month/No Due/Agenda.
  - Form unification: Pending for all Show-InputForm callers listed above.
  - Visual focus/footers: Applied to several views; remaining views need the same highlight/footers.


  **************************************************************
  *************************************************************
  review 2:
   Explored
  └ Read ConsoleUI.ps1, ConsoleUI.Core.ps1, Debug.ps1, DepsLoader.ps1
    List deps
    Read TaskHandlers.ps1, ProjectHandlers.ps1, ConsoleUI-Modular.ps1, start.ps1, start-
consoleui.ps1
    Search function Show-ConsoleUIFooter|class PmcSimpleTerminal|class PmcConsoleUIApp|Get-
PmcAllData|
           Open-SystemPath|Select-ConsoleUIPathAt|Browse-ConsoleUIPath in ConsoleUI.Core.ps1
    Read Storage.ps1, Theme.ps1, Config.ps1, Types.ps1, ConsoleUI.Core.ps1, Security.ps1, State.ps1
    Search PmcStringCache\]::Initialize\(\)|class PmcStringCache|GetBoxDrawing\( in
ConsoleUI.Core.ps1
    Read ConsoleUI.Core.ps1
    Search ProcessExtendedActions\(|ShowDropdown\(|ProcessMenuAction|Start-PmcConsoleUI|Start-
Process
    Read ConsoleUI.Core.ps1
    Search function\s+Show-PmcAgendaInteractive|Show-PmcAllTasksInteractive|Show-
PmcHelpCategories|Show-
           PmcPreferences in consoleui
    Search PmcTheme\:\:SetTheme|CurrentTheme|GetColor\(|\.pmc-theme|LoadTheme\(\) in consoleui
    Search PmcTheme::SetTheme|CurrentTheme|GetColor\(|\.pmc-theme|LoadTheme\(\) in consoleui

> Here’s a focused review of the standalone ConsoleUI and its associated files only.

  Scope

  - Launchers: start-consoleui.ps1, module/Pmc.Strict/consoleui/start.ps1
  - Loader: module/Pmc.Strict/consoleui/ConsoleUI.ps1
  - Core: module/Pmc.Strict/consoleui/ConsoleUI.Core.ps1
  - Modular extensions: module/Pmc.Strict/consoleui/ConsoleUI-Modular.ps1
  - Handlers: module/Pmc.Strict/consoleui/Handlers/TaskHandlers.ps1, module/Pmc.Strict/consoleui/
  Handlers/ProjectHandlers.ps1
  - Deps loader: module/Pmc.Strict/consoleui/DepsLoader.ps1
  - Deps (subset): module/Pmc.Strict/consoleui/deps/* (Config, Storage, Security, Theme,
  UniversalDisplay, HelpUI, Types, etc.)
  - UI debug: module/Pmc.Strict/consoleui/Debug.ps1

  Summary

  - The standalone build is cleanly separated from any module import and self-contained via
  DepsLoader.ps1.
  - Core UI class, terminal rendering, menu system, and action routing are implemented in
  ConsoleUI.Core.ps1. Modular handlers extend actions via Update-TypeData.
  - Storage is hardened: locking, atomic writes with .tmp, rotating backups, undo stacks, and path/
  resource validation.
  - Cross-platform support is present (Windows Explorer vs xdg-open/gio; default file picker roots;
  ANSI themes).

  What’s Working Well

  - Architecture
      - Clear separation: ConsoleUI.ps1 loads core; ConsoleUI-Modular.ps1 augments handlers; start-
  consoleui.ps1 bootstraps without module import.
      - Robust deps isolation: DepsLoader.ps1 neutralizes Export-ModuleMember and uses local-only
  copies.
  - Rendering and UX
      - PmcSimpleTerminal, PmcStringCache, PmcStringBuilderPool provide efficient rendering with
  pooled builders and cached sequences.
      - Input flows use ReadKey loops safely; footer helpers keep user guidance visible.
      - File picker (Browse-ConsoleUIPath/Select-ConsoleUIPathAt) is intuitive with proper bounds
  and scrolling.
  - Data and Safety
      - deps/Storage.ps1: schema initialization and normalization prevent “missing property” errors
  across tasks/projects/timelogs.
      - Security (deps/Security.ps1): input/path checks, resource limits, audit logging, and secure
  file ops wrapper.
      - Config indirection: deps/Config.ps1 supports provider injection and sane defaults.
  - Compatibility
      - Legacy fields handled (e.g., dueDate as fallback for due).
      - Projects stored as strings or objects; handlers treat both.

  Notable Issues and Risks

  - Two launch variants with different features
      - module/Pmc.Strict/consoleui/start.ps1 sources ConsoleUI.ps1 (core only), so extended
  handlers (Tasks/Projects, Help, Theme tools) are not loaded there.
      - start-consoleui.ps1 sources ConsoleUI-Modular.ps1 (which loads core + handlers) and then
  starts the UI. This means user experience differs depending on which launcher is used.
  - Duplicate definition of Start-PmcConsoleUI
      - Defined in both ConsoleUI.ps1 and at the end of ConsoleUI.Core.ps1. Harmless but redundant
  and can surprise maintainers when sourcing both.
  - Two theme systems in play
      - ConsoleUI.Core.ps1 defines PmcTheme (with named palettes, saved to .pmc-theme).
      - deps/Theme.ps1 manages hex-based themes persisted in config.json.
      - Result: UI chrome (menus/boxes/labels via PmcVT100) may drift from the “Theme” applied in
  deps unless both are kept in sync.
  - Debug/log naming overlap
      - There are two debug systems: consoleui/Debug.ps1 (Write-ConsoleUIDebug) and deps Debug.ps1
  (Write-PmcDebug). Names don’t collide (good), but the presence of two logging streams can add
  confusion when troubleshooting if users expect a single log stream.
  - Minor UX nits
      - Box drawing relies on PmcStringCache.Initialize() (it is called, but late in the file);
  any early draw before initialization would fail to render frames (currently fine because
  initialization is done before UI entry point).
      - Alt+<letter> handling depends on [Console]::ReadKey behavior per terminal; in some terminals
  Alt delivery can vary.

  Suggestions

  - Unify launcher behavior
      - Option A: Update module/Pmc.Strict/consoleui/start.ps1 to source ConsoleUI-Modular.ps1
  (instead of ConsoleUI.ps1) to ensure extended handlers are available in both launch paths.
      - Option B: Keep ConsoleUI.ps1 as the single loader: dot-source ConsoleUI.Core.ps1 and then
  ConsoleUI-Modular.ps1 from it, so all entry points get the same features.
  - Remove the duplicate Start-PmcConsoleUI
      - Keep it only in one place (recommend ConsoleUI.Core.ps1 since start-consoleui.ps1 uses the
  modular loader that includes core). Let ConsoleUI.ps1 just dot-source and then call the function.
  - Bridge theme systems
      - Option A: Make PmcVT100 color accessors read from the hex theme in deps/Theme.ps1 and map it
  (or compute derived ANSI sequences), deprecating .pmc-theme.
      - Option B: When Apply-PmcTheme or Edit-PmcTheme runs, also update PmcTheme.CurrentTheme or
  write a computed palette file to .pmc-theme to keep both consistent.
  - Logging
      - Add a short note in consoleui/Debug.ps1 about the separate deps debug log to reduce
  confusion, or optionally forward Write-ConsoleUIDebug entries into the deps debug system when
  enabled.
  - Minor hardening/ergonomics
      - Consider collapsing repeated Get-PmcAllData calls during a single screen action into one
  local variable where possible for performance and consistency.
      - In Open-SystemPath, detect and report if xdg-open/gio isn’t found (currently falls back

  Validation Notes

  - start-consoleui.ps1 works because ConsoleUI-Modular.ps1 sources ConsoleUI.Core.ps1 and that
  defines Start-PmcConsoleUI at the end of the file.
  - Handlers resolve expected external functions from deps: e.g., Show-PmcAgendaInteractive in
  deps/UniversalDisplay.ps1, Show-PmcHelpCategories in deps/HelpUI.ps1, and theme tools in deps/

  - Align both launchers to the same feature set.
  - Deduplicate Start-PmcConsoleUI.
  - Add a small bridge so the console theme respects the hex theme from config.

▌unify launcher. need an easily accessible one at root of the repo. just call it start.ps1. make it
▌THE defi itive launcher. unify the theme systems. amalgamate, consolidate. get everything into one
▌place, one system. remove any other way. standardize on the one. for debug also, consolidate the
▌output. collapse the repeated calls. go.

> Next, I’ll open relevant deps to ensure we can map theme hex colors to ANSI and update the core to
  use the centralized theme, then add the root launcher and remove legacy launchers.

• Explored
  └ Read PraxisVT.ps1
    Search ConvertFrom-PmcHex in deps
    Read UI.ps1, Debug.ps1

• Added start.ps1 (+13 -0)
    1     +#!/usr/bin/env pwsh
    2     +# Definitive launcher for PMC ConsoleUI (standalone)
    3     +
    4     +Set-StrictMode -Version Latest
    5     +
    6     +$root = Split-Path -Parent $MyInvocation.MyCommand.Path
    7     +
    8     +# Always load the modular loader which brings in Core + Handlers + Deps
    9     +. "$root/module/Pmc.Strict/consoleui/ConsoleUI-Modular.ps1"
    10    +
    11    +# Start the Console UI
    12    +Start-PmcConsoleUI
    13    +

• Deleted start-consoleui.ps1 (+0 -10)
    1     -#!/usr/bin/env pwsh
    2     -# Standalone launcher for PMC ConsoleUI (no module import)
    3     -
    4     -$root = Split-Path -Parent $MyInvocation.MyCommand.Path
    5     -
    6     -# Load ConsoleUI (modular loader) directly from standalone consoleui
    7     -. "$root/module/Pmc.Strict/consoleui/ConsoleUI-Modular.ps1"
    8     -
    9     -# Start Console UI
    10    -Start-PmcConsoleUI

• Deleted module/Pmc.Strict/consoleui/start.ps1 (+0 -8)
    1     -#!/usr/bin/env pwsh
    2     -# Standalone launcher for ConsoleUI (no PMC module import)
    3     -
    4     -Set-StrictMode -Version Latest
    5     -$here = Split-Path -Parent $MyInvocation.MyCommand.Path
    6     -
    7     -. "$here/ConsoleUI.ps1"
    8     -Start-PmcConsoleUI

• Edited module/Pmc.Strict/consoleui/ConsoleUI.Core.ps1 (+57 -188)
    135
    136   -# === THEME SYSTEM ===
    137   -class PmcTheme {
    138   -    static [string]$CurrentTheme = 'Default'
    139   -    static [hashtable]$Themes = @{
    140   -        'Default' = @{
    141   -            Red = "`e[31m"
    142   -            Green = "`e[32m"
    143   -            Yellow = "`e[33m"
    144   -            Blue = "`e[34m"
    145   -            Cyan = "`e[36m"
    146   -            White = "`e[37m"
    147   -            Gray = "`e[90m"
    148   -            Black = "`e[30m"
    149   -            BgRed = "`e[41m"
    150   -            BgGreen = "`e[42m"
    151   -            BgYellow = "`e[43m"
    152   -            BgBlue = "`e[44m"
    153   -            BgCyan = "`e[46m"
    154   -            BgWhite = "`e[47m"
    155   -        }
    156   -        'Dark' = @{
    157   -            Red = "`e[38;2;255;85;85m"
    158   -            Green = "`e[38;2;80;250;123m"
    159   -            Yellow = "`e[38;2;241;250;140m"
    160   -            Blue = "`e[38;2;139;233;253m"
    161   -            Cyan = "`e[38;2;128;255;234m"
    162   -            White = "`e[38;2;248;248;242m"
    163   -            Gray = "`e[38;2;98;114;164m"
    164   -            Black = "`e[38;2;40;42;54m"
    165   -            BgRed = "`e[48;2;68;10;10m"
    166   -            BgGreen = "`e[48;2;10;68;30m"
    167   -            BgYellow = "`e[48;2;68;68;10m"
    168   -            BgBlue = "`e[48;2;10;30;68m"
    169   -            BgCyan = "`e[48;2;10;68;68m"
    170   -            BgWhite = "`e[48;2;68;68;68m"
    171   -        }
    172   -        'Light' = @{
    173   -            Red = "`e[38;2;200;40;41m"
    174   -            Green = "`e[38;2;64;160;43m"
    175   -            Yellow = "`e[38;2;181;137;0m"
    176   -            Blue = "`e[38;2;38;139;210m"
    177   -            Cyan = "`e[38;2;42;161;152m"
    178   -            White = "`e[38;2;88;110;117m"
    179   -            Gray = "`e[38;2;147;161;161m"
    180   -            Black = "`e[38;2;0;43;54m"
    181   -            BgRed = "`e[48;2;253;246;227m"
    182   -            BgGreen = "`e[48;2;238;255;238m"
    183   -            BgYellow = "`e[48;2;255;255;224m"
    184   -            BgBlue = "`e[48;2;230;244;255m"
    185   -            BgCyan = "`e[48;2;224;255;255m"
    186   -            BgWhite = "`e[48;2;238;232;213m"
    187   -        }
    188   -        'Solarized' = @{
    189   -            Red = "`e[38;2;220;50;47m"
    190   -            Green = "`e[38;2;133;153;0m"
    191   -            Yellow = "`e[38;2;181;137;0m"
    192   -            Blue = "`e[38;2;38;139;210m"
    193   -            Cyan = "`e[38;2;42;161;152m"
    194   -            White = "`e[38;2;147;161;161m"
    195   -            Gray = "`e[38;2;88;110;117m"
    196   -            Black = "`e[38;2;7;54;66m"
    197   -            BgRed = "`e[48;2;7;54;66m"
    198   -            BgGreen = "`e[48;2;7;54;66m"
    199   -            BgYellow = "`e[48;2;7;54;66m"
    200   -            BgBlue = "`e[48;2;0;43;54m"
    201   -            BgCyan = "`e[48;2;7;54;66m"
    202   -            BgWhite = "`e[48;2;88;110;117m"
    203   -        }
    204   -        'Matrix' = @{
    205   -            Red = "`e[38;2;0;255;0m"
    206   -            Green = "`e[38;2;0;255;0m"
    207   -            Yellow = "`e[38;2;0;200;0m"
    208   -            Blue = "`e[38;2;0;180;0m"
    209   -            Cyan = "`e[38;2;0;220;0m"
    210   -            White = "`e[38;2;0;255;0m"
    211   -            Gray = "`e[38;2;0;136;0m"
    212   -            Black = "`e[38;2;0;0;0m"
    213   -            BgRed = "`e[48;2;0;80;0m"
    214   -            BgGreen = "`e[48;2;0;100;0m"
    215   -            BgYellow = "`e[48;2;0;80;0m"
    216   -            BgBlue = "`e[48;2;0;80;0m"
    217   -            BgCyan = "`e[48;2;0;100;0m"
    218   -            BgWhite = "`e[48;2;0;68;0m"
    219   -        }
    220   -        'Amber' = @{
    221   -            Red = "`e[38;2;255;128;0m"
    222   -            Green = "`e[38;2;255;191;0m"
    223   -            Yellow = "`e[38;2;255;191;0m"
    224   -            Blue = "`e[38;2;255;140;0m"
    225   -            Cyan = "`e[38;2;255;165;0m"
    226   -            White = "`e[38;2;255;191;0m"
    227   -            Gray = "`e[38;2;139;90;0m"
    228   -            Black = "`e[38;2;0;0;0m"
    229   -            BgRed = "`e[48;2;139;69;0m"
    230   -            BgGreen = "`e[48;2;139;90;0m"
    231   -            BgYellow = "`e[48;2;184;134;11m"
    232   -            BgBlue = "`e[48;2;139;69;0m"
    233   -            BgCyan = "`e[48;2;139;90;0m"
    234   -            BgWhite = "`e[48;2;101;67;33m"
    235   -        }
    236   -        'Synthwave' = @{
    237   -            Red = "`e[38;2;255;0;128m"         # Hot pink
    238   -            Green = "`e[38;2;0;255;255m"       # Cyan
    239   -            Yellow = "`e[38;2;255;215;0m"      # Bright gold
    240   -            Blue = "`e[38;2;138;43;226m"       # Blue violet
    241   -            Cyan = "`e[38;2;0;255;200m"        # Bright cyan
    242   -            White = "`e[38;2;255;105;180m"     # Hot pink (lighter)
    243   -            Gray = "`e[38;2;148;0;211m"        # Dark violet
    244   -            Black = "`e[38;2;25;0;51m"         # Very dark purple
    245   -            BgRed = "`e[48;2;75;0;130m"        # Indigo background
    246   -            BgGreen = "`e[48;2;25;25;112m"     # Midnight blue background
    247   -            BgYellow = "`e[48;2;138;43;226m"   # Blue violet background
    248   -            BgBlue = "`e[48;2;72;61;139m"      # Dark slate blue
    249   -            BgCyan = "`e[48;2;123;104;238m"    # Medium slate blue
    250   -            BgWhite = "`e[48;2;138;43;226m"    # Blue violet
    251   -        }
    252   -    }
    253   -
    254   -    static [void] SetTheme([string]$themeName) {
    255   -        if ([PmcTheme]::Themes.ContainsKey($themeName)) {
    256   -            [PmcTheme]::CurrentTheme = $themeName
    257   -            # Save to local preference file within the standalone folder tree
    258   -            try {
    259   -                $rootPath = Get-PmcRootPath
    260   -            } catch { $rootPath = (Split-Path $PSScriptRoot -Parent) }
    261   -            $prefPath = Join-Path $rootPath '.pmc-theme'
    262   -            $themeName | Set-Content -Path $prefPath -Force
    263   -        }
    264   -    }
    265   -
    266   -    static [void] LoadTheme() {
    267   -        try { $rootPath = Get-PmcRootPath } catch { $rootPath = (Split-Path $PSScriptRoot
            -Parent) }
    268   -        $prefPath = Join-Path $rootPath '.pmc-theme'
    269   -        if (Test-Path $prefPath) {
    270   -            $saved = Get-Content -Path $prefPath -Raw | ForEach-Object { $_.Trim() }
    271   -            if ([PmcTheme]::Themes.ContainsKey($saved)) {
    272   -                [PmcTheme]::CurrentTheme = $saved
    273   -            }
    274   -        }
    275   -    }
    276   -
    277   -    static [string] GetColor([string]$colorName) {
    278   -        $theme = [PmcTheme]::Themes[[PmcTheme]::CurrentTheme]
    279   -        if ($theme.ContainsKey($colorName)) {
    280   -            return $theme[$colorName]
    281   -        }
    282   -        return ""
    283   -    }
    284   -}
    285   -
    136   +# === THEME SYSTEM (Unified) ===
    137   +# Adapter to the centralized theme in deps/UI.ps1 + deps/Theme.ps1
    138    class PmcVT100 {
    ⋮
    141
    290   -    static [string] MoveTo([int]$x, [int]$y) {
    291   -        return "`e[$($y + 1);$($x + 1)H"
    142   +    static hidden [string] _AnsiFromHex([string]$hex, [bool]$bg=$false) {
    143   +        if (-not $hex) { return '' }
    144   +        try {
    145   +            if (-not $hex.StartsWith('#')) { $hex = '#'+$hex }
    146   +            $rgb = ConvertFrom-PmcHex $hex
    147   +            $key = "{0}_{1}_{2}_{3}" -f ($bg ? 'bg' : 'fg'), $rgb.R, $rgb.G, $rgb.B
    148   +            if ([PmcVT100]::_colorCache.ContainsKey($key)) { return [PmcVT100]::_colorCac
           he[$key] }
    149   +            $seq = if ($bg) { "`e[48;2;$($rgb.R);$($rgb.G);$($rgb.B)m" } else { "`e[38;2;
           $($rgb.R);$($rgb.G);$($rgb.B)m" }
    150   +            if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) { [PmcVT100
           ]::_colorCache[$key] = $seq }
    151   +            return $seq
    152   +        } catch { return '' }
    153        }
    154
    294   -    static [string] RGB([int]$r, [int]$g, [int]$b) {
    295   -        $key = "fg_${r}_${g}_${b}"
    296   -        if ([PmcVT100]::_colorCache.ContainsKey($key)) {
    297   -            return [PmcVT100]::_colorCache[$key]
    298   -        }
    299   -        $sequence = "`e[38;2;$r;$g;${b}m"
    300   -        if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) {
    301   -            [PmcVT100]::_colorCache[$key] = $sequence
    302   -        }
    303   -        return $sequence
    304   -    }
    305   -
    306   -    static [string] BgRGB([int]$r, [int]$g, [int]$b) {
    307   -        $key = "bg_${r}_${g}_${b}"
    308   -        if ([PmcVT100]::_colorCache.ContainsKey($key)) {
    309   -            return [PmcVT100]::_colorCache[$key]
    155   +    static hidden [string] _MapColor([string]$name, [bool]$bg=$false) {
    156   +        # Map legacy ConsoleUI color names to centralized style tokens
    157   +        $styles = Get-PmcState -Section 'Display' -Key 'Styles'
    158   +        $token = switch ($name) {
    159   +            'Red'      { 'Error' }
    160   +            'Green'    { 'Success' }
    161   +            'Yellow'   { 'Warning' }
    162   +            'Blue'     { 'Header' }
    163   +            'Cyan'     { 'Info' }
    164   +            'White'    { 'Body' }
    165   +            'Gray'     { 'Muted' }
    166   +            'Black'    { $null }
    167   +            'BgRed'    { 'Error' }
    168   +            'BgGreen'  { 'Success' }
    169   +            'BgYellow' { 'Warning' }
    170   +            'BgBlue'   { 'Header' }
    171   +            'BgCyan'   { 'Info' }
    172   +            'BgWhite'  { 'Body' }
    173   +            default    { 'Body' }
    174            }
    311   -        $sequence = "`e[48;2;$r;$g;${b}m"
    312   -        if ([PmcVT100]::_colorCache.Count -lt [PmcVT100]::_maxColorCache) {
    313   -            [PmcVT100]::_colorCache[$key] = $sequence
    175   +        if ($null -eq $token) { return ($bg ? "`e[48;2;0;0;0m" : "`e[38;2;0;0;0m") }
    176   +        if ($styles -and $styles.ContainsKey($token)) {
    177   +            $fg = $styles[$token].Fg Ctrl+C quit   142K tokens used   76% context left
    178   +            return [PmcVT100]::_AnsiFromHex($fg, $bg)
    179            }
    315   -        return $sequence to interrupt)
    180   +        # Fallback to theme palette primary color
    181   +        $palette = Get-PmcColorPalette
    182   +        $hex = '#33aaff'
    183   +        try { $hex = ("#{0:X2}{1:X2}{2:X2}" -f $palette.Primary.R,$palette.Primary.G,$pal
           ette.Primary.B) } catch {}
    184   +        return [PmcVT100]::_AnsiFromHex($hex, $bg)
    185        }
    186
    187   +    static [string] MoveTo([int]$x, [int]$y) { return "`e[$($y + 1);$($x + 1)H" }
    188        static [string] Reset() { return "`e[0m" }
    189        static [string] Bold() { return "`e[1m" }
    320   -    static [string] Red() { return [PmcTheme]::GetColor('Red') }
    321   -    static [string] Green() { return [PmcTheme]::GetColor('Green') }
    322   -    static [string] Yellow() { return [PmcTheme]::GetColor('Yellow') }
    323   -    static [string] Blue() { return [PmcTheme]::GetColor('Blue') }
    324   -    static [string] Cyan() { return [PmcTheme]::GetColor('Cyan') }
    325   -    static [string] White() { return [PmcTheme]::GetColor('White') }
    326   -    static [string] Gray() { return [PmcTheme]::GetColor('Gray') }
    327   -    static [string] Black() { return [PmcTheme]::GetColor('Black') }
    328   -    static [string] BgRed() { return [PmcTheme]::GetColor('BgRed') }
    329   -    static [string] BgGreen() { return [PmcTheme]::GetColor('BgGreen') }
    330   -    static [string] BgYellow() { return [PmcTheme]::GetColor('BgYellow') }
    331   -    static [string] BgBlue() { return [PmcTheme]::GetColor('BgBlue') }
    332   -    static [string] BgCyan() { return [PmcTheme]::GetColor('BgCyan') }
    333   -    static [string] BgWhite() { return [PmcTheme]::GetColor('BgWhite') }
    190   +    static [string] Red() { return [PmcVT100]::_MapColor('Red', $false) }
    191   +    static [string] Green() { return [PmcVT100]::_MapColor('Green', $false) }
    192   +    static [string] Yellow() { return [PmcVT100]::_MapColor('Yellow', $false) }
    193   +    static [string] Blue() { return [PmcVT100]::_MapColor('Blue', $false) }
    194   +    static [string] Cyan() { return [PmcVT100]::_MapColor('Cyan', $false) }
    195   +    static [string] White() { return [PmcVT100]::_MapColor('White', $false) }
    196   +    static [string] Gray() { return [PmcVT100]::_MapColor('Gray', $false) }
    197   +    static [string] Black() { return [PmcVT100]::_MapColor('Black', $false) }
    198   +    static [string] BgRed() { return [PmcVT100]::_MapColor('BgRed', $true) }
    199   +    static [string] BgGreen() { return [PmcVT100]::_MapColor('BgGreen', $true) }
    200   +    static [string] BgYellow() { return [PmcVT100]::_MapColor('BgYellow', $true) }
    201   +    static [string] BgBlue() { return [PmcVT100]::_MapColor('BgBlue', $true) }
    202   +    static [string] BgCyan() { return [PmcVT100]::_MapColor('BgCyan', $true) }
    203   +    static [string] BgWhite() { return [PmcVT100]::_MapColor('BgWhite', $true) }
    204    }
    ⋮
    1021       PmcConsoleUIApp() {
    1152  -        # Load saved theme preference first
    1153  -        [PmcTheme]::LoadTheme()
    1022  +        # Theme is managed by centralized system via deps/Theme.ps1
    1023

• Edited module/Pmc.Strict/consoleui/Debug.ps1 (+18 -25)
    3
    4     -$Script:DebugLogPath = "$PSScriptRoot/consoleui-debug.log"
    5     -# Opt-in debug logging via env var PMC_CONSOLEUI_DEBUG (1/true/on). Default: off.
    6     -$Script:DebugEnabled = $false
    4     +# Consolidated debug output: forward to central Write-PmcDebug
    5     +# The standalone ConsoleUI no longer writes its own logfile; it routes
    6     +# messages into the centralized debug system configured via deps/Debug.ps1.
    7     +
    8     +# Optional opt-in level boost via PMC_CONSOLEUI_DEBUG
    9      try {
    8     -    if ($env:PMC_CONSOLEUI_DEBUG -and ($env:PMC_CONSOLEUI_DEBUG -match '^(?i:1|true|yes|o
           n)$')) { $Script:DebugEnabled = $true }
    10    +    if ($env:PMC_CONSOLEUI_DEBUG -and ($env:PMC_CONSOLEUI_DEBUG -match '^(?i:1|true|yes|o
           n)$')) {
    11    +        try { Initialize-PmcDebugSystem -Level 1 } catch {}
    12    +    }
    13     } catch {}
    ⋮
    19         )
    16    -
    17    -    if (-not $Script:DebugEnabled) { return }
    18    -
    19    -    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    20    -    $logEntry = "[$timestamp] [$Category] $Message"
    20
    21         try {
    23    -        Add-Content -Path $Script:DebugLogPath -Value $logEntry -ErrorAction SilentlyCont
           inue
    24    -    } catch {
    25    -        # Silently fail if can't write to log
    26    -    }
    22    +        Write-PmcDebug -Level 1 -Category ("ConsoleUI:" + $Category) -Message $Message
    23    +    } catch {}
    24     }
    ⋮
    26     function Clear-ConsoleUIDebugLog {
    30    -    try {
    31    -        if (Test-Path $Script:DebugLogPath) {
    32    -            Remove-Item $Script:DebugLogPath -Force
    33    -        }
    34    -        Write-ConsoleUIDebug "Debug log initialized" "SYSTEM"
    35    -    } catch {}
    27    +    # No-op: central debug handles rotation/clearing; keep for compatibility
    28    +    Write-ConsoleUIDebug "Debug initialized" "SYSTEM"
    29     }
    ⋮
    33
    41    -    if (Test-Path $Script:DebugLogPath) {
    42    -        Get-Content $Script:DebugLogPath -Tail $Lines
    43    -    } else {
    44    -        Write-Host "No debug log found at: $Script:DebugLogPath" -ForegroundColor Yellow
    45    -    }
    34    +    # Read central debug log path if available
    35    +    try {
    36    +        $path = Get-PmcDebugLogPath
    37    +        if (Test-Path $path) { Get-Content $path -Tail $Lines } else { Write-Host "No deb
           ug log found at: $path" -ForegroundColor Yellow }
    38    +    } catch { Write-Host "Debug log unavailable" -ForegroundColor Yellow }
    39     }
    40
    48    -# Do not auto-clear on load to preserve history; clear only on demand
    41    +# Centralized logging takes precedence

• Edited module/Pmc.Strict/consoleui/deps/Storage.ps1 (+20 -3)
    4
    5     +# In-memory data cache to reduce repeated disk reads across UI loops
    6     +$script:PmcDataCache = $null
    7     +$script:PmcDataDirty = $true
    8     +
    9      function Add-PmcUndoEntry {
    ⋮
    220    function Get-PmcData {
    221   +    # Serve from cache if not dirty
    222   +    if (-not $script:PmcDataDirty -and $script:PmcDataCache) { return $script:PmcDataCach
           e }
    223   +
    224        $file = Get-PmcTaskFilePath
    ⋮
    243            $data = Initialize-PmcDataSchema $data
    237   -        return $data
    244   +        $script:PmcDataCache = $data
    245   +        $script:PmcDataDirty = $false
    246   +        return $script:PmcDataCache
    247        } catch {
    ⋮
    255                    Write-PmcDebug -Level 1 -Category 'STORAGE' -Message 'Recovered data from
            tmp'
    247   -                return (Initialize-PmcDataSchema $data)
    256   +                $data = Initialize-PmcDataSchema $data
    257   +                $script:PmcDataCache = $data; $script:PmcDataDirty = $false
    258   +                return $script:PmcDataCache
    259                }
    ⋮
    270                    Write-PmcDebug -Level 1 -Category 'STORAGE' -Message ("Recovered data fro
           m backup: {0}" -f (Split-Path $bak -Leaf))
    260   -                return (Initialize-PmcDataSchema $data)
    271   +                $data = Initialize-PmcDataSchema $data
    272   +                $script:PmcDataCache = $data; $script:PmcDataDirty = $false
    273   +                return $script:PmcDataCache
    274                } catch {
    ⋮
    445
    446   +        # Update in-memory cache with saved data
    447   +        $script:PmcDataCache = $data
    448   +        $script:PmcDataDirty = $false
    449   +
    450        } catch {

• Edited module/Pmc.Strict/consoleui/ConsoleUI.ps1 (+1 -15)
    6
    7     -# Load main UI implementation
    10    -function Start-PmcConsoleUI {
    11    -    try {
    12    -        Write-Host "Starting PMC ConsoleUI..." -ForegroundColor Green
    13    -        $app = [PmcConsoleUIApp]::new()
    14    -        $app.Initialize()
    15    -        $app.Run()
    16    -        $app.Shutdown()
    17    -        Write-Host "PMC ConsoleUI exited." -ForegroundColor Green
    18    -    } catch {
    19    -        Write-Host "Failed to start PMC ConsoleUI: $($_.Exception.Message)" -ForegroundCo
           lor Red
    20    -        throw
    21    -    }
    22    -}
