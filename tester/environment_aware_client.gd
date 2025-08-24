extends Node

# Environment Aware Client - True environmental awareness for navigation

class_name EnvironmentAwareClient

var game_manager = null
var my_peer_id = 0
var awareness_timer: Timer

# True environmental awareness
var last_position = Vector2.ZERO
var position_history = []
var stuck_threshold = 5.0  # pixels
var stuck_counter = 0
var max_stuck_time = 20  # 2 seconds at 0.1 interval

# Navigation intelligence
var target_player_id = 1
var current_strategy = "direct_approach"
var jump_cooldown = 0.0
var path_attempts = []
var blocked_directions = []

# World analysis
var world_scan_radius = 3  # tiles to scan around position
var obstacle_map = {}  # position -> obstacle_type
var safe_tiles = []
var last_world_scan_pos = Vector2.ZERO

func _ready():
	print("=== ENVIRONMENT AWARE CLIENT ===")
	print("🧠 Implementing true environmental awareness")
	print("🔍 Features: Obstacle detection, pathfinding, spatial memory")
	
	_setup_scene()
	call_deferred("_initialize_awareness")

func _setup_scene():
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)

func _initialize_awareness():
	await get_tree().create_timer(3.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ GameManager not found")
		return
	
	my_peer_id = multiplayer.get_unique_id()
	print("🆔 Environment Aware Client ready - Peer ID: ", my_peer_id)
	
	_start_environmental_awareness()

func _start_environmental_awareness():
	awareness_timer = Timer.new()
	add_child(awareness_timer)
	awareness_timer.wait_time = 0.1
	awareness_timer.timeout.connect(_process_environmental_awareness)
	awareness_timer.start()
	print("🧠 Environmental awareness system active")

func _process_environmental_awareness():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var current_pos = game_manager.players[my_peer_id].global_position
	
	# Update position tracking
	_update_position_tracking(current_pos)
	
	# Reduce jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= 0.1
	
	# Scan environment if we've moved significantly
	if last_world_scan_pos.distance_to(current_pos) > 64:  # Scan every tile moved
		_scan_surrounding_environment(current_pos)
		last_world_scan_pos = current_pos
	
	# Check for target
	if not game_manager.players.has(target_player_id):
		print("🔍 Scanning for target...")
		return
	
	var target_pos = game_manager.players[target_player_id].global_position
	var distance = current_pos.distance_to(target_pos)
	
	# Environmental status report
	print("🧠 ENV AWARE | Me: (", int(current_pos.x), ",", int(current_pos.y), ") | Target: (", int(target_pos.x), ",", int(target_pos.y), ") | Distance: ", int(distance))
	print("📊 Strategy: ", current_strategy, " | Stuck: ", stuck_counter, "/", max_stuck_time, " | Known obstacles: ", obstacle_map.size())
	
	# Navigate intelligently
	_navigate_to_target(current_pos, target_pos)

func _update_position_tracking(current_pos: Vector2):
	# Track position history
	position_history.append(current_pos)
	if position_history.size() > 10:
		position_history.pop_front()
	
	# Detect if stuck
	if last_position.distance_to(current_pos) < stuck_threshold:
		stuck_counter += 1
		if stuck_counter >= max_stuck_time:
			print("🚫 STUCK DETECTED! Analyzing obstacle...")
			_analyze_stuck_situation(current_pos)
	else:
		stuck_counter = 0
		_clear_stuck_state()
	
	last_position = current_pos

func _analyze_stuck_situation(current_pos: Vector2):
	print("🔍 OBSTACLE ANALYSIS:")
	
	# Record this position as problematic
	var grid_pos = Vector2i(int(current_pos.x / 64), int(current_pos.y / 64))
	obstacle_map[grid_pos] = "movement_blocked"
	
	# Analyze what direction we were trying to move
	var intended_direction = _get_last_movement_direction()
	if intended_direction != "":
		blocked_directions.append(intended_direction)
		print("🚧 Direction BLOCKED: ", intended_direction)
	
	# Try alternative strategy
	_switch_navigation_strategy()
	stuck_counter = 0

func _get_last_movement_direction() -> String:
	if Input.is_action_pressed("ui_right"):
		return "right"
	elif Input.is_action_pressed("ui_left"):
		return "left"
	return ""

func _switch_navigation_strategy():
	match current_strategy:
		"direct_approach":
			current_strategy = "jump_over_obstacle"
			print("🦘 STRATEGY: Switching to jump over obstacle")
		"jump_over_obstacle":
			current_strategy = "pathfind_around"
			print("🗺️ STRATEGY: Switching to pathfinding around obstacle")
		"pathfind_around":
			current_strategy = "retreat_and_reapproach"
			print("🔄 STRATEGY: Retreating and finding new approach")
		"retreat_and_reapproach":
			current_strategy = "direct_approach"
			blocked_directions.clear()
			print("🎯 STRATEGY: Resetting to direct approach")

func _navigate_to_target(my_pos: Vector2, target_pos: Vector2):
	var distance = my_pos.distance_to(target_pos)
	
	# Close range interaction - stop repetitive jumping when very close
	if distance < 80:
		_strategy_close_range_interaction(my_pos, target_pos)
		return
	
	match current_strategy:
		"direct_approach":
			_strategy_direct_approach(my_pos, target_pos)
		"jump_over_obstacle":
			_strategy_jump_over_obstacle(my_pos, target_pos)
		"pathfind_around":
			_strategy_pathfind_around(my_pos, target_pos)
		"retreat_and_reapproach":
			_strategy_retreat_and_reapproach(my_pos, target_pos)

func _strategy_direct_approach(my_pos: Vector2, target_pos: Vector2):
	print("🎯 DIRECT APPROACH")
	
	# Stop all movement
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	var horizontal_distance = target_pos.x - my_pos.x
	
	if abs(horizontal_distance) > 30:
		if horizontal_distance > 0 and "right" not in blocked_directions:
			Input.action_press("ui_right")
			print("➡️ Moving right toward target")
		elif horizontal_distance < 0 and "left" not in blocked_directions:
			Input.action_press("ui_left")
			print("⬅️ Moving left toward target")
		else:
			print("🚧 Direct path blocked, switching strategy")
			_switch_navigation_strategy()

func _strategy_jump_over_obstacle(my_pos: Vector2, target_pos: Vector2):
	print("🦘 JUMP OVER OBSTACLE")
	
	# Always move horizontally toward target
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	var horizontal_distance = target_pos.x - my_pos.x
	if abs(horizontal_distance) > 30:
		if horizontal_distance > 0:
			Input.action_press("ui_right")
			print("➡️ Moving right while jumping over obstacle")
		else:
			Input.action_press("ui_left")
			print("⬅️ Moving left while jumping over obstacle")
	
	# Jump when available
	if jump_cooldown <= 0:
		_perform_jump("Jumping over detected obstacle!")
	else:
		print("⏳ Jump cooldown active, but still moving toward target...")

func _strategy_pathfind_around(my_pos: Vector2, target_pos: Vector2):
	print("🗺️ PATHFIND AROUND")
	
	# Try to find alternate route using safe tiles
	var safe_direction = _find_safe_direction(my_pos, target_pos)
	
	if safe_direction != "":
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		
		if safe_direction == "right":
			Input.action_press("ui_right")
			print("🔄 Pathfinding: Moving right around obstacle")
		elif safe_direction == "left":
			Input.action_press("ui_left")
			print("🔄 Pathfinding: Moving left around obstacle")
		elif safe_direction == "jump_right":
			if jump_cooldown <= 0:
				_perform_jump("Pathfinding jump right")
				Input.action_press("ui_right")
		elif safe_direction == "jump_left":
			if jump_cooldown <= 0:
				_perform_jump("Pathfinding jump left")
				Input.action_press("ui_left")
	else:
		print("🚧 No safe path found, trying retreat strategy")
		_switch_navigation_strategy()

func _strategy_retreat_and_reapproach(my_pos: Vector2, target_pos: Vector2):
	print("🔄 RETREAT AND REAPPROACH")
	
	# Move away from target briefly to find new angle
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	var horizontal_distance = target_pos.x - my_pos.x
	
	# Move opposite to target direction
	if horizontal_distance > 0:
		Input.action_press("ui_left")
		print("🔙 Retreating left to find new approach")
	else:
		Input.action_press("ui_right")
		print("🔙 Retreating right to find new approach")
	
	# Jump to get to different elevation
	if jump_cooldown <= 0 and randf() < 0.3:
		_perform_jump("Retreat jump to change elevation")

var celebration_timer = 0.0
var interaction_phase = "approaching"

func _strategy_close_range_interaction(my_pos: Vector2, target_pos: Vector2):
	var distance = my_pos.distance_to(target_pos)
	
	print("🎯 CLOSE RANGE INTERACTION | Distance: ", int(distance), " | Phase: ", interaction_phase)
	
	# Stop all movement first
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	# Different behaviors based on phase
	match interaction_phase:
		"approaching":
			if distance < 60:
				print("🎉 SUCCESS! I made it to your head!")
				interaction_phase = "celebrating"
				celebration_timer = 3.0
			else:
				# Fine movement toward target
				var horizontal_distance = target_pos.x - my_pos.x
				if abs(horizontal_distance) > 15:
					if horizontal_distance > 0:
						Input.action_press("ui_right")
						print("➡️ Fine positioning right")
					else:
						Input.action_press("ui_left")
						print("⬅️ Fine positioning left")
		
		"celebrating":
			celebration_timer -= 0.1
			if celebration_timer > 2.0:
				if jump_cooldown <= 0:
					_perform_jump("🦘 Victory jump on your head!")
			elif celebration_timer > 1.0:
				print("🎊 I'm on your head! Mission accomplished!")
			elif celebration_timer <= 0:
				interaction_phase = "playful"
				print("😄 Now let's be playful!")
		
		"playful":
			# Random playful behaviors
			var behavior = randi() % 4
			match behavior:
				0:
					if jump_cooldown <= 0 and randf() < 0.3:
						_perform_jump("🦘 Playful bounce!")
				1:
					print("👋 Hello there! I'm right here with you!")
				2:
					print("🎪 Look at me! I'm balancing on your head!")
				3:
					# Occasionally move slightly to stay close
					var horizontal_distance = target_pos.x - my_pos.x
					if abs(horizontal_distance) > 40:
						if horizontal_distance > 0:
							Input.action_press("ui_right")
							print("➡️ Following you")
						else:
							Input.action_press("ui_left")
							print("⬅️ Following you")

func _find_safe_direction(my_pos: Vector2, target_pos: Vector2) -> String:
	# Analyze safe directions based on known obstacles and safe tiles
	var directions = ["right", "left", "jump_right", "jump_left"]
	
	for direction in directions:
		if direction in blocked_directions:
			continue
			
		# Check if this direction has known safe tiles
		var test_pos = my_pos
		match direction:
			"right", "jump_right":
				test_pos.x += 64
			"left", "jump_left":
				test_pos.x -= 64
		
		var grid_pos = Vector2i(int(test_pos.x / 64), int(test_pos.y / 64))
		if not obstacle_map.has(grid_pos):
			return direction
	
	return ""

func _scan_surrounding_environment(my_pos: Vector2):
	var main_scene = get_tree().root.get_node("Node2D")
	if not main_scene:
		return
		
	var world_manager = main_scene.get_node("WorldManager")
	if not world_manager:
		return
	
	print("🔍 SCANNING ENVIRONMENT at (", int(my_pos.x), ", ", int(my_pos.y), ")")
	
	var tiles_scanned = 0
	safe_tiles.clear()
	
	for child in world_manager.get_children():
		if child is TileMapLayer:
			tiles_scanned += _scan_tilemap_for_obstacles(child, my_pos)
	
	print("🗺️ Environment scan complete: ", tiles_scanned, " tiles analyzed")

func _scan_tilemap_for_obstacles(tilemap: TileMapLayer, center_pos: Vector2) -> int:
	var tile_center = tilemap.local_to_map(center_pos)
	var tiles_found = 0
	
	# Scan larger area for better awareness
	for x_offset in range(-world_scan_radius, world_scan_radius + 1):
		for y_offset in range(-world_scan_radius, world_scan_radius + 1):
			var tile_pos = tile_center + Vector2i(x_offset, y_offset)
			var source_id = tilemap.get_cell_source_id(tile_pos)
			var world_pos = tilemap.map_to_local(tile_pos)
			var grid_pos = Vector2i(int(world_pos.x / 64), int(world_pos.y / 64))
			
			if source_id != -1:
				# Tile exists - potential obstacle
				obstacle_map[grid_pos] = "solid_tile"
				tiles_found += 1
				var distance = center_pos.distance_to(world_pos)
				print("🔲 OBSTACLE: Tile at (", int(world_pos.x), ", ", int(world_pos.y), ") - ", int(distance), " units")
			else:
				# Empty space - safe to move
				safe_tiles.append(world_pos)
				if grid_pos in obstacle_map:
					obstacle_map.erase(grid_pos)  # Clear outdated obstacle info
	
	return tiles_found

func _clear_stuck_state():
	if stuck_counter == 0 and current_strategy != "direct_approach":
		# We're moving again, gradually return to direct approach
		if blocked_directions.size() > 0:
			blocked_directions.pop_back()  # Gradually clear blocked directions
			print("✅ Movement restored, clearing blocked direction")

func _perform_jump(reason: String):
	if jump_cooldown > 0:
		return
	
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	jump_cooldown = 1.2
	print("🦘 JUMP! Reason: ", reason)

func get_environmental_status() -> Dictionary:
	return {
		"position": last_position,
		"stuck_counter": stuck_counter,
		"strategy": current_strategy,
		"known_obstacles": obstacle_map.size(),
		"safe_tiles": safe_tiles.size(),
		"blocked_directions": blocked_directions
	}

func _exit_tree():
	print("🧠 Environment Aware Client shutting down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")
	
	if awareness_timer:
		awareness_timer.queue_free()