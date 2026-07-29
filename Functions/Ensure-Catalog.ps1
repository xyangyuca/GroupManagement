function Ensure-Catalog {

    param(
        [string]$DisplayName,
        [string]$Description,
        [bool]$Simulate
    )

    $Catalog = Get-MgEntitlementManagementCatalog `
        -Filter "displayName eq '$DisplayName'"

    if ($Catalog) {

        #Write-Host "Catalog exists:$DisplayName"

        Write-Log -Message "Catalog [$DisplayName] already exists." -Level Info

        return $Catalog
    }

    if ($Simulate) {

        #Write-Host "SIMULATION:Would create catalog:$DisplayName"
        Write-Log -Message "SIMULATION - Would create catalog [$DisplayName]" -Level Info
        return [PSCustomObject]@{
            Id = "SIMULATION"
            DisplayName = $DisplayName
        }
    }

    #Write-Host "Creating catalog:$DisplayName"
    Write-Log -Message "Catalog [$DisplayName] created."  -Level Success
    #return New-MgEntitlementManagementCatalog -DisplayName $DisplayName -Description $Description -IsExternallyVisible $true
    return New-MgEntitlementManagementCatalog -BodyParameter @{
                displayName         = $DisplayName
                description         = $Description
                isExternallyVisible = $true
            }

}