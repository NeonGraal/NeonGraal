[CmdletBinding()]
param (
    $machine
)

$machine = Get-Content "$machine.winget.machine" | ConvertFrom-Json

$machineAsAt = $machine.CreationDate

$used = @{}

$machine.Sources[0].Packages | Select-Object -ExpandProperty PackageIdentifier `
    | ForEach-Object { $used[$_] = @("M") }

Get-Item *.winget | ForEach-Object {
    $name = $_.BaseName
    Write-Host "Loading $name.winget ..."
    $json = $_ | Get-Content | ConvertFrom-Json
    $json.Sources[0].Packages | Select-Object -ExpandProperty PackageIdentifier | ForEach-Object {
        if ($used.Keys -contains $_) {
            $used[$_] += @($name)
        } else {
            $used[$_] = @("X", $name)
        }
    }    
}

$used | Format-Table -AutoSize
