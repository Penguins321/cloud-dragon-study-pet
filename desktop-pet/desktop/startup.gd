extends RefCounted

const SHORTCUT_NAME := "WarmJadeStudyCompanion.lnk"
var available := false
var message := ""
var shortcut_path := ""
var executable_path := ""

# Overrides are used only by integration tests, never by normal app startup.
func _init(directory_override := "", executable_override := "") -> void:
	if OS.get_name() != "Windows":
		message = "开机自启动仅支持 Windows。"
		return
	if directory_override.is_empty() and (OS.has_feature("editor") or not OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty()):
		message = "请在正式导出的 EXE 中设置自启动；开发和隔离测试模式不修改系统配置。"
		return
	executable_path = OS.get_executable_path() if executable_override.is_empty() else executable_override
	if not FileAccess.file_exists(executable_path):
		message = "程序文件不存在，无法设置自启动。"
		return
	var directory: String = directory_override
	if directory.is_empty():
		var result := _powershell("[Environment]::GetFolderPath('Startup','DoNotVerify')")
		if result.code != 0 or result.text.is_empty():
			message = "无法读取 Windows 启动目录。" + result.text
			return
		directory = result.text
	shortcut_path = directory.path_join(SHORTCUT_NAME)
	available = true

func is_enabled() -> bool:
	return not shortcut_path.is_empty() and FileAccess.file_exists(shortcut_path)

func set_enabled(enabled: bool) -> Error:
	if not available:
		return ERR_UNAVAILABLE
	message = ""
	if not enabled:
		var error := DirAccess.remove_absolute(shortcut_path) if is_enabled() else OK
		if error != OK: message = "未能移除自启动快捷方式，请检查启动目录的写入权限。"
		return error
	if not FileAccess.file_exists(executable_path):
		message = "程序文件已移动或删除，无法设置自启动。"
		return ERR_FILE_NOT_FOUND
	var directory_error := DirAccess.make_dir_recursive_absolute(shortcut_path.get_base_dir())
	if directory_error != OK:
		message = "无法创建 Windows 启动目录。"
		return directory_error
	var script := """$link = (New-Object -ComObject WScript.Shell).CreateShortcut(%s)
$link.TargetPath = %s
$link.WorkingDirectory = %s
$link.Arguments = ''
$link.Description = 'Warm Jade Study Companion'
$link.WindowStyle = 1
$link.Save()
""" % [_literal(shortcut_path),_literal(executable_path.replace("/","\\")),_literal(executable_path.get_base_dir().replace("/","\\"))]
	var result := _powershell(script)
	if result.code != 0 or not is_enabled():
		message = "未能启用自启动：" + result.text
		return ERR_CANT_CREATE
	return OK

func _literal(value: String) -> String:
	return "'" + value.replace("'","''") + "'"

func _powershell(script: String) -> Dictionary:
	# Encode the entire script as UTF-16LE; paths remain literal data even with
	# Chinese text, quotes, dollars or shell metacharacters. No cmd.exe involved.
	var command := "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false); try { " + script + " } catch { [Console]::WriteLine($_.Exception.Message); exit 1 }"
	var output: Array = []
	var code := OS.execute("powershell.exe",["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-EncodedCommand",Marshalls.raw_to_base64(command.to_utf16_buffer())],output,true)
	return {"code":code,"text":"".join(output).strip_edges()}
