function Resolve-Template {

    param(
        [string]$Template,
        [hashtable]$Tokens
    )

    $value = $Template

    foreach ($token in $Tokens.Keys) {
        $value = $value.Replace("{$token}", $Tokens[$token])
    }

    return $value
}