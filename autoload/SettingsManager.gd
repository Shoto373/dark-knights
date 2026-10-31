extends Node

## Глобальный менеджер настроек (экран, разрешение, звук, горячие клавиши)

const SETTINGS_FILE_PATH: String = "user://settings.json"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

const RESOLUTION_NAMES: Array[String] = [
	"1280 x 720 (HD)",
	"1600 x 900 (HD+)",
	"1920 x 1080 (Full HD)",
	"2560 x 1440 (2K QHD)"
]

const WINDOW_MODES: Array[String] = [
	"Полноэкранный",
	"Оконный",
	"Окно без рамок"
]

var current_window_mode_index: int = 1 # 0: Fullscreen, 1: Windowed, 2: Borderless
var current_resolution_index: int = 0 # 1280x720
var master_volume: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
			get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	if current_window_mode_index == 0:
		set_window_mode(1) # Switch to windowed
	else:
		set_window_mode(0) # Switch to fullscreen
	save_settings()

func set_window_mode(mode_idx: int) -> void:
	current_window_mode_index = clampi(mode_idx, 0, 2)
	match current_window_mode_index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			set_resolution(current_resolution_index)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			set_resolution(current_resolution_index)

func set_resolution(res_idx: int) -> void:
	current_resolution_index = clampi(res_idx, 0, RESOLUTIONS.size() - 1)
	if current_window_mode_index != 0:
		var target_size: Vector2i = RESOLUTIONS[current_resolution_index]
		DisplayServer.window_set_size(target_size)
		# Центрируем окно на экране
		var screen_id: int = DisplayServer.window_get_current_screen()
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_id)
		var target_pos: Vector2i = screen_rect.position + (screen_rect.size - target_size) / 2
		DisplayServer.window_set_position(target_pos)

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if master_volume <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))

func apply_settings() -> void:
	set_window_mode(current_window_mode_index)
	set_master_volume(master_volume)

func save_settings() -> void:
	var data: Dictionary = {
		"window_mode": current_window_mode_index,
		"resolution_index": current_resolution_index,
		"master_volume": master_volume
	}
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		return
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		current_window_mode_index = int(parsed.get("window_mode", 1))
		current_resolution_index = int(parsed.get("resolution_index", 0))
		master_volume = float(parsed.get("master_volume", 1.0))

