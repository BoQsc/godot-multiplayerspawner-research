extends Node

# Interactive Demo Client - Shows Claude interacting with the world

class_name InteractiveDemoClient

var game_manager = null
var my_peer_id = 0
var demo_timer: Timer
var interaction_timer: Timer

# Demo sequence
var demo_phase = 0
var phase_time = 0.0
var demo_phases = [
	{"name": "exploring", "duration": 8.0, "description": "🗺️ Exploring the world"},
	{"name": "jumping", "duration": 3.0, "description": "🦘 Demonstrating jumps"},
	{"name": "dancing", "duration": 5.0, "description": "💃 Dancing for you!"},
	{"name": "chasing", "duration": 10.0, "description": "🏃 Chasing other players"},
	{"name": "tile_scanning", "duration": 6.0, "description": "🔍 Analyzing terrain"},
	{"name": "interaction", "duration": 8.0, "description": "🎯 Interactive behaviors"}
]

# Current action state
var current_movement = ""
var jump_cooldown = 0.0
var scan_counter = 0

func _ready():
	print("=== INTERACTIVE DEMO CLIENT ===")
	print("🎭 Claude will demonstrate world interaction")
	print("👁️ Watch the game window to see me in action!")
	
	_setup_scene()
	call_deferred("_initialize_demo")

func _setup_scene():
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	print("📋 Scene loaded - preparing demonstration...")

