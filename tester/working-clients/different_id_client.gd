extends Node

# Test client with different ID for multiplayer testing

var command_file_path = "res://client_commands.txt"
var last_command = ""
var position_timer: Timer

func _ready():
	print("=== DIFFERENT ID CLIENT ===" + str(randi() % 999999))
	print("Testing with alternative client ID")
	
	# This client will get an auto-assigned unique ID from the multiplayer system
	print("My unique ID will be assigned automatically")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	call_deferred("_start_systems")

func _start_systems():
	# Wait for connection
	await get_tree().create_timer(3.0).timeout
	
	print("🆔 Different ID Client Ready! Commands: right, left, jump, stop")
	print("📡 Real-time position tracking active")
	
	# Start position tracking
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 1.0  # Every second
	position_timer.timeout.connect(_report_positions)
	position_timer.start()
	
	# Start command checking
	var command_timer = Timer.new()
	add_child(command_timer)
	command_timer.wait_time = 0.1
	command_timer.timeout.connect(_check_commands)
	command_timer.start()

func _report_positions():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		var world_manager = main_scene.get_node("WorldManager")
		
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					var my_pos = player.global_position
					print("📍 Me (ID ", my_id, "): ", my_pos)
					_analyze_world_around_me(main_scene, my_pos)
				elif peer_id == 1:
					var my_pos = game_manager.players[my_id].global_position
					var target_pos = player.global_position
					var distance = my_pos.distance_to(target_pos)
					var direction = ""
					
					if target_pos.x > my_pos.x + 50:
						direction += "RIGHT "
					elif target_pos.x < my_pos.x - 50:
						direction += "LEFT "
					
					if target_pos.y < my_pos.y - 50:
						direction += "UP "
					elif target_pos.y > my_pos.y + 50:
						direction += "DOWN "
					
					if direction == "":
						direction = "VERY CLOSE! "
					
					print("🎯 YOU: ", target_pos, " | Distance: ", int(distance), " | Go: ", direction)

func _analyze_world_around_me(main_scene, my_pos):
	print("🌍 === WORLD AWARENESS ANALYSIS ===")
	
	# Analyze WorldManager and terrain
	var world_manager = main_scene.get_node("WorldManager")
	if world_manager:
		print("🗺️ WorldManager found!")
		
		# Try to access tilemap data
		var children = world_manager.get_children()
		for child in children:
			print("   - WorldManager child: ", child.name, " (", child.get_class(), ")")
			if child is TileMapLayer:
				_analyze_tilemap(child, my_pos)
	
	# Analyze all objects in SpawnContainer
	var spawn_container = main_scene.get_node("SpawnContainer")
	if spawn_container:
		print("📦 SpawnContainer analysis:")
		var objects = spawn_container.get_children()
		print("   - Total objects in world: ", objects.size())
		for obj in objects:
			var obj_pos = obj.global_position
			var distance_to_obj = my_pos.distance_to(obj_pos)
			if distance_to_obj < 500:  # Only report nearby objects
				print("   - ", obj.name, " at ", obj_pos, " (distance: ", int(distance_to_obj), ")")
	
	# Analyze immediate surroundings (collision detection)
	print("🎯 Immediate surroundings scan:")
	var space_state = get_tree().root.get_world_2d().direct_space_state
	if space_state:
		_scan_cardinal_directions(space_state, my_pos)
	
	print("🌍 ========================")

func _analyze_tilemap(tilemap, my_pos):
	print("🔲 TileMap analysis:")
	print("   - TileMap: ", tilemap.name)
	
	# Convert world position to tile coordinates
	var tile_pos = tilemap.local_to_map(my_pos)
	print("   - My tile position: ", tile_pos)
	
	# Check tiles around me
	for x_offset in range(-3, 4):
		for y_offset in range(-3, 4):
			var check_pos = tile_pos + Vector2i(x_offset, y_offset)
			var source_id = tilemap.get_cell_source_id(check_pos)
			if source_id != -1:
				var atlas_coords = tilemap.get_cell_atlas_coords(check_pos)
				var world_pos = tilemap.map_to_local(check_pos)
				var distance_to_tile = my_pos.distance_to(world_pos)
				print("   - Tile at ", check_pos, " (world: ", world_pos, ") source:", source_id, " atlas:", atlas_coords, " dist:", int(distance_to_tile))

func _scan_cardinal_directions(space_state, my_pos):
	var scan_distance = 100.0
	var directions = [
		Vector2.RIGHT,
		Vector2.LEFT, 
		Vector2.UP,
		Vector2.DOWN,
		Vector2(1, 1).normalized(),   # Diagonal down-right
		Vector2(-1, 1).normalized(),  # Diagonal down-left
		Vector2(1, -1).normalized(),  # Diagonal up-right
		Vector2(-1, -1).normalized()  # Diagonal up-left
	]
	
	var direction_names = ["RIGHT", "LEFT", "UP", "DOWN", "DOWN-RIGHT", "DOWN-LEFT", "UP-RIGHT", "UP-LEFT"]
	
	for i in range(directions.size()):
		var query = PhysicsRayQueryParameters2D.create(
			my_pos, 
			my_pos + directions[i] * scan_distance
		)
		var result = space_state.intersect_ray(query)
		if result:
			var distance_to_obstacle = my_pos.distance_to(result.position)
			print("   - ", direction_names[i], ": BLOCKED at ", int(distance_to_obstacle), " units by ", result.collider.name if result.collider else "unknown")
		else:
			print("   - ", direction_names[i], ": CLEAR for ", int(scan_distance), " units")

func _check_commands():
	if FileAccess.file_exists(command_file_path):
		var file = FileAccess.open(command_file_path, FileAccess.READ)
		if file:
			var command = file.get_as_text().strip_edges()
			file.close()
			
			if command != last_command and command != "":
				last_command = command
				_execute_command(command)

func _execute_command(command: String):
	print("🎮 (ID ", multiplayer.get_unique_id(), ") ", command)
	
	match command.to_lower():
		"right":
			Input.action_release("ui_left")
			Input.action_press("ui_right")
		"left":
			Input.action_release("ui_right") 
			Input.action_press("ui_left")
		"jump":
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
		"stop":
			Input.action_release("ui_right")
			Input.action_release("ui_left")
		_:
			print("❌ Unknown: ", command)