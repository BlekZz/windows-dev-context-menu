Dim shell, psFile, action, path, cmd
Set shell = CreateObject("WScript.Shell")

psFile = Replace(WScript.ScriptFullName, WScript.ScriptName, "dev-launcher.ps1")
action = WScript.Arguments(0)
path   = WScript.Arguments(1)

cmd = "powershell.exe -WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass" _
    & " -File """ & psFile & """" _
    & " -action " & action _
    & " -path """ & path & """"

shell.Run cmd, 0, False
