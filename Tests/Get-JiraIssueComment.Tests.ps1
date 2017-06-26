. $PSScriptRoot\Shared.ps1


InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-JiraIssueComment" {

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 12345
        $issueKey = 'TEST-1'

        $restResult = @"
{
  "startAt": 0,
  "maxResults": 1,
  "total": 1,
  "comments": [
    {
      "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
      "id": "90730",
      "body": "Test comment",
      "created": "2015-05-01T16:24:38.000-0500",
      "updated": "2015-05-01T16:24:38.000-0500",
      "visibility": {
        "type": "role",
        "value": "Developers"
      }
    }
  ]
}
"@

        if ($ShowDebugData) {
            Mock Write-Debug {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{
                ID      = $issueID;
                Key     = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
            }
        }

        # Obtaining comments from an issue
        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/latest/issue/$issueID/comment"} {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Method', 'Uri', 'ServerName'
            # if ($ShowMockData) {
            #     Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
            #     Write-Host "         [Method] $Method" -ForegroundColor Cyan
            #     Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            # }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Obtains all Jira comments from a Jira issue if the issue key is provided" {
            $comments = Get-JiraIssueComment -Issue $issueKey
            $comments | Should Not BeNullOrEmpty
            @($comments).Count | Should Be 1
            $comments.ID | Should Be 90730
            $comments.Body | Should Be 'Test comment'
            $comments.RestUrl | Should Be "$jiraServer/rest/api/2/issue/$issueID/comment/90730"

            # Get-JiraIssue should be called to identify the -Issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

            # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueComment, but
            # since we've mocked Get-JiraIssue out, it will only be called once.
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Obtains all Jira comments from a Jira issue if the Jira object is provided" {
            $issue = Get-JiraIssue -Key $issueKey
            $comments = Get-JiraIssueComment -Issue $issue
            $comments | Should Not BeNullOrEmpty
            $comments.ID | Should Be 90730
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Handles pipeline input from Get-JiraIssue" {
            $comments = Get-JiraIssue -Key $issueKey | Get-JiraIssueComment
            $comments | Should Not BeNullOrEmpty
            $comments.ID | Should Be 90730
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Passes the -ServerName parameter to Get-JiraIssue if specified" {
            Get-JiraIssueComment -Issue $issueKey -ServerName 'testServer' | Out-Null
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }
    }
}


