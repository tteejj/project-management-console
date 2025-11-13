# ExcelMappingService.ps1 - Service for managing Excel import profiles and mappings
#
# Provides CRUD operations for Excel mapping profiles
# Each profile contains field mappings (Excel cell -> Project property)
#
# Usage:
#   $service = [ExcelMappingService]::GetInstance()
#   $profile = $service.CreateProfile("My Profile", "Description")
#   $service.AddMapping($profileId, @{ display_name="Name"; excel_cell="A1"; project_property="name" })

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

class ExcelMappingService {
    # === Configuration ===
    hidden [string]$_profilesFile
    hidden [string]$_activeProfileId = $null

    # === In-memory cache ===
    hidden [hashtable]$_profilesCache = @{}
    hidden [datetime]$_cacheLoadTime = [datetime]::MinValue

    # === Event Callbacks ===
    [scriptblock]$OnProfileAdded = {}
    [scriptblock]$OnProfileUpdated = {}
    [scriptblock]$OnProfileDeleted = {}
    [scriptblock]$OnProfilesChanged = {}

    # === Constructor ===
    ExcelMappingService() {
        # Determine profiles file location relative to PMC root
        $pmcRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        $this._profilesFile = Join-Path $pmcRoot "excel_profiles.json"

        # Load profiles
        $this.LoadProfiles()
    }

    # === Profile Management ===
    hidden [void] LoadProfiles() {
        if (Test-Path $this._profilesFile) {
            try {
                $json = Get-Content $this._profilesFile -Raw | ConvertFrom-Json

                $this._activeProfileId = $json.active_profile_id

                foreach ($profile in $json.profiles) {
                    $mappings = @()
                    # Check if mappings property exists and is not null - JSON deserialization can omit empty arrays
                    if ($profile.PSObject.Properties['mappings'] -and $null -ne $profile.mappings) {
                        foreach ($mapping in $profile.mappings) {
                            # Force type conversion for boolean and int values from JSON
                            $mappings += @{
                                id = $mapping.id
                                display_name = $mapping.display_name
                                excel_cell = $mapping.excel_cell
                                project_property = $mapping.project_property
                                required = [bool]$mapping.required
                                data_type = $mapping.data_type
                                include_in_export = [bool]$mapping.include_in_export
                                sort_order = [int]$mapping.sort_order
                            }
                        }
                    }

                    # Parse datetime with error handling
                    try {
                        $created = [datetime]::Parse($profile.created)
                    } catch {
                        Write-PmcTuiLog "Failed to parse created date for profile $($profile.id), using current time: $_" "WARN"
                        $created = [datetime]::Now
                    }

                    try {
                        $modified = [datetime]::Parse($profile.modified)
                    } catch {
                        Write-PmcTuiLog "Failed to parse modified date for profile $($profile.id), using current time: $_" "WARN"
                        $modified = [datetime]::Now
                    }

                    $this._profilesCache[$profile.id] = @{
                        id = $profile.id
                        name = $profile.name
                        description = $profile.description
                        start_cell = $profile.start_cell
                        mappings = $mappings
                        created = $created
                        modified = $modified
                    }
                }
                $this._cacheLoadTime = [datetime]::Now
            } catch {
                Write-PmcTuiLog "Failed to load Excel profiles: $_" "ERROR"
                $this._profilesCache = @{}
            }
        }
    }

    hidden [void] SaveProfiles() {
        try {
            $profiles = $this._profilesCache.Values | ForEach-Object {
                $mappings = @()
                foreach ($mapping in $_.mappings) {
                    $mappings += @{
                        id = $mapping.id
                        display_name = $mapping.display_name
                        excel_cell = $mapping.excel_cell
                        project_property = $mapping.project_property
                        required = $mapping.required
                        data_type = $mapping.data_type
                        include_in_export = $mapping.include_in_export
                        sort_order = $mapping.sort_order
                    }
                }

                @{
                    id = $_.id
                    name = $_.name
                    description = $_.description
                    start_cell = $_.start_cell
                    mappings = $mappings
                    created = $_.created.ToString("o")
                    modified = $_.modified.ToString("o")
                }
            }

            $metadata = @{
                schema_version = 1
                active_profile_id = $this._activeProfileId
                profiles = $profiles
            }

            # Atomic save
            $tempFile = "$($this._profilesFile).tmp"
            $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

            if (Test-Path $this._profilesFile) {
                Copy-Item $this._profilesFile "$($this._profilesFile).bak" -Force
            }

            Move-Item -Path $tempFile -Destination $this._profilesFile -Force

        } catch {
            Write-PmcTuiLog "Failed to save Excel profiles: $_" "ERROR"
            Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
            throw "Failed to save profiles: $($_.Exception.Message)"
        }
    }

    # === Profile CRUD Operations ===

    [array] GetAllProfiles() {
        return @($this._profilesCache.Values | Sort-Object -Property name)
    }

    [object] GetProfile([string]$profileId) {
        if ($this._profilesCache.ContainsKey($profileId)) {
            return $this._profilesCache[$profileId]
        }
        return $null
    }

    [object] GetActiveProfile() {
        if ($null -ne $this._activeProfileId -and $this._profilesCache.ContainsKey($this._activeProfileId)) {
            return $this._profilesCache[$this._activeProfileId]
        }
        return $null
    }

