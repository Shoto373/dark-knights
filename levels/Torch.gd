class_name TorchSconce
extends Node2D

## Настенный факел с живым многочастотным пламенем, искрами и динамическим источником света

@onready var sconce_sprite: Sprite2D = $SconceSprite
@onready var flame_sprite: Sprite2D = $FlameSprite
@onready var light_glow: Sprite2D = $LightGlow

@export var torch_color: Color = Color(1.0, 0.72, 0.3, 0.35)
@export var flame_scale: float = 1.0

var _flame_phase: float = 0.0
var _base_glow_scale: Vector2 = Vector2(1.2, 1.2)
var _ember_timer: float = 0.0
var _torch_point_light: PointLight2D = null

func _ready() -> void:
	_flame_phase = randf() * 10.0
	var sconce_tex: Texture2D = SpriteGenerator.get_torch_texture()
	if sconce_tex != null:
		sconce_sprite.texture = sconce_tex
	var flame_tex: Texture2D = SpriteGenerator.get_torch_flame_texture()
	if flame_tex != null:
		flame_sprite.texture = flame_tex
	var glow_tex: Texture2D = SpriteGenerator.get_light_halo_texture()
	if glow_tex != null:
		light_glow.texture = glow_tex
		light_glow.modulate = torch_color
	
	# Динамический PointLight2D для освещения стен и окружения
	_torch_point_light = LightTextureGenerator.create_point_light(Color(1.0, 0.8, 0.45), 0.85, 2.4)
	_torch_point_light.name = "TorchPointLight"
	_torch_point_light.position = Vector2(0, -14)
	add_child(_torch_point_light)

func _process(delta: float) -> void:
	_flame_phase += delta * 12.0
	
	# Анимация мерцания и подрагивания пламени
	var f_scale_y: float = flame_scale * (1.0 + sin(_flame_phase) * 0.12 + randf_range(-0.06, 0.06))
	var f_scale_x: float = flame_scale * (1.0 + cos(_flame_phase * 1.3) * 0.08)
	flame_sprite.scale = Vector2(f_scale_x, f_scale_y)
	flame_sprite.rotation = sin(_flame_phase * 0.7) * 0.08
	
	# Пульсация мягкого рассеянного ореола
	var light_pulse: float = 1.0 + sin(_flame_phase * 0.5) * 0.08 + randf_range(-0.03, 0.03)
	light_glow.scale = _base_glow_scale * light_pulse
	light_glow.modulate.a = torch_color.a * (0.9 + sin(_flame_phase * 0.8) * 0.15)
	
	# Органический многочастотный танец света факела (AAA Dynamic Light Flicker)
	if _torch_point_light != null:
		var energy_fluctuation: float = 0.78 + sin(_flame_phase * 0.7) * 0.07 + sin(_flame_phase * 1.9) * 0.04 + randf_range(-0.02, 0.02)
		_torch_point_light.energy = energy_fluctuation
		_torch_point_light.position.x = sin(_flame_phase * 1.1) * 1.2
	
	# Выброс отдельных искорок
	_ember_timer += delta
	if _ember_timer >= 0.35:
		_ember_timer = 0.0
		_spawn_ember()

func _spawn_ember() -> void:
	var spark: Sprite2D = Sprite2D.new()
	spark.texture = EffectsHelper.get_spark_texture()
	var sz: float = randf_range(0.12, 0.22)
	spark.scale = Vector2(sz, sz)
	spark.modulate = Color(1.0, randf_range(0.6, 0.9), 0.2, 0.9)
	spark.position = flame_sprite.position + Vector2(randf_range(-3.0, 3.0), -6.0)
	add_child(spark)
	
	var tween: Tween = spark.create_tween()
	var rise_target: Vector2 = spark.position + Vector2(randf_range(-8.0, 8.0), randf_range(-18.0, -28.0))
	tween.tween_property(spark, "position", rise_target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.45)
	tween.tween_callback(spark.queue_free)
