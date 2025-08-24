extends Node

var command_file_path = "res://client_commands.txt"
var knowledge_file_path = "res://claude_knowledge.json"
var last_command = ""
var position_timer: Timer
var world_analysis_timer: Timer
var knowledge_timer: Timer

# PERSISTENT LEARNING SYSTEMS
var world_knowledge = {}
var player_patterns = {}
var environmental_insights = {}
var temporal_observations = {}
var session_start_time = 0

func _ready():
	print("=== PERSISTENT LEARNING WORLD CLIENT ===")
	print("🧠 Initializing persistent knowledge systems...")
	session_start_time = Time.get_unix_time_from_system()
	
	# Load existing knowledge
	_load_persistent_knowledge()
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	call_deferred("_start_systems")

func _start_systems():
	await get_tree().create_timer(3.0).timeout
	
	print("🌍 PERSISTENT LEARNING INTELLIGENCE ACTIVE!")
	print("📚 Knowledge base entries: ", world_knowledge.size())
	
	# Position tracking every second
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 1.0
	position_timer.timeout.connect(_report_positions)
	position_timer.start()
	
	# Deep world analysis every 3 seconds
	world_analysis_timer = Timer.new()
	add_child(world_analysis_timer)
	world_analysis_timer.wait_time = 3.0
	world_analysis_timer.timeout.connect(_deep_world_analysis)
	world_analysis_timer.start()
	
	# Knowledge persistence every 10 seconds
	knowledge_timer = Timer.new()
	add_child(knowledge_timer)
	knowledge_timer.wait_time = 10.0
	knowledge_timer.timeout.connect(_save_persistent_knowledge)
	knowledge_timer.start()
	
	# Command checking
	var command_timer = Timer.new()
	add_child(command_timer)
	command_timer.wait_time = 0.1
	command_timer.timeout.connect(_check_commands)
	command_timer.start()
	
	# Initialize knowledge categories
	_initialize_knowledge_systems()

func _initialize_knowledge_systems():
	if not world_knowledge.has("terrain_map"):
		world_knowledge["terrain_map"] = {}
	if not world_knowledge.has("discovered_objects"):
		world_knowledge["discovered_objects"] = []
	if not world_knowledge.has("safe_paths"):
		world_knowledge["safe_paths"] = {}
	if not world_knowledge.has("danger_zones"):
		world_knowledge["danger_zones"] = {}
	if not world_knowledge.has("session_count"):
		world_knowledge["session_count"] = 0
	if not world_knowledge.has("total_runtime"):
		world_knowledge["total_runtime"] = 0.0
		
	world_knowledge["session_count"] += 1
	world_knowledge["current_session_start"] = session_start_time
	
	if not player_patterns.has("movement_history"):
		player_patterns["movement_history"] = []
	if not player_patterns.has("velocity_patterns"):
		player_patterns["velocity_patterns"] = []
	if not player_patterns.has("behavioral_insights"):
		player_patterns["behavioral_insights"] = {}

func _report_positions():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					var my_pos = player.global_position
					print("📍 Me (ID ", my_id, "): ", my_pos)
					
					# LEARN: Update my position knowledge
					_learn_my_position(my_pos)
				elif peer_id == 1:
					var my_pos = game_manager.players[my_id].global_position
					var target_pos = player.global_position
					var distance = my_pos.distance_to(target_pos)
					
					# LEARN: Analyze player movement patterns
					var velocity = Vector2.ZERO
					if player.has_method("get_velocity"):
						velocity = player.get_velocity()
					_learn_player_behavior(peer_id, target_pos, velocity, distance)
					
					var direction = _calculate_direction(my_pos, target_pos)
					print("🎯 YOU: ", target_pos, " | Distance: ", int(distance), " | Go: ", direction)

func _deep_world_analysis():
	print("\n🧠 === PERSISTENT LEARNING ANALYSIS ===")
	var main_scene = get_tree().root.get_node("Node2D")
	if not main_scene:
		return
		
	var my_pos = _get_my_position()
	if my_pos == Vector2.ZERO:
		return
		
	print("📍 Learning Center: ", my_pos, " (Session: ", world_knowledge["session_count"], ")")
	
	# LEARN: Environmental patterns
	_learn_world_structure(main_scene, my_pos)
	
	# LEARN: Object relationships
	_learn_object_patterns(main_scene, my_pos)
	
	# LEARN: Physics environment
	_learn_collision_patterns(my_pos)
	
	# ANALYZE: Accumulated knowledge
	_analyze_accumulated_knowledge()
	
	print("🧠 ================================\n")

