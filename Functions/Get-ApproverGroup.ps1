function Get-ApproverGroup {

    param(
        [string]$DisplayName
    )

    Get-MgGroup `
        -Filter "displayName eq '$DisplayName'"
}