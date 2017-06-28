function Get-JiraProject {
    <#
    .Synopsis
       Returns a project from Jira
    .DESCRIPTION
       This function returns information regarding a specified project from Jira. If
       the Project parameter is not supplied, it will return information about all
       projects the given user is authorized to view.

       The -Project parameter will accept either a project ID or a project key.
    .EXAMPLE
       Get-JiraProject -Project TEST -Credential $cred
       Returns information about the project TEST
    .EXAMPLE
       Get-JiraProject 2 -Credential $cred
       Returns information about the project with ID 2
    .EXAMPLE
       Get-JiraProject -Credential $cred
       Returns information about all projects the user is authorized to view
    .INPUTS
       [String[]] Project ID or project key
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.Project]
    #>
    [CmdletBinding(DefaultParameterSetName = 'AllProjects')]
    param(
        # The Project ID or project key of a project to search.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [String[]] $Project,

        # Server name from the module config to connect to.
        # If not specified, the default server will be used.
        [Parameter(Mandatory = $false)]
        [String] $ServerName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        $uri = "/rest/api/latest/project"
    }

    process {
        if ($Project) {
            foreach ($p in $Project) {
                Write-Debug "[Get-JiraProject] Processing project [$p]"
                $thisUri = "$uri/${p}?expand=projectKeys"

                Write-Debug "[Get-JiraProject] Preparing for blastoff!"

                $result = Invoke-JiraMethod -Method Get -URI $thisUri -ServerName $ServerName -Credential $Credential
                if ($result) {
                    Write-Debug "[Get-JiraProject] Converting to object"
                    $obj = ConvertTo-JiraProject -InputObject $result

                    Write-Debug "[Get-JiraProject] Outputting result"
                    Write-Output $obj
                }
                else {
                    Write-Debug "[Get-JiraProject] No results were returned from Jira"
                    Write-Debug "[Get-JiraProject] No results were returned from Jira for project [$p]"
                }
            }
        }
        else {
            Write-Debug "[Get-JiraProject] Attempting to search for all projects"
            $thisUri = "$uri"

            Write-Debug "[Get-JiraProject] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential
            if ($result) {
                Write-Debug "[Get-JiraProject] Converting to object"
                $obj = ConvertTo-JiraProject -InputObject $result

                Write-Debug "[Get-JiraProject] Outputting result"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraProject] No results were returned from Jira"
                Write-Debug "[Get-JiraProject] No project results were returned from Jira"
            }
        }
    }

    end {
        Write-Debug "Complete"
    }
}
