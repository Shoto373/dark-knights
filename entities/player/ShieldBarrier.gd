class_name ShieldBarrier
extends Node2D

## Визуальный компонент щита и эгиды героя (Dark Fantasy Knight Aegis)
## Отображает кованый щит, защитный рунический купол и вспышки отражения урона

@export var shield_texture: Texture2D = preload("res://assets/sprites/shield_aegis.svg")

var shield_pivot: Node2D
var shield_sprite: Sprite2D
var shield_light: PointLight2D

var is_active: bool = false
var aegis_radius: float = 30.0
var aegis_alpha: float = 0.0
var aegis_rotation: float = 0.0

var _block_tween: Tween
var _pulse_phase: float = 0.0

func _ready() -> void:
	z_index = 2 # Поверх персонажа
	
	shield_pivot = Node2D.new()
	shield_pivot.name = "ShieldPivot"
	add_child(shield_pivot)
	
	shield_sprite = Sprite2D.new()
	shield_sprite.name = "ShieldSprite"
	shield_sprite.texture = shield_texture
	shield_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shield_sprite.position = Vector2(24, 0)
	shield_sprite.scale = Vector2.ZERO
	shield_sprite.visible = false
	shield_pivot.add_child(shield_sprite)
	
	shield_light = LightTextureGenerator.create_point_light(Color(1.0, 0.85, 0.35), 0.0, 2.0)
	shield_light.name = "ShieldLight"
	add_child(shield_light)
	
	visible = true

func _process(delta: float) -> void:
	if not is_active:
		return
	
	_pulse_phase += delta * 5.0
	aegis_rotation += delta * 1.5
	
	# Пульсирующее свечение щита
	if is_instance_valid(shield_light):
		shield_light.energy = 0.85 + sin(_pulse_phase) * 0.2
	
	queue_redraw()

func _draw() -> void:
	if not is_active or aegis_alpha <= 0.01:
		return
	
	# Рисуем защитное силовое поле вокруг героя
	var pulse_r: float = aegis_radius + sin(_pulse_phase) * 2.0
	var col_outer: Color = Color(1.8, 1.4, 0.5, 0.65 * aegis_alpha)
	var col_inner: Color = Color(1.0, 0.8, 0.2, 0.15 * aegis_alpha)
	
	# Внутренняя полупрозрачная аура
	draw_circle(Vector2.ZERO, pulse_r, col_inner)
	
	# Внешнее руническое силовое кольцо
	draw_arc(Vector2.ZERO, pulse_r, 0.0, TAU, 32, col_outer, 2.0)
	draw_arc(Vector2.ZERO, pulse_r - 4.0, 0.0, TAU, 24, Color(1.5, 1.2, 0.3, 0.35 * aegis_alpha), 1.0)
	
	# Вращающиеся рунические лучи
	for i in range(6):
		var ang: float = aegis_rotation + (float(i) / 6.0) * TAU
		var p1: Vector2 = Vector2(cos(ang), sin(ang)) * (pulse_r - 6.0)
		var p2: Vector2 = Vector2(cos(ang), sin(ang)) * pulse_r
		draw_line(p1, p2, col_outer, 1.5)

func update_aim(aim_dir: Vector2) -> void:
	if is_instance_valid(shield_pivot):
		shield_pivot.rotation = aim_dir.angle()
		# Корректируем вертикальный переворот спрайта щита
		if is_instance_valid(shield_sprite):
			shield_sprite.flip_v = aim_dir.x < 0.0

func activate_block(duration: float) -> void:
	is_active = true
	shield_sprite.visible = true
	
	if _block_tween != null and _block_tween.is_valid():
		_block_tween.kill()
	
	shield_sprite.position = Vector2(24, 0)
	shield_sprite.scale = Vector2(0.2, 0.2)
	aegis_alpha = 0.0
	
	_block_tween = create_tween().set_parallel(true)
	_block_tween.tween_property(shield_sprite, "scale", Vector2(0.85, 0.85), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_block_tween.tween_method(func(val: float): aegis_alpha = val, 0.0, 1.0, 0.15)
	if is_instance_valid(shield_light):
		_block_tween.tween_property(shield_light, "energy", 0.95, 0.15)
	
	# Таймер деактивации
	var end_tween: Tween = create_tween()
	end_tween.tween_interval(maxf(0.1, duration - 0.2))
	end_tween.tween_callback(deactivate)

func activate_charge(dash_dir: Vector2, duration: float) -> void:
	is_active = true
	shield_sprite.visible = true
	update_aim(dash_dir)
	
	if _block_tween != null and _block_tween.is_valid():
		_block_tween.kill()
	
	shield_sprite.position = Vector2(20, 0)
	shield_sprite.scale = Vector2(0.3, 0.3)
	aegis_alpha = 0.6
	
	_block_tween = create_tween().set_parallel(true)
	# Выпад щитом вперед при таране
	_block_tween.tween_property(shield_sprite, "position", Vector2(34, 0), duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_block_tween.tween_property(shield_sprite, "scale", Vector2(1.1, 1.1), duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(shield_light):
		_block_tween.tween_property(shield_light, "energy", 1.2, duration * 0.4)
	
	var end_tween: Tween = create_tween()
	end_tween.tween_interval(duration)
	end_tween.tween_callback(deactivate)

func trigger_block_impact() -> void:
	if not is_instance_valid(shield_sprite):
		return
	
	# Яркая белая вспышка щита при отражении удара
	EffectsHelper.apply_hit_flash(shield_sprite, 0.1, Color(2.5, 2.5, 1.8))
	EffectsHelper.spawn_hit_sparks(get_parent(), shield_sprite.global_position, Color(1.0, 0.9, 0.4), 10)
	EventBus.screen_shake_requested.emit(3.0, 0.12)
	
	# Толчок щита назад от удара
	var push_tween: Tween = shield_sprite.create_tween()
	push_tween.tween_property(shield_sprite, "position:x", 16.0, 0.05)
	push_tween.tween_property(shield_sprite, "position:x", 24.0, 0.1).set_trans(Tween.TRANS_BACK)

func deactivate() -> void:
	if not is_active:
		return
	
	var fade_tween: Tween = create_tween().set_parallel(true)
	fade_tween.tween_property(shield_sprite, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_method(func(val: float): aegis_alpha = val, aegis_alpha, 0.0, 0.18)
	if is_instance_valid(shield_light):
		fade_tween.tween_property(shield_light, "energy", 0.0, 0.18)
	fade_tween.chain().tween_callback(func():
		is_active = false
		shield_sprite.visible = false
		queue_redraw()
	)
