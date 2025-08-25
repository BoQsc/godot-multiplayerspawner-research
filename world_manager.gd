@tool
extends Node2D
class_name WorldManager

@export var world_tile_map_layer: TileMapLayer
@export var world_misc_tile_map_layer: TileMapLayer
@export var enable_terrain_modification: bool = true
@export var default_tile_source: int = 1
@export var default_tile_coords: Vector2i = Vector2i(0, 0)
@export var world_data: WorldData : set = set_world_data
@export var world_save_path: String = "user://world_data.tres"
@export_group("Editor Tools")
@export var refresh_from_file: bool = false : set = _on_refresh_from_file
@export var export_to_scene: bool = false : set = _on_export_to_scene
@export var sync_scene_to_world: bool = false : set = _on_sync_scene_to_world
@export var show_world_info: bool = false : set = _on_show_world_info
@export var save_world_now: bool = false : set = _on_save_world_now
@export var sync_editor_players: bool = false : set = _on_sync_editor_players
@export var rescue_lost_players: bool = false : set = _on_rescue_lost_players
@export_group("Manual Player Positioning")
@export var player_to_move: String = ""
@export var new_position: Vector2 = Vector2.ZERO
@export var move_player_now: bool = false : set = _on_move_player_now
@export_group("Player Search & Management")
@export var search_term: String = ""
@export var search_players: bool = false : set = _on_search_players
@export var focus_on_player: String = ""
@export var focus_camera: bool = false : set = _on_focus_camera
@export var list_all_players: bool = false : set = _on_list_all_players
@export var show_player_distances: bool = false : set = _on_show_distances
@export_group("Editor Diagnostics")
@export var test_editor_display: bool = false : set = _on_test_editor_display
@export var cleanup_duplicate_players: bool = false : set = _on_cleanup_duplicates
@export var reset_all_players: bool = false : set = _on_reset_all_players
@export_group("Editor Player Visibility")
@export var toggle_players_visible: bool = false : set = _on_toggle_players_visible
@export var editor_players_visible: bool = true
@export_group("Player Focus Mode")
@export var focus_player_list: String = "" # Comma-separated list of player IDs
@export var apply_focus: bool = false : set = _on_apply_focus
@export var clear_focus: bool = false : set = _on_clear_focus
@export var highlight_focused: bool = true
@export_group("Player Filtering & Display")
@export var show_recent_players_only: bool = true
@export var max_recent_players: int = 20 : set = _on_max_recent_changed
@export var hide_insignificant_players: bool = true
@export var significance_threshold: int = 5 # Minimum level or playtime to be "significant"
@export var use_transparency_gradient: bool = true
@export var oldest_player_alpha: float = 0.3 # How transparent the oldest players become
@export var refresh_display_filters: bool = false : set = _on_refresh_filters

var game_manager: Node
var is_loading: bool = false
var last_file_modified_time: int = 0
var last_tilemap_cell_count: int = 0

# Editor player persistence
var editor_players: Dictionary = {}  # player_id -> player_node
var spawn_container: Node2D

# Focus mode state
var focused_players: Array[String] = []  # List of player IDs currently focused
var is_focus_mode_active: bool = false

signal terrain_modified(coords: Vector2i, source_id: int, atlas_coords: Vector2i)
signal world_data_changed()

func _ready():
	if not Engine.is_editor_hint():
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not world_tile_map_layer:
		world_tile_map_layer = get_node_or_null("WorldTileMapLayer")
	
	if not world_misc_tile_map_layer:
		world_misc_tile_map_layer = get_node_or_null("WorldMiscTileMapLayer")
	
	if world_tile_map_layer:
		print("WorldManager: Initialized with WorldTileMapLayer")
	else:
		print("WorldManager: No WorldTileMapLayer found")
		
	if world_misc_tile_map_layer:
		print("WorldManager: Initialized with WorldMiscTileMapLayer")
	else:
		print("WorldManager: No WorldMiscTileMapLayer found")
	
	# Find SpawnContainer for editor player persistence
	spawn_container = get_node_or_null("../SpawnContainer")
	if not spawn_container:
		spawn_container = get_tree().get_first_node_in_group("spawn_container")
	
	if spawn_container:
		print("WorldManager: Found SpawnContainer at ", spawn_container.get_path())
	else:
		print("WorldManager: SpawnContainer not found")
	
	# Always load from external file to ensure editor and runtime sync
	load_world_data()
	
	# Load NPCs on server startup (delay to ensure all systems are ready)
	if not Engine.is_editor_hint() and multiplayer.is_server():
		# Delay NPC loading to ensure GameManager is fully initialized
		await get_tree().process_frame
		await get_tree().process_frame  # Extra delay for safety
		load_npcs()
		
		# Load pickups after another delay
		await get_tree().process_frame
		load_pickups()
	
	# In editor: always apply world data to override scene's tile_map_data
	if Engine.is_editor_hint():
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()
			print("WorldManager: Editor refreshed with ", world_data.get_tile_count(), " tiles from persistent data")
		# Sync editor players from world data
		sync_editor_players_from_world_data()
	else:
		# Check if tilemaps have data but world_data is empty (editor painted tiles)
		if world_data and world_data.get_tile_count() == 0:
			var total_cells = 0
			if world_tile_map_layer:
				total_cells += world_tile_map_layer.get_used_cells().size()
			if world_misc_tile_map_layer:
				total_cells += world_misc_tile_map_layer.get_used_cells().size()
			
			if total_cells > 0:
				print("WorldManager: Found ", total_cells, " tiles across all tilemap layers, syncing to world data...")
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
	if not world_data:
		print("WorldManager: ERROR - No world data to save")
		return false
		
	# Use mutex to prevent concurrent saves
	save_mutex.lock()
	
	if save_in_progress:
		print("WorldManager: Save already in progress, skipping")
		save_mutex.unlock()
		return false
	
	save_in_progress = true
	save_mutex.unlock()
	
	var success = _robust_save_world_data()
	
	save_mutex.lock()
	save_in_progress = false
	save_mutex.unlock()
	
	return success

