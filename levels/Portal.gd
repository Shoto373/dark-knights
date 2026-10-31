class_name DungeonPortal
extends Area2D

## Мистический портал перехода с вращающимся разломом пустоты, сиянием и частицами

@onready var prompt_label: Label = %PromptLabel
@onready var portal_glow: CanvasItem = %PortalGlow
@onready var portal_outer: CanvasItem = %PortalOuter
@onready var light_glow: CanvasItem = %LightGlow

@export var target_scene: String = "res://levels/DungeonFloor.tscn"
@export var next_world_node_id: String = ""

var is_player_inside: bool = false
var _anim_time: float = 0.0
var _particle_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(delta: float) -> void:
	_anim_time += delta
	
	# Скорость вращения увеличивается, если игрок рядом с порталом
	var spin_speed: float = 2.4 if is_player_inside else 0.8
	if portal_outer != null:
		portal_outer.rotation += delta * spin_speed
	if portal_glow != null:
		portal_glow.rotation -= delta * (spin_speed * 1.5)
		var breathe: float = 0.85 + sin(_anim_time * 3.5) * 0.08
		portal_glow.scale = Vector2(breathe, breathe)
	
	if light_glow != null:
		var target_alpha: float = 0.7 if is_player_inside else 0.4
		light_glow.modulate.a = move_toward(light_glow.modulate.a, target_alpha + sin(_anim_time * 2.0) * 0.1, delta)
		var light_scale: float = 1.6 if is_player_inside else 1.35
		light_glow.scale = Vector2(light_scale, light_scale)
	
	# Появление кружащих магических частиц, втягивающихся в центр
	_particle_timer += delta
	var spawn_interval: float = 0.08 if is_player_inside else 0.18
	if _particle_timer >= spawn_interval:
		_particle_timer = 0.0
		_spawn_portal_particle()
	
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_enter_portal()

func _spawn_portal_particle() -> void:
	var angle: float = randf_range(0, TAU)
	var spawn_dist: float = randf_range(38.0, 54.0)
	var spawn_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * spawn_dist
	var mote_color: Color = Color(0.9, 0.45, 1.0, 0.75) if randf() > 0.4 else Color(0.4, 0.85, 1.0, 0.75)
	EffectsHelper.spawn_portal_mote(get_parent(), spawn_pos, global_position, mote_color)

func _enter_portal() -> void:
	if not GameState.is_run_active:
		GameState.start_new_run(GameState.selected_hero_id)
		SceneRouter.change_scene(target_scene, 0.4)
	else:
		if not next_world_node_id.is_empty():
			var world_graph: WorldGraph = WorldGraph.new()
			var target_node: WorldNodeData = world_graph.get_node(next_world_node_id)
			if target_node != null:
				GameState.advance_to_world_node(target_node)
				return
		var current_node: WorldNodeData = GameState.current_world_node
		if current_node != null:
			if current_node.next_nodes.size() > 1:
				var map_scene: PackedScene = load("res://ui/WorldMap.tscn")
				var map_inst = map_scene.instantiate()
				get_tree().root.add_child(map_inst)
				if map_inst.has_method("set_mode"):
					map_inst.set_mode(true)
			elif current_node.next_nodes.size() == 1:
				GameState.advance_to_world_node(current_node.next_nodes[0])
			else:
				GameState.end_run(true)
		else:
			SceneRouter.change_scene(target_scene, 0.4)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		is_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		is_player_inside = false
		prompt_label.visible = false
