function Get-SqlAccessToken {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    $secureSecret = ConvertTo-SecureString `
        $Config.secrectValue `
        -AsPlainText `
        -Force

    Get-MsalToken `
        -TenantId $Config.tenantId `
        -ClientId $Config.clientId `
        -ClientSecret $secureSecret `
        -Scopes "https://database.windows.net/.default"
}