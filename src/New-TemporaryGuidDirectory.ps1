# New-TemporaryGuidDirectory.ps1

#*------v Function New-TemporaryGuidDirectory v------
Function New-TemporaryGuidDirectory {
 <#
    .SYNOPSIS
    New-TemporaryGuidDirectory - Creates a directory named with a GUID in the user's TEMP path
    .NOTES
    Version     : 0.0.2
    Author      : rossobianero
    Website     : https://github.com/rossobianero
    Twitter     : 
    CreatedDate : 2024-01-12
    FileName    : New-TemporaryGuidDirectory.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/NupkgDownloader
    Tags        : Powershell,NuPackage,Chocolatey,Package
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 12:05 PM 1/12/2024 fork & tweak: Alias & rename more descriptively New-TemporaryDirectory -> New-TemporaryGuidDirectory; added CBH; stick into verb-IO
    * 6/9/23 rossobianero posted version
    .DESCRIPTION
    New-TemporaryGuidDirectory - Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET

    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    System.IO.DirectoryInfo object
    .EXAMPLE
    PS> $tempDirectory = New-TemporaryGuidDirectory 
    PS> $tempDirectory

            Directory: C:\Users\USERNAME\AppData\Local\Temp\5


        Mode                LastWriteTime         Length Name                                                                                                                                       
        ----                -------------         ------ ----                                                                                                                                       
        d-----        1/12/2024   1:38 PM                3e9424eb-7211-4e70-87cb-42922bae5e75    
        

    Creates a new guid-named dir below $env:TEMP
    .LINK
    https://github.com/tostka/NupkgDownloader
    .LINK
    https://github.com/rossobianero/NupkgDownloader
    .LINK
    #>
    [CmdletBinding()]
    [Alias('New-TemporaryDirectory')]
    Param()
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $tempDir= $(New-Item -ItemType Directory -Path (Join-Path $parent $name))
    Write-Host "Created temp directory '$($tempDir.FullName)'"
    return $tempDir
}
#*------^ END Function New-TemporaryGuidDirectory ^------