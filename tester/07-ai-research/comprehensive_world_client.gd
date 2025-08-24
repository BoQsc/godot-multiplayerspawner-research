extends Node

var command_file_path = "res://client_commands.txt"
var last_command = ""
var position_timer: Timer
var world_analysis_timer: Timer

func _ready():
	print("=== COMPREHENSIVE WORLD AWARENESS CLIENT ===")
	print("Maximum world awareness analysis active!")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	call_deferred("_start_systems")

func _start_systems():
	await get_tree().create_timer(3.0).timeout
	
	print("🌍 COMPREHENSIVE WORLD AWARENESS ACTIVE!")
	print("📡 Commands: right, left, jump, stop")
	
	# Position tracking every second
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 1.0
	position_timer.timeout.connect(_report_positions)
	position_timer.start()
	
	# Dedicated world analysis every 2 seconds for thorough analysis
	world_analysis_timer = Timer.new()
	add_child(world_analysis_timer)
	world_analysis_timer.wait_time = 2.0
	world_analysis_timer.timeout.connect(_comprehensive_world_analysis)
	world_analysis_timer.start()
	
	# Command checking
	var command_timer = Timer.new()
	add_child(command_timer)
	command_timer.wait_time = 0.1
	command_timer.timeout.connect(_check_commands)
	command_timer.start()

func _report_positions():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					print("📍 Me (ID ", my_id, "): ", player.global_position)
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

func _comprehensive_world_analysis():
	print("\n🌍 === COMPREHENSIVE WORLD ANALYSIS ===")
	var main_scene = get_tree().root.get_node("Node2D")
	if not main_scene:
		print("❌ No main scene found!")
		return
	
	var game_manager = main_scene.get_node("GameManager")
	if not game_manager:
		print("❌ No GameManager found!")
		return
		
	var my_id = multiplayer.get_unique_id()
	if not my_id in game_manager.players:
		print("❌ My player not found in game!")
		return
		
	var my_pos = game_manager.players[my_id].global_position
	print("📍 Analysis Center: ", my_pos, " (ID: ", my_id, ")")
	
	# 1. WORLD MANAGER ANALYSIS
	_analyze_world_manager(main_scene, my_pos)
	
	# 2. SPAWN CONTAINER ANALYSIS  
	_analyze_spawn_container(main_scene, my_pos)
	
	# 3. COLLISION/PHYSICS ANALYSIS
	_analyze_physics_environment(my_pos)
	
	# 4. PLAYER ANALYSIS
	_analyze_other_players(game_manager, my_pos)
	
	print("🌍 ========================\n")

func _analyze_world_manager(main_scene, my_pos):
	print("🗺️ === WORLD MANAGER ANALYSIS ===")
	var world_manager = main_scene.get_node("WorldManager")
	if world_manager:
		print("✅ WorldManager found!")
		var children = world_manager.get_children()
		print("   - WorldManager has ", children.size(), " children")
		
		for child in children:
			print("   - Child: ", child.name, " (", child.get_class(), ")")
			if child is TileMapLayer:
				_analyze_tilemap_detailed(child, my_pos)
	else:
		print("❌ WorldManager not found!")

func _analyze_tilemap_detailed(tilemap, my_pos):
	print("🔲 === TILEMAP DETAILED ANALYSIS ===")
	print("   - TileMap: ", tilemap.name)
	
	var tile_pos = tilemap.local_to_map(my_pos)
	print("   - My tile coordinates: ", tile_pos)
	
	# Extended tile analysis - larger area
	var tiles_found = 0
	for x_offset in range(-5, 6):  # 11x11 area
		for y_offset in range(-5, 6):
			var check_pos = tile_pos + Vector2i(x_offset, y_offset)
			var source_id = tilemap.get_cell_source_id(check_pos)
			if source_id != -1:
				var atlas_coords = tilemap.get_cell_atlas_coords(check_pos)
				var world_pos = tilemap.map_to_local(check_pos)
				var distance = my_pos.distance_to(world_pos)
				tiles_found += 1
				print("     - Tile[", x_offset, ",", y_offset, "] at ", world_pos, " | source:", source_id, " | dist:", int(distance))
	
	print("   - Total tiles in 11x11 area: ", tiles_found)

