function Ensure-AccessPackageDeleted {

    param(
        [string]$DisplayName,
        [bool]$Simulate
    )

    $existing =
        Get-AccessPackage `
            -DisplayName $DisplayName

    if (-not $existing) {

        return @{
            Action          = "Skipped"
            Status          = "Success"
            Message         = "Access Package not found"
            AccessPackageId = ""
        }
    }

    if ($Simulate) {

        return @{
            Action          = "Simulated"
            Status          = "Success"
            Message         = "Would delete Access Package"
            AccessPackageId = $existing.Id
        }
    }

    Remove-MgEntitlementManagementAccessPackage `
        -AccessPackageId $existing.Id

    return @{
        Action          = "Deleted"
        Status          = "Success"
        Message         = "Access Package deleted"
        AccessPackageId = $existing.Id
    }
}