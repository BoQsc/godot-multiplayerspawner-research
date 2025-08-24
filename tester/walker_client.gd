extends Node

# Lively Walker Client - Actively explores and interacts with the world

class_name WalkerClient

var game_manager = null
var my_peer_id = 0
var exploration_timer: Timer
var action_timer: Timer

# Movement state
var current_action = "exploring"
var movement_direction = 1  # 1 for right, -1 for left
var action_duration = 0.0
var time_in_current_action = 0.0

# World interaction
var last_position = Vector2.ZERO
var stuck_counter = 0
var jump_cooldown = 0.0

func _ready():
	print("=== LIVELY WALKER CLIENT ===")
	print("🚶 Preparing to walk around and explore the world!")
	
	_setup_scene()
	call_deferred("_initialize_walker")

func _setup_scene():
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)

func _initialize_walker():
	await get_tree().create_timer(3.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ GameManager not found")
		return
	
	my_peer_id = multiplayer.get_unique_id()
	print("🆔 Walker ready - Peer ID: ", my_peer_id)
	
	_start_exploration()
	_start_action_system()

func _start_exploration():
	"""Start continuous exploration with frequent updates"""
	exploration_timer = Timer.new()
	add_child(exploration_timer)
	exploration_timer.wait_time = 0.5  # Update every half second
	exploration_timer.timeout.connect(_update_exploration)
	exploration_timer.start()
	print("🗺️ Active exploration started")

func _start_action_system():
	"""Start dynamic action system"""
	action_timer = Timer.new()
	add_child(action_timer)
	action_timer.wait_time = 0.1  # Very responsive
	action_timer.timeout.connect(_process_actions)
	action_timer.start()
	print("⚡ Action system active")

func _update_exploration():
	"""Update exploration state and report position"""
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var current_pos = game_manager.players[my_peer_id].global_position
	
	# Check if stuck
	if last_position.distance_to(current_pos) < 5.0:
		stuck_counter += 1
		if stuck_counter > 4:  # Stuck for 2+ seconds
			print("🚫 Stuck detected! Changing strategy...")
			_handle_stuck_situation()
	else:
		stuck_counter = 0
	
	last_position = current_pos
	
	# Find interesting targets
	var targets = _scan_for_targets(current_pos)
	if targets.size() > 0:
		print("👁️ Found ", targets.size(), " targets nearby:")
		for target in targets:
			print("   - ", target.name, " at distance ", int(target.distance))
	
	# Report current state
	print("📍 Walker at (", int(current_pos.x), ", ", int(current_pos.y), ") - ", current_action)

func _scan_for_targets(my_pos: Vector2) -> Array:
	"""Scan for interesting targets around the player"""
	var targets = []
	
	# Scan for other players
	for peer_id in game_manager.players:
		if peer_id == my_peer_id:
			continue
		
		var player = game_manager.players[peer_id]
		var distance = my_pos.distance_to(player.global_position)
		
		if distance < 800:  # Within interaction range
			targets.append({
				"name": "Player_" + str(peer_id),
				"position": player.global_position,
				"distance": distance,
				"type": "player"
			})
	
	# Scan for objects in SpawnContainer
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var spawn_container = main_scene.get_node("SpawnContainer")
		if spawn_container:
			for child in spawn_container.get_children():
				var distance = my_pos.distance_to(child.global_position)
				if distance < 300 and child.name != str(my_peer_id):  # Nearby objects
					targets.append({
						"name": child.name,
						"position": child.global_position,
						"distance": distance,
						"type": "object"
					})
	
	return targets

func _process_actions():
	"""Process current actions and movement"""
	time_in_current_action += 0.1
	
	# Reduce jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= 0.1
	
	match current_action:
		"exploring":
			_action_explore()
		"chasing":
			_action_chase()
		"jumping":
			_action_jump()
		"dancing":
			_action_dance()

func _action_explore():
	"""Explore the world by walking around"""
	if time_in_current_action > action_duration:
		# Time to change action
		_choose_new_action()
		return
	
	# Continue current movement
	if movement_direction > 0:
		Input.action_release("ui_left")
		Input.action_press("ui_right")
	else:
		Input.action_release("ui_right")
		Input.action_press("ui_left")
	
	# Randomly jump while exploring
	if randf() < 0.05 and jump_cooldown <= 0:  # 5% chance per tick
		_perform_jump()

func _action_chase():
	"""Chase after the nearest player"""
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var targets = _scan_for_targets(my_pos)
	
	var nearest_player = null
	var min_distance = INF
	
	for target in targets:
		if target.type == "player" and target.distance < min_distance:
			min_distance = target.distance
			nearest_player = target
	
	if nearest_player:
		var target_pos = nearest_player.position
		
		# Stop all movement first
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		
		# Move toward target
		if target_pos.x > my_pos.x + 30:
			Input.action_press("ui_right")
			print("🏃 Chasing right toward ", nearest_player.name)
		elif target_pos.x < my_pos.x - 30:
			Input.action_press("ui_left")
			print("🏃 Chasing left toward ", nearest_player.name)
		
		# Jump toward elevated targets
		if target_pos.y < my_pos.y - 50 and abs(target_pos.x - my_pos.x) < 80 and jump_cooldown <= 0:
			_perform_jump()
			print("🦘 Jumping toward ", nearest_player.name)
	
	# Change action after chasing for a while
	if time_in_current_action > 5.0:
		_choose_new_action()

func _action_jump():
	"""Dedicated jumping action"""
	if time_in_current_action < 0.5:
		# Continue current movement while jumping
		if movement_direction > 0:
			Input.action_press("ui_right")
		else:
			Input.action_press("ui_left")
	else:
		_choose_new_action()

func _action_dance():
	"""Dance by alternating movements"""
	var dance_phase = int(time_in_current_action * 4) % 4
	
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	match dance_phase:
		0:
			Input.action_press("ui_right")
		1:
			pass  # Stand still
		2:
			Input.action_press("ui_left")
		3:
			pass  # Stand still
	
	# Occasional dance jumps
	if dance_phase == 1 and jump_cooldown <= 0 and randf() < 0.3:
		_perform_jump()
	
	if time_in_current_action > 3.0:
		print("💃 Dance complete!")
		_choose_new_action()

func _choose_new_action():
	"""Choose a new action based on current situation"""
	var actions = ["exploring", "chasing", "dancing"]
	
	# Check for nearby players to chase
	if not game_manager or not game_manager.players.has(my_peer_id):
		current_action = "exploring"
	else:
		var my_pos = game_manager.players[my_peer_id].global_position
		var targets = _scan_for_targets(my_pos)
		
		var has_nearby_players = false
		for target in targets:
			if target.type == "player" and target.distance < 400:
				has_nearby_players = true
				break
		
		if has_nearby_players and randf() < 0.6:  # 60% chance to chase
			current_action = "chasing"
		else:
			current_action = actions[randi() % actions.size()]
	
	# Set action duration
	match current_action:
		"exploring":
			action_duration = randf_range(3.0, 8.0)
			movement_direction = 1 if randf() < 0.5 else -1
		"chasing":
			action_duration = randf_range(4.0, 10.0)
		"dancing":
			action_duration = randf_range(2.0, 4.0)
		"jumping":
			action_duration = randf_range(1.0, 2.0)
	
	time_in_current_action = 0.0
	print("🎯 New action: ", current_action, " for ", action_duration, " seconds")

func _handle_stuck_situation():
	"""Handle being stuck by jumping and changing direction"""
	print("🔄 Handling stuck situation...")
	
	# Jump to get unstuck
	_perform_jump()
	
	# Change direction
	movement_direction *= -1
	
	# Force new action
	current_action = "jumping"
	action_duration = 1.0
	time_in_current_action = 0.0
	
	stuck_counter = 0

func _perform_jump():
	"""Perform a jump action"""
	if jump_cooldown > 0:
		return
	
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	jump_cooldown = 1.0  # 1 second cooldown
	print("🦘 JUMP!")

func _exit_tree():
	print("🛑 Walker client shutting down...")
	# Release all inputs
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")
	
	if exploration_timer:
		exploration_timer.queue_free()
	if action_timer:
		action_timer.queue_free()