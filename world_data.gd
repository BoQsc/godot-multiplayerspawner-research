@tool
extends Resource
class_name WorldData

@export var world_name: String = "MyWorld"
@export var created_at: String = ""
@export var last_modified: String = ""
@export var world_size: Vector2i = Vector2i(100, 100)

# Dictionary to store tile data: Vector2i -> TileInfo
@export var tile_data: Dictionary = {}

# Nested class to represent individual tile information
class TileInfo:
	var source_id: int
	var atlas_coords: Vector2i
	var alternative_tile: int
	
	func _init(p_source_id: int = -1, p_atlas_coords: Vector2i = Vector2i(-1, -1), p_alternative_tile: int = 0):
		source_id = p_source_id
		atlas_coords = p_atlas_coords
		alternative_tile = p_alternative_tile
	
	func to_dict() -> Dictionary:
		return {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		}
	
	func from_dict(data: Dictionary):
		source_id = data.get("source_id", -1)
		atlas_coords = data.get("atlas_coords", Vector2i(-1, -1))
		alternative_tile = data.get("alternative_tile", 0)

func _init():
	created_at = Time.get_datetime_string_from_system()
	last_modified = created_at

func set_tile(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int = 0):
	if source_id == -1:
		# Remove tile
		tile_data.erase(coords)
	else:
		# Set tile
		var tile_info = TileInfo.new(source_id, atlas_coords, alternative_tile)
		tile_data[coords] = tile_info.to_dict()
	
	last_modified = Time.get_datetime_string_from_system()

func get_tile(coords: Vector2i) -> Dictionary:
	if coords in tile_data:
		return tile_data[coords]
	else:
		return {
			"source_id": -1,
			"atlas_coords": Vector2i(-1, -1),
			"alternative_tile": -1
		}

func has_tile(coords: Vector2i) -> bool:
	return coords in tile_data

func get_all_tiles() -> Dictionary:
	return tile_data.duplicate()

func clear_all_tiles():
	tile_data.clear()
	last_modified = Time.get_datetime_string_from_system()

func get_tile_count() -> int:
	return tile_data.size()

func get_world_bounds() -> Rect2i:
	if tile_data.is_empty():
		return Rect2i()
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for coords in tile_data.keys():
		if coords is Vector2i:
			min_x = min(min_x, coords.x)
			min_y = min(min_y, coords.y)
			max_x = max(max_x, coords.x)
			max_y = max(max_y, coords.y)
	
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

# Debug function to print world info
func print_world_info():
	print("=== World Data Info ===")
	print("Name: ", world_name)
	print("Created: ", created_at)
	print("Last Modified: ", last_modified)
	print("Tile Count: ", get_tile_count())
	print("Bounds: ", get_world_bounds())
	print("=======================")