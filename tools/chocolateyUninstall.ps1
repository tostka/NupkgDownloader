
$ErrorActionPreference = 'SilentlyContinue'
$AllUsersModuleDir = Join-Path $env:ProgramFiles "/PowerShell/Modules/VerintPM"

Remove-Module VerintPM
Remove-Item $AllUsersModuleDir -Recurse
