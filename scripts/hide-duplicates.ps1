# Requires administrator — modifying HKLM entries needs elevated privileges.
$envFile    = Join-Path $PSScriptRoot "..\.env"
$backupFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.hidden-entries.json"))

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Host "[!] Administrator privileges required." -ForegroundColor Red
    Write-Host "    Right-click PowerShell -> 'Run as administrator', then re-run this script." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $envFile)) {
    Write-Host "[!] .env not found. Run setup-env.ps1 first." -ForegroundColor Red
    exit 1
}

# Load .env
$envPaths = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and ($line -notlike "#*")) {
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) { $envPaths[$parts[0].Trim()] = $parts[1].Trim() }
    }
}

# ── Shell verb keys (LegacyDisable, .env-gated) ──────────────────────────────
# Maps: .env app key → shell\<verb> registry keys to suppress.
# NOTE: shell\cmd and shell\Powershell are TrustedInstaller-owned — they cannot be
#       modified even by administrators and are excluded deliberately.
#       Those entries only appear in "Show more options" (classic menu), not the main
#       Windows 11 context menu, so hiding them is not necessary.
$appToKeys = [ordered]@{
    "WT_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\OpenWTHere",
        "HKCU:\Software\Classes\Directory\Background\shell\OpenWTHere"
    )
    "PWSH_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\PowerShell7x64",
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\PowerShell7",
        "HKCU:\Software\Classes\Directory\Background\shell\PowerShell7x64"
    )
    "GITBASH_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\git_shell",
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\git_gui",
        "HKCU:\Software\Classes\Directory\Background\shell\git_shell",
        "HKCU:\Software\Classes\Directory\Background\shell\git_gui"
    )
    "VSCODE_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\VSCode",
        "HKCU:\Software\Classes\Directory\Background\shell\VSCode"
    )
    "WARP_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\WarpTab",
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\WarpWindow",
        "HKCU:\Software\Classes\Directory\Background\shell\WarpTab",
        "HKCU:\Software\Classes\Directory\Background\shell\WarpWindow"
    )
    "ANTIGRAVITY_PATH" = @(
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\Antigravity",
        "HKCU:\Software\Classes\Directory\Background\shell\Antigravity"
    )
}

# ── Shell verb keys (LegacyDisable, unconditional) ───────────────────────────
# Hidden regardless of .env — the key existing in the registry is proof enough.
# Use for: third-party launchers where we can't reliably detect an exe path.
$unconditionalKeys = @(
    "HKLM:\SOFTWARE\Classes\Directory\Background\shell\AnyCode"  # VS Launcher ("Open with Visual Studio")
)

# ── COM shellex ContextMenuHandlers (key deletion, unconditional) ─────────────
# LegacyDisable does not work on COM handlers; we delete the key and restore on uninstall.
$shelexTargets = @(
    "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\PowerRenameExt"
)

Write-Host "Hiding duplicate context menu entries..." -ForegroundColor Cyan

$hiddenLegacy  = [System.Collections.Generic.List[string]]::new()
$hiddenShellex = [System.Collections.Generic.List[hashtable]]::new()

# Seed from existing backup so previously-hidden entries are still tracked for restoration
if (Test-Path $backupFile) {
    $prev = Get-Content $backupFile -Raw | ConvertFrom-Json
    if ($prev -is [array]) {
        foreach ($k in $prev) { if (-not $hiddenLegacy.Contains($k)) { $hiddenLegacy.Add($k) } }
    } else {
        foreach ($k in $prev.legacyDisable) { if (-not $hiddenLegacy.Contains($k)) { $hiddenLegacy.Add($k) } }
        foreach ($s in $prev.shellex)        { $hiddenShellex.Add(@{ path = $s.path; value = $s.value }) }
    }
}

function Set-LegacyDisable {
    param([string]$RegKey)
    if (-not (Test-Path $RegKey)) { return }

    $alreadyDisabled = Get-ItemProperty $RegKey -Name "LegacyDisable" -ErrorAction SilentlyContinue
    if ($null -ne $alreadyDisabled) {
        Write-Host "  [~] Already hidden (skipped): $($RegKey.Split('\')[-1])" -ForegroundColor DarkGray
        return
    }

    try {
        New-ItemProperty $RegKey -Name "LegacyDisable" -Value "" -PropertyType String -Force -ErrorAction Stop | Out-Null
        $script:hiddenLegacy.Add($RegKey)
        $label = (Get-ItemProperty $RegKey -ErrorAction SilentlyContinue).MUIVerb
        if (-not $label) { $label = (Get-ItemProperty $RegKey -ErrorAction SilentlyContinue).'(default)' }
        Write-Host "  [+] Hidden: $($RegKey.Split('\')[-1])  ($label)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Permission denied (skipped): $($RegKey.Split('\')[-1])" -ForegroundColor Yellow
        Write-Host "      This key is protected by TrustedInstaller and cannot be modified." -ForegroundColor DarkGray
    }
}

# ── Process .env-gated shell verb keys ───────────────────────────────────────
foreach ($appKey in $appToKeys.Keys) {
    $appPath = $envPaths[$appKey]
    if (-not $appPath -or $appPath -eq "NOT_FOUND") { continue }
    foreach ($regKey in $appToKeys[$appKey]) { Set-LegacyDisable $regKey }
}

# ── Process unconditional shell verb keys ────────────────────────────────────
foreach ($regKey in $unconditionalKeys) { Set-LegacyDisable $regKey }

# ── Process COM shellex handlers ─────────────────────────────────────────────
foreach ($regKey in $shelexTargets) {
    if (-not (Test-Path $regKey)) { continue }

    $alreadyTracked = $hiddenShellex | Where-Object { $_.path -eq $regKey }
    if ($alreadyTracked) {
        Write-Host "  [~] Already removed (skipped): $(Split-Path $regKey -Leaf)" -ForegroundColor DarkGray
        continue
    }

    try {
        $guid = (Get-ItemProperty $regKey -ErrorAction SilentlyContinue).'(default)'
        Remove-Item $regKey -Recurse -Force -ErrorAction Stop
        $hiddenShellex.Add(@{ path = $regKey; value = $guid })
        Write-Host "  [+] Removed shellex: $(Split-Path $regKey -Leaf)  ($guid)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Permission denied (skipped): $(Split-Path $regKey -Leaf)" -ForegroundColor Yellow
    }
}

$anyHidden = ($hiddenLegacy.Count + $hiddenShellex.Count) -gt 0

if (-not $anyHidden) {
    Write-Host "  Nothing to hide (no matching entries found)." -ForegroundColor DarkGray
} else {
    @{
        legacyDisable = $hiddenLegacy.ToArray()
        shellex       = @($hiddenShellex)
    } | ConvertTo-Json -Depth 3 | Set-Content -Path $backupFile -Encoding utf8
    Write-Host ""
    Write-Host "Backup saved to: $backupFile" -ForegroundColor Cyan
    Write-Host "Run uninstall.ps1 to restore these entries." -ForegroundColor Gray
}
