class_name HUD
extends CanvasLayer

## Игровой интерфейс (HUD): Здоровье, Способности, Полоска Босса, Экран смерти, Всплывающий урон, Ключи

@onready var hp_bar: ProgressBar = %PlayerHpBar
@onready var hp_label: Label = %PlayerHpLabel
@onready var dash_bar: ProgressBar = %DashBar
@onready var ability_1_bar: ProgressBar = %Ability1Bar
@onready var ability_2_bar: ProgressBar = %Ability2Bar
@onready var ability_1_label: Label = %Ability1Label
@onready var ability_2_label: Label = %Ability2Label
@onready var hero_portrait: TextureRect = %HeroPortrait
@onready var hero_name_label: Label = %HeroNameLabel
@onready var souls_label: Label = %SoulsLabel
@onready var gold_label: Label = %GoldLabel
@onready var keys_label: Label = %KeysLabel

@onready var boss_bar_container: Control = %BossBarContainer
@onready var boss_hp_bar: ProgressBar = %BossHpBar
@onready var boss_name_label: Label = %BossNameLabel

@onready var death_screen: Control = %DeathScreen
@onready var btn_respawn: Button = %BtnRespawn
@onready var damage_numbers_container: Control = %DamageNumbersContainer

@onready var dash_label: Label = get_node_or_null("%DashLabel") as Label
@onready var dash_timer_label: Label = get_node_or_null("%DashTimerLabel") as Label
@onready var ability_1_container: Control = get_node_or_null("%Ability1Container") as Control
@onready var ability_1_timer_label: Label = get_node_or_null("%Ability1TimerLabel") as Label
@onready var ability_2_container: Control = get_node_or_null("%Ability2Container") as Control
@onready var ability_2_timer_label: Label = get_node_or_null("%Ability2TimerLabel") as Label

var player_ref: Player = null
var ghost_hp_bar: ProgressBar = null
var boss_ghost_hp_bar: ProgressBar = null
var _hp_ghost_tween: Tween = null
var _boss_ghost_tween: Tween = null

