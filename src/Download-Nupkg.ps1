Function Download-Nupkg
{
    <#
    .SYNOPSIS
    Downloads a NUPKG and dependencies from Azure DevOps artifacts using NUGET
    #>    
    Param(
        [Parameter(Mandatory=$true, Position=0)] [string] $PackageId,
        [Parameter(Position=1)] [string]$Source=$null,
        [Parameter(Position=2)] [string]$Version,
        [Parameter(Position=3)] [string]$OutputDirectory=$pwd,
        [switch]$Prerelease
    )

    $startParams = @{
        FilePath = 'nuget.exe'
    }
    
    $tempDirectory = New-TemporaryDirectory
    try {
        $startParams.ArgumentList = "install $PackageId"
        $startParams.ArgumentList += " -OutputDirectory ""$($tempDirectory.FullName)"""
        $startParams.ArgumentList += " -DirectDownload"
        $startParams.ArgumentList += " -NoCache"
        if ($Source) {
            $startParams.ArgumentList += " -Source ""$Source"""
        }        
        if ($Version) {
            $startParams.ArgumentList += " -Version $Version"
        }
        if ($Prerelease) {
            $startParams.ArgumentList += " -Prerelease"
        }

        $startParams.NoNewWindow=$true
        $startParams.Wait=$true
        
        Write-Host "Starting download..."
        Start-Process @startParams 

        Write-Host "Flattening nupkgs..."
        $nupkgs = Get-ChildItem -Recurse -Path $($tempDirectory.FullName) -Include *.nupkg 
        $nupkgs | ForEach-Object { 
            Copy-Item -Path $_.FullName -Destination $OutputDirectory 
        }
    }
    finally {
        if(Test-Path($tempDirectory.FullName)) {
            Write-Host "Removing $($tempDirectory.FullName).."
            Remove-Item -Force -Recurse -Path $($tempDirectory.FullName)
        }
    }
    Write-Host "Done."
}