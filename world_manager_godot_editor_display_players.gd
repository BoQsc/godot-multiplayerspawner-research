@tool
extends Node
class_name WorldManagerGodotEditorDisplayPlayers

@export_group("Editor Diagnostics")
@export var test_editor_display: bool = false : set = _on_test_editor_display
@export var cleanup_duplicate_players: bool = false : set = _on_cleanup_duplicates
@export var reset_all_players: bool = false : set = _on_reset_all_players

@export_group("Editor Player Visibility")
@export var toggle_players_visible: bool = false : set = _on_toggle_players_visible
@export var editor_players_visible: bool = true

# Editor player persistence
var editor_players: Dictionary = {}  # player_id -> player_node

# Component references
var world_manager: WorldManager
var spawn_container: Node2D
var player_search_component: WorldManagerGodotEditorPlayerSearch

func _ready():
	if not Engine.is_editor_hint():
		return
		
	# Find references to main components
	world_manager = get_parent() as WorldManager
	if not world_manager:
		print("❌ WorldManagerGodotEditorDisplayPlayers: Could not find WorldManager parent")
		return
		
	# Get references from world manager
	_refresh_component_references()
	
	# Component initialized successfully

# Refresh component references (call this after WorldManager is fully initialized)
func _refresh_component_references():
	if world_manager:
		spawn_container = world_manager.spawn_container
		player_search_component = world_manager.get_node_or_null("PlayerSearchComponent")
		
		# If spawn_container is still null, try to find it manually
		if not spawn_container:
			spawn_container = get_node_or_null("/root/Node2D/SpawnContainer")

