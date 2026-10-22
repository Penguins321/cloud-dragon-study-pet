extends SceneTree

func _initialize() -> void:
	var destination := ProjectSettings.globalize_path("res://build")
	DirAccess.make_dir_recursive_absolute(destination)
	var file := FileAccess.open(destination.path_join("GODOT-LICENSE.txt"), FileAccess.WRITE)
	file.store_string(Engine.get_license_text())
	file.close()
	file = FileAccess.open(destination.path_join("GODOT-THIRD-PARTY.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"copyright": Engine.get_copyright_info(), "licenses": Engine.get_license_info()}, "\t"))
	file.close()
	quit()
