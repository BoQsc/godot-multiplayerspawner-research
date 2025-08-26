@tool
extends Node
class_name WorldManagerGodotEditorPlayerSearch

@export_group("Player Search & Management")
@export var search_term: String = "player_"
@export var search_players: bool = false : set = _on_search_players
@export var mark_player_visually: bool = false : set = _on_mark_player
@export var focus_camera: bool = false : set = _on_focus_camera
@export var list_all_players: bool = false : set = _on_list_all_players
@export var show_player_distances: bool = false : set = _on_show_distances
@export var cleanup_focus_markers: bool = false : set = _on_cleanup_markers

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

# Camera focus state
var is_camera_focused: bool = false

# Component references
var world_manager: WorldManager
var spawn_container: Node2D

func _ready():
	if not Engine.is_editor_hint():
		return
		
	# Find references to main components
	world_manager = get_parent() as WorldManager
	
	# If parent isn't WorldManager, try to find it in the scene
	if not world_manager:
		world_manager = get_node_or_null("../") as WorldManager  # Try parent of parent
		if not world_manager:
			world_manager = get_tree().get_first_node_in_group("world_manager") as WorldManager
	
	if not world_manager:
		print("❌ WorldManagerGodotEditorPlayerSearch: Could not find WorldManager anywhere")
		print("🔧 DEBUG: My parent is: ", get_parent())
		print("🔧 DEBUG: My path is: ", get_path())
		return
	else:
		print("✅ WorldManagerGodotEditorPlayerSearch: Found WorldManager at: ", world_manager.get_path())
		
	# Get spawn container reference - will be set later when world manager is fully initialized
	_refresh_spawn_container_reference()
	
	# Clean up any leftover focus markers from previous sessions
	cleanup_old_focus_markers()

# Refresh spawn container reference (call this after WorldManager is fully initialized)
func _refresh_spawn_container_reference():
	if world_manager:
		spawn_container = world_manager.spawn_container
		
		# If spawn_container is still null, try to find it manually
		if not spawn_container:
			spawn_container = get_node_or_null("/root/Node2D/SpawnContainer")
			if not spawn_container and get_tree():
				spawn_container = get_tree().get_first_node_in_group("spawn_container")

# Export button handlers
func _on_search_players(value: bool):
	if Engine.is_editor_hint() and value:
		print("🔍 WorldManager: Searching for players containing '", search_term, "'...")
		search_for_players(search_term)
		# Reset the button
		search_players = false

func _on_mark_player(value: bool):
	if Engine.is_editor_hint() and value:
		# Check if we should unmark instead (toggle functionality)
		if is_camera_focused and world_manager and world_manager.spawn_container:
			var markers_removed = remove_all_visual_markers()
			if markers_removed > 0:
				is_camera_focused = false
				print("🔄 Removed ", markers_removed, " visual markers")
				print("💡 TIP: Click 'Mark Player Visually' again to mark players")
				mark_player_visually = false
				return
		
		print("🔧 DEBUG: search_term field contains: '", search_term, "'")
		
		if search_term != "" and search_term.strip_edges() != "":
			var player_to_mark = search_term.strip_edges()
			print("🎯 Marking player visually based on search term: ", player_to_mark)
			mark_player_visually_by_term(player_to_mark)
		else:
			print("❌ Please enter a search term to mark a player")
			print("💡 TIP: Enter partial player ID (e.g., '997') or full ID")
		# Reset the button
		mark_player_visually = false

func _on_focus_camera(value: bool):
	if Engine.is_editor_hint() and value:
		print("📷 Focus Camera: Attempting to pan Godot editor viewport")
		
		# Always clean up first
		_refresh_spawn_container_reference()
		cleanup_focus_helpers()
		
		if search_term != "" and search_term.strip_edges() != "":
			var player_to_focus = search_term.strip_edges()
			print("🎯 Focusing editor camera on player matching: ", player_to_focus)
			focus_editor_camera_on_player(player_to_focus)
		else:
			print("❌ Please enter a search term to focus camera on a player")
			print("💡 TIP: Enter partial player ID (e.g., '997') or full ID")
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