# Export button handlers
func _on_test_editor_display(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔧 WorldManager: Testing editor display system...")
		test_editor_player_display()
		# Reset the button
		test_editor_display = false

func _on_cleanup_duplicates(value: bool):
	if Engine.is_editor_hint() and value:
		print("🧹 WorldManager: Cleaning up duplicate players...")
		cleanup_duplicate_players_from_identity_bug()
		# Reset the button
		cleanup_duplicate_players = false

func _on_reset_all_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔄 WorldManager: Resetting all player data...")
		reset_all_players_data()
		# Reset the button
		reset_all_players = false

func _on_toggle_players_visible(value: bool):
	if Engine.is_editor_hint() and value:
		# Try to refresh references if spawn_container is null
		if not spawn_container:
			_refresh_component_references()
		
		editor_players_visible = !editor_players_visible
		print("👁️ WorldManager: Toggling editor players visibility to ", "VISIBLE" if editor_players_visible else "HIDDEN")
		toggle_editor_players_visibility()
		# Reset the button
		toggle_players_visible = false

# Main editor player display function
func sync_editor_players_from_world_data():
	if not Engine.is_editor_hint():
		print("WorldManager: Not in editor, skipping player sync")
		return
	if not world_manager or not world_manager.world_data:
		print("WorldManager: No world data, skipping player sync")
		return
	if not spawn_container:
		print("WorldManager: No spawn container found, trying to refresh references...")
		_refresh_component_references()
		if not spawn_container:
			print("WorldManager: Still no spawn container found, skipping player sync")
			return
	
	print("WorldManager: Syncing editor players from world data...")
	
	# Clear existing editor players
	clear_editor_players()
	
	# Get and filter player data
	var all_player_data = world_manager.world_data.get_all_players()
	var filtered_players = player_search_component.get_filtered_players(all_player_data) if player_search_component else []
	
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

# Create styled editor player node
func spawn_editor_player_with_styling(player_id: String, spawn_pos: Vector2, player_info: Dictionary, rank: int, total_filtered: int):
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	# Check if player is lost (far from reasonable bounds)
	var is_lost = spawn_pos.y < -5000  # Only check for falling below world
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
	if player_search_component and player_search_component.use_transparency_gradient and total_filtered > 1:
		# Most recent = 1.0 alpha, oldest = oldest_player_alpha
		var age_ratio = float(rank) / float(total_filtered - 1)
		alpha = lerp(1.0, player_search_component.oldest_player_alpha, age_ratio)
	
	# Color and transparency based on player status
	var base_color = Color.CYAN
	if is_lost:
		base_color = Color.RED
	elif player_search_component and player_search_component.is_player_insignificant(player_info):
		base_color = Color.GRAY
	
	# Apply calculated alpha
	base_color.a = alpha
	sprite.modulate = base_color
	
	# Scale based on significance
	var scale_factor = 1.0
	if player_search_component and player_info.get("level", 1) >= player_search_component.significance_threshold * 2:
		scale_factor = 1.2  # Important players are slightly larger
	elif player_search_component and player_search_component.is_player_insignificant(player_info):
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
	if player_search_component and player_search_component.is_player_insignificant(player_info):
		label_color = Color.GRAY
	elif player_search_component and level >= player_search_component.significance_threshold * 2:
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
	player.set_meta("is_significant", not (player_search_component and player_search_component.is_player_insignificant(player_info)))
	player.set_meta("rank", rank)
	
	# Set initial visibility based on global setting
	player.visible = editor_players_visible
	
	# Add to scene and track
	spawn_container.add_child(player)
	editor_players[player_id] = player

# Simple editor player spawn (legacy function for compatibility)
func spawn_editor_player(player_id: String, spawn_pos: Vector2):
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	# Create basic player info for styling
	var player_info = {
		"position": spawn_pos,
		"level": 1,
		"last_seen": Time.get_unix_time_from_system()
	}
	
	spawn_editor_player_with_styling(player_id, spawn_pos, player_info, 0, 1)

# Clear all editor players
func clear_editor_players():
	if not Engine.is_editor_hint():
		return
	
	# Remove all existing editor players
	for player_id in editor_players.keys():
		var player = editor_players[player_id]
		if is_instance_valid(player):
			player.queue_free()
	
	editor_players.clear()

# Toggle visibility of all editor players
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
			print("💡 TIP: Use 'Toggle Players Visible' button to show them again")
	else:
		print("⚠️ No editor players found to toggle")

# Check for editor player movement (for position syncing)
func _check_for_editor_player_movement():
	if not Engine.is_editor_hint() or not world_manager or not world_manager.world_data:
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
		var stored_data = world_manager.world_data.get_player(persistent_id)
		var stored_position = stored_data["position"]
		
		# Check if editor position differs significantly from stored position
		var distance = player.position.distance_to(stored_position)
		if distance > 5.0:  # More than 5 pixels difference
			print("📍 Player ", persistent_id, " moved in editor: ", player.position, " (was ", stored_position, ")")
			# Update world data with new position
			world_manager.world_data.set_player_position(persistent_id, player.position)
			world_manager.world_data_changed.emit()

# Diagnostic and testing functions
func test_editor_player_display():
	if not Engine.is_editor_hint():
		return
	
	print("🔧 === EDITOR DISPLAY TEST ===")
	print("📊 Current editor players: ", editor_players.size())
	print("👁️ Players visible: ", editor_players_visible)
	print("📦 Spawn container: ", spawn_container.get_path() if spawn_container else "MISSING")
	print("🔍 Search component: ", "Found" if player_search_component else "MISSING")
	
	if spawn_container:
		var editor_player_count = 0
		for child in spawn_container.get_children():
			if child.name.begins_with("EditorPlayer_"):
				editor_player_count += 1
		print("🎭 EditorPlayer nodes in scene: ", editor_player_count)
	
	# Test basic spawn
	print("🧪 Testing spawn of test player...")
	spawn_editor_player("test_player_display", Vector2(200, 200))
	print("✅ Test complete")

func cleanup_duplicate_players_from_identity_bug():
	if not Engine.is_editor_hint() or not world_manager or not world_manager.world_data:
		return
	
	print("🧹 === CLEANING DUPLICATE PLAYERS ===")
	var all_players = world_manager.world_data.get_all_players()
	var duplicates_found = []
	var seen_positions = {}
	
	for player_id in all_players.keys():
		var player_data = all_players[player_id]
		var pos = player_data["position"]
		var pos_key = str(pos.x) + "," + str(pos.y)
		
		if pos_key in seen_positions:
			duplicates_found.append({
				"id": player_id,
				"position": pos,
				"duplicate_of": seen_positions[pos_key]
			})
		else:
			seen_positions[pos_key] = player_id
	
	print("🔍 Found ", duplicates_found.size(), " duplicate players")
	for dup in duplicates_found:
		print("  🗑️ ", dup.id, " at ", dup.position, " (duplicate of ", dup.duplicate_of, ")")
	
	if duplicates_found.size() > 0:
		print("⚠️ Manual cleanup required - this is for diagnostic purposes only")
	else:
		print("✅ No duplicates found")

func reset_all_players_data():
	if not Engine.is_editor_hint() or not world_manager or not world_manager.world_data:
		print("❌ Cannot reset - not in editor or no world data")
		return
	
	print("🔄 === RESETTING ALL PLAYER DATA ===")
	print("⚠️ This will clear ALL player data - are you sure?")
	print("💡 This is a diagnostic function - implement confirmation dialog if needed")
	
	# For now, just clear editor players as a safety measure
	clear_editor_players()
	print("✅ Cleared editor players only (world data preserved)")
	print("💡 To fully reset world data, implement world_data.clear_all_players() if needed")
