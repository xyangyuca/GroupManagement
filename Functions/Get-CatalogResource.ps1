function Get-CatalogResource {

    param(
        [Parameter(Mandatory)]
        [string]$CatalogId,

        [Parameter(Mandatory)]
        [string]$GroupId
    )

    $resources =
        Get-MgEntitlementManagementCatalogResource `
            -AccessPackageCatalogId $CatalogId `
            -All

    return $resources |
        Where-Object {
            $_.OriginSystem -eq "AadGroup" -and
            $_.OriginId -eq $GroupId
        } |
        Select-Object -First 1
}