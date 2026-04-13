# 🛠️ Windows Dev Context Menu

A customizable Windows right-click context menu that provides quick access to your favorite development tools — terminals, editors, and utilities — all from one cascading "Dev Tools" submenu.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)

[繁體中文](README.zh-TW.md)

## ✨ Features

- **One-click access** to dev tools from the Windows Explorer context menu
- **Admin variants** for Windows Terminal and PowerShell 7 — launch elevated with a single click
- **No window flash** — menu clicks are dispatched via a hidden VBScript shim (`launcher.vbs`)
- **Auto-detection** of installed applications via `setup-env.ps1`
- **Skips uninstalled apps** — only installed tools appear in the menu
- **Error notifications** — if a path becomes invalid, a popup explains the issue
- **Hides duplicate entries** — optionally remove redundant per-app context menu items
- **Safe uninstall** — original context menu entries are fully restored on removal
- **Portable configuration** — paths stored in `.env`, not hardcoded
- **No admin required** for install/uninstall (admin only needed for hiding duplicates)

## 📦 Supported Tools

| Category  | Tool                       | Notes                                      |
|-----------|----------------------------|--------------------------------------------|
| Terminals | Windows Terminal           | Open folder in Windows Terminal            |
| Terminals | Windows Terminal (Admin)   | Open folder in Windows Terminal as admin   |
| Terminals | PowerShell 7               | Open folder in PowerShell 7                |
| Terminals | PowerShell 7 (Admin)       | Open folder in PowerShell 7 as admin       |
| Terminals | Git Bash                   | Open folder in Git Bash                    |
| Editors   | VS Code                    | Open folder in VS Code                     |
| Editors   | Warp                       | Open folder in Warp                        |
| Editors   | Antigravity                | Open folder in Antigravity                 |
| Tools     | PowerRename                | Launch PowerToys PowerRename               |

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

This adds a `LegacyDisable` flag to each duplicate entry — the original keys are not deleted. A backup of which entries were hidden is saved to `.hidden-entries.json` so that `uninstall.ps1` can fully restore them.

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
1. Restore all previously hidden context menu entries
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

1. **`setup-env.ps1`** scans your system for supported applications (known install paths + Scoop + PATH), then writes discovered paths to `.env`.
2. **`install.ps1`** reads `.env`, skips any `NOT_FOUND` entries, and registers a cascading context menu under `HKEY_CURRENT_USER`. Icons are pulled from each app's own `.exe`.
3. **`hide-duplicates.ps1`** (optional) adds `LegacyDisable` to known per-app context menu entries, suppressing them without deleting. Records what it changed in `.hidden-entries.json`.
4. When you click a menu item, Windows runs **`launcher.vbs`** via `wscript.exe` (fully invisible — no window flash), which in turn runs **`dev-launcher.ps1`** hidden. If a path is invalid, a popup message is shown. Admin variants use `Start-Process -Verb RunAs` to trigger a UAC prompt.
5. **`uninstall.ps1`** removes the Dev Tools menu and restores any previously hidden entries using the `.hidden-entries.json` backup.

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
   Add-MenuItem -Key "10myapp" -Label "Open with MyApp" -Action "myapp" -PathEnvName "MYAPP_PATH"
   ```

3. **Add launch logic** in `scripts/dev-launcher.ps1`:
   ```powershell
   "myapp" {
       Invoke-App $env:MYAPP_PATH "`"$path`"" "MyApp"
   }
   ```

4. **Add duplicate hiding** in `scripts/hide-duplicates.ps1` (if the app adds its own context menu entry):
   ```powershell
   "MYAPP_PATH" = @(
       "HKLM:\SOFTWARE\Classes\Directory\Background\shell\MyApp",
       "HKCU:\Software\Classes\Directory\Background\shell\MyApp"
   )
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
- Compatible with tools that restore the Windows 10 legacy context menu (e.g. ExplorerPatcher, Winaero Tweaker).

## 📄 License

MIT
