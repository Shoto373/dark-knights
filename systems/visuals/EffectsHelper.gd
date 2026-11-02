class_name EffectsHelper
extends RefCounted

## Процедурные визуальные эффекты и сочные частицы (Isaac / Gungeon style)
## Следы рывка, мягкие радиальные искры, клубы пыли, взрывы при гибели, вспышки ударов

static var _spark_tex: Texture2D = null
static var _hit_flash_shader: Shader = preload("res://shaders/hit_flash.gdshader")

static func get_spark_texture() -> Texture2D:
	if _spark_tex != null:
		return _spark_tex
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(16):
		for x in range(16):
			var dist: float = Vector2(x - 7.5, y - 7.5).length()
			if dist <= 7.5:
				var alpha: float = clampf(1.0 - (dist / 7.5), 0.0, 1.0)
				# Квадратичное сглаживание для яркого ядра и мягких краев
				alpha = alpha * alpha
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_spark_tex = ImageTexture.create_from_image(img)
	return _spark_tex

static func apply_hit_flash(node: CanvasItem, duration: float = 0.08, flash_color: Color = Color.WHITE) -> void:
	if not is_instance_valid(node):
		return
	var mat: ShaderMaterial = null
	if node.material is ShaderMaterial and node.material.shader == _hit_flash_shader:
		mat = node.material as ShaderMaterial
	else:
		mat = ShaderMaterial.new()
		mat.shader = _hit_flash_shader
		node.material = mat
	
	mat.set_shader_parameter("flash_color", flash_color)
	mat.set_shader_parameter("flash_modifier", 1.0)
	
	var tween: Tween = node.create_tween()
	tween.tween_method(func(val: float):
		if is_instance_valid(node) and node.material == mat:
			mat.set_shader_parameter("flash_modifier", val)
	, 1.0, 0.0, duration)

static func spawn_dash_ghost(parent: Node, global_pos: Vector2, texture: Texture2D, flip_h: bool = false, tint: Color = Color(0.3, 0.75, 1.0, 0.6)) -> void:
	if parent == null or texture == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = texture
	ghost.global_position = global_pos
	ghost.flip_h = flip_h
	ghost.modulate = tint
	ghost.scale = Vector2(1.1, 1.1)
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(ghost)
	
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(1.3, 1.3), 0.22)
	tween.tween_callback(ghost.queue_free)

static func spawn_hit_sparks(parent: Node, global_pos: Vector2, color: Color = Color(1.0, 0.9, 0.3, 1.0), count: int = 6) -> void:
	if parent == null:
		return
	var tex: Texture2D = get_spark_texture()
	for i in range(count):
		var spark: Sprite2D = Sprite2D.new()
		spark.texture = tex
		var sz: float = randf_range(0.35, 0.7)
		spark.scale = Vector2(sz, sz)
		spark.modulate = color.lightened(randf_range(-0.1, 0.35))
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos
		pivot.add_child(spark)
		parent.add_child(pivot)
		
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(16.0, 42.0)
		var target: Vector2 = Vector2(cos(angle), sin(angle)) * dist
		
		var tween: Tween = pivot.create_tween()
		tween.tween_property(spark, "position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(spark, "scale", Vector2.ZERO, 0.18)
		tween.tween_callback(pivot.queue_free)

static func spawn_dust_puff(parent: Node, global_pos: Vector2) -> void:
	if parent == null:
		return
	var tex: Texture2D = get_spark_texture()
	for i in range(4):
		var dust: Sprite2D = Sprite2D.new()
		dust.texture = tex
		var sz: float = randf_range(0.6, 1.1)
		dust.scale = Vector2(sz, sz)
		dust.modulate = Color(0.75, 0.72, 0.68, 0.5)
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
		pivot.add_child(dust)
		parent.add_child(pivot)
		
		var target_offset: Vector2 = Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 10.0))
		var tween: Tween = pivot.create_tween()
		tween.tween_property(dust, "position", target_offset, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(dust, "scale", Vector2(1.6, 1.6), 0.25)
		tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.25)
		tween.tween_callback(pivot.queue_free)

