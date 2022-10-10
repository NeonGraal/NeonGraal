# Reinstallation notes

## Windows 10

1. Install "App Installer" from Windows Store to get `winget` tool.
2. Rename User account from `ms`
3. Set User Home directory with `lusrmgr.msc` tool
4. Manually install HW software (Motherboard, Graphics Drivers, etc...)
5. Windows 10 settings
   1. Rename Machine
   2. Configure File History
   3. Turn on Developer mode
6. Install Theme pack
7. Install Font Cascadia Code from [NerdFonts](https://www.nerdfonts.com/font-downloads)
   - Currently [v2.1.0](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip)
8. Install Powershell modules
   - `Install-Module posh-git`
9. Copy `Powershell_profile.ps1` into `$PROFILE`
10. Copy `struan.omp.json` into `D:\Struan` (or somewhere else and edit the profile from 9.) 
11. Install the desired `*.winget` packs with `install.ps1 pack.winget`
    - Start with `Basic.winget`

## WSL Ubuntu

1. Install with root username of `struan`
2. Copy `struan-sudoer.d` into `/etc/sudoers.d`
3. Remove `snapd` with `sudo apt purge snapd`
4. Edit `/etc/update-manager/release-upgrades` and change `Prompt=lts` to be `Prompt=normal`
5. Run `update-alternatives --config editor` and change editor to be vim