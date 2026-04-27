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
        [string]$Name,
        [switch]$Admin
    )

    if ($Path -and ($Path -ne "NOT_FOUND") -and (Test-Path $Path)) {
        $params = @{ FilePath = $Path }
        if ($ArgumentList) { $params.ArgumentList = $ArgumentList }
        if ($Admin)        { $params.Verb = "RunAs" }
        Start-Process @params
    } else {
        Show-Error "$Name is not installed or its path is invalid.`n`nRe-run setup-env.ps1 to update paths."
    }
}

switch ($action) {

    "cmd" {
        $escapedPath = $path.TrimEnd('\')
        Start-Process "$env:SystemRoot\System32\cmd.exe" -ArgumentList "/K", "cd /d `"$escapedPath`""
    }

    "cmdadmin" {
        $escapedPath = $path.TrimEnd('\')
        Start-Process "$env:SystemRoot\System32\cmd.exe" -ArgumentList "/K", "cd /d `"$escapedPath`"" -Verb RunAs
    }

    "pwsh" {
        # Escape single quotes in path to avoid breaking the -Command string
        $escapedPath = $path -replace "'", "''"
        Invoke-App $env:PWSH_PATH "-NoExit -Command `"Set-Location '$escapedPath'`"" "PowerShell 7"
    }

    "pwshadmin" {
        $escapedPath = $path -replace "'", "''"
        Invoke-App $env:PWSH_PATH "-NoExit -Command `"Set-Location '$escapedPath'`"" "PowerShell 7" -Admin
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

    "vs" {
        Invoke-App $env:VS_PATH "`"$path`"" "Visual Studio"
    }

    default {
        Show-Error "Unknown action: '$action'`n`nThis may indicate a broken install. Re-run install.ps1."
    }
}
