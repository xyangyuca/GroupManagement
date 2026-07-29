function Update-GroupMappings {

    param(
        [array]$Results,
        $Config
    )

    $token = Get-SqlAccessToken -Config $Config

    foreach ($record in $Results) {

        if ($record.Result -ne "Success") {
            continue
        }

        if ($record.ID -eq "SIMULATED") {
            continue
        }

        $groupName = $record.Name.Replace("'","''")
        $groupId = $record.ID

        $query = @"
IF EXISTS
(
    SELECT 1
    FROM col_data.SecurityGroupEntraMapping
    WHERE FullGroupName = '$groupName'
)
BEGIN

    UPDATE col_data.SecurityGroupEntraMapping
    SET
        EntraGroupObjectId = '$groupId',
        IsDeletedInd = 0,
        modified_datetime = GETUTCDATE()
    WHERE FullGroupName = '$groupName'

END
ELSE
BEGIN

    INSERT INTO col_data.SecurityGroupEntraMapping
    (
        FullGroupName,
        EntraGroupObjectId,
        IsDeletedInd,
        created_datetime,
        modified_datetime
    )
    VALUES
    (
        '$groupName',
        '$groupId',
        0,
        GETUTCDATE(),
        GETUTCDATE()
    )

END
"@

        try {

            Invoke-Sqlcmd `
                -ServerInstance $Config.DBServer `
                -Database $Config.Database `
                -AccessToken $token.AccessToken `
                -Query $query `
                -ErrorAction Stop

            Write-Log `
                -Message "Mapping updated: $groupName" `
                -Level Success

        }
        catch {

            Write-Log `
                -Message "Failed mapping update: $groupName $_" `
                -Level Error

        }
    }
}