#All credit to https://powershell.one/tricks/filesystem/filesystemwatcher
<#
$global:ProgressCounterStart=1
$global:ProgressCounterReset=25
$global:ProgressCounterMax=100

$global:ProgressCounter=$global:ProgressCounterStart
#>
#*------v Function Add-DirectoryWatch v------
Function Add-DirectoryWatch {
    <#
    .SYNOPSIS
    Add-DirectoryWatch - Monitoring Folders for File Changes
    .NOTES
    Version     : 0.1.0
    Author      : Dr. Tobias Weltner
    Website     : https://powershell.one/tricks/filesystem/filesystemwatcher
    Twitter     : 
    CreatedDate : 11/3/19 20191103
    FileName    : Add-DirectoryWatch.ps1
    License     : Attribution-NoDerivatives 4.0 International https://creativecommons.org/licenses/by-nd/4.0/
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/NupkgDownloader
    Tags        : Powershell,NuPackage,Chocolatey,Package
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 12:05 PM 1/12/2024 forked rossobianero copy under NuPkgDownloader: Aliased funcs to reflect inconsist names in other bundled functions; 
        expand CBH; 
    * 6/9/23 rossobianero posted version
    .DESCRIPTION
    Add-DirectoryWatch - Monitoring Folders for File Changes

    Bundled with NuPkgDownloader by rossobianero

    Source post intro:
    [Monitoring Folders for File Changes - powershell.one](https://powershell.one/tricks/filesystem/filesystemwatcher)

    # Monitoring Folders for File Changes

    With a **FileSystemWatcher**, you can monitor folders for file changes and respond immediately when changes are detected. This way, you can create “drop” folders and respond to log file changes.

    The **FileSystemWatcher** object can monitor files or folders and notify **PowerShell** when changes occur. It can monitor a single folder or include all subfolders, and there is a variety of filters.
    
    
    .PARAMETER Path
    Folder to be watched for changes[-path c:\path-to\]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output 
    .EXAMPLE
    PS> $watcherObject = Add-DirectoryWatch -Path $($tempDirectory.FullName) ;
    PS> write-host 'Change!' ; 
    PS> Remove-DirectoryWatch -WatcherObject $watcherObject ; 
    Add WatcherObject on specified path, and store the object in the $WatcherObject variable; wait for a change; and then use the matching Remove-DirectoryWatch to remove the watcher.
    .LINK
    https://github.com/tostka/NupkgDownloader
    .LINK
    https://github.com/rossobianero/NupkgDownloader
    #>
    [CmdletBinding()]
    [Alias('Watch-Directory')]
    Param(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'Folder to be watched for changes[-path c:\path-to\]')]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path=(get-location)
    ) ; 
    if(-not (get-variable -name ProgressCounterStart -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterStart=1}
    if(-not (get-variable -name ProgressCounterReset -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterReset=25}
    if(-not (get-variable -name ProgressCounterMax -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterMax=100}
    if(-not (get-variable -name ProgressCounter -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounter=$global:ProgressCounterStart}
    # specify which files you want to monitor
    $FileFilter = '*'  

    # specify whether you want to monitor subfolders as well:
    $IncludeSubfolders = $true

    # specify the file or folder properties you want to monitor:
    $AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 

    $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
        Path = $Path
        Filter = $FileFilter
        IncludeSubdirectories = $IncludeSubfolders
        NotifyFilter = $AttributeFilter
    }

    # define the code that should execute when a change occurs:
    $action = {
        $global:ProgressCounter++
        if($global:ProgressCounter -gt $global:ProgressCounterMax) {
            $global:ProgressCounter=$global:ProgressCounterReset
        }
        Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
    }

    # subscribe your event handler to all event types that are
    # important to you. Do this as a scriptblock so all returned
    # event handlers can be easily stored in $handlers:
    $handlers = . {
        Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action 
        Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action 
        Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action 
        Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action 
    }

    # monitoring starts now:
    $watcher.EnableRaisingEvents = $true

    $watchObject = [pscustomobject]@{
        Watcher = $watcher;
        Handlers = $handlers
    }

    return $watchObject;
}
#*------^ END Function Add-DirectoryWatch ^------

#*------v Function Remove-DirectoryWatch v------
Function Remove-DirectoryWatch {
    <#
    .SYNOPSIS
    Remove-DirectoryWatch - Monitoring Folders for File Changes
    .NOTES
    Version     : 0.1.0
    Author      : Dr. Tobias Weltner
    Website     : https://powershell.one/tricks/filesystem/filesystemwatcher
    Twitter     : 
    CreatedDate : 11/3/19 20191103
    FileName    : Remove-DirectoryWatch.ps1
    License     : Attribution-NoDerivatives 4.0 International https://creativecommons.org/licenses/by-nd/4.0/
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/NupkgDownloader
    Tags        : Powershell,NuPackage,Chocolatey,Package
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 12:05 PM 1/12/2024 forked rossobianero copy under NuPkgDownloader: Aliased funcs to reflect inconsist names in other bundled functions; 
        expand CBH; 
    * 6/9/23 rossobianero posted version
    .DESCRIPTION
    Remove-DirectoryWatch - Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET

    Bundled with NuPkgDownloader by rossobianero

    Source post intro:
    [Monitoring Folders for File Changes - powershell.one](https://powershell.one/tricks/filesystem/filesystemwatcher)

    # Monitoring Folders for File Changes

    With a **FileSystemWatcher**, you can monitor folders for file changes and respond immediately when changes are detected. This way, you can create “drop” folders and respond to log file changes.

    The **FileSystemWatcher** object can monitor files or folders and notify **PowerShell** when changes occur. It can monitor a single folder or include all subfolders, and there is a variety of filters.
    
    
    .PARAMETER Path
    Folder to be watched for changes[-path c:\path-to\]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output 
    .EXAMPLE
    PS> $watcherObject = Add-DirectoryWatch -Path $($tempDirectory.FullName) ;
    PS> write-host 'Change!' ; 
    PS> Remove-DirectoryWatch -WatcherObject $watcherObject ; 
    Add WatcherObject on specified path, and store the object in the $WatcherObject variable; wait for a change; and then use the matching Remove-DirectoryWatch to remove the watcher.
    .LINK
    https://github.com/tostka/NupkgDownloader
    .LINK
    https://github.com/rossobianero/NupkgDownloader
    #>
    [CmdletBinding()]
    [Alias('Unwatch-Directory')]
    Param([Parameter(Mandatory=$true)][object]$WatcherObject)


    $watcher = $WatcherObject.Watcher;
    $handlers = $WatcherObject.Handlers;

    # stop monitoring
    $watcher.EnableRaisingEvents = $false
    
    # remove the event handlers
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    
    # event handlers are technically implemented as a special kind
    # of background job, so remove the jobs now:
    $handlers | Remove-Job
    
    # properly dispose the FileSystemWatcher:
    $watcher.Dispose()
    
    Write-Progress -Activity "Download" -PercentComplete 100
}
#*------^ END Function Remove-DirectoryWatch ^------