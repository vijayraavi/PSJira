function Set-JiraConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            Position = 0)]
        [Object] $Config,

        [Parameter()]
        [String] $FilePath = (Get-JiraConfigFile)
    )

    process {
        $Config | ConvertTo-Json | Set-Content -Path $FilePath
    }
}
