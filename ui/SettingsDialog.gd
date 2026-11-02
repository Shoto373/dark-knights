class_name SettingsDialog
extends CanvasLayer

## Диалоговое окно настроек: Режимы экрана, разрешения, звук и клавиши

signal closed

@onready var mode_option: OptionButton = %ModeOption
@onready var res_option: OptionButton = %ResOption
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_label: Label = %VolumeLabel
@onready var check_glow: CheckBox = get_node_or_null("%CheckGlow") as CheckBox
@onready var check_post_process: CheckBox = get_node_or_null("%CheckPostProcess") as CheckBox
@onready var btn_apply: Button = %BtnApply
@onready var btn_close: Button = %BtnClose

func _ready() -> void:
	layer = 120
	
	_populate_options()
	_load_current_values()
	
	mode_option.item_selected.connect(_on_mode_selected)
	res_option.item_selected.connect(_on_res_selected)
	volume_slider.value_changed.connect(_on_volume_changed)
	btn_apply.pressed.connect(_on_apply_and_close)
	btn_close.pressed.connect(_on_close_pressed)

func _populate_options() -> void:
	mode_option.clear()
	for mode_name in SettingsManager.WINDOW_MODES:
		mode_option.add_item(mode_name)
	
	res_option.clear()
	for res_name in SettingsManager.RESOLUTION_NAMES:
		res_option.add_item(res_name)
	
	_style_popup(mode_option.get_popup())
	_style_popup(res_option.get_popup())

func _style_popup(popup: PopupMenu) -> void:
	if popup == null:
		return
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0, 1.0))
	popup.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.4, 1.0))
	popup.add_theme_color_override("font_separator_color", Color(0.4, 0.45, 0.55, 1.0))

func _load_current_values() -> void:
	mode_option.selected = SettingsManager.current_window_mode_index
	res_option.selected = SettingsManager.current_resolution_index
	res_option.disabled = (mode_option.selected == 0)
	
	var vol: float = SettingsManager.master_volume
	volume_slider.value = vol * 100.0
	volume_label.text = "%d%%" % int(vol * 100.0)
	
	if check_glow != null:
		check_glow.button_pressed = SettingsManager.glow_enabled
	if check_post_process != null:
		check_post_process.button_pressed = SettingsManager.postprocessing_enabled

func _on_mode_selected(index: int) -> void:
	res_option.disabled = (index == 0)

func _on_res_selected(_index: int) -> void:
	pass

func _on_volume_changed(val: float) -> void:
	volume_label.text = "%d%%" % int(val)
	SettingsManager.set_master_volume(val / 100.0)

func _on_apply_and_close() -> void:
	SettingsManager.set_window_mode(mode_option.selected)
	SettingsManager.set_resolution(res_option.selected)
	SettingsManager.set_master_volume(volume_slider.value / 100.0)
	if check_glow != null:
		SettingsManager.set_glow_enabled(check_glow.button_pressed)
	if check_post_process != null:
		SettingsManager.set_postprocessing_enabled(check_post_process.button_pressed)
	SettingsManager.save_settings()
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

