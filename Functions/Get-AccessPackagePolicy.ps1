function Get-AccessPackagePolicy {

    param(
        [string]$AccessPackageId
    )

    Get-MgEntitlementManagementAccessPackageAssignmentPolicy `
        -AccessPackageId $AccessPackageId `
        -ErrorAction SilentlyContinue
}