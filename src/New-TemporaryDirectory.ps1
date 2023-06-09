Function New-TemporaryDirectory 
{
    <#
    .SYNOPSIS
    Creates a directory named with a GUID in the user's TEMP path
    #>    
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $tempDir= $(New-Item -ItemType Directory -Path (Join-Path $parent $name))
    Write-Host "Created temp directory '$($tempDir.FullName)'"
    return $tempDir
}