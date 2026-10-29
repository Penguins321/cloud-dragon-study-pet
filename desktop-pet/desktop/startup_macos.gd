extends RefCounted

const LABEL := "org.warmjade.studycompanion"
var available := false
var message := ""
var shortcut_path := ""
var executable_path := ""

# Directory overrides isolate tests from the real login configuration.
func _init(directory_override := "", executable_override := "") -> void:
	if directory_override.is_empty():
		if OS.get_name() != "macOS" or OS.has_feature("editor") or not OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
			message = "请在正式导出的应用中设置自启动；开发和隔离测试不会修改系统配置。"
			return
	executable_path = OS.get_executable_path() if executable_override.is_empty() else executable_override
	if not FileAccess.file_exists(executable_path):
		message = "程序文件不存在，无法设置自启动。"
		return
	var directory: String = directory_override
	if directory.is_empty():
		var home_directory := OS.get_environment("HOME")
		if home_directory.is_empty():
			message = "无法读取用户目录。"
			return
		if executable_path.begins_with("/Volumes/") or executable_path.contains("/AppTranslocation/"):
			message = "请先将应用移到应用程序文件夹，再设置自启动。"
			return
		directory = home_directory.path_join("Library/LaunchAgents")
	shortcut_path = directory.path_join(LABEL + ".plist")
	available = true
	if is_enabled(): set_enabled(true)

func is_enabled() -> bool:
	return not shortcut_path.is_empty() and FileAccess.file_exists(shortcut_path)

func set_enabled(enabled: bool) -> Error:
	if not available: return ERR_UNAVAILABLE
	message = ""
	if not enabled:
		var error := DirAccess.remove_absolute(shortcut_path) if is_enabled() else OK
		if error != OK: message = "无法移除登录启动项，请检查目录权限。"
		return error
	if not FileAccess.file_exists(executable_path):
		message = "程序文件已移动或删除。"
		return ERR_FILE_NOT_FOUND
	var error := DirAccess.make_dir_recursive_absolute(shortcut_path.get_base_dir())
	if error != OK:
		message = "无法创建登录启动目录。"
		return error
	var temporary := shortcut_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "无法写入登录启动项。"
		return FileAccess.get_open_error()
	file.store_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\"><dict><key>Label</key><string>%s</string><key>ProgramArguments</key><array><string>%s</string></array><key>RunAtLoad</key><true/><key>LimitLoadToSessionType</key><string>Aqua</string></dict></plist>" % [LABEL, executable_path.xml_escape()])
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK: error = DirAccess.rename_absolute(temporary, shortcut_path)
	if error != OK:
		DirAccess.remove_absolute(temporary)
		message = "保存登录启动项失败。"
	else:
		message = "已设置，下次登录时自动启动；系统登录项设置也可能影响启动。"
	return error
