function Get-JiraComponent {
    <#
    .Synopsis
       Returns a Component from Jira
    .DESCRIPTION
       This function returns information regarding a specified component from Jira.
       If -InputObject is given via parameter or pipe all components for
       the given project are returned.
       It is not possible to get all components with this function.
    .EXAMPLE
       Get-JiraComponent -Id 10000 -Credential $cred
       Returns information about the component with ID 10000
    .EXAMPLE
       Get-JiraComponent 20000 -Credential $cred
       Returns information about the component with ID 20000
    .EXAMPLE
       Get-JiraProject Project1 | Get-JiraComponent -Credential $cred
       Returns information about all components within project 'Project1'
    .EXAMPLE
        Get-JiraComponent ABC,DEF
        Return information about all components within projects 'ABC' and 'DEF'
    .INPUTS
       [String[]] Component ID
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.Component]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # The Project ID or project key of a project to search.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'ByProject'
        )]
        $Project,

        # The Component ID.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [Alias("Id")]
        [int[]] $ComponentId,

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
        $uri = "/rest/api/latest"
    }

    process {
        if ($Project) {
            if ($Project.PSObject.TypeNames[0] -eq 'JiraPS.Project') {
                $ComponentId = @($Project.Components | Select-Object -ExpandProperty id)
            }
            else {
                foreach ($p in $Project) {
                    if ($p -is [string]) {
                        Write-Debug "[Get-JiraComponent] Processing project [$p]"
                        $thisUri = "$uri/project/${p}/components"

                        Write-Debug "[Get-JiraComponent] Preparing for blastoff!"

                        $result = Invoke-JiraMethod -Method Get -URI $thisUri -ServerName $ServerName -Credential $Credential
                        if ($result) {
                            Write-Debug "[Get-JiraComponent] Converting to object"
                            $obj = ConvertTo-JiraComponent -InputObject $result

                            Write-Debug "[Get-JiraComponent] Outputting result"
                            Write-Output $obj
                        }
                        else {
                            Write-Debug "[Get-JiraComponent] No results were returned from Jira"
                            Write-Debug "[Get-JiraComponent] No results were returned from Jira for component [$i]"
                        }
                    }
                }
            }
        }
        if ($ComponentId) {
            foreach ($i in $ComponentId) {
                Write-Debug "[Get-JiraComponent] Processing component [$i]"
                $thisUri = "$uri/component/${i}"

                Write-Debug "[Get-JiraComponent] Preparing for blastoff!"

                $result = Invoke-JiraMethod -Method Get -URI $thisUri -ServerName $ServerName -Credential $Credential
                if ($result) {
                    Write-Debug "[Get-JiraComponent] Converting to object"
                    $obj = ConvertTo-JiraComponent -InputObject $result

                    Write-Debug "[Get-JiraComponent] Outputting result"
                    Write-Output $obj
                }
                else {
                    Write-Debug "[Get-JiraComponent] No results were returned from Jira"
                    Write-Debug "[Get-JiraComponent] No results were returned from Jira for component [$i]"
                }
            }
        }
    }

    end {
        Write-Debug "[Get-JiraComponent] Complete"
    }
}
