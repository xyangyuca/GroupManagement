function Ensure-AccessPackageDeleted {

    param(
        [string]$DisplayName,
        [bool]$Simulate
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

    $policies = Get-AccessPackagePolicies -AccessPackageId $existingPackage.Id

    if ($policies.Count -gt 0) {

        return @{
            Action          = "Skipped"
            Status          = "Success"
            Message         = "Access Package has assignment policies and cannot be deleted"
            AccessPackageId = $existingPackage.Id
            PolicyCount     = $policies.Count
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
        Message         = "Access Package deleted"
        AccessPackageId = $existingPackage.Id
        PolicyCount     = 0
    }
}