param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$PartnerFiler,

    [Parameter(Mandatory = $false)]
    [string]$Release = "",

    [Parameter(Mandatory = $false)]
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

# New functions
. "$PSScriptRoot\Functions\Get-SecurityGroups.ps1"
. "$PSScriptRoot\Functions\New-EntraGroups.ps1"
. "$PSScriptRoot\Functions\Update-GroupMappings.ps1"
. "$PSScriptRoot\Functions\Get-TemplateGroups.ps1"

$config = Get-AppConfig

$runId = "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$logFile = "$PSScriptRoot\Logs\SecurityGroupProcess_$runId.log"

Write-Log -Message "Starting security group processing." -Level Info

#Connect-GraphSession $config.tenantId $config.clientId $config.thumbprint

Connect-GraphSessionSecret $config.tenantId $config.clientId $config.secrectValue


try {

    $groups = Get-SecurityGroups -Environment $Environment -PartnerFiler $PartnerFiler -Release $Release -Config $config

    #$templateGroups = Get-TemplateGroups -Groups $groups
    $templateGroups = Get-TemplateGroups -Groups $groups -PartnerFiler $PartnerFiler
    #$results = New-EntraGroups -Groups $groups -Simulate $Simulate

    $primaryResults = New-EntraGroups -Groups $groups -Simulate $Simulate

    #Update-GroupMappings -Results $primaryResults -Config $config

    if (-not $Simulate) {

    Update-GroupMappings -Results $primaryResults -Config $config
    }
        else {

        Write-Log `
        -Message "Simulation mode detected. Skipping SecurityGroupEntraMapping updates." `
        -Level Info
    }


    $templateResults = New-EntraGroups -Groups $templateGroups -Simulate $Simulate

    $outputCsv = "$PSScriptRoot\Output\SecurityGroupResults_$runId.csv"

    $results = @(
    	$primaryResults
    	$templateResults
	)

     $results |  
        Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

    Write-Log -Message "Results written to $outputCsv" -Level Success

}
finally {
    Disconnect-MgGraph
}