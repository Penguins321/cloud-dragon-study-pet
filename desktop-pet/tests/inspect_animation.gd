extends SceneTree
func _initialize() -> void:
	var image := Image.load_from_file("res://titi/animation-sheet.png")
	for point in [Vector2i(0,0),Vector2i(200,100),Vector2i(384,350),Vector2i(20,600)]:
		print(point, ": ", image.get_pixelv(point))
	quit()