func _initialize_demo():
	await get_tree().create_timer(3.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ GameManager not found")
		return
	
	my_peer_id = multiplayer.get_unique_id()
	print("🆔 Claude ready - Peer ID: ", my_peer_id)
	print("🎬 Starting interactive demonstration...")
	
	_start_demo_sequence()
	_start_interaction_system()

func _start_demo_sequence():
	demo_timer = Timer.new()
	add_child(demo_timer)
	demo_timer.wait_time = 0.5
	demo_timer.timeout.connect(_update_demo)
	demo_timer.start()
	print("🎭 Demo sequence initiated")

func _start_interaction_system():
	interaction_timer = Timer.new()
	add_child(interaction_timer)
	interaction_timer.wait_time = 0.1
	interaction_timer.timeout.connect(_process_interactions)
	interaction_timer.start()
	print("⚡ Real-time interaction system active")

func _update_demo():
	if demo_phase >= demo_phases.size():
		demo_phase = 0  # Loop the demo
	
	var current_phase = demo_phases[demo_phase]
	phase_time += 0.5
	
	if phase_time >= current_phase.duration:
		# Move to next phase
		demo_phase = (demo_phase + 1) % demo_phases.size()
		phase_time = 0.0
		var next_phase = demo_phases[demo_phase]
		print("🎬 Phase change: ", next_phase.description)
	
	# Report current status
	_report_status()

func _process_interactions():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	# Reduce jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= 0.1
	
	var current_phase = demo_phases[demo_phase]
	
	match current_phase.name:
		"exploring":
			_demo_explore()
		"jumping":
			_demo_jumping()
		"dancing":
			_demo_dancing()
		"chasing":
			_demo_chasing()
		"tile_scanning":
			_demo_tile_scanning()
		"interaction":
			_demo_interaction()

func _demo_explore():
	# Random exploration with direction changes
	var actions = ["right", "left", "stop", "jump"]
	var random_action = actions[randi() % actions.size()]
	
	if randf() < 0.1:  # 10% chance to change action
		_execute_movement(random_action)
		if random_action != "stop":
			print("🚶 Exploring: ", random_action)

func _demo_jumping():
	# Show off jumping abilities
	if jump_cooldown <= 0 and randf() < 0.3:
		_execute_movement("jump")
		print("🦘 Demonstration jump!")
	else:
		# Move while jumping
		var move = "right" if randf() < 0.5 else "left"
		_execute_movement(move)

func _demo_dancing():
	# Rhythmic dance pattern
	var dance_beat = int(phase_time * 2) % 4
	
	match dance_beat:
		0:
			_execute_movement("right")
			print("💃 Dance right!")
		1:
			_execute_movement("stop")
		2:
			_execute_movement("left")
			print("💃 Dance left!")
		3:
			_execute_movement("stop")
			if randf() < 0.2 and jump_cooldown <= 0:
				_execute_movement("jump")
				print("💃 Dance jump!")

func _demo_chasing():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var target_player = _find_nearest_player(my_pos)
	
	if target_player:
		var target_pos = target_player.position
		var distance = my_pos.distance_to(target_pos)
		
		print("🎯 Chasing Player_", target_player.id, " at distance ", int(distance))
		
		# Chase behavior
		if target_pos.x > my_pos.x + 50:
			_execute_movement("right")
			print("🏃 Chasing right!")
		elif target_pos.x < my_pos.x - 50:
			_execute_movement("left")
			print("🏃 Chasing left!")
		else:
			_execute_movement("stop")
		
		# Jump toward elevated targets
		if target_pos.y < my_pos.y - 60 and abs(target_pos.x - my_pos.x) < 100:
			if jump_cooldown <= 0:
				_execute_movement("jump")
				print("🦘 Jump chase!")
	else:
		# No target, explore
		_demo_explore()

func _demo_tile_scanning():
	scan_counter += 1
	
	if scan_counter % 10 == 0:  # Every second
		_analyze_surrounding_tiles()
		print("🔍 Terrain analysis complete")
	
	# Move slowly while scanning
	if scan_counter % 20 == 0:
		var move = "right" if (scan_counter / 20) % 2 == 0 else "left"
		_execute_movement(move)
		print("🚶 Scanning while moving: ", move)

func _demo_interaction():
	# Complex interactive behavior
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var nearby_objects = _scan_for_objects(my_pos)
	
	if nearby_objects.size() > 0:
		print("👁️ Found ", nearby_objects.size(), " objects nearby!")
		for obj in nearby_objects:
			print("   - ", obj.name, " at distance ", int(obj.distance))
		
		# Move toward interesting objects
		var closest = nearby_objects[0]
		if closest.position.x > my_pos.x:
			_execute_movement("right")
			print("➡️ Moving toward ", closest.name)
		else:
			_execute_movement("left")
			print("⬅️ Moving toward ", closest.name)
	else:
		# Interactive exploration
		if randf() < 0.2:
			var action = "jump" if randf() < 0.3 else ("right" if randf() < 0.5 else "left")
			_execute_movement(action)
			print("🎮 Interactive: ", action)

func _execute_movement(action: String):
	# Stop all movement first
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	match action:
		"right":
			Input.action_press("ui_right")
			current_movement = "right"
		"left":
			Input.action_press("ui_left")
			current_movement = "left"
		"jump":
			if jump_cooldown <= 0:
				Input.action_press("ui_accept")
				await get_tree().process_frame
				Input.action_release("ui_accept")
				jump_cooldown = 1.0
		"stop":
			current_movement = "stopped"

func _find_nearest_player(my_pos: Vector2):
	var nearest = null
	var min_distance = INF
	
	for peer_id in game_manager.players:
		if peer_id == my_peer_id:
			continue
		
		var player = game_manager.players[peer_id]
		var distance = my_pos.distance_to(player.global_position)
		
		if distance < min_distance:
			min_distance = distance
			nearest = {"id": peer_id, "position": player.global_position, "distance": distance}
	
	return nearest

func _scan_for_objects(my_pos: Vector2) -> Array:
	var objects = []
	
	# Scan SpawnContainer for objects
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var spawn_container = main_scene.get_node("SpawnContainer")
		if spawn_container:
			for child in spawn_container.get_children():
				var distance = my_pos.distance_to(child.global_position)
				if distance < 200 and child.name != str(my_peer_id):
					objects.append({
						"name": child.name,
						"position": child.global_position,
						"distance": distance
					})
	
	return objects

func _analyze_surrounding_tiles():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var main_scene = get_tree().root.get_node("Node2D")
	if not main_scene:
		return
	
	var world_manager = main_scene.get_node("WorldManager")
	if not world_manager:
		return
	
	var total_tiles = 0
	for child in world_manager.get_children():
		if child is TileMapLayer:
			var tiles_found = _scan_tilemap_layer(child, my_pos)
			total_tiles += tiles_found
			if tiles_found > 0:
				print("🔲 ", child.name, ": ", tiles_found, " tiles")
	
	if total_tiles > 0:
		print("🗺️ Total terrain tiles: ", total_tiles)

func _scan_tilemap_layer(tilemap: TileMapLayer, my_pos: Vector2) -> int:
	var tile_pos = tilemap.local_to_map(my_pos)
	var tiles_found = 0
	
	# Quick 3x3 scan for demo
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var check_pos = tile_pos + Vector2i(x_offset, y_offset)
			var source_id = tilemap.get_cell_source_id(check_pos)
			if source_id != -1:
				tiles_found += 1
	
	return tiles_found

func _report_status():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var current_phase = demo_phases[demo_phase]
	var phase_progress = int((phase_time / current_phase.duration) * 100)
	
	print("📊 Claude Status: ", current_phase.description, " (", phase_progress, "% complete)")
	print("📍 Position: (", int(my_pos.x), ", ", int(my_pos.y), ") | Movement: ", current_movement)
	
	# Count other players
	var player_count = game_manager.players.size() - 1
	if player_count > 0:
		print("👥 Other players in world: ", player_count)

func _exit_tree():
	print("🎭 Interactive demo client shutting down...")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")
	
	if demo_timer:
		demo_timer.queue_free()
	if interaction_timer:
		interaction_timer.queue_free()