#!/usr/bin/env pwsh
# PMC Launcher - runs PMC in proper interactive context like t2.ps1

param(
    [switch]$CLI,
    [switch]$Debug1,
    [switch]$Debug2,
    [switch]$Debug3,
    [string]$Config = $null,
    [string]$SecurityLevel = 'balanced',
    [switch]$Help
)

# Get the directory this script is in
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Change to PMC directory
Set-Location $ScriptDir

# Build argument hashtable for pmc.ps1 (secure parameter passing)
$params = @{}
if ($CLI) { $params['CLI'] = $true }
if ($Debug1) { $params['Debug1'] = $true }
if ($Debug2) { $params['Debug2'] = $true }
if ($Debug3) { $params['Debug3'] = $true }
if ($Config) { $params['Config'] = $Config }
if ($SecurityLevel -ne 'balanced') { $params['SecurityLevel'] = $SecurityLevel }
if ($Help) { $params['Help'] = $true }

# Execute PMC via dot-sourcing with parameter splatting (secure)
# PMC will launch FakeTUI by default unless -CLI is specified
. ./pmc.ps1 @params
