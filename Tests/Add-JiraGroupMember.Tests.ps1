. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    # In most test cases, user 1 is a member of the group and user 2 is not
    $testGroupName = 'testGroup'
    $testUsername1 = 'testUsername1'
    $testUsername2 = 'testUsername2'

    Describe "Add-JiraGroupMember" {

<<<<<<< HEAD
        Mock Write-Debug {
=======
        Mock Write-Debug -ModuleName JiraPS {
>>>>>>> dev
            if ($ShowDebugData) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraGroup {
            [PSCustomObject] @{
                'Name' = $testGroupName
                'Size' = 2
            }
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            [PSCustomObject] @{
                'Name' = "$InputObject"
            }
        }

        Mock Get-JiraGroupMember -ModuleName JiraPS {
            @(
                [PSCustomObject] @{
                    'Name' = $testUsername1
                }
            )
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Method', 'URI'
        }

        #############
        # Tests
        #############
        Context "Sanity checking" {

            $expectedUrl = "/rest/api/latest/group/user?groupname=$testGroupName"
            It "Accepts a group name as a String to the -Group parameter" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -eq $expectedUrl} -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.Group object to the -Group parameter" {
                Get-JiraGroup -GroupName $testGroupName | Out-Null
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -eq $expectedUrl} -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraGroup" {
                { Get-JiraGroup -GroupName $testGroupName | Add-JiraGroupMember -User $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$URI -eq $expectedUrl} -Exactly -Times 1 -Scope It
            }

            It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
                Add-JiraGroupMember -GroupName $testGroupName -User $testUsername2 -ServerName 'testServer' | Out-Null
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
            }
        }

        Context "Behavior testing" {

            It "Tests to see if a provided user is currently a member of the provided JIRA group before attempting to add them" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1 } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraGroupMember -Exactly -Times 1 -Scope It
            }

            It "Adds a user to a JIRA group if the user is not a member" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Post' -and $URI -match $testGroupName -and $Body -match $testUsername2} -Exactly -Times 1 -Scope It
            }

            It "Adds multiple users to a JIRA group if they are passed to the -User parameter" {

                # Override our previous mock so we have no group members
                Mock Get-JiraGroupMember -ModuleName JiraPS {
                    @()
                }

                # Should use the REST method twice, since at present, you can only add one group member per API call
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Post' -and $URI -match $testGroupName} -Exactly -Times 2 -Scope It
            }
        }

        Context "Error checking" {
            It "Gracefully handles cases where a provided user is already in the provided group" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$Method -eq 'Post' -and $URI -match $testGroupName} -Exactly -Times 1 -Scope It
            }
        }
    }
}
