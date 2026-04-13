$basePath  = "HKCU:\Software\Classes\Directory\Background\shell\DevTools"
$scriptPath = Join-Path $PSScriptRoot "dev-launcher.ps1"
$envFile    = Join-Path $PSScriptRoot "..\.env"

# Auto-run setup if .env is missing
if (-not (Test-Path $envFile)) {
    Write-Host ".env not found — running setup-env.ps1 first..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "setup-env.ps1")
}

# Load .env
$envPaths = @{}
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and ($line -notlike "#*")) {
            $parts = $line.Split('=', 2)
            if ($parts.Count -eq 2) {
                $envPaths[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }
}

# Remove old entries
Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DevTools" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installing Dev Tools context menu..." -ForegroundColor Cyan

# Create top-level submenu
New-Item $basePath -Force | Out-Null
New-ItemProperty $basePath -Name "MUIVerb"      -Value "Dev Tools"     -Force | Out-Null
New-ItemProperty $basePath -Name "SubCommands"  -Value ""              -Force | Out-Null
New-ItemProperty $basePath -Name "Icon"         -Value "shell32.dll,269" -Force | Out-Null
New-Item "$basePath\shell" -Force | Out-Null

function Add-MenuItem {
    param(
        [string]$Key,
        [string]$Label,
        [string]$Action,
        [string]$PathEnvName
    )

    $appPath = $envPaths[$PathEnvName]

    # Skip apps that were not found during setup
    if (-not $appPath -or $appPath -eq "NOT_FOUND") {
        Write-Host "  [~] Skipping '$Label' — not installed" -ForegroundColor DarkGray
        return
    }

    $itemPath = "$basePath\shell\$Key"
    $cmdPath  = "$itemPath\command"

    New-Item $itemPath -Force | Out-Null
    New-ItemProperty $itemPath -Name "MUIVerb" -Value $Label -Force | Out-Null

    # Use the app's own exe as the menu icon
    if (Test-Path $appPath) {
        New-ItemProperty $itemPath -Name "Icon" -Value $appPath -Force | Out-Null
    }

    New-Item $cmdPath -Force | Out-Null
    $command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -action $Action -path `"%V`""
    Set-ItemProperty $cmdPath -Name "(Default)" -Value $command -Force

    Write-Host "  [+] $Label" -ForegroundColor Green
}

# Terminals
Add-MenuItem -Key "01terminal"    -Label "Windows Terminal"       -Action "terminal"     -PathEnvName "WT_PATH"
Add-MenuItem -Key "02pwsh"        -Label "PowerShell 7"           -Action "pwsh"         -PathEnvName "PWSH_PATH"
Add-MenuItem -Key "03gitbash"     -Label "Git Bash"               -Action "gitbash"      -PathEnvName "GITBASH_PATH"

# Editors
Add-MenuItem -Key "04vscode"      -Label "Open with VSCode"       -Action "vscode"       -PathEnvName "VSCODE_PATH"
Add-MenuItem -Key "05warp"        -Label "Open with Warp"         -Action "warp"         -PathEnvName "WARP_PATH"
Add-MenuItem -Key "06antigravity" -Label "Open with Antigravity"  -Action "antigravity"  -PathEnvName "ANTIGRAVITY_PATH"

# Tools
Add-MenuItem -Key "07powerrename" -Label "Power Rename"           -Action "powerrename"  -PathEnvName "POWERRENAME_PATH"

Write-Host "`nDev Tools context menu installed successfully!" -ForegroundColor Cyan
Write-Host "Right-click on any folder background to see it." -ForegroundColor Gray
