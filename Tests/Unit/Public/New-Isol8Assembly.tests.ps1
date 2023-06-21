BeforeAll {
    $script:moduleName = 'Isol8'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe New-Isol8Assembly {
    Context 'ShouldProcess' {
        It 'Supports WhatIf' {
            (Get-Command New-Isol8Assembly).Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
    }

    Context 'Base functionallity' {
        BeforeAll {
            # Set up mock manifest
            New-Item -Path "TestDrive:/Module" -ItemType Directory -Force
            New-ModuleManifest -Path "TestDrive:/Module/UnitTest.psd1" -RootModule "" -NestedModules 'one'
        }

        It 'Creates an assembly' {
            New-Isol8Assembly -Name 'UnitTest' -Path "TestDrive:/Module/Dependencies/UnitTest.dll"
            Test-Path "TestDrive:/Module/Dependencies/UnitTest.dll" | Should -Be $true
        }

        It 'Creates an assembly if one allready exists' {
            New-Isol8Assembly -Name 'UnitTest' -Path "TestDrive:/Module/Dependencies/UnitTest.dll"
            {Test-Path "TestDrive:/Module/Dependencies/UnitTest.dll"} | Should -Not -Throw
        }

        It 'Updates a manifest' {
            New-Isol8Assembly -Name 'UnitTest' -Path "TestDrive:/Module/Dependencies/UnitTest.dll" -ManifestPath "TestDrive:/Module/UnitTest.psd1"
            Test-Path "TestDrive:/Module/UnitTest.psd1" | Should -Be $true
            (Import-PowerShellDataFile -Path "TestDrive:/Module/UnitTest.psd1").NestedModules | Should -Match @('\.[\\|/]Dependencies[\\/]UnitTest\.dll', 'one')
        }
    }
}

