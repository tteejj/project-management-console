Import-Module ./module/Pmc.Strict/Pmc.Strict.psd1 -Force
. ./module/Pmc.Strict/FakeTUI/FakeTUI-Modular.ps1
$app = [PmcFakeTUIApp]::new()
$app.Initialize()
"INIT_OK"
