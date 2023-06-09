Function Download-Nupkg
{
    <#
    .SYNOPSIS
    Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET
    #>    
    Param(
        [Parameter(Mandatory=$true, Position=0)] [string] $PackageId,
        [string]$OutputDirectory=$pwd,
        [string]$Version,

        [switch]$Prerelease,

        [string]$Source=$null,
        [string]$Verbosity="quiet"
    )

    $tempDirectory = New-TemporaryDirectory
    $watcherObject = Watch-Directory -Path $($tempDirectory.FullName)

    try {
        $startParams = @{
            FilePath = 'nuget.exe'
            ArgumentList = @(
                "install $PackageId",
                " -OutputDirectory ""$($tempDirectory.FullName)""",
                #" -DirectDownload",
                " -NoCache",
                " -Verbosity $Verbosity"
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

        Write-Host "Copying to '$OutputDirectory'..."
        $nupkgs = Get-ChildItem -Recurse -Path $($tempDirectory.FullName) -Include *.nupkg 
        $nupkgs | ForEach-Object { 
            Copy-Item -Path $_.FullName -Destination $OutputDirectory 
        }
    }
    finally {
        if($null -ne $watcherObject) {
            Unwatch-Directory -WatcherObject $watcherObject
        }
        if(Test-Path($tempDirectory.FullName)) {
            Write-Host "Removing $($tempDirectory.FullName).."
            Remove-Item -Force -Recurse -Path $($tempDirectory.FullName)
        }
    }
    Write-Host "Done."
}