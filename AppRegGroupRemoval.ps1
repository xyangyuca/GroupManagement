param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler,

    [Parameter(Mandatory)]
    [string]$AppName,

    [bool]$Simulate = $true
)

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Groups
Import-Module SqlServer

# Common

. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# Helpers

. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

# Functions

. "$PSScriptRoot\Functions\Get-CatalogGroups.ps1"
. "$PSScriptRoot\Functions\Ensure-AppRoleRemoval.ps1"

$config = Get-AppConfig

$runId =
    "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$logFile =
    "$PSScriptRoot\Logs\AppRegGroupRemoval_$runId.log"

try {

    Connect-GraphSessionSecret `
        $config.tenantId `
        $config.clientId `
        $config.secrectValue

    Write-Log `
        -Message "Searching for Enterprise Application [$AppName]" `
        -Level Info

    $servicePrincipal =
        Get-MgServicePrincipal `
            -Filter "displayName eq '$AppName'"

    if (-not $servicePrincipal) {
        throw "Enterprise Application [$AppName] not found."
    }

    if ($servicePrincipal.Count -gt 1) {
        throw "Multiple Enterprise Applications found named [$AppName]."
    }

    Write-Log `
        -Message "Found Enterprise Application [$AppName]" `
        -Level Success

    $groups =
        Get-CatalogGroups `
            -Environment $Environment `
            -PartnerFile $PartnerFiler `
            -Config $config

    Write-Log `
        -Message "Retrieved [$($groups.Count)] groups from SQL." `
        -Level Info

    $results = @()

    foreach ($group in $groups) {

        $result =
            Ensure-AppRoleRemoval `
                -ApplicationName $AppName `
                -ServicePrincipalId $servicePrincipal.Id `
                -GroupId $group.EntraGroupObjectId `
                -GroupName $group.FullGroupName `
                -Simulate $Simulate

        $results += $result
    }

    $outputCsv =
        "$PSScriptRoot\Output\AppRegGroupRemoval_$runId.csv"

    $results |
        Export-Csv `
            -Path $outputCsv `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Log `
        -Message "Results written to $outputCsv" `
        -Level Success

    $Removed =
        ($results |
            Where-Object {
                $_.Action -eq 'Removed'
            }).Count

    $Skipped =
        ($results |
            Where-Object {
                $_.Action -eq 'Skipped'
            }).Count

    $Failed =
        ($results |
            Where-Object {
                $_.Action -eq 'Failed'
            }).Count

    $Simulated =
        ($results |
            Where-Object {
                $_.Action -eq 'Simulated'
            }).Count

    Write-Log -Message "

Application Registration Group Removal Summary

Application: $AppName

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