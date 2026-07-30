function Ensure-AccessPackage {

    param(
        [object]$Row,

        [object]$Catalog,

        [string]$DisplayName,

        [string]$Description,

        [bool]$Simulate
    )

    #
    # Validate Catalog Resource
    #
    $catalogResource =
        Get-CatalogGroupResource `
            -CatalogId $Catalog.Id `
            -EntraGroupObjectId $Row.EntraGroupObjectId

    if (-not $catalogResource) {

        return @{
            Action          = "Failed"
            Status          = "Failed"
            PolicyEligible  = $false
            Message         = "Group resource not found in catalog"
            AccessPackageId = ""
        }
    }

    #
    # Get Member Role
    #
    $memberRole =
        Get-CatalogGroupMemberRole `
            -CatalogId $Catalog.Id `
            -CatalogResourceId $catalogResource.Id

    if (-not $memberRole) {

        return @{
            Action          = "Failed"
            Status          = "Failed"
            PolicyEligible  = $false
            Message         = "Member role not found"
            AccessPackageId = ""
        }
    }

    #
    # Lookup Access Package by Name
    #
    $existingPackage =
        Get-AccessPackage `
            -DisplayName $DisplayName

    if ($existingPackage) {

        #
        # Validate package belongs to expected catalog
        #

        #$localId = $existingPackage.Catalog.Id
        #$catId = $Catalog.Id
        #if ($existingPackage.Catalog.Id -ne $Catalog.Id) {
            #Write-Host "localId: $localId"
            #Write-Host "CatalogID: $catId"
            #return @{
            #    Action          = "Failed"
            #    Status          = "Failed"
            #    PolicyEligible  = $false
            #    Message         = "Access Package name exists in a different catalog"
            #    AccessPackageId = $existingPackage.Id
            #}
        #}

        #
        # Check whether the resource assignment already exists
        #
        $resourceAssigned =
            Test-AccessPackageResourceAssignment `
                -AccessPackageId $existingPackage.Id `
                -EntraGroupObjectId $Row.EntraGroupObjectId

        if ($resourceAssigned) {

            return @{
                Action          = "Skipped"
                Status          = "Success"
                PolicyEligible  = $true                
                Message         = "Access Package and Member assignment already exist"
                AccessPackageId = $existingPackage.Id
            }
        }

        #
        # Package exists but resource assignment doesn't
        #
        if ($Simulate) {

            return @{
                Action          = "Simulated"
                Status          = "Success"
                PolicyEligible  = $false
                Message         = "Would add Member assignment to existing Access Package"
                AccessPackageId = $existingPackage.Id
            }
        }

        $scope = $catalogResource.Scopes[0]

        $resourceParams = @{
            role = @{
                id           = $memberRole.Id
                displayName  = $memberRole.DisplayName
                description  = $memberRole.Description
                originId     = $memberRole.OriginId
                originSystem = "AadGroup"

                resource = @{
                    id           = $catalogResource.Id
                    originId     = $catalogResource.OriginId
                    originSystem = "AadGroup"
                    displayName  = $catalogResource.DisplayName
                }
            }

            scope = @{
                id           = $scope.Id
                displayName  = "Root"
                description  = "Root Scope"
                originId     = $catalogResource.OriginId
                originSystem = "AadGroup"
                isRootScope  = $true
            }
        }

        New-MgEntitlementManagementAccessPackageResourceRoleScope `
            -AccessPackageId $existingPackage.Id `
            -BodyParameter $resourceParams

        return @{
            Action          = "Updated"
            Status          = "Success"
            PolicyEligible  = $true
            Message         = "Member assignment added to existing Access Package"
            AccessPackageId = $existingPackage.Id
        }
    }

    #
    # Package does not exist
    #
    if ($Simulate) {

        return @{
            Action          = "Simulated"
            Status          = "Success"
            PolicyEligible  = $false
            Message         = "Would create Access Package"
            AccessPackageId = ""
        }
    }

    #
    # Create Access Package
    #
    $accessPackage =
        Add-AccessPackage `
            -DisplayName $DisplayName `
            -Description $Description `
            -CatalogId $Catalog.Id

    Start-Sleep -Seconds 10

    #
    # Assign Group Resource (Member)
    #
    $scope = $catalogResource.Scopes[0]

    $resourceParams = @{
        role = @{
            id           = $memberRole.Id
            displayName  = $memberRole.DisplayName
            description  = $memberRole.Description
            originId     = $memberRole.OriginId
            originSystem = "AadGroup"

            resource = @{
                id           = $catalogResource.Id
                originId     = $catalogResource.OriginId
                originSystem = "AadGroup"
                displayName  = $catalogResource.DisplayName
            }
        }

        scope = @{
            id           = $scope.Id
            displayName  = "Root"
            description  = "Root Scope"
            originId     = $catalogResource.OriginId
            originSystem = "AadGroup"
            isRootScope  = $true
        }
    }

    New-MgEntitlementManagementAccessPackageResourceRoleScope `
        -AccessPackageId $accessPackage.Id `
        -BodyParameter $resourceParams

    return @{
        Action          = "Added"
        Status          = "Success"
        PolicyEligible  = $true
        Message         = "Access Package created and Member role assigned"
        AccessPackageId = $accessPackage.Id
    }
}