param(
    [switch]$Force
)

$envFile = Join-Path $PSScriptRoot "..\.env"

if ((Test-Path $envFile) -and (-not $Force)) {
    Write-Host ".env already exists. Use -Force to overwrite." -ForegroundColor Yellow
    return
}

function Test-AppPath {
    param([string]$Path)

    if (-not $Path) { return $false }
    try { return (Test-Path $Path -ErrorAction Stop) }
    catch { return $false }
}

function Find-App {
    param(
        [string]$Name,
        [string[]]$Paths
    )

    # 1. Check known install paths first — more reliable than PATH for .exe resolution
    foreach ($p in $Paths) {
        if (Test-AppPath $p) { return $p }
    }

    # 2. Fallback: search PATH, but only accept real executables (skip .cmd/.bat wrappers)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -match '\.(exe|com)$') { return $cmd.Source }

    return "NOT_FOUND"
}

# Enumerates all pwsh.exe under versioned subdirectories and returns the one with
# the highest file version — avoids hardcoding \7\ which breaks on 7.2, 7.4, etc.
function Find-LatestPwsh {
    param(
        [string[]]$BaseDirs,
        [string]$ScoopExe
    )
    $candidates = @()
    foreach ($base in $BaseDirs) {
        if (-not (Test-AppPath $base)) { continue }
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $exe = Join-Path $_.FullName "pwsh.exe"
            if (Test-AppPath $exe) { $candidates += $exe }
        }
    }
    if (Test-AppPath $ScoopExe) { $candidates += $ScoopExe }

    if ($candidates.Count -eq 0) {
        $cmd = Get-Command "pwsh" -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -match '\.exe$') { return $cmd.Source }
        return "NOT_FOUND"
    }

    $best = $candidates | Sort-Object {
        try { [version](Get-Item $_).VersionInfo.ProductVersion.Split('-')[0] }
        catch { [version]"0.0" }
    } | Select-Object -Last 1
    return $best
}

function Find-CodexDesktop {
    $candidates = @()

    # MSIX package install location is the most stable way to find the desktop app.
    Get-AppxPackage "OpenAI.Codex" -ErrorAction SilentlyContinue | ForEach-Object {
        $exe = Join-Path $_.InstallLocation "app\Codex.exe"
        if (Test-AppPath $exe) { $candidates += $exe }
    }

    # The CLI helper is often on PATH; use it to infer the desktop executable.
    $cmd = Get-Command "codex" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -match '\\app\\resources\\codex\.exe$') {
        $appDir = Split-Path (Split-Path $cmd.Source -Parent) -Parent
        $exe = Join-Path $appDir "Codex.exe"
        if (Test-AppPath $exe) { $candidates += $exe }
    }

    # Fallback for environments where Get-AppxPackage is unavailable or filtered.
    $windowsApps = Join-Path $env:ProgramFiles "WindowsApps"
    Get-ChildItem $windowsApps -Directory -Filter "OpenAI.Codex_*" -ErrorAction SilentlyContinue | ForEach-Object {
        $exe = Join-Path $_.FullName "app\Codex.exe"
        if (Test-AppPath $exe) { $candidates += $exe }
    }

    if ($candidates.Count -eq 0) { return "NOT_FOUND" }

    $best = $candidates | Sort-Object {
        try { [version](Get-Item $_).VersionInfo.ProductVersion.Split('-')[0] }
        catch { [version]"0.0" }
    } | Select-Object -Last 1
    return $best
}

Write-Host "Detecting application paths..." -ForegroundColor Cyan

$local  = $env:LOCALAPPDATA
$prog   = $env:ProgramFiles
$prog86 = ${env:ProgramFiles(x86)}
$scoop  = Join-Path $env:USERPROFILE "scoop\apps"

$apps = @{
    "WT_PATH" = Find-App "wt" @(
        (Join-Path $local "Microsoft\WindowsApps\wt.exe")
    )
    "PWSH_PATH" = Find-LatestPwsh `
        -BaseDirs @("$prog\PowerShell", "$prog86\PowerShell") `
        -ScoopExe "$scoop\pwsh\current\pwsh.exe"
    "GITBASH_PATH" = Find-App "git-bash" @(
        "$prog\Git\git-bash.exe",
        "$prog86\Git\git-bash.exe",
        (Join-Path $local "Programs\Git\git-bash.exe"),
        "$scoop\git\current\git-bash.exe",
        "$scoop\git-with-openssh\current\git-bash.exe"
    )
    "VSCODE_PATH" = Find-App "code" @(
        (Join-Path $local "Programs\Microsoft VS Code\Code.exe"),
        "$prog\Microsoft VS Code\Code.exe",
        "$scoop\vscode\current\Code.exe",
        "$scoop\vscode-insiders\current\Code.exe"
    )
    "WARP_PATH" = Find-App "warp" @(
        (Join-Path $local "Programs\Warp\Warp.exe"),
        (Join-Path $local "Warp\warp.exe"),
        "$prog\Warp\warp.exe",
        "$scoop\warp\current\warp.exe"
    )
    "ANTIGRAVITY_PATH" = Find-App "antigravity" @(
        (Join-Path $local "Programs\Antigravity\Antigravity.exe"),
        "$prog\Antigravity\antigravity.exe"
    )
    "CODEX_PATH" = Find-CodexDesktop
    "POWERRENAME_PATH" = Find-App "PowerToys.PowerRename" @(
        "$prog\PowerToys\WinUI3Apps\PowerToys.PowerRename.exe",
        "$prog\PowerToys\PowerToys.PowerRename.exe",
        "$prog\PowerToys\PowerRename\PowerToys.PowerRename.exe",
        (Join-Path $local "PowerToys\WinUI3Apps\PowerToys.PowerRename.exe"),
        (Join-Path $local "PowerToys\PowerToys.PowerRename.exe")
    )
    "VS_PATH" = Find-App "devenv" @(
        "$prog\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2022\Preview\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe",
        "$prog\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\devenv.exe",
        "$prog86\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe",
        "$prog86\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe",
        "$prog86\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe",
        "$prog86\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe",
        # VSLauncher.exe: shipped with VS Installer, opens VS even without a full devenv install
        "$prog86\Common Files\Microsoft Shared\MSEnv\VSLauncher.exe",
        "$prog\Common Files\Microsoft Shared\MSEnv\VSLauncher.exe"
    )
}

# Write as array so Set-Content produces one key=value per line
$lines = @("# Auto-generated by setup-env.ps1")
$apps.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $lines += "$($_.Key)=$($_.Value)"
    if ($_.Value -eq "NOT_FOUND") {
        Write-Host "  [-] $($_.Key): not found" -ForegroundColor DarkGray
    } else {
        Write-Host "  [+] $($_.Key): $($_.Value)" -ForegroundColor Green
    }
}

Set-Content -Path $envFile -Value $lines -Encoding utf8
Write-Host "`nEnvironment file created at: $envFile" -ForegroundColor Cyan
