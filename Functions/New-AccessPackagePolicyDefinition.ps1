function New-AccessPackagePolicyDefinition {

    param(
        [string]$PolicyName,

        [string]$PolicyDescription,

        [string]$AccessPackageId,

        [string]$RequestorGroupId,

        [string]$ApproverGroupId,

        [object]$Config
    )

    return @{
        displayName = $PolicyName

        description = $PolicyDescription

        notificationSettings = @{
            isAssignmentNotificationDisabled =
                $Config.AccessPackagePolicies.AssignmentNotificationsDisabled
        }

        allowedTargetScope = "specificDirectoryUsers"

        specificAllowedTargets = @(
            @{
                "@odata.type" = "#microsoft.graph.groupMembers"
                groupId = $RequestorGroupId
            }
        )

        requestorSettings = @{
            enableTargetsToSelfAddAccess            = $true
            enableTargetsToSelfUpdateAccess         = $true
            enableTargetsToSelfRemoveAccess         = $false
            allowCustomAssignmentSchedule           = $false
            enableOnBehalfRequestorsToAddAccess     = $false
            enableOnBehalfRequestorsToUpdateAccess  = $false
            enableOnBehalfRequestorsToRemoveAccess  = $false
            onBehalfRequestors                      = @()
        }

        requestApprovalSettings = @{
            isApprovalRequiredForAdd =
                $Config.AccessPackagePolicies.IsApprovalRequiredForAdd

            isApprovalRequiredForUpdate =
                $Config.AccessPackagePolicies.IsApprovalRequiredForUpdate

            isRequestorJustificationRequired =
                $Config.AccessPackagePolicies.IsRequestorJustificationRequired

            stages = @(
                @{
                    durationBeforeAutomaticDenial =
                        $Config.AccessPackagePolicies.ApprovalDuration

                    isApproverJustificationRequired = $false

                    isEscalationEnabled             = $false

                    durationBeforeEscalation        = "PT0S"

                    primaryApprovers = @(
                        @{
                            "@odata.type" =
                                "#microsoft.graph.groupMembers"

                            groupId = $ApproverGroupId
                        }
                    )

                    fallbackPrimaryApprovers    = @()
                    escalationApprovers         = @()
                    fallbackEscalationApprovers = @()
                }
            )
        }

        expiration = @{
            type     = "afterDuration"
            duration = $Config.AccessPackagePolicies.ExpirationDuration
        }

        accessPackage = @{
            id = $AccessPackageId
        }
    }
}