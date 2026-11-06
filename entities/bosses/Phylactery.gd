class_name Phylactery
extends Node2D

## Филактерия Короля-лича (Ключевая механика 3 фазы):
## Содержит бессмертную душу Лича. Пока филактерия цела, Лич не может умереть.
## Окружена вращающимися ледяными кристаллами, наносящими контактный урон.

signal destroyed

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var visuals: Node2D = %Visuals
@onready var shards_pivot: Node2D = %ShardsPivot
@onready var hp_bar: ProgressBar = %HpBar

var rotation_speed: float = 2.4

func _ready() -> void:
	add_to_group("bosses")
	
	hurtbox_component.health_component = health_component
	hurtbox_component.is_player_hurtbox = false
	
	health_component.max_health = 180
	health_component.reset(180)
	hp_bar.max_value = 180
	hp_bar.value = 180
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	# Анимация парения
	var bob: Tween = create_tween().set_loops()
	bob.tween_property(visuals, "position:y", -6.0, 0.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(visuals, "position:y", 6.0, 0.8).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	if shards_pivot != null:
		shards_pivot.rotation += rotation_speed * delta

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	hp_bar.value = current_hp
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 3.5, 4.0, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)
	EventBus.screen_shake_requested.emit(5.0, 0.1)

func _on_died() -> void:
	EventBus.screen_shake_requested.emit(18.0, 0.6)
	destroyed.emit()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.5)
	tween.chain().tween_callback(queue_free)

