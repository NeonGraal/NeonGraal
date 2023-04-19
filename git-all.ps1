$all = @($args)

Get-ChildItem .. -Directory | Select-Object -ExpandProperty FullName | ForEach-Object {    
    Push-Location $_
    if (Test-Path .git) {
        Write-Host "Running against $_ : " -BackgroundColor DarkBlue -NoNewline
        if ($all) {
            Write-Host "$all " -BackgroundColor DarkBlue -NoNewline
            git @all
        } else {
            if (@(git remote)) {
                git behind
            } else {
                git st
            }
        }
    }
    Pop-Location
}