func _on_cleanup_markers(value: bool):
	if Engine.is_editor_hint() and value:
		print("🧹 Manually cleaning up focus markers...")
		cleanup_old_focus_markers()
		# Reset the button
		cleanup_focus_markers = false

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
		var display_component = world_manager.get_node_or_null("DisplayPlayersComponent") if world_manager else null
		if display_component and display_component.has_method("sync_editor_players_from_world_data"):
			display_component.sync_editor_players_from_world_data()
		else:
			print("❌ Could not find DisplayPlayersComponent to refresh")
		refresh_display_filters = false

# Core search functionality
func search_for_players(term: String):
	if not world_manager:
		print("❌ No world_manager available")
		return
	if not world_manager.world_data:
		print("❌ No world_data available in world_manager")
		return
	
	var player_data = world_manager.world_data.get_all_players()
	if player_data.is_empty():
		print("❌ World data exists but contains no players")
		return
	
	print("🔍 Searching in ", player_data.size(), " total players for term '", term, "'")
	
	# Show first few player IDs as examples
	var example_ids = []
	var count = 0
	for player_id in player_data.keys():
		example_ids.append(player_id)
		count += 1
		if count >= 3:
			break
	print("📋 Example player IDs: ", example_ids)
	
	var matches = []
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

func mark_player_visually_by_term(term: String):
	if not world_manager or not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var all_players = world_manager.world_data.get_all_players()
	var matches = []
	
	# Find players matching the search term
	for player_id in all_players.keys():
		if term == "" or player_id.to_lower().contains(term.to_lower()):
			var player_info = all_players[player_id]
			matches.append({
				"id": player_id,
				"position": player_info["position"],
				"level": player_info.get("level", 1)
			})
	
	print("🔍 Found ", matches.size(), " players matching '", term, "'")
	
	if matches.size() == 0:
		print("❌ No players found matching '", term, "'")
		return
	elif matches.size() == 1:
		# Single match - mark this player
		var player = matches[0]
		print("🎯 Marking single match: ", player.id)
		create_visual_marker(player.id, player.position)
	else:
		# Multiple matches - mark the first few
		print("🎯 Multiple matches found - marking first 3:")
		for i in range(min(3, matches.size())):
			var player = matches[i]
			print("  • Marking: ", player.id)
			create_visual_marker(player.id, player.position, i)

func create_visual_marker(player_id: String, pos: Vector2, index: int = 0):
	if not Engine.is_editor_hint() or not world_manager:
		return
	
	# Refresh spawn container reference if needed
	if not spawn_container:
		_refresh_spawn_container_reference()
	
	if not spawn_container:
		print("❌ Cannot create visual marker - spawn container not found")
		return
	
	# Create a unique marker name
	var marker_name = "VISUAL_MARK_" + str(index) if index > 0 else "VISUAL_MARK"
	
	# Remove existing marker with same name
	var existing_marker = world_manager.spawn_container.get_node_or_null(marker_name)
	if existing_marker:
		existing_marker.queue_free()
	
	# Create visual marker
	var marker = Node2D.new()
	marker.name = marker_name
	marker.position = pos
	
	# Add visible sprite
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(120, 120)
	sprite.texture = texture
	sprite.modulate = Color.ORANGE if index == 0 else Color.YELLOW
	marker.add_child(sprite)
	
	# Add label
	var label = Label.new()
	label.text = "MARK: " + player_id.substr(-12) + "\nPos: " + str(pos)
	label.position = Vector2(-60, -90)
	label.add_theme_color_override("font_color", Color.WHITE)
	marker.add_child(label)
	
	spawn_container.add_child(marker)
	is_camera_focused = true  # Reuse this flag for "has visual markers"
	
	print("✅ Created visual marker '", marker_name, "' for player ", player_id.substr(-12))

func remove_all_visual_markers() -> int:
	if not world_manager:
		return 0
	
	# Refresh spawn container reference if needed
	if not spawn_container:
		_refresh_spawn_container_reference()
	
	if not spawn_container:
		return 0
	
	var removed_count = 0
	for child in world_manager.spawn_container.get_children():
		if child.name.begins_with("VISUAL_MARK"):
			child.queue_free()
			removed_count += 1
	
	return removed_count

func focus_editor_camera_on_player(term: String):
	if not Engine.is_editor_hint() or not world_manager or not world_manager.world_data:
		print("❌ Editor camera focus only works in editor with world data")
		return
	
	# Find the player position
	var target_position = find_player_position_by_term(term)
	if target_position == Vector2.ZERO:
		print("❌ Could not find player position for term: ", term)
		return
	
	print("📍 Found player position: ", target_position)
	
	# Create the working visual marker system
	create_focus_marker_at_position(target_position, term)
	
	# Try viewport panning as bonus feature
	try_viewport_panning_bonus(target_position)

