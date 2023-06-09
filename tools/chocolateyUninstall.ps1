
$ErrorActionPreference = 'SilentlyContinue'
$AllUsersModuleDir = Join-Path $env:ProgramFiles "/PowerShell/Modules/NupkgDownloader"

Remove-Module NupkgDownloader
Remove-Item $AllUsersModuleDir -Recurse
