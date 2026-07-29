function Assert-NotNullOrEmpty {
    param([string]$Value, [string]$Name)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name cannot be null or empty"
    }
}