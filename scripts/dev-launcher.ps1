param(
    [string]$action,
    [string]$path
)

if ($path) {
    Set-Location $path
}

# Load .env file
$envFile = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and ($line -notlike "#*")) {
            $parts = $line.Split('=', 2)
            if ($parts.Count -eq 2) {
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                Set-Item -Path "Env:\$name" -Value $value
            }
        }
    }
}

function Invoke-App {
    param(
        [string]$Path,
        [string]$ArgumentList,
        [string]$Name
    )
    
    if ($Path -and ($Path -ne "NOT_FOUND") -and (Test-Path $Path)) {
        if ($ArgumentList) {
            Start-Process -FilePath $Path -ArgumentList $ArgumentList
        } else {
            Start-Process -FilePath $Path
        }
    } else {
        Write-Host "[-] $Name not found or path invalid: $Path" -ForegroundColor Red
    }
}

switch ($action) {

    "terminal" {
        Invoke-App $env:WT_PATH "-d `"$path`"" "Windows Terminal"
    }

    "pwsh" {
        Invoke-App $env:PWSH_PATH "-NoExit -Command `"Set-Location '$path'`"" "PowerShell 7"
    }

    "gitbash" {
        Invoke-App $env:GITBASH_PATH "--cd=`"$path`"" "Git Bash"
    }

    "vscode" {
        Invoke-App $env:VSCODE_PATH "`"$path`"" "VSCode"
    }

    "warp" {
        Invoke-App $env:WARP_PATH "`"$path`"" "Warp"
    }

    "antigravity" {
        Invoke-App $env:ANTIGRAVITY_PATH "`"$path`"" "Antigravity"
    }

    "powerrename" {
        Invoke-App $env:POWERRENAME_PATH "`"$path`"" "PowerRename"
    }

    default {
        Write-Host "[!] Unknown action: $action" -ForegroundColor Yellow
    }
}