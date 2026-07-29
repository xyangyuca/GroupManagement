function Get-AccessPackage {

    param(
        [string]$DisplayName
    )

    Get-MgEntitlementManagementAccessPackage `
        -Filter "displayName eq '$DisplayName'"
}