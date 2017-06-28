function Get-JiraUser {
    <#
    .Synopsis
       Returns a user from Jira
    .DESCRIPTION
       This function returns information regarding a specified user from Jira.
    .EXAMPLE
       Get-JiraUser -UserName user1 -Credential $cred
       Returns information about the user user1
    .EXAMPLE
       Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
       This example searches Active Directory for the username of John W. Smith, John H. Smith,
       and any other John Smiths, then obtains their JIRA user accounts.
    .INPUTS
       [String[]] Username
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.User]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByUserName')]
    param(
        # Username, name, or e-mail address of the user. Any of these should
        # return search results from Jira.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByUserName'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Name')]
        [String[]] $UserName,

        # User Object of the user.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByInputObject'
        )]
        [Object[]] $InputObject,

        # Include inactive users in the search
        [Switch] $IncludeInactive,

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
        Write-Debug "[Get-JiraUser] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraUser] Building URI for REST call"
        $userSearchUrl = "/rest/api/latest/user/search?username={0}"
        if ($IncludeInactive) {
            $userSearchUrl = "$userSearchUrl&includeInactive=true"
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByUserName') {
            foreach ($u in $UserName) {
                Write-Debug "[Get-JiraUser] Processing user [$u]"
                $thisSearchUrl = $userSearchUrl -f $u

                Write-Debug "[Get-JiraUser] Preparing for blastoff!"
                $rawResult = Invoke-JiraMethod -Method Get -URI $thisSearchUrl -ServerName $ServerName -Credential $Credential

                if ($rawResult) {
                    Write-Debug "[Get-JiraUser] Processing raw results from JIRA"
                    foreach ($r in $rawResult) {
                        Write-Debug "[Get-JiraUser] Re-obtaining user information for user [$r]"
                        $url = '{0}&expand=groups' -f $r.self
                        Write-Debug "[Get-JiraUser] Preparing for blastoff!"
                        $thisUserResult = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

                        if ($thisUserResult) {
                            Write-Debug "[Get-JiraUser] Converting result to JiraPS.User object"
                            $thisUserObject = ConvertTo-JiraUser -InputObject $thisUserResult
                            Write-Output $thisUserObject
                        }
                        else {
                            Write-Debug "[Get-JiraUser] User [$r] could not be found in JIRA."
                        }
                    }
                }
                else {
                    Write-Debug "[Get-JiraUser] JIRA returned no results."
                    Write-Verbose "JIRA returned no results for user [$u]."
                }
            }
        }
        else {
            foreach ($i in $InputObject) {
                Write-Debug "[Get-JiraUser] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'JiraPS.User') {
                    Write-Debug "[Get-JiraUser] User parameter is a JiraPS.User object"
                    $thisUserName = $i.Name
                }
                else {
                    $thisUserName = $i.ToString()
                    Write-Debug "[Get-JiraUser] Username is assumed to be [$thisUserName] via ToString()"
                }

                Write-Debug "[Get-JiraUser] Invoking myself with the UserName parameter set to search for user [$thisUserName]"
                $userObj = Get-JiraUser -UserName $thisUserName -ServerName $ServerName -Credential $Credential
                Write-Debug "[Get-JiraUser] Returned from invoking myself; outputting results"
                Write-Output $userObj
            }
        }
    }

    end {
        Write-Debug "[Get-JiraUser] Complete"
    }
}
