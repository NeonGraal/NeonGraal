[CmdletBinding()]
param (
    [switch]$All = $false,
    [switch]$Main = $false
)

function Get-Main() {
    $main = git config --local init.defaultBranch
    if ($null -eq $main) {
        return "master"
    } else {
        return $main
    }
}

function Get-Master($path, $master) {
    Write-Host "Resetting and pulling $master for $path" -BackgroundColor DarkBlue
    git reset --hard --quiet
    if (git remote) {
        git pull origin --ff-only --progress --stat --quiet
    }
}

$repos = '../paddock','../platform-services','../pushpay','../equestria','../bifrost', '../customer-admin-portal' | Get-Item

$mainRepos = '../mobile-application-studio','../ccb-local','../engagement-analytics-app','../advent-of-code'

if ($All) {
    $repos = Get-ChildItem .. -Directory | Where-Object { 
        ($_.FullName -notlike '*-master') -and ($_.FullName -notlike '*-main') -and (Test-Path (Join-Path $_ .git)) 
    }
} elseif ($Main) {
    $repos = $mainRepos | Get-Item
}

$repos | Select-Object -ExpandProperty FullName |`
    ForEach-Object {
        Push-Location $_
        try {
            $master = Get-Main
            $branches = @(git branch -vv)
            $currMaster = $branches -match "\* $master"
            $remote = @(git remote)

            Write-Host "Fetching latest for $_" -BackgroundColor DarkBlue
            if ($remote) {
                git fetch --all --prune --prune-tags --tags --update-head-ok --progress 
            }

            $masterPath = "$_-$master"
            if (Test-Path $masterPath) {            
                Push-Location $masterPath
                try {
                    Get-Master $masterPath $master
                } finally {
                    Pop-Location                    
                }
            } elseif (!$currMaster -and $remote) {
                git fetch origin $master`:$master
            }

            if ($currMaster) {
                Get-Master $_ $master
            } else {
                if ($branches -match "\*.*: gone") {
                    git switch local
                }
                if ($branches -match "\* local") {
                    if (git remote) {
                        git rebase $master
                    }
                }
            }
            foreach ($branch in $branches -match ": gone]") {
                $words = $branch -split "\s+"
                git branch -D $words[1]
            }
        }
        finally {
            Pop-Location
        }
    }
