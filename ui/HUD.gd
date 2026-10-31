class_name HUD
extends CanvasLayer

## Игровой интерфейс (HUD): Здоровье, Перезарядка рывка, Экран смерти, Всплывающий урон

@onready var hp_bar: ProgressBar = %PlayerHpBar
@onready var hp_label: Label = %PlayerHpLabel
@onready var dash_bar: ProgressBar = %DashBar
@onready var death_screen: Control = %DeathScreen
@onready var btn_respawn: Button = %BtnRespawn
@onready var damage_numbers_container: Control = %DamageNumbersContainer

var player_ref: Player = null

func _ready() -> void:
	death_screen.visible = false
	btn_respawn.pressed.connect(_on_respawn_pressed)
	
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)

func _process(_delta: float) -> void:
	if is_instance_valid(player_ref):
		dash_bar.value = player_ref.get_dash_cooldown_ratio() * 100.0

func _on_player_spawned(player: Node2D) -> void:
	player_ref = player as Player
	if is_instance_valid(player_ref) and player_ref.health_component:
		_on_player_health_changed(player_ref.health_component.current_health, player_ref.health_component.max_health)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]

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
	
	# Преобразуем глобальную позицию цели в координаты экрана
	var canvas_pos: Vector2 = target.get_global_transform_with_canvas().origin + Vector2(randf_range(-12, 12), -24)
	label.position = canvas_pos
	damage_numbers_container.add_child(label)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", canvas_pos.y - 30.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
