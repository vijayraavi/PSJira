. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

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

    Describe "Remove-JiraIssueLink" {

        if ($ShowDebugText) {
            Mock Write-Debug {
                Write-Host "DEBUG: $Message" -ForegroundColor Yellow
            }
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'ServerName'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Delete' -and $URI -eq "/rest/api/latest/issueLink/1234"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'ServerName'
        }

        Mock Get-JiraIssue -ParameterFilter {$Key -eq "TEST-01"} {
            # We don't care about the content of any field except for the id of the issuelinks
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            $issue = [PSCustomObject]@{
                issueLinks = @(
                    $obj
                )
            }
            $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $issue
        }

        Mock Get-JiraIssueLink {
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            return $obj
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraIssueLink

            defParam $command 'IssueLink'
            defParam $command 'Credential'
        }

        Context "Functionality" {


            It "Accepts generic object with the correct properties" {
                $issueLink = [PSCustomObject]@{ id = $issueLinkId }
                { Remove-JiraIssueLink -IssueLink $issueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.Issue object over the pipeline" {
                { Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.IssueType over the pipeline" {
                { Get-JiraIssueLink -Id 1234 | Remove-JiraIssueLink  } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Validates pipeline input" {
                { @{id = 1} | Remove-JiraIssueLink } | Should Throw
            }

            It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
                Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink -ServerName 'testServer' | Out-Null
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
            }
        }
    }
}