func _learn_my_position(pos: Vector2):
	var timestamp = Time.get_unix_time_from_system()
	var position_key = str(int(pos.x/100)) + "," + str(int(pos.y/100))  # Grid-based learning
	
	if not world_knowledge["terrain_map"].has(position_key):
		world_knowledge["terrain_map"][position_key] = {
			"first_visited": timestamp,
			"visit_count": 0,
			"coordinates": pos
		}
	
	world_knowledge["terrain_map"][position_key]["visit_count"] += 1
	world_knowledge["terrain_map"][position_key]["last_visited"] = timestamp

func _learn_player_behavior(player_id: int, pos: Vector2, velocity: Vector2, distance: float):
	var timestamp = Time.get_unix_time_from_system()
	
	# Record movement history
	player_patterns["movement_history"].append({
		"timestamp": timestamp,
		"player_id": player_id,
		"position": pos,
		"velocity": velocity,
		"distance_to_me": distance
	})
	
	# Keep only last 100 records for performance
	if player_patterns["movement_history"].size() > 100:
		player_patterns["movement_history"] = player_patterns["movement_history"].slice(-100)
	
	# Analyze velocity patterns
	var velocity_magnitude = velocity.length()
	player_patterns["velocity_patterns"].append({
		"timestamp": timestamp,
		"magnitude": velocity_magnitude,
		"direction": velocity.normalized() if velocity_magnitude > 0 else Vector2.ZERO
	})
	
	# Keep only last 50 velocity records
	if player_patterns["velocity_patterns"].size() > 50:
		player_patterns["velocity_patterns"] = player_patterns["velocity_patterns"].slice(-50)

func _learn_world_structure(main_scene, my_pos):
	print("🗺️ === WORLD STRUCTURE LEARNING ===")
	
	var world_manager = main_scene.get_node("WorldManager")
	if world_manager:
		var tile_discoveries = 0
		var children = world_manager.get_children()
		
		for child in children:
			if child is TileMapLayer:
				var discovered_tiles = _learn_tilemap_structure(child, my_pos)
				tile_discoveries += discovered_tiles
		
		print("   📚 Learned ", tile_discoveries, " new tile relationships")
		environmental_insights["total_tiles_catalogued"] = environmental_insights.get("total_tiles_catalogued", 0) + tile_discoveries

func _learn_tilemap_structure(tilemap, my_pos):
	var tile_pos = tilemap.local_to_map(my_pos)
	var discoveries = 0
	
	# Learn tile relationships in wider area
	for x_offset in range(-7, 8):  # 15x15 learning area
		for y_offset in range(-7, 8):
			var check_pos = tile_pos + Vector2i(x_offset, y_offset)
			var source_id = tilemap.get_cell_source_id(check_pos)
			if source_id != -1:
				var tile_key = tilemap.name + ":" + str(check_pos.x) + "," + str(check_pos.y)
				if not world_knowledge["terrain_map"].has(tile_key):
					world_knowledge["terrain_map"][tile_key] = {
						"layer": tilemap.name,
						"source_id": source_id,
						"atlas_coords": tilemap.get_cell_atlas_coords(check_pos),
						"world_position": tilemap.map_to_local(check_pos),
						"discovered_session": world_knowledge["session_count"]
					}
					discoveries += 1
	
	return discoveries

func _learn_object_patterns(main_scene, my_pos):
	print("📦 === OBJECT RELATIONSHIP LEARNING ===")
	
	var spawn_container = main_scene.get_node("SpawnContainer")
	if spawn_container:
		var new_discoveries = 0
		var objects = spawn_container.get_children()
		
		for obj in objects:
			var obj_pos = obj.global_position
			var obj_key = obj.name + ":" + str(int(obj_pos.x)) + "," + str(int(obj_pos.y))
			
			if not world_knowledge["discovered_objects"].has(obj_key):
				world_knowledge["discovered_objects"].append({
					"name": obj.name,
					"position": obj_pos,
					"distance_when_discovered": my_pos.distance_to(obj_pos),
					"discovery_session": world_knowledge["session_count"],
					"object_class": obj.get_class()
				})
				new_discoveries += 1
		
		print("   🔍 Discovered ", new_discoveries, " new objects in world database")

