# PMC Enhanced Data Validator - Comprehensive validation and sanitization
# Implements Phase 3 data validation improvements

Set-StrictMode -Version Latest

# Data validation rules and schemas
class PmcValidationRule {
    [string] $Name
    [string] $Type  # Required, Optional, Computed
    [scriptblock] $Validator
    [scriptblock] $Sanitizer
    [string] $ErrorMessage
    [hashtable] $Constraints = @{}

    PmcValidationRule([string]$name, [string]$type, [scriptblock]$validator) {
        $this.Name = $name
        $this.Type = $type
        $this.Validator = $validator
        $this.ErrorMessage = "Validation failed for field: $name"
    }

    [bool] Validate([object]$value) {
        try {
            return & $this.Validator $value
        } catch {
            Write-PmcDebug -Level 1 -Category 'Validation' -Message "Validation rule error for $($this.Name): $_"
            return $false
        }
    }

    [object] Sanitize([object]$value) {
        if ($this.Sanitizer) {
            try {
                return & $this.Sanitizer $value
            } catch {
                Write-PmcDebug -Level 1 -Category 'Validation' -Message "Sanitization failed for $($this.Name): $_"
                return $value
            }
        }
        return $value
    }
}

# Domain-specific validation schemas
class PmcDomainValidator {
    [string] $Domain
    [hashtable] $Rules = @{}
    [hashtable] $CrossFieldValidators = @{}

    PmcDomainValidator([string]$domain) {
        $this.Domain = $domain
        $this.InitializeRules()
    }

    [void] InitializeRules() {
        switch ($this.Domain) {
            'task' { $this.InitializeTaskRules() }
            'project' { $this.InitializeProjectRules() }
            'timelog' { $this.InitializeTimelogRules() }
        }
    }

    [void] InitializeTaskRules() {
        # Task ID validation
        $this.Rules['id'] = [PmcValidationRule]::new('id', 'Optional', {
            param($value)
            if ($null -eq $value) { return $true }
            return ($value -is [int] -and $value -gt 0) -or ($value -match '^\d+$' -and [int]$value -gt 0)
        })
        $this.Rules['id'].Sanitizer = { param($value) if ($value -match '^\d+$') { return [int]$value } else { return $value } }
        $this.Rules['id'].ErrorMessage = "Task ID must be a positive integer"

        # Task text validation
        $this.Rules['text'] = [PmcValidationRule]::new('text', 'Required', {
            param($value)
            return $value -and $value.ToString().Trim().Length -gt 0 -and $value.ToString().Length -le 500
        })
        $this.Rules['text'].Sanitizer = { param($value) return $value.ToString().Trim() }
        $this.Rules['text'].ErrorMessage = "Task text is required and must be 1-500 characters"

        # Project validation
        $this.Rules['project'] = [PmcValidationRule]::new('project', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().Trim()
            return $str.Length -le 100 -and $str -notmatch '[<>|"*?\\/:]+' -and $str -notmatch '^\s*$'
        })
        $this.Rules['project'].Sanitizer = { param($value) if ($value) { return $value.ToString().Trim() } else { return $null } }
        $this.Rules['project'].ErrorMessage = "Project name must be valid and under 100 characters"

