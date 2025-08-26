@tool
extends Node
class_name WorldManagerGodotEditorPlayerSearch

@export_group("Player Search & Management")
@export var search_term: String = ""
@export var search_players: bool = false : set = _on_search_players
@export var focus_on_player: String = ""
@export var focus_camera: bool = false : set = _on_focus_camera
@export var list_all_players: bool = false : set = _on_list_all_players
@export var show_player_distances: bool = false : set = _on_show_distances

@export_group("Player Focus Mode")
@export var focus_player_list: String = "" # Comma-separated list of player IDs
@export var apply_focus: bool = false : set = _on_apply_focus
@export var clear_focus: bool = false : set = _on_clear_focus
@export var highlight_focused: bool = true

@export_group("Player Filtering & Display")
@export var show_recent_players_only: bool = false
@export var max_recent_players: int = 50 : set = _on_max_recent_changed
@export var hide_insignificant_players: bool = false
@export var significance_threshold: int = 1
@export var use_transparency_gradient: bool = true
@export var oldest_player_alpha: float = 0.3
@export var refresh_display_filters: bool = false : set = _on_refresh_filters

# Focus mode state
var focused_players: Array[String] = []
var is_focus_mode_active: bool = false

# Component references
var world_manager: WorldManager
var spawn_container: Node2D

func _ready():
	if not Engine.is_editor_hint():
		return
		
	# Find references to main components
	world_manager = get_parent() as WorldManager
	if not world_manager:
		print("❌ WorldManagerGodotEditorPlayerSearch: Could not find WorldManager parent")
		return
		
	# Get spawn container reference from world manager
	spawn_container = world_manager.spawn_container

# Export button handlers
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

func _on_max_recent_changed(value: int):
	max_recent_players = max(1, value)  # Ensure at least 1
	if Engine.is_editor_hint():
		print("📊 Max recent players changed to: ", max_recent_players)

func _on_refresh_filters(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔄 Refreshing display filters...")
		if world_manager and world_manager.has_method("sync_editor_players_from_world_data"):
			world_manager.sync_editor_players_from_world_data()
		refresh_display_filters = false

# Core search functionality
func search_for_players(term: String):
	if not world_manager or not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var matches = []
	var player_data = world_manager.world_data.get_all_players()
	
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
	if not world_manager or not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var player_info = world_manager.world_data.get_player(player_id)
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
	if not world_manager or not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var player_data = world_manager.world_data.get_all_players()
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
		if player.distance > 50000:
			status = "🚨 LOST"
		elif player.distance > 1000:
			status = "⚠️ FAR"
		
		print("  ", status, " ", player.id, " at (", int(info.position.x), ", ", int(info.position.y), ") - Distance: ", int(player.distance), " - Level: ", info.level, " - HP: ", info.health, "/", info.max_health)

func show_player_distances_from_spawn():
	if not world_manager or not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var spawn_point = Vector2(100, 100)  # Default spawn
	var player_data = world_manager.world_data.get_all_players()
	
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
		elif distance < 50000:
			far_players.append({"id": player_id, "distance": distance})
		else:
			lost_players.append({"id": player_id, "distance": distance})
	
	print("✅ CLOSE (< 500 units): ", close_players.size(), " players")
	for player in close_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("⚠️ MEDIUM (500-1000 units): ", medium_players.size(), " players")
	for player in medium_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("🔶 FAR (1000-50000 units): ", far_players.size(), " players")
	for player in far_players:
		print("    ", player.id, " - ", int(player.distance), " units")
	
	print("🚨 LOST (> 50000 units): ", lost_players.size(), " players")
	for player in lost_players:
		print("    ", player.id, " - ", int(player.distance), " units")

# Focus management functions
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
			print("  ❌ Player not found in editor: ", player_id)
	
	print("🎯 Focus complete: ", visible_count, " visible, ", hidden_count, " hidden, ", not_found_count, " not found")

func clear_player_focus():
	if not Engine.is_editor_hint() or not spawn_container:
		return
	
	focused_players.clear()
	is_focus_mode_active = false
	
	var restored_count = 0
	
	# Show all players and remove highlights
	for child in spawn_container.get_children():
		if child.name.begins_with("EditorPlayer_"):
			child.visible = world_manager.editor_players_visible if world_manager else true  # Respect global visibility setting
			remove_player_highlight(child)
			restored_count += 1
	
	print("🔄 Focus mode cleared - restored visibility for ", restored_count, " players")
	var visibility_status = "VISIBLE" if (world_manager and world_manager.editor_players_visible) else "HIDDEN"
	print("💡 Players now follow global visibility setting (currently ", visibility_status, ")")

# Player filtering functions
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

# Player highlighting functions
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
