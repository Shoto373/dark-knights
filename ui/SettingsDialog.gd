class_name SettingsDialog
extends CanvasLayer

## Диалоговое окно настроек: Режимы экрана, разрешения, звук и клавиши

signal closed

@onready var mode_option: OptionButton = %ModeOption
@onready var res_option: OptionButton = %ResOption
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_label: Label = %VolumeLabel
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

func _load_current_values() -> void:
	mode_option.selected = SettingsManager.current_window_mode_index
	res_option.selected = SettingsManager.current_resolution_index
	res_option.disabled = (mode_option.selected == 0)
	
	var vol: float = SettingsManager.master_volume
	volume_slider.value = vol * 100.0
	volume_label.text = "%d%%" % int(vol * 100.0)

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
	SettingsManager.save_settings()
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
