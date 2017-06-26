function Add-JiraIssueLink {
    <#
    .Synopsis
        Adds a link between two Issues on Jira
    .DESCRIPTION
        Creates a new link of the specified type between two Issue.
    .EXAMPLE
        $link = [PSCustomObject]@{
            outwardIssue = [PSCustomObject]@{key = "TEST-10"}
            type = [PSCustomObject]@{name = "Composition"}
        }
        Add-JiraIssueLink -Issue TEST-01 -IssueLink $link
        Creates a link "is part of" between TEST-01 and TEST-10
    .INPUTS
        [JiraPS.Issue[]] The JIRA issue that should be linked
        [JiraPS.IssueLink[]] The JIRA issue link that should be used
    #>
    [CmdletBinding()]
    param(
        # Issue key or JiraPS.Issue object returned from Get-JiraIssue
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object[]] $Issue,

        # Issue Link to be created.
        [Parameter(Mandatory = $true)]
        [Object[]] $IssueLink,

        # Write a comment to the issue
        [String] $Comment,

        # Server name from the module config to connect to.
        # If not specified, the default server will be used.
        [Parameter(Mandatory = $false)]
        [String] $ServerName,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        $issueLinkURL = "/rest/api/latest/issueLink"
    }

    process {
        # Validate IssueLink object
        $objectProperties = $IssueLink | Get-Member -MemberType *Property
        if (-not(($objectProperties.Name -contains "type") -and (($objectProperties.Name -contains "outwardIssue") -or ($objectProperties.Name -contains "inwardIssue")))) {
            $message = "The IssueLink provided does not contain the information needed."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Validate input object from Pipeline
        if (($_) -and ($_.PSObject.TypeNames[0] -ne "JiraPS.Issue")) {
            $message = "Wrong object type provided for Issue. Only JiraPS.Issue is accepted"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($i in $Issue) {
            Write-Debug "[Add-JiraIssueLink] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -ServerName $ServerName -Credential $Credential

            foreach ($link in $IssueLink) {
                if ($link.inwardIssue) {
                    $inwardIssue = [PSCustomObject]@{key = $link.inwardIssue.key}
                }
                else {
                    $inwardIssue = [PSCustomObject]@{key = $issueObj.key}
                }

                if ($link.outwardIssue) {
                    $outwardIssue = [PSCustomObject]@{key = $link.outwardIssue.key}
                }
                else {
                    $outwardIssue = [PSCustomObject]@{key = $issueObj.key}
                }

                $body = [PSCustomObject] @{
                    type         = [PSCustomObject]@{name = $link.type.name}
                    inwardIssue  = $inwardIssue
                    outwardIssue = $outwardIssue
                }
                if ($Comment) {$body["comment"] = [PSCustomObject]@{body = $Comment}
                }
                $json = ConvertTo-Json $body

                $null = Invoke-JiraMethod -Method POST -URI $issueLinkURL -Body $json -ServerName $ServerName -Credential $Credential
            }
        }
    }

    end {
        Write-Debug "[Add-JiraIssueLink] Complete"
    }
}
