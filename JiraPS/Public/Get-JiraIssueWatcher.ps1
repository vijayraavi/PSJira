function Get-JiraIssueWatcher {
    <#
    .Synopsis
       Returns watchers on an issue in JIRA.
    .DESCRIPTION
       This function obtains watchers from existing issues in JIRA.
    .EXAMPLE
       Get-JiraIssueWatcher -Key TEST-001
       This example returns all watchers posted to issue TEST-001.
    .EXAMPLE
       Get-JiraIssue TEST-002 | Get-JiraIssueWatcher
       This example illustrates use of the pipeline to return all watchers on issue TEST-002.
    .INPUTS
       This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.  It uses Get-JiraIssue to identify the issue parameter; see its Inputs section for details on how this function handles inputs.
    .OUTPUTS
       This function outputs all JiraPS.Watchers issues associated with the provided issue.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # JIRA issue to check for watchers. Can be a JiraPS.Issue object, issue key, or internal issue ID.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Server name from the module config to connect to.
        # If not specified, the default server will be used.
        [Parameter(Mandatory = $false)]
        [String] $ServerName,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    process {
        Write-Debug "[Get-JiraIssueWatcher] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -ServerName $ServerName -Credential $Credential

        $url = "$($issueObj.RestURL)/watchers"

        Write-Debug "[Get-JiraIssueWatcher] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

        if ($result) {
            if ($result.watchers) {
                Write-Verbose "Result: $($result)"
                Write-Verbose "Watchers: $($result.Watchers)"

                Write-Debug "[Get-JiraIssueWatcher] Converting result to Jira user objects"
                $obj = ConvertTo-JiraUser -InputObject $result.watchers

                Write-Debug "[Get-JiraIssueWatcher] Outputting results"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraIssueWatcher] Result appears to be in an unexpected format. Outputting raw result."
                Write-Output $result
            }
        }
        else {
            Write-Debug "[Get-JiraIssueWatcher] Invoke-JiraMethod returned no results to output."
        }
    }

    end {
        Write-Debug "[Get-JiraIssueWatcher] Completed"
    }
}
