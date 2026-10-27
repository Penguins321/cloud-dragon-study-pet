extends RefCounted

class ProbeWindow extends "res://desktop/pet_window.gd":
	var popups := 0
	func _show_context_menu() -> void:
		popups += 1

static func run(tree: SceneTree, check: Callable) -> void:
	var previous_auto_accept := tree.auto_accept_quit
	tree.auto_accept_quit = false
	var desktop := ProbeWindow.new()
	tree.root.add_child(desktop)
	var requested: Array[String] = []
	desktop.quit_requested.connect(func(): requested.append("quit"))
	desktop.pet_visibility_changed.connect(func(_active: bool): requested.append("visibility"))
	tree.root.close_requested.emit()
	check.call(requested == ["quit"],"Windows close requests a real exit instead of hiding")
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_RIGHT
	down.pressed = true
	desktop._input(down)
	check.call(desktop.popups == 0,"pet context menu waits for right-button release")
	check.call(desktop.pointer_busy(),"right press blocks automatic desktop-icon avoidance")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_RIGHT
	desktop._input(up)
	await tree.process_frame
	check.call(desktop.popups == 1,"matching right press/release opens only one menu")
	desktop._input(up)
	await tree.process_frame
	check.call(desktop.popups == 1,"stray release cannot reopen menu")
	if desktop._tray != null and NativeMenu.has_feature(NativeMenu.FEATURE_POPUP_MENU):
		check.call(not desktop._tray.menu.is_empty() and desktop._tray.get_node(desktop._tray.menu) == desktop._menu,"tray uses Windows native menu binding")
		check.call(desktop._menu.is_native_menu(),"tray popup is actually bound to the native Windows menu")
	desktop.free()
	var pet = load("res://pet/pet_view.gd").new()
	tree.root.add_child(pet)
	pet.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
	pet.set_process(false)
	var phase: float = pet.actor.phase
	pet.set_interaction_paused(true)
	pet._process(0.2)
	check.call(pet.actor.phase == phase and pet.is_active(),"menu interaction freezes moving hit regions without hiding pet")
	pet.set_interaction_paused(false)
	pet._process(0.2)
	check.call(pet.actor.phase > phase,"dismissed menu resumes continuous hover")
	pet.free()
	tree.auto_accept_quit = previous_auto_accept
