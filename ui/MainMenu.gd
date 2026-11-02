extends Control

## Главное меню: Темное фэнтези, живые искры, готические кнопки и настройки

const SETTINGS_DIALOG_SCENE: PackedScene = preload("res://ui/SettingsDialog.tscn")

@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

var _ember_timer: float = 0.0

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	if has_node("%SettingsPanel"):
		get_node("%SettingsPanel").visible = false
	btn_continue.disabled = not SaveManager.has_saved_run()
	
	_style_menu()

func _style_menu() -> void:
	var title_lbl: Label = get_node_or_null("CenterContainer/VBoxContainer/TitleLabel") as Label
	if title_lbl != null:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		title_lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.02, 1.0))
		title_lbl.add_theme_constant_override("outline_size", 6)
	
	var sub_lbl: Label = get_node_or_null("CenterContainer/VBoxContainer/SubtitleLabel") as Label
	if sub_lbl != null:
		sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		sub_lbl.text = "✦   ПУТЬ В ТЕМНОТУ И ИСКУПЛЕНИЕ   ✦"
	
	_style_button(btn_new_game)
	_style_button(btn_continue)
	_style_button(btn_settings)
	_style_button(btn_quit)

func _style_button(btn: Button) -> void:
	if btn == null:
		return
	
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.48, 0.4, 0.22)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.18, 0.22, 0.32, 1.0)
	hover.border_color = Color(0.95, 0.82, 0.3)
	
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.08, 0.09, 0.14, 1.0)
	pressed.border_color = Color(0.7, 0.55, 0.15)
	
	var disabled_style: StyleBoxFlat = normal.duplicate()
	disabled_style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
	disabled_style.border_color = Color(0.25, 0.25, 0.25, 0.5)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4))
	
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			AudioManager.play_sfx_named("swing")
			var tw: Tween = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.025, 1.025), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _process(delta: float) -> void:
	_ember_timer += delta
	if _ember_timer >= 0.18:
		_ember_timer = 0.0
		_spawn_menu_ember()

func _spawn_menu_ember() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var spawn_x: float = randf_range(0.0, vp_size.x)
	var spawn_pos: Vector2 = Vector2(spawn_x, vp_size.y + 10.0)
	var end_pos: Vector2 = Vector2(spawn_x + randf_range(-70.0, 70.0), randf_range(vp_size.y * 0.1, vp_size.y * 0.5))
	
	var ember: Sprite2D = Sprite2D.new()
	ember.texture = EffectsHelper.get_spark_texture()
	var sz: float = randf_range(0.3, 0.7)
	ember.scale = Vector2(sz, sz)
	ember.position = spawn_pos
	ember.modulate = Color(1.0, randf_range(0.4, 0.8), 0.15, randf_range(0.3, 0.65))
	add_child(ember)
	move_child(ember, 1) # Позади панелей
	
	var tw: Tween = ember.create_tween()
	var dur: float = randf_range(3.5, 6.0)
	tw.tween_property(ember, "position", end_pos, dur).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(ember, "modulate:a", 0.0, dur)
	tw.tween_callback(ember.queue_free)

func _on_new_game_pressed() -> void:
	AudioManager.play_sfx_named("cast")
	GameState.is_run_active = false
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx_named("cast")
	if SaveManager.has_saved_run():
		if SaveManager.load_run():
			if GameState.current_world_node_id == "hub" or not GameState.is_run_active:
				SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)
			else:
				SceneRouter.change_scene("res://levels/DungeonFloor.tscn", 0.3)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx_named("swing")
	var dialog: SettingsDialog = SETTINGS_DIALOG_SCENE.instantiate() as SettingsDialog
	add_child(dialog)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			for child in get_children():
				if child is SettingsDialog:
					child.queue_free()
					get_viewport().set_input_as_handled()
					return
			get_tree().quit()
