function Add-CatalogResource {

    param(
        [Parameter(Mandatory)]
        [string]$CatalogId,

        [Parameter(Mandatory)]
        [string]$GroupId
    )

    $body = @{
        requestType = "adminAdd"

        catalog = @{
            id = $CatalogId
        }

        resource = @{
            originId     = $GroupId
            originSystem = "AadGroup"
        }
    }

    New-MgEntitlementManagementResourceRequest -BodyParameter $body
}
