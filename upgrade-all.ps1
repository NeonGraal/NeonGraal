Write-Host "* WSL" -ForegroundColor Blue
wsa update
wsau
wsa autoremove

Write-Host "* Powershell" -ForegroundColor Blue
$modules = @(Get-InstalledModule | Where-Object { $_.RepositorySourceLocation -ne $_.Repository } | Select-Object -ExpandProperty Name)
Update-Module $modules

Write-Host "* Dotnet Tools (dntu) " -ForegroundColor Blue
dn tools-outdated

Write-Host "* Winget (wgu)" -ForegroundColor Blue
wgu

Write-Host "* WSL (wsau)" -ForegroundColor Blue
wsau
