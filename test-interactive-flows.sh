#!/bin/bash
# Test interactive flows by piping input to PowerShell

echo "=== Testing Interactive Flows with Piped Input ==="
echo ""

# Test Project Wizard
echo "Testing Project Wizard..."
echo -e "TestProject\nTest Description\nactive\ntag1,tag2\n" | timeout 5 pwsh -NoProfile -Command "
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1
\$app = [PmcFakeTUIApp]::new()
\$app.Initialize()
\$app.currentView = 'toolswizard'
try {
    \$app.HandleProjectWizard()
    Write-Host '✓ Project Wizard completed' -ForegroundColor Green
} catch {
    Write-Host '✗ Project Wizard failed:' \$_.Exception.Message -ForegroundColor Red
}
\$app.Shutdown()
" 2>&1

echo ""

# Test Edit Project Form
echo "Testing Edit Project Form..."
echo -e "TestProject\ndescription\nNew description here\n" | timeout 5 pwsh -NoProfile -Command "
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1
\$app = [PmcFakeTUIApp]::new()
\$app.Initialize()
\$app.currentView = 'projectedit'
try {
    \$app.HandleEditProjectForm()
    Write-Host '✓ Edit Project Form completed' -ForegroundColor Green
} catch {
    Write-Host '✗ Edit Project Form failed:' \$_.Exception.Message -ForegroundColor Red
}
\$app.Shutdown()
" 2>&1

echo ""

# Test Project Info
echo "Testing Project Info..."
echo -e "TestProject\n" | timeout 5 pwsh -NoProfile -Command "
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1
\$app = [PmcFakeTUIApp]::new()
\$app.Initialize()
\$app.currentView = 'projectinfo'
try {
    \$app.HandleProjectInfoView()
    Write-Host '✓ Project Info completed' -ForegroundColor Green
} catch {
    Write-Host '✗ Project Info failed:' \$_.Exception.Message -ForegroundColor Red
}
\$app.Shutdown()
" 2>&1

echo ""

# Test Help Search
echo "Testing Help Search..."
echo -e "task\n" | timeout 5 pwsh -NoProfile -Command "
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1
\$app = [PmcFakeTUIApp]::new()
\$app.Initialize()
\$app.currentView = 'helpsearch'
try {
    \$app.HandleHelpSearch()
    Write-Host '✓ Help Search completed' -ForegroundColor Green
} catch {
    Write-Host '✗ Help Search failed:' \$_.Exception.Message -ForegroundColor Red
}
\$app.Shutdown()
" 2>&1

echo ""
echo "=== Interactive Flow Tests Complete ==="
