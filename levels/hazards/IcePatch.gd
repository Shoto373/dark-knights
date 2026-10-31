class_name IcePatch
extends Area2D

## Скользкий участок льда: уменьшает сцепление с поверхностью (трение в 4 раза меньше)

@onready var visual_rect: ColorRect = get_node_or_null("VisualIce") as ColorRect

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 # Player (2) и Enemies (4)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var mov: MovementComponent = body.get_node_or_null("MovementComponent") as MovementComponent
	if mov == null:
		return
	
	var sem: StatusEffectManager = body.get_node_or_null("StatusEffectManager") as StatusEffectManager
	if sem != null and sem.immunities.has("freeze"):
		# Существа с иммунитетом к холоду не скользят
		return
	
	mov.is_on_ice = true

func _on_body_exited(body: Node2D) -> void:
	var mov: MovementComponent = body.get_node_or_null("MovementComponent") as MovementComponent
	if mov != null:
		mov.is_on_ice = false