func _robust_save_world_data() -> bool:
	print("WorldManager: Starting robust save operation...")
	print("WorldManager: Client mapping size: ", world_data.client_to_player_mapping.size())
	print("WorldManager: Player data size: ", world_data.player_data.size())
	
	# Store critical data for verification
	var original_client_mappings = world_data.client_to_player_mapping.duplicate()
	var original_player_data = world_data.player_data.keys()
	var original_mapping_size = world_data.client_to_player_mapping.size()
	
	for attempt in range(max_save_retries):
		print("WorldManager: Save attempt ", attempt + 1, "/", max_save_retries)
		
		# Create timestamped backup before save
		var backup_path = world_save_path + ".backup." + str(Time.get_unix_time_from_system())
		var backup_result = ResourceSaver.save(world_data, backup_path)
		if backup_result == OK:
			print("WorldManager: Backup created: ", backup_path)
		
		# Attempt primary save
		var result = ResourceSaver.save(world_data, world_save_path)
		
		if result != OK:
			print("WorldManager: Save attempt failed, error: ", result, " - ", error_string(result))
			OS.delay_msec(100)  # Wait before retry
			continue
		
		print("WorldManager: Save operation completed, verifying...")
		
		# Verify save by reloading and checking critical data
		if _verify_save_integrity(original_client_mappings, original_player_data, original_mapping_size):
			print("WorldManager: ✅ ROBUST SAVE SUCCESSFUL")
			var file_time = FileAccess.get_modified_time(world_save_path)
			print("WorldManager: File modified at ", Time.get_datetime_string_from_unix_time(file_time))
			return true
		else:
			print("WorldManager: Save verification failed, retrying...")
			OS.delay_msec(200)  # Wait longer before retry
	
	# All attempts failed
	print("WorldManager: ❌ CRITICAL SAVE FAILURE - All ", max_save_retries, " attempts failed")
	print("WorldManager: Data may be lost! Check backup files.")
	return false

