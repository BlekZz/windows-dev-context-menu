# 🛠️ Windows Dev Context Menu

A customizable Windows right-click context menu that provides quick access to your favorite development tools — terminals, editors, and utilities — all from one cascading "Dev Tools" submenu.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)

## ✨ Features

- **One-click access** to dev tools from the Windows Explorer context menu
- **Auto-detection** of installed applications via `setup-env.ps1`
- **Portable configuration** — paths stored in `.env`, not hardcoded
- **Easy customization** — add or remove tools by editing a single script
- **Compatible with Legacy context menus** (e.g. ExplorerPatcher, Winaero Tweaker)

## 📦 Supported Tools

| Category   | Tool                | Description                  |
|------------|---------------------|------------------------------|
| Terminals  | Windows Terminal    | Open folder in Windows Terminal |
| Terminals  | PowerShell 7        | Open folder in PowerShell 7  |
| Terminals  | Git Bash            | Open folder in Git Bash      |
| Editors    | VS Code             | Open folder in VS Code       |
| Editors    | Warp                | Open folder in Warp          |
| Editors    | Antigravity         | Open folder in Antigravity   |
| Tools      | PowerRename         | Launch PowerToys PowerRename |

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

This scans your system for all supported tools and generates a `.env` file with their paths.

### 3. Install the context menu

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

### 4. Done! 🎉

Right-click on any folder background in Windows Explorer to see the **Dev Tools** submenu.

## 🗑️ Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

## 📁 Project Structure

```
windows-dev-context-menu/
├── .env                        # Auto-generated app paths (git-ignored)
├── .gitignore
├── README.md
└── scripts/
    ├── setup-env.ps1           # Detects installed apps → generates .env
    ├── install.ps1             # Registers the context menu in Windows
    ├── uninstall.ps1           # Removes the context menu from Windows
    └── dev-launcher.ps1        # Core dispatcher (invoked by menu clicks)
```

## ⚙️ How It Works

```
Right-click folder → Dev Tools → Windows Terminal
                                         │
                                         ▼
                               dev-launcher.ps1
                                    loads .env
                                    finds WT_PATH
                                    launches wt.exe
```

1. **`setup-env.ps1`** scans your system for supported applications (via `PATH` lookup and common install locations), then writes the discovered paths to a `.env` file.
2. **`install.ps1`** reads the `.env` file and registers a cascading context menu under `HKEY_CURRENT_USER`, with icons pulled from the actual `.exe` files.
3. When you click a menu item, Windows invokes **`dev-launcher.ps1`** with the action name and the current folder path. The launcher loads `.env`, resolves the application path, and launches it.

## 🔧 Customization

### Adding a new tool

1. **Add detection** in `scripts/setup-env.ps1`:
   ```powershell
   "MYAPP_PATH" = Find-App "myapp" @("C:\Path\To\myapp.exe")
   ```

2. **Add menu entry** in `scripts/install.ps1`:
   ```powershell
   Add-MenuItem -Key "08myapp" -Label "Open with MyApp" -Action "myapp" -IconEnvName "MYAPP_PATH"
   ```

3. **Add launch logic** in `scripts/dev-launcher.ps1`:
   ```powershell
   "myapp" {
       Invoke-App $env:MYAPP_PATH "`"$path`"" "MyApp"
   }
   ```

4. Re-run setup and install:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
   powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
   ```

### Updating paths after installing/moving apps

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

## 📝 Notes

- The `.env` file is **git-ignored** since it contains machine-specific paths.
- The context menu is registered under `HKEY_CURRENT_USER`, so **no admin privileges** are required.
- Compatible with tools that restore the Windows 10 legacy context menu (e.g. ExplorerPatcher). Sub-menu items use `MUIVerb` for maximum compatibility.

## 📄 License

MIT
