extends CanvasLayer

## Маршрутизатор сцен с плавным переходом (Fade In / Fade Out)

signal transition_finished

var color_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(color_rect)
	
	EventBus.hit_stop_requested.connect(_on_hit_stop_requested)

func _on_hit_stop_requested(duration_ms: float) -> void:
	if duration_ms <= 0.0 or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	# Используем ignore_time_scale = true, чтобы таймер работал в реальном времени
	var duration_sec: float = (duration_ms / 1000.0)
	await get_tree().create_timer(duration_sec, true, false, true).timeout
	Engine.time_scale = 1.0

func change_scene(target_path: String, fade_duration: float = 0.3) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	var err: Error = get_tree().change_scene_to_file(target_path)
	if err != OK:
		push_error("SceneRouter: Failed to load scene: %s, code: %d" % [target_path, err])
	
	# Небольшая задержка для завершения инициализации сцены
	await get_tree().process_frame
	
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await fade_in_tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	transition_finished.emit()

