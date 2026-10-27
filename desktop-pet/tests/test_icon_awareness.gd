extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var path := "res://desktop/icon_awareness.gd"
	if not ResourceLoader.exists(path):
		check.call(false,"desktop icon awareness service exists")
		return
	var awareness = load(path).new()
	tree.root.add_child(awareness)
	var snapshot := {"sequence":1,"available":true,"desktop_under_pointer":true,"pointer":[120,130],"icons":[[100,100,60,70],[300,100,60,70]]}
	awareness.accept_snapshot(snapshot,1000)
	var target: Dictionary = awareness.attention_target(Vector2(120,130),1100)
	check.call(target.get("point",Vector2.ZERO) == Vector2(130,135),"hovered real desktop icon becomes attention target")
	check.call(awareness.attention_target(Vector2(450,450),1100).is_empty(),"empty desktop does not attract attention")
	check.call(awareness.attention_target(Vector2(120,130),5001).is_empty(),"stale scanner snapshot cannot drive attention")
	snapshot.desktop_under_pointer = false
	snapshot.sequence = 2
	awareness.accept_snapshot(snapshot,5100)
	check.call(awareness.attention_target(Vector2(120,130),5200).is_empty(),"application-covered icons do not attract pet")
	snapshot.desktop_under_pointer = true
	snapshot.sequence = 3
	awareness.accept_snapshot(snapshot,6000)
	var window := Rect2(0,0,400,350)
	var footprint := Rect2(90,90,100,100)
	var area := Rect2(0,0,1200,900)
	var position: Vector2 = awareness.avoid_position(window,footprint,area,6100)
	check.call(position != window.position,"icon overlap finds a nearby unobstructed position")
	var moved := Rect2(footprint.position+position-window.position,footprint.size)
	var clear := true
	for icon in awareness.icons: clear = clear and not moved.intersects(icon.grow(12))
	check.call(clear and area.encloses(Rect2(position,window.size)),"avoidance clears all icons while retaining full animation window on screen")
	check.call(awareness.avoid_position(window,Rect2(700,600,80,100),area,6100) == window.position,"no overlap means no gratuitous roaming")
	awareness.accept_snapshot({"sequence":4,"available":false,"icons":[]},7000)
	check.call(awareness.attention_target(Vector2(120,130),7100).is_empty() and awareness.avoid_position(window,footprint,area,7100) == window.position,"unsupported desktop degrades to ordinary idle")
	awareness.accept_snapshot({"sequence":5,"available":true,"icons":[[INF,0,10,10],[0,0,-1,10],[1,2,30,40]],"desktop_under_pointer":true,"pointer":[10,10]},8000)
	check.call(awareness.icons.size() == 1,"malformed icon bounds are discarded")
	awareness.set_enabled(false)
	check.call(awareness.attention_target(Vector2(10,10),8100).is_empty(),"user can disable icon interactions")
	awareness.free()
	var actor = load("res://pet/skins/warm_jade/view.tscn").instantiate()
	tree.root.add_child(actor)
	actor.set_desktop_attention(Vector2.RIGHT)
	actor.advance_pose(0.3)
	check.call(actor.parts[1].get_rotation() > 0.04,"jade smoothly inclines toward an icon")
	actor.set_desktop_attention(Vector2.ZERO)
	actor.advance_pose(1.5)
	check.call(absf(actor.parts[1].get_rotation()) < 0.03,"icon attention smoothly returns to idle")
	actor.free()
