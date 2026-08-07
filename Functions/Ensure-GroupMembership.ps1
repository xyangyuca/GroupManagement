function Ensure-GroupMembership {

    param(
        [Parameter(Mandatory)]
        [string]$TargetGroupName,

        [Parameter(Mandatory)]
        [string]$TargetGroupId,

        [Parameter(Mandatory)]
        [string]$MemberGroupId,

        [Parameter(Mandatory)]
        [string]$MemberGroupName,

        [Parameter(Mandatory)]
        [bool]$Simulate
    )

    try {

        $existingMember =
            Get-MgGroupMember `
                -GroupId $TargetGroupId `
                -All |
            Where-Object {
                $_.Id -eq $MemberGroupId
            }

        if ($existingMember) {

            return [PSCustomObject]@{
                TargetGroup        = $TargetGroupName
                FullGroupName      = $MemberGroupName
                EntraGroupObjectId = $MemberGroupId
                Action             = 'Skipped'
                Status             = 'AlreadyMember'
                Message            = 'Group already a member'
            }
        }

        if ($Simulate) {

            return [PSCustomObject]@{
                TargetGroup        = $TargetGroupName
                FullGroupName      = $MemberGroupName
                EntraGroupObjectId = $MemberGroupId
                Action             = 'Simulated'
                Status             = 'Success'
                Message            = 'Would add group membership'
            }
        }

        New-MgGroupMemberByRef `
            -GroupId $TargetGroupId `
            -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$MemberGroupId"
            }

        return [PSCustomObject]@{
            TargetGroup        = $TargetGroupName
            FullGroupName      = $MemberGroupName
            EntraGroupObjectId = $MemberGroupId
            Action             = 'Added'
            Status             = 'Success'
            Message            = ''
        }

    }
    catch {

        return [PSCustomObject]@{
            TargetGroup        = $TargetGroupName
            FullGroupName      = $MemberGroupName
            EntraGroupObjectId = $MemberGroupId
            Action             = 'Failed'
            Status             = 'Error'
            Message            = $_.Exception.Message
        }
    }
}