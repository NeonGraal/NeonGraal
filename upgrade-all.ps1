Write-Host "* Powershell" -ForegroundColor Blue
$modules = @(Get-InstalledModule | Where-Object { $_.RepositorySourceLocation -ne $_.Repository } | Select-Object -ExpandProperty Name)
Update-Module $modules

Start-Admin .\windows-updated.ps1

Write-Host "* WSL" -ForegroundColor Blue
wsa update
wsau
wsa autoremove

Write-Host "* Dotnet Tools (dntu) " -ForegroundColor Blue
dn tools-outdated

Write-Host "* Winget (wgu)" -ForegroundColor Blue
wgu

Write-Host "* WSL (wsau)" -ForegroundColor Blue
wsau
wsl lsb_release -cd
wsl do-release-upgrade -c
