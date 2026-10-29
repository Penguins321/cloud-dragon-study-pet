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
	file = FileAccess.open(destination.path_join("GOBKIT-ASSETS.txt"), FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string("res://pet/skins/animals/models/CC0-NOTICE.txt"))
	file.store_string("\nSource: https://gobkit.itch.io/gobkit-free-animal-pack\nManifest: https://gobkit.com/api/free\nModels: Corgi.glb, Duck.glb, Jellyfish.glb\nNormalized, lit and animated in Godot by this application.\n")
	file.close()
	quit()
