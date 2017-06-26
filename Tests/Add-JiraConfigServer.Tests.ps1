. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Add-JiraConfigServer" {

        Mock Write-Debug {
            if ($ShowDebugText) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Context "Behavior testing" {

            Mock Get-JiraConfig {
                @{
                    Servers = @()
                }
            }

            Mock Set-JiraConfig {
                $Config | ConvertTo-Json | Out-File 'TestDrive:\config.json'
            }

            Context "Sanity checking" {
                $command = Get-Command -Name "Add-JiraConfigServer"
                defParam $command "Name"
                defParam $command "Url"
                defParam $command "Default"
            }

            $output = Add-JiraConfigServer -Name 'add' -Url 'addUrl'
            $config = Get-Content 'TestDrive:\config.json' -Raw | ConvertFrom-Json
            $addServer = $config.Servers | Where-Object {$_.Name -eq 'add'}

            It "Creates the configuration file if it does not exist" {
                'TestDrive:\config.json' | Should Exist
            }

            It "Defines an item in the Servers array in the JSON file" {
                $addServer | Should Not BeNullOrEmpty
                $addServer.Name | Should Be 'add'
                $addServer.Url | Should Be 'addUrl'
            }

            It "Sets the new server as default (if the file did not exist)" {
                $addServer.Default | Should Be $true
            }

            It 'Writes no output' {
                $output | Should Be $null
            }

            Mock Get-JiraConfig {
                @{
                    Servers = @(
                        @{
                            Name    = 'Existing'
                            Url     = 'existingUrl'
                            Default = $false
                        }
                    )
                }
            }

            It "Adds a new entry if the config file exists and the given server is not in it" {
                Add-JiraConfigServer -Name 'addNew' -Url 'addNewUrl'
                $config = Get-Content 'TestDrive:\config.json' -Raw | ConvertFrom-Json

                $config.Servers.Count | Should Be 2

                $existingServer = $config.Servers | Where-Object {$_.Name -eq 'Existing'}
                $newServer = $config.Servers | Where-Object {$_.Name -eq 'addNew'}

                $existingServer.Url | Should Be 'existingUrl'
                $newServer.Url | Should Be 'addNewUrl'
            }

            Mock Write-Warning

            It "If the server exists and -Force was not used, writes a warning message and does not change the config file" {
                Add-JiraConfigServer -Name 'Existing' -Url 'existingNewUrl'
                $config = Get-Content 'TestDrive:\config.json' -Raw | ConvertFrom-Json
                $existingServer = $config.Servers | Where-Object {$_.Name -eq 'Existing'}

                $existingServer.Url | Should Be 'existingUrl'
                Assert-MockCalled 'Write-Warning'
            }

            It "If the server exists and -Force was used, overwrites the existing entry" {
                Add-JiraConfigServer -Name 'Existing' -Url 'existingNewUrl' -Force
                $config = Get-Content 'TestDrive:\config.json' -Raw | ConvertFrom-Json
                $existingServer = $config.Servers | Where-Object {$_.Name -eq 'Existing'}

                $existingServer.Url | Should Be 'existingNewUrl'
                Assert-MockCalled 'Write-Warning' -Scope It -Exactly -Times 0
            }
        }

        Context "Integration with other config functions" {
            Mock Get-JiraConfigFile { 'TestDrive:\config.json' }
            It "Writes a server in a format compatible with Get-JiraConfigServer" {
                Add-JiraConfigServer -Name 'Pester' -Url 'pesterUrl'
                $server = Get-JiraConfigServer
                $server | Should Not BeNullOrEmpty
                $server.Name | Should Be 'Pester'
                $server.Default | Should Be $true
            }
        }
    }
}