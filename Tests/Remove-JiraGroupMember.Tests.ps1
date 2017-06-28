. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'testGroup'
    $testUsername1 = 'testUsername1'
    $testUsername2 = 'testUsername2'

    Describe "Remove-JiraGroupMember" {

        if ($ShowDebugData) {
            Mock Write-Debug {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraGroup {
            [PSCustomObject] @{
                'Name' = $testGroupName;
                'Size' = 2;
            }
        }

        Mock Get-JiraUser {
            [PSCustomObject] @{
                'Name' = "$InputObject";
            }
        }

        Mock Get-JiraGroupMember {
            @(
                [PSCustomObject] @{
                    'Name' = $testUsername1;
                }
            )
        }

        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
        }

        #############
        # Tests
        #############
        Context "Sanity checking" {

            It "Accepts a group name as a String to the -Group parameter" {
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -match $testGroupName} -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.Group object to the -Group parameter" {
                $group = Get-JiraGroup -GroupName $testGroupName
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -match $testGroupName} -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraGroup" {
                { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroupMember -User $testUsername1 -Force} | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -match $testGroupName} -Exactly -Times 1 -Scope It
            }
        }

        Context "Behavior testing" {

            It "Tests to see if a provided user is currently a member of the provided JIRA group before attempting to remove them" {
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraGroupMember -Exactly -Times 1 -Scope It
            }

            It "Removes a user from a JIRA group if the user is a member" {
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Delete' -and $URI -like "*/rest/api/*/group/user?groupname=$testGroupName&username=$testUsername1"} -Exactly -Times 1 -Scope It
            }

            It "Removes multiple users to a JIRA group if they are passed to the -User parameter" {

                # Override our previous mock so we have two group members
                Mock Get-JiraGroupMember {
                    @(
                        [PSCustomObject] @{
                            'Name' = $testUsername1;
                        },
                        [PSCustomObject] @{
                            'Name' = $testUsername2;
                        }
                    )
                }

                # Should use the REST method twice, since at present, you can only delete one group member per API call
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Delete' -and $URI -like "*/rest/api/*/group/user?groupname=$testGroupName&username=*"} -Exactly -Times 2 -Scope It
            }

            It "Passes the -ServerName parameter to Get-JiraGroup, Get-JiraUser, and Invoke-JiraMethod if specified" {
                Remove-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -Force -ServerName 'testServer' | Out-Null
                Assert-MockCalled -CommandName Get-JiraGroup -ParameterFilter {$ServerName -eq 'testServer'}
                Assert-MockCalled -CommandName Get-JiraUser -ParameterFilter {$ServerName -eq 'testServer'}
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
            }
        }

        Context "Error checking" {
            It "Gracefully handles cases where a provided user is not currently in the provided group" {
                { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -Force } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Delete' -and $URI -like "*/rest/api/*/group/user?groupname=$testGroupName&username=*"} -Exactly -Times 1 -Scope It
            }
        }
    }
}
