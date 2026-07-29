function New-EntraGroups {

    param(
        [array]$Groups,
        [bool]$Simulate = $true
    )

    Write-Log -Message "Loading existing Entra groups." -Level Info

    $existingGroups =
        Get-MgGroup -All |
        Select-Object -ExpandProperty DisplayName

    $results = @()

    foreach ($row in $Groups) {

        $groupName = $row.GroupName.Trim()
        $code = $row.Code.Trim()

        if ($existingGroups -contains $groupName) {

            $results += [PSCustomObject]@{
                Name   = $groupName
                ID     = ""
                Result = "Skipped"
                Reason = "Already Exists"
                GroupType = $row.GroupType
            }

            continue
        }

        $mailNickname = (
            $groupName -replace '[^a-zA-Z0-9]',''
        ).ToLower()

        if ($mailNickname.Length -gt 64) {
            $mailNickname =
                $mailNickname.Substring(0,64)
        }

        if ($Simulate) {

            $results += [PSCustomObject]@{
                Name   = $groupName
                ID     = "SIMULATED"
                Result = "Success"
                Reason = ""
                GroupType = $row.GroupType
            }

            continue
        }

        try {

            $newGroup = New-MgGroup `
                -DisplayName $groupName `
                -MailEnabled:$false `
                -SecurityEnabled:$true `
                -MailNickname $mailNickname `
                -ErrorAction Stop

            $results += [PSCustomObject]@{
                Name   = $groupName
                ID     = $newGroup.Id
                Result = "Success"
                Reason = ""
                GroupType = $row.GroupType
            }

        }
        catch {

            $results += [PSCustomObject]@{
                Name   = $groupName
                ID     = ""
                Result = "Failed"
                Reason = $_.Exception.Message
                GroupType = $row.GroupType
            }

        }

    }

    return $results
}