function Add-AccessPackagePolicy {

    param(
        [hashtable]$PolicyDefinition
    )

    New-MgEntitlementManagementAssignmentPolicy `
        -BodyParameter $PolicyDefinition
}