func _analyze_spawn_container(main_scene, my_pos):
	print("📦 === SPAWN CONTAINER ANALYSIS ===")
	var spawn_container = main_scene.get_node("SpawnContainer")
	if spawn_container:
		var objects = spawn_container.get_children()
		print("✅ SpawnContainer found with ", objects.size(), " objects")
		
		# Categorize objects
		var players = []
		var npcs = []
		var items = []
		var others = []
		
		for obj in objects:
			var obj_pos = obj.global_position
			var distance = my_pos.distance_to(obj_pos)
			
			if "Player" in obj.name:
				players.append({"obj": obj, "pos": obj_pos, "dist": distance})
			elif "NPC" in obj.name:
				npcs.append({"obj": obj, "pos": obj_pos, "dist": distance})
			elif "Item" in obj.name or "Pickup" in obj.name:
				items.append({"obj": obj, "pos": obj_pos, "dist": distance})
			else:
				others.append({"obj": obj, "pos": obj_pos, "dist": distance})
		
		print("   📊 Object Categories:")
		print("     - Players: ", players.size())
		print("     - NPCs: ", npcs.size()) 
		print("     - Items: ", items.size())
		print("     - Others: ", others.size())
		
		# Show nearby objects (within 1000 units)
		print("   🔍 Nearby Objects (< 1000 units):")
		for category in [players, npcs, items, others]:
			for entry in category:
				if entry.dist < 1000:
					print("     - ", entry.obj.name, " at ", entry.pos, " (", int(entry.dist), " units)")
	else:
		print("❌ SpawnContainer not found!")

func _analyze_physics_environment(my_pos):
	print("🎯 === PHYSICS ENVIRONMENT SCAN ===")
	var space_state = get_tree().root.get_world_2d().direct_space_state
	if space_state:
		var directions = [
			{"name": "RIGHT", "vec": Vector2.RIGHT},
			{"name": "LEFT", "vec": Vector2.LEFT},
			{"name": "UP", "vec": Vector2.UP},
			{"name": "DOWN", "vec": Vector2.DOWN},
			{"name": "UP-RIGHT", "vec": Vector2(1, -1).normalized()},
			{"name": "UP-LEFT", "vec": Vector2(-1, -1).normalized()},
			{"name": "DOWN-RIGHT", "vec": Vector2(1, 1).normalized()},
			{"name": "DOWN-LEFT", "vec": Vector2(-1, 1).normalized()}
		]
		
		# Multiple distance scans
		var scan_distances = [50.0, 100.0, 200.0, 500.0]
		
		for distance in scan_distances:
			print("   🔍 Scan at ", int(distance), " units:")
			for dir in directions:
				var query = PhysicsRayQueryParameters2D.create(
					my_pos,
					my_pos + dir.vec * distance
				)
				var result = space_state.intersect_ray(query)
				if result:
					var hit_distance = my_pos.distance_to(result.position)
					print("     - ", dir.name, ": HIT at ", int(hit_distance), " | ", result.collider.name if result.collider else "unknown")
				else:
					print("     - ", dir.name, ": CLEAR")
	else:
		print("❌ No physics space available!")

func _analyze_other_players(game_manager, my_pos):
	print("👥 === PLAYER ANALYSIS ===")
	var my_id = multiplayer.get_unique_id()
	
	for peer_id in game_manager.players:
		var player = game_manager.players[peer_id]
		if peer_id != my_id:
			var distance = my_pos.distance_to(player.global_position)
			var velocity = Vector2.ZERO
			if player.has_method("get_velocity"):
				velocity = player.get_velocity()
			
			print("   👤 Player ID ", peer_id, ":")
			print("     - Position: ", player.global_position)
			print("     - Distance: ", int(distance))
			print("     - Velocity: ", velocity)
			
			# Predict future position
			if velocity.length() > 0:
				var predicted_pos = player.global_position + velocity * 2.0  # 2 seconds ahead
				print("     - Predicted (2s): ", predicted_pos)

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