# Reinstallation notes

## Windows 10

1. Install "App Installer" from Windows Store to get `winget` tool, then install the following packages:
   - Google.Chrome
   - Twilio.Authy
   - Github.Cli
   - Microsoft.Powershell
1. Rename User account from `ms`
1. Set User Home directory with `lusrmgr.msc` tool
1. Manually install HW software (Motherboard, Graphics Drivers, etc...)
1. Windows 10 settings
   1. Rename Machine
   1. Configure File History
   1. Turn on Developer mode
1. Install Theme pack
1. Install Font Cascadia Code from [NerdFonts](https://www.nerdfonts.com/font-downloads)
   - Currently [v2.1.0](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip)
1. Install Powershell modules with `Install-Module`
   - `posh-git`
   - `PsWindowsUpdate`
   - `zLocation`
1. Create `\Dev` directory and git clone this repo with `gh repo clone NeonGraal/NeonGraal`
1. Copy `Powershell_profile.ps1` into `$PROFILE`
1. Copy `upgrade-all.ps1` and `windows-updates.ps1` into `~`
1. Copy `struan.omp.json` into `D:\Struan` (or somewhere else and edit the profile from 9.) 
1. Install the desired `*.winget` packs with `install.ps1 pack.winget`
   - Start with `Basic.winget`

## WSL Ubuntu

1. Install with root username of `struan`
2. Copy `struan-sudoer.d` into `/etc/sudoers.d`
3. Remove `snapd` with `sudo apt purge snapd`
4. Edit `/etc/update-manager/release-upgrades` and change `Prompt=lts` to be `Prompt=normal`
5. Run `update-alternatives --config editor` and change editor to be vim
