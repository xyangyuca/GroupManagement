.\GroupManagement.ps1 -Environment RDEV -PartnerFiler Partner -Release R1 -Simulate $true

.\DeleteGroups.ps1 -Environment RDEV -Simulate $true

.\CatalogManagement.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $false

.\AccessPackageManagement.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $true

.\AccessPackageDeletion.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $true

.\AppRegGroupManagement.ps1 -Environment PROD -PartnerFiler Filer -AppName "DCS-EntitlementManagement-Automation-Prod" -Simulate $true

.\AppRegGroupManagement.ps1 -Environment RDEV -PartnerFiler Partner -AppName "DCS-EntitlementManagement-Automation-Prod" -Simulate $true

.\AppRegGroupRemoval.ps1 -Environment PROD  -PartnerFiler Filer   -AppName "DCS-EntitlementManagement-Automation-Prod"     -Simulate $false

.\GroupMembershipManagement.ps1 -Environment RDEV -PartnerFiler Partner -TargetGroupName "SG-DCS-Approved-Users" -Simulate $true

.\GroupMembershipRemoval.ps1 -Environment RDEV  -PartnerFiler Partner -TargetGroupName "SG-DCS-Test-Container" -Simulate $false

.\GenerateGroupFile.ps1 -Environment RDEV -PartnerFiler Partner
dcs_rdh_group_mgt
