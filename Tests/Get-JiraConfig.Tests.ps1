. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-JiraConfig" {

        Mock Write-Debug {
            if ($ShowDebugText) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Context "Sanity checking" {
            $command = Get-Command 'Get-JiraConfig'
            defParam $command 'FilePath'
        }

        Context "Behavior testing" {
            $testPath = 'TestDrive:\config.json'
            $example = @{
                foo = @(
                    'bar', 'baz'
                )
            }
            $example | ConvertTo-Json | Set-Content -Path $testPath -Force

            It "Reads a JSON file at the provided path and outputs the results" {
                $config = Get-JiraConfig -FilePath $testPath
                $config | Should Not BeNullOrEmpty
                $config.foo[0] | Should Be 'bar'
            }

            It "Provides a default output if the file does not exist" {
                $config = Get-JiraConfig -FilePath 'TestDrive:\fake.json'
                $config | Should Not BeNullOrEmpty
                $config.PSObject.Properties.Name -contains 'Servers' | Should Be $true
                $config.Servers.Count | Should Be 0
            }

            Mock Get-JiraConfigFile { 'TestDrive:\default.json' }
            It "Uses Get-JiraConfigFile to use a default config path if -FilePath is not specified" {
                Get-JiraConfig
                Assert-MockCalled 'Get-JiraConfigFile'
            }
        }
    }
}