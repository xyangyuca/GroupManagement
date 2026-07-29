function Get-AppConfig {

    $configPath = "$PSScriptRoot\..\Config\settings.json"

    if (!(Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    Get-Content $configPath | ConvertFrom-Json
}
