function Get-CatalogGroups {

    param(
        [string]$Environment,
        [string]$PartnerFile,
        $Config
    )

    Write-Log -Message "Loading security groups from database." -Level Info

    $token = Get-SqlAccessToken -Config $Config
   
    $Query = @"
SELECT
    sg.FullGroupName,
    map.EntraGroupObjectId
FROM
    col_data.SecurityGroups sg
        INNER JOIN
    col_data.SecurityGroupEntraMapping map
        ON sg.FullGroupName = map.FullGroupName
WHERE
        sg.Environment = '$Environment'
    AND sg.PartnerOrPortalGroup = '$PartnerFile'
    AND sg.IsDeletedInd = 0
    AND map.IsDeletedInd = 0
    AND map.EntraGroupObjectId IS NOT NULL
"@

    Invoke-Sqlcmd `
        -ServerInstance $Config.DBServer `
        -Database $Config.Database `
        -AccessToken $token.AccessToken `
        -Query $Query

    Write-Log -Message "Loaded security groups from database." -Level Info
}