function New-JiraGroup {
    <#
    .Synopsis
       Creates a new group in JIRA
    .DESCRIPTION
       This function creates a new group in JIRA.
    .EXAMPLE
       New-JiraGroup -GroupName testGroup
       This example creates a new JIRA group named testGroup.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [JiraPS.Group] The user object created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Name for the new group.
        [Parameter(Mandatory = $true,
            Position = 0)]
        [Alias('Name')]
        [String] $GroupName,

        # Server name from the module config to connect to.
        # If not specified, the default server will be used.
        [Parameter(Mandatory = $false)]
        [String] $ServerName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    begin {
        $restUrl = "/rest/api/latest/group"
    }

    process {
        Write-Debug "[New-JiraGroup] Defining properties"
        $props = @{
            "name" = $GroupName;
        }

        Write-Debug "[New-JiraGroup] Converting to JSON"
        $json = ConvertTo-Json -InputObject $props

        Write-Debug "[New-JiraGroup] Checking for -WhatIf and Confirm"
        if ($PSCmdlet.ShouldProcess($GroupName, "Creating group [$GroupName] to JIRA")) {
            Write-Debug "[New-JiraGroup] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -ServerName $ServerName -Credential $Credential
        }
        if ($result) {
            Write-Debug "[New-JiraGroup] Converting output object into a Jira user and outputting"
            ConvertTo-JiraGroup -InputObject $result
        }
        else {
            Write-Debug "[New-JiraGroup] Jira returned no results to output."
        }
    }
}
