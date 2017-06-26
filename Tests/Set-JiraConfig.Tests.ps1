. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Set-JiraConfig" {
        Mock Write-Debug {
            if ($ShowDebugText) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        $testPath = 'TestDrive:\config.json'
        $example = @{
            foo = @(
                'bar', 'baz'
            )
        }

        $result = Set-JiraConfig -Config $example -FilePath $testPath
        $resultFileContents = Get-Content $testPath -Raw | ConvertFrom-Json

        It "Sets a configuration file at the provided path to the JSON representation of a hashtable" {
            $testPath | Should Exist
            $resultFileContents | Should Not BeNullOrEmpty
            $resultFileContents.foo | Should Be @('bar', 'baz')
        }

        It "Writes no output" {
            $result | Should Be $null
        }

        Mock Get-JiraConfigFile { 'TestDrive:\default.json' }
        It "Uses Get-JiraConfigFile to get a default config path if -FilePath is not specified" {
            Set-JiraConfig $example
            Assert-MockCalled 'Get-JiraConfigFile'
            'TestDrive:\default.json' | Should Exist
        }
    }
}