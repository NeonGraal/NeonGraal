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

function Use-Compose() {
    docker compose $args
}

Set-Alias d docker
Set-Alias dc Use-Compose
Set-Alias dn dotnet
Set-Alias g git
Set-Alias wu Update-ViaWinget
Set-Alias uz Update-ZLocation
Set-Alias rz Remove-ZLocation

function Use-Admin($service, [switch]$Stop = $false) {
    $action = "Start-Service"
    if ($Stop) {
        $action = "Stop-Service"
    }
    Start-Process pwsh.exe "-C",$action,$service -Verb RunAs
}