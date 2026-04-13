# 🛠️ Windows 開發者右鍵選單

在 Windows 檔案總管的右鍵選單中，新增一個「Dev Tools」子選單，讓你一鍵開啟常用的開發工具 — 終端機、編輯器、實用工具，全部集中管理。

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)

[English](README.md)

## ✨ 功能特色

- **一鍵開啟**常用開發工具，直接從檔案總管右鍵存取
- **Admin 提權選項**，Windows Terminal 與 PowerShell 7 各有對應的以系統管理員開啟選項
- **零閃爍啟動**，選單點擊透過隱形 VBScript shim（`launcher.vbs`）派送，不會出現閃爍的 PowerShell 視窗
- **自動偵測**已安裝的應用程式路徑，透過 `setup-env.ps1` 生成設定檔
- **自動跳過未安裝的工具**，選單只顯示真正裝了的 app
- **錯誤提示**，路徑失效時會彈出說明視窗
- **隱藏重複項目**，可選擇移除各 app 原本加入的右鍵選單項目，讓選單更乾淨
- **安全卸載**，卸載時完整還原被隱藏的原始項目
- **可攜式設定**，路徑儲存在 `.env`，不寫死在腳本裡
- **安裝/卸載不需要 admin**（隱藏重複項目才需要）

## 📦 支援的工具

| 分類   | 工具                          | 說明                                        |
|--------|-------------------------------|---------------------------------------------|
| 終端機 | Windows Terminal              | 在當前資料夾開啟 Windows Terminal            |
| 終端機 | Windows Terminal (Admin)      | 以系統管理員在當前資料夾開啟 Windows Terminal |
| 終端機 | PowerShell 7                  | 在當前資料夾開啟 PowerShell 7               |
| 終端機 | PowerShell 7 (Admin)          | 以系統管理員在當前資料夾開啟 PowerShell 7    |
| 終端機 | Git Bash                      | 在當前資料夾開啟 Git Bash                   |
| 編輯器 | VS Code                       | 以 VS Code 開啟資料夾                       |
| 編輯器 | Warp                          | 以 Warp 開啟資料夾                          |
| 編輯器 | Antigravity                   | 以 Antigravity 開啟資料夾                   |
| 工具   | PowerRename                   | 啟動 PowerToys PowerRename                  |

目前機器上未安裝的工具會自動跳過，不會出現在選單中。

## 🚀 快速開始

### 1. 複製專案

```bash
git clone https://github.com/BlekZz/windows-dev-context-menu.git
cd windows-dev-context-menu
```

### 2. 偵測已安裝的應用程式

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1
```

掃描系統中所有支援工具的路徑，生成 `.env` 設定檔。會自動搜尋常見安裝位置及 Scoop 安裝的套件。

### 3. 安裝右鍵選單

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

如果 `.env` 不存在，此步驟會自動執行 `setup-env.ps1`。

### 4. （選用）隱藏重複的右鍵項目

部分工具安裝時會自行加入右鍵選單（如 Git Bash、PowerShell 7、Warp 等）。若想讓選單更簡潔，可以用**系統管理員**身份執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\hide-duplicates.ps1
```

此腳本會在每個重複項目加上 `LegacyDisable` 旗標來隱藏它，**不會刪除任何 key**。修改過的項目會備份到 `.hidden-entries.json`，供卸載時還原。

### 5. 完成！🎉

在任意資料夾背景按右鍵，即可看到 **Dev Tools** 子選單。

## 🗑️ 卸載

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

若有隱藏項目備份（`.hidden-entries.json`），需以**系統管理員**身份執行才能完整還原：

