
$ErrorActionPreference = 'SilentlyContinue'
$_PSModulePath = $($env:PSModulePath -split ";")[1]
$AllUsersModuleDir = Join-Path $_PSModulePath "NupkgDownloader"

Remove-Module NupkgDownloader
Remove-Item $AllUsersModuleDir -Recurse
