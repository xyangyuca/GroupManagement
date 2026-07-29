function Get-Catalog {

    param(
        [string]$Environment,
        [string]$PartnerFiler,
        [object]$Config
    )

    $tokens = @{
        Environment  = $Environment
        PartnerFiler = $PartnerFiler
    }

    $catalogName =
        Resolve-Template `
            -Template $Config.Catalogs.DisplayNameTemplate `
            -Tokens $tokens

    $catalog =
        Get-MgEntitlementManagementCatalog `
            -Filter "displayName eq '$catalogName'"

    if (-not $catalog) {
        throw "Catalog not found: $catalogName"
    }

    return $catalog
}
