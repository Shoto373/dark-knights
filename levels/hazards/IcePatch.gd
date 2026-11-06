class_name IcePatch
extends Area2D

## Скользкий участок льда: уменьшает сцепление с поверхностью (трение в 4 раза меньше)

@onready var visual_rect: ColorRect = get_node_or_null("VisualIce") as ColorRect

func _ready() -> void:
	add_to_group("ice_patches")
	collision_layer = 0
	collision_mask = 2 | 4 # Player (2) и Enemies (4)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _draw() -> void:
	# Кристаллическая фаска и прожилки льда поверх базового прямоугольника
	var w: float = 90.0
	var h: float = 65.0
	draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), Color(0.75, 0.95, 1.0, 0.55), false, 2.0)
	draw_line(Vector2(-55, -35), Vector2(20, 15), Color(0.85, 0.98, 1.0, 0.45), 1.5)
	draw_line(Vector2(20, 15), Vector2(65, -20), Color(0.85, 0.98, 1.0, 0.45), 1.5)
	draw_line(Vector2(-20, 40), Vector2(20, 15), Color(0.85, 0.98, 1.0, 0.35), 1.2)

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
	if mov == null:
		return
	# Проверяем, не находится ли персонаж всё ещё на другом перекрывающемся участке льда
	if is_inside_tree():
		for patch in get_tree().get_nodes_in_group("ice_patches"):
			if patch != self and patch is Area2D and (patch as Area2D).overlaps_body(body):
				return
	mov.is_on_ice = false

