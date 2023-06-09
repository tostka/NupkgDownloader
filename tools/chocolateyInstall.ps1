
$ErrorActionPreference = 'Stop';
$PackageDir = Split-Path -Parent $PSScriptRoot
$AllUsersModuleDir = Join-Path $env:ProgramFiles "/PowerShell/Modules/NupkgDownloader"

New-Item $AllUsersModuleDir/src -ItemType Directory -Force | Out-Null
Copy-Item $PackageDir/src/* $AllUsersModuleDir/src
Copy-Item $PackageDir/NupkgDownloader.ps* $AllUsersModuleDir
