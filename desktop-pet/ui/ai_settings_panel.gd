extends VBoxContainer

signal save_requested(config: Dictionary)
signal test_requested(config: Dictionary)
signal chat_requested

var enabled_button := CheckButton.new()
var provider := OptionButton.new()
var model_input := LineEdit.new()
var key_input := LineEdit.new()
var bubbles_button := CheckButton.new()
var save_button := Button.new()
var test_button := Button.new()
var status_label := Label.new()
var chat_button := Button.new()
var _selected_provider := "deepseek"

func _init() -> void:
	add_theme_constant_override("separation",8)
	_add_label("AI 陪伴",16)
	_add_label("自主陪伴默认关闭。自主决策发送角色、专注状态、闲置时长区间、最近动作和事件类型，也可能使用已保存偏好；不自动读取或发送任务内容、屏幕或文件。")
	_add_label("聊天会将最近对话、已保存偏好和当前伙伴性格发送给选定的服务商。关闭自主陪伴后仍可手动聊天。")
	enabled_button.text = "启用自主 AI 陪伴"
	add_child(enabled_button)
	_add_label("服务商")
	provider.add_item("DeepSeek")
	provider.add_item("OpenAI")
	provider.item_selected.connect(_provider_changed)
	add_child(provider)
	_add_label("模型")
	model_input.placeholder_text = "填写服务商提供的可用模型名称"
	model_input.accessibility_name = "AI 模型名称"
	add_child(model_input)
	_add_label("API Key")
	key_input.secret = true
	key_input.placeholder_text = "输入 API Key"
	key_input.accessibility_name = "AI API Key"
	add_child(key_input)
	_add_label("密钥以明文仅保存在本机用户数据目录的 ai_private.cfg；不纳入 Git 或学习备份。请勿分享此文件。")
	bubbles_button.text = "显示简短气泡"
	bubbles_button.button_pressed = true
	add_child(bubbles_button)
	save_button.text = "保存 AI 设置"
	save_button.pressed.connect(func(): save_requested.emit(_form_config()))
	add_child(save_button)
	test_button.text = "保存并测试连接"
	test_button.pressed.connect(func(): test_requested.emit(_form_config()))
	add_child(test_button)
	chat_button.text = "聊天与记忆…"
	chat_button.pressed.connect(func(): chat_requested.emit())
	add_child(chat_button)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",12)
	add_child(status_label)
	set_status("AI 陪伴默认关闭；未配置时继续本地陪伴。")

func _add_label(message: String, font_size := 12) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)

func set_config(config: Dictionary) -> void:
	enabled_button.set_pressed_no_signal(config.get("enabled",false))
	_selected_provider = "openai" if config.get("provider","deepseek") == "openai" else "deepseek"
	provider.select(1 if _selected_provider == "openai" else 0)
	model_input.text = config.get("model","")
	key_input.text = config.get("api_key","")
	bubbles_button.set_pressed_no_signal(config.get("bubbles",true))

func set_status(message: String, busy: bool = false) -> void:
	status_label.text = message.replace(key_input.text,"[密钥已隐藏]") if not key_input.text.is_empty() else message
	test_button.disabled = busy

func _provider_changed(index: int) -> void:
	var selected := "openai" if index == 1 else "deepseek"
	if selected == _selected_provider: return
	_selected_provider = selected
	model_input.clear()
	key_input.clear()
	set_status("已切换服务商，请填写对应模型和密钥。")

func _form_config() -> Dictionary:
	return {
		"enabled":enabled_button.button_pressed,
		"provider":_selected_provider,
		"model":model_input.text.strip_edges(),
		"api_key":key_input.text.strip_edges(),
		"bubbles":bubbles_button.button_pressed,
	}
