extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var service_path := "res://desktop/startup.gd"
	if not ResourceLoader.exists(service_path):
		check.call(false,"startup service exists")
		return
	var Startup = load(service_path)
	var directory := ProjectSettings.globalize_path("res://../.tools/startup-test 中文 ' $ & ()/" + str(OS.get_process_id()))
	var executable := OS.get_executable_path()
	var service = Startup.new(directory,executable)
	check.call(service.available,"Windows startup service available for isolated integration test")
	if not service.available: return
	var resolved: Dictionary = service._powershell("[Environment]::GetFolderPath('Startup','DoNotVerify')")
	check.call(resolved.code == 0 and String(resolved.text).is_absolute_path(),"Windows resolves the current user's Startup known folder without creating it")
	check.call(not service.is_enabled(),"startup defaults to off")
	check.call(service.set_enabled(true) == OK and service.is_enabled(),"enable creates actual Windows shortcut")
	check.call(service.set_enabled(true) == OK,"repeated enable is idempotent")
	# Read the actual shortcut with Windows COM, independently of service state.
	var output: Array = []
	var script := "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%s'); if($s.TargetPath -ne '%s' -or $s.WorkingDirectory -ne '%s' -or $s.Arguments -ne ''){exit 1}" % [service.shortcut_path.replace("'","''"),executable.replace("/","\\").replace("'","''"),executable.get_base_dir().replace("/","\\").replace("'","''")]
	var code := OS.execute("powershell.exe",["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-EncodedCommand",Marshalls.raw_to_base64(script.to_utf16_buffer())],output,true)
	if code != 0:
		print("Shortcut verification output: ",output)
	check.call(code == 0,"shortcut target and working directory preserve paths and have no engine flags")
	var sibling := directory.path_join("unrelated.txt")
	var file := FileAccess.open(sibling,FileAccess.WRITE)
	file.store_string("keep")
	file.close()
	check.call(service.set_enabled(false) == OK and not service.is_enabled(),"disable removes shortcut")
	check.call(service.set_enabled(false) == OK,"repeated disable is idempotent")
	check.call(FileAccess.file_exists(sibling),"disable preserves unrelated files")
	var blocked = Startup.new(sibling.path_join("subfolder"),executable)
	check.call(blocked.set_enabled(true) != OK and not blocked.is_enabled() and not blocked.message.is_empty(),"unwritable startup directory reports failure without enabling")
	DirAccess.remove_absolute(sibling)
	DirAccess.remove_absolute(directory)
	var missing = Startup.new(directory,directory.path_join("missing.exe"))
	check.call(missing.set_enabled(true) != OK and not missing.is_enabled(),"missing executable cannot create misleading startup state")
	var normal = Startup.new()
	check.call(not normal.available,"source/test mode cannot alter real system startup")
	var panel = load("res://ui/settings_panel.tscn").instantiate()
	tree.root.add_child(panel)
	panel.set_startup_state(true,false,"")
	var requests: Array[bool] = []
	panel.startup_requested.connect(func(enabled: bool): requests.append(enabled))
	panel.startup_button.button_pressed = true
	check.call(requests == [true],"settings emits startup enable request")
	panel.set_startup_state(true,false,"模拟写入失败")
	check.call(not panel.startup_button.button_pressed and panel.startup_status.text == "模拟写入失败","failed startup change restores real state and shows error")
	check.call(requests == [true],"refresh does not emit another system change")
	panel.set_startup_state(false,false,"请使用导出版")
	check.call(panel.startup_button.disabled,"source mode startup control disabled with explanation")
	panel.free()
