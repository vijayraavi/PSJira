function Get-JiraConfigFile {
    [CmdletBinding()]
    param()

    process {
        Join-Path -Path $env:APPDATA -ChildPath 'WindowsPowerShell\PSJira\config.json' | Write-Output
    }
}
