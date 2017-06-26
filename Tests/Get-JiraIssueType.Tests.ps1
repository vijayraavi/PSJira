. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    $jiraServer = 'http://jiraserver.example.com'

    $issueTypeId = 10103
    $issueTypeName = 'Bug'

    $restResult = @"
[
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10100",
        "id": "10100",
        "description": "A user story. Created by JIRA Software - do not edit or delete.",
        "iconUrl": "$jiraServer/secure/viewavatar?size=xsmall&avatarId=10315&avatarType=issuetype",
        "name": "Story",
        "subtask": false,
        "avatarId": 10315
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10101",
        "id": "10101",
        "description": "A task that needs to be done.",
        "iconUrl": "$jiraServer/secure/viewavatar?size=xsmall&avatarId=10318&avatarType=issuetype",
        "name": "Task",
        "subtask": false,
        "avatarId": 10318
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10103",
        "id": "10103",
        "description": "jira.translation.issuetype.bug.name.desc",
        "iconUrl": "$jiraServer/secure/viewavatar?size=xsmall&avatarId=10303&avatarType=issuetype",
        "name": "Bug",
        "subtask": false,
        "avatarId": 10303
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10102",
        "id": "10102",
        "description": "The sub-task of the issue",
        "iconUrl": "$jiraServer/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
        "name": "Sub-task",
        "subtask": true,
        "avatarId": 10316
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10000",
        "id": "10000",
        "description": "A big user story that needs to be broken down. Created by JIRA Software - do not edit or delete.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/epic.svg",
        "name": "Epic",
        "subtask": false
    }
]
"@

    Describe "Get-JiraIssueType" {

        Mock Get-JiraConfigServer {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $Uri -eq "/rest/api/latest/issuetype"} {
            ConvertFrom-Json2 $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Gets all issue types in Jira if called with no parameters" {
            $allResults = Get-JiraIssueType
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be (ConvertFrom-Json2 $restResult).Count
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Gets a specified issue type if an issue type ID is provided" {
            $oneResult = Get-JiraIssueType -IssueType $issueTypeId
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be $issueTypeId
            $oneResult.Name | Should Be $issueTypeName
        }

        It "Gets a specified issue type if an issue type name is provided" {
            $oneResult = Get-JiraIssueType -IssueType $issueTypeName
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be $issueTypeId
            $oneResult.Name | Should Be $issueTypeName
        }

        It "Handles positional parameters correctly" {
            $oneResult = Get-JiraIssueType $issueTypeName
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be $issueTypeId
            $oneResult.Name | Should Be $issueTypeName
        }

        It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
            Get-JiraIssueType $issueTypeName -ServerName 'testServer' | Out-Null
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }

        Context "Output Checking" {

            Mock ConvertTo-JiraIssueType {}

            Get-JiraIssueType

            It "Uses ConvertTo-JiraIssueType to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraIssueType'
            }
        }
    }
}