    [void] SetActiveProfile([string]$profileId) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $this._activeProfileId = $profileId
        $this.SaveProfiles()

        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }
    }

    [object] CreateProfile([string]$name, [string]$description) {
        return $this.CreateProfile($name, $description, "A1")
    }

    [object] CreateProfile([string]$name, [string]$description, [string]$startCell) {
        # Check for duplicate name
        $existing = $this._profilesCache.Values | Where-Object { $_['name'] -eq $name }
        if ($existing) {
            throw "Profile with name '$name' already exists"
        }

        $profileId = [guid]::NewGuid().ToString()

        $profile = @{
            id = $profileId
            name = $name
            description = $description
            start_cell = $startCell
            mappings = @()
            created = [datetime]::Now
            modified = [datetime]::Now
        }

        $this._profilesCache[$profileId] = $profile

        # Set as active if this is the first profile
        if ($this._profilesCache.Count -eq 1) {
            $this._activeProfileId = $profileId
        }

        $this.SaveProfiles()

        if ($this.OnProfileAdded) {
            & $this.OnProfileAdded $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }

        return $profile
    }

    [void] UpdateProfile([string]$profileId, [hashtable]$changes) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $profile = $this._profilesCache[$profileId]

        # Check for duplicate name if name is being changed
        if ($changes.ContainsKey('name') -and $changes.name -ne $profile['name']) {
            $existing = $this._profilesCache.Values | Where-Object { $_['name'] -eq $changes.name -and $_['id'] -ne $profileId }
            if ($existing) {
                throw "Profile with name '$($changes.name)' already exists"
            }
        }

        if ($changes.ContainsKey('name')) { $profile.name = $changes.name }
        if ($changes.ContainsKey('description')) { $profile.description = $changes.description }
        if ($changes.ContainsKey('start_cell')) { $profile.start_cell = $changes.start_cell }

        $profile.modified = [datetime]::Now

        $this.SaveProfiles()

        if ($this.OnProfileUpdated) {
            & $this.OnProfileUpdated $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }
    }

    [void] DeleteProfile([string]$profileId) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $profile = $this._profilesCache[$profileId]
        $this._profilesCache.Remove($profileId)

        # Clear active profile if it was deleted
        if ($this._activeProfileId -eq $profileId) {
            # Set to first remaining profile, or null
            $remaining = $this._profilesCache.Keys
            $this._activeProfileId = if ($remaining.Count -gt 0) { $remaining[0] } else { $null }
        }

        $this.SaveProfiles()

        if ($this.OnProfileDeleted) {
            & $this.OnProfileDeleted $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }
    }

    # === Mapping CRUD Operations ===

    [object] AddMapping([string]$profileId, [hashtable]$mappingData) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $profile = $this._profilesCache[$profileId]
        $mappingId = [guid]::NewGuid().ToString()

        # Determine sort order
        $sortOrder = if ($mappingData.ContainsKey('sort_order')) {
            $mappingData.sort_order
        } else {
            $profile.mappings.Count + 1
        }

        $mapping = @{
            id = $mappingId
            display_name = $mappingData.display_name
            excel_cell = $mappingData.excel_cell
            project_property = $mappingData.project_property
            required = if ($mappingData.ContainsKey('required')) { $mappingData.required } else { $false }
            data_type = if ($mappingData.ContainsKey('data_type')) { $mappingData.data_type } else { "string" }
            include_in_export = if ($mappingData.ContainsKey('include_in_export')) { $mappingData.include_in_export } else { $true }
            sort_order = $sortOrder
        }

        $profile.mappings += $mapping
        $profile.modified = [datetime]::Now

        $this.SaveProfiles()

        if ($this.OnProfileUpdated) {
            & $this.OnProfileUpdated $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }

        return $mapping
    }

    [void] UpdateMapping([string]$profileId, [string]$mappingId, [hashtable]$changes) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $profile = $this._profilesCache[$profileId]
        $mapping = $profile.mappings | Where-Object { $_.id -eq $mappingId } | Select-Object -First 1

        if (-not $mapping) {
            throw "Mapping not found: $mappingId"
        }

        if ($changes.ContainsKey('display_name')) { $mapping.display_name = $changes.display_name }
        if ($changes.ContainsKey('excel_cell')) { $mapping.excel_cell = $changes.excel_cell }
        if ($changes.ContainsKey('project_property')) { $mapping.project_property = $changes.project_property }
        if ($changes.ContainsKey('required')) { $mapping.required = $changes.required }
        if ($changes.ContainsKey('data_type')) { $mapping.data_type = $changes.data_type }
        if ($changes.ContainsKey('include_in_export')) { $mapping.include_in_export = $changes.include_in_export }
        if ($changes.ContainsKey('sort_order')) { $mapping.sort_order = $changes.sort_order }

        $profile.modified = [datetime]::Now

        $this.SaveProfiles()

        if ($this.OnProfileUpdated) {
            & $this.OnProfileUpdated $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }
    }

    [void] DeleteMapping([string]$profileId, [string]$mappingId) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            throw "Profile not found: $profileId"
        }

        $profile = $this._profilesCache[$profileId]
        # @() wrapper ensures array type even with 0 or 1 results
        $profile.mappings = @($profile.mappings | Where-Object { $_.id -ne $mappingId })
        $profile.modified = [datetime]::Now

        $this.SaveProfiles()

        if ($this.OnProfileUpdated) {
            & $this.OnProfileUpdated $profile
        }
        if ($this.OnProfilesChanged) {
            & $this.OnProfilesChanged
        }
    }

    [array] GetMappings([string]$profileId) {
        if (-not $this._profilesCache.ContainsKey($profileId)) {
            return @()
        }

        $profile = $this._profilesCache[$profileId]
        return @($profile.mappings | Sort-Object -Property sort_order)
    }
}
