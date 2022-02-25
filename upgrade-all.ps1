Write-Host "* WSL" -ForegroundColor Blue
wsl sudo apt update
wsl sudo apt dist-upgrade
wsl sudo apt autoremove

Write-Host "* Powershell" -ForegroundColor Blue
Update-Module

Write-Host "* Dotnet Tools" -ForegroundColor Blue
dotnet tools-outdated

Write-Host "* Winget" -ForegroundColor Blue
winget upgrade
