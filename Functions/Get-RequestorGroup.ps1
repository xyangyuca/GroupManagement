function Get-RequestorGroup {

    param(
        [string]$DisplayName
    )

    Get-MgGroup `
        -Filter "displayName eq '$DisplayName'"
}