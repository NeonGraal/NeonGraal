#Requires -RunAsAdministrator

Install-Module PSWindowsUpdate -confirm:$false -force
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
