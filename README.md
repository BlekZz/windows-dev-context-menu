# 🛠️ Windows Dev Context Menu

A customizable Windows right-click context menu that provides quick access to your favorite development tools — terminals, editors, and utilities — all from one cascading "Dev Tools" submenu.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)

[繁體中文](README.zh-TW.md)

## ✨ Features

- **One-click access** to dev tools from the Windows Explorer context menu
- **Admin variants** for Command Prompt and PowerShell 7 — launch elevated with a single click
- **No window flash** — menu clicks are dispatched via a hidden VBScript shim (`launcher.vbs`)
- **Auto-detection** of installed applications via `setup-env.ps1`
- **Latest PowerShell version** — enumerates all installed PS7 versions and picks the highest
- **Skips uninstalled apps** — only installed tools appear in the menu
- **Error notifications** — if a path becomes invalid, a popup explains the issue
- **Deduplication** — hides redundant per-app context menu entries (supports both `LegacyDisable` shell verb keys and COM shellex handler removal)
- **Safe uninstall** — original context menu entries are fully restored on removal
- **Portable configuration** — paths stored in `.env`, not hardcoded
- **No admin required** for install/uninstall (admin only needed for hiding duplicates)

## 📦 Supported Tools

| Category  | Tool                       | Notes                                       |
|-----------|----------------------------|---------------------------------------------|
| Terminals | Command Prompt             | Open folder in cmd.exe                      |
| Terminals | Command Prompt (Admin)     | Open folder in cmd.exe as administrator     |
| Terminals | PowerShell 7               | Open folder in PowerShell 7 (latest version)|
| Terminals | PowerShell 7 (Admin)       | Open folder in PowerShell 7 as administrator|
| Terminals | Git Bash                   | Open folder in Git Bash                     |
| Editors   | VS Code                    | Open folder in VS Code                      |
| Editors   | Warp                       | Open folder in Warp                         |
| Editors   | Antigravity                | Open folder in Antigravity                  |
| Tools     | Power Rename               | Launch PowerToys Power Rename               |
| Tools     | Open with Visual Studio    | Open folder in Visual Studio (or VSLauncher)|

Tools not installed on the current machine are automatically skipped — they won't appear in the menu.

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/BlekZz/windows-dev-context-menu.git
cd windows-dev-context-menu
```

### 2. Detect installed applications

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1
```

Scans your system for all supported tools and generates a `.env` file with their paths. Searches common install locations as well as Scoop-managed packages.

### 3. Install the context menu

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

If `.env` is missing, this step runs `setup-env.ps1` automatically.

### 4. (Optional) Hide duplicate entries

Some apps (Git Bash, PowerShell 7, Warp, etc.) add their own right-click entries when installed. If you want a cleaner menu, run this as **administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\hide-duplicates.ps1
```

This suppresses duplicate entries using two methods:
- **`LegacyDisable`** — for standard `shell\<verb>` keys (no deletion, fully reversible)
- **Key deletion** — for COM `shellex\ContextMenuHandlers` entries (e.g. PowerToys Power Rename), where `LegacyDisable` has no effect

A backup of all changes is saved to `.hidden-entries.json` so that `uninstall.ps1` can fully restore them.

### 5. Done! 🎉

Right-click on any folder background in Windows Explorer to see the **Dev Tools** submenu.

## 🗑️ Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

If hidden entries exist (`.hidden-entries.json`), run as **administrator** to restore them:

```powershell
# Run PowerShell as administrator, then:
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

The uninstaller will:
1. Restore all previously hidden context menu entries (both `LegacyDisable` and shellex handlers)
2. Remove the Dev Tools submenu from the registry

## 📁 Project Structure

```
windows-dev-context-menu/
├── .env                        # Auto-generated app paths (git-ignored)
├── .hidden-entries.json        # Backup of hidden entries per machine (git-ignored)
├── .gitignore
├── README.md
├── README.zh-TW.md
└── scripts/
    ├── setup-env.ps1           # Detects installed apps → generates .env
    ├── install.ps1             # Registers the context menu in Windows registry
    ├── hide-duplicates.ps1     # Hides per-app context menu entries (requires admin)
    ├── uninstall.ps1           # Removes context menu and restores hidden entries
    ├── launcher.vbs            # Hidden shim invoked on every menu click (no window flash)
    └── dev-launcher.ps1        # Dispatcher that launcher.vbs hands off to
```

