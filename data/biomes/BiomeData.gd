class_name BiomeData
extends Resource

## Описание биома для процедурной генерации этажей

@export var id: String = "goblin_dungeon"
@export var name: String = "Темница гоблинов"
@export var floor_theme_color: Color = Color(0.12, 0.14, 0.18, 1.0)
@export var wall_theme_color: Color = Color(0.06, 0.08, 0.11, 1.0)
@export var chasm_color: Color = Color(0.04, 0.04, 0.05, 1.0)
@export var bridge_color: Color = Color(0.42, 0.30, 0.18, 1.0)
@export var min_rooms: int = 8
@export var max_rooms: int = 14
@export var background_music: AudioStream
@export var enemy_pool: Array[EnemyData] = []
@export var elite_enemy: EnemyData
@export var boss_data: BossData
@export var boss_scene: PackedScene
@export var boss_scene_path: String = ""

