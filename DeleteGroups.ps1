param(
    [string]$Environment,
    [string]$Release = "",
    [bool]$Simulate = $true
)

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

Import-Module MSAL.PS
Import-Module SqlServer

# Common
. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# Existing helpers
. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

# New functions
. "$ScriptRoot\Functions\Get-DeletedSecurityGroups.ps1"
. "$ScriptRoot\Functions\Remove-EntraGroups.ps1"
. "$ScriptRoot\Functions\Update-DeletedGroupMappings.ps1"

$runId = "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$logFile = "$PSScriptRoot\Logs\DeleteGroupProcess_$runId.log"

$config = Get-AppConfig



Write-Log `
    -Message "Starting delete process. Environment=[$Environment] Simulate=[$Simulate]" `
    -Level Info

$groups = Get-DeletedSecurityGroups `
    -Environment $Environment `
    -Release $Release `
    -Config $config

Write-Log `
    -Message "Found $($groups.Count) deleted groups." `
    -Level Info
Connect-GraphSessionSecret $config.tenantId $config.clientId $config.secrectValue
$results = Remove-EntraGroups `
    -Groups $groups `
    -Simulate $Simulate

if (-not $Simulate) {

    foreach ($result in $results | Where-Object Result -eq "Success") {

        Update-DeletedGroupMappings -GroupName $result.Name -Config $config
    }
}

#$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$outputPath = Join-Path `
    $ScriptRoot `
    "Output\DeletedGroups_$runId.csv"

$results |
    Export-Csv `
        -Path $outputPath `
        -NoTypeInformation

Write-Log `
    -Message "Delete process complete. Output written to [$outputPath]" `
    -Level Info