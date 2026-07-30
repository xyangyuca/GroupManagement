param(
    [string]$Environment,

    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler,

    [bool]$Simulate = $true,
    [switch]$Cascade
)

# ==========================================
# LOAD DEPENDENCIES
# ==========================================

Import-Module MSAL.PS
Import-Module SqlServer

# ==========================================
# LOAD HELPERS / CORE
# ==========================================

# Common
. "$PSScriptRoot\Common\Config.ps1"
. "$PSScriptRoot\Common\SqlHelpers.ps1"

# Existing helpers
. "$PSScriptRoot\Helpers\LoggingHelpers.ps1"
. "$PSScriptRoot\Core\GraphCore.ps1"

. "$PSScriptRoot\Functions\Resolve-Template.ps1"
. "$PSScriptRoot\Functions\Get-Catalog.ps1"
. "$PSScriptRoot\Functions\Get-AccessPackagePolicies.ps1"
. "$PSScriptRoot\Functions\Get-AccessPackageGroups.ps1"
. "$PSScriptRoot\Functions\Get-AccessPackage.ps1"
. "$PSScriptRoot\Functions\Ensure-AccessPackageDeleted.ps1"



# ==========================================
# CONFIGURATION
# ==========================================

$config = Get-AppConfig

# ==========================================
# RUN ID
# ==========================================

$runId =
    "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ==========================================
# FOLDERS
# ==========================================

$logFolder =
    Join-Path $PSScriptRoot "Logs"

$outputFolder =
    Join-Path $PSScriptRoot "Output"

#New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
#New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null

# ==========================================
# FILES
# ==========================================

$logFile =
    Join-Path $logFolder `
        "AccessPackageDeletion_$runId.log"

$outputFile =
    Join-Path $outputFolder `
        "AccessPackageDeletionResults_$runId.csv"

# ======================================================
# RESULTS
# ======================================================

$results =
    [System.Collections.Generic.List[Object]]::new()

# ======================================================
# GRAPH
# ======================================================

Connect-GraphSessionSecret `
    $config.tenantId `
    $config.clientId `
    $config.secrectValue

try {

    Write-ExecutionLog "Starting Access Package Deletion"

    # ==================================================
    # RESOLVE CATALOG
    # ==================================================

    $catalog =
        Get-Catalog `
            -Environment $Environment `
            -PartnerFiler $PartnerFiler `
            -Config $config

    if (-not $catalog) {

        Write-ExecutionLog "Catalog not found. Exiting."

        $results.Add(
            [PSCustomObject]@{
                AccessPackageName  = ""
                CatalogName        = ""
                Organization       = ""
                Group              = ""
                FullGroupName      = ""
                EntraGroupObjectId = ""
                Action             = "Failed"
                Status             = "Failed"
                Message            = "Catalog not found"
                AccessPackageId    = ""
            }
        )

        $results |
            Export-Csv `
                -Path $outputFile `
                -NoTypeInformation `
                -Encoding UTF8

        return
    }

    Write-ExecutionLog "Catalog Found: $($catalog.DisplayName)"

    # ==================================================
    # GET SOURCE DATA
    # ==================================================

    $groups =
        Get-AccessPackageGroups `
            -Environment $Environment `
            -PartnerFiler $PartnerFiler `
            -Config $config

    Write-ExecutionLog "Groups Retrieved: $($groups.Count)"

    foreach ($row in $groups) {

        try {

            $tokens = @{
                Environment  = $Environment
                PartnerFiler = $PartnerFiler
                Organization = $row.Organization
                Group        = $row.Group
            }

            $accessPackageName =
                Resolve-Template `
                    -Template $config.AccessPackages.DisplayNameTemplate `
                    -Tokens $tokens

            Write-ExecutionLog "Processing $accessPackageName"

            $result =
                Ensure-AccessPackageDeleted `
                    -DisplayName $accessPackageName `
                    -Simulate $Simulate -Cascade:$Cascade

            $results.Add(
                [PSCustomObject]@{
                    AccessPackageName  = $accessPackageName
                    CatalogName        = $catalog.DisplayName
                    Organization       = $row.Organization
                    Group              = $row.Group
                    FullGroupName      = $row.FullGroupName
                    EntraGroupObjectId = $row.EntraGroupObjectId
                    Action             = $result.Action
                    Status             = $result.Status
                    Message            = $result.Message
                    AccessPackageId    = $result.AccessPackageId
                }
            )

        }
        catch {

            $results.Add(
                [PSCustomObject]@{
                    AccessPackageName  = $accessPackageName
                    CatalogName        = $catalog.DisplayName
                    Organization       = $row.Organization
                    Group              = $row.Group
                    FullGroupName      = $row.FullGroupName
                    EntraGroupObjectId = $row.EntraGroupObjectId
                    Action             = "Failed"
                    Status             = "Failed"
                    Message            = $_.Exception.Message
                    AccessPackageId    = ""
                }
            )
        }
    }

    # ==================================================
    # EXPORT CSV
    # ==================================================

    $results |
        Export-Csv `
            -Path $outputFile `
            -NoTypeInformation `
            -Encoding UTF8

    Write-ExecutionLog "Results exported to $outputFile"

    # ==================================================
    # SUMMARY
    # ==================================================

    $deleted =
        ($results |
            Where-Object Action -eq "Deleted").Count

    $skipped =
        ($results |
            Where-Object Action -eq "Skipped").Count

    $failed =
        ($results |
            Where-Object Action -eq "Failed").Count

    $simulated =
        ($results |
            Where-Object Action -eq "Simulated").Count

    Write-ExecutionLog ""
    Write-ExecutionLog "Access Package Deletion Summary"
    Write-ExecutionLog "Deleted:   $deleted"
    Write-ExecutionLog "Skipped:   $skipped"
    Write-ExecutionLog "Failed:    $failed"
    Write-ExecutionLog "Simulated: $simulated"
    Write-ExecutionLog "Output File: $outputFile"
}
finally {

    Disconnect-MgGraph

    Write-ExecutionLog "Disconnected from Graph"
}