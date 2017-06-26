function Get-JiraConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0)]
        [String] $FilePath = (Get-JiraConfigFile)
    )

    begin {
        # If a config file doesn't exist, create a default configuration
        # to prevent null errors
        $defaultConfig = [PSCustomObject] @{
            'Servers' = @()
        }
    }

    process {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Debug "[Get-JiraConfig] Configuration file does not exist at path [[ $FilePath ]]; returning default config"
            return $defaultConfig
        }

        Write-Debug "[Get-JiraConfig] Reading configuration from file [[ $FilePath ]]"
        Get-Content -Path $FilePath -Raw | ConvertFrom-Json | Write-Output
    }
}
