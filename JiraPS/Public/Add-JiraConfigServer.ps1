function Add-JiraConfigServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0)]
        [String] $Name,

        [Parameter(Mandatory = $true,
            Position = 0)]
        [String] $Url,

        [Parameter()]
        [Switch] $Default,

        [Parameter()]
        [Switch] $Force
    )

    process {
        $config = Get-JiraConfig
        $existingServer = $config.Servers | Where-Object {$_.Name -eq $Name}

        if (-not $Force -and $existingServer) {
            Write-Warning "JiraPS configuration file already contains a server named $Name. Use -Force to overwrite the existing entry, or Get-JiraConfigServer for more information."
            return
        }
        elseif ($existingServer) {
            Write-Debug "[Add-JiraConfigServer] -Force was specified; overwriting existing server $Name"
            $servers = @($config.Servers | Where-Object {$_.Name -ne $Name})
        }
        else {
            $servers = @($config.Servers)
        }

        if (-not $Default -and -not ($config.Servers | Where-Object {$_.Default})) {
            Write-Debug "[Add-JiraConfigServer] No default server was found; setting new server to default"
            $Default = $true
        }

        $newServer = @{
            Name    = $Name.Trim()
            Url     = $Url.Trim()
            Default = [bool] $Default
        }
        $config.Servers = $servers + $newServer

        Set-JiraConfig $config
    }
}