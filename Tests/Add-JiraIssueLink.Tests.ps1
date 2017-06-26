. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $issueKey = "TEST-01"
    $issueLink = [PSCustomObject]@{
        outwardIssue = [PSCustomObject]@{key = "TEST-10"}
        type         = [PSCustomObject]@{name = "Composition"}
    }


    Describe 'Add-JiraIssueLink' {

        Mock Get-JiraIssue {
            ShowMockInfo 'Get-JiraIssue' 'Key', 'ServerName'

            # Creates an object with the value of the $Key parameter
            [PSCustomObject]@{
                Key = $Key
            }
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'POST' -and $URI -eq "/rest/api/latest/issueLink"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            return $true
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Add-JiraIssueLink

            defParam $command 'Issue'
            defParam $command 'IssueLink'
            defParam $command 'Comment'
            defParam $command 'Credential'
        }

        Context "Functionality" {

            It 'Adds a new IssueLink' {
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It 'Validates the IssueType provided' {
                $issueLink = [PSCustomObject]@{ type = "foo" }
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should Throw
            }

            It 'Validates pipeline input object' {
                { "foo" | Add-JiraIssueLink -IssueLink $issueLink } | Should Throw
            }

            It "Passes the -ServerName parameter to both Get-JiraIssue and Invoke-JiraMethod if specified" {
                Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink -ServerName 'testServer' | Out-Null
                Assert-MockCalled -CommandName Get-JiraIssue -ParameterFilter {$ServerName -eq 'testServer'}
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
            }
        }
    }
}
