extends SceneTree

const ACTIONS := [&"idle",&"swim",&"look",&"stretch",&"rest",&"celebrate",&"breath",&"dragging"]
const NAMES := ["01  悬浮", "02  巡游", "03  感知", "04  舒展", "05  收息", "06  共鸣", "07  引光 · 聚光成笺", "08  牵引 / 释放"]
const NOTES := ["持续呼吸升降 · 玉片错相漂浮", "左右双向弧线 · 转向时倾斜领航", "左探 → 右探 → 回正 · 约 ±14°", "主核抬升 28 px · 双片向外各展 44 px", "主核下沉 25 px · 双片向内各收 19 px", "两次起伏 · 上升约 37 px · 双片上展", "蓄光 → 牵引 → 成笺 → 阅读 → 收光", "拖动位移由鼠标决定 · 此图只画跟随与释放归位"]

class Paths extends Node2D:
	var data: Array = []
	func _draw() -> void:
		for cell in data:
			var rect: Rect2 = cell.rect
			draw_style_box(_box(),rect)
			var center: Vector2 = rect.position+Vector2(230,220)
			for x in range(-150,151,50): draw_line(center+Vector2(x*1.1,-110),center+Vector2(x*1.1,83),Color(0.1,0.3,0.3,0.07),1)
			for y in range(-100,76,25): draw_line(center+Vector2(-175,y*1.1),center+Vector2(175,y*1.1),Color(0.1,0.3,0.3,0.07),1)
			var colors := [Color("6b9bb9"),Color("2c8d83"),Color("c29346")]
			for part in range(3):
				var line := PackedVector2Array()
				for frame in cell.frames:
					line.append(center+(Vector2(frame.parts[part][0],frame.parts[part][1])-Vector2(220,133))*1.1)
				draw_polyline(line,colors[part],2.1,true)
				draw_circle(line[0],3.5,colors[part])
				draw_arc(line[-1],6,0,TAU,24,colors[part],1.1,true)
				for index in [40,85,130,170]:
					var direction := (line[index+2]-line[index-2]).normalized()
					if direction.length() > 0.1:
						draw_polyline(PackedVector2Array([line[index]-direction.rotated(0.55)*7,line[index],line[index]-direction.rotated(-0.55)*7]),colors[part],1.4,true)
			# Faint tip path reveals angular motion even when the center stays put.
			var tip := PackedVector2Array()
			for index in range(0,cell.frames.size(),3):
				var frame: Dictionary = cell.frames[index]
				var point := Vector2(frame.parts[1][0],frame.parts[1][1])+Vector2(0,-75).rotated(frame.parts[1][2])
				tip.append(center+(point-Vector2(220,133))*1.1)
			draw_polyline(tip,Color(0.25,0.6,0.5,0.28),1,true)
	func _box() -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("f9faf5")
		box.border_color = Color("d8e1d8")
		box.set_border_width_all(1)
		box.set_corner_radius_all(12)
		return box

func _initialize() -> void:
	call_deferred("run")

func _label(text: String, point: Vector2, size: int, color := Color("284942")) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	root.add_child(label)

func _view(action: StringName):
	var view = load("res://pet/pet_view.gd").new()
	root.add_child(view)
	view.apply_skin(load("res://pet/skins/warm_jade/skin.tres"))
	view.set_process(false)
	view.select_action(action)
	return view

func run() -> void:
	root.size = Vector2i(1720,1630)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("e9eee8"))
	_label("温玉灵核 / 动作轨迹施工图",Vector2(30,20),32)
	_label("实际运行采样 · 单位 px · 轨迹图按 1.1× 绘制 · 主核不变形 · 动作结束回悬浮，浮动相位不断开",Vector2(32,67),18)
	_label("蓝：左玉片   青：主核中心   金：右玉片   浅青：主核上端转向轨迹   ● 起点   ○ 终点   › 方向",Vector2(32,98),18)
	var drawing := Paths.new()
	root.add_child(drawing)
	drawing.z_index = -1
	var export_data: Array = []
	for index in range(ACTIONS.size()):
		var offset := Vector2(25+(index%2)*850,145+(index/2)*365)
		var view = _view(ACTIONS[index])
		view.visible = false
		var duration: float = view.player.current_animation_length if ACTIONS[index] != &"dragging" else 4.0
		var frames: Array = []
		var light = null
		if ACTIONS[index] == &"breath":
			light = load("res://pet/effects/goal_light.gd").new()
			root.add_child(light)
			light.visible = false
		var released := false
		for sample in range(201):
			if ACTIONS[index] == &"dragging" and sample >= 60 and not released:
				view.play_action(&"idle")
				released = true
			if sample > 0: view._process(duration/200)
			var parts: Array = []
			for part: Transform2D in view.actor.parts: parts.append([snappedf(part.origin.x,0.01),snappedf(part.origin.y,0.01),snappedf(part.get_rotation(),0.001)])
			var frame := {"time":snappedf(sample*duration/200,0.001),"parts":parts}
			if light != null:
				light.set_frame(view.map_skin_point(view.skin.breath_anchor),1.0,sample*duration/200,"学习目标")
				light.visible = false
				var curve: Array = []
				for point_index in range(21):
					var point: Vector2 = light._curve(point_index/20.0)
					curve.append([point.x,point.y])
				frame["light"] = {"curve":curve,"scroll_alpha":light._sheet_alpha(),"flow_alpha":light._flow_alpha(),"returning":sample*duration/200 >= 5.0}
			frames.append(frame)
		if light != null: light.free()
		view.free()
		var cell := {"action":str(ACTIONS[index]),"duration":duration,"rect":Rect2(offset,Vector2(825,345)),"frames":frames}
		drawing.data.append(cell)
		export_data.append({"action":cell.action,"duration":duration,"frames":frames})
		_label(NAMES[index]+"   /   %.1f s" % duration,offset+Vector2(18,13),23)
		_label(NOTES[index],offset+Vector2(18,50),17)
		_label("轨迹 / 方向",offset+Vector2(20,92),15)
		_label("关键姿态  0% → 20% → 45% → 75% → 100%",offset+Vector2(420,92),14)
		for pose_index in range(5):
			var fraction: float = [0.0,0.2,0.45,0.75,1.0][pose_index]
			var pose = _view(ACTIONS[index])
			for step in range(ceilf(duration*fraction*60)):
				if ACTIONS[index] == &"dragging" and step == 72: pose.play_action(&"idle")
				pose._process(1.0/60)
			pose.scale = Vector2.ONE*0.23
			pose.position = offset+Vector2(452+pose_index*72,197)-Vector2(220,133)*0.23
			if ACTIONS[index] == &"breath":
				var effect = load("res://pet/effects/goal_light.gd").new()
				root.add_child(effect)
				effect.position = pose.position
				effect.scale = pose.scale
				effect.set_frame(pose.map_skin_point(pose.skin.breath_anchor)/0.23,1.0,duration*fraction,"学习目标")
			_label("%.1f" % (duration*fraction),offset+Vector2(438+pose_index*72,265),14)
		_label("每格 50 × 25 px · 伴生片跟随延迟 70 / 120 ms",offset+Vector2(23,316),14)
	var output := FileAccess.open("res://docs/screenshots/jade-motion-trajectories.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"units":"px, radians","source":"runtime sampled at 201 time points per action","actions":export_data}))
	output.close()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/jade-motion-blueprint.png")
	print("Motion blueprint and runtime trajectory samples exported")
	quit()
