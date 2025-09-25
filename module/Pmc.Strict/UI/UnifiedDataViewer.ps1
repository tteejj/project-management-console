# PMC Unified Data Viewer - Real-time data display with navigation
# Preserves PMC's existing query language and data structures

Set-StrictMode -Version Latest

# Data viewer state and configuration
class PmcDataViewerState {
    [string] $DataType = "tasks"           # tasks, projects, timelog, help
    [object[]] $Data = @()                 # Current dataset
    [object[]] $FilteredData = @()         # After filtering/sorting
    [hashtable] $Columns = @{}             # Column configuration
    [string] $Query = ""                   # Current query string
    [hashtable] $Filters = @{}             # Active filters

    # View state
    [int] $SelectedRow = 0
    [int] $ScrollOffset = 0
    [int] $VisibleRows = 20
    [string] $SortColumn = ""
    [string] $SortDirection = "asc"

    # Real-time update tracking
    [datetime] $LastUpdate = [datetime]::Now
    [string] $LastDataHash = ""
    [bool] $AutoRefresh = $false
    [int] $RefreshIntervalMs = 1000

    [void] Reset() {
        $this.SelectedRow = 0
        $this.ScrollOffset = 0
        $this.Query = ""
        $this.Filters.Clear()
        $this.LastUpdate = [datetime]::Now
    }

    [void] SetData([object[]]$newData) {
        $this.Data = $newData
        $this.FilteredData = $newData
        $this.SelectedRow = 0
        $this.ScrollOffset = 0
        $this.LastUpdate = [datetime]::Now

        # Calculate hash for change detection
        $this.LastDataHash = $this.CalculateDataHash($newData)
    }

    [string] CalculateDataHash([object[]]$data) {
        if (-not $data -or $data.Count -eq 0) { return "" }

        try {
            $hashInput = ($data | ConvertTo-Json -Compress)
            $hash = [System.Security.Cryptography.SHA256]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashInput)
            $hashBytes = $hash.ComputeHash($bytes)
            return [Convert]::ToBase64String($hashBytes).Substring(0, 16)
        } catch {
            return [datetime]::Now.Ticks.ToString()
        }
    }

    [bool] HasDataChanged([object[]]$newData) {
        $newHash = $this.CalculateDataHash($newData)
        return $newHash -ne $this.LastDataHash
    }
}

# Main unified data viewer class
class PmcUnifiedDataViewer {
    hidden [PmcDataViewerState] $_state
    hidden [object] $_renderer
    hidden [object] $_bounds
    hidden [hashtable] $_theme = @{}
    hidden [bool] $_initialized = $false

    # Integration with existing PMC systems
    [scriptblock] $QueryExecutor = $null     # Executes PMC queries
    [scriptblock] $DataProvider = $null      # Provides raw data
    [scriptblock] $ColumnProvider = $null    # Provides column definitions

    # Event handlers
    [scriptblock] $OnSelectionChanged = $null
    [scriptblock] $OnDataChanged = $null
    [scriptblock] $OnQueryChanged = $null

    PmcUnifiedDataViewer([object]$bounds) {
        $this._state = [PmcDataViewerState]::new()
        $this._bounds = $bounds
        $this.InitializeTheme()
        $this._initialized = $true
    }