var _prev_dash_ready: bool = true
var _prev_ability1_ready: bool = true
var _prev_ability2_ready: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	death_screen.visible = false
	boss_bar_container.visible = false
	btn_respawn.pressed.connect(_on_respawn_pressed)
	
	_setup_ghost_health_bars()
	
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.hero_changed.connect(_on_hero_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.currency_changed.connect(_on_currency_changed)
	
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	
	_update_hero_info()
	_on_currency_changed(GameState.gold, MetaProgress.souls)
	
	# Если игрок уже заспавнен в сцене (до создания HUD)
	if not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_on_player_spawned(players[0] as Player)

func _setup_ghost_health_bars() -> void:
	# AAA Ghost / Damage Lag Bar для шкалы здоровья игрока
	if hp_bar != null:
		ghost_hp_bar = ProgressBar.new()
		ghost_hp_bar.name = "PlayerHpGhostBar"
		ghost_hp_bar.max_value = hp_bar.max_value
		ghost_hp_bar.value = hp_bar.value
		ghost_hp_bar.show_percentage = false
		ghost_hp_bar.custom_minimum_size = hp_bar.custom_minimum_size
		ghost_hp_bar.size = hp_bar.size
		
		var ghost_fill: StyleBoxFlat = StyleBoxFlat.new()
		ghost_fill.bg_color = Color(1.0, 0.85, 0.45, 0.95)
		ghost_fill.border_width_top = 1
		ghost_fill.border_color = Color(1.0, 1.0, 0.8, 1.0)
		ghost_fill.corner_radius_top_left = 3
		ghost_fill.corner_radius_top_right = 3
		ghost_fill.corner_radius_bottom_right = 3
		ghost_fill.corner_radius_bottom_left = 3
		ghost_hp_bar.add_theme_stylebox_override("fill", ghost_fill)
		ghost_hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
		
		hp_bar.get_parent().add_child(ghost_hp_bar)
		hp_bar.get_parent().move_child(ghost_hp_bar, hp_bar.get_index())
	
	# AAA Ghost / Damage Lag Bar для шкалы босса
	if boss_hp_bar != null:
		boss_ghost_hp_bar = ProgressBar.new()
		boss_ghost_hp_bar.name = "BossHpGhostBar"
		boss_ghost_hp_bar.max_value = boss_hp_bar.max_value
		boss_ghost_hp_bar.value = boss_hp_bar.value
		boss_ghost_hp_bar.show_percentage = false
		boss_ghost_hp_bar.custom_minimum_size = boss_hp_bar.custom_minimum_size
		
		var boss_ghost_fill: StyleBoxFlat = StyleBoxFlat.new()
		boss_ghost_fill.bg_color = Color(1.2, 0.88, 0.4, 0.95)
		boss_ghost_fill.corner_radius_top_left = 4
		boss_ghost_fill.corner_radius_top_right = 4
		boss_ghost_fill.corner_radius_bottom_right = 4
		boss_ghost_fill.corner_radius_bottom_left = 4
		boss_ghost_hp_bar.add_theme_stylebox_override("fill", boss_ghost_fill)
		boss_ghost_hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
		
		boss_hp_bar.get_parent().add_child(boss_ghost_hp_bar)
		boss_hp_bar.get_parent().move_child(boss_ghost_hp_bar, boss_hp_bar.get_index())

func _process(_delta: float) -> void:
	if not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_ref = players[0] as Player
			_update_hero_info()

	if is_instance_valid(player_ref):
		var d_ratio: float = player_ref.get_dash_cooldown_ratio()
		var a1_ratio: float = player_ref.get_ability_cooldown_ratio(1)
		var a2_ratio: float = player_ref.get_ability_cooldown_ratio(2)
		
		dash_bar.value = d_ratio * 100.0
		ability_1_bar.value = a1_ratio * 100.0
		ability_2_bar.value = a2_ratio * 100.0
		
		# 1. Рывок (Dash)
		if d_ratio < 1.0:
			var d_time: float = player_ref.get_dash_cooldown_time_left()
			if dash_timer_label != null:
				dash_timer_label.text = "%.1fс" % d_time
				dash_timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
			if dash_label != null:
				dash_label.modulate.a = 0.55
		else:
			if dash_timer_label != null:
				dash_timer_label.text = "ГОТОВ"
				dash_timer_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
			if dash_label != null:
				dash_label.modulate.a = 1.0
			if not _prev_dash_ready:
				_pulse_cooldown_ready(dash_bar, dash_timer_label)
		_prev_dash_ready = (d_ratio >= 1.0)
		
		# 2. Способность 1 (Q)
		if a1_ratio < 1.0:
			var a1_time: float = player_ref.get_ability_cooldown_time_left(1)
			if ability_1_timer_label != null:
				ability_1_timer_label.text = "%.1fс" % a1_time
				ability_1_timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
			if ability_1_label != null:
				ability_1_label.modulate.a = 0.55
		else:
			if ability_1_timer_label != null:
				ability_1_timer_label.text = "ГОТОВ"
				ability_1_timer_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
			if ability_1_label != null:
				ability_1_label.modulate.a = 1.0
			if not _prev_ability1_ready:
				_pulse_cooldown_ready(ability_1_bar, ability_1_timer_label)
		_prev_ability1_ready = (a1_ratio >= 1.0)
		
		# 3. Способность 2 (E)
		if a2_ratio < 1.0:
			var a2_time: float = player_ref.get_ability_cooldown_time_left(2)
			if ability_2_timer_label != null:
				ability_2_timer_label.text = "%.1fс" % a2_time
				ability_2_timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
			if ability_2_label != null:
				ability_2_label.modulate.a = 0.55
		else:
			if ability_2_timer_label != null:
				ability_2_timer_label.text = "ГОТОВ"
				ability_2_timer_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
			if ability_2_label != null:
				ability_2_label.modulate.a = 1.0
			if not _prev_ability2_ready:
				_pulse_cooldown_ready(ability_2_bar, ability_2_timer_label)
		_prev_ability2_ready = (a2_ratio >= 1.0)
		
	keys_label.text = "%d" % GameState.keys

func _pulse_cooldown_ready(target_control: Control, timer_label: Label = null) -> void:
	if target_control != null:
		var tween: Tween = target_control.create_tween()
		target_control.modulate = Color(2.4, 2.4, 2.7, 1.0)
		tween.tween_property(target_control, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD)
	if timer_label != null:
		var l_tween: Tween = timer_label.create_tween()
		timer_label.scale = Vector2(1.3, 1.3)
		l_tween.tween_property(timer_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)

func _on_player_spawned(player: Node2D) -> void:
	player_ref = player as Player
	_update_hero_info()
	if is_instance_valid(player_ref) and player_ref.health_component:
		_on_player_health_changed(player_ref.health_component.current_health, player_ref.health_component.max_health)

func _on_hero_changed(data: HeroData) -> void:
	_update_hero_info(data)

func _update_hero_info(custom_hero_data: HeroData = null) -> void:
	var h_data: HeroData = custom_hero_data
	if h_data == null and is_instance_valid(player_ref):
		h_data = player_ref.hero_data
	if h_data == null and not GameState.selected_hero_id.is_empty():
		var h_path: String = "res://data/heroes/%s.tres" % GameState.selected_hero_id
		if ResourceLoader.exists(h_path):
			h_data = load(h_path) as HeroData
	if h_data == null:
		var def_path: String = "res://data/heroes/warrior.tres"
		if ResourceLoader.exists(def_path):
			h_data = load(def_path) as HeroData

	if h_data != null:
		hero_name_label.text = h_data.name
		if hero_portrait != null:
			hero_portrait.texture = SpriteGenerator.get_hero_icon(h_data.id)
		if h_data.ability_1:
			ability_1_label.text = "Q: %s" % h_data.ability_1.name
			if ability_1_container != null:
				ability_1_container.visible = true
		else:
			ability_1_label.text = "Q: -"
			if ability_1_container != null:
				ability_1_container.visible = false
		if h_data.ability_2:
			ability_2_label.text = "E: %s" % h_data.ability_2.name
			if ability_2_container != null:
				ability_2_container.visible = true
		else:
			ability_2_label.text = "E: -"
			if ability_2_container != null:
				ability_2_container.visible = false
			
		if is_instance_valid(player_ref) and player_ref.health_component:
			_on_player_health_changed(player_ref.health_component.current_health, player_ref.health_component.max_health)
		elif hp_bar != null:
			_on_player_health_changed(h_data.max_hp, h_data.max_hp)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]

