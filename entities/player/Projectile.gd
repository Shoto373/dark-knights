class_name Projectile
extends Area2D

## Снаряд для дальних атак и способностей с частицами и векторной графикой

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var projectile_sprite: Sprite2D = %ProjectileSprite

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var max_distance: float = 600.0
var distance_traveled: float = 0.0
var proj_type: String = "magic"
var pierce_count: int = 0
var _trail_timer: float = 0.0
var projectile_light: PointLight2D = null

func _ready() -> void:
	# Снаряд врезается в стены (слой 1: world)
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if hitbox != null:
		hitbox.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(_target: Node) -> void:
	if pierce_count <= 0:
		_destroy()
	else:
		pierce_count -= 1

func setup(
	dir: Vector2,
	proj_speed: float,
	damage: int,
	is_player: bool = true,
	max_range: float = 600.0,
	knockback: float = 200.0,
	color: Color = Color.WHITE,
	p_damage_type: String = "physical",
	p_tags: Array[String] = [],
	p_proj_type: String = "",
	p_pierce_count: int = 0
) -> void:
	direction = dir.normalized()
	speed = proj_speed
	max_distance = max_range
	pierce_count = p_pierce_count
	rotation = direction.angle()
	
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = is_player
	hitbox.knockback_force = knockback
	hitbox.source_owner = self
	hitbox.damage_type = p_damage_type
	hitbox.tags = p_tags.duplicate()
	
	# Определение типа снаряда для текстуры
	if not p_proj_type.is_empty():
		proj_type = p_proj_type
	elif p_damage_type == "fire" or p_tags.has("fire"):
		proj_type = "fireball"
	elif p_damage_type == "freeze" or p_tags.has("frost") or p_tags.has("freeze"):
		proj_type = "frost"
	else:
		proj_type = "magic"
	
	var tex: Texture2D = SpriteGenerator.get_projectile_texture(proj_type)
	if tex != null and projectile_sprite != null:
		projectile_sprite.texture = tex
	
	modulate = color
	
	# Forward+ 2D динамический источник света летящего снаряда
	if SettingsManager.dynamic_lighting_enabled:
		var light_col: Color = color
		var light_energy: float = 0.85
		var light_scale: float = 1.6
		if proj_type == "fireball":
			light_col = Color(1.0, 0.55, 0.2)
			light_energy = 0.95
			light_scale = 1.8
		elif proj_type == "frost":
			light_col = Color(0.35, 0.85, 1.1)
			light_energy = 0.85
			light_scale = 1.6
		elif proj_type == "arrow":
			light_col = Color(1.0, 0.9, 0.6)
			light_energy = 0.65
			light_scale = 1.2
		else:
			light_col = Color(0.9, 0.45, 1.2)
			light_energy = 0.85
			light_scale = 1.6
		
		if projectile_light == null:
			projectile_light = LightTextureGenerator.create_point_light(light_col, light_energy, light_scale)
			projectile_light.name = "ProjectileLight"
			add_child(projectile_light)
		else:
			projectile_light.color = light_col
			projectile_light.energy = light_energy
			projectile_light.texture_scale = light_scale
			projectile_light.visible = true

func _physics_process(delta: float) -> void:
	var step: Vector2 = direction * speed * delta
	global_position += step
	distance_traveled += step.length()
	
	_trail_timer += delta
	if _trail_timer >= 0.04:
		_trail_timer = 0.0
		_spawn_trail()
	
	if distance_traveled >= max_distance:
		_destroy()

func _spawn_trail() -> void:
	var p_parent: Node = get_parent()
	if p_parent == null:
		return
	var spark: Sprite2D = Sprite2D.new()
	spark.texture = EffectsHelper.get_spark_texture()
	var sz: float = randf_range(0.2, 0.4)
	spark.scale = Vector2(sz, sz)
	spark.global_position = global_position - direction * 6.0
	
	var trail_color: Color = modulate
	if proj_type == "fireball":
		trail_color = Color(1.0, randf_range(0.4, 0.7), 0.1, 0.8)
	elif proj_type == "frost":
		trail_color = Color(0.4, 0.85, 1.0, 0.8)
	elif proj_type == "arrow":
		trail_color = Color(0.7, 0.7, 0.7, 0.5)
	
	spark.modulate = trail_color
	p_parent.add_child(spark)
	
	var tween: Tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.16)
	tween.tween_callback(spark.queue_free)

func _on_body_entered(_body: Node2D) -> void:
	_destroy()

func _destroy() -> void:
	var spark_color: Color = modulate
	if proj_type == "fireball":
		spark_color = Color(1.0, 0.5, 0.1)
	elif proj_type == "frost":
		spark_color = Color(0.3, 0.8, 1.0)
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, spark_color, 5)
	
	if SettingsManager.dynamic_lighting_enabled and get_parent() != null:
		var flash: PointLight2D = LightTextureGenerator.create_point_light(spark_color.lightened(0.2), 0.9, 1.4)
		flash.global_position = global_position
		get_parent().add_child(flash)
		var f_tween: Tween = flash.create_tween()
		f_tween.tween_property(flash, "energy", 0.0, 0.12)
		f_tween.tween_callback(flash.queue_free)
	
	queue_free()