func find_player_position_by_term(term: String) -> Vector2:
	if not world_manager or not world_manager.world_data:
		return Vector2.ZERO
	
	var all_players = world_manager.world_data.get_all_players()
	
	# Find first matching player
	for player_id in all_players.keys():
		if term == "" or player_id.to_lower().contains(term.to_lower()):
			var player_info = all_players[player_id]
			return player_info["position"]
	
	return Vector2.ZERO

func create_focus_marker_at_position(target_pos: Vector2, marker_search_term: String):
	if not spawn_container:
		_refresh_spawn_container_reference()
	
	if not spawn_container:
		print("❌ Cannot create focus marker - no spawn container")
		return
	
	# Remove any existing focus marker
	var existing = spawn_container.get_node_or_null("FOCUS_MARKER")
	if existing:
		existing.queue_free()
	
	# Create a bright, visible marker
	var marker = Node2D.new()
	marker.name = "FOCUS_MARKER"
	marker.position = target_pos
	
	# Large bright circle
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(200, 200)
	sprite.texture = texture
	sprite.modulate = Color.YELLOW
	marker.add_child(sprite)
	
	# Clear label
	var label = Label.new()
	label.text = "🎯 " + marker_search_term
	label.position = Vector2(-50, -120)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.BLACK)
	marker.add_child(label)
	
	spawn_container.add_child(marker)
	
	print("✅ Created focus marker - Look for yellow circle in 2D editor")
	print("📍 Coordinates: X=", int(target_pos.x), " Y=", int(target_pos.y))

func try_viewport_panning_bonus(target_pos: Vector2):
	print("🔧 IMPROVED METHOD: Reset first, then apply correct transform...")
	
	# First, reset any previous transform
	if last_panned_viewport and is_instance_valid(last_panned_viewport):
		if last_panned_viewport.has_method("set_canvas_transform"):
			last_panned_viewport.set_canvas_transform(last_original_transform)
			print("🔧 Reset previous viewport transform")
	
	var subviewports = find_all_subviewports(get_tree().root)
	print("🔧 Found ", subviewports.size(), " SubViewports")
	
	# Find the 2D editor viewport specifically (CanvasItemEditor)
	var canvas_editor_viewport: SubViewport = null
	var largest_viewport: SubViewport = null
	var largest_size: float = 0.0
	
	for viewport in subviewports:
		var path = str(viewport.get_path())
		var size = viewport.get_visible_rect().size
		var area = size.x * size.y
		
		print("🔧 SubViewport: ", path, " Size: ", size, " Area: ", area)
		
		# Look specifically for the CanvasItemEditor viewport (2D editor)
		if path.contains("CanvasItemEditor"):
			canvas_editor_viewport = viewport
			print("🎯 FOUND 2D EDITOR VIEWPORT: ", path)
		
		if area > largest_size:
			largest_size = area
			largest_viewport = viewport
	
	# Prefer the CanvasItemEditor viewport if found
	var target_viewport = canvas_editor_viewport if canvas_editor_viewport else largest_viewport
	
	if target_viewport:
		if canvas_editor_viewport:
			print("🎯 Using 2D EDITOR viewport: ", target_viewport.get_path())
		else:
			print("🎯 Using largest viewport (fallback): ", target_viewport.get_path())
		
		if target_viewport.has_method("get_canvas_transform"):
			var current_transform = target_viewport.get_canvas_transform()
			var viewport_size = target_viewport.get_visible_rect().size
			
			# Store original for next reset
			last_original_transform = current_transform
			last_panned_viewport = target_viewport
			
			print("🔧 Current origin: ", current_transform.origin)
			print("🔧 Viewport size: ", viewport_size)
			print("🔧 Target position: ", target_pos)
			
			# CORRECTED CALCULATION: Pan so target appears in center of viewport
			var viewport_center = viewport_size / 2
			var new_origin = target_pos - viewport_center
			
			var new_transform = current_transform
			new_transform.origin = -new_origin  # Negative because we're moving the world view
			
			print("🔧 Viewport center: ", viewport_center)
			print("🔧 Calculated new origin: ", new_transform.origin)
			
			if target_viewport.has_method("set_canvas_transform"):
				target_viewport.set_canvas_transform(new_transform)
				print("✅ Applied transform to 2D EDITOR viewport!")
				print("🎯 The 2D editor should now show the player!")
			else:
				print("❌ No set_canvas_transform method")
		else:
			print("❌ No get_canvas_transform method")
	else:
		print("❌ No suitable viewports found")