    [void] InitializeTheme() {
        # Get theme from PMC's existing theme system
        try {
            $display = Get-PmcState -Section 'Display' -Key 'Theme' -ErrorAction SilentlyContinue
            if ($display) {
                $this._theme = @{
                    HeaderFg = 'white'
                    HeaderBg = 'blue'
                    SelectedFg = 'black'
                    SelectedBg = 'cyan'
                    NormalFg = 'white'
                    NormalBg = 'black'
                    BorderFg = 'gray'
                    Accent = $display.Hex ?? '#33aaff'
                }
            } else {
                # Fallback theme
                $this._theme = @{
                    HeaderFg = 'white'
                    HeaderBg = 'blue'
                    SelectedFg = 'black'
                    SelectedBg = 'cyan'
                    NormalFg = 'white'
                    NormalBg = 'black'
                    BorderFg = 'gray'
                    Accent = '#33aaff'
                }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Theme initialization failed, using defaults"
        }
    }

    # No column normalization fallbacks — providers must return an array of @{ Name; DisplayName; Width }

    hidden [string] GetColName([object]$col) { if ($null -eq $col) { return '' }; if ($col -is [hashtable]) { return [string]$col['Name'] }; return [string]$col.Name }

    hidden [int] GetColWidth([object]$col) { if ($null -eq $col) { return 0 }; if ($col -is [hashtable]) { return [int]$col['Width'] }; return [int]$col.Width }

    hidden [string] NormalizeDataType([string]$dataType) {
        $normalized = ''
        if (-not $dataType) {
            $normalized = ''
        } else {
            $lower = $dataType.ToLower()
            switch ($lower) {
                'tasks'    { $normalized = 'task' }
                'projects' { $normalized = 'project' }
                default    { $normalized = $lower }
            }
        }
        return $normalized
    }

    # Set the renderer for drawing operations
    [void] SetRenderer([object]$renderer) {
        $this._renderer = $renderer
    }

    hidden [void] EnsureValidBounds() {
        # Ensure _bounds has X,Y,Width,Height; otherwise, default to full buffer
        $hasProps = $false
        try {
            $null = $this._bounds.X; $null = $this._bounds.Y; $null = $this._bounds.Width; $null = $this._bounds.Height
            $hasProps = $true
        } catch { $hasProps = $false }

        if (-not $hasProps) {
            $w = 80; $h = 24
            try {
                if ($this._renderer) {
                    $buf = $this._renderer.GetDrawBuffer()
                    $w = $buf.GetWidth(); $h = $buf.GetHeight()
                } else {
                    $w = [Console]::WindowWidth; $h = [Console]::WindowHeight
                }
            } catch {}
            $this._bounds = [PSCustomObject]@{ X = 0; Y = 0; Width = $w; Height = $h }
            # Debug removed
        }
    }

    # Set data type and refresh
    [void] SetDataType([string]$dataType) {
        if ($this._state.DataType -ne $dataType) {
            $this._state.DataType = $dataType
            $this._state.Reset()
            $this.RefreshData()
        }
    }

    # Execute a query and update display
    [void] ExecuteQuery([string]$query) {
        if (-not $this._initialized) { return }

        $this._state.Query = $query
        Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Executing query: '$query'"

        try {
            if ($this.QueryExecutor) {
                # Use PMC's existing query system
                $result = & $this.QueryExecutor $query
                if ($result) {
                    $this._state.SetData($result)
                    $this.ApplyFilters()
                    $this.Render()

                    if ($this.OnQueryChanged) {
                        & $this.OnQueryChanged $query $result
                    }
                }
            } else {
                Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "No query executor configured"
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "Query execution failed: $_"
        }
    }

    # Refresh data from provider
    [void] RefreshData() {
        if (-not $this._initialized -or -not $this.DataProvider) { return }

        try {
            $newData = & $this.DataProvider $this._state.DataType
            if ($newData -and $this._state.HasDataChanged($newData)) {
                $this._state.SetData($newData)
                $this.ApplyFilters()
                $this.Render()

                if ($this.OnDataChanged) {
                    & $this.OnDataChanged $newData
                }

                Write-PmcDebug -Level 3 -Category 'UnifiedDataViewer' -Message "Data refreshed: $($newData.Count) items"
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "Data refresh failed: $_"
        }
    }

    # Apply current filters to data
    [void] ApplyFilters() {
        $this._state.FilteredData = $this._state.Data

        # Apply sorting if specified
        if ($this._state.SortColumn -and $this._state.FilteredData.Count -gt 0) {
            try {
                if ($this._state.SortDirection -eq "desc") {
                    $this._state.FilteredData = $this._state.FilteredData | Sort-Object $this._state.SortColumn -Descending
                } else {
                    $this._state.FilteredData = $this._state.FilteredData | Sort-Object $this._state.SortColumn
                }
            } catch {
                Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Sort failed on column $($this._state.SortColumn)"
            }
        }

        # Apply filters
        foreach ($filterKey in $this._state.Filters.Keys) {
            $filterValue = $this._state.Filters[$filterKey]
            try {
                $this._state.FilteredData = $this._state.FilteredData | Where-Object { $_.$filterKey -like "*$filterValue*" }
            } catch {
                Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Filter failed on $filterKey"
            }
        }

        # Ensure selected row is still valid
        if ($this._state.SelectedRow -ge $this._state.FilteredData.Count) {
            $this._state.SelectedRow = [Math]::Max(0, $this._state.FilteredData.Count - 1)
        }
    }

    # Navigation methods
    [void] MoveSelection([int]$delta) {
        $newRow = $this._state.SelectedRow + $delta
        $newRow = [Math]::Max(0, [Math]::Min($newRow, $this._state.FilteredData.Count - 1))

        if ($newRow -ne $this._state.SelectedRow) {
            $this._state.SelectedRow = $newRow
            $this.EnsureRowVisible()
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataRows($buf)

            if ($this.OnSelectionChanged) {
                $selectedItem = if ($this._state.FilteredData.Count -gt $this._state.SelectedRow) {
                    $this._state.FilteredData[$this._state.SelectedRow]
                } else { $null }
                & $this.OnSelectionChanged $this._state.SelectedRow $selectedItem
            }
        }
    }

    [void] EnsureRowVisible() {
        $visibleStart = $this._state.ScrollOffset
        $visibleEnd = $this._state.ScrollOffset + $this._state.VisibleRows - 1

        if ($this._state.SelectedRow -lt $visibleStart) {
            $this._state.ScrollOffset = $this._state.SelectedRow
        } elseif ($this._state.SelectedRow -gt $visibleEnd) {
            $this._state.ScrollOffset = $this._state.SelectedRow - $this._state.VisibleRows + 1
        }

        $this._state.ScrollOffset = [Math]::Max(0, $this._state.ScrollOffset)
    }

    # Rendering methods
    [void] Render() {
        if (-not $this._initialized -or -not $this._renderer) { return }

        $this.EnsureValidBounds()

        $buffer = $this._renderer.GetDrawBuffer()

        # Clear the viewer area
        $buffer.ClearRegion($this._bounds.X, $this._bounds.Y, $this._bounds.Width, $this._bounds.Height)

        # Calculate layout
        $this._state.VisibleRows = $this._bounds.Height - 2  # Leave space for header and border

        $this.RenderHeader($buffer)
        $this.RenderDataRows($buffer)
        $this.RenderStatus($buffer)
    }

    [void] RenderHeader([object]$buffer) {
        $this.EnsureValidBounds()
        # Get column definitions
        $columns = $this.GetColumnDefinitions()
        # Legacy debug removed
        if (-not $columns -or $columns.Count -eq 0) { return }

        $y = $this._bounds.Y
        $x = $this._bounds.X + 1

        # Calculate column widths — no fallbacks
        $availableWidth = $this._bounds.Width - 2
        $columnWidths = $this.CalculateColumnWidths($columns, $availableWidth)

        # Render column headers
        foreach ($column in $columns) {
            $name = $this.GetColName($column)
            if (-not $name) { continue }
            $width = $columnWidths[$name]
            if ($width -le 0) { continue }

            $headerText = $name
            if ($column -is [hashtable]) {
                if ($column.ContainsKey('DisplayName')) { $headerText = [string]$column['DisplayName'] }
            } elseif ($column.PSObject.Properties['DisplayName']) {
                $headerText = [string]$column.DisplayName
            }
            if ($headerText.Length -gt $width) {
                $headerText = $headerText.Substring(0, $width - 1) + "…"
            }

            $buffer.SetText($x, $y, $headerText.PadRight($width), $this._theme.HeaderFg, $this._theme.HeaderBg)
            $x += $width + 1
        }
    }

    [void] RenderDataRows([object]$buffer) {
        $this.EnsureValidBounds()
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

        $columns = $this.GetColumnDefinitions()
        if (-not $columns -or $columns.Count -eq 0) { return }

        $availableWidth = $this._bounds.Width - 2
        # Calculate column widths — no fallbacks
        $columnWidths = $this.CalculateColumnWidths($columns, $availableWidth)

        $startY = $this._bounds.Y + 1
        $visibleEnd = [Math]::Min($this._state.ScrollOffset + $this._state.VisibleRows, $this._state.FilteredData.Count)

        for ($i = $this._state.ScrollOffset; $i -lt $visibleEnd; $i++) {
            $rowY = $startY + ($i - $this._state.ScrollOffset)
            $item = $this._state.FilteredData[$i]
            $isSelected = ($i -eq $this._state.SelectedRow)

            $x = $this._bounds.X + 1

            foreach ($column in $columns) {
                $name = $this.GetColName($column)
                if (-not $name) { continue }
                $width = $columnWidths[$name]
                if ($width -le 0) { continue }

                $value = $this.GetColumnValue($item, @{ Name = $name })
                if ($value.Length -gt $width) {
                    $value = $value.Substring(0, $width - 1) + "…"
                }

                $fg = if ($isSelected) { $this._theme.SelectedFg } else { $this._theme.NormalFg }
                $bg = if ($isSelected) { $this._theme.SelectedBg } else { $this._theme.NormalBg }

                $buffer.SetText($x, $rowY, $value.PadRight($width), $fg, $bg)
                $x += $width + 1
            }
        }
    }

    [void] RenderStatus([object]$buffer) {
        $this.EnsureValidBounds()
        $statusY = $this._bounds.Y + $this._bounds.Height - 1
        $statusText = "$($this._state.FilteredData.Count) items"

        if ($this._state.Query) {
            $statusText += " | Query: $($this._state.Query)"
        }

        $buffer.SetText($this._bounds.X + 1, $statusY, $statusText, $this._theme.BorderFg, $this._theme.NormalBg)
    }

    # Column management
    [object] GetColumnDefinitions() {
        # Strict column provider — no fallbacks
        if (-not $this.ColumnProvider) { throw "No ColumnProvider configured" }
        $dt = $this.NormalizeDataType($this._state.DataType)
        $cols = @(& $this.ColumnProvider $dt)
        if (-not $cols -or $cols.Count -eq 0) { throw "Column provider returned no columns for '$dt'" }
        foreach ($c in $cols) {
            if (-not ($c -is [hashtable] -and $c.ContainsKey('Name') -and $c.ContainsKey('DisplayName') -and $c.ContainsKey('Width'))) {
                throw "Invalid column definition encountered (expect @{ Name; DisplayName; Width })"
            }
        }
        return $cols
    }

    [hashtable] CalculateColumnWidths([object]$columns, [int]$availableWidth) {
        $widths = @{}
        $total = 0
        foreach ($column in $columns) {
            if (-not $column) { throw "Null column encountered" }
            $name = $this.GetColName($column)
            $width = $this.GetColWidth($column)
            if (-not $name -or $width -le 0) { throw "Invalid column spec; each column must define Name and Width > 0" }
            $widths[$name] = [int]$width
            $total += [int]$width
        }
        $totalWithSeparators = $total + ([Math]::Max(0, @($columns).Count - 1))
        if ($totalWithSeparators -gt $availableWidth) { throw "Total column widths ($totalWithSeparators) exceed available width ($availableWidth)" }
        return $widths
    }

    [string] GetColumnValue([object]$item, [hashtable]$column) {
        if (-not $item) { return "" }

        try {
            $value = $null
            if ($column.Name -eq 'ToString') {
                $value = $item.ToString()
            } else {
                $value = $item.($column.Name)
            }

            if ($null -eq $value) { return "" }
            return [string]$value
        } catch {
            return ""
        }
    }

    # Public interface
    [PmcDataViewerState] GetState() { return $this._state }
    [object] GetSelectedItem() {
        if ($this._state.FilteredData.Count -gt $this._state.SelectedRow) {
            return $this._state.FilteredData[$this._state.SelectedRow]
        }
        return $null
    }

    [void] SetBounds([object]$bounds) {
        $this._bounds = $bounds
        $this.EnsureValidBounds()
        $this.Render()
    }

    [void] SetAutoRefresh([bool]$enabled) {
        $this._state.AutoRefresh = $enabled
    }

    [bool] ShouldRefresh() {
        if (-not $this._state.AutoRefresh) { return $false }
        $elapsed = ([datetime]::Now - $this._state.LastUpdate).TotalMilliseconds
        return $elapsed -ge $this._state.RefreshIntervalMs
    }
}

# Global instance
$Script:PmcUnifiedDataViewer = $null

function Initialize-PmcUnifiedDataViewer {
    param([object]$Bounds)

    if ($Script:PmcUnifiedDataViewer) {
        Write-Warning "PMC Unified Data Viewer already initialized"
        return
    }

    $Script:PmcUnifiedDataViewer = [PmcUnifiedDataViewer]::new($Bounds)

    # Set up integration with existing PMC systems (strict)
    $Script:PmcUnifiedDataViewer.QueryExecutor = {
        param([string]$query)
        if (-not (Get-Command Invoke-PmcEnhancedQuery -ErrorAction SilentlyContinue)) { throw "Invoke-PmcEnhancedQuery not found" }
        $res = Invoke-PmcEnhancedQuery -QueryString $query
        if ($res -and $res.Data) { return $res.Data }
        return @()
    }

    $Script:PmcUnifiedDataViewer.DataProvider = {
        param([string]$dataType)
        switch ($dataType) {
            'tasks'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { return Get-PmcTasksData } else { throw "Get-PmcTasksData not found" } }
            'projects' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { return Get-PmcProjectsData } else { throw "Get-PmcProjectsData not found" } }
            'timelog'  { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { return Get-PmcTimeLogsData } else { throw "Get-PmcTimeLogsData not found" } }
            'help'     {
                # Build help categories from module help content if available
                try {
                    $var = Get-Variable -Name PmcHelpContent -Scope Script -ErrorAction SilentlyContinue
                    if (-not $var) { $var = Get-Variable -Name PmcHelpContent -Scope Global -ErrorAction SilentlyContinue }
                    $hc = if ($var) { $var.Value } else { $null }
                    if ($hc) {
                        $rows = @()
                        foreach ($k in $hc.Keys) {
                            $cat = $hc[$k]
                            $rows += [pscustomobject]@{
                                Category     = [string]$k
                                CommandCount = @($cat.Items).Count
                                Description  = [string]$cat.Description
                            }
                        }
                        return $rows
                    }
                } catch { }
                return @()
            }
            default    { throw "Unknown dataType '$dataType'" }
        }
    }

    $Script:PmcUnifiedDataViewer.ColumnProvider = {
        param([string]$dataType)
        if (-not (Get-Command Get-PmcDefaultColumns -ErrorAction SilentlyContinue)) { throw "Get-PmcDefaultColumns not found" }
        # Normalize to singular like GetColumnDefinitions does
        $dt = switch ($dataType.ToLower()) { 'tasks' { 'task' } 'projects' { 'project' } default { $dataType.ToLower() } }
        $out = @((Get-PmcDefaultColumns -DataType $dt))
        return $out
    }

    Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Unified data viewer initialized"
}

function Get-PmcUnifiedDataViewer {
    return $Script:PmcUnifiedDataViewer
}

function Reset-PmcUnifiedDataViewer {
    $Script:PmcUnifiedDataViewer = $null
}

Export-ModuleMember -Function Initialize-PmcUnifiedDataViewer, Get-PmcUnifiedDataViewer, Reset-PmcUnifiedDataViewer