static func spawn_death_burst(parent: Node, global_pos: Vector2, color: Color = Color(0.85, 0.2, 0.2, 1.0)) -> void:
	if parent == null:
		return
	var tex: Texture2D = get_spark_texture()
	for i in range(12):
		var p: Sprite2D = Sprite2D.new()
		p.texture = tex
		var sz: float = randf_range(0.5, 1.0)
		p.scale = Vector2(sz, sz)
		p.modulate = color.lightened(randf_range(-0.15, 0.35))
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos
		pivot.add_child(p)
		parent.add_child(pivot)
		
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(25.0, 65.0)
		var target: Vector2 = Vector2(cos(angle), sin(angle)) * dist
		
		var tween: Tween = pivot.create_tween()
		tween.tween_property(p, "position", target, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(p, "scale", Vector2.ZERO, 0.28)
		tween.tween_callback(pivot.queue_free)

static func spawn_slash_arc(parent: Node, global_pos: Vector2, angle: float, arc_radius: float = 30.0, color: Color = Color(0.9, 0.95, 1.0, 0.85)) -> void:
	if parent == null:
		return
	var arc_root: Node2D = Node2D.new()
	arc_root.global_position = global_pos
	arc_root.rotation = angle
	parent.add_child(arc_root)
	
	var tex: Texture2D = get_spark_texture()
	for i in range(6):
		var spark: Sprite2D = Sprite2D.new()
		spark.texture = tex
		var sz: float = randf_range(0.4, 0.75)
		spark.scale = Vector2(sz, sz)
		spark.modulate = color
		var step_angle: float = deg_to_rad(-45.0 + i * 18.0)
		spark.position = Vector2(cos(step_angle), sin(step_angle)) * arc_radius
		arc_root.add_child(spark)
	
	var tween: Tween = arc_root.create_tween()
	tween.tween_property(arc_root, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc_root, "modulate:a", 0.0, 0.12)
	tween.tween_callback(arc_root.queue_free)

static func spawn_straw_puff(parent: Node, global_pos: Vector2, count: int = 5) -> void:
	if parent == null:
		return
	var tex: Texture2D = get_spark_texture()
	for i in range(count):
		var straw: Sprite2D = Sprite2D.new()
		straw.texture = tex
		var w: float = randf_range(0.3, 0.5)
		var h: float = randf_range(0.8, 1.4)
		straw.scale = Vector2(w, h)
		straw.modulate = Color(0.95, 0.8, 0.3).lightened(randf_range(-0.15, 0.2))
		straw.rotation = randf_range(0, TAU)
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos
		pivot.add_child(straw)
		parent.add_child(pivot)
		
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(14.0, 34.0)
		var target: Vector2 = Vector2(cos(angle), sin(angle)) * dist
		var tween: Tween = pivot.create_tween()
		tween.tween_property(straw, "position", target, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(straw, "rotation", straw.rotation + randf_range(-2.0, 2.0), 0.24)
		tween.parallel().tween_property(straw, "modulate:a", 0.0, 0.24)
		tween.tween_callback(pivot.queue_free)

static func spawn_portal_mote(parent: Node, spawn_pos: Vector2, center_pos: Vector2, color: Color = Color(0.85, 0.4, 1.0, 0.7)) -> void:
	if parent == null:
		return
	var tex: Texture2D = get_spark_texture()
	var mote: Sprite2D = Sprite2D.new()
	mote.texture = tex
	var sz: float = randf_range(0.3, 0.6)
	mote.scale = Vector2(sz, sz)
	mote.modulate = color
	
	var node: Node2D = Node2D.new()
	node.global_position = spawn_pos
	node.add_child(mote)
	parent.add_child(node)
	
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "global_position", center_pos, randf_range(0.35, 0.65)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "scale", Vector2.ZERO, 0.6)
	tween.tween_callback(node.queue_free)
