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

var player_ref: Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	death_screen.visible = false
	boss_bar_container.visible = false
	btn_respawn.pressed.connect(_on_respawn_pressed)
	
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.hero_changed.connect(_on_hero_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.currency_changed.connect(_on_currency_changed)
	
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	
	_update_hero_info()
	_on_currency_changed(GameState.gold, MetaProgress.souls)

func _process(_delta: float) -> void:
	if is_instance_valid(player_ref):
		dash_bar.value = player_ref.get_dash_cooldown_ratio() * 100.0
		ability_1_bar.value = player_ref.get_ability_cooldown_ratio(1) * 100.0
		ability_2_bar.value = player_ref.get_ability_cooldown_ratio(2) * 100.0
	keys_label.text = "%d" % GameState.keys

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
		else:
			ability_1_label.text = "Q: -"
		if h_data.ability_2:
			ability_2_label.text = "E: %s" % h_data.ability_2.name
		else:
			ability_2_label.text = "E: -"
			
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
	if not is_instance_valid(target):
		return
	
	var label: Label = Label.new()
	label.text = str(amount) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 18 if is_crit else 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_crit else Color(1.0, 1.0, 1.0))
	
	var canvas_pos: Vector2 = target.get_global_transform_with_canvas().origin + Vector2(randf_range(-12, 12), -24)
	label.position = canvas_pos
	damage_numbers_container.add_child(label)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", canvas_pos.y - 30.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
