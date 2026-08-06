param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler
)

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

# ====================================
# FUNCTIONS
# ====================================

. "$PSScriptRoot\Functions\Get-CatalogGroups.ps1"

$config = Get-AppConfig

$runId =
    "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

try {

    Write-Log `
        -Message "Retrieving groups from SQL." `
        -Level Info

    $groups =
        Get-CatalogGroups `
            -Environment $Environment `
            -PartnerFile $PartnerFiler `
            -Config $config

    if (-not $groups) {
        throw "No groups returned from database."
    }

    # ====================================
    # ENSURE DATA FOLDER EXISTS
    # ====================================

    $dataFolder = "$PSScriptRoot\Data"

    if (-not (Test-Path $dataFolder)) {

        New-Item `
            -ItemType Directory `
            -Path $dataFolder | Out-Null

        Write-Log `
            -Message "Created Data folder." `
            -Level Info
    }

    # ====================================
    # OUTPUT FILE
    # ====================================

    $outputFile =
        "$dataFolder\GroupExport_$runId.csv"

    $groups |
        Select-Object @{
            Name = "Code"
            Expression = { $_.Organization }
        },
        @{
            Name = "FullGroupName"
            Expression = { $_.FullGroupName }
        } |
        Export-Csv `
            -Path $outputFile `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Log `
        -Message "Output file written to: $outputFile" `
        -Level Success
}
catch {

    Write-Log `
        -Message $_.Exception.Message `
        -Level Error

    throw
}