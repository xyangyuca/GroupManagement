function Remove-EntraGroups {

    param(
        [array]$Groups,
        [bool]$Simulate = $true
    )

    $results = @()

    foreach ($group in $Groups) {

        Write-Log `
            -Message "Processing delete for [$($group.GroupName)]" `
            -Level Info

        try {

            if ($Simulate) {

                $results += [PSCustomObject]@{
                    Name      = $group.GroupName
                    ID        = $group.EntraGroupObjectId
                    Result    = "Simulated"
                    Reason    = ""
                    GroupType = $group.GroupType
                }

                continue
            }

            if ($group.EntraGroupObjectId) {

                Remove-MgGroup `
                    -GroupId $group.EntraGroupObjectId `
                    -ErrorAction Stop

                Write-Log `
                    -Message "Deleted group [$($group.GroupName)] using ObjectId." `
                    -Level Info
            }
            else {

                Write-Log `
                    -Message "ObjectId missing. Looking up Entra group by DisplayName." `
                    -Level Warning

                $entraGroup = Get-MgGroup `
                    -Filter "displayName eq '$($group.GroupName)'"

                if (-not $entraGroup) {
                    throw "Group not found in Entra."
                }

                Remove-MgGroup `
                    -GroupId $entraGroup.Id `
                    -ErrorAction Stop

                Write-Log `
                    -Message "Deleted group [$($group.GroupName)] using DisplayName lookup." `
                    -Level Info
            }

            $results += [PSCustomObject]@{
                Name      = $group.GroupName
                ID        = $group.EntraGroupObjectId
                Result    = "Success"
                Reason    = ""
                GroupType = $group.GroupType
            }
        }
        catch {

            Write-Log `
                -Message "Failed to delete [$($group.GroupName)]. $_" `
                -Level Error

            $results += [PSCustomObject]@{
                Name      = $group.GroupName
                ID        = $group.EntraGroupObjectId
                Result    = "Failed"
                Reason    = $_.Exception.Message
                GroupType = $group.GroupType
            }
        }
    }

    return $results
}