param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler,

    [Parameter(Mandatory)]
    [string]$TargetGroupName,

    [bool]$Simulate = $true
)

Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Authentication
Import-Module SqlServer

# ====================================
# COMMON
# ====================================

. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# ====================================
# HELPERS
# ====================================

. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

# ====================================
# FUNCTIONS
# ====================================

. "$PSScriptRoot\Functions\Get-CatalogGroups.ps1"
. "$PSScriptRoot\Functions\Ensure-GroupMembershipRemoval.ps1"

$config = Get-AppConfig

$runId =
    "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

try {

    Connect-GraphSessionSecret `
        $config.tenantId `
        $config.clientId `
        $config.secrectValue

    Write-Log `
        -Message "Searching for target group [$TargetGroupName]" `
        -Level Info

    $targetGroup =
        Get-MgGroup `
            -Filter "displayName eq '$TargetGroupName'"

    if (-not $targetGroup) {
        throw "Target group [$TargetGroupName] not found."
    }

    if ($targetGroup.Count -gt 1) {
        throw "Multiple groups found named [$TargetGroupName]."
    }

    $groups =
        Get-CatalogGroups `
            -Environment $Environment `
            -PartnerFile $PartnerFiler `
            -Config $config

    if (-not $groups) {
        throw "No groups returned from database."
    }

    Write-Log `
        -Message "Retrieved [$($groups.Count)] groups from SQL." `
        -Level Info

    $results = @()

    foreach ($group in $groups) {

        $result =
            Ensure-GroupMembershipRemoval `
                -TargetGroupName $TargetGroupName `
                -TargetGroupId $targetGroup.Id `
                -MemberGroupId $group.EntraGroupObjectId `
                -MemberGroupName $group.FullGroupName `
                -Simulate $Simulate

        $results += $result
    }

    $outputCsv =
        "$PSScriptRoot\Output\GroupMembershipRemoval_$runId.csv"

    $results |
        Export-Csv `
            -Path $outputCsv `
            -NoTypeInformation `
            -Encoding UTF8

    $Removed =
        ($results | Where-Object {
            $_.Action -eq 'Removed'
        }).Count

    $Skipped =
        ($results | Where-Object {
            $_.Action -eq 'Skipped'
        }).Count

    $Failed =
        ($results | Where-Object {
            $_.Action -eq 'Failed'
        }).Count

    $Simulated =
        ($results | Where-Object {
            $_.Action -eq 'Simulated'
        }).Count

    Write-Log -Message "

Group Membership Removal Summary

Target Group: $TargetGroupName

Removed:    $Removed
Skipped:    $Skipped
Failed:     $Failed
Simulated:  $Simulated

Output File: $outputCsv

" -Level Info
}
finally {

    Disconnect-MgGraph
}