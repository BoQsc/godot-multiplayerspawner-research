extends Node

# Head Jumper Client - Tries to jump on the user's head

class_name HeadJumperClient

var game_manager = null
var my_peer_id = 0
var movement_timer: Timer
var jump_cooldown = 0.0

var target_player_id = 1  # Looking for Player_1 (the user)

func _ready():
	print("=== HEAD JUMPER CLIENT ===")
	print("🦘 I'm going to try to jump on your head!")
	print("🎯 Target: Player_1")
	
	_setup_scene()
	call_deferred("_initialize_head_jumper")

func _setup_scene():
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)

func _initialize_head_jumper():
	await get_tree().create_timer(3.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ GameManager not found")
		return
	
	my_peer_id = multiplayer.get_unique_id()
	print("🆔 Head Jumper ready - Peer ID: ", my_peer_id)
	print("🎯 Starting head-jumping mission!")
	
	_start_head_jumping()

func _start_head_jumping():
	movement_timer = Timer.new()
	add_child(movement_timer)
	movement_timer.wait_time = 0.1
	movement_timer.timeout.connect(_try_to_jump_on_head)
	movement_timer.start()
	print("🦘 Head jumping system active!")

func _try_to_jump_on_head():
	if not game_manager or not game_manager.players.has(my_peer_id):
		return
	
	# Reduce jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= 0.1
	
	# Check if target exists
	if not game_manager.players.has(target_player_id):
		print("👀 Looking for Player_1...")
		return
	
	var my_pos = game_manager.players[my_peer_id].global_position
	var target_pos = game_manager.players[target_player_id].global_position
	var distance = my_pos.distance_to(target_pos)
	
	print("📍 Me: (", int(my_pos.x), ", ", int(my_pos.y), ") | You: (", int(target_pos.x), ", ", int(target_pos.y), ") | Distance: ", int(distance))
	
	# Head jumping strategy
	if distance > 200:
		_approach_target(my_pos, target_pos)
	elif distance > 80:
		_position_for_head_jump(my_pos, target_pos)
	else:
		_attempt_head_jump(my_pos, target_pos)

func _approach_target(my_pos: Vector2, target_pos: Vector2):
	print("🏃 Approaching target for head jump attempt...")
	
	# Stop all movement first
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	# Move toward target
	if target_pos.x > my_pos.x + 30:
		Input.action_press("ui_right")
		print("➡️ Running right to get closer")
	elif target_pos.x < my_pos.x - 30:
		Input.action_press("ui_left")
		print("⬅️ Running left to get closer")
	
	# Jump toward target if they're higher up
	if target_pos.y < my_pos.y - 60 and jump_cooldown <= 0:
		_perform_jump("🦘 Jumping to reach higher target")

func _position_for_head_jump(my_pos: Vector2, target_pos: Vector2):
	print("🎯 Positioning for head jump attack!")
	
	# Stop all movement first  
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	var horizontal_distance = abs(target_pos.x - my_pos.x)
	var vertical_distance = target_pos.y - my_pos.y
	
	# Try to get above the target
	if vertical_distance > -50:  # Target is not sufficiently below me
		if horizontal_distance < 40:
			# We're close horizontally, try to get higher
			if jump_cooldown <= 0:
				_perform_jump("🦘 Jumping to get above you for head stomp!")
		else:
			# Move closer horizontally first
			if target_pos.x > my_pos.x:
				Input.action_press("ui_right")
				print("➡️ Moving right to position above target")
			else:
				Input.action_press("ui_left")
				print("⬅️ Moving left to position above target")
	else:
		# We're above target, fine-tune horizontal position
		if horizontal_distance > 20:
			if target_pos.x > my_pos.x:
				Input.action_press("ui_right")
				print("➡️ Fine-tuning position above target")
			else:
				Input.action_press("ui_left")
				print("⬅️ Fine-tuning position above target")
		else:
			print("🎯 Perfect position! Ready for head jump!")

func _attempt_head_jump(my_pos: Vector2, target_pos: Vector2):
	var horizontal_distance = abs(target_pos.x - my_pos.x)
	var vertical_distance = target_pos.y - my_pos.y
	
	# Stop horizontal movement for precise jump
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	
	if vertical_distance > -20:
		# Target is roughly at same level or above - try to jump onto their head
		if horizontal_distance < 30 and jump_cooldown <= 0:
			_perform_jump("🦘 JUMPING ON YOUR HEAD! *BOING*")
			print("🎯 HEAD STOMP ATTEMPT!")
		else:
			# Get closer horizontally for head stomp
			if target_pos.x > my_pos.x:
				Input.action_press("ui_right")
				print("➡️ Getting closer for head stomp")
			else:
				Input.action_press("ui_left")
				print("⬅️ Getting closer for head stomp")
	else:
		# We're above target - perfect for head jump!
		if horizontal_distance < 25:
			if jump_cooldown <= 0:
				_perform_jump("🦘 DIVING HEAD JUMP FROM ABOVE!")
				print("💥 AERIAL HEAD STOMP!")
			else:
				print("⏳ Waiting for jump cooldown to perform head stomp...")
		else:
			# Position directly above target
			if target_pos.x > my_pos.x:
				Input.action_press("ui_right")
				print("➡️ Positioning directly above for head dive")
			else:
				Input.action_press("ui_left")
				print("⬅️ Positioning directly above for head dive")

func _perform_jump(message: String):
	if jump_cooldown > 0:
		return
	
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	jump_cooldown = 1.5  # Longer cooldown for more strategic jumping
	print(message)

func _exit_tree():
	print("🦘 Head jumper signing off! Hope I got your head!")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")
	
	if movement_timer:
		movement_timer.queue_free()