func find_all_viewports_recursively(node: Node) -> Array:
	var viewports = []
	
	if node is Viewport:
		viewports.append(node)
	
	for child in node.get_children():
		viewports.append_array(find_all_viewports_recursively(child))
	
	return viewports

# Store the last successful viewport for resetting
var last_panned_viewport: Viewport = null
var last_original_transform: Transform2D

func reset_viewport_transforms():
	print("🔧 Resetting viewport transforms...")
	
	# Reset the last successful viewport if we have one
	if last_panned_viewport and is_instance_valid(last_panned_viewport):
		if last_panned_viewport.has_method("set_canvas_transform") and last_original_transform:
			last_panned_viewport.set_canvas_transform(last_original_transform)
			print("✅ Reset last panned viewport to original transform")
	
	# Clear the reference
	last_panned_viewport = null
	last_original_transform = Transform2D()

func try_transform_viewport(viewport: Viewport, target_pos: Vector2) -> bool:
	if viewport.has_method("get_canvas_transform"):
		var current_transform = viewport.get_canvas_transform()
		var viewport_size = viewport.get_visible_rect().size
		if viewport_size.length() > 0:  # Valid viewport size
			print("🔧 Viewport size: ", viewport_size, " Current origin: ", current_transform.origin)
			
			# Calculate new transform
			var new_transform = current_transform
			new_transform.origin = viewport_size / 2 - target_pos
			
			print("🔧 Would apply transform - New origin: ", new_transform.origin)
			
			if viewport.has_method("set_canvas_transform"):
				# Store original for potential rollback
				last_original_transform = current_transform
				last_panned_viewport = viewport
				
				# Apply the transform
				viewport.set_canvas_transform(new_transform)
				print("✅ Transform applied to: ", viewport.get_path())
				
				# Wait a moment to see the effect
				await get_tree().process_frame
				
				# Check if this looks like it worked for 2D editor panning
				# (This is where we'd add logic to detect if we moved the right thing)
				
				return true
	
	return false

func try_direct_editor_viewport_pan(target_pos: Vector2) -> bool:
	print("🔧 Method 1: Direct editor viewport search...")
	
	# Search through the entire scene tree for editor viewports
	var root = get_tree().root
	var editor_viewports = find_all_editor_viewports(root)
	
	print("🔧 Found ", editor_viewports.size(), " potential editor viewports")
	
	for viewport in editor_viewports:
		print("🔧 Trying viewport: ", viewport.get_path())
		if try_pan_viewport(viewport, target_pos):
			return true
	
	return false

func try_canvas_item_editor_pan(target_pos: Vector2) -> bool:
	print("🔧 Method 2: Canvas item editor search...")
	
	# Look specifically for CanvasItemEditor nodes
	var root = get_tree().root
	var canvas_editors = find_canvas_item_editors(root)
	
	print("🔧 Found ", canvas_editors.size(), " canvas editors")
	
	for editor in canvas_editors:
		print("🔧 Trying canvas editor: ", editor.get_path())
		if try_manipulate_canvas_editor(editor, target_pos):
			return true
	
	return false

func try_subviewport_manipulation(target_pos: Vector2) -> bool:
	print("🔧 Method 3: SubViewport manipulation...")
	
	var root = get_tree().root
	var subviewports = find_all_subviewports(root)
	
	print("🔧 Found ", subviewports.size(), " subviewports")
	
	for viewport in subviewports:
		print("🔧 Trying subviewport: ", viewport.get_path())
		if try_pan_viewport(viewport, target_pos):
			return true
	
	return false

func try_main_viewport_transform(target_pos: Vector2) -> bool:
	print("🔧 Method 4: Main viewport transform...")
	
	var main_viewport = get_viewport()
	if main_viewport:
		print("🔧 Working with main viewport: ", main_viewport.get_path())
		return try_pan_viewport(main_viewport, target_pos)
	
	return false

