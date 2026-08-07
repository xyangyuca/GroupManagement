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

# Common

. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# Helpers

. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

# Functions

. "$PSScriptRoot\Functions\Get-CatalogGroups.ps1"
. "$PSScriptRoot\Functions\Ensure-GroupMembership.ps1"

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

    $results = @()

    foreach ($group in $groups) {

        $result =
            Ensure-GroupMembership `
                -TargetGroupName $TargetGroupName `
                -TargetGroupId $targetGroup.Id `
                -MemberGroupId $group.EntraGroupObjectId `
                -MemberGroupName $group.FullGroupName `
                -Simulate $Simulate

        $results += $result
    }

    $outputCsv =
        "$PSScriptRoot\Output\GroupMembershipManagement_$runId.csv"

    $results |
        Export-Csv `
            -Path $outputCsv `
            -NoTypeInformation `
            -Encoding UTF8

    $Added =
        ($results | Where-Object {
            $_.Action -eq 'Added'
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

Group Membership Summary

Target Group: $TargetGroupName

Added:      $Added
Skipped:    $Skipped
Failed:     $Failed
Simulated:  $Simulated

Output File: $outputCsv

" -Level Info
}
finally {
    Disconnect-MgGraph
}