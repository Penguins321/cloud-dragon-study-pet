extends Node

signal import_path_selected(path: String)
signal export_path_selected(path: String, kind: String)
signal import_confirmed

var file_dialog := FileDialog.new()
var confirmation := ConfirmationDialog.new()
var summary_scroll := ScrollContainer.new()
var summary_label := Label.new()
var _export_kind := ""
var _configured := false
var _parent_window: Window

func setup(parent_window: Window) -> void:
	if _configured: return
	_configured = true
	_parent_window = parent_window
	file_dialog.use_native_dialog = true
	file_dialog.mode_overrides_title = false
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; 学习计划 JSON"])
	parent_window.add_child(file_dialog)
	file_dialog.file_selected.connect(_on_file_selected)
	confirmation.title = "确认导入学习计划"
	confirmation.ok_button_text = "替换当前计划"
	confirmation.cancel_button_text = "取消"
	confirmation.dialog_autowrap = true
	confirmation.theme = preload("res://ui/study_theme.tres").duplicate(true)
	parent_window.add_child(confirmation)
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary_scroll.follow_focus = true
	summary_scroll.focus_mode = Control.FOCUS_ALL
	summary_scroll.accessibility_name = "导入计划预览与替换说明"
	confirmation.add_child(summary_scroll)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_scroll.add_child(summary_label)
	confirmation.confirmed.connect(func(): import_confirmed.emit())

func choose_import() -> void:
	_export_kind = ""
	file_dialog.title = "导入学习计划"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered_ratio(0.75)

func choose_export(kind: String) -> void:
	if kind not in ["template","backup"]: return
	_export_kind = kind
	file_dialog.title = "导出模板" if kind == "template" else "导出备份"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = "学习计划模板.json" if kind == "template" else "学习计划备份.json"
	file_dialog.popup_centered_ratio(0.75)

func confirm_import(summary: String) -> void:
	summary_label.text = summary + "\n\n导入会替换当前整份计划。当前有效计划会先保留为导入前恢复点。确认后才会写入。"
	# Keep the full summary in a scrolling body; dialog actions remain outside it.
	# AcceptDialog still measures its hidden internal label, so leave it empty.
	confirmation.dialog_text = ""
	confirmation.get_label().hide()
	var bounds := _parent_window.size - Vector2i(32,32)
	bounds = Vector2i(maxi(1,bounds.x),maxi(1,bounds.y))
	confirmation.max_size = Vector2i(mini(480,bounds.x),mini(400,bounds.y))
	summary_scroll.custom_minimum_size.y = mini(120,maxi(32,bounds.y-140))
	confirmation.popup_centered_clamped(Vector2i(mini(480,bounds.x),mini(400,bounds.y)),0.95)

func _on_file_selected(path: String) -> void:
	if _export_kind.is_empty(): import_path_selected.emit(path)
	else: export_path_selected.emit(path,_export_kind)

func _exit_tree() -> void:
	# Dialogs belong to the host Window so native child windows work correctly.
	if is_instance_valid(file_dialog): file_dialog.queue_free()
	if is_instance_valid(confirmation): confirmation.queue_free()
