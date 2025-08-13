@tool
extends Node2D
class_name WorldManager

@export var world_tile_map_layer: TileMapLayer
@export var enable_terrain_modification: bool = true
@export var default_tile_source: int = 1
@export var default_tile_coords: Vector2i = Vector2i(0, 0)
@export var world_data: WorldData : set = set_world_data
@export var world_save_path: String = "user://world_data.tres"
@export_group("Editor Tools")
@export var refresh_from_file: bool = false : set = _on_refresh_from_file
@export var export_to_scene: bool = false : set = _on_export_to_scene
@export var show_world_info: bool = false : set = _on_show_world_info

var game_manager: Node
var is_loading: bool = false
var last_file_modified_time: int = 0

signal terrain_modified(coords: Vector2i, source_id: int, atlas_coords: Vector2i)
signal world_data_changed()

func _ready():
	if not Engine.is_editor_hint():
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not world_tile_map_layer:
		world_tile_map_layer = get_node_or_null("WorldTileMapLayer")
	
	if world_tile_map_layer:
		print("WorldManager: Initialized with TileMapLayer")
	else:
		print("WorldManager: No TileMapLayer found")
	
	# Always load from external file to ensure editor and runtime sync
	load_world_data()
	
	# In editor: always apply world data to override scene's tile_map_data
	if Engine.is_editor_hint():
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()
			print("WorldManager: Editor refreshed with ", world_data.get_tile_count(), " tiles from persistent data")
	else:
		# Check if tilemap has data but world_data is empty (editor painted tiles)
		if world_tile_map_layer and world_data and world_data.get_tile_count() == 0:
			var used_cells = world_tile_map_layer.get_used_cells()
			if used_cells.size() > 0:
				print("WorldManager: Found ", used_cells.size(), " tiles in tilemap, syncing to world data...")
				sync_tilemap_to_world_data()
				save_world_data()
		
		# Apply world data to tilemap
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()

func set_world_data(new_world_data: WorldData):
	world_data = new_world_data
	if world_data and world_tile_map_layer and not is_loading:
		apply_world_data_to_tilemap()
	world_data_changed.emit()

func load_world_data():
	is_loading = true
	
	if FileAccess.file_exists(world_save_path):
		world_data = load(world_save_path) as WorldData
		print("WorldManager: Loaded world data from ", world_save_path)
	else:
		world_data = WorldData.new()
		world_data.world_name = "New World"
		print("WorldManager: Created new world data")
	
	is_loading = false

func save_world_data():
	if world_data:
		var result = ResourceSaver.save(world_data, world_save_path)
		if result == OK:
			print("WorldManager: Saved world data to ", world_save_path)
		else:
			print("WorldManager: Failed to save world data, error: ", result)

func apply_world_data_to_tilemap():
	if not world_tile_map_layer or not world_data:
		return
	
	print("WorldManager: Applying world data to tilemap...")
	
	# Clear existing tiles
	world_tile_map_layer.clear()
	
	# Apply all tiles from world data
	for coords in world_data.get_all_tiles().keys():
		var tile_info = world_data.get_tile(coords)
		world_tile_map_layer.set_cell(
			coords,
			tile_info.source_id,
			tile_info.atlas_coords,
			tile_info.alternative_tile
		)
	
	# Note: Editor visual refresh from @tool scripts has known limitations
	# Use the "Refresh From File" button in the inspector for manual refresh
	
	print("WorldManager: Applied ", world_data.get_tile_count(), " tiles")

func sync_tilemap_to_world_data():
	if not world_tile_map_layer or not world_data:
		return
	
	# Get all used cells from tilemap and sync to world data
	var used_cells = world_tile_map_layer.get_used_cells()
	
	# Clear world data first
	world_data.clear_all_tiles()
	
	# Add all tiles from tilemap to world data
	for coords in used_cells:
		var source_id = world_tile_map_layer.get_cell_source_id(coords)
		var atlas_coords = world_tile_map_layer.get_cell_atlas_coords(coords)
		var alternative_tile = world_tile_map_layer.get_cell_alternative_tile(coords)
		
		world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
	
	print("WorldManager: Synced ", used_cells.size(), " tiles to world data")

