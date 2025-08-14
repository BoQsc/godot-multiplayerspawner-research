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
@export var sync_scene_to_world: bool = false : set = _on_sync_scene_to_world
@export var show_world_info: bool = false : set = _on_show_world_info
@export var save_world_now: bool = false : set = _on_save_world_now
@export var sync_editor_players: bool = false : set = _on_sync_editor_players
@export var rescue_lost_players: bool = false : set = _on_rescue_lost_players

var game_manager: Node
var is_loading: bool = false
var last_file_modified_time: int = 0
var last_tilemap_cell_count: int = 0

# Editor player persistence
var editor_players: Dictionary = {}  # player_id -> player_node
var spawn_container: Node2D

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
	
	# In editor: always apply world data to override scene's tile_map_data
	if Engine.is_editor_hint():
		if world_data and world_tile_map_layer:
			apply_world_data_to_tilemap()
			print("WorldManager: Editor refreshed with ", world_data.get_tile_count(), " tiles from persistent data")
		# Sync editor players from world data
		sync_editor_players_from_world_data()
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
		# Check if tilemap was modified in editor (direct painting)
		_check_for_tilemap_changes()
		# Check if editor players were moved
		_check_for_editor_player_movement()
	elif multiplayer.is_server():
		auto_save_timer += delta
		if auto_save_timer >= auto_save_interval:
			print("WorldManager: Auto-saving world data (", world_data.get_tile_count(), " tiles, ", world_data.get_player_count(), " players)")
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
		# Also sync editor players
		sync_editor_players_from_world_data()

func _check_for_tilemap_changes():
	if not world_tile_map_layer or not world_data:
		return
	
	var current_cell_count = world_tile_map_layer.get_used_cells().size()
	
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
	
	# Spawn editor players for each player in world data
	var player_data = world_data.get_all_players()
	print("WorldManager: Found ", player_data.size(), " players in world data")
	
	for player_id in player_data.keys():
		var player_info = player_data[player_id]
		print("WorldManager: Spawning editor player ", player_id, " at ", player_info["position"])
		spawn_editor_player(player_id, player_info["position"])
	
	print("WorldManager: Spawned ", editor_players.size(), " editor players")
	if editor_players.size() > 0:
		print("💡 TIP: Look in Scene tab under SpawnContainer for EditorPlayer nodes. Select them to drag around!")

func spawn_editor_player(player_id: String, position: Vector2):
	if not Engine.is_editor_hint() or not spawn_container:
		print("WorldManager: Cannot spawn editor player - missing requirements")
		return
	
	# Check if player is lost (far from reasonable bounds)
	var is_lost = abs(position.x) > 5000 or abs(position.y) > 5000
	var safe_position = position
	if is_lost:
		safe_position = Vector2(100, 100)  # Default safe spawn
		print("WorldManager: Player ", player_id, " is lost at ", position, ", spawning at safe position ", safe_position)
	
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
	
	# Make selectable in editor by giving it a unique node configuration
	player.set_notify_transform(true)  # Enable transform notifications
	
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