func _verify_save_integrity(original_mappings: Dictionary, original_players: Array, original_size: int) -> bool:
	print("WorldManager: Verifying save integrity...")
	
	if not FileAccess.file_exists(world_save_path):
		print("WorldManager: Verification failed - file doesn't exist")
		return false
	
	# Load the saved file
	var loaded_data = ResourceLoader.load(world_save_path)
	if not loaded_data:
		print("WorldManager: Verification failed - couldn't load saved file")
		return false
	
	# Check client mapping integrity
	if loaded_data.client_to_player_mapping.size() != original_size:
		print("WorldManager: Verification failed - client mapping size mismatch")
		print("WorldManager: Expected: ", original_size, " Got: ", loaded_data.client_to_player_mapping.size())
		return false
	
	# Check for critical server mappings
	var server_mappings_lost = 0
	for client_id in original_mappings.keys():
		if client_id.begins_with("server_"):
			if not loaded_data.client_to_player_mapping.has(client_id):
				print("WorldManager: Verification failed - lost server mapping: ", client_id)
				server_mappings_lost += 1
	
	if server_mappings_lost > 0:
		print("WorldManager: Verification failed - ", server_mappings_lost, " server mappings lost")
		return false
	
	# Check player data integrity
	var players_lost = 0
	for player_id in original_players:
		if not loaded_data.player_data.has(player_id):
			print("WorldManager: Verification failed - lost player data: ", player_id)
			players_lost += 1
	
	if players_lost > 0:
		print("WorldManager: Verification failed - ", players_lost, " players lost")
		return false
	
	print("WorldManager: ✅ Save verification passed")
	return true

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
	if not world_data:
		return
	
	# Clear world data first
	world_data.clear_all_tiles()
	
	var total_synced = 0
	
	# Sync WorldTileMapLayer
	if world_tile_map_layer:
		var used_cells = world_tile_map_layer.get_used_cells()
		for coords in used_cells:
			var source_id = world_tile_map_layer.get_cell_source_id(coords)
			var atlas_coords = world_tile_map_layer.get_cell_atlas_coords(coords)
			var alternative_tile = world_tile_map_layer.get_cell_alternative_tile(coords)
			world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
		total_synced += used_cells.size()
		print("WorldManager: Synced ", used_cells.size(), " tiles from WorldTileMapLayer")
	
	# Sync WorldMiscTileMapLayer  
	if world_misc_tile_map_layer:
		var used_cells_misc = world_misc_tile_map_layer.get_used_cells()
		for coords in used_cells_misc:
			var source_id = world_misc_tile_map_layer.get_cell_source_id(coords)
			var atlas_coords = world_misc_tile_map_layer.get_cell_atlas_coords(coords)
			var alternative_tile = world_misc_tile_map_layer.get_cell_alternative_tile(coords)
			world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
		total_synced += used_cells_misc.size()
		print("WorldManager: Synced ", used_cells_misc.size(), " tiles from WorldMiscTileMapLayer")
	
	print("WorldManager: Total synced ", total_synced, " tiles to world data")

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
		if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			game_manager.rpc("sync_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
		# Save world data EVERY change for reliability
		save_world_data()
	else:
		# Client: Send request to server
		if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			game_manager.rpc_id(1, "request_terrain_modification", coords, source_id, atlas_coords, alternative_tile)
	
	return true

func get_terrain_at(coords: Vector2i) -> Dictionary:
	if world_data:
		# Get from world data (authoritative)
		var tile_info = world_data.get_tile(coords)
		# Try to get tile data from either tilemap layer
		var tile_data = null
		if world_tile_map_layer:
			tile_data = world_tile_map_layer.get_cell_tile_data(coords)
		if not tile_data and world_misc_tile_map_layer:
			tile_data = world_misc_tile_map_layer.get_cell_tile_data(coords)
		
		return {
			"source_id": tile_info.source_id,
			"atlas_coords": tile_info.atlas_coords,
			"alternative_tile": tile_info.alternative_tile,
			"tile_data": tile_data
		}
	else:
		# Fallback to tilemap layers
		# Try WorldTileMapLayer first
		if world_tile_map_layer:
			var source_id = world_tile_map_layer.get_cell_source_id(coords)
			if source_id != -1:  # Valid tile found
				return {
					"source_id": source_id,
					"atlas_coords": world_tile_map_layer.get_cell_atlas_coords(coords),
					"alternative_tile": world_tile_map_layer.get_cell_alternative_tile(coords),
					"tile_data": world_tile_map_layer.get_cell_tile_data(coords)
				}
		
		# Try WorldMiscTileMapLayer if not found in main layer
		if world_misc_tile_map_layer:
			var source_id = world_misc_tile_map_layer.get_cell_source_id(coords)
			if source_id != -1:  # Valid tile found
				return {
					"source_id": source_id,
					"atlas_coords": world_misc_tile_map_layer.get_cell_atlas_coords(coords),
					"alternative_tile": world_misc_tile_map_layer.get_cell_alternative_tile(coords),
					"tile_data": world_misc_tile_map_layer.get_cell_tile_data(coords)
				}
		
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
var auto_save_interval: float = -1.0  # Disabled - GameManager handles all saving

# Robust saving system
var save_mutex: Mutex = Mutex.new()
var save_in_progress: bool = false
var save_retry_count: int = 0
var max_save_retries: int = 3

func _process(delta):
	# Check if tilemap was modified in editor (direct painting) - ALWAYS run this
	_check_for_tilemap_changes()
	
	if Engine.is_editor_hint():
		# Check if world data file was modified externally (by runtime)
		_check_for_external_changes()
		# Check if editor players were moved
		_check_for_editor_player_movement()
	elif multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED and multiplayer.is_server():
		# WorldManager auto-save is disabled - GameManager handles all saving to prevent conflicts
		pass

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
		# Also sync editor players
		sync_editor_players_from_world_data()

func _check_for_tilemap_changes():
	if not world_data:
		return
	
	# Count cells from all tilemap layers
	var current_cell_count = 0
	if world_tile_map_layer:
		current_cell_count += world_tile_map_layer.get_used_cells().size()
	if world_misc_tile_map_layer:
		current_cell_count += world_misc_tile_map_layer.get_used_cells().size()
	
	# Initialize the count on first check
	if last_tilemap_cell_count == 0:
		last_tilemap_cell_count = current_cell_count
		return
	
	# Detect changes in tilemap
	if current_cell_count != last_tilemap_cell_count:
		print("WorldManager: Detected tilemap changes in editor (", current_cell_count, " cells), auto-syncing to persistent world...")
		sync_tilemap_to_world_data()
		save_world_data()
		last_tilemap_cell_count = current_cell_count
		print("✅ Editor changes automatically saved to persistent world data")

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

func _on_sync_scene_to_world(value: bool):
	if Engine.is_editor_hint() and value:
		print("📤 WorldManager: Syncing scene changes to persistent world...")
		
		if world_tile_map_layer and world_data:
			sync_tilemap_to_world_data()
			save_world_data()
			print("✅ Synced ", world_data.get_tile_count(), " tiles from scene to persistent world")
			print("💾 Changes saved to ", world_save_path)
		else:
			print("❌ No tilemap or world data available")
		
		# Reset the button
		sync_scene_to_world = false

func _on_show_world_info(value: bool):
	if Engine.is_editor_hint() and value:
		if world_data:
			world_data.print_world_info()
		else:
			print("❌ No world data available")
		# Reset the button
		show_world_info = false

func _on_save_world_now(value: bool):
	if value:
		print("💾 WorldManager: Manual save triggered...")
		if world_data:
			save_world_data()
			print("✅ World data saved (", world_data.get_tile_count(), " tiles, ", world_data.get_player_count(), " players)")
		else:
			print("❌ No world data available to save")
		# Reset the button
		save_world_now = false

func _input(event):
	# Editor keyboard shortcuts (only in editor)
	if Engine.is_editor_hint() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_H and event.ctrl_pressed:
			editor_players_visible = !editor_players_visible
			print("⌨️ Keyboard shortcut: Toggling editor players to ", "VISIBLE" if editor_players_visible else "HIDDEN")
			toggle_editor_players_visibility()
			return
	
	# Terrain modification (only when enabled)
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

# Send complete world state to a client
func send_world_state_to_client(peer_id: int):
	if multiplayer.is_server() and world_data and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("WorldManager: Sending world state to client ", peer_id)
		var tile_data = world_data.tile_data
		rpc_id(peer_id, "receive_world_state", tile_data)

# Receive complete world state from server
@rpc("authority", "call_remote", "reliable")
func receive_world_state(tile_data: Dictionary):
	if not multiplayer.is_server():
		print("WorldManager: Received world state with ", tile_data.size(), " tiles")
		
		# Clear current tilemap
		world_tile_map_layer.clear()
		
		# Apply all tiles from server
		for coords in tile_data.keys():
			var tile_info = tile_data[coords]
			var source_id = tile_info.get("source_id", -1)
			var atlas_coords = tile_info.get("atlas_coords", Vector2i(-1, -1))
			var alternative_tile = tile_info.get("alternative_tile", 0)
			
			if source_id != -1:  # Only set valid tiles
				world_tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		
		print("WorldManager: Applied ", tile_data.size(), " tiles from server")

# Editor Player Persistence Functions
func sync_editor_players_from_world_data():
	if not Engine.is_editor_hint():
		print("WorldManager: Not in editor, skipping player sync")
		return
	if not world_data:
		print("WorldManager: No world data, skipping player sync")
		return
	if not spawn_container:
		print("WorldManager: No spawn container found, skipping player sync")
		return
	
	print("WorldManager: Syncing editor players from world data...")
	
	# Clear existing editor players
	clear_editor_players()
	
	# Get and filter player data
	var all_player_data = world_data.get_all_players()
	var filtered_players = get_filtered_players(all_player_data)
	
	print("WorldManager: Found ", all_player_data.size(), " total players, showing ", filtered_players.size(), " after filtering")
	
	# Spawn filtered players with appropriate styling
	for i in range(filtered_players.size()):
		var player_info = filtered_players[i]
		var player_id = player_info["player_id"]
		var player_position = player_info["position"]
		var rank = i  # 0 = most recent, higher = older
		
		spawn_editor_player_with_styling(player_id, player_position, player_info, rank, filtered_players.size())
	
	print("WorldManager: Spawned ", editor_players.size(), " editor players")
	if editor_players.size() > 0:
		print("💡 TIP: Look in Scene tab under SpawnContainer for EditorPlayer nodes. Select them to drag around!")
		if all_player_data.size() > filtered_players.size():
			var hidden_count = all_player_data.size() - filtered_players.size()
			print("📊 Filtered out ", hidden_count, " players (insignificant or too old). Use focus mode to find specific players.")

func spawn_editor_player(player_id: String, spawn_pos: Vector2):
	if not Engine.is_editor_hint() or not spawn_container:
		print("WorldManager: Cannot spawn editor player - missing requirements")
		return
	
	# Check if player is lost (far from reasonable bounds)
	var is_lost = abs(spawn_pos.x) > 5000 or abs(spawn_pos.y) > 5000
	var safe_position = spawn_pos
	if is_lost:
		safe_position = Vector2(100, 100)  # Default safe spawn
		print("WorldManager: Player ", player_id, " is lost at ", spawn_pos, ", spawning at safe position ", safe_position)
	
	# Create a simple Node2D for editor representation
	var player = Node2D.new()
	player.name = "EditorPlayer_" + player_id
	player.position = safe_position
	
	# Add visual representation (sprite)
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(50, 50)
	sprite.texture = texture
	
	# Color based on status
	if is_lost:
		sprite.modulate = Color.RED  # Lost players are red
	else:
		sprite.modulate = Color.CYAN  # Normal players are cyan
	
	player.add_child(sprite)
	
	# Add label with player ID and status
	var label = Label.new()
	if is_lost:
		label.text = player_id + " (LOST)"
	else:
		label.text = player_id
	
	label.position = Vector2(-30, -40)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	player.add_child(label)
	
	# Store metadata for later retrieval
	player.set_meta("persistent_player_id", player_id)
	player.set_meta("original_position", position)
	player.set_meta("is_lost", is_lost)
	
	# Add to spawn container and track
	spawn_container.add_child(player)
	editor_players[player_id] = player
	
	if is_lost:
		print("WorldManager: Spawned LOST player ", player_id, " (originally at ", position, ") at safe position ", safe_position)
	else:
		print("WorldManager: Successfully spawned editor player ", player_id, " at ", position)
	print("WorldManager: Editor players count now: ", editor_players.size())

func clear_editor_players():
	if not Engine.is_editor_hint():
		return
	
	# Remove all existing editor players
	for player_id in editor_players.keys():
		var player = editor_players[player_id]
		if is_instance_valid(player):
			player.queue_free()
	
	editor_players.clear()

func _check_for_editor_player_movement():
	if not Engine.is_editor_hint() or not world_data:
		return
	
	# Check each editor player for position changes
	for player_id in editor_players.keys():
		var player = editor_players[player_id]
		if not is_instance_valid(player):
			continue
		
		var persistent_id = player.get_meta("persistent_player_id", "")
		if persistent_id == "":
			continue
		
		# Get current position from world data
		var stored_data = world_data.get_player(persistent_id)
		var stored_position = stored_data["position"]
		
		# Check if position changed
		if player.position.distance_to(stored_position) > 1.0:  # Small threshold for floating point precision
			# Update world data
			world_data.update_player_position(persistent_id, player.position)
			save_world_data()
			print("WorldManager: Editor player ", persistent_id, " moved to ", player.position)

func _on_sync_editor_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🎭 WorldManager: Syncing editor players...")
		sync_editor_players_from_world_data()
		# Reset the button
		sync_editor_players = false

func _on_rescue_lost_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🚑 WorldManager: Rescuing lost players...")
		rescue_all_lost_players()
		# Reset the button
		rescue_lost_players = false

func rescue_all_lost_players():
	if not Engine.is_editor_hint() or not world_data:
		return
	
	var rescued_count = 0
	var safe_spawn = Vector2(100, 100)
	
	# Check all players in world data for lost positions
	var player_data = world_data.get_all_players()
	for player_id in player_data.keys():
		var player_info = player_data[player_id]
		var pos = player_info["position"]
		
		# Check if player is lost (far from reasonable bounds)
		if abs(pos.x) > 5000 or abs(pos.y) > 5000:
			print("WorldManager: Rescuing lost player ", player_id, " from ", pos, " to ", safe_spawn)
			world_data.update_player_position(player_id, safe_spawn)
			rescued_count += 1
	
	if rescued_count > 0:
		save_world_data()
		sync_editor_players_from_world_data()  # Refresh editor display
		print("✅ WorldManager: Rescued ", rescued_count, " lost players to safe spawn at ", safe_spawn)
	else:
		print("WorldManager: No lost players found to rescue")

func _on_move_player_now(value: bool):
	if Engine.is_editor_hint() and value:
		if player_to_move != "" and world_data:
			print("🎯 WorldManager: Moving player ", player_to_move, " to ", new_position)
			world_data.update_player_position(player_to_move, new_position)
			save_world_data()
			sync_editor_players_from_world_data()  # Refresh editor display
			print("✅ Player ", player_to_move, " moved to ", new_position)
		else:
			print("❌ Please specify player_to_move (e.g., 'player_1') and new_position")
		# Reset the button
		move_player_now = false

func _on_search_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔍 WorldManager: Searching for players containing '", search_term, "'...")
		search_for_players(search_term)
		# Reset the button
		search_players = false

func _on_focus_camera(value: bool):
	if Engine.is_editor_hint() and value:
		if focus_on_player != "":
			print("🎯 WorldManager: Focusing camera on player ", focus_on_player)
			focus_camera_on_player(focus_on_player)
		else:
			print("❌ Please specify focus_on_player (e.g., 'player_1')")
		# Reset the button
		focus_camera = false

func _on_list_all_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("📋 WorldManager: Listing all players...")
		list_all_players_with_positions()
		# Reset the button
		list_all_players = false

func _on_show_distances(value: bool):
	if Engine.is_editor_hint() and value:
		print("📏 WorldManager: Showing player distances from spawn...")
		show_player_distances_from_spawn()
		# Reset the button
		show_player_distances = false

func search_for_players(term: String):
	if not world_data:
		print("❌ No world data available")
		return
	
	var matches = []
	var player_data = world_data.get_all_players()
	
	for player_id in player_data.keys():
		if term == "" or player_id.to_lower().contains(term.to_lower()):
			var player_info = player_data[player_id]
			matches.append({
				"id": player_id,
				"position": player_info["position"],
				"last_seen": player_info["last_seen"],
				"level": player_info["level"]
			})
	
	print("🔍 Found ", matches.size(), " matching players:")
	for match in matches:
		var pos = match["position"]
		var distance = pos.distance_to(Vector2(100, 100))  # Distance from default spawn
		print("  • ", match["id"], " at ", pos, " (", int(distance), " units from spawn) - Level ", match["level"], " - Last seen: ", match["last_seen"])

func focus_camera_on_player(player_id: String):
	if not world_data:
		print("❌ No world data available")
		return
	
	var player_info = world_data.get_player(player_id)
	if player_info.has("position"):
		var pos = player_info["position"]
		print("📍 Player ", player_id, " is at position ", pos)
		print("💡 TIP: Navigate to coordinates X:", pos.x, " Y:", pos.y, " in the editor viewport")
		
		# Try to move the editor camera (this might not work in all contexts)
		var editor_viewport = get_viewport()
		if editor_viewport and editor_viewport.has_method("get_camera_2d"):
			var camera = editor_viewport.get_camera_2d()
			if camera:
				camera.global_position = pos
				print("🎯 Editor camera moved to player position")
		else:
			print("💡 Manually navigate to position ", pos, " in the editor")
	else:
		print("❌ Player ", player_id, " not found")

func list_all_players_with_positions():
	if not world_data:
		print("❌ No world data available")
		return
	
	var player_data = world_data.get_all_players()
	print("📋 === ALL PLAYERS (", player_data.size(), " total) ===")
	
	# Sort players by distance from spawn for easier management
	var players_with_distance = []
	for player_id in player_data.keys():
		var player_info = player_data[player_id]
		var pos = player_info["position"]
		var distance = pos.distance_to(Vector2(100, 100))
		players_with_distance.append({
			"id": player_id,
			"info": player_info,
			"distance": distance
		})
	
	# Sort by distance
	players_with_distance.sort_custom(func(a, b): return a.distance < b.distance)
	
	for player in players_with_distance:
		var info = player.info
		var status = "✅ NORMAL"
		if player.distance > 5000:
			status = "🚨 LOST"
		elif player.distance > 1000:
			status = "⚠️ FAR"
		
		print("  ", status, " ", player.id, " at (", int(info.position.x), ", ", int(info.position.y), ") - Distance: ", int(player.distance), " - Level: ", info.level, " - HP: ", info.health, "/", info.max_health)

func show_player_distances_from_spawn():
	if not world_data:
		print("❌ No world data available")
		return
	
	var spawn_point = Vector2(100, 100)  # Default spawn
	var player_data = world_data.get_all_players()
	
	print("📏 === PLAYER DISTANCES FROM SPAWN (", spawn_point, ") ===")
	
	var close_players = []
	var medium_players = []
	var far_players = []
	var lost_players = []
	
	for player_id in player_data.keys():
		var player_info = player_data[player_id]
		var distance = player_info["position"].distance_to(spawn_point)
		
		if distance < 500:
			close_players.append({"id": player_id, "distance": distance})
		elif distance < 1000:
			medium_players.append({"id": player_id, "distance": distance})
		elif distance < 5000:
			far_players.append({"id": player_id, "distance": distance})
		else:
			lost_players.append({"id": player_id, "distance": distance})
	
	print("✅ CLOSE (< 500 units): ", close_players.size(), " players")
	for player in close_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("⚠️ MEDIUM (500-1000 units): ", medium_players.size(), " players")
	for player in medium_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("🔶 FAR (1000-5000 units): ", far_players.size(), " players")
	for player in far_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("🚨 LOST (> 5000 units): ", lost_players.size(), " players")
	for player in lost_players:
		print("    ", player.id, " - ", int(player.distance), " units")

func _on_test_editor_display(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔧 WorldManager: Testing editor display system...")
		test_editor_player_display()
		# Reset the button
		test_editor_display = false

func test_editor_player_display():
	if not Engine.is_editor_hint():
		print("❌ Not in editor mode")
		return
	
	print("🔧 === EDITOR DISPLAY DIAGNOSTICS ===")
	
	# Test spawn container
	if spawn_container:
		print("✅ SpawnContainer found at: ", spawn_container.get_path())
		print("   Children count: ", spawn_container.get_child_count())
	else:
		print("❌ SpawnContainer not found")
		return
	
	# Test world data
	if world_data:
		var player_count = world_data.get_player_count()
		print("✅ WorldData loaded with ", player_count, " players")
		
		if player_count > 0:
			print("   Player list:")
			var players = world_data.get_all_players()
			for player_id in players.keys():
				var info = players[player_id]
				print("     • ", player_id, " at ", info["position"])
		else:
			print("   No players in world data")
	else:
		print("❌ WorldData not found")
		return
	
	# Test editor players
	print("📊 Editor players status:")
	print("   Tracked count: ", editor_players.size())
	
	for player_id in editor_players.keys():
		var player_node = editor_players[player_id]
		if is_instance_valid(player_node):
			print("   ✅ ", player_id, " - Node valid at ", player_node.position)
			print("      Node name: ", player_node.name)
			print("      Parent: ", player_node.get_parent().name if player_node.get_parent() else "None")
			print("      Children: ", player_node.get_child_count())
		else:
			print("   ❌ ", player_id, " - Node invalid")
	
	# Test if nodes are visible in scene tree
	print("📋 SpawnContainer children:")
	for child in spawn_container.get_children():
		if child.name.begins_with("EditorPlayer_"):
			print("   ✅ Found: ", child.name, " at ", child.position)
		else:
			print("   ℹ️ Other child: ", child.name)
	
	print("🔧 === DIAGNOSTICS COMPLETE ===")
	
	if editor_players.size() == 0:
		print("💡 TIP: Try clicking 'Sync Editor Players' to refresh the display")

func _on_cleanup_duplicates(value: bool):
	if Engine.is_editor_hint() and value:
		print("🧹 WorldManager: Cleaning up duplicate players...")
		cleanup_duplicate_players_from_identity_bug()
		# Reset the button
		cleanup_duplicate_players = false

func _on_reset_all_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔥 WorldManager: Resetting all players...")
		reset_all_players_data()
		# Reset the button
		reset_all_players = false

func cleanup_duplicate_players_from_identity_bug():
	if not world_data:
		print("❌ No world data available")
		return
	
	print("🧹 === DUPLICATE PLAYER CLEANUP ===")
	
	# Get current mappings
	var client_mappings = world_data.client_to_player_mapping
	var players = world_data.get_all_players()
	
	print("Before cleanup:")
	print("  Client mappings: ", client_mappings.size())
	for client_id in client_mappings.keys():
		var player_id = client_mappings[client_id]
		print("    ", client_id, " -> ", player_id)
	
	# Strategy: Merge newer identity format players back into older ones
	# Look for pairs: old short IDs + new long IDs for same role
	
	var merges_to_perform = []
	
	# Find client duplicates - look for different length IDs (old vs new format)
	var old_client_id = ""
	var new_client_id = ""
	for client_id in client_mappings.keys():
		if client_id.begins_with("client_"):
			print("🔍 Checking client ID: ", client_id, " (length: ", client_id.length(), ")")
			if client_id.length() <= 14:  # Old/shorter format like "client_4e8eud3a" (12 chars)
				old_client_id = client_id
				print("  → Marked as OLD client: ", old_client_id)
			elif client_id.length() > 14:  # New/longer format like "client_a70ds7hrkpyz" (16 chars)
				new_client_id = client_id
				print("  → Marked as NEW client: ", new_client_id)
	
	if old_client_id != "" and new_client_id != "":
		merges_to_perform.append({
			"old_client": old_client_id,
			"new_client": new_client_id,
			"type": "client"
		})
		print("🔗 Found client duplicate: ", old_client_id, " vs ", new_client_id)
	
	# Find server duplicates - look for different length IDs (old vs new format)
	var old_server_id = ""
	var new_server_id = ""
	for client_id in client_mappings.keys():
		if client_id.begins_with("server_"):
			print("🔍 Checking server ID: ", client_id, " (length: ", client_id.length(), ")")
			if client_id.length() <= 14:  # Old/shorter format like "server_sref1044" (12 chars)
				old_server_id = client_id
				print("  → Marked as OLD server: ", old_server_id)
			elif client_id.length() > 14:  # New/longer format like "server_e5c4zwkibvaq" (16 chars)
				new_server_id = client_id
				print("  → Marked as NEW server: ", new_server_id)
	
	if old_server_id != "" and new_server_id != "":
		merges_to_perform.append({
			"old_client": old_server_id,
			"new_client": new_server_id,
			"type": "server"
		})
		print("🔗 Found server duplicate: ", old_server_id, " vs ", new_server_id)
	
	# Perform merges
	var cleaned_count = 0
	for merge in merges_to_perform:
		var merge_old_client_id = merge["old_client"]
		var merge_new_client_id = merge["new_client"]
		var old_player_id = client_mappings[merge_old_client_id]
		var new_player_id = client_mappings[merge_new_client_id]
		
		print("🧹 Merging ", merge["type"], ": ", merge_new_client_id, " (", new_player_id, ") into ", merge_old_client_id, " (", old_player_id, ")")
		
		# Get player data
		var old_player_data = players[old_player_id]
		var new_player_data = players[new_player_id]
		
		# Use the newer player data (more recent position/activity)
		if new_player_data["last_seen"] >= old_player_data["last_seen"]:
			print("  → Using newer player data from ", new_player_id)
			# Copy new data to old player ID
			world_data.player_data[old_player_id] = new_player_data.duplicate()
			world_data.player_data[old_player_id]["player_id"] = old_player_id  # Fix the ID reference
		else:
			print("  → Keeping older player data from ", old_player_id)
		
		# Update client mapping to point new client ID to old player ID
		world_data.client_to_player_mapping[merge_new_client_id] = old_player_id
		
		# Remove the duplicate player data
		world_data.player_data.erase(new_player_id)
		
		cleaned_count += 1
	
	if cleaned_count > 0:
		save_world_data()
		sync_editor_players_from_world_data()  # Refresh display
		print("✅ Cleanup complete: Merged ", cleaned_count, " duplicate players")
		print("🔄 You should now see 2 players in the editor instead of 4")
		
		# Show final mapping
		print("After cleanup:")
		for client_id in world_data.client_to_player_mapping.keys():
			var player_id = world_data.client_to_player_mapping[client_id]
			print("    ", client_id, " -> ", player_id)
	else:
		print("ℹ️ No duplicate players found to clean up")

func reset_all_players_data():
	if not world_data:
		print("❌ No world data available")
		return
	
	print("🔥 === RESET ALL PLAYERS ===")
	print("Before reset:")
	print("  Players: ", world_data.player_data.size())
	print("  Client mappings: ", world_data.client_to_player_mapping.size())
	print("  Peer mappings: ", world_data.peer_to_client_mapping.size())
	
	# Clear all player data
	world_data.player_data.clear()
	world_data.client_to_player_mapping.clear()
	world_data.peer_to_client_mapping.clear()
	
	# Reset the player ID counter
	world_data.next_player_id = 1
	
	# Clear editor players display
	for player_node in editor_players.values():
		if player_node and is_instance_valid(player_node):
			player_node.queue_free()
	editor_players.clear()
	
	# Save the changes
	save_world_data()
	
	print("✅ Reset complete!")
	print("After reset:")
	print("  Players: ", world_data.player_data.size())
	print("  Client mappings: ", world_data.client_to_player_mapping.size())
	print("  Peer mappings: ", world_data.peer_to_client_mapping.size())
	print("🔄 All player data has been cleared. Next run will create fresh players starting from player_1")

func _on_toggle_players_visible(value: bool):
	if Engine.is_editor_hint() and value:
		editor_players_visible = !editor_players_visible
		print("👁️ WorldManager: Toggling editor players visibility to ", "VISIBLE" if editor_players_visible else "HIDDEN")
		toggle_editor_players_visibility()
		# Reset the button
		toggle_players_visible = false

func toggle_editor_players_visibility():
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	var affected_count = 0
	
	# Toggle visibility for all EditorPlayer nodes
	for child in spawn_container.get_children():
		if child.name.begins_with("EditorPlayer_"):
			child.visible = editor_players_visible
			affected_count += 1
	
	# Also update the tracked editor players
	for player_id in editor_players.keys():
		var player_node = editor_players[player_id]
		if is_instance_valid(player_node):
			player_node.visible = editor_players_visible
	
	if affected_count > 0:
		var status = "VISIBLE" if editor_players_visible else "HIDDEN"
		print("✅ Updated visibility for ", affected_count, " editor players - now ", status)
		if not editor_players_visible:
			print("💡 TIP: Click 'Toggle Players Visible' again to show them")
	else:
		print("ℹ️ No editor players found to toggle")

# Keyboard shortcut: Ctrl+H to toggle player visibility

func _on_apply_focus(value: bool):
	if Engine.is_editor_hint() and value:
		if focus_player_list.strip_edges() == "":
			print("❌ Please enter player IDs in 'Focus Player List' (comma-separated)")
		else:
			print("🎯 WorldManager: Applying focus to players: ", focus_player_list)
			apply_player_focus(focus_player_list)
		# Reset the button
		apply_focus = false

func _on_clear_focus(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔄 WorldManager: Clearing player focus")
		clear_player_focus()
		# Reset the button
		clear_focus = false

func apply_player_focus(player_list_string: String):
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	# Parse the comma-separated list
	var player_ids = []
	for player_id in player_list_string.split(","):
		var trimmed_id = player_id.strip_edges()
		if trimmed_id != "":
			player_ids.append(trimmed_id)
	
	if player_ids.size() == 0:
		print("❌ No valid player IDs found in list")
		return
	
	focused_players = player_ids
	is_focus_mode_active = true
	
	print("🎯 Focus mode activated for ", focused_players.size(), " players: ", focused_players)
	
	var visible_count = 0
	var hidden_count = 0
	var not_found_count = 0
	
	# Hide all players first
	for child in spawn_container.get_children():
		if child.name.begins_with("EditorPlayer_"):
			child.visible = false
			hidden_count += 1
	
	# Show and highlight only focused players
	for player_id in focused_players:
		var found_player = false
		
		# Look for the player in spawn container
		for child in spawn_container.get_children():
			if child.name == "EditorPlayer_" + player_id:
				child.visible = true
				visible_count += 1
				found_player = true
				
				# Highlight if enabled
				if highlight_focused:
					highlight_player_node(child)
				
				print("  ✅ Focused on player: ", player_id, " at ", child.position)
				break
		
		if not found_player:
			not_found_count += 1
			print("  ❌ Player not found: ", player_id)
	
	print("📊 Focus Results:")
	print("  • Visible: ", visible_count, " players")
	print("  • Hidden: ", hidden_count, " players") 
	print("  • Not found: ", not_found_count, " players")
	
	if visible_count > 0:
		print("💡 TIP: Use 'Clear Focus' to show all players again")

func clear_player_focus():
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	focused_players.clear()
	is_focus_mode_active = false
	
	var restored_count = 0
	
	# Show all players and remove highlights
	for child in spawn_container.get_children():
		if child.name.begins_with("EditorPlayer_"):
			child.visible = editor_players_visible  # Respect global visibility setting
			remove_player_highlight(child)
			restored_count += 1
	
	print("🔄 Focus mode cleared - restored visibility for ", restored_count, " players")
	print("💡 Players now follow global visibility setting (currently ", "VISIBLE" if editor_players_visible else "HIDDEN", ")")

func highlight_player_node(player_node: Node2D):
	# Make the focused player more prominent
	var sprite = player_node.get_child(0) as Sprite2D  # First child should be the sprite
	if sprite:
		sprite.modulate = Color.YELLOW
		sprite.scale = Vector2(1.5, 1.5)
	
	# Update label to show it's focused
	var label = player_node.get_child(1) as Label  # Second child should be the label
	if label:
		var original_text = label.text
		if not original_text.contains("🎯"):
			label.text = "🎯 " + original_text
		label.add_theme_color_override("font_color", Color.YELLOW)

func remove_player_highlight(player_node: Node2D):
	# Reset sprite appearance
	var sprite = player_node.get_child(0) as Sprite2D
	if sprite:
		# Check if it's a lost player (keep red color for lost players)
		var is_lost = player_node.get_meta("is_lost", false)
		sprite.modulate = Color.RED if is_lost else Color.CYAN
		sprite.scale = Vector2(1.0, 1.0)
	
	# Reset label
	var label = player_node.get_child(1) as Label
	if label:
		var original_text = label.text
		if original_text.contains("🎯 "):
			label.text = original_text.replace("🎯 ", "")
		label.add_theme_color_override("font_color", Color.WHITE)

# Player Filtering Functions
func get_filtered_players(all_players: Dictionary) -> Array:
	var players_array = []
	
	# Convert dictionary to array with metadata
	for player_id in all_players.keys():
		var player_info = all_players[player_id]
		var enhanced_info = player_info.duplicate()
		enhanced_info["player_id"] = player_id
		players_array.append(enhanced_info)
	
	# Sort by last_seen (most recent first)
	players_array.sort_custom(func(a, b): return a["last_seen"] > b["last_seen"])
	
	var filtered_players = []
	
	for player_info in players_array:
		var should_show = true
		
		# Filter by significance
		if hide_insignificant_players and should_show:
			if is_player_insignificant(player_info):
				should_show = false
		
		if should_show:
			filtered_players.append(player_info)
		
		# Limit to recent players
		if show_recent_players_only and filtered_players.size() >= max_recent_players:
			break
	
	return filtered_players

func is_player_insignificant(player_info: Dictionary) -> bool:
	# Check if player meets significance threshold
	var level = player_info.get("level", 1)
	var last_seen_raw = player_info.get("last_seen", 0)
	
	# Convert last_seen to float if it's a string
	var last_seen: float = 0.0
	if last_seen_raw is String:
		last_seen = float(last_seen_raw)
	else:
		last_seen = float(last_seen_raw)
	
	var current_time = Time.get_unix_time_from_system()
	var time_since_seen = current_time - last_seen
	
	# Player is insignificant if:
	# 1. Level is below threshold AND
	# 2. Haven't been seen in over an hour (3600 seconds)
	return level < significance_threshold and time_since_seen > 3600

func spawn_editor_player_with_styling(player_id: String, spawn_pos: Vector2, player_info: Dictionary, rank: int, total_filtered: int):
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	# Check if player is lost (far from reasonable bounds)
	var is_lost = abs(spawn_pos.x) > 5000 or abs(spawn_pos.y) > 5000
	var safe_position = spawn_pos
	if is_lost:
		safe_position = Vector2(100, 100)  # Default safe spawn
	
	# Create a simple Node2D for editor representation
	var player = Node2D.new()
	player.name = "EditorPlayer_" + player_id
	player.position = safe_position
	
	# Add visual representation (sprite)
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(50, 50)
	sprite.texture = texture
	
	# Calculate transparency based on rank (age)
	var alpha = 1.0
	if use_transparency_gradient and total_filtered > 1:
		# Most recent = 1.0 alpha, oldest = oldest_player_alpha
		var age_ratio = float(rank) / float(total_filtered - 1)
		alpha = lerp(1.0, oldest_player_alpha, age_ratio)
	
	# Color and transparency based on player status
	var base_color = Color.CYAN
	if is_lost:
		base_color = Color.RED
	elif is_player_insignificant(player_info):
		base_color = Color.GRAY
	
	# Apply calculated alpha
	base_color.a = alpha
	sprite.modulate = base_color
	
	# Scale based on significance
	var scale_factor = 1.0
	if player_info.get("level", 1) >= significance_threshold * 2:
		scale_factor = 1.2  # Important players are slightly larger
	elif is_player_insignificant(player_info):
		scale_factor = 0.8  # Insignificant players are smaller
	
	sprite.scale = Vector2(scale_factor, scale_factor)
	player.add_child(sprite)
	
	# Add detailed label
	var label = Label.new()
	var level = player_info.get("level", 1)
	var last_seen_raw = player_info.get("last_seen", 0)
	
	# Convert last_seen to float if it's a string
	var last_seen: float = 0.0
	if last_seen_raw is String:
		last_seen = float(last_seen_raw)
	else:
		last_seen = float(last_seen_raw)
	
	var current_time = Time.get_unix_time_from_system()
	var hours_ago = int((current_time - last_seen) / 3600.0)
	
	var status_text = ""
	if is_lost:
		status_text += " (LOST)"
	elif hours_ago < 1:
		status_text += " (RECENT)"
	elif hours_ago < 24:
		status_text += " (" + str(hours_ago) + "h ago)"
	else:
		var days_ago = int(hours_ago / 24.0)
		status_text += " (" + str(days_ago) + "d ago)"
	
	label.text = player_id + " L" + str(level) + status_text
	label.position = Vector2(-40, -50)
	
	# Label styling based on significance
	var label_color = Color.WHITE
	if is_player_insignificant(player_info):
		label_color = Color.GRAY
	elif level >= significance_threshold * 2:
		label_color = Color.YELLOW
	
	label_color.a = alpha  # Apply same transparency
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	player.add_child(label)
	
	# Store enhanced metadata
	player.set_meta("persistent_player_id", player_id)
	player.set_meta("original_position", spawn_pos)
	player.set_meta("is_lost", is_lost)
	player.set_meta("player_level", level)
	player.set_meta("last_seen", last_seen)
	player.set_meta("is_significant", not is_player_insignificant(player_info))
	player.set_meta("rank", rank)
	
	# Add to spawn container and track
	spawn_container.add_child(player)
	editor_players[player_id] = player

# Filter control callbacks
func _on_max_recent_changed(value: int):
	max_recent_players = max(1, value)  # Ensure at least 1
	if Engine.is_editor_hint():
		print("📊 Max recent players changed to: ", max_recent_players)

func _on_refresh_filters(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔄 Refreshing display filters...")
		sync_editor_players_from_world_data()
		refresh_display_filters = false

# ==================== NPC PERSISTENCE SYSTEM ====================

func save_npcs():
	"""Save all current NPCs to world data (server only)"""
	if not multiplayer.is_server():
		return
	
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm or not world_data:
		return
	
	# Save each NPC's current state
	var saved_count = 0
	for npc_id in gm.npcs:
		var npc = gm.npcs[npc_id]
		if npc and npc.has_method("get_save_data"):
			var npc_save_data = npc.get_save_data()
			world_data.save_npc(
				npc_id,
				npc_save_data.get("npc_type", "unknown"),
				npc.position,
				npc_save_data.get("health", 100.0),
				npc_save_data.get("max_health", 100.0),
				npc_save_data.get("ai_state", "idle"),
				npc_save_data.get("ai_timer", 0.0),
				npc_save_data.get("config_data", {})
			)
			saved_count += 1
	
	# NOTE: Don't save here - GameManager handles the save to prevent race conditions
	# save_world_data()  # REMOVED: Causes race condition with concurrent saves
	print("WorldManager: Saved ", saved_count, " NPCs to persistent storage")

func load_npcs():
	"""Restore NPCs from world data on server startup"""
	if not multiplayer.is_server() or not world_data:
		return
	
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		print("WorldManager: Cannot load NPCs - GameManager not found")
		return
	
	var npc_count = world_data.get_npc_count()
	if npc_count == 0:
		print("WorldManager: No NPCs to load")
		return
	
	print("WorldManager: Loading ", npc_count, " NPCs from persistent storage")
	
	var loaded_count = 0
	var all_npcs = world_data.get_all_npcs()
	
	for npc_id in all_npcs:
		var npc_data = all_npcs[npc_id]
		var npc_type = npc_data.get("npc_type", "")
		var npc_position = npc_data.get("position", Vector2.ZERO)
		var config_data = npc_data.get("config_data", {})
		
		# Restore the NPC ID counter to prevent conflicts
		var id_number = int(npc_id.replace("npc_", ""))
		if id_number >= gm.next_npc_id:
			gm.next_npc_id = id_number + 1
		
		# Spawn the NPC directly using the saved ID
		gm._spawn_npc_locally(npc_id, npc_type, npc_position, config_data)
		# Broadcast to clients
		gm.rpc("sync_npc_spawn", npc_id, npc_type, npc_position, config_data)
		
		if npc_id in gm.npcs:
			# Restore additional state
			var npc = gm.npcs[npc_id]
			if npc.has_method("restore_save_data"):
				npc.restore_save_data(npc_data)
			loaded_count += 1
			print("Restored NPC: ", npc_id, " (", npc_type, ") at ", npc_position)
	
	print("WorldManager: Successfully loaded ", loaded_count, " NPCs")

func auto_save_npcs():
	"""Automatically save NPCs periodically (called by timer or game events)"""
	if multiplayer.is_server():
		save_npcs()

# ==================== PICKUP PERSISTENCE SYSTEM ====================

func save_pickups():
	"""Save all current pickups to world data (server only)"""
	if not multiplayer.is_server():
		return
	
	if not game_manager or not world_data:
		print("WorldManager: Cannot save pickups - missing references")
		return
	
	var saved_count = 0
	
	# Clear existing pickup data
	world_data.pickup_data.clear()
	
	# Save all current pickups
	for item_id in game_manager.pickups:
		var pickup = game_manager.pickups[item_id]
		if pickup and pickup.has_method("get_save_data"):
			var pickup_save_data = pickup.get_save_data()
			
			# Save pickup data to WorldData
			world_data.save_pickup(
				item_id,
				pickup_save_data.get("item_type", "generic"),
				pickup.position,
				pickup_save_data.get("pickup_value", 1.0),
				pickup_save_data.get("respawn_time", 0.0),
				pickup_save_data.get("is_collected", false),
				pickup_save_data.get("respawn_timer", 0.0),
				pickup_save_data.get("config_data", {})
			)
			saved_count += 1
	
	# NOTE: Don't save here - GameManager handles the save to prevent race conditions  
	# save_world_data()  # REMOVED: Causes race condition with concurrent saves
	print("WorldManager: Saved ", saved_count, " pickups to persistent storage")

func load_pickups():
	"""Restore pickups from world data on server startup"""
	if not multiplayer.is_server() or not world_data:
		return
	
	if not game_manager:
		print("WorldManager: Cannot load pickups - GameManager not available")
		return
	
	var pickup_save_data = world_data.get_all_pickups()
	if pickup_save_data.is_empty():
		print("WorldManager: No saved pickups to restore")
		return
	
	print("WorldManager: Loading ", pickup_save_data.size(), " pickups from save data...")
	
	var loaded_count = 0
	for item_id in pickup_save_data:
		var pickup_data = pickup_save_data[item_id]
		var item_type = pickup_data.get("item_type", "generic")
		var pickup_position = pickup_data.get("position", Vector2.ZERO)
		var config_data = pickup_data.get("config_data", {})
		
		# Handle special pickup types
		if item_type == "health_potion":
			config_data["healing_amount"] = pickup_data.get("pickup_value", 25.0)
		else:
			config_data["pickup_value"] = pickup_data.get("pickup_value", 1.0)
		
		config_data["respawn_time"] = pickup_data.get("respawn_time", 0.0)
		
		# Spawn the pickup
		var spawned_item_id = game_manager.spawn_pickup(item_type, pickup_position, config_data)
		
		# Restore pickup state after spawning
		if spawned_item_id != "" and spawned_item_id in game_manager.pickups:
			await get_tree().process_frame  # Wait for pickup to be fully initialized
			var pickup_node = game_manager.pickups[spawned_item_id]
			if pickup_node and pickup_node.has_method("restore_save_data"):
				pickup_node.restore_save_data(pickup_data)
			
			loaded_count += 1
			print("Restored pickup: ", item_id, " (", item_type, ") at ", pickup_position)
	
	print("WorldManager: Successfully loaded ", loaded_count, " pickups")

func auto_save_pickups():
	"""Automatically save pickups periodically (called by timer or game events)"""
	if multiplayer.is_server():
		save_pickups()
