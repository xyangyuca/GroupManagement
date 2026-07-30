function Update-AccessPackagePolicy {

    param(
        [string]$PolicyId,

        [hashtable]$PolicyDefinition
    )

    Update-MgEntitlementManagementAssignmentPolicy `
        -AccessPackageAssignmentPolicyId $PolicyId `
        -BodyParameter $PolicyDefinition
}