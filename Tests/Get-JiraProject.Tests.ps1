. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $projectKey = 'IT'
    $projectId = '10003'
    $projectName = 'Information Technology'

    $projectKey2 = 'TEST'
    $projectId2 = '10004'
    $projectName2 = 'Test Project'

    $restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    },
    {
        "self": "$jiraServer/rest/api/2/project/10121",
        "id": "$projectId2",
        "key": "$projectKey2",
        "name": "$projectName2",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@

    $restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@

    Describe "Get-JiraProject" {

        if ($ShowDebugText) {
            Mock Write-Debug {
                Write-Host "DEBUG: $Message" -ForegroundColor Yellow
            }
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/latest/project"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Get', 'ServerName'
            ConvertFrom-Json2 $restResultAll
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/latest/project/${projectKey}?expand=projectKeys"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            ConvertFrom-Json2 $restResultOne
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/latest/project/${projectId}?expand=projectKeys"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            ConvertFrom-Json2 $restResultOne
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'Get' -and $URI -eq "/rest/api/latest/project/${projectKey}expand=projectKeys"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            ConvertFrom-Json2 $restResultOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Returns all projects if called with no parameters" {
            $allResults = Get-JiraProject
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be (ConvertFrom-Json2 -InputObject $restResultAll).Count
        }

        It "Returns details about specific projects if the project key is supplied" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
        }

        It "Returns details about specific projects if the project ID is supplied" {
            $oneResult = Get-JiraProject -Project $projectId
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
        }

        It "Provides the key of the project" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult.Key | Should Be $projectKey
        }

        It "Provides the ID of the project" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult.Id | Should Be $projectId
        }

        It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
            Get-JiraProject -Project $projectKey -ServerName 'testServer' | Out-Null
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }
    }
}
