extends RefCounted

static func restore_position(saved: Vector2i, size: Vector2i, areas: Array[Rect2i]) -> Vector2i:
	if areas.is_empty():
		return saved
	var target := areas[0]
	var best_overlap := -1
	var rect := Rect2i(saved, size)
	for area in areas:
		var overlap := rect.intersection(area).get_area()
		if overlap > best_overlap:
			best_overlap = overlap
			target = area
	return Vector2i(
		clampi(saved.x, target.position.x, maxi(target.position.x, target.end.x - size.x)),
		clampi(saved.y, target.position.y, maxi(target.position.y, target.end.y - size.y))
	)

static func place_panel(pet_rect: Rect2i, panel_size: Vector2i, areas: Array[Rect2i]) -> Vector2i:
	var y := pet_rect.end.y - panel_size.y
	var candidates: Array[Vector2i] = [
		Vector2i(pet_rect.position.x - panel_size.x - 16, y),
		Vector2i(pet_rect.end.x + 16, y),
		Vector2i(pet_rect.position.x, pet_rect.position.y - panel_size.y - 16),
		Vector2i(pet_rect.position.x, pet_rect.end.y + 16)
	]
	for candidate in candidates:
		for area in areas:
			if area.encloses(Rect2i(candidate, panel_size)):
				return candidate
	return restore_position(candidates[0], panel_size, areas)

static func combine_input_regions(body: PackedVector2Array, bubble: PackedVector2Array) -> PackedVector2Array:
	# A doubled, zero-width bridge joins two contours without filling the gap.
	# Windows polygon regions use the paired edge only as a contour connection.
	if body.is_empty():
		return bubble.duplicate()
	if bubble.is_empty():
		return body.duplicate()
	var nearest_body := 0
	var distance := INF
	for i in body.size():
		var candidate := body[i].distance_squared_to(bubble[0])
		if candidate < distance:
			distance = candidate
			nearest_body = i
	var result := PackedVector2Array()
	result.append(body[nearest_body])
	for offset in bubble.size() + 1:
		result.append(bubble[offset % bubble.size()])
	for offset in body.size() + 1:
		result.append(body[(nearest_body + offset) % body.size()])
	return result
