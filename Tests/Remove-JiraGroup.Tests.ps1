. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'testGroup'

    $testJson = @"
{
    "name": "$testGroupName",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": 0,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@

    Describe "Remove-JiraGroup" {

        if ($ShowDebugData) {
            Mock Write-Debug -ModuleName JiraPS {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraGroup -ModuleName JiraPS {
            ConvertTo-JiraGroup (ConvertFrom-Json2 $testJson)
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "/rest/api/latest/group?groupname=$testGroupName"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a group name as a String to the -Group parameter" {
            { Remove-JiraGroup -Group $testGroupName -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.Group object to the -Group parameter" {
            $group = Get-JiraGroup -GroupName $testGroupName
            { Remove-JiraGroup -Group $group -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraGroup" {
            { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroup -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a group from JIRA" {
            { Remove-JiraGroup -Group $testGroupName -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraGroup -Group $testGroupName -Force | Should BeNullOrEmpty
        }

        It "Passes the -ServerName parameter to both Get-JiraGroup and Invoke-JiraMethod if specified" {
            Remove-JiraGroup -Group $testGroupName -ServerName 'testServer' -Force | Out-Null
            Assert-MockCalled -CommandName Get-JiraGroup -ParameterFilter {$ServerName -eq 'testServer'}
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }
    }
}
