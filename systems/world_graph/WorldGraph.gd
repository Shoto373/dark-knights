class_name WorldGraph
extends RefCounted

## Менеджер графа мира и переходов между биомами (Data-Driven Roguelite World Graph)

const WORLD_DIR: String = "res://data/world/"

var nodes: Dictionary = {} # id: String -> WorldNodeData

func _init() -> void:
	load_all_nodes()

func load_all_nodes() -> void:
	nodes.clear()
	var dir: DirAccess = DirAccess.open(WORLD_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path: String = WORLD_DIR + file_name
				var node_res: Resource = load(full_path)
				if node_res is WorldNodeData:
					var node_data: WorldNodeData = node_res as WorldNodeData
					if not node_data.id.is_empty():
						nodes[node_data.id] = node_data
			file_name = dir.get_next()
		dir.list_dir_end()

func get_node(node_id: String) -> WorldNodeData:
	if nodes.has(node_id):
		return nodes[node_id]
	# Попытка прямой загрузки если еще не в кэше
	var path: String = WORLD_DIR + node_id + ".tres"
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is WorldNodeData:
			nodes[node_id] = res as WorldNodeData
			return nodes[node_id]
	return null

func add_node(node: WorldNodeData) -> void:
	if node != null and not node.id.is_empty():
		nodes[node.id] = node

func get_all_nodes() -> Dictionary:
	return nodes

func get_next_nodes(current_id: String) -> Array[WorldNodeData]:
	var current: WorldNodeData = get_node(current_id)
	if current != null:
		return current.next_nodes
	return []

func can_reach(start_id: String, target_id: String) -> bool:
	if start_id == target_id:
		return true
	
	var visited: Dictionary = {}
	var queue: Array[String] = [start_id]
	visited[start_id] = true
	
	while not queue.is_empty():
		var curr_id: String = queue.pop_front()
		var curr_node: WorldNodeData = get_node(curr_id)
		if curr_node == null:
			continue
		
		for next_node in curr_node.next_nodes:
			if next_node == null:
				continue
			if next_node.id == target_id:
				return true
			if not visited.has(next_node.id):
				visited[next_node.id] = true
				queue.append(next_node.id)
				
	return false

