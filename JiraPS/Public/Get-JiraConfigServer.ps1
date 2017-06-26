function Get-JiraConfigServer {
    [CmdletBinding(DefaultParameterSetName = 'ReturnSpecificServer')]
    param(
        [Parameter(ParameterSetName = 'ReturnSpecificServer',
            Position = 0)]
        [Alias('Name')]
        [String] $ServerName,

        [Parameter(ParameterSetName = 'ReturnAll',
            Mandatory)]
        [Switch] $All
    )

    process {
        $servers = (Get-JiraConfig).Servers

        if ($All) {
            $servers | Write-Output
        }
        elseif ($ServerName) {
            $servers | Where-Object {$_.Name -like $ServerName} | Write-Output
        }
        else {
            $servers | Where-Object {$_.Default} | Write-Output
        }
    }
}
