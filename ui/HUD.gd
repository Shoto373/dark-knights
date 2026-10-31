class_name HUD
extends CanvasLayer

## Игровой интерфейс (HUD): Здоровье, Способности, Полоска Босса, Экран смерти, Всплывающий урон

@onready var hp_bar: ProgressBar = %PlayerHpBar
@onready var hp_label: Label = %PlayerHpLabel
@onready var dash_bar: ProgressBar = %DashBar
@onready var ability_1_bar: ProgressBar = %Ability1Bar
@onready var ability_2_bar: ProgressBar = %Ability2Bar
@onready var ability_1_label: Label = %Ability1Label
@onready var ability_2_label: Label = %Ability2Label
@onready var hero_name_label: Label = %HeroNameLabel
@onready var souls_label: Label = %SoulsLabel
@onready var gold_label: Label = %GoldLabel

# Босс-бар
@onready var boss_bar_container: Control = %BossBarContainer
@onready var boss_hp_bar: ProgressBar = %BossHpBar
@onready var boss_name_label: Label = %BossNameLabel

@onready var death_screen: Control = %DeathScreen
@onready var btn_respawn: Button = %BtnRespawn
@onready var damage_numbers_container: Control = %DamageNumbersContainer

var player_ref: Player = null

func _ready() -> void:
	death_screen.visible = false
	boss_bar_container.visible = false
	btn_respawn.pressed.connect(_on_respawn_pressed)
	
	EventBus.player_spawned.connect(_on_player_spawned)
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

func _on_player_spawned(player: Node2D) -> void:
	player_ref = player as Player
	_update_hero_info()
	if is_instance_valid(player_ref) and player_ref.health_component:
		_on_player_health_changed(player_ref.health_component.current_health, player_ref.health_component.max_health)

func _update_hero_info() -> void:
	if is_instance_valid(player_ref) and player_ref.hero_data != null:
		hero_name_label.text = player_ref.hero_data.name
		if player_ref.hero_data.ability_1:
			ability_1_label.text = "Q: %s" % player_ref.hero_data.ability_1.name
		if player_ref.hero_data.ability_2:
			ability_2_label.text = "E: %s" % player_ref.hero_data.ability_2.name

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]

func _on_currency_changed(gold: int, souls: int) -> void:
	gold_label.text = "Золото: %d" % gold
	souls_label.text = "Души: %d" % souls

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
	var tween: Tween = create_tween()
	death_screen.modulate.a = 0.0
	tween.tween_property(death_screen, "modulate:a", 1.0, 0.4)

func _on_respawn_pressed() -> void:
	death_screen.visible = false
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