## ⚙️ How It Works

```
Right-click folder background → Dev Tools → Git Bash
                                                │
                                                ▼
                                      dev-launcher.ps1
                                           loads .env
                                           finds GITBASH_PATH
                                           launches git-bash.exe
```

1. **`setup-env.ps1`** scans your system for supported applications (known install paths + Scoop + PATH), then writes discovered paths to `.env`. PowerShell 7 detection enumerates all version subdirectories under `Program Files\PowerShell\` and selects the highest file version.
2. **`install.ps1`** reads `.env`, skips any `NOT_FOUND` entries, and registers a cascading context menu under `HKEY_CURRENT_USER`. MSIX-packaged apps (PowerToys, etc.) use explicit `shell32.dll` icon references instead of exe-based extraction, which fails for packaged apps.
3. **`hide-duplicates.ps1`** (optional) suppresses duplicate entries in two ways: `LegacyDisable` for shell verb keys, and key deletion for COM shellex handlers. Backs up all changes to `.hidden-entries.json`. Note: `shell\cmd` and `shell\Powershell` are TrustedInstaller-owned and cannot be modified — they only appear in the classic "Show more options" menu anyway.
4. When you click a menu item, Windows runs **`launcher.vbs`** via `wscript.exe` (fully invisible — no window flash), which in turn runs **`dev-launcher.ps1`** hidden. If a path is invalid, a popup message is shown. Admin variants use `Start-Process -Verb RunAs` to trigger a UAC prompt.
5. **`uninstall.ps1`** removes the Dev Tools menu and restores any previously hidden entries using the `.hidden-entries.json` backup. Supports both the old (plain array) and new (`{ legacyDisable, shellex }`) backup formats.

## 🔧 Customization

### Adding a new tool

1. **Add detection** in `scripts/setup-env.ps1`:
   ```powershell
   "MYAPP_PATH" = Find-App "myapp" @(
       "C:\Program Files\MyApp\myapp.exe",
       (Join-Path $local "Programs\MyApp\myapp.exe")
   )
   ```

2. **Add menu entry** in `scripts/install.ps1`:
   ```powershell
   # For regular apps — icon extracted from exe automatically:
   Add-MenuItem -Key "11myapp" -Label "Open with MyApp" -Action "myapp" -PathEnvName "MYAPP_PATH"

   # For MSIX-packaged apps — specify an explicit DLL icon:
   Add-MenuItem -Key "11myapp" -Label "Open with MyApp" -Action "myapp" -PathEnvName "MYAPP_PATH" -Icon "shell32.dll,269"
   ```

3. **Add launch logic** in `scripts/dev-launcher.ps1`:
   ```powershell
   "myapp" {
       Invoke-App $env:MYAPP_PATH "`"$path`"" "MyApp"
   }
   ```

4. **Add duplicate hiding** in `scripts/hide-duplicates.ps1`:
   ```powershell
   # For standard shell verb keys — add to $appToKeys:
   "MYAPP_PATH" = @(
       "HKLM:\SOFTWARE\Classes\Directory\Background\shell\MyApp",
       "HKCU:\Software\Classes\Directory\Background\shell\MyApp"
   )

   # For COM shellex handlers — add to $shelexTargets:
   "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\MyAppExt"
   ```

5. Re-run setup and install:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
   powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
   ```

### Updating paths after installing or moving apps

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

## 📝 Notes

- `.env` and `.hidden-entries.json` are **git-ignored** — they contain machine-specific paths and state.
- The context menu is registered under `HKEY_CURRENT_USER` — **no admin required** for install/uninstall.
- Hiding duplicate entries modifies `HKEY_LOCAL_MACHINE` keys, which **requires admin**.
- `shell\cmd` and `shell\Powershell` are protected by TrustedInstaller and cannot be suppressed via script. They only appear in the "Show more options" classic context menu.
- The Windows 11 native **"Open in Terminal"** option in the main context menu is a built-in OS feature, not a registry shell key. To remove it, go to **Windows Settings → System → For developers → Terminal** and set it to "Windows Console Host".
- Compatible with tools that restore the Windows 10 legacy context menu (e.g. ExplorerPatcher, Winaero Tweaker).

## 📄 License

MIT
