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

Import-Module MSAL.PS
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Groups
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
. "$PSScriptRoot\Functions\Ensure-AppRoleAssignment.ps1"

$config = Get-AppConfig

$runId =
    "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$logFile =
    "$PSScriptRoot\Logs\AppRegGroupManagement_$runId.log"

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

    $appRoleId = $null

    if ($servicePrincipal.AppRoles -and
        $servicePrincipal.AppRoles.Count -gt 0) {

        $defaultRole =
            $servicePrincipal.AppRoles |
            Where-Object {
                $_.Value -eq "" -or
                $_.DisplayName -eq "Default Access"
            } |
            Select-Object -First 1

        if ($defaultRole) {
            $appRoleId = $defaultRole.Id
        }
        else {
            $appRoleId = $servicePrincipal.AppRoles[0].Id
        }

        Write-Log `
            -Message "Using App Role [$appRoleId]" `
            -Level Info
    }
    else {

        $appRoleId =
            "00000000-0000-0000-0000-000000000000"

        Write-Log `
            -Message "Using Default Access role." `
            -Level Info
    }

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
            Ensure-AppRoleAssignment `
                -ApplicationName $AppName `
                -ServicePrincipalId $servicePrincipal.Id `
                -AppRoleId $appRoleId `
                -GroupId $group.EntraGroupObjectId `
                -GroupName $group.FullGroupName `
                -Simulate $Simulate

        $results += $result
    }

    $outputCsv =
        "$PSScriptRoot\Output\AppRegGroupManagement_$runId.csv"

    $results |
        Export-Csv `
            -Path $outputCsv `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Log `
        -Message "Results written to $outputCsv" `
        -Level Success

    $Added =
        ($results |
            Where-Object {
                $_.Action -eq 'Added'
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

Application Registration Group Assignment Summary

Application: $AppName

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