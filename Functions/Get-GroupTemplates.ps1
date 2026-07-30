function Get-GroupTemplates {

    param(
        [string]$PartnerFiler,
        [object]$Config
    )

    switch ($PartnerFiler) {

        'Partner' {
            return @{
                RequestorTemplate =
                    $Config.PartnerRequestorGroups.DisplayNameTemplate

                ApproverTemplate =
                    $Config.PartnerApproverGroups.DisplayNameTemplate
            }
        }

        'Filer' {
            return @{
                RequestorTemplate =
                    $Config.FilerRequestorGroups.DisplayNameTemplate

                ApproverTemplate =
                    $Config.FilerApproverGroups.DisplayNameTemplate
            }
        }

        default {
            throw "Unsupported PartnerFiler value: $PartnerFiler"
        }
    }
}