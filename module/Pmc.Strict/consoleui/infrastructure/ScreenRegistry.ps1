# ScreenRegistry.ps1 - Central Registry for Screen Navigation
#
# SINGLETON pattern - provides centralized screen registration and creation with:
# - Register screens by name with type and category
# - Create screen instances by name (with dependency injection)
# - List all registered screens
# - Filter screens by category (Tasks, Projects, Reports, Settings)
# - Validate screen registration
# - Thread-safe operations
#
# Usage:
#   [ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks')
#   [ScreenRegistry]::Register('ProjectList', [ProjectListScreen], 'Projects')
#
#   $screen = [ScreenRegistry]::Create('TaskList')
#   $allScreens = [ScreenRegistry]::GetAllScreens()
#   $taskScreens = [ScreenRegistry]::GetByCategory('Tasks')

using namespace System
using namespace System.Collections.Generic
using namespace System.Threading

<#
.SYNOPSIS
Screen registration information

.DESCRIPTION
Contains metadata about a registered screen
#>
class ScreenRegistration {
    [string]$Name
    [type]$Type
    [string]$Category
    [string]$Description
    [hashtable]$Metadata

    ScreenRegistration([string]$name, [type]$type, [string]$category, [string]$description) {
        $this.Name = $name
        $this.Type = $type
        $this.Category = $category
        $this.Description = $description
        $this.Metadata = @{}
    }
}

<#
.SYNOPSIS
Central registry for screen types and navigation

.DESCRIPTION
ScreenRegistry provides:
- Singleton instance for centralized screen management
- Screen registration with type and category
- Screen creation with dependency injection support
- Category-based filtering
- Screen listing and discovery
- Validation and error handling
- Thread-safe operations

