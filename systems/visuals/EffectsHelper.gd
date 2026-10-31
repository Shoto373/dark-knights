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
