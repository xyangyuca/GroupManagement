param(
    [string]$Environment,
    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler,
    [bool]$Simulate = $true
)
Import-Module MSAL.PS
Import-Module SqlServer

# Common
. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# Existing helpers
. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

. "$PSScriptRoot\Functions\Add-CatalogResource.ps1"
. "$PSScriptRoot\Functions\Get-CatalogResource.ps1"
. "$PSScriptRoot\Functions\Ensure-Catalog.ps1"
. "$PSScriptRoot\Functions\Get-CatalogGroups.ps1"
. "$PSScriptRoot\Functions\Ensure-CatalogResource.ps1"

$config = Get-AppConfig

$runId = "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$logFile = "$PSScriptRoot\Logs\CatalogManagement_$runId.log"

$clientId = $config.clientId

try {

    Connect-GraphSessionSecret $config.tenantId $config.clientId $config.secrectValue

    $CatalogName = $config.Catalogs.DisplayNameTemplate.Replace("{Environment}", $Environment).Replace("{PartnerFiler}", $PartnerFiler)

    $CatalogDescription = $config.Catalogs.DescriptionTemplate.Replace("{Environment}", $Environment).Replace("{PartnerFiler}", $PartnerFiler)

    Write-Log -Message "Catalog Name:$CatalogName" -Level Info
    Write-Log -Message "Catalog Description:$CatalogDescription" -Level Info

    $Catalog = Ensure-Catalog -DisplayName $CatalogName -Description $CatalogDescription -Simulate $Simulate
    Write-Log -Message "ClientId:$clientId" -Level Info
    $Groups = Get-CatalogGroups -Environment $Environment -PartnerFile $PartnerFiler -Config $config

    $results = @()
    
    foreach ($Group in $Groups) {

        $result = Ensure-CatalogResource `
            -CatalogId $Catalog.Id `
            -CatalogName $CatalogName `
            -GroupId $Group.EntraGroupObjectId `
            -GroupName $Group.FullGroupName `
            -Simulate $Simulate

        $results += $result
    }

    $outputCsv = "$PSScriptRoot\Output\CatalogManagementResults_$runId.csv"

    $results |  
        Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

    Write-Log -Message "Results written to $outputCsv" -Level Success

    $Added =
    ($results | Where-Object {$_.Action -eq 'Added'}).Count

    $Skipped =
    ($results | Where-Object {$_.Action -eq 'Skipped'}).Count

    $Failed =
    ($results | Where-Object {$_.Action -eq 'Failed'}).Count

    $Simulated =
    ($results | Where-Object {$_.Action -eq 'Simulated'}).Count

    Write-Log -Message "

    Catalog Management Summary

    Catalog: $CatalogName

    Added:      $Added
    Skipped:    $Skipped
    Failed:     $Failed
    Simulated:  $Simulated

    Output File: $outputCsv" -Level Info
}
finally {

            Disconnect-MgGraph
}