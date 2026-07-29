function Ensure-CatalogResource_Obsolete {

    param(
        [string]$CatalogId,
        [string]$GroupId,
        [string]$GroupName,
        [bool]$Simulate
    )

    $Existing = Get-MgEntitlementManagementCatalogResource `
        -AccessPackageCatalogId $CatalogId `
        -All |
        Where-Object {
            $_.OriginSystem -eq "AadGroup" -and
            $_.OriginId -eq $GroupId
        }

    if ($Existing) {

        Write-Host "Group already exists:$GroupName"

        return
    }

    if ($Simulate) {

        Write-Host "SIMULATION:Would add group:$GroupNameto catalog.
"

        return
    }

    $Body = @{
        requestType = "adminAdd"
        catalog = @{
            id = $CatalogId
        }
        resource = @{
            originId = $GroupId
            originSystem = "AadGroup"
        }
    }

    New-MgEntitlementManagementResourceRequest `
        -BodyParameter $Body

    Write-Host "Added:$GroupName"
}


function Ensure-CatalogResource {

    param(
        [string]$CatalogId,
        [string]$CatalogName,
        [string]$GroupId,
        [string]$GroupName,
        [bool]$Simulate
    )

    try {

        $Existing =
            Get-CatalogResource `
                -CatalogId $CatalogId `
                -GroupId $GroupId

        if ($Existing) {

            return [PSCustomObject]@{
                CatalogName        = $CatalogName
                FullGroupName      = $GroupName
                EntraGroupObjectId = $GroupId
                Action             = 'Skipped'
                Status             = 'AlreadyExists'
                Message            = 'Resource already exists in catalog'
            }
        }

        if ($Simulate) {

            return [PSCustomObject]@{
                CatalogName        = $CatalogName
                FullGroupName      = $GroupName
                EntraGroupObjectId = $GroupId
                Action             = 'Simulated'
                Status             = 'Success'
                Message            = 'Would add catalog resource'
            }
        }

        $Added = Add-CatalogResource -CatalogId $CatalogId -GroupId $GroupId

        return [PSCustomObject]@{
            CatalogName        = $CatalogName
            FullGroupName      = $GroupName
            EntraGroupObjectId = $GroupId
            Action             = 'Added'
            Status             = 'Success'
            Message            = ''
        }
    }
    catch {

        return [PSCustomObject]@{
            CatalogName        = $CatalogName
            FullGroupName      = $GroupName
            EntraGroupObjectId = $GroupId
            Action             = 'Failed'
            Status             = 'Error'
            Message            = $_.Exception.Message
        }
    }
}