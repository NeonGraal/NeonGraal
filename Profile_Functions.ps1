
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

function Update-ViaWinget() {
    winget upgrade @args
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

# ~/bin/docker
function Use-Compose() {
    docker compose $args
}

function Invoke-Location($Dir, [scriptblock]$AtLocation) {
    Push-Location $Dir
    try {
        & $AtLocation
    }
    finally {
        Pop-Location
    }
}

function Find-Git([switch]$Recurse = $false, [scriptblock]$AtGit, [string]$Branch) {
    Get-ChildItem . -Directory -Recurse:$Recurse | Where-Object { 
        Test-Path "$_/.git" 
    } | ForEach-Object {
        $path = (Resolve-Path $_ -Relative).TrimStart(".\")
        Invoke-Location $_ {
            if ($Branch) {
                if (git branch | Select-String $Branch) {
                    Write-Host "> $path($Branch)`: " -NoNewline -ForegroundColor Yellow
                    & $AtGit
                }
            }
            else {
                Write-Host "> $path`: " -NoNewline -ForegroundColor Yellow
                & $AtGit
            }
        }
    }
}

function Invoke-GitAll {
    [CmdletBinding(PositionalBinding = $false)]
    Param(
        [switch]$Recurse = $false,
        [string]$Branch,
        [Parameter(ValueFromRemainingArguments = $true)]$params
    )
    $findParams = @{"-Recurse" = $Recurse }
    if ($Branch) {
        $findParams["-Branch"] = $Branch
    }
    if ($params) {
        Find-Git @findParams -AtGit {
            git @params
            Write-Host
        }
    }
    else {
        Find-Git @findParams -AtGit {
            if (@(git remote)) {
                git base
            }
            else {
                git st
            }
        }
    }
}

function Invoke-GitFetchOrigin([switch]$Recurse = $false, [Parameter(Mandatory = $true)][string]$Branch) {
    Find-Git -Recurse:$Recurse -Branch:$Branch {
        $check = git branch -l $Branch -vv
        if ($check -notmatch "\* $Branch") {
            git fetch origin $Branch`:$Branch
            Write-Host
        } elseif ($check -match "\[origin/$Branch\]") {
            git pull origin
        }
    }
}

function Get-GitCloneFlow($Dir, $Url, $Branch) {
    git clone $Url -b $Branch $Dir
    if ($LASTEXITCODE -ne 0) {
        return $LASTEXITCODE
    }
    Invoke-Location $Dir {
        git flow init -d        
    }
}

function Get-MainMasterDevelop($Dir = "C:\Dev") {
    Push-Location $Dir
    try {
        Invoke-GitFetchOrigin -Recurse main
        Invoke-GitFetchOrigin -Recurse master
        Invoke-GitFetchOrigin -Recurse develop
        # Invoke-GitFetchOrigin -Recurse "support*"
    }
    finally {
        Pop-Location
    }
}
