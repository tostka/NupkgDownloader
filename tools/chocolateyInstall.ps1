
$ErrorActionPreference = 'Stop';
$_PSModulePath = $($env:PSModulePath -split ";")[1]
$AllUsersModuleDir = Join-Path $_PSModulePath "NupkgDownloader"
$PackageDir = Split-Path -Parent $PSScriptRoot

New-Item $AllUsersModuleDir/src -ItemType Directory -Force | Out-Null
Copy-Item $PackageDir/src/* $AllUsersModuleDir/src
Copy-Item $PackageDir/NupkgDownloader.ps* $AllUsersModuleDir
