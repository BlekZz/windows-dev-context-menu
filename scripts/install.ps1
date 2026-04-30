$basePath = "HKCU:\Software\Classes\Directory\Background\shell\DevTools"
$envFile  = Join-Path $PSScriptRoot "..\.env"
$ErrorActionPreference = "Stop"

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
# Position=Top causes Dev Tools to appear BEFORE View/Sort/Refresh in Windows 11 — omitted
# intentionally so Windows places it naturally after system items.
New-Item $basePath -Force | Out-Null
New-ItemProperty $basePath -Name "MUIVerb"     -Value "Dev Tools"      -Force | Out-Null
New-ItemProperty $basePath -Name "SubCommands" -Value ""               -Force | Out-Null
New-ItemProperty $basePath -Name "Icon"        -Value "shell32.dll,22" -Force | Out-Null
New-Item "$basePath\shell" -Force | Out-Null

function Add-MenuItem {
    param(
        [string]$Key,
        [string]$Label,
        [string]$Action,
        [string]$PathEnvName,
        [string]$DirectPath,  # bypass .env lookup (e.g. system binaries always present)
        [string]$Icon         # explicit icon resource — use for MSIX apps whose exe can't be extracted
    )

    if ($DirectPath) {
        $appPath = $DirectPath
    } else {
        $appPath = $envPaths[$PathEnvName]
        if (-not $appPath -or $appPath -eq "NOT_FOUND") {
            Write-Host "  [~] Skipping '$Label' — not installed" -ForegroundColor DarkGray
            return
        }
    }

    $itemPath = "$basePath\shell\$Key"
    $cmdPath  = "$itemPath\command"

    New-Item $itemPath -Force | Out-Null
    New-ItemProperty $itemPath -Name "MUIVerb" -Value $Label -Force | Out-Null

    # Icon priority: explicit -Icon > exe path > nothing
    $iconSource = if ($Icon) { $Icon } elseif ($appPath -and (Test-Path $appPath)) { $appPath } else { $null }
    if ($iconSource) {
        New-ItemProperty $itemPath -Name "Icon" -Value $iconSource -Force | Out-Null
    }

    New-Item $cmdPath -Force | Out-Null
    $vbsPath = Join-Path $PSScriptRoot "launcher.vbs"
    $command = "wscript.exe `"$vbsPath`" $Action `"%V`""
    Set-ItemProperty $cmdPath -Name "(Default)" -Value $command -Force

    Write-Host "  [+] $Label" -ForegroundColor Green
}

$cmdExe = "$env:SystemRoot\System32\cmd.exe"

# Terminals
Add-MenuItem -Key "01cmd"         -Label "Command Prompt"          -Action "cmd"         -DirectPath $cmdExe
Add-MenuItem -Key "02cmdadmin"    -Label "Command Prompt (Admin)"  -Action "cmdadmin"    -DirectPath $cmdExe
Add-MenuItem -Key "03pwsh"        -Label "PowerShell 7"            -Action "pwsh"        -PathEnvName "PWSH_PATH"
Add-MenuItem -Key "04pwshadmin"   -Label "PowerShell 7 (Admin)"    -Action "pwshadmin"   -PathEnvName "PWSH_PATH"
Add-MenuItem -Key "05gitbash"     -Label "Git Bash"                -Action "gitbash"     -PathEnvName "GITBASH_PATH"

# Editors
Add-MenuItem -Key "06vscode"      -Label "Open with VSCode"        -Action "vscode"      -PathEnvName "VSCODE_PATH"
Add-MenuItem -Key "07warp"        -Label "Open with Warp"          -Action "warp"        -PathEnvName "WARP_PATH"
Add-MenuItem -Key "08antigravity" -Label "Open with Antigravity"   -Action "antigravity" -PathEnvName "ANTIGRAVITY_PATH"
Add-MenuItem -Key "09codex"       -Label "Open with Codex"         -Action "codex"       -PathEnvName "CODEX_PATH"       -Icon "shell32.dll,269"

# Tools — MSIX-packaged apps use explicit DLL icons; their exe icons can't be extracted by Shell
Add-MenuItem -Key "10powerrename" -Label "Power Rename"            -Action "powerrename" -PathEnvName "POWERRENAME_PATH" -Icon "shell32.dll,269"
Add-MenuItem -Key "11vs"          -Label "Open with Visual Studio" -Action "vs"          -PathEnvName "VS_PATH"          -Icon "shell32.dll,269"

Write-Host "`nDev Tools context menu installed successfully!" -ForegroundColor Cyan
Write-Host "Right-click on any folder background to see it." -ForegroundColor Gray
