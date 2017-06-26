. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-JiraConfigServer" {

        Mock Write-Debug {
            if ($ShowDebugText) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfig {
            @{
                Servers = @(
                    [PSCustomObject] @{
                        Name    = 'Server1'
                        Url     = 'url1'
                        Default = $false
                    },
                    [PSCustomObject] @{
                        Name    = 'Server2'
                        Url     = 'url2'
                        Default = $true
                    }
                )
            }
        }

        It "When no parameters are specified, outputs only the default server" {
            $default = Get-JiraConfigServer
            $default | Should Not BeNullOrEmpty
            $default.Name | Should Be 'Server2'
            $default.Url | Should Be 'url2'
            $default.Default | Should Be $true
        }

        It "When the -Name parameter is used, outputs the server with the provided name" {
            $server = Get-JiraConfigServer -Name 'Server1'
            $server | Should Not BeNullOrEmpty
            $server.Name | Should Be 'Server1'
            $server.Url | Should Be 'url1'
        }

        It "When the -All parameter is used, outputs all servers in the config file" {
            $allServers = Get-JiraConfigServer -All
            $allServers.Count | Should Be 2
            $allServers[0].Name | Should Be 'Server1'
            $allServers[1].Url | Should Be 'url2'
        }

        It "Uses -Name for a positional parameter" {
            $server = Get-JiraConfigServer 'Server1'
            $server | Should Not BeNullOrEmpty
            $server.Name | Should Be 'Server1'
        }
    }
}