func find_all_editor_viewports(node: Node) -> Array:
	var viewports = []
	
	if node is Viewport:
		var path_str = str(node.get_path()).to_lower()
		if path_str.contains("editor") or path_str.contains("canvas") or path_str.contains("2d"):
			viewports.append(node)
	
	for child in node.get_children():
		viewports.append_array(find_all_editor_viewports(child))
	
	return viewports

func find_canvas_item_editors(node: Node) -> Array:
	var editors = []
	
	var node_class = node.get_class().to_lower()
	if node_class.contains("canvas") and node_class.contains("editor"):
		editors.append(node)
	
	for child in node.get_children():
		editors.append_array(find_canvas_item_editors(child))
	
	return editors

func find_all_subviewports(node: Node) -> Array:
	var viewports = []
	
	if node is SubViewport:
		viewports.append(node)
	
	for child in node.get_children():
		viewports.append_array(find_all_subviewports(child))
	
	return viewports

func try_pan_viewport(viewport: Viewport, target_pos: Vector2) -> bool:
	print("🔧 Attempting to pan viewport: ", viewport.get_class())
	
	# Method A: Canvas transform manipulation
	if viewport.has_method("get_canvas_transform"):
		var transform = viewport.get_canvas_transform()
		var viewport_size = viewport.get_visible_rect().size
		var new_origin = viewport_size / 2 - target_pos
		
		transform.origin = new_origin
		
		if viewport.has_method("set_canvas_transform"):
			viewport.set_canvas_transform(transform)
			print("✅ Applied canvas transform")
			return true
	
	# Method B: Global canvas transform
	if viewport.has_method("get_global_canvas_transform"):
		var global_transform = viewport.get_global_canvas_transform()
		var viewport_size = viewport.get_visible_rect().size
		var new_origin = viewport_size / 2 - target_pos
		
		global_transform.origin = new_origin
		
		if viewport.has_method("set_global_canvas_transform"):
			viewport.set_global_canvas_transform(global_transform)
			print("✅ Applied global canvas transform")
			return true
	
	return false

func try_manipulate_canvas_editor(editor: Node, target_pos: Vector2) -> bool:
	print("🔧 Attempting to manipulate canvas editor: ", editor.get_class())
	
	# Look for viewport children in the canvas editor
	for child in editor.get_children():
		if child is Viewport:
			if try_pan_viewport(child, target_pos):
				return true
	
	# Try to call any panning methods directly on the editor
	if editor.has_method("set_pan"):
		editor.call("set_pan", -target_pos)
		print("✅ Called set_pan on canvas editor")
		return true
	
	if editor.has_method("pan_to"):
		editor.call("pan_to", target_pos)
		print("✅ Called pan_to on canvas editor")
		return true
	
	return false

func create_large_focus_indicator(target_pos: Vector2, indicator_search_term: String):
	if not spawn_container:
		return
	
	# Remove any existing camera target
	var existing = spawn_container.get_node_or_null("CAMERA_TARGET")
	if existing:
		existing.queue_free()
	
	# Create a very large, visible target
	var target = Node2D.new()
	target.name = "CAMERA_TARGET"
	target.position = target_pos
	
	# Create a large, bright sprite
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(300, 300)
	sprite.texture = texture
	sprite.modulate = Color.RED
	sprite.modulate.a = 0.8  # Slightly transparent
	target.add_child(sprite)
	
	# Add a pulsing animation (fix infinite loop)
	var tween = create_tween()
	tween.set_loops(10)  # Limit to 10 loops instead of infinite
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), 0.5)
	
	# Add a very visible label
	var label = Label.new()
	label.text = "🎯 CAMERA TARGET 🎯\n" + indicator_search_term + "\nSELECT ME!"
	label.position = Vector2(-100, -200)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	target.add_child(label)
	
	spawn_container.add_child(target)
	
	print("✅ Created large camera target at ", target_pos)
	print("📋 MANUAL NAVIGATION INSTRUCTIONS:")
	print("   1. In Scene tab, expand SpawnContainer")
	print("   2. Find and select 'CAMERA_TARGET'")
	print("   3. In the 2D editor, zoom out until you see the red rectangle")
	print("   4. The red rectangle marks the exact player location")
	print("   5. You can drag the camera target in the 2D editor to move it")