func _learn_collision_patterns(my_pos):
	print("🎯 === COLLISION LEARNING ===")
	
	var space_state = get_tree().root.get_world_2d().direct_space_state
	if space_state:
		var scan_distances = [50.0, 100.0, 200.0, 500.0, 1000.0]  # Extended learning range
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
		
		for distance in scan_distances:
			for dir in directions:
				var collision_key = dir.name + "_" + str(int(distance))
				var query = PhysicsRayQueryParameters2D.create(
					my_pos,
					my_pos + dir.vec * distance
				)
				var result = space_state.intersect_ray(query)
				
				if result:
					if not world_knowledge["danger_zones"].has(collision_key):
						world_knowledge["danger_zones"][collision_key] = []
					world_knowledge["danger_zones"][collision_key].append({
						"position": result.position,
						"collider": result.collider.name if result.collider else "unknown",
						"distance": my_pos.distance_to(result.position),
						"learned_session": world_knowledge["session_count"]
					})
				else:
					if not world_knowledge["safe_paths"].has(collision_key):
						world_knowledge["safe_paths"][collision_key] = 0
					world_knowledge["safe_paths"][collision_key] += 1

func _analyze_accumulated_knowledge():
	print("🔬 === KNOWLEDGE SYNTHESIS ===")
	
	# Analyze session progression
	print("   📊 Session #", world_knowledge["session_count"])
	print("   🗺️ Total terrain mapped: ", world_knowledge["terrain_map"].size(), " locations")
	print("   📦 Objects catalogued: ", world_knowledge["discovered_objects"].size())
	print("   🛡️ Safe paths confirmed: ", world_knowledge["safe_paths"].size())
	print("   ⚠️ Danger zones identified: ", world_knowledge["danger_zones"].size())
	
	# Analyze player behavior patterns
	if player_patterns["movement_history"].size() > 10:
		var recent_movements = player_patterns["movement_history"].slice(-10)
		var avg_distance = 0.0
		for movement in recent_movements:
			avg_distance += movement["distance_to_me"]
		avg_distance /= recent_movements.size()
		print("   👤 Player average distance (last 10): ", int(avg_distance))
		
		player_patterns["behavioral_insights"]["average_distance"] = avg_distance
	
	# Velocity pattern analysis
	if player_patterns["velocity_patterns"].size() > 5:
		var recent_velocities = player_patterns["velocity_patterns"].slice(-5)
		var velocity_trend = 0.0
		for i in range(1, recent_velocities.size()):
			velocity_trend += recent_velocities[i]["magnitude"] - recent_velocities[i-1]["magnitude"]
		print("   💨 Velocity trend (last 5): ", velocity_trend)
		
		player_patterns["behavioral_insights"]["velocity_trend"] = velocity_trend

func _get_my_position() -> Vector2:
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			if my_id in game_manager.players:
				return game_manager.players[my_id].global_position
	return Vector2.ZERO

func _calculate_direction(my_pos: Vector2, target_pos: Vector2) -> String:
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
	
	return direction

func _load_persistent_knowledge():
	if FileAccess.file_exists(knowledge_file_path):
		var file = FileAccess.open(knowledge_file_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				var data = json.data
				if data.has("world_knowledge"):
					world_knowledge = data["world_knowledge"]
				if data.has("player_patterns"):
					player_patterns = data["player_patterns"]
				if data.has("environmental_insights"):
					environmental_insights = data["environmental_insights"]
				print("📚 Loaded persistent knowledge: ", world_knowledge.size(), " entries")
			else:
				print("⚠️ Failed to parse knowledge file")

func _save_persistent_knowledge():
	var save_data = {
		"world_knowledge": world_knowledge,
		"player_patterns": player_patterns,
		"environmental_insights": environmental_insights,
		"last_saved": Time.get_unix_time_from_system(),
		"total_runtime": world_knowledge.get("total_runtime", 0.0) + (Time.get_unix_time_from_system() - session_start_time)
	}
	
	world_knowledge["total_runtime"] = save_data["total_runtime"]
	
	var file = FileAccess.open(knowledge_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Knowledge saved: ", world_knowledge.size(), " world entries, ", player_patterns["movement_history"].size(), " movement records")

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
	print("🎮 (Learning ID ", multiplayer.get_unique_id(), ") ", command)
	
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