function Get-AccessPackagePolicies {

    param(
        [string]$AccessPackageId
    )

    Get-MgEntitlementManagementAssignmentPolicy `
        -Filter "accessPackage/id eq '$AccessPackageId'" -All
}