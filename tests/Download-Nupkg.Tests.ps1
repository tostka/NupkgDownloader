BeforeAll {
    Get-ChildItem $PSScriptRoot/../src/*.ps1 | ForEach-Object { . $_.FullName }
}

Describe "Download-Nupkg"  {
    BeforeEach {
        Mock Test-Path { $True } 
        Mock Remove-Item { }
        Mock Start-Process { }
        Mock Write-Host { }
        Mock New-TemporaryDirectory  {
            $parent = [System.IO.Path]::GetTempPath()
            [string] $name = [System.Guid]::NewGuid()
            $fullName = Join-Path $parent $name
            $mock = New-MockObject -Type "System.IO.DirectoryInfo" -Properties @{ 
                Parent = $parent;
                FullName = $fullName
            }
            $mock
        }
        Mock Get-ChildItem {
            $directory = Join-Path $([System.IO.Path]::GetTempPath()) $([System.Guid]::NewGuid())
            $ret = @(
                (New-MockObject -Type "System.IO.FileInfo" -Properties @{ 
                    FullName = Join-Path $directory "fooPackage.1.2.3.nupkg"
                }),
                (New-MockObject -Type "System.IO.FileInfo" -Properties @{ 
                    FullName = Join-Path $directory "dependencyPackage.1.2.3.nupkg"
                })
            )
            $ret;
        }
        Mock Copy-Item { }
    }
    Context "Normal execution without parameters" {
        BeforeEach {
            Download-Nupkg "fooPackage"
        }
        It "Creates a temp directory" {
            Assert-MockCalled New-TemporaryDirectory
        }    
        It "Calls nuget to install the package to the temp directory" {
            Assert-MockCalled Start-Process -ParameterFilter {
                $FilePath -eq "nuget.exe" -and
                $ArgumentList -match "install fooPackage" -and
                $ArgumentList -match "\s-OutputDirectory ""[^""]+"""
            }
        }    
        It "Copies" {
            Assert-MockCalled Get-ChildItem -ParameterFilter {$Path.StartsWith([System.IO.Path]::GetTempPath())}
            Assert-MockCalled Copy-Item -ParameterFilter {$Destination.StartsWith($pwd)} -Times 2
        }        
        It "Removes the temporary directory" {
            Assert-MockCalled Remove-Item -ParameterFilter {$Path.StartsWith([System.IO.Path]::GetTempPath())}
        }     
    }
    Context "Normal execution with parameters" {
        BeforeEach {
            Download-Nupkg "fooPackage" -Version 1.2.3 -Prerelease -OutputDirectory "c:\foo\bar" -Source "http://foo/bar"
        }
        It "Calls nuget to install the package to the temp directory" {
            Assert-MockCalled New-TemporaryDirectory
            Assert-MockCalled Start-Process -ParameterFilter {
                $ArgumentList -match "install fooPackage" -and
                $ArgumentList -match "\s-OutputDirectory ""[^""]+""" -and    
                $ArgumentList -match "\s-Version 1.2.3" -and
                $ArgumentList -match "\s-Prerelease" -and  
                $ArgumentList -match "\s-Source ""http://foo/bar"""            
            }
        }  
        It "Copies" {
            Assert-MockCalled Get-ChildItem -ParameterFilter {$Path.StartsWith([System.IO.Path]::GetTempPath())}
            Assert-MockCalled Copy-Item -ParameterFilter {$Destination -eq "c:\foo\bar"} -Times 2
        }           
        It "Removes the temporary directory" {
            Assert-MockCalled Remove-Item -ParameterFilter {$Path.StartsWith([System.IO.Path]::GetTempPath())}
        }     
    }    
    Context "Error occurs" {
        BeforeEach {
            Mock Start-Process { throw "Some error occurred" }
        }
        It "Removes the temporary directory when found" {
            { Download-Nupkg "fooPackage" } | Should -Throw
            Assert-MockCalled Remove-Item -ParameterFilter {$Path.StartsWith([System.IO.Path]::GetTempPath())}
        }     
        It "Does not remove the temporary directory when not found" {
            Mock Test-Path { $False }
            { Download-Nupkg "fooPackage" } | Should -Throw
            Assert-MockCalled Remove-Item -Times 0
        }     
    }       
}

