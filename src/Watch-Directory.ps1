#All credit to https://powershell.one/tricks/filesystem/filesystemwatcher

$global:ProgressCounter=1
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
        # the code is receiving this to work with:
        
        # change type information:
        $details = $event.SourceEventArgs
        $Name = $details.Name
        $FullPath = $details.FullPath
        $OldFullPath = $details.OldFullPath
        $OldName = $details.OldName
        
        # type of change:
        $ChangeType = $details.ChangeType
        
        # when the change occured:
        $Timestamp = $event.TimeGenerated
        
        # save information to a global variable for testing purposes
        # so you can examine it later
        # MAKE SURE YOU REMOVE THIS IN PRODUCTION!
        #$global:all = $details
        
        # now you can define some action to take based on the
        # details about the change event:
        
        # let's compose a message:
        $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp
        
        # you can also execute code based on change type here:

        $global:ProgressCounter++
        if($global:ProgressCounter -gt 100) {
            $global:ProgressCounter=1
        }
        Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
        # switch ($ChangeType)
        # {
        # 'Created'  { "CREATED" 
        #     Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
        # }
        # 'Changed'  { "CHANGE" 
        #     Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
        # }
        # 'Renamed'  { 
        #     Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
        # }
        # 'Deleted'  { "DELETED"
        #    Write-Progress -Activity "Download" -PercentComplete $global:ProgressCounter
        # }
            
        # # any unhandled change types surface here:
        # default   { Write-Progress -Activity "Download" -PercentComplete $counter++ }
        #}
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
    #Write-Host "Watching for changes to $Path"

    return $watchObject;
}


Function Unwatch-Directory {
    Param([Parameter(Mandatory=$true)][object]$WatcherObject)
    # since the FileSystemWatcher is no longer blocking PowerShell
    # we need a way to pause PowerShell while being responsive to
    # incoming events. Use an endless loop to keep PowerShell busy:

    Write-Progress -Activity "Download" -PercentComplete 100

    $watcher = $WatcherObject.Watcher;
    $handlers = $WatcherObject.Handlers;

    # this gets executed when user presses CTRL+C:
    
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
    
    #Write-Warning "Event Handler disabled, monitoring ends."
    #Write-Host "#"
}