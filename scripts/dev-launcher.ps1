param(
    [string]$action,
    [string]$path
)

function Show-Error {
    param([string]$Message)
    (New-Object -ComObject WScript.Shell).Popup($Message, 0, "Dev Tools", 48) | Out-Null
}

# Load .env
$envFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.env"))
if (-not (Test-Path $envFile)) {
    Show-Error ".env not found at:`n$envFile`n`nPlease run setup-env.ps1 and install.ps1 again."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and ($line -notlike "#*")) {
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            Set-Item -Path "Env:\$($parts[0].Trim())" -Value $parts[1].Trim()
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
        Show-Error "$Name is not installed or its path is invalid.`n`nRe-run setup-env.ps1 to update paths."
    }
}

switch ($action) {

    "terminal" {
        Invoke-App $env:WT_PATH "-d `"$path`"" "Windows Terminal"
    }

    "pwsh" {
        # Escape single quotes in path to avoid breaking the -Command string
        $escapedPath = $path -replace "'", "''"
        Invoke-App $env:PWSH_PATH "-NoExit -Command `"Set-Location '$escapedPath'`"" "PowerShell 7"
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
        Show-Error "Unknown action: '$action'`n`nThis may indicate a broken install. Re-run install.ps1."
    }
}
