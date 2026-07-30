function Ensure-AccessPackagePolicy {

    param(
        [string]$AccessPackageId,

        [string]$AccessPackageName,

        [object]$Row,

        [object]$Config,

        [string]$Environment,

        [string]$PartnerFiler,

        [bool]$Simulate
    )

    $tokens = @{
        Environment       = $Environment
        PartnerFiler      = $PartnerFiler
        Organization      = $Row.Organization
        Group             = $Row.Group
        AccessPackageName = $AccessPackageName
    }

    $policyName =
        Resolve-Template `
            -Template $Config.AccessPackagePolicies.DisplayNameTemplate `
            -Tokens $tokens

    $policyDescription =
        Resolve-Template `
            -Template $Config.AccessPackagePolicies.DescriptionTemplate `
            -Tokens $tokens

    $requestorGroupName =
        Resolve-Template `
            -Template $Config.RequestorGroups.DisplayNameTemplate `
            -Tokens $tokens

    $approverGroupName =
        Resolve-Template `
            -Template $Config.ApproverGroups.DisplayNameTemplate `
            -Tokens $tokens

    Write-Log -Message "Policy Name: $policyName"

    $requestorGroup =
        Get-RequestorGroup `
            -DisplayName $requestorGroupName

    if (-not $requestorGroup) {

        return @{
            Action = "Failed"
            Status = "Failed"
            Message = "Requestor group not found"
            PolicyId = ""
        }
    }

    $approverGroup =
        Get-ApproverGroup `
            -DisplayName $approverGroupName

    if (-not $approverGroup) {

        return @{
            Action = "Failed"
            Status = "Failed"
            Message = "Approver group not found"
            PolicyId = ""
        }
    }

    $policies =
        Get-AccessPackagePolicy `
            -AccessPackageId $AccessPackageId

    if (($policies | Measure-Object).Count -gt 1) {

        return @{
            Action = "Failed"
            Status = "Failed"
            Message = "Multiple policies found for Access Package"
            PolicyId = ""
        }
    }

    $policyDefinition =
        New-AccessPackagePolicyDefinition `
            -PolicyName $policyName `
            -PolicyDescription $policyDescription `
            -AccessPackageId $AccessPackageId `
            -RequestorGroupId $requestorGroup.Id `
            -ApproverGroupId $approverGroup.Id `
            -Config $Config

    if (($policies | Measure-Object).Count -eq 0) {

        if ($Simulate) {

            return @{
                Action = "Simulated"
                Status = "Success"
                Message = "Would create policy"
                PolicyId = ""
            }
        }

        $newPolicy =
            Add-AccessPackagePolicy `
                -PolicyDefinition $policyDefinition

        return @{
            Action = "Added"
            Status = "Success"
            Message = "Policy created"
            PolicyId = $newPolicy.Id
        }
    }

    $existingPolicy = $policies[0]

    if ($existingPolicy.DisplayName -ne $policyName) {

        return @{
            Action = "Failed"
            Status = "Failed"
            Message = "Existing policy name does not match expected template"
            PolicyId = $existingPolicy.Id
        }
    }

    if ($Simulate) {

        return @{
            Action = "Simulated"
            Status = "Success"
            Message = "Would update policy"
            PolicyId = $existingPolicy.Id
        }
    }

    Update-AccessPackagePolicy `
        -PolicyId $existingPolicy.Id `
        -PolicyDefinition $policyDefinition

    return @{
        Action = "Updated"
        Status = "Success"
        Message = "Policy updated"
        PolicyId = $existingPolicy.Id
    }
}