func try_automatic_camera_focus(target_pos: Vector2) -> bool:
	# Try the most reliable method first - scene camera
	var scene_camera = find_active_camera_2d()
	if scene_camera:
		scene_camera.global_position = target_pos
		scene_camera.force_update_scroll()
		return true
	
	# Try viewport manipulation
	var viewport = get_viewport()
	if viewport and viewport.has_method("get_canvas_transform"):
		var transform = viewport.get_canvas_transform()
		transform.origin = viewport.get_visible_rect().size / 2 - target_pos
		if viewport.has_method("set_canvas_transform"):
			viewport.set_canvas_transform(transform)
			return true
	
	return false

func try_editor_interface_panning(target_pos: Vector2) -> bool:
	print("🔧 Attempting EditorInterface method...")
	
	# Try to access the editor through Engine
	if Engine.has_singleton("EditorInterface"):
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			print("📷 Found EditorInterface singleton")
			# Try to get the main screen control
			var main_screen = editor_interface.get_editor_main_screen()
			if main_screen:
				print("📷 Found main screen control")
				# This is complex - EditorInterface doesn't directly expose viewport panning
			return false
	
	# Try alternative approach - look for editor-specific nodes
	var scene_tree = get_tree()
	if scene_tree and scene_tree.get_root():
		var root = scene_tree.get_root()
		print("📷 Searching editor tree for viewport controls...")
		
		# Look for editor viewport nodes
		var editor_viewport = find_editor_viewport_recursive(root)
		if editor_viewport:
			print("📷 Found potential editor viewport: ", editor_viewport.get_class())
			return try_manipulate_editor_viewport(editor_viewport, target_pos)
	
	return false

func try_editor_2d_camera_panning(target_pos: Vector2) -> bool:
	print("🔧 Attempting 2D camera method...")
	
	# Look for any Camera2D in the current scene tree
	var camera = find_active_camera_2d()
	if camera:
		camera.global_position = target_pos
		camera.force_update_scroll()
		print("✅ Moved scene Camera2D to target position")
		return true
	
	return false

func find_active_camera_2d() -> Camera2D:
	# Look for Camera2D nodes in the scene
	var scene_root = get_tree().current_scene if get_tree() else null
	if scene_root:
		return find_camera_2d_recursive(scene_root)
	return null

func find_camera_2d_recursive(node: Node) -> Camera2D:
	if node is Camera2D and node.is_current():
		return node
	
	for child in node.get_children():
		var result = find_camera_2d_recursive(child)
		if result:
			return result
	
	return null

func find_editor_viewport_recursive(node: Node) -> Node:
	if not node:
		return null
	
	var node_class_name = node.get_class()
	
	# Look for specific editor viewport classes
	if node_class_name.contains("Viewport") or node_class_name.contains("CanvasItemEditor") or node_class_name.contains("SubViewport"):
		# Check if this looks like an editor viewport
		var node_path = str(node.get_path())
		if node_path.contains("Editor") or node_path.contains("Canvas"):
			return node
	
	# Recursively search children
	for child in node.get_children():
		var result = find_editor_viewport_recursive(child)
		if result:
			return result
	
	return null

func try_manipulate_editor_viewport(viewport_node: Node, target_pos: Vector2) -> bool:
	print("🔧 Attempting to manipulate editor viewport: ", viewport_node.get_class())
	
	# Try different approaches based on the viewport type
	if viewport_node is SubViewport:
		var subviewport = viewport_node as SubViewport
		print("📷 Working with SubViewport")
		
		# Try to find the camera or transform in the subviewport
		var camera = find_camera_in_viewport(subviewport)
		if camera:
			camera.global_position = target_pos
			print("✅ Moved camera in SubViewport")
			return true
	
	# Try to access viewport transform directly
	if viewport_node.has_method("set_global_canvas_transform"):
		print("🔧 Attempting canvas transform manipulation...")
		var transform = Transform2D()
		transform.origin = -target_pos  # Negative because we're moving the canvas, not the camera
		viewport_node.call("set_global_canvas_transform", transform)
		print("✅ Applied canvas transform")
		return true
	
	# Try to find and manipulate any Control nodes that might handle panning
	if viewport_node.has_method("get_children"):
		for child in viewport_node.get_children():
			if child is Control:
				if child.has_method("set_position") or child.has_method("set_global_position"):
					print("🔧 Trying to move Control child: ", child.get_class())
					if child.has_method("set_global_position"):
						child.set_global_position(-target_pos)
					elif child.has_method("set_position"):
						child.set_position(-target_pos)
					return true
	
	return false

