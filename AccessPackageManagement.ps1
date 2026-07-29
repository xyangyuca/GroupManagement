param(
    [string]$Environment,

    [ValidateSet("Partner","Filer")]
    [string]$PartnerFiler,

    [bool]$Simulate = $true
)

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
. "$PSScriptRoot\..\Core\GraphCore.ps1"

. "$PSScriptRoot\Functions\Resolve-Template.ps1"
. "$PSScriptRoot\Functions\Get-Catalog.ps1"

. "$PSScriptRoot\Functions\Get-AccessPackageGroups.ps1"
. "$PSScriptRoot\Functions\Get-AccessPackage.ps1"

. "$PSScriptRoot\Functions\Get-CatalogGroupResource.ps1"
. "$PSScriptRoot\Functions\Get-CatalogGroupMemberRole.ps1"

. "$PSScriptRoot\Functions\Test-AccessPackageResourceAssignment.ps1"

. "$PSScriptRoot\Functions\Add-AccessPackage.ps1"
. "$PSScriptRoot\Functions\Ensure-AccessPackage.ps1"

# ==========================================
# CONFIGURATION
# ==========================================

$config = Get-AppConfig

# ==========================================
# RUN ID
# ==========================================

$runId = "${Environment}_${PartnerFiler}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"



# ==========================================
# FOLDERS
# ==========================================

$logFolder = Join-Path $PSScriptRoot "Logs"

$outputFolder = Join-Path $PSScriptRoot "Output"

$logFile = "$logFolder\AccessPackageManagement_$runId.log"

#New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
#New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null

# ==========================================
# FILES
# ==========================================

$logFile = Join-Path $logFolder "AccessPackageManagement_$runId.log"

$outputFile = Join-Path $outputFolder "AccessPackageManagementResults_$runId.csv"

# ==========================================
# RESULTS
# ==========================================

$results = [System.Collections.Generic.List[Object]]::new()

# ==========================================
# CONNECT GRAPH
# ==========================================

Connect-GraphSessionSecret $config.tenantId $config.clientId $config.secretValue

try {

    Write-Log -Message "Starting Access Package Management." -Level Info

    # ==========================================
    # RESOLVE CATALOG
    # ==========================================

    try {

        $catalog = Get-Catalog -Environment $Environment -PartnerFiler $PartnerFiler -Config $config

        Write-Log -Message "Catalog Found: $($catalog.DisplayName)" -Level Info
    }
    catch {

        $message =
        "Catalog lookup failed. Environment=$Environment PartnerFiler=$PartnerFiler Error=$($_.Exception.Message)"

        Write-Log -Message $message

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
                Message            = $message
                AccessPackageId    = ""
            }
        )

        $results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

        return
    }

    # ==========================================
    # GET SOURCE DATA
    # ==========================================

    $groups =
        Get-AccessPackageGroups `
            -Environment $Environment `
            -PartnerFiler $PartnerFiler `
            -Config $config

    Write-Log -Message "Groups Retrieved: $($groups.Count)"

    foreach ($row in $groups) {

        try {

            # ==========================================
            # RESOLVE ACCESS PACKAGE NAME
            # ==========================================

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

            $accessPackageDescription =
                Resolve-Template `
                    -Template $config.AccessPackages.DescriptionTemplate `
                    -Tokens $tokens

            Write-Log -Message "Processing: $accessPackageName"

            # ==========================================
            # CREATE / GET ACCESS PACKAGE
            # ==========================================

            $result = Ensure-AccessPackage `
                    -Row $row `
                    -Catalog $catalog `
                    -DisplayName $accessPackageName `
                    -Description $accessPackageDescription `
                    -Simulate $Simulate

            if ($result.PolicyEligible) {
                Ensure-AccessPackagePolicy `
                -AccessPackageId $result.AccessPackageId `
                -Row $row
            }

            # ==========================================
            # OUTPUT RECORD
            # ==========================================

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

    # ==========================================
    # EXPORT OUTPUT
    # ==========================================

    $results |
        Export-Csv `
            -Path $outputFile `
            -NoTypeInformation `
            -Encoding UTF8

    # ==========================================
    # SUMMARY
    # ==========================================

    $added =
        ($results |
            Where-Object Action -eq "Added").Count

    $skipped =
        ($results |
            Where-Object Action -eq "Skipped").Count

    $failed =
        ($results |
            Where-Object Action -eq "Failed").Count

    $simulated =
        ($results |
            Where-Object Action -eq "Simulated").Count

    Write-Host ""
    Write-Host "===================================="
    Write-Host "Access Package Management Summary"
    Write-Host "===================================="
    Write-Host "Added:     $added"
    Write-Host "Skipped:   $skipped"
    Write-Host "Failed:    $failed"
    Write-Host "Simulated: $simulated"
    Write-Host ""
    Write-Host "Output: $outputFile"
}
finally {

    Disconnect-MgGraph
}