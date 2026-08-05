function Ensure-AppRoleAssignment {

    param(
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        [Parameter(Mandatory)]
        [string]$ServicePrincipalId,

        [Parameter(Mandatory)]
        [string]$AppRoleId,

        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [bool]$Simulate
    )

    try {

        $existingAssignment =
            Get-MgServicePrincipalAppRoleAssignedTo `
                -ServicePrincipalId $ServicePrincipalId `
                -All |
            Where-Object {
                $_.PrincipalId -eq $GroupId
            }

        if ($existingAssignment) {

            return [PSCustomObject]@{
                ApplicationName   = $ApplicationName
                FullGroupName     = $GroupName
                EntraGroupObjectId= $GroupId
                Action            = 'Skipped'
                Status            = 'AlreadyAssigned'
                Message           = 'Group already assigned to application'
            }
        }

        if ($Simulate) {

            return [PSCustomObject]@{
                ApplicationName   = $ApplicationName
                FullGroupName     = $GroupName
                EntraGroupObjectId= $GroupId
                Action            = 'Simulated'
                Status            = 'Success'
                Message           = 'Would assign group to application'
            }
        }

        $params = @{
            PrincipalId = $GroupId
            ResourceId  = $ServicePrincipalId
            AppRoleId   = $AppRoleId
        }

        New-MgServicePrincipalAppRoleAssignedTo `
            -ServicePrincipalId $ServicePrincipalId `
            -BodyParameter $params `
            -ErrorAction Stop

        return [PSCustomObject]@{
            ApplicationName   = $ApplicationName
            FullGroupName     = $GroupName
            EntraGroupObjectId= $GroupId
            Action            = 'Added'
            Status            = 'Success'
            Message           = ''
        }

    }
    catch {

        return [PSCustomObject]@{
            ApplicationName   = $ApplicationName
            FullGroupName     = $GroupName
            EntraGroupObjectId= $GroupId
            Action            = 'Failed'
            Status            = 'Error'
            Message           = $_.Exception.Message
        }
    }
}