func find_camera_in_viewport(viewport: Viewport) -> Camera2D:
	for child in viewport.get_children():
		if child is Camera2D:
			return child
		# Recursively search
		var result = find_camera_in_viewport_recursive(child)
		if result:
			return result
	return null

func find_camera_in_viewport_recursive(node: Node) -> Camera2D:
	if node is Camera2D:
		return node
	for child in node.get_children():
		var result = find_camera_in_viewport_recursive(child)
		if result:
			return result
	return null

func try_viewport_panning(target_pos: Vector2) -> bool:
	print("🔧 Attempting advanced viewport method...")
	
	# Get the current viewport and try more sophisticated manipulation
	var viewport = get_viewport()
	if viewport:
		print("📷 Working with viewport: ", viewport.get_class())
		
		# Try to access the viewport's canvas transform
		if viewport.has_method("get_canvas_transform"):
			var current_transform = viewport.get_canvas_transform()
			print("📷 Current canvas transform: ", current_transform)
			
			# Calculate new transform to center on target
			var new_transform = current_transform
			new_transform.origin = viewport.get_visible_rect().size / 2 - target_pos
			
			if viewport.has_method("set_canvas_transform"):
				viewport.set_canvas_transform(new_transform)
				print("✅ Applied new canvas transform")
				return true
		
		# Alternative: try to access the global canvas transform
		if viewport.has_method("get_global_canvas_transform"):
			var global_transform = viewport.get_global_canvas_transform()
			print("📷 Current global canvas transform: ", global_transform)
			
			var new_global_transform = global_transform
			new_global_transform.origin = viewport.get_visible_rect().size / 2 - target_pos
			
			if viewport.has_method("set_global_canvas_transform"):
				viewport.set_global_canvas_transform(new_global_transform)
				print("✅ Applied new global canvas transform")
				return true
	
	return false

func try_selection_helper_method(target_pos: Vector2, term: String) -> bool:
	print("🔧 Creating selection helper method...")
	
	# Create a temporary node that gets selected, forcing editor to center on it
	if world_manager:
		# Refresh spawn container reference if needed
		if not spawn_container:
			_refresh_spawn_container_reference()
		
		if spawn_container:
			var helper = Node2D.new()
			helper.name = "CAMERA_FOCUS_HELPER"
			helper.position = target_pos
			
			# Add a distinctive visual element
			var sprite = Sprite2D.new()
			var texture = PlaceholderTexture2D.new()
			texture.size = Vector2(200, 200)
			sprite.texture = texture
			sprite.modulate = Color.RED
			helper.add_child(sprite)
			
			var label = Label.new()
			label.text = "CAMERA FOCUS\n" + term
			label.position = Vector2(-100, -120)
			label.add_theme_color_override("font_color", Color.WHITE)
			helper.add_child(label)
			
			spawn_container.add_child(helper)
		
			
			print("✅ Created camera focus helper - select it in Scene tab to center view")
			print("💡 The red square marks the focus location")
			
			# Schedule auto-removal without await
			if get_tree():
				get_tree().create_timer(15.0).timeout.connect(func(): 
					if is_instance_valid(helper):
						helper.queue_free()
				)
			
			return true
	
	return false

# Clean up focus helpers specifically (more targeted than cleanup_old_focus_markers)
func cleanup_focus_helpers():
	if not spawn_container:
		return
	
	# Reset viewport transforms first
	reset_viewport_transforms()
	
	# Remove focus helpers from camera focus system
	var focus_names = ["FOCUS_HERE", "CAMERA_FOCUS_HELPER", "CAMERA_TARGET", "FOCUS_MARKER"]
	for helper_name in focus_names:
		var helper = spawn_container.get_node_or_null(helper_name)
		if helper:
			helper.queue_free()
	
	# Also check children for any that start with these prefixes
	for child in spawn_container.get_children():
		if child.name.begins_with("FOCUS_HERE") or child.name.begins_with("CAMERA_FOCUS_HELPER") or child.name.begins_with("CAMERA_TARGET") or child.name.begins_with("FOCUS_MARKER"):
			child.queue_free()
	
	# Reset state
	is_camera_focused = false

