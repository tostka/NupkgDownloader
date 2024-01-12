# Save-NuGetPackage.ps1

#*------v Function Save-NuGetPackage v------
Function Save-NuGetPackage {
    <#
    .SYNOPSIS
    Save-NuGetPackage - Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET
    .NOTES
    Version     : 0.0.
    Author      : rossobianero
    Website     : https://github.com/rossobianero
    Twitter     : 
    CreatedDate : 2024-01-12
    FileName    : Save-NuGetPackage.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/NupkgDownloader
    Tags        : Powershell,NuPackage,Chocolatey,Package
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 4:53 PM 1/12/2024 fork & tweak: fix broken psd1 (regen full: missing ModuleVersion); expand CBH; alias & ren to stock verb: Download-Nupkg -> Save-NuGetPackage ; 
        corrected mixed function names (between Add-DirectoryWatch.ps1 & Download-Nupkg.ps1: Alias Watch-Directory & Unwatch-Directory to Add-DirectoryWatch & Remove-DirectoryWatch, update on this end)
        moved freestanding Add-DirectoryWatch() & Remove-Directory() as backup internal (moving set to verb-IO mod); 
        add pipeline support (flip $packageID to array and ValueFromPipeline=$true, adv func & proc loop
        added ThrottleDelay (try to avoid choco pushback)
        moved new-TemporaryGuidDirectory into begin block as well - make it self contained (and leaf funcs covered in verb-io mod)
        Added RateLimit Throttling, to 50% of the $limitPkgsPerMin (20 per current docs)
    * 6/9/23 rossobianero posted version
    .DESCRIPTION
    Save-NuGetPackage - Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET

    # Original Readme.md contents: 
    
        [rossobianero/NupkgDownloader: Powershell module to download nupkg files from a nuget feed as well as all dependencies](https://github.com/rossobianero/NupkgDownloader)

        ## Introduction

        This repository contains a Powershell module that downloads nuget (and chocolatey) packages as nupkg files from a feed including their dependencies

        ## Chocolatey Installation

        choco install NupkgDownloader


        [](https://github.com/rossobianero/NupkgDownloader#usage)

        ## Usage

        Once installed, run the command as follows (e.g. this will download fooPackage version 1.2.3 from the chocolatey community feed to c:\\temp\\install, along with all of its dependencies):

        Save-NuGetPackage fooPackage -Version 1.2.3 -OutputDirectory c:\temp\install -Source "https://community.chocolatey.org/api/v2/"

    ---

    ## On Chocolatey Throttling
    
    Installations/downloads of Chocolatey itself (chocolatey.nupkg) are rate limited at about 5 per minute per IP address - temporary ban expires after 1 hour.
    All other packages are rate limited at about 20 per minute per IP address - temporary ban expires after 1 hour.


        [Excessive Use - Chocolatey Software Docs | community.chocolatey.org Packages Disclaimer](https://docs.chocolatey.org/en-us/community-repository/community-packages-disclaimer#excessive-use)
        ...
        [Chocolatey Software Docs | community.chocolatey.org Packages Disclaimer](https://docs.chocolatey.org/en-us/community-repository/community-packages-disclaimer)

        By abusive, it **may** mean more than **100 installs per hour on average over an internally determined amount of time** (it could be more, could be less) - this is not queries, this is **installs, upgrades** where actual package downloads are occurring. Let's say that is 30 days - that would mean 72,000+ package downloads over 30 days.        
        ...
        [Chocolatey Software Docs | community.chocolatey.org Packages Disclaimer](https://docs.chocolatey.org/en-us/community-repository/community-packages-disclaimer)

        ### Rate Limiting

        **NOTE**

        Purchasing licenses will not have any effect on rate limiting of the community package repository. Please read carefully below to understand why this was put in place and steps you can take to reduce issues if you run into it. HINT: It's not an attempt to get you to pay for commercial editions.

        As a measure to increase site stability and prevent excessive use, the Chocolatey website uses rate limiting on requests for the community repository. Rate limiting was introduced in November 2018. Most folks typically won't hit rate limits unless they are automatically tagged for excessive use. If you do trigger the rate limit, you will see a `(429) Too Many Requests`. When attempting to install Chocolatey you will see the following:

        ![Exception calling "DownloadFile" with "2" arguments: The remote server returned an error: 429 Too Many Requests](https://docs.chocolatey.org/assets/images/cloudflare_ratelimiting_choco_install.png)

        It will look like the following using choco.exe:

        ![The remote server returned an error: 429 Too Many Requests](https://docs.chocolatey.org/assets/images/cloudflare_ratelimiting_choco.png)

        If you go to a package page and attempt to use the download link in the left menu, you will see the following:

        ![Error 1015, You are being rate limited](https://docs.chocolatey.org/assets/images/cloudflare_ratelimiting.png)

        You will start to see `429 Too Many Requests` if you have triggered the rate limit. Currently the rate limit will be in place for one hour. If you trigger it again, it will then be set for another hour.

        -   Error 1015

        **NOTE**

        Please note that individuals using the community repository are unlikely to hit rate limiting under normal usage scenarios.

        **Details:**

        -   Installations/downloads of Chocolatey itself (chocolatey.nupkg) are rate limited at about 5 per minute per IP address - temporary ban expires after 1 hour.
        -   All other packages are rate limited at about 20 per minute per IP address - temporary ban expires after 1 hour.
    
    .PARAMETER PackageId
    NuPkg ID (e.g. Chocolatey ID)[-PackageId notepad2]
    .PARAMETER Destination
    Output path [-Destination c:\pathto\]
    .PARAMETER Version
    Target Version [-Version c:\pathto\]
    .PARAMETER Prerelease
    Switch to indicate to permit Prerelease versions[-Prerelease]
    .PARAMETER Source
    Nuget Feed source[-Source 'https://community.chocolatey.org/api/v2/']
    .PARAMETER VerbosityNG
    Specifies the amount of Nuget.exe detail displayed in the output: normal (the default), quiet, or detailed[-VerbosityNG normal]
    .PARAMETER ThrottleDelay
    Delay in milliseconds to be applied between a series of downloads(1000 = 1sec)[-ThrottleDelay 1000]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output 
    .EXAMPLE
    PS> Save-NuGetPackage notepad2 -Version 4.2.25.20160422 -Destination d:\tmp\chococache -Source "https://community.chocolatey.org/api/v2/" 
    Download notepad2 4.2.25.20160422 to d:\tmp\chococache, from the Choolatey Community Feed.
    .EXAMPLE
    PS> Save-NuGetPackage notepad2,curl -Destination d:\tmp\chococache -Source Chocolatey
    Download latest verison of notepad2 & curl to d:\tmp\chococache, from the Choolatey Community Feed (designated by the Chocolatey keyword)
    .EXAMPLE
    PS> 'awk','grep ' |Save-NuGetPackage -Destination d:\tmp\chococache -Source Chocolatey
    Demo pipeline support: Download latest verison of awk & grep to d:\tmp\chococache, from the Choolatey Community Feed (designated by the Chocolatey keyword)
    .LINK
    https://github.com/tostka/NupkgDownloader
    .LINK
    https://github.com/rossobianero/NupkgDownloader
    .LINK
    #>
    [CmdletBinding()]
    [Alias('Save-Nupkg')]
    Param(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,HelpMessage="NuPkg ID (e.g. Chocolatey ID)[-PackageId notepad2]")]
            [string[]] $PackageId,
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'Output path [-Destination c:\pathto\]')]
            [Alias('PsPath','OutputDirectory')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})] # don't require it to be preexisting
            #[string]
            [System.IO.DirectoryInfo]$Destination=(get-location),
        [Parameter(HelpMessage = 'Target Version [-Version c:\pathto\]')]
            #[version]
            [string]$Version,
        [Parameter(HelpMessage = 'Switch to indicate to permit Prerelease versions[-Prerelease]')]
            [switch]$Prerelease,
        [Parameter(HelpMessage = "Nuget Feed source (supports 'Chocolatey' to designate the community Choco endpoint)[-Source 'https://community.chocolatey.org/api/v2/']")]
            [string]$Source=$null,
        [Parameter(HelpMessage = 'Specifies the amount of Nuget.exe detail displayed in the output: normal (the default), quiet, or detailed[-VerbosityNG normal]')]
            [Alias('Verbosity')]
            [string]$VerbosityNG="quiet",
        [Parameter(HelpMessage = "Delay in milliseconds to be applied between a series of downloads(1000 = 1sec)[-ThrottleDelay 1000]")]
            [int]$ThrottleDelay
    )
    BEGIN { 
        if(-not (get-variable -name ProgressCounterStart -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterStart=1}
        if(-not (get-variable -name ProgressCounterReset -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterReset=25}
        if(-not (get-variable -name ProgressCounterMax -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounterMax=100}
        if(-not (get-variable -name ProgressCounter -Scope global -ErrorAction SilentlyContinue)){$global:ProgressCounter=$global:ProgressCounterStart}
        $chocoDefaultSource = "https://community.chocolatey.org/api/v2/"  ; 
        $limitPkgsPerMin = 20 ; 

        if($Source -eq 'Chocolatey'){
            write-verbose "Flip -Source:$($Source) -> $($chocoDefaultSource)" ;
            $Source = $chocoDefaultSource
        } ; 
        if(-not $ThrottleDelay -AND ((get-variable -name ThrottleMs -ea 0).value)){
            $ThrottleDelay = $ThrottleMs ; 
            $smsg = "(no -ThrottleDelay specified, but found & using `$global:ThrottleMs:$($ThrottleMs)ms" ; 
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"; 
        } ; 
        #*------v Function Add-DirectoryWatch v------
        if(-not (get-command Add-DirectoryWatch -ea 0)){
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
        } ;
        #*------v Function Remove-DirectoryWatch v------
        if(-not (get-command Remove-DirectoryWatch -ea 0)){
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
        } ;
        #*------^ END Function Remove-DirectoryWatch ^------
        #*------v Function New-TemporaryGuidDirectory v------
        if(-not (get-command Remove-DirectoryWatch -ea 0)){
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
        } ;
        #*------^ END Function New-TemporaryGuidDirectory ^------

        if(-not (test-path -path $Destination.fullname -PathType Container)){
            TRY{
                $Destination = mkdir -Path $Destination.fullname -ErrorAction stop -verbose:$true ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
            
        } ; 

        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;
        
        # $limitPkgsPerMin 
        $PkgsThisMin = 0 ;
        $TimeStart = $null ; 
    } ;  # BEGIN-E
    PROCESS {
        foreach($item in $PackageId) {
        
            $smsg = $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;

            $TimeStart = (get-date )  ; 

            $tempDirectory = New-TemporaryGuidDirectory
            $watcherObject = Add-DirectoryWatch -Path $($tempDirectory.FullName)

            try {
                <# [NuGet CLI install command | Microsoft Learn](https://learn.microsoft.com/en-us/nuget/reference/cli-reference/cli-ref-install)
                  install : Downloads and installs a package into a project, defaulting to the current folder, using specified package sources.
                    -OutputDirectory: Specifies the folder in which packages are installed. If no folder is specified, the current folder is used.
                    -DirectDownload: Download directly without populating any caches with metadata or binaries.
                    -NoCache:
                    -Verbosity [normal|quiet|detailed]: Specifies the amount of detail displayed in the output: normal (the default), quiet, or detailed.
                    -Version: Specifies the version of the package to install.
                    -Prerelease:Allows prerelease packages to be installed. This flag is not required when restoring packages with packages.config.
                    -Source: Specifies the list of package sources (as URLs) to use. If omitted, the command uses the sources provided in configuration files, see Common NuGet configurations.
                #>
                $startParams = @{
                    FilePath = 'nuget.exe'
                    ArgumentList = @(
                        #"install $PackageId",
                        "install $item",
                        " -OutputDirectory ""$($tempDirectory.FullName)""",
                        #" -DirectDownload",
                        " -NoCache",
                        " -Verbosity $VerbosityNG"
                    )
                }
                if($Version) {
                    $startParams.ArgumentList += " -Version $Version"
                }
                if($Prerelease) {
                    $startParams.ArgumentList += " -Prerelease"
                }
                if($Source) {
                    $startParams.ArgumentList += " -Source $Source"
                }

                $startParams.NoNewWindow=$true
                $startParams.PassThru=$true

                Write-Host "Starting download..."
                $process = Start-Process @startParams 

                while(-not $process.WaitForExit(10)) {
                    # wait
                }

                Write-Host "Copying to '$($Destination.fullname)'..."
                $nupkgs = Get-ChildItem -Recurse -Path $($tempDirectory.FullName) -Include *.nupkg 
                $nupkgs | ForEach-Object { 
                    Copy-Item -Path $_.FullName -Destination "$($Destination.fullname)\" -verbose:$($VerbosePreference -eq "Continue"); 
                }
            }
            finally {
                if($null -ne $watcherObject) {
                    Remove-DirectoryWatch -WatcherObject $watcherObject
                }
                if(Test-Path($tempDirectory.FullName)) {
                    Write-Host "Removing $($tempDirectory.FullName).."
                    Remove-Item -Force -Recurse -Path $($tempDirectory.FullName)
                }
            }

            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;

            # RateLimit Throttle to 50% of $limitPkgsPerMin
            $ElapsedTime = (Get-Date) - $TimeStart
            if($ElapsedTime.totalminutes -lt 1){
                $PkgsThisMin ++ ; 
            } else {
                $PkgsThisMin = 0
                $TimeStart = (get-date )  ; 
            }; 
            write-verbose "Aiming to stay 50% below RateLimit, so we only approach *half* the permitted rate limit" ; 
            write-verbose "Rate:$($PkgsThisMin)/$(($limitPkgsPerMin/2))" ; 
            if($PkgsThisMin -gt ($limitPkgsPerMin/2)){
                write-host "Rate:$($PkgsThisMin)/$(($limitPkgsPerMin/2)):pausing while a minute completes..." ; 
                $a=1 ; 
                [int]$waits = ((1 - $elapsedtime.totalminutes) * 60) ;
                Do {write-host -NoNewline ".$($waits)" ; start-sleep -Seconds 1 ; $waits--} 
                While ($waits -gt 0) ;
                $PkgsThisMin = 0
                $TimeStart = (get-date )  ; 
            } 

            <# strict time wait throttle
            if($ThrottleDelay){
                start-sleep -Milliseconds $ThrottleDelay ; 
            } ; 
            #>
        } ;  # loop-E
    } ;  # PROC-E
} ; 
#*------^ END Function Save-NuGetPackage ^------