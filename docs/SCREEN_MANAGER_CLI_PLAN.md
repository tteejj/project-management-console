CLI-first Screen Manager Integration Plan (Detailed)

Goals
- Keep the single-line CLI as the primary interface (type → Tab/Right Arrow → Enter → Escape).
- Use Screen Manager (header/status/content/input) to make assists calm, minimal, and fast.
- Standardize navigation across pickers/wizards: Arrow keys + Enter + Escape only.

Phase 1: Status + Toast Primitives
- File: module/Pmc.Strict/src/ScreenManager.ps1
  - Add: Write-PmcStatus([string]$Text, [string]$Style='Muted')
    - Writes one line (truncated) to header’s status region (right side), using PmcTerminalService for width.
  - Add: Show-PmcToast([string]$Text, [int]$Ms=2000, [string]$Style='Success')
    - Non-blocking: calls Write-PmcStatus, auto-clears on timer tick or next command.
- File: module/Pmc.Strict/src/UI.ps1 (or thin wrapper)
  - Route Show-PmcSuccess/Error/Warning/Info to Write-PmcStatus when ScreenManager is available; else current behavior.

Phase 2: Unify Navigation for Pickers (Return Tokens)
- Use PmcGridRenderer with NavigationMode (EditMode = $false) + OnSelectCallback.
- OnSelectCallback inserts a token into the input buffer (see Pmc-InsertAtCursor) and exits; Escape cancels.
- File: module/Pmc.Strict/src/Interactive.ps1
  - Add: Pmc-InsertAtCursor([string]$Text): mutates PmcEditorState.Buffer at CursorPos and re-renders.
- File: existing pickers (e.g., ExcelFlowLite Invoke-PmcPathPicker)
  - Ensure Set-PmcHeader + Clear-PmcContentArea are used; Enter inserts, Escape cancels.

Phase 3: Ghost Suggestions (Inline)
- File: module/Pmc.Strict/src/Interactive.ps1
  - State: GhostText, GhostList, GhostIndex (kept in interactive state map).
  - Compute ghost in Render-Interactive:
    1) Domain → actions from $Script:PmcCommandMap.
    2) Args from Get-PmcSchema -Domain d -Action a (prefix+name).
    3) Prefix-match history best candidate (non-destructive).
  - Render ghost after cursor with dim style (Render-Line).
  - Keys:
    - RightArrow: accept remainder of GhostText.
    - Tab: cycle GhostList; if no ghost, fall back to Phase 4.
    - Escape: clear ghost (no buffer changes).

Phase 4: Compact Completion Overlay (Optional)
- File: module/Pmc.Strict/src/Interactive.ps1
  - Add: Show-PmcMiniList([string[]]$Items,[string]$Title='') → returns string or $null.
    - Uses Set-PmcHeader (Title + short hint), Clear-PmcContentArea; small list (5–7 rows) via PmcGridRenderer in NavigationMode.
  - Bind Tab: when no ghost present, open mini-list for domains/actions/args/enum values; Enter inserts via Pmc-InsertAtCursor; Escape closes.

Phase 5: Token-Aware Hints (Status Line)
- File: module/Pmc.Strict/src/Interactive.ps1
  - For token under cursor:
    - If enum-like arg (e.g., format:), show options in status (CSV JSON) from schema.
    - Else show compact Pmc-FormatSchemaSummary.
  - Escape clears hints.

Phase 6: Prefix-Aware History Reuse (Non-Destructive)
- File: module/Pmc.Strict/src/Interactive.ps1
  - Up/Down with text in buffer: show prefix-matching history as ghost (do not replace buffer).
  - RightArrow/Enter accept; Escape cancels ghost.
  - Up/Down with empty buffer: keep existing history navigation behavior.

Phase 7: NAV Flag Compliance
- File: module/Pmc.Strict/src/State.ps1 (flag), overlays and pickers
  - Respect state Display.NavMode: force NavigationMode for overlays; header shows NAV while overlay is active; clear on exit.

Phase 8: Quiet Progress (Status)
- Files: long operations (exports/batch/xflow)
  - Optional -OnProgress callback updating Write-PmcStatus("Exporting… {pct}%").
  - On completion: Show-PmcToast("✓ …") and clear status.

Phase 9: Picker Library (Token Suppliers)
- File: module/Pmc.Strict/src/Pickers.ps1 (new)
  - Functions: Pick-PmcFile, Pick-PmcFolder, Pick-PmcProject, Pick-PmcDate.
  - All use NavigationMode, OnSelect inserts token via Pmc-InsertAtCursor, Escape cancels.
  - Gradually replace bespoke pickers with these.

Phase 10: Command Palette and Tiny Examples (Insert-Only)
- File: module/Pmc.Strict/src/Interactive.ps1
  - Ctrl+K: Show-PmcMiniList of "domain action" pairs; Enter inserts skeleton; Escape cancels.
  - "??" at end of line: show 2–3 compact examples; Enter inserts; Escape closes.

Help System Integration (High Level)
- Keep CLI-centric: input stays in place; help uses content/status regions.
- Use NavigationMode for help lists; Enter selects, Escape exits.
- Prefer schema-driven customization over bespoke displays (see below).

Exact Touchpoints for Help
- File: module/Pmc.Strict/src/HelpUI.ps1
  - Ensure Show-PmcHelpCategories/Commands call Show-PmcCustomGrid (or PmcGridRenderer) with -NavigationMode and OnSelect to insert tokens or jump to command help.
  - Use Set-PmcHeader for titles and one-line hints; Clear-PmcContentArea before rendering lists.
- File: module/Pmc.Strict/src/Interactive.ps1
  - Enhance Pmc-FormatSchemaSummary and token-hint logic to show arg details from schema (see Schemas custom fields).
- File: module/Pmc.Strict/src/Schemas.ps1
  - Extend schema entries with optional fields: Enum (string[]), Examples (string[]), Help (string), InsertTemplate (string), Picker (string|scriptblock).
  - Interactive engine reads these to provide hints, mini-lists, pickers, and skeleton insertions.

Why Schema-Driven Instead of Custom Display
- Custom fields let the same Help UI and Interactive engine adapt per command/arg without bespoke UIs.
- Screen Manager provides the structure; the data (hints, enums, templates) comes from schema, making help consistent and easy to extend.

Intrusiveness Summary
- Low: status/toasts, navigation for pickers, help header/content usage, NAV flag, quiet progress.
- Moderate: ghost suggestions, compact overlay, prefix-aware history, schema field extensions, palette keybinding.
- All changes are localized (Interactive.ps1, ScreenManager.ps1, Schemas.ps1, HelpUI.ps1) and backward-compatible with the CLI model.