func focus_camera_on_player(player_id: String):
	if not world_manager:
		print("❌ No world_manager available")
		return
	
	# Always clean up any existing focus helpers first
	if world_manager:
		# Refresh spawn container reference if needed
		if not spawn_container:
			_refresh_spawn_container_reference()
		
		if spawn_container:
			# Remove all existing focus helpers
			cleanup_focus_helpers()
			print("🔄 Cleaned up previous focus helpers")
	
	if not world_manager.world_data:
		print("❌ No world data available")
		return
	
	var player_info = world_manager.world_data.get_player(player_id)
	if player_info.has("position") and not player_info.is_empty():
		var pos = player_info["position"]
		print("📍 Player ", player_id, " is at position ", pos)
		
		# Create a focus helper node that you can easily select in the editor
		if Engine.is_editor_hint() and world_manager:
			# Refresh spawn container reference if needed
			if not spawn_container:
				_refresh_spawn_container_reference()
			
			if spawn_container:
				# Remove any existing focus helper first
				var existing_helper = spawn_container.get_node_or_null("FOCUS_HERE")
				if existing_helper:
					existing_helper.queue_free()
				
				# Create a new focus helper node
				var focus_helper = Node2D.new()
				focus_helper.name = "FOCUS_HERE"
				focus_helper.position = pos
				
				# Add a visible sprite to make it easy to spot
				var sprite = Sprite2D.new()
				var texture = PlaceholderTexture2D.new()
				texture.size = Vector2(100, 100)
				sprite.texture = texture
				sprite.modulate = Color.YELLOW
				focus_helper.add_child(sprite)
				
				# Add a label with player info
				var label = Label.new()
				label.text = "FOCUS: " + player_id.substr(-8) + "\nAt: " + str(pos)
				label.position = Vector2(-50, -80)
				label.add_theme_color_override("font_color", Color.YELLOW)
				focus_helper.add_child(label)
				
				spawn_container.add_child(focus_helper)
				is_camera_focused = true
			
				print("🎯 Created FOCUS_HERE node at player position")
				print("📍 INSTRUCTIONS:")
				print("   1. Go to Scene tab")
				print("   2. Find 'FOCUS_HERE' under SpawnContainer")
				print("   3. Double-click it to center the editor view")
				print("   4. The yellow square shows the exact player location")
				print("💡 TIP: Click 'Focus Camera' again to remove focus")
			
		else:
			print("💡 Manually navigate to position ", pos, " in the editor viewport")
	else:
		print("❌ Player '", player_id, "' not found")
		print("💡 TIP: Player IDs must be complete and exact (e.g., 'player_997013ce-1619-421e-b83d-b98557443a42')")
		print("🔍 Use 'Search Players' with partial ID like '997' to find the complete ID first")
		
		# Try to find similar players
		if world_manager.world_data:
			var all_players = world_manager.world_data.get_all_players()
			var similar_players = []
			for existing_id in all_players.keys():
				if existing_id.contains(player_id) or player_id.contains(existing_id.substr(0, 20)):
					similar_players.append(existing_id)
			
			if similar_players.size() > 0:
				print("🔍 Did you mean one of these?")
				for similar_id in similar_players:
					print("   • ", similar_id)
			else:
				print("🔍 No similar player IDs found")

# Clean up any leftover focus markers from previous versions
func cleanup_old_focus_markers():
	if not world_manager:
		return
	
	# Refresh spawn container reference if needed
	if not spawn_container:
		_refresh_spawn_container_reference()
	
	if not spawn_container:
		return
	
	var cleanup_count = 0
	# Look for various possible marker names from different versions
	var marker_names = ["FOCUS_HERE", "VISUAL_MARK", "VISUAL_MARK_0", "VISUAL_MARK_1", "VISUAL_MARK_2"]
	
	for marker_name in marker_names:
		var marker = spawn_container.get_node_or_null(marker_name)
		if marker:
			marker.queue_free()
			cleanup_count += 1
	
	# Also check for any nodes that start with marker prefixes
	for child in spawn_container.get_children():
		if child.name.begins_with("FocusMarker_") or child.name.begins_with("VISUAL_MARK"):
			child.queue_free()
			cleanup_count += 1
	
	if cleanup_count > 0:
		print("🧹 Cleaned up ", cleanup_count, " old focus markers")
		is_camera_focused = false

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
		
		# Limit to recent players (either when show_recent_players_only is true, or when max_recent_players is set to a low number)
		var should_limit = show_recent_players_only or max_recent_players < 50  # Auto-enable limiting for small numbers
		if should_limit and filtered_players.size() >= max_recent_players:
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
