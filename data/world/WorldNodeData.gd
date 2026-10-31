class_name WorldNodeData
extends Resource

## Описание узла графа мира (Data-Driven Roguelite World Graph)

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var biome: BiomeData
@export var floors_count: int = 1
@export var next_nodes: Array[WorldNodeData] = []
@export var access_condition: String = "" # Например: "", "requires_souls_50", "unlocked"
@export var is_final: bool = false
@export var map_position: Vector2 = Vector2.ZERO # Координаты на экране карты мира (0..1280, 0..720)
@export var icon_symbol: String = "⚔"
