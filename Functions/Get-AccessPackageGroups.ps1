function Get-AccessPackageGroups {
    param(
        [string]$Environment,
        [string]$PartnerFiler,
        [object]$Config
    )

    Write-Log -Message "Loading security groups from database." -Level Info

    $token = Get-SqlAccessToken -Config $Config
   
    $query = "
    SELECT sg.Organization,
            sg.[Group],
            sg.FullGroupName,
            map.EntraGroupObjectId
        FROM col_data.SecurityGroups sg
        INNER JOIN col_data.SecurityGroupEntraMapping map
            ON sg.FullGroupName = map.FullGroupName
        WHERE sg.Environment = '$Environment'
            AND sg.PartnerOrPortalGroup = '$PartnerFiler'
        "

    Invoke-Sqlcmd -ServerInstance $Config.DBServer -Database $Config.Database -AccessToken $token.AccessToken -Query $query
}