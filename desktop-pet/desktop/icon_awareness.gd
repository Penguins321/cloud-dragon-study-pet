extends Node

signal state_changed

var enabled := true
var available := false
var status := "桌面图标感知尚未启动。"
var icons: Array[Rect2] = []
var desktop_under_pointer := false
var left_button_down := false
var cache_directory := ""
var _pointer := Vector2.ZERO
var _updated := -1
var _sequence := -1
var _active := false
var _pid := -1
var _snapshot_path := ""
var _poll_elapsed := 0.0

func set_enabled(value: bool) -> void:
	enabled = value
	if enabled and _active: _start_reader()
	else: _stop_reader()
	state_changed.emit()

func set_active(value: bool) -> void:
	_active = value
	if value and enabled: _start_reader()
	else: _stop_reader()

func _start_reader() -> void:
	if _pid > 0: return
	if OS.get_name() != "Windows" or DisplayServer.get_name() == "headless":
		status = "当前系统暂不支持桌面图标感知。"
		return
	if not OS.get_environment("CLOUD_DRAGON_DATA_DIR").is_empty():
		status = "隔离测试模式不读取真实桌面。"
		return
	var script := FileAccess.get_file_as_string("res://desktop/read_desktop_icons.ps1")
	if script.is_empty():
		status = "图标感知组件暂不可用，保持普通悬浮。"
		return
	var directory := OS.get_user_data_dir() if cache_directory.is_empty() else cache_directory
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		status = "图标感知暂不可用，保持普通悬浮。"
		return
	_snapshot_path = directory.path_join(".desktop-icons-%d.json" % OS.get_process_id())
	var invocation := "& { " + script + "\n } -SnapshotPath '" + _snapshot_path.replace("'","''") + "' -ParentProcessId " + str(OS.get_process_id())
	var encoded := Marshalls.raw_to_base64(invocation.to_utf16_buffer())
	if encoded.length() > 30000:
		status = "图标感知组件暂不可用，保持普通悬浮。"
		return
	_sequence = -1
	_updated = -1
	_pid = OS.create_process("powershell.exe",["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-EncodedCommand",encoded])
	status = "正在感知桌面图标…" if _pid > 0 else "当前桌面暂不可用，保持普通悬浮。"
	state_changed.emit()

func _stop_reader() -> void:
	var previous_pid := _pid
	if _pid > 0 and OS.is_process_running(_pid): OS.kill(_pid)
	_pid = -1
	available = false
	icons.clear()
	desktop_under_pointer = false
	_updated = -1
	status = "已关闭，保持普通悬浮。" if not enabled else "隐藏期间暂停图标感知。"
	if not _snapshot_path.is_empty():
		for path in [_snapshot_path,_snapshot_path+".tmp",_snapshot_path+"."+str(previous_pid)+".tmp"]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	state_changed.emit()

func _process(delta: float) -> void:
	if _pid <= 0: return
	_poll_elapsed += delta
	if _poll_elapsed < 0.5: return
	_poll_elapsed = 0.0
	if not OS.is_process_running(_pid):
		_stop_reader()
		status = "当前桌面暂不可用，保持普通悬浮。"
		state_changed.emit()
		return
	if not FileAccess.file_exists(_snapshot_path): return
	var file := FileAccess.open(_snapshot_path,FileAccess.READ)
	if file == null or file.get_length() > 262144: return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) == OK:
		accept_snapshot(parser.data,Time.get_ticks_msec())
	if _updated >= 0 and Time.get_ticks_msec()-_updated > 3500 and available:
		available = false
		status = "桌面图标读取暂停，保持普通悬浮。"
		state_changed.emit()

func accept_snapshot(data: Variant, now: int) -> void:
	if not data is Dictionary or not _number(data.get("sequence")) or not data.get("available") is bool: return
	var sequence := int(data.sequence)
	if sequence == _sequence: return
	_sequence = sequence
	_updated = now
	var previous := available
	var previous_status := status
	available = data.available
	icons.clear()
	var raw: Variant = data.get("icons",[])
	if raw is Array and available:
		for entry in raw.slice(0,512):
			if not entry is Array or entry.size() != 4: continue
			var valid := true
			for value in entry: valid = valid and _number(value) and absf(float(value)) <= 200000
			if valid and entry[2] > 0 and entry[3] > 0 and entry[2] <= 2048 and entry[3] <= 2048:
				icons.append(Rect2(entry[0],entry[1],entry[2],entry[3]))
	desktop_under_pointer = data.get("desktop_under_pointer",false) == true
	left_button_down = data.get("left_button_down",false) == true
	var pointer: Variant = data.get("pointer",[])
	if pointer is Array and pointer.size() == 2 and _number(pointer[0]) and _number(pointer[1]):
		_pointer = Vector2(pointer[0],pointer[1])
	else: desktop_under_pointer = false
	status = "靠近图标时轻轻转向，遮挡时自动让开。" if available else "当前桌面暂不可用，保持普通悬浮。"
	if previous != available or previous_status != status: state_changed.emit()

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func fresh(now: int) -> bool:
	return enabled and available and _updated >= 0 and now >= _updated and now-_updated <= 3500

func attention_target(pointer: Vector2, now: int) -> Dictionary:
	if not fresh(now) or not desktop_under_pointer or left_button_down or pointer.distance_to(_pointer) > 36: return {}
	for icon in icons:
		if icon.grow(10).has_point(pointer): return {"point":icon.get_center()}
	return {}

func avoid_position(window: Rect2, footprint: Rect2, area: Rect2, now: int) -> Vector2:
	if not fresh(now) or not desktop_under_pointer or left_button_down: return window.position
	var candidates: Array[Vector2] = []
	for icon in icons:
		var obstacle := icon.grow(12)
		if not footprint.intersects(obstacle): continue
		candidates.append_array([Vector2(obstacle.position.x-footprint.end.x-2,0),Vector2(obstacle.end.x-footprint.position.x+2,0),Vector2(0,obstacle.position.y-footprint.end.y-2),Vector2(0,obstacle.end.y-footprint.position.y+2)])
		if candidates.size() >= 64: break
	var best := window.position
	var distance := INF
	var maximum := area.position.max(area.end-window.size)
	for offset in candidates:
		var position := (window.position+offset).clamp(area.position,maximum)
		var shift := position-window.position
		if shift.length() > 260 or shift.length_squared() >= distance: continue
		var moved := Rect2(footprint.position+shift,footprint.size)
		var clear := true
		for icon in icons:
			if moved.intersects(icon.grow(12)):
				clear = false
				break
		if clear:
			best = position
			distance = shift.length_squared()
	return best

func _exit_tree() -> void:
	_stop_reader()
