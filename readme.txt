.\GroupManagement.ps1 -Environment RDEV -PartnerFiler Partner -Release R1 -Simulate $true

.\DeleteGroups.ps1 -Environment RDEV -Simulate $true

.\CatalogManagement.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $false

.\AccessPackageManagement.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $true

.\AccessPackageDeletion.ps1 -Environment RDEV -PartnerFiler Partner -Simulate $true
dcs_rdh_group_mgt