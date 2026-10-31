class_name DungeonPortal
extends Area2D

## Портал перехода (Хаб -> Данж или Данж -> Следующий узел графа)

@onready var prompt_label: Label = %PromptLabel
@onready var portal_glow: ColorRect = %PortalGlow

@export var target_scene: String = "res://levels/DungeonFloor.tscn"

var is_player_inside: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_enter_portal()

func _enter_portal() -> void:
	if not GameState.is_run_active:
		GameState.start_new_run(GameState.selected_hero_id)
		SceneRouter.change_scene(target_scene, 0.4)
	else:
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
