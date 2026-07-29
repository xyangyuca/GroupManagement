function Get-TemplateGroups {

    param(
        [Parameter(Mandatory)]
        [array]$Groups,
	
	    [Parameter(Mandatory)]
	    [string]$PartnerFiler	
    )


    $templatePath =
        "$PSScriptRoot\..\Config\GroupTemplates.json"

    if (!(Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }

    $templateConfig =
        Get-Content $templatePath |
        ConvertFrom-Json

        switch ($PartnerFiler.ToUpper()) {

            "FILER" {
                $templates = $templateConfig.FilerTemplates
            }

            "PARTNER" {
                $templates = $templateConfig.PartnerTemplates
            }

            default {
                throw "Invalid PartnerFile value [$PartnerFiler]. Expected FILER or PARTNER."
            }
        }


    $uniqueCodes =
    $Groups |
    Where-Object {
        $_.Code -and $_.Code.Trim() -ne ""
    } |
    Select-Object -ExpandProperty Code -Unique

    $generatedGroups = @()

    foreach ($code in $uniqueCodes) {

        foreach ($template in $templates) {

            $groupName =
                $template.Replace("{Code}", $code)

            $generatedGroups += [PSCustomObject]@{
                Code      = $code
                GroupName = $groupName
                Desc      = ""
		        GroupType = "Template"
            }
        }
    }

    return $generatedGroups
}