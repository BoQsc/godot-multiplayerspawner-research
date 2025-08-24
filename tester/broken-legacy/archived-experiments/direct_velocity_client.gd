extends Node

# Test client that directly manipulates velocity in the physics process

var target_player = null

func _ready():
	print("=== DIRECT VELOCITY CLIENT ===")
	print("This client directly modifies velocity during physics processing")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_velocity_control")

func _start_velocity_control():
	await get_tree().create_timer(8.0).timeout
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found")
		return
	
	target_player = players[my_peer_id]
	print("✅ Found target player: " + str(my_peer_id))
	print("📍 Starting position: " + str(target_player.position))
	print("🔧 Overriding physics process...")
	
	# Override the player's physics process
	_override_player_physics()

func _override_player_physics():
	"""Override the player's input handling"""
	if not target_player:
		return
	
	print("🎮 Starting direct velocity control demo...")
	
	# Create a custom physics override
	target_player._custom_physics_process = _custom_movement_override
	
	# Start movement sequence
	_start_movement_sequence()

func _start_movement_sequence():
	"""Execute movement commands by directly setting velocity"""
	print("🚀 Starting velocity-based movement...")
	
	# Move right for 4 seconds
	print("➡️ Setting velocity.x = 200")
	_set_target_velocity(200, 0)
	await get_tree().create_timer(4.0).timeout
	
	# Stop
	print("⏹️ Setting velocity.x = 0")
	_set_target_velocity(0, 0)
	await get_tree().create_timer(1.0).timeout
	
	# Jump
	print("🦘 Setting velocity.y = -400")
	_set_target_velocity(0, -400)
	await get_tree().create_timer(1.0).timeout
	
	# Move left
	print("⬅️ Setting velocity.x = -200")
	_set_target_velocity(-200, 0)
	await get_tree().create_timer(4.0).timeout
	
	# Stop
	print("⏹️ Final stop")
	_set_target_velocity(0, 0)
	
	print("🏁 Direct velocity demo completed!")

var target_velocity_x = 0.0
var target_velocity_y = 0.0

func _set_target_velocity(vx: float, vy: float):
	target_velocity_x = vx
	target_velocity_y = vy

func _custom_movement_override(delta: float):
	"""Custom physics process that bypasses input system"""
	if not target_player:
		return
	
	# Apply target velocity directly
	target_player.velocity.x = target_velocity_x
	if target_velocity_y != 0:
		target_player.velocity.y = target_velocity_y
		target_velocity_y = 0  # Reset after one frame for jump
	
	# Let gravity work normally when not jumping
	if target_player.velocity.y == 0 and not target_player.is_on_floor():
		target_player.velocity.y += target_player.gravity * delta