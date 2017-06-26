. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-JiraConfigFile" {
        $configFilePath = Join-Path -Path $env:APPDATA -ChildPath "WindowsPowerShell\PSJira\config.json"

        It "Returns the path to the PSJira config file" {
            Get-JiraConfigFile | Should Be $configFilePath
        }
    }
}