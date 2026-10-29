extends RefCounted

const NAMES := ["正常", "大一点", "戴眼镜", "老年人"]
const FACTORS := [1.0, 1.2, 1.45, 1.7]

static func valid_level(value: Variant) -> int:
	return value if value is int and value >= 0 and value < FACTORS.size() else 0

static func apply(control: Node, level: int) -> void:
	if control is Control and (control is Label or control is BaseButton or control is LineEdit or control is TextEdit):
		if not control.has_meta("normal_font_size"):
			control.set_meta("normal_font_size",control.get_theme_font_size("font_size"))
		control.add_theme_font_size_override("font_size",roundi(int(control.get_meta("normal_font_size"))*FACTORS[valid_level(level)]))
	# Do not scale the pet preview's own viewport or its artwork.
	if control is SubViewportContainer: return
	# ConfirmationDialog creates its label and action buttons as internal nodes.
	for child in control.get_children(true): apply(child,level)
