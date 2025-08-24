extends Node

# Production-Ready Multiplayer Client
# Consolidates best practices from working client analysis

class_name ProductionClient

# Core systems
var game_manager = null
var my_peer_id = 0
var position_timer: Timer
var behavior_timer: Timer

# State management
var current_behavior = "idle"
var behaviors = ["idle", "exploring", "tracking", "following"]
var behavior_index = 0

# Configuration
var position_update_interval = 1.0
var behavior_change_interval = 10.0
var connection_wait_time = 3.0

func _ready():
	print("=== PRODUCTION CLIENT ===")
	print("🚀 Initializing production-ready multiplayer client...")
	
	# Load main scene with proper structure
	_setup_scene()
	
	# Initialize client systems
	call_deferred("_initialize_systems")

func _setup_scene():
	"""Load main scene with proper node hierarchy"""
	print("📋 Setting up scene structure...")
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	print("✅ Main scene loaded")

func _initialize_systems():
	"""Initialize all client systems after scene setup"""
	print("⏳ Waiting for connection...")
	await get_tree().create_timer(connection_wait_time).timeout
	
	# Get game manager reference
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ GameManager not found - client may not function properly")
		return
	
	my_peer_id = multiplayer.get_unique_id()
	print("🆔 Client initialized - Peer ID: ", my_peer_id)
	
	# Setup tracking systems
	_setup_position_tracking()
	_setup_behavior_system()
	
	print("✅ All systems online - Production client ready!")

func _setup_position_tracking():
	"""Setup real-time position and player tracking"""
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = position_update_interval
	position_timer.timeout.connect(_update_tracking)
	position_timer.start()
	print("📡 Position tracking enabled")

func _setup_behavior_system():
	"""Setup intelligent behavior system"""
	behavior_timer = Timer.new()
	add_child(behavior_timer)
	behavior_timer.wait_time = behavior_change_interval
	behavior_timer.timeout.connect(_cycle_behavior)
	behavior_timer.start()
	print("🤖 Behavior system enabled")

func _update_tracking():
	"""Update position tracking and world awareness"""
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
		
	var my_pos = game_manager.players[my_peer_id].global_position
	
	# Find and track other players
	var nearest_player = _find_nearest_player(my_pos)
	if nearest_player:
		var distance = my_pos.distance_to(nearest_player.position)
		var direction = _calculate_direction(my_pos, nearest_player.position)
		print("🎯 Player ", nearest_player.id, " at distance ", int(distance), " - ", direction)
		
		# Adjust behavior based on proximity
		if distance < 100:
			current_behavior = "following"
		elif distance > 1000:
			current_behavior = "exploring"

func _find_nearest_player(my_pos: Vector2):
	"""Find the nearest other player"""
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

func _calculate_direction(from: Vector2, to: Vector2) -> String:
	"""Calculate direction from one point to another"""
	var direction = ""
	var threshold = 50.0
	
	if to.x > from.x + threshold:
		direction += "RIGHT "
	elif to.x < from.x - threshold:
		direction += "LEFT "
		
	if to.y < from.y - threshold:
		direction += "UP "
	elif to.y > from.y + threshold:
		direction += "DOWN "
	
	return direction if direction != "" else "CLOSE"

func _cycle_behavior():
	"""Cycle through different behaviors"""
	behavior_index = (behavior_index + 1) % behaviors.size()
	current_behavior = behaviors[behavior_index]
	print("🔄 Behavior changed to: ", current_behavior)
	
	# Execute behavior
	match current_behavior:
		"idle":
			_behavior_idle()
		"exploring":
			_behavior_explore()
		"tracking":
			_behavior_track()
		"following":
			_behavior_follow()

func _behavior_idle():
	"""Stop all movement and wait"""
	print("💤 Behavior: Idle")
	Input.action_release("ui_left")
	Input.action_release("ui_right")

func _behavior_explore():
	"""Random exploration movement"""
	print("🗺️ Behavior: Exploring")
	
	# Random movement pattern
	var actions = ["ui_left", "ui_right", "ui_accept"]
	var random_action = actions[randi() % actions.size()]
	
	# Stop previous actions
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	if random_action != "ui_accept":
		Input.action_press(random_action)
		print("🚶 Moving: ", random_action)
	else:
		# Jump
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		print("🦘 Jumping")

func _behavior_track():
	"""Track nearest player without following"""
	print("👁️ Behavior: Tracking")
	
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
		
	var my_pos = game_manager.players[my_peer_id].global_position
	var nearest = _find_nearest_player(my_pos)
	
	if nearest:
		print("📍 Tracking player ", nearest.id, " at distance ", int(nearest.distance))

func _behavior_follow():
	"""Actively follow the nearest player"""
	print("🏃 Behavior: Following")
	
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
		
	var my_pos = game_manager.players[my_peer_id].global_position
	var nearest = _find_nearest_player(my_pos)
	
	if not nearest:
		return
		
	# Stop all movement first
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	# Move toward target
	var target_pos = nearest.position
	var threshold = 75.0
	
	if target_pos.x > my_pos.x + threshold:
		Input.action_press("ui_right")
		print("➡️ Following right")
	elif target_pos.x < my_pos.x - threshold:
		Input.action_press("ui_left")
		print("⬅️ Following left")
	
	# Jump if target is above and close
	if target_pos.y < my_pos.y - 50 and abs(target_pos.x - my_pos.x) < 100:
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		print("🦘 Following jump")

func get_status() -> Dictionary:
	"""Return current client status"""
	return {
		"peer_id": my_peer_id,
		"behavior": current_behavior,
		"connected": game_manager != null,
		"players_count": game_manager.players.size() if game_manager else 0
	}

func _exit_tree():
	"""Clean shutdown"""
	print("🛑 Production client shutting down...")
	if position_timer:
		position_timer.queue_free()
	if behavior_timer:
		behavior_timer.queue_free()