Unicode true
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
Name "温玉灵核"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\WarmJade"
RequestExecutionLevel user
SetCompressor /SOLID lzma
VIProductVersion "0.9.0.0"
VIAddVersionKey /LANG=2052 "ProductName" "温玉灵核"
VIAddVersionKey /LANG=2052 "FileDescription" "温玉灵核安装程序"
VIAddVersionKey /LANG=2052 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=2052 "LegalCopyright" "Warm Jade contributors"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_TEXT "安装完成。学习进度保存在当前用户的数据目录，卸载时会保留。可在设置中启用开机启动。"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"
Var TestMode
Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK "温玉灵核需要 64 位 Windows。" /SD IDOK
    SetErrorLevel 1
    Quit
  ${EndIf}
  SetShellVarContext current
  StrCpy $TestMode "0"
  ${GetParameters} $0
  ClearErrors
  ${GetOptions} $0 "/TESTMODE" $1
  ${IfNot} ${Errors}
    StrCpy $TestMode "1"
  ${Else}
    ReadRegStr $1 HKCU "Software\WarmJade" "InstallDir"
    ${If} $1 != ""
      StrCpy $INSTDIR $1
    ${EndIf}
  ${EndIf}
FunctionEnd
Function .onVerifyInstDir
  ${If} $EXEPATH == "$INSTDIR\WarmJade.exe"
    Abort
  ${EndIf}
FunctionEnd
Section "温玉灵核"
  ${If} $EXEPATH == "$INSTDIR\WarmJade.exe"
    Abort "不能覆盖正在运行的安装程序。"
  ${EndIf}
  SetOutPath "$INSTDIR"
  ClearErrors
  File /oname=WarmJade.exe "${PAYLOAD}"
  ${If} ${Errors}
    Abort "无法写入程序。请先退出正在运行的温玉，再重新安装。"
  ${EndIf}
  File "${ROOT}\desktop-pet\build\GODOT-LICENSE.txt"
  File "${ROOT}\desktop-pet\build\GODOT-THIRD-PARTY.json"
  File "${ROOT}\desktop-pet\packaging\remove-startup.ps1"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  ${If} $TestMode == "1"
    FileOpen $0 "$INSTDIR\.warmjade-test" w
    FileWrite $0 "Isolated packaging test"
    FileClose $0
  ${Else}
    CreateDirectory "$SMPROGRAMS\温玉灵核"
    CreateShortcut "$SMPROGRAMS\温玉灵核\温玉灵核.lnk" "$INSTDIR\WarmJade.exe"
    CreateShortcut "$SMPROGRAMS\温玉灵核\卸载.lnk" "$INSTDIR\Uninstall.exe"
    CreateShortcut "$DESKTOP\温玉灵核.lnk" "$INSTDIR\WarmJade.exe"
    WriteRegStr HKCU "Software\WarmJade" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "DisplayName" "温玉灵核"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "DisplayVersion" "${VERSION}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "InstallLocation" "$INSTDIR"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade" "NoRepair" 1
  ${EndIf}
SectionEnd
Function un.onInit
  SetShellVarContext current
FunctionEnd
Section "Uninstall"
  ClearErrors
  Delete "$INSTDIR\WarmJade.exe"
  ${If} ${Errors}
    Abort "温玉可能仍在运行，请先退出程序后重试卸载。"
  ${EndIf}
  IfFileExists "$INSTDIR\.warmjade-test" cleanup
  nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$INSTDIR\remove-startup.ps1"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_OK "开机启动快捷方式清理失败，请在 Windows 启动文件夹中手动检查。" /SD IDOK
  ${EndIf}
  ReadRegStr $0 HKCU "Software\WarmJade" "InstallDir"
  ${If} $0 == $INSTDIR
    Delete "$DESKTOP\温玉灵核.lnk"
    Delete "$SMPROGRAMS\温玉灵核\温玉灵核.lnk"
    Delete "$SMPROGRAMS\温玉灵核\卸载.lnk"
    RMDir "$SMPROGRAMS\温玉灵核"
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\WarmJade"
    DeleteRegKey HKCU "Software\WarmJade"
  ${EndIf}
  cleanup:

  Delete "$INSTDIR\GODOT-LICENSE.txt"
  Delete "$INSTDIR\GODOT-THIRD-PARTY.json"
  Delete "$INSTDIR\remove-startup.ps1"
  Delete "$INSTDIR\.warmjade-test"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd


