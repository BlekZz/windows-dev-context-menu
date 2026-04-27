$basePath   = "HKCU:\Software\Classes\Directory\Background\shell\DevTools"
$backupFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.hidden-entries.json"))

# ── Restore hidden entries ──────────────────────────────────────────────────
if (Test-Path $backupFile) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {
        Write-Host "[!] Hidden entries backup found but restoring HKLM keys requires administrator." -ForegroundColor Yellow
        Write-Host "    Re-run uninstall.ps1 as administrator to fully restore your original context menu." -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "Restoring hidden context menu entries..." -ForegroundColor Cyan

        $raw = Get-Content $backupFile -Raw | ConvertFrom-Json

        # Support both old format (plain array) and new format ({ legacyDisable, shellex })
        if ($raw -is [array]) {
            $legacyDisable = $raw
            $shellex = @()
        } else {
            $legacyDisable = if ($raw.legacyDisable) { $raw.legacyDisable } else { @() }
            $shellex       = if ($raw.shellex)       { $raw.shellex }       else { @() }
        }

        foreach ($key in $legacyDisable) {
            if (Test-Path $key) {
                Remove-ItemProperty $key -Name "LegacyDisable" -ErrorAction SilentlyContinue
                Write-Host "  [+] Restored: $($key.Split('\')[-1])" -ForegroundColor Green
            } else {
                Write-Host "  [~] Key no longer exists (skipped): $($key.Split('\')[-1])" -ForegroundColor DarkGray
            }
        }

        foreach ($item in $shellex) {
            $path  = $item.path
            $value = $item.value
            if (-not (Test-Path $path)) {
                New-Item $path -Force | Out-Null
                Set-ItemProperty $path -Name "(Default)" -Value $value -Force
                Write-Host "  [+] Restored shellex: $(Split-Path $path -Leaf)" -ForegroundColor Green
            } else {
                Write-Host "  [~] Shellex key already exists (skipped): $(Split-Path $path -Leaf)" -ForegroundColor DarkGray
            }
        }

        Remove-Item $backupFile -Force
        Write-Host ""
    }
}

# ── Remove DevTools menu ────────────────────────────────────────────────────
Write-Host "Removing Dev Tools context menu..." -ForegroundColor Cyan

Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DevTools" -Recurse -Force -ErrorAction SilentlyContinue

# Clean up any CommandStore entries from older versions
$csBase = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
@("DT.Terminal","DT.Pwsh","DT.GitBash","DT.VSCode","DT.Warp","DT.Antigravity","DT.PowerRename") | ForEach-Object {
    Remove-Item "$csBase\$_" -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item "HKCU:\Software\Classes\Directory\Background\shell\TestItem" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Dev Tools context menu removed successfully!" -ForegroundColor Green
