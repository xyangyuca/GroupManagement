function Connect-GraphSession {
     param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$Thumbprint
    )

if (-not $TenantId -or -not $ClientId -or -not $Thumbprint) {
    throw "Missing required Graph connection parameters"
}

    # =========================
    # CONNECT TO GRAPH (SILENT)
    # =========================
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $Thumbprint -NoWelcome


}

function Connect-GraphSessionSecret {

    param(
	[Parameter(Mandatory = $true)]
        [string]$TenantId,
	[Parameter(Mandatory = $true)]
        [string]$ClientId,
	[Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $secureSecret = ConvertTo-SecureString `
        $ClientSecret `
        -AsPlainText `
        -Force

    $credential = New-Object `
        System.Management.Automation.PSCredential(
            $ClientId,
            $secureSecret
        )
try {
    Connect-MgGraph `
        -TenantId $TenantId `
        -ClientSecretCredential $credential `
        -NoWelcome

    Write-Host "Connected to Microsoft Graph"
	}
	catch {
	Write-HOst "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
	}
}