        # Due date validation
        $this.Rules['due'] = [PmcValidationRule]::new('due', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString()
            try {
                $parsed = [datetime]::Parse($str)
                return $parsed -ge [datetime]::Today.AddDays(-1)  # Allow yesterday and future
            } catch {
                return $false
            }
        })
        $this.Rules['due'].Sanitizer = {
            param($value)
            if ($value) {
                try {
                    return [datetime]::Parse($value.ToString()).ToString('yyyy-MM-dd')
                } catch {
                    return $null
                }
            }
            return $null
        }
        $this.Rules['due'].ErrorMessage = "Due date must be a valid date (yesterday or later)"

        # Priority validation
        $this.Rules['priority'] = [PmcValidationRule]::new('priority', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().ToLower()
            return $str -in @('p1', 'p2', 'p3', 'high', 'medium', 'low', '1', '2', '3')
        })
        $this.Rules['priority'].Sanitizer = {
            param($value)
            if ($value) {
                $str = $value.ToString().ToLower()
                switch ($str) {
                    { $_ -in @('p1', 'high', '1') } { return 'p1' }
                    { $_ -in @('p2', 'medium', '2') } { return 'p2' }
                    { $_ -in @('p3', 'low', '3') } { return 'p3' }
                    default { return 'p2' }  # Default to medium
                }
            }
            return 'p2'
        }
        $this.Rules['priority'].ErrorMessage = "Priority must be p1/p2/p3, high/medium/low, or 1/2/3"

        # Tags validation
        $this.Rules['tags'] = [PmcValidationRule]::new('tags', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $tags = if ($value -is [array]) { $value } else { @($value) }
            foreach ($tag in $tags) {
                $str = $tag.ToString().Trim()
                if ($str.Length -gt 50 -or $str -match '[<>|"*?\\/:]+' -or $str -match '^\s*$') {
                    return $false
                }
            }
            return $true
        })
        $this.Rules['tags'].Sanitizer = {
            param($value)
            if ($value) {
                $tags = if ($value -is [array]) { $value } else { @($value) }
                return $tags | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }
            }
            return @()
        }
        $this.Rules['tags'].ErrorMessage = "Tags must be valid strings under 50 characters each"
    }

    [void] InitializeProjectRules() {
        # Project name validation
        $this.Rules['name'] = [PmcValidationRule]::new('name', 'Required', {
            param($value)
            if (-not $value) { return $false }
            $str = $value.ToString().Trim()
            return $str.Length -gt 0 -and $str.Length -le 100 -and $str -notmatch '[<>|"*?\\/:]+' -and $str -notmatch '^\s*$'
        })
        $this.Rules['name'].Sanitizer = { param($value) return $value.ToString().Trim() }
        $this.Rules['name'].ErrorMessage = "Project name is required and must be 1-100 valid characters"

        # Description validation
        $this.Rules['description'] = [PmcValidationRule]::new('description', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            return $value.ToString().Length -le 1000
        })
        $this.Rules['description'].Sanitizer = { param($value) if ($value) { return $value.ToString().Trim() } else { return $null } }
        $this.Rules['description'].ErrorMessage = "Description must be under 1000 characters"

        # Status validation
        $this.Rules['status'] = [PmcValidationRule]::new('status', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().ToLower()
            return $str -in @('active', 'inactive', 'archived', 'completed')
        })
        $this.Rules['status'].Sanitizer = {
            param($value)
            if ($value) {
                return $value.ToString().ToLower()
            }
            return 'active'
        }
        $this.Rules['status'].ErrorMessage = "Status must be active, inactive, archived, or completed"
    }

    [void] InitializeTimelogRules() {
        # Task reference validation
        $this.Rules['task'] = [PmcValidationRule]::new('task', 'Required', {
            param($value)
            return ($value -is [int] -and $value -gt 0) -or ($value -match '^\d+$' -and [int]$value -gt 0)
        })
        $this.Rules['task'].Sanitizer = { param($value) if ($value -match '^\d+$') { return [int]$value } else { return $value } }
        $this.Rules['task'].ErrorMessage = "Task reference must be a positive integer"

        # Duration validation
        $this.Rules['duration'] = [PmcValidationRule]::new('duration', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            # Accept formats like "1h", "30m", "1h30m", or decimal hours
            $str = $value.ToString()
            return $str -match '^(\d+h)?(\d+m)?$' -or $str -match '^\d+(\.\d+)?$'
        })
        $this.Rules['duration'].Sanitizer = {
            param($value)
            if ($value) {
                $str = $value.ToString()
                # Convert to decimal hours
                if ($str -match '^(\d+)h(\d+)m$') {
                    return [decimal]$matches[1] + ([decimal]$matches[2] / 60)
                } elseif ($str -match '^(\d+)h$') {
                    return [decimal]$matches[1]
                } elseif ($str -match '^(\d+)m$') {
                    return [decimal]$matches[1] / 60
                } elseif ($str -match '^\d+(\.\d+)?$') {
                    return [decimal]$str
                }
            }
            return $null
        }
        $this.Rules['duration'].ErrorMessage = "Duration must be in format like '1h30m' or decimal hours"
    }

    [hashtable] ValidateData([hashtable]$data) {
        $result = @{
            IsValid = $true
            Errors = @()
            Warnings = @()
            SanitizedData = @{}
        }

        # Validate each field
        foreach ($field in $data.Keys) {
            $value = $data[$field]

            if ($this.Rules.ContainsKey($field)) {
                $rule = $this.Rules[$field]

                # Sanitize first
                $sanitized = $rule.Sanitize($value)
                $result.SanitizedData[$field] = $sanitized

                # Then validate
                if (-not $rule.Validate($sanitized)) {
                    $result.IsValid = $false
                    $result.Errors += $rule.ErrorMessage
                }
            } else {
                # Unknown field - add warning but allow
                $result.Warnings += "Unknown field: $field"
                $result.SanitizedData[$field] = $value
            }
        }

        # Check required fields
        $requiredFields = $this.Rules.Values | Where-Object { $_.Type -eq 'Required' } | ForEach-Object { $_.Name }
        foreach ($required in $requiredFields) {
            if (-not $data.ContainsKey($required) -or -not $data[$required]) {
                $result.IsValid = $false
                $result.Errors += "Required field missing: $required"
            }
        }

        # Run cross-field validation
        foreach ($validator in $this.CrossFieldValidators.Values) {
            $crossResult = & $validator $result.SanitizedData
            if (-not $crossResult.IsValid) {
                $result.IsValid = $false
                $result.Errors += $crossResult.Errors
            }
        }

        return $result
    }
}

