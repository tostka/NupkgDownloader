BeforeAll {
    Get-ChildItem $PSScriptRoot/../src/*.ps1 | ForEach-Object { . $_.FullName }
}

Describe "New-TemporaryDirectory"  {
    BeforeEach {
        Mock New-Item  {
            $parent = [System.IO.Path]::GetTempPath()
            [string] $name = [System.Guid]::NewGuid()
            $fullName = Join-Path $parent $name
            $mock = New-MockObject -Type "System.IO.DirectoryInfo" -Properties @{ 
                Parent = $parent;
                FullName = $fullName
            }
            $mock
        }
        Mock Write-Host { }
    }
    It "Created a temporary directory" {
        $tempDir = New-TemporaryDirectory
        $userTempPath = [System.IO.Path]::GetTempPath()
        Assert-MockCalled Write-Host -ParameterFilter { $Object.StartsWith("Created temp") }
        Assert-MockCalled New-Item -ParameterFilter { 
            $Path.StartsWith($userTempPath) 
        }
        $tempDir.GetType() | Should -Be "System.IO.DirectoryInfo" 
        $tempDir.Parent | Should -BeExactly $userTempPath
    }    
}
