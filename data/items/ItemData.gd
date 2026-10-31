class_name ItemData
extends Resource

## Ресурс описания предмета/артефакта (Data-Driven)

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_enum("common", "rare", "epic", "legendary") var rarity: String = "common"
@export_enum("passive", "active", "consumable") var item_type: String = "passive"
@export var cost_gold: int = 25
@export var weight: float = 100.0
@export var tags: Array[String] = []
@export var modifiers: Array[StatModifier] = []

func get_rarity_color() -> Color:
	match rarity:
		"common": return Color(0.7, 0.7, 0.7, 1.0)
		"rare": return Color(0.2, 0.6, 1.0, 1.0)
		"epic": return Color(0.75, 0.3, 0.9, 1.0)
		"legendary": return Color(1.0, 0.65, 0.1, 1.0)
		_: return Color.WHITE
