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

function Update-ViaWinget() {
    winget upgrade @args
}

function Invoke-SshDresden() {
    ssh struan@dresden-u @args
}

function Invoke-SshDresdenSudo() {
    Invoke-SshDresden sudo @args
}

function Invoke-SshDresdenSudoApt() {
    Invoke-SshDresden sudo apt-get -y @args
}

function Update-ViaSshDresdenSudoApt() {
    Invoke-SshDresdenSudoApt dist-upgrade @args
}

function Invoke-WslSudo() {
    wsl sudo @args
}

function Invoke-WslSudoApt() {
    Invoke-WslSudo apt-get -y @args
}

function Update-ViaWslSudoApt() {
    Invoke-WslSudoApt dist-upgrade @args
}

function Update-ViaDotnetTool() {
    dotnet tool update -g @args
}

# ~/bin/docker
function Use-Compose() {
    docker compose @args
}

Set-Alias d docker
Set-Alias dc Use-Compose
Set-Alias g git.exe
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

function Start-Admin() {
    $params = @('-NOE', '-C') + $args
    Start-Process pwsh.exe $params -Verb RunAs
}

function Use-Admin($service, [switch]$Stop = $false) {
    $action = 'Start-Service'
    if ($Stop) {
        $action = 'Stop-Service'
    }
    Start-Admin $action $service
}
