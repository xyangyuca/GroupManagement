function Ensure-AppRoleRemoval {

    param(
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        [Parameter(Mandatory)]
        [string]$ServicePrincipalId,

        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [bool]$Simulate
    )

    try {

        $assignments =
            Get-MgServicePrincipalAppRoleAssignedTo `
                -ServicePrincipalId $ServicePrincipalId `
                -All |
            Where-Object {
                $_.PrincipalId -eq $GroupId
            }

        if (-not $assignments) {

            return [PSCustomObject]@{
                ApplicationName    = $ApplicationName
                FullGroupName      = $GroupName
                EntraGroupObjectId = $GroupId
                Action             = 'Skipped'
                Status             = 'NotAssigned'
                Message            = 'Group not assigned to application'
            }
        }

        if ($Simulate) {

            return [PSCustomObject]@{
                ApplicationName    = $ApplicationName
                FullGroupName      = $GroupName
                EntraGroupObjectId = $GroupId
                Action             = 'Simulated'
                Status             = 'Success'
                Message            = 'Would remove group from application'
            }
        }

        foreach ($assignment in $assignments) {

            Remove-MgServicePrincipalAppRoleAssignedTo `
                -ServicePrincipalId $ServicePrincipalId `
                -AppRoleAssignmentId $assignment.Id `
                -ErrorAction Stop
        }

        return [PSCustomObject]@{
            ApplicationName    = $ApplicationName
            FullGroupName      = $GroupName
            EntraGroupObjectId = $GroupId
            Action             = 'Removed'
            Status             = 'Success'
            Message            = ''
        }
    }
    catch {

        return [PSCustomObject]@{
            ApplicationName    = $ApplicationName
            FullGroupName      = $GroupName
            EntraGroupObjectId = $GroupId
            Action             = 'Failed'
            Status             = 'Error'
            Message            = $_.Exception.Message
        }
    }
}
