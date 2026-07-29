function Get-CatalogGroupResource {

    param(
        [string]$CatalogId,
        [string]$EntraGroupObjectId
    )

    $resources =
        Get-MgEntitlementManagementCatalogResource `
            -AccessPackageCatalogId $CatalogId `
            -ExpandProperty Scopes `
            -Filter "originSystem eq 'AadGroup'" `
            -All

    $resources |
        Where-Object {
            $_.OriginId -eq $EntraGroupObjectId
        }
}