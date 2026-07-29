function Get-CatalogGroupMemberRole {

    param(
        [string]$CatalogId,
        [string]$CatalogResourceId
    )

    $roles =
        Get-MgEntitlementManagementCatalogResourceRole `
            -AccessPackageCatalogId $CatalogId `
            -Filter "originSystem eq 'AadGroup' and resource/id eq '$CatalogResourceId'" `
            -ExpandProperty Resource `
            -All

    $roles |
        Where-Object {
            $_.DisplayName -eq 'Member'
        }
}