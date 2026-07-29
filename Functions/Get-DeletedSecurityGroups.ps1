function Get-DeletedSecurityGroups {

    param(
        [string]$Environment,
        [string]$Release,
        $Config
    )

    Write-Log -Message "Loading deleted security groups from database." -Level Info

    $token = Get-SqlAccessToken -Config $Config

    $query = @"
SELECT DISTINCT
       sg.FullGroupName,
       sg.Organization,
       map.EntraGroupObjectId
FROM col_data.SecurityGroups sg
LEFT JOIN col_data.SecurityGroupEntraMapping map
    ON sg.FullGroupName = map.FullGroupName
WHERE sg.Environment = '$Environment'
  AND sg.IsDeletedInd = 1
  AND ISNULL(map.IsDeletedInd,0) = 0
ORDER BY sg.FullGroupName
"@

    $rows = Invoke-Sqlcmd `
        -ServerInstance $Config.DBServer `
        -Database $Config.Database `
        -AccessToken $token.AccessToken `
        -Query $query

    foreach ($group in $rows) {

        [PSCustomObject]@{
            Code               = $group.Organization
            GroupName          = $group.FullGroupName
            EntraGroupObjectId = $group.EntraGroupObjectId
            GroupType          = "Database"
        }
    }
}