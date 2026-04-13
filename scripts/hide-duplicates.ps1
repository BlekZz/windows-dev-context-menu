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

# Map: which .env app key -> which registry context menu entries it duplicates
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
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\git_gui"
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

Write-Host "Hiding duplicate context menu entries..." -ForegroundColor Cyan

$hidden = [System.Collections.Generic.List[string]]::new()

foreach ($appKey in $appToKeys.Keys) {
    $appPath = $envPaths[$appKey]
    if (-not $appPath -or $appPath -eq "NOT_FOUND") { continue }   # app not installed, skip

    foreach ($regKey in $appToKeys[$appKey]) {
        if (-not (Test-Path $regKey)) { continue }   # entry doesn't exist on this machine

        # Don't double-add — if LegacyDisable is already set (not by us), leave it alone
        $alreadyDisabled = Get-ItemProperty $regKey -Name "LegacyDisable" -ErrorAction SilentlyContinue
        if ($null -ne $alreadyDisabled) {
            Write-Host "  [~] Already hidden (skipped): $($regKey.Split('\')[-1])" -ForegroundColor DarkGray
            continue
        }

        New-ItemProperty $regKey -Name "LegacyDisable" -Value "" -PropertyType String -Force | Out-Null
        $hidden.Add($regKey)

        $label = (Get-ItemProperty $regKey -ErrorAction SilentlyContinue).MUIVerb
        if (-not $label) { $label = (Get-ItemProperty $regKey -ErrorAction SilentlyContinue).'(default)' }
        Write-Host "  [+] Hidden: $($regKey.Split('\')[-1])  ($label)" -ForegroundColor Green
    }
}

if ($hidden.Count -eq 0) {
    Write-Host "  Nothing to hide (no matching entries found)." -ForegroundColor DarkGray
} else {
    # Save exactly which keys WE modified — uninstall.ps1 reads this to restore
    $hidden.ToArray() | ConvertTo-Json | Set-Content -Path $backupFile -Encoding utf8
    Write-Host ""
    Write-Host "Backup saved to: $backupFile" -ForegroundColor Cyan
    Write-Host "Run uninstall.ps1 to restore these entries." -ForegroundColor Gray
}