func _on_currency_changed(gold: int, souls: int) -> void:
	gold_label.text = "%d" % gold
	souls_label.text = "%d" % souls
	keys_label.text = "%d" % GameState.keys

func _on_boss_spawned(boss_name: String, max_hp: int) -> void:
	boss_name_label.text = boss_name.to_upper()
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp
	boss_bar_container.visible = true
	boss_bar_container.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(boss_bar_container, "modulate:a", 1.0, 0.4)

func _on_boss_health_changed(current_hp: int, _max_hp: int) -> void:
	boss_hp_bar.value = current_hp

func _on_boss_defeated(_boss_name: String) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): boss_bar_container.visible = false)

func _on_player_died() -> void:
	death_screen.visible = true
	var subtitle: Label = death_screen.get_node_or_null("CenterContainer/VBoxContainer/SubtitleLabel") as Label
	if subtitle != null:
		var s: Dictionary = GameState.run_stats
		subtitle.text = "Врагов сражено: %d  |  Очищено комнат: %d\nУрона нанесено: %d  |  Время: %.1f с" % [
			s.get("kills", 0),
			s.get("rooms_cleared", 0),
			s.get("damage_dealt", 0),
			s.get("time_elapsed", 0.0)
		]
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	death_screen.modulate.a = 0.0
	tween.tween_property(death_screen, "modulate:a", 1.0, 0.4)
	get_tree().paused = true

func _on_respawn_pressed() -> void:
	get_tree().paused = false
	death_screen.visible = false
	GameState.end_run(false)
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _on_damage_dealt(target: Node2D, amount: int, is_crit: bool) -> void:
	if not is_instance_valid(target) or amount <= 0:
		return
	
	var is_player_target: bool = (target is Player) or (target.is_in_group("player"))
	var label: Label = Label.new()
	
	if is_player_target:
		label.text = "-%d" % amount
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
		label.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.02, 0.95))
		label.add_theme_constant_override("outline_size", 4)
	elif is_crit:
		label.text = "%d! CRIT" % amount
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
		label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 0.95))
		label.add_theme_constant_override("outline_size", 5)
	else:
		label.text = str(amount)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.12, 0.95))
		label.add_theme_constant_override("outline_size", 3)
	
	var canvas_pos: Vector2 = target.get_global_transform_with_canvas().origin + Vector2(randf_range(-14, 14), -26)
	label.position = canvas_pos
	label.scale = Vector2(1.5, 1.5) if is_crit else Vector2(1.2, 1.2)
	damage_numbers_container.add_child(label)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", canvas_pos.y - 36.0, 0.55).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _on_player_healed(amount: int) -> void:
	if not is_instance_valid(player_ref) or amount <= 0:
		return
	
	var label: Label = Label.new()
	label.text = "+%d HP" % amount
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.15, 0.04, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	
	var canvas_pos: Vector2 = player_ref.get_global_transform_with_canvas().origin + Vector2(randf_range(-10, 10), -32)
	label.position = canvas_pos
	label.scale = Vector2(1.3, 1.3)
	damage_numbers_container.add_child(label)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", canvas_pos.y - 38.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
