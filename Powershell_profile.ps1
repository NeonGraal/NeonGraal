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
    winget upgrade $args
}

function Invoke-WslSudo() {
    wsl sudo @args
}

function Invoke-WslSudoApt() {
    Invoke-WslSudo apt -y @args
}

function Update-ViaWslSudoApt() {
    wsl sudo apt-get -y dist-upgrade $args
}

function Update-ViaDotnetTool() {
    dotnet tool update -g $args
}

# ~/bin/docker
function Use-Compose() {
    docker compose $args
}

Set-Alias d docker
Set-Alias dc Use-Compose
Set-Alias g git.exe
Set-Alias dn dotnet
Set-Alias wg winget
Set-Alias ws Invoke-WslSudo
Set-Alias wsa Invoke-WslSudoApt
Set-Alias dntu Update-ViaDotnetTool
Set-Alias wgu Update-ViaWinget
Set-Alias wsau Update-ViaWslSudoApt
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
