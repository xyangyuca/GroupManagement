function Test-AccessPackageResourceAssignment {

    param(
        [string]$AccessPackageId,
        [string]$EntraGroupObjectId
    )

    $assignments =
        Get-MgEntitlementManagementAccessPackageResourceRoleScope `
            -AccessPackageId $AccessPackageId `
            -All

    $assignment =
        $assignments |
        Where-Object {
            $_.Role.Resource.OriginId -eq $EntraGroupObjectId
        }

    return ($null -ne $assignment)
}