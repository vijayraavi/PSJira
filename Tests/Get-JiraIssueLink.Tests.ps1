. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $issueLinkId = 1234

    # We don't care about anything except for the id
    $resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@

    Describe "Get-JiraIssueLink" {

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/2/issueLink/$issueLinkId"} {
            ConvertFrom-Json2 $resultsJson
        }

        Mock Get-JiraIssue -ParameterFilter {$Key -eq "TEST-01"} {
            # We don't care about the content of any field except for the id
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            return [PSCustomObject]@{
                issueLinks = @(
                    $obj
                )
            }
        }

        #############
        # Tests
        #############

        It "Returns details about a specific issue link" {
            $result = Get-JiraIssueLink -Id $issueLinkId
            $result | Should Not BeNullOrEmpty
            @($result).Count | Should Be 1
        }

        It "Provides the ID of the issue link" {
            $result = Get-JiraIssueLink -Id $issueLinkId
            $result.Id | Should Be $issueLinkId
        }

        It "Accepts input from pipeline" {
            $result = (Get-JiraIssue -Key TEST-01).issuelinks | Get-JiraIssueLink
            $result.Id | Should Be $issueLinkId
        }

        It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
            Get-JiraIssueLink -Id $issueLinkId -ServerName 'testServer'
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }

        It 'Fails if input from the pipeline is of the wrong type' {
            { [PSCustomObject]@{id = $issueLinkId} | Get-JiraIssueLink } | Should Throw
        }
    }
}
