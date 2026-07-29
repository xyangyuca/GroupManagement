
function Add-AccessPackage {

    param(
        [string]$DisplayName,
        [string]$Description,
        [string]$CatalogId
    )

    New-MgEntitlementManagementAccessPackage `
        -BodyParameter @{
            displayName = $DisplayName
            description = $Description
            isHidden    = $false

            catalog = @{
                id = $CatalogId
            }
        }
}