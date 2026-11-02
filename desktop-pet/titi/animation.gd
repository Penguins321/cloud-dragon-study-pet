extends RefCounted

var clips: Dictionary = {}
var hulls: Dictionary = {}
# Measured head diameters in cropped atlas pixels, independent of tails,
# raised paws and transparent margins. One physical size across all actions.
var head_widths := {0: 300.0, 1: 250.0, 2: 260.0, 3: 305.0, 4: 205.0, 5: 270.0}

func load_sheet() -> void:
	var source: Image = load("res://titi/animation-sheet.png").get_image()
	# Hand-verified atlas cuts: generated tail tips cross the nominal grid.
	# Align torsos before applying a shared crop; never auto-center each frame.
	var cell := Vector2i(432, 512)
	var cuts := [[0, 408, 792, 1160, 1536], [0, 388, 774, 1152, 1536]]
	var offsets := [[0, 22, 23, 12], [0, 10, 4, 8]]
	for row in 2:
		var images: Array[Image] = []
		var bounds := Rect2i()
		for column in 4:
			var frame := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
			var region := Rect2i(cuts[row][column], row * 512, cuts[row][column + 1] - cuts[row][column], 512)
			frame.blit_rect(source, region, Vector2i(offsets[row][column], 0))
			_extract_sprite(frame)
			images.append(frame)
			var mask := BitMap.new()
			mask.create_from_image_alpha(frame, 0.12)
			for outline in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, cell), 1.0):
				for point in outline:
					var pixel := Rect2i(Vector2i(point), Vector2i.ONE)
					bounds = bounds.merge(pixel) if bounds.has_area() else pixel
		bounds = bounds.grow(2).intersection(Rect2i(Vector2i.ZERO, cell))
		var frames: Array[ImageTexture] = []
		var points := PackedVector2Array()
		for frame in images:
			var cropped := frame.get_region(bounds)
			frames.append(ImageTexture.create_from_image(cropped))
			var mask := BitMap.new()
			mask.create_from_image_alpha(cropped, 0.12)
			for outline in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, cropped.get_size()), 2.0):
				points.append_array(outline)
		var action := 1 if row == 0 else 4
		clips[action] = frames
		hulls[action] = Geometry2D.convex_hull(points)
	for entry in [[0, "lick"], [2, "yarn"], [3, "belly"], [5, "stretch"]]:
		_load_action(entry[0], entry[1])

func _load_action(action: int, name: String) -> void:
	var source: Image = load("res://titi/animation-" + name + ".png").get_image()
	var cell := Vector2i(source.get_width() / 2, source.get_height() / 2)
	# Atlas registration in source pixels: align fixed contact points instead
	# of independently centering frames (which would chase moving tails).
	var offsets: Array = {
		0: [Vector2i(0,0), Vector2i(30,0), Vector2i(0,58), Vector2i(30,58)],
		2: [Vector2i(0,0), Vector2i(30,0), Vector2i(0,100), Vector2i(20,100)],
		3: [Vector2i(0,0), Vector2i(40,0), Vector2i(0,40), Vector2i(40,40)],
		5: [Vector2i(0,0), Vector2i(40,0), Vector2i(0,60), Vector2i(40,60)]
	}[action]
	var canvas := cell + Vector2i(128, 128)
	var images: Array[Image] = []
	var bounds := Rect2i()
	for index in 4:
		var frame := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
		frame.blit_rect(source, Rect2i(Vector2i(index % 2, int(index / 2)) * cell, cell), offsets[index])
		images.append(frame)
		var mask := BitMap.new()
		mask.create_from_image_alpha(frame, 0.12)
		for outline in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, canvas), 1.0):
			for point in outline:
				var pixel := Rect2i(Vector2i(point), Vector2i.ONE)
				bounds = bounds.merge(pixel) if bounds.has_area() else pixel
	bounds = bounds.grow(2).intersection(Rect2i(Vector2i.ZERO, canvas))
	var frames: Array[ImageTexture] = []
	var points := PackedVector2Array()
	for frame in images:
		var cropped := frame.get_region(bounds)
		frames.append(ImageTexture.create_from_image(cropped))
		var mask := BitMap.new()
		mask.create_from_image_alpha(cropped, 0.12)
		for outline in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, cropped.get_size()), 2.0): points.append_array(outline)
	clips[action] = frames
	hulls[action] = Geometry2D.convex_hull(points)

# Atlas extraction: keep the cat's connected silhouette, not neighboring
# whisker fragments that cross a generated cell boundary. Retain a 1px AA rim.
func _extract_sprite(frame: Image) -> void:
	var mask := BitMap.new()
	mask.create_from_image_alpha(frame, 0.12)
	var area := Rect2i(Vector2i.ZERO, frame.get_size())
	var largest := PackedVector2Array()
	var largest_area := 0.0
	for outline in mask.opaque_to_polygons(area, 0.5):
		var polygon_area := 0.0
		for index in outline.size():
			polygon_area += outline[index].cross(outline[(index + 1) % outline.size()])
		if absf(polygon_area) > largest_area:
			largest_area = absf(polygon_area)
			largest = outline
	assert(not largest.is_empty())
	var keep := BitMap.new()
	keep.create(frame.get_size())
	for y in frame.get_height():
		for x in frame.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), largest): keep.set_bit(x, y, true)
	keep.grow_mask(1, area)
	for y in frame.get_height():
		for x in frame.get_width():
			if not keep.get_bit(x, y): frame.set_pixel(x, y, Color.TRANSPARENT)

func frame_index(action: int, elapsed: float) -> int:
	if action == 1:
		var time := fposmod(elapsed, 6.0)
		if time < 2.6: return 0
		if time < 2.72: return 1
		if time < 2.87: return 2
		if time < 2.99: return 1
		if time < 4.5: return 3
		return 0
	if action == 4:
		return [0, 1, 2, 3, 2, 1][int(fposmod(elapsed, 4.8) / 0.8)]
	var step: float = {0: 0.24, 2: 0.20, 3: 0.28, 5: 0.40}.get(action, 0.25)
	return [0, 1, 2, 3, 2, 1][int(fposmod(elapsed, step * 6.0) / step)]

func texture(action: int, elapsed: float) -> Texture2D:
	return clips[action][frame_index(action, elapsed)]

# Continuous local movement; the head and contact points stay stable.
func deformation(action: int, uv: Vector2, elapsed: float, extent: Vector2) -> Vector2:
	var above_ground := 1.0 - smoothstep(0.78, 0.95, uv.y)
	var amplitude := extent.x / 210.0
	if action == 4:
		var breath := (1.0 - cos(TAU * elapsed / 6.4)) * 0.5
		var back := smoothstep(0.38, 0.63, uv.x) * (1.0 - smoothstep(0.88, 1.0, uv.x))
		return Vector2(0, -1.8 * amplitude * breath * back * above_ground)
	if action == 5:
		var stretch := smoothstep(0.0, 1.0, elapsed) * (1.0 - smoothstep(1.9, 3.0, elapsed))
		var shoulder := exp(-pow((uv.x - 0.43) / 0.25, 2.0))
		var tail := smoothstep(0.70, 0.90, uv.x) * (1.0 - smoothstep(0.30, 0.50, uv.y))
		return Vector2(-1.6 * amplitude * stretch * tail, 1.7 * amplitude * stretch * shoulder * above_ground)
	return Vector2.ZERO