```powershell
# 以系統管理員開啟 PowerShell，再執行：
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

卸載程序會：
1. 還原所有被隱藏的右鍵選單項目
2. 從 registry 移除 Dev Tools 子選單

## 📁 專案結構

```
windows-dev-context-menu/
├── .env                        # 自動生成的路徑設定（git-ignored）
├── .hidden-entries.json        # 各機器的隱藏項目備份（git-ignored）
├── .gitignore
├── README.md                   # English
├── README.zh-TW.md             # 繁體中文
└── scripts/
    ├── setup-env.ps1           # 偵測已安裝的 app → 生成 .env
    ├── install.ps1             # 將右鍵選單寫入 Windows Registry
    ├── hide-duplicates.ps1     # 隱藏各 app 原生的右鍵項目（需要 admin）
    ├── uninstall.ps1           # 移除選單並還原被隱藏的項目
    ├── launcher.vbs            # 隱形 shim，每次點選選單時被呼叫（零閃爍）
    └── dev-launcher.ps1        # 由 launcher.vbs 轉呼叫的啟動器主體
```

## ⚙️ 運作原理

```
右鍵資料夾背景 → Dev Tools → Git Bash
                                  │
                                  ▼
                        dev-launcher.ps1
                             讀取 .env
                             取得 GITBASH_PATH
                             啟動 git-bash.exe
```

1. **`setup-env.ps1`** 掃描系統，搜尋各工具的安裝路徑（已知路徑 + Scoop + PATH），將結果寫入 `.env`。
2. **`install.ps1`** 讀取 `.env`，跳過 `NOT_FOUND` 的項目，在 `HKEY_CURRENT_USER` 下建立子選單。每個選單項目的圖示直接從各 app 的 `.exe` 取得。
3. **`hide-duplicates.ps1`**（選用）對各 app 原生的右鍵項目加上 `LegacyDisable`，使其不顯示。修改紀錄存於 `.hidden-entries.json`。
4. 點選選單時，Windows 執行 **`launcher.vbs`**（完全隱形，無閃爍），再轉呼叫 **`dev-launcher.ps1`**。若路徑失效，會彈出錯誤提示。Admin 選項透過 `Start-Process -Verb RunAs` 觸發 UAC 提權。
5. **`uninstall.ps1`** 移除 Dev Tools 選單，並根據 `.hidden-entries.json` 備份還原被隱藏的項目。

## 🔧 自訂

### 新增工具

1. **新增偵測邏輯** — `scripts/setup-env.ps1`：
   ```powershell
   "MYAPP_PATH" = Find-App "myapp" @(
       "C:\Program Files\MyApp\myapp.exe",
       (Join-Path $local "Programs\MyApp\myapp.exe")
   )
   ```

2. **新增選單項目** — `scripts/install.ps1`：
   ```powershell
   Add-MenuItem -Key "10myapp" -Label "以 MyApp 開啟" -Action "myapp" -PathEnvName "MYAPP_PATH"
   ```

3. **新增啟動邏輯** — `scripts/dev-launcher.ps1`：
   ```powershell
   "myapp" {
       Invoke-App $env:MYAPP_PATH "`"$path`"" "MyApp"
   }
   ```

4. **新增隱藏規則**（若該 app 有自己的右鍵項目）— `scripts/hide-duplicates.ps1`：
   ```powershell
   "MYAPP_PATH" = @(
       "HKLM:\SOFTWARE\Classes\Directory\Background\shell\MyApp",
       "HKCU:\Software\Classes\Directory\Background\shell\MyApp"
   )
   ```

5. 重新執行 setup 和 install：
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
   powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
   ```

### 安裝或移動 app 後更新路徑

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1 -Force
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

## 📝 備註

- `.env` 與 `.hidden-entries.json` 已加入 **git-ignored**，這兩個檔案內容因機器而異。
- 右鍵選單寫入 `HKEY_CURRENT_USER`，**安裝與卸載不需要 admin**。
- 隱藏重複項目會修改 `HKEY_LOCAL_MACHINE` 的 key，**需要 admin**。
- 相容於還原 Windows 10 舊式右鍵選單的工具（如 ExplorerPatcher、Winaero Tweaker）。

## 📄 授權

MIT
