class_name EffectsHelper
extends RefCounted

## Процедурные визуальные эффекты и сочные частицы (Isaac / Gungeon style)
## Следы рывка (afterimages/ghosts), искры попадания, клубы пыли, взрывы при гибели

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
	for i in range(count):
		var spark: ColorRect = ColorRect.new()
		var sz: float = randf_range(3.0, 5.0)
		spark.size = Vector2(sz, sz)
		spark.position = -Vector2(sz, sz) / 2.0
		spark.color = color.lightened(randf_range(-0.1, 0.4))
		
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
	for i in range(4):
		var dust: ColorRect = ColorRect.new()
		var sz: float = randf_range(5.0, 8.0)
		dust.size = Vector2(sz, sz)
		dust.position = -Vector2(sz, sz) / 2.0
		dust.color = Color(0.75, 0.72, 0.68, 0.5)
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
		pivot.add_child(dust)
		parent.add_child(pivot)
		
		var target_offset: Vector2 = Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 10.0))
		var tween: Tween = pivot.create_tween()
		tween.tween_property(dust, "position", target_offset, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(dust, "scale", Vector2(1.8, 1.8), 0.25)
		tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.25)
		tween.tween_callback(pivot.queue_free)

static func spawn_death_burst(parent: Node, global_pos: Vector2, color: Color = Color(0.85, 0.2, 0.2, 1.0)) -> void:
	if parent == null:
		return
	for i in range(10):
		var p: ColorRect = ColorRect.new()
		var sz: float = randf_range(5.0, 9.0)
		p.size = Vector2(sz, sz)
		p.position = -Vector2(sz, sz) / 2.0
		p.color = color.lightened(randf_range(-0.15, 0.35))
		
		var pivot: Node2D = Node2D.new()
		pivot.global_position = global_pos
		pivot.add_child(p)
		parent.add_child(pivot)
		
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(25.0, 60.0)
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
	
	# Создаем полукруглый взмах клинка
	for i in range(5):
		var spark: ColorRect = ColorRect.new()
		var sz: float = randf_range(3.0, 6.0)
		spark.size = Vector2(sz, sz)
		spark.color = color
		var step_angle: float = deg_to_rad(-45.0 + i * 22.5)
		spark.position = Vector2(cos(step_angle), sin(step_angle)) * arc_radius
		arc_root.add_child(spark)
	
	var tween: Tween = arc_root.create_tween()
	tween.tween_property(arc_root, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc_root, "modulate:a", 0.0, 0.12)
	tween.tween_callback(arc_root.queue_free)

static func spawn_straw_puff(parent: Node, global_pos: Vector2, count: int = 5) -> void:
	if parent == null:
		return
	for i in range(count):
		var straw: ColorRect = ColorRect.new()
		var w: float = randf_range(2.0, 3.5)
		var h: float = randf_range(6.0, 11.0)
		straw.size = Vector2(w, h)
		straw.color = Color(0.9, 0.75, 0.25).lightened(randf_range(-0.15, 0.2))
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
	var mote: ColorRect = ColorRect.new()
	var sz: float = randf_range(2.5, 4.5)
	mote.size = Vector2(sz, sz)
	mote.position = -Vector2(sz, sz) / 2.0
	mote.color = color
	
	var node: Node2D = Node2D.new()
	node.global_position = spawn_pos
	node.add_child(mote)
	parent.add_child(node)
	
	var to_center: Vector2 = center_pos - spawn_pos
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "global_position", center_pos, randf_range(0.35, 0.65)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "scale", Vector2.ZERO, 0.6)
	tween.tween_callback(node.queue_free)

