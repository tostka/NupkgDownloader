#All credit to https://powershell.one/tricks/filesystem/filesystemwatcher

$global:ProgressCounterStart=1
$global:ProgressCounterReset=25
$global:ProgressCounterMax=100

$global:ProgressCounter=$global:ProgressCounterStart

Function Watch-Directory {
    Param([string]$Path=$pwd)

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


Function Unwatch-Directory {
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