func modify_terrain(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
	if not enable_terrain_modification or not world_tile_map_layer or not world_data:
		return false
	
	if Engine.is_editor_hint():
		# In editor: Update both tilemap and world data directly
		world_tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
		terrain_modified.emit(coords, source_id, atlas_coords)
		# Auto-save in editor
		save_world_data()
	elif multiplayer.is_server():
		# Server: Apply change to both tilemap and world data, then sync
		world_tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
		terrain_modified.emit(coords, source_id, atlas_coords)
		if game_manager:
			game_manager.rpc("sync_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
		# Save world data EVERY change for reliability
		save_world_data()
	else:
		# Client: Send request to server
		if game_manager:
			game_manager.rpc_id(1, "request_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
	
	return true

func get_terrain_at(coords: Vector2i) -> Dictionary:
	if world_data:
		# Get from world data (authoritative)
		var tile_info = world_data.get_tile(coords)
		return {
			"source_id": tile_info.source_id,
			"atlas_coords": tile_info.atlas_coords,
			"alternative_tile": tile_info.alternative_tile,
			"tile_data": world_tile_map_layer.get_cell_tile_data(coords) if world_tile_map_layer else null
		}
	elif world_tile_map_layer:
		# Fallback to tilemap
		return {
			"source_id": world_tile_map_layer.get_cell_source_id(coords),
			"atlas_coords": world_tile_map_layer.get_cell_atlas_coords(coords),
			"alternative_tile": world_tile_map_layer.get_cell_alternative_tile(coords),
			"tile_data": world_tile_map_layer.get_cell_tile_data(coords)
		}
	else:
		return {}

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
	if world_data:
		return world_data.get_world_bounds()
	elif world_tile_map_layer:
		return world_tile_map_layer.get_used_rect()
	else:
		return Rect2i()

# Editor utility functions
func create_new_world(world_name: String = "New World"):
	world_data = WorldData.new()
	world_data.world_name = world_name
	if world_tile_map_layer:
		world_tile_map_layer.clear()
	print("WorldManager: Created new world: ", world_name)

func export_world_to_scene():
	if world_data and world_tile_map_layer:
		sync_tilemap_to_world_data()
		save_world_data()
		print("WorldManager: Exported current tilemap to world data")

# Auto-save functionality
var auto_save_timer: float = 0.0
var auto_save_interval: float = 300.0  # 5 minutes

func _process(delta):
	if Engine.is_editor_hint():
		# Check if world data file was modified externally (by runtime)
		_check_for_external_changes()
	elif multiplayer.is_server():
		auto_save_timer += delta
		if auto_save_timer >= auto_save_interval:
			save_world_data()
			auto_save_timer = 0.0

func _check_for_external_changes():
	if not FileAccess.file_exists(world_save_path):
		return
	
	var file_time = FileAccess.get_modified_time(world_save_path)
	if last_file_modified_time == 0:
		last_file_modified_time = file_time
		return
	
	if file_time > last_file_modified_time:
		print("WorldManager: Detected external changes to world data, auto-refreshing editor...")
		last_file_modified_time = file_time
		load_world_data()
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()
			print("WorldManager: Editor auto-refreshed with ", world_data.get_tile_count(), " tiles")

func _on_refresh_from_file(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔄 WorldManager: Refreshing editor from persistent file...")
		load_world_data()
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()
			print("✅ Editor refreshed with ", world_data.get_tile_count(), " tiles from ", world_save_path)
			if world_data.get_tile_count() > 0:
				print("💡 NOTE: If tiles aren't visible, try closing and reopening the scene")
		# Reset the button
		refresh_from_file = false

func _on_export_to_scene(value: bool):
	if Engine.is_editor_hint() and value:
		print("📝 WorldManager: Exporting persistent data to scene file...")
		
		# First load latest data
		load_world_data()
		
		if world_data and world_tile_map_layer:
			# Clear and apply data to tilemap
			world_tile_map_layer.clear()
			
			for coords in world_data.get_all_tiles().keys():
				var tile_info = world_data.get_tile(coords)
				world_tile_map_layer.set_cell(
					coords,
					tile_info.source_id,
					tile_info.atlas_coords,
					tile_info.alternative_tile
				)
			
			print("✅ Exported ", world_data.get_tile_count(), " tiles to scene")
			print("💾 Now save the scene (Ctrl+S) to make changes permanent")
			
			# Mark the scene as modified so it needs saving
			if get_tree():
				get_tree().set_edited_scene_root(get_tree().edited_scene_root)
		else:
			print("❌ No world data or tilemap available")
		
		# Reset the button
		export_to_scene = false

func _on_show_world_info(value: bool):
	if Engine.is_editor_hint() and value:
		if world_data:
			world_data.print_world_info()
		else:
			print("❌ No world data available")
		# Reset the button
		show_world_info = false

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
