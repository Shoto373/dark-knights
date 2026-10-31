class_name VoidRiftTrap
extends Area2D

## Астральный разлом пустоты: притягивает сущности к своему центру гравитационной силой
## и наносит периодический урон в ядре разлома

@export var pull_radius: float = 180.0
@export var pull_force: float = 240.0
@export var core_damage: int = 8
@export var tick_interval: float = 0.5

@onready var visual_vortex: Node2D = %VisualVortex
@onready var core_rect: ColorRect = %CoreRect

var damage_timer: float = 0.0
var bodies_in_range: Array[Node2D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 # Player (2) и Enemies (4)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# Вращение визуальной воронки
	if visual_vortex != null:
		visual_vortex.rotation += 3.5 * delta
	
	# Притяжение сущностей
	bodies_in_range = bodies_in_range.filter(func(b): return is_instance_valid(b))
	for body in bodies_in_range:
		var to_center: Vector2 = global_position - body.global_position
		var dist: float = to_center.length()
		if dist > 4.0:
			var pull_dir: Vector2 = to_center.normalized()
			var pull_step: Vector2 = pull_dir * pull_force * delta
			if body is CharacterBody2D:
				var cb: CharacterBody2D = body as CharacterBody2D
				cb.velocity += pull_step * 10.0
				cb.move_and_slide()
	
	# Периодический урон в эпицентре (в пределах 40 пикселей)
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_tick_core_damage()

func _on_body_entered(body: Node2D) -> void:
	if not bodies_in_range.has(body):
		bodies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	bodies_in_range.erase(body)

func _tick_core_damage() -> void:
	for body in bodies_in_range:
		if is_instance_valid(body) and global_position.distance_to(body.global_position) <= 42.0:
			var hc: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				hc.take_damage(core_damage, true)
				EventBus.screen_shake_requested.emit(3.0, 0.1)
