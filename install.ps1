[CmdletBinding()]
param (
    $winget
)

winget import --accept-package-agreements --accept-source-agreements --ignore-unavailable $winget
