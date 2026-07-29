function Update-DeletedGroupMappings {

    param(
        [string]$GroupName,
        $Config
    )

    Write-Log `
        -Message "Marking mapping record as deleted for [$GroupName]" `
        -Level Info

    $token = Get-SqlAccessToken -Config $Config

    $query = @"
UPDATE col_data.SecurityGroupEntraMapping
SET
    IsDeletedInd = 1,
    modified_datetime = GETUTCDATE()
WHERE FullGroupName = '$GroupName'
"@

    Invoke-Sqlcmd `
        -ServerInstance $Config.DBServer `
        -Database $Config.Database `
        -AccessToken $token.AccessToken `
        -Query $query

    Write-Log `
        -Message "Mapping record updated for [$GroupName]" `
        -Level Info
}