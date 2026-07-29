function Get-SecurityGroups {

    param(
        [string]$Environment,
        [string]$PartnerFiler,
        [string]$Release,
        $Config
    )

    Write-Log -Message "Loading security groups from database." -Level Info

    $token = Get-SqlAccessToken -Config $Config

    $query = @"SELECT DISTINCT
       sg.FullGroupName,
       sg.[Group],
       sg.Organization
FROM col_data.SecurityGroups sg
WHERE sg.Environment = '$Environment'
  AND sg.[PartnerOrPortalGroup] = '$PartnerFiler'
  AND sg.IsDeletedInd = 0
  ORDER BY sg.FullGroupName
"@

    # Release intentionally retained for future use.
    # AND sgp.Release = '$Release'

   

    $rows = Invoke-Sqlcmd -ServerInstance $Config.DBServer -Database $Config.Database -AccessToken $token.AccessToken -Query $query

    foreach ($group in $rows) {

        [PSCustomObject]@{
            Code      = $group.Organization
            GroupName = $group.FullGroupName
            Desc      = ""
            GroupType = "Database"
        }
    }
}