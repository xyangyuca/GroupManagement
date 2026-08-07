function Ensure-GroupMembershipRemoval {

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

        if (-not $existingMember) {

            return [PSCustomObject]@{
                TargetGroup        = $TargetGroupName
                FullGroupName      = $MemberGroupName
                EntraGroupObjectId = $MemberGroupId
                Action             = 'Skipped'
                Status             = 'NotMember'
                Message            = 'Group is not a member of target group'
            }
        }

        if ($Simulate) {

            return [PSCustomObject]@{
                TargetGroup        = $TargetGroupName
                FullGroupName      = $MemberGroupName
                EntraGroupObjectId = $MemberGroupId
                Action             = 'Simulated'
                Status             = 'Success'
                Message            = 'Would remove group membership'
            }
        }

        Remove-MgGroupMemberByRef `
            -GroupId $TargetGroupId `
            -DirectoryObjectId $MemberGroupId `
            -ErrorAction Stop

        return [PSCustomObject]@{
            TargetGroup        = $TargetGroupName
            FullGroupName      = $MemberGroupName
            EntraGroupObjectId = $MemberGroupId
            Action             = 'Removed'
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