# Enhanced validation engine with caching and performance monitoring
class PmcEnhancedDataValidator {
    hidden [hashtable] $_domainValidators = @{}
    hidden [hashtable] $_validationStats = @{
        TotalValidations = 0
        SuccessfulValidations = 0
        FailedValidations = 0
        TotalDuration = 0
    }

    PmcEnhancedDataValidator() {
        $this.InitializeDomainValidators()
    }

    [void] InitializeDomainValidators() {
        $this._domainValidators['task'] = [PmcDomainValidator]::new('task')
        $this._domainValidators['project'] = [PmcDomainValidator]::new('project')
        $this._domainValidators['timelog'] = [PmcDomainValidator]::new('timelog')
    }

    [hashtable] ValidateData([string]$domain, [hashtable]$data) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $this._validationStats.TotalValidations++

        try {
            if (-not $this._domainValidators.ContainsKey($domain)) {
                return @{
                    IsValid = $false
                    Errors = @("Unknown domain: $domain")
                    Warnings = @()
                    SanitizedData = $data
                }
            }

            $validator = $this._domainValidators[$domain]
            $result = $validator.ValidateData($data)

            if ($result.IsValid) {
                $this._validationStats.SuccessfulValidations++
            } else {
                $this._validationStats.FailedValidations++
            }

            Write-PmcDebug -Level 3 -Category 'EnhancedValidator' -Message "Data validation completed" -Data @{
                Domain = $domain
                IsValid = $result.IsValid
                ErrorCount = $result.Errors.Count
                WarningCount = $result.Warnings.Count
                Duration = $stopwatch.ElapsedMilliseconds
            }

            return $result

        } catch {
            $this._validationStats.FailedValidations++
            Write-PmcDebug -Level 1 -Category 'EnhancedValidator' -Message "Validation error: $_" -Data @{ Domain = $domain }

            return @{
                IsValid = $false
                Errors = @("Validation system error: $_")
                Warnings = @()
                SanitizedData = $data
            }

        } finally {
            $stopwatch.Stop()
            $this._validationStats.TotalDuration += $stopwatch.ElapsedMilliseconds
        }
    }

    [hashtable] GetValidationStats() {
        $avgDuration = if ($this._validationStats.TotalValidations -gt 0) {
            [Math]::Round($this._validationStats.TotalDuration / $this._validationStats.TotalValidations, 2)
        } else { 0 }

        $successRate = if ($this._validationStats.TotalValidations -gt 0) {
            [Math]::Round(($this._validationStats.SuccessfulValidations * 100.0) / $this._validationStats.TotalValidations, 2)
        } else { 0 }

        return @{
            TotalValidations = $this._validationStats.TotalValidations
            SuccessfulValidations = $this._validationStats.SuccessfulValidations
            FailedValidations = $this._validationStats.FailedValidations
            SuccessRate = $successRate
            AverageDuration = $avgDuration
            TotalDuration = $this._validationStats.TotalDuration
        }
    }

    [void] ResetStats() {
        $this._validationStats = @{
            TotalValidations = 0
            SuccessfulValidations = 0
            FailedValidations = 0
            TotalDuration = 0
        }
    }
}

# Global instance
$Script:PmcEnhancedDataValidator = $null

function Initialize-PmcEnhancedDataValidator {
    if ($Script:PmcEnhancedDataValidator) {
        Write-Warning "PMC Enhanced Data Validator already initialized"
        return
    }

    $Script:PmcEnhancedDataValidator = [PmcEnhancedDataValidator]::new()
    Write-PmcDebug -Level 2 -Category 'EnhancedValidator' -Message "Enhanced data validator initialized"
}

function Test-PmcEnhancedData {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [hashtable]$Data
    )

    if (-not $Script:PmcEnhancedDataValidator) {
        Initialize-PmcEnhancedDataValidator
    }

    return $Script:PmcEnhancedDataValidator.ValidateData($Domain, $Data)
}

function Get-PmcDataValidationStats {
    if (-not $Script:PmcEnhancedDataValidator) {
        Write-Host "Enhanced data validator not initialized"
        return
    }

    $stats = $Script:PmcEnhancedDataValidator.GetValidationStats()

    Write-Host "PMC Data Validation Statistics" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "Total Validations: $($stats.TotalValidations)"
    Write-Host "Successful: $($stats.SuccessfulValidations)"
    Write-Host "Failed: $($stats.FailedValidations)"
    Write-Host "Success Rate: $($stats.SuccessRate)%"
    Write-Host "Average Duration: $($stats.AverageDuration) ms"
    Write-Host "Total Duration: $($stats.TotalDuration) ms"
}

Export-ModuleMember -Function Initialize-PmcEnhancedDataValidator, Test-PmcEnhancedData, Get-PmcDataValidationStats