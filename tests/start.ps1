#!/usr/bin/env pwsh
# Definitive launcher for PMC ConsoleUI (standalone)

Set-StrictMode -Version Latest

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Always load the modular loader which brings in Core + Handlers + Deps
. "$root/ConsoleUI-Modular.ps1"

# Start the Console UI
Start-PmcConsoleUI

