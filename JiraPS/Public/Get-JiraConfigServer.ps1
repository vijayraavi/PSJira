function Get-JiraConfigServer {
    [CmdletBinding(DefaultParameterSetName = 'ReturnSpecificServer')]
    param(
        [Parameter(ParameterSetName = 'ReturnSpecificServer',
            Position = 0)]
        [Alias('Name')]
        [String] $ServerName,

        [Parameter(ParameterSetName = 'ReturnAll',
            Mandatory)]
        [Switch] $Default
    )

    process {
        $servers = (Get-JiraConfig).Servers

        if ($Default) {
            $servers | Where-Object {$_.Default} | Write-Output
        }
        elseif ($ServerName) {
            $servers | Where-Object {$_.Name -like $ServerName} | Write-Output
        }
        else {
            $servers | Write-Output
        }
    }
}
