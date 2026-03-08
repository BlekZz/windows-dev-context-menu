param(
    [string]$action,
    [string]$path
)

if ($path) {
    Set-Location $path
}

function CommandExists($cmd) {
    return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

switch ($action) {

    "terminal" {
        if (CommandExists "wt") {
            wt.exe -d $path
        } else {
            Write-Host "Windows Terminal not installed"
        }
    }

    "pwsh" {
        if (CommandExists "pwsh") {
            pwsh -NoExit -Command "Set-Location '$path'"
        } else {
            Write-Host "PowerShell 7 not installed"
        }
    }

    "gitbash" {
        $gitbash = "C:\Program Files\Git\git-bash.exe"
        if (Test-Path $gitbash) {
            & $gitbash --cd="$path"
        } else {
            Write-Host "Git Bash not installed"
        }
    }

    "vscode" {
        $code = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
        if (Test-Path $code) {
            & $code $path
        } else {
            Write-Host "VSCode not installed"
        }
    }

    "warp" {
        $warp = "$env:LOCALAPPDATA\Programs\Warp\warp.exe"
        if (Test-Path $warp) {
            & $warp $path
        } else {
            Write-Host "Warp not installed"
        }
    }

    "antigravity" {
        $ag = "C:\Program Files\Antigravity\antigravity.exe"
        if (Test-Path $ag) {
            & $ag $path
        } else {
            Write-Host "Antigravity not installed"
        }
    }

    "powerrename" {
        $pr = "C:\Program Files\PowerToys\PowerToys.PowerRename.exe"
        if (Test-Path $pr) {
            & $pr $path
        } else {
            Write-Host "PowerRename not installed"
        }
    }

    default {
        Write-Host "Unknown action"
    }
}