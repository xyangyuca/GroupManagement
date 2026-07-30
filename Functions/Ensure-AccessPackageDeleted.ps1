function Ensure-AccessPackageDeleted {

    param(
        [string]$DisplayName,
        [bool]$Simulate,
        [switch]$Cascade
    )

    $existingPackage =
        Get-AccessPackage `
            -DisplayName $DisplayName

    if (-not $existingPackage) {

        return @{
            Action          = "Skipped"
            Status          = "Success"
            Message         = "Access Package not found"
            AccessPackageId = ""
        }
    }

    $policies =
        Get-AccessPackagePolicies `
            -AccessPackageId $existingPackage.Id

    if ($policies.Count -gt 0) {

        if (-not $Cascade) {

            return @{
                Action          = "Skipped"
                Status          = "Success"
                Message         = "Access Package has assignment policies and cannot be deleted. Use -Cascade to remove policies first."
                AccessPackageId = $existingPackage.Id
                PolicyCount     = $policies.Count
            }
        }

        if ($Simulate) {

            return @{
                Action          = "Simulated"
                Status          = "Success"
                Message         = "Would delete $($policies.Count) assignment policies and then delete Access Package"
                AccessPackageId = $existingPackage.Id
                PolicyCount     = $policies.Count
            }
        }

        foreach ($policy in $policies) {

            Remove-MgEntitlementManagementAssignmentPolicy `
                -AccessPackageAssignmentPolicyId $policy.Id
        }
    }

    if ($Simulate) {

        return @{
            Action          = "Simulated"
            Status          = "Success"
            Message         = "Would delete Access Package"
            AccessPackageId = $existingPackage.Id
            PolicyCount     = 0
        }
    }

    Remove-MgEntitlementManagementAccessPackage `
        -AccessPackageId $existingPackage.Id

    return @{
        Action          = "Deleted"
        Status          = "Success"
        Message         = if ($Cascade) {
            "Access Package and associated policies deleted"
        }
        else {
            "Access Package deleted"
        }
        AccessPackageId = $existingPackage.Id
        PolicyCount     = 0
    }
}