Push-Location .

Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

oh-my-posh --init --shell pwsh --config ~/struan.omp.json | Invoke-Expression

$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n='
$GitPromptSettings.DefaultPromptWriteStatusFirst = $true

Import-Module zLocation

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Set-Alias d docker
Set-Alias dc Use-Compose
Set-Alias g git.exe
Set-Alias ga Invoke-GitAll
Set-Alias gfo Invoke-GitFetchOrigin
Set-Alias dn dotnet
Set-Alias wg winget
Set-Alias ws Invoke-WslSudo
Set-Alias wsa Invoke-WslSudoApt
Set-Alias wsau Update-ViaWslSudoApt
Set-Alias dntu Update-ViaDotnetTool
Set-Alias sd Invoke-SshDresden
Set-Alias sds Invoke-SshDresdenSudo
Set-Alias sdsa Invoke-SshDresdenSudoApt
Set-Alias sdsau Update-ViaSshDresdenSudoApt
Set-Alias wgu Update-ViaWinget
Set-Alias uz Update-ZLocation
Set-Alias rz Remove-ZLocation

# Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
# Import-Module "Equivalent to above but for Community"
# Enter-VsDevShell 1866e1cc

Pop-Location