.EXAMPLE
[ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks', 'View and manage tasks')
$screen = [ScreenRegistry]::Create('TaskList')
$allTaskScreens = [ScreenRegistry]::GetByCategory('Tasks')
#>
class ScreenRegistry {
    # === Singleton Instance ===
    static hidden [ScreenRegistry]$_instance = $null
    static hidden [object]$_instanceLock = [object]::new()

    # === Screen Storage ===
    hidden [Dictionary[string, ScreenRegistration]]$_screens = [Dictionary[string, ScreenRegistration]]::new()

    # === Categories ===
    hidden [List[string]]$_categories = [List[string]]::new(@(
        'Tasks',
        'Projects',
        'Reports',
        'Settings',
        'Other'
    ))

    # === Thread Safety ===
    hidden [object]$_registryLock = [object]::new()

    # === Statistics ===
    [int]$ScreenCount = 0
    [string]$LastError = ""

    # === Constructor (Private) ===
    ScreenRegistry() {
        # Private constructor for singleton
    }

    # === Singleton Pattern ===

    <#
    .SYNOPSIS
    Get the singleton instance of ScreenRegistry

    .OUTPUTS
    ScreenRegistry singleton instance
    #>
    static [ScreenRegistry] GetInstance() {
        if ($null -eq [ScreenRegistry]::_instance) {
            [Monitor]::Enter([ScreenRegistry]::_instanceLock)
            try {
                if ($null -eq [ScreenRegistry]::_instance) {
                    [ScreenRegistry]::_instance = [ScreenRegistry]::new()
                }
            }
            finally {
                [Monitor]::Exit([ScreenRegistry]::_instanceLock)
            }
        }

        return [ScreenRegistry]::_instance
    }

    <#
    .SYNOPSIS
    Reset the singleton instance (for testing)
    #>
    static [void] ResetInstance() {
        [Monitor]::Enter([ScreenRegistry]::_instanceLock)
        try {
            [ScreenRegistry]::_instance = $null
        }
        finally {
            [Monitor]::Exit([ScreenRegistry]::_instanceLock)
        }
    }

    # === Registration Methods ===

    <#
    .SYNOPSIS
    Register a screen type

    .PARAMETER name
    Screen name (unique identifier)

    .PARAMETER type
    Screen type (must be a PowerShell class type)

    .PARAMETER category
    Screen category (Tasks, Projects, Reports, Settings, Other)

    .PARAMETER description
    Optional description

    .OUTPUTS
    True if registration succeeded, False otherwise
    #>
    static [bool] Register([string]$name, [type]$type, [string]$category, [string]$description = "") {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            # Validate name
            if ([string]::IsNullOrWhiteSpace($name)) {
                $instance.LastError = "Screen name cannot be empty"
                return $false
            }

            # Check for duplicate
            if ($instance._screens.ContainsKey($name)) {
                $instance.LastError = "Screen '$name' is already registered"
                return $false
            }

            # Validate type
            if ($null -eq $type) {
                $instance.LastError = "Screen type cannot be null"
                return $false
            }

            # Validate category
            if (-not $instance._categories.Contains($category)) {
                $instance.LastError = "Invalid category '$category'. Valid: $($instance._categories -join ', ')"
                return $false
            }

            # Create registration
            $registration = [ScreenRegistration]::new($name, $type, $category, $description)
            $instance._screens[$name] = $registration
            $instance.ScreenCount = $instance._screens.Count
            $instance.LastError = ""

            return $true
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    <#
    .SYNOPSIS
    Unregister a screen type

    .PARAMETER name
    Screen name

    .OUTPUTS
    True if unregistration succeeded, False otherwise
    #>
    static [bool] Unregister([string]$name) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            if (-not $instance._screens.ContainsKey($name)) {
                $instance.LastError = "Screen '$name' is not registered"
                return $false
            }

            $instance._screens.Remove($name)
            $instance.ScreenCount = $instance._screens.Count
            $instance.LastError = ""

            return $true
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    # === Screen Creation ===

    <#
    .SYNOPSIS
    Create a screen instance by name

    .PARAMETER name
    Screen name

    .PARAMETER args
    Optional constructor arguments

    .OUTPUTS
    Screen instance or $null if creation failed
    #>
    static [object] Create([string]$name, [object[]]$args = @()) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            if (-not $instance._screens.ContainsKey($name)) {
                $instance.LastError = "Screen '$name' is not registered"
                return $null
            }

            $registration = $instance._screens[$name]

            try {
                # Create screen instance
                if ($args.Count -gt 0) {
                    $screen = $registration.Type::new($args)
                }
                else {
                    $screen = $registration.Type::new()
                }

                $instance.LastError = ""
                return $screen
            }
            catch {
                $instance.LastError = "Failed to create screen '$name': $($_.Exception.Message)"
                return $null
            }
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    # === Query Methods ===

    <#
    .SYNOPSIS
    Get all registered screens

    .OUTPUTS
    Array of ScreenRegistration objects
    #>
    static [array] GetAllScreens() {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            return $instance._screens.Values.ToArray()
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    <#
    .SYNOPSIS
    Get screens by category

    .PARAMETER category
    Category name

    .OUTPUTS
    Array of ScreenRegistration objects
    #>
    static [array] GetByCategory([string]$category) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            $screens = $instance._screens.Values | Where-Object { $_.Category -eq $category }
            return if ($screens) { @($screens) } else { @() }
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    <#
    .SYNOPSIS
    Get screen registration by name

    .PARAMETER name
    Screen name

    .OUTPUTS
    ScreenRegistration object or $null if not found
    #>
    static [ScreenRegistration] GetRegistration([string]$name) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            if ($instance._screens.ContainsKey($name)) {
                return $instance._screens[$name]
            }
            return $null
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    <#
    .SYNOPSIS
    Check if a screen is registered

    .PARAMETER name
    Screen name

    .OUTPUTS
    True if registered, False otherwise
    #>
    static [bool] IsRegistered([string]$name) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            return $instance._screens.ContainsKey($name)
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    # === Category Methods ===

    <#
    .SYNOPSIS
    Get all available categories

    .OUTPUTS
    Array of category names
    #>
    static [array] GetCategories() {
        $instance = [ScreenRegistry]::GetInstance()
        return $instance._categories.ToArray()
    }

    <#
    .SYNOPSIS
    Add a custom category

    .PARAMETER category
    Category name

    .OUTPUTS
    True if added, False if already exists
    #>
    static [bool] AddCategory([string]$category) {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            if ($instance._categories.Contains($category)) {
                return $false
            }

            $instance._categories.Add($category)
            return $true
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }

    # === Statistics ===

    <#
    .SYNOPSIS
    Get registry statistics

    .OUTPUTS
    Hashtable with statistics
    #>
    static [hashtable] GetStatistics() {
        $instance = [ScreenRegistry]::GetInstance()

        [Monitor]::Enter($instance._registryLock)
        try {
            $stats = @{
                totalScreens = $instance._screens.Count
                categories = @{}
                lastError = $instance.LastError
            }

            foreach ($category in $instance._categories) {
                $count = ($instance._screens.Values | Where-Object { $_.Category -eq $category }).Count
                $stats.categories[$category] = $count
            }

            return $stats
        }
        finally {
            [Monitor]::Exit($instance._registryLock)
        }
    }
}
