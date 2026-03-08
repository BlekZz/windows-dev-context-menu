$basePath = "HKCU:\Software\Classes\Directory\Background\shell\DevTools"
$scriptPath = "C:\DevTools\windows-dev-context-menu\scripts\dev-launcher.ps1"

# 載入 .env 取得圖示路徑
$envFile = Join-Path $PSScriptRoot "..\.env"
$icons = @{}
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and ($line -notlike "#*")) {
            $parts = $line.Split('=', 2)
            if ($parts.Count -eq 2) {
                $icons[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }
}

# 清除舊項目
Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DevTools" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installing Dev Tools context menu..." -ForegroundColor Cyan

# 建立主選單
New-Item $basePath -Force | Out-Null
New-ItemProperty $basePath -Name "MUIVerb" -Value "Dev Tools" -Force | Out-Null
New-ItemProperty $basePath -Name "SubCommands" -Value "" -Force | Out-Null
New-ItemProperty $basePath -Name "Icon" -Value "shell32.dll,269" -Force | Out-Null

# 建立 shell 容器
New-Item "$basePath\shell" -Force | Out-Null

function Add-MenuItem {
    param(
        [string]$Key,
        [string]$Label,
        [string]$Action,
        [string]$IconEnvName
    )

    $itemPath = "$basePath\shell\$Key"
    $cmdPath  = "$itemPath\command"

    New-Item $itemPath -Force | Out-Null
    New-ItemProperty $itemPath -Name "MUIVerb" -Value $Label -Force | Out-Null

    $iconPath = $icons[$IconEnvName]
    if ($iconPath -and ($iconPath -ne "NOT_FOUND") -and (Test-Path $iconPath)) {
        New-ItemProperty $itemPath -Name "Icon" -Value $iconPath -Force | Out-Null
    }

    New-Item $cmdPath -Force | Out-Null
    $command = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`" $Action `"%V`""
    Set-ItemProperty $cmdPath -Name "(Default)" -Value $command -Force

    Write-Host "[+] $Label" -ForegroundColor Green
}

# Terminals
Add-MenuItem -Key "01terminal"    -Label "Windows Terminal"       -Action "terminal"     -IconEnvName "WT_PATH"
Add-MenuItem -Key "02pwsh"        -Label "PowerShell 7"           -Action "pwsh"         -IconEnvName "PWSH_PATH"
Add-MenuItem -Key "03gitbash"     -Label "Git Bash"               -Action "gitbash"      -IconEnvName "GITBASH_PATH"

# Editors
Add-MenuItem -Key "04vscode"      -Label "Open with VSCode"       -Action "vscode"       -IconEnvName "VSCODE_PATH"
Add-MenuItem -Key "05warp"        -Label "Open with Warp"         -Action "warp"         -IconEnvName "WARP_PATH"
Add-MenuItem -Key "06antigravity" -Label "Open with Antigravity"  -Action "antigravity"  -IconEnvName "ANTIGRAVITY_PATH"

# Tools
Add-MenuItem -Key "07powerrename" -Label "Power Rename"           -Action "powerrename"  -IconEnvName "POWERRENAME_PATH"

Write-Host "`nDev Tools context menu installed successfully!" -ForegroundColor Cyan
Write-Host "Right-click on any folder background to see it." -ForegroundColor Gray
