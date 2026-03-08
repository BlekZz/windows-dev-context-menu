$basePath = "HKCU:\Software\Classes\Directory\Background\shell\DevTools"

# 清除 HKCU
Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue

# 清除 HKCR（如果有殘留）
Remove-Item "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DevTools" -Recurse -Force -ErrorAction SilentlyContinue

# 清除 CommandStore（如果之前有使用過）
$csBase = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
@("DT.Terminal","DT.Pwsh","DT.GitBash","DT.VSCode","DT.Warp","DT.Antigravity","DT.PowerRename") | ForEach-Object {
    Remove-Item "$csBase\$_" -Recurse -Force -ErrorAction SilentlyContinue
}

# 清除測試用項目
Remove-Item "HKCU:\Software\Classes\Directory\Background\shell\TestItem" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Dev Tools context menu removed successfully!" -ForegroundColor Green
