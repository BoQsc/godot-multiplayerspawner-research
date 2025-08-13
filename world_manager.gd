extends Node2D
class_name WorldManager

@export var world_tile_map_layer: TileMapLayer
@export var enable_terrain_modification: bool = true
@export var default_tile_source: int = 1
@export var default_tile_coords: Vector2i = Vector2i(0, 0)

var game_manager: Node

signal terrain_modified(coords: Vector2i, source_id: int, atlas_coords: Vector2i)

func _ready():
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not world_tile_map_layer:
		world_tile_map_layer = get_node_or_null("WorldTileMapLayer")
	
	if world_tile_map_layer:
		print("WorldManager: Initialized with TileMapLayer")
	else:
		print("WorldManager: No TileMapLayer found")

func modify_terrain(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
	if not enable_terrain_modification or not world_tile_map_layer:
		return false
	
	if multiplayer.is_server():
		# Server: Apply change locally and sync to clients
		world_tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		terrain_modified.emit(coords, source_id, atlas_coords)
		if game_manager:
			game_manager.rpc("sync_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
	else:
		# Client: Send request to server
		if game_manager:
			game_manager.rpc_id(1, "request_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
	
	return true

func get_terrain_at(coords: Vector2i) -> Dictionary:
	if not world_tile_map_layer:
		return {}
	
	return {
		"source_id": world_tile_map_layer.get_cell_source_id(coords),
		"atlas_coords": world_tile_map_layer.get_cell_atlas_coords(coords),
		"alternative_tile": world_tile_map_layer.get_cell_alternative_tile(coords),
		"tile_data": world_tile_map_layer.get_cell_tile_data(coords)
	}

func is_walkable(coords: Vector2i) -> bool:
	var terrain_info = get_terrain_at(coords)
	if terrain_info.is_empty():
		return true
	
	var tile_data = terrain_info.get("tile_data")
	if tile_data:
		return not tile_data.get_collision_layer_value(0)
	
	return true

func world_position_to_map(world_pos: Vector2) -> Vector2i:
	if not world_tile_map_layer:
		return Vector2i.ZERO
	return world_tile_map_layer.local_to_map(world_pos)

func map_to_world_position(map_coords: Vector2i) -> Vector2:
	if not world_tile_map_layer:
		return Vector2.ZERO
	return world_tile_map_layer.map_to_local(map_coords)

func get_world_bounds() -> Rect2i:
	if not world_tile_map_layer:
		return Rect2i()
	return world_tile_map_layer.get_used_rect()

func _input(event):
	if not enable_terrain_modification:
		return
		
	if event is InputEventMouseButton and event.pressed:
		var clicked_coords = world_position_to_map(get_global_mouse_position())
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Place default tile
			modify_terrain(clicked_coords, default_tile_source, default_tile_coords)
			print("Placed tile at: ", clicked_coords)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Remove tile
			modify_terrain(clicked_coords, -1)
			print("Removed tile at: ", clicked_coords)

@rpc("any_peer", "call_local", "reliable")
func sync_terrain_modification(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int):
	if not multiplayer.is_server():
		world_tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		terrain_modified.emit(coords, source_id, atlas_coords)
