function Test-CsvPath {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "CSV file not found: $Path"
    }
}