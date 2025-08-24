extends Node

# Command-controlled test client

var my_player = null
var game_manager = null
var move_speed = 50

func _ready():
	print("=== COMMAND CLIENT ===")
	
	# Load and instantiate the main scene
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_setup_commands")

func _setup_commands():
	"""Setup command system after connection"""
	await get_tree().create_timer(5.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	_find_my_player()
	
	print("🎮 COMMAND CLIENT READY!")
	print("Available commands: up, down, left, right, jump")
	print("Current position: " + str(my_player.position if my_player else "Unknown"))
	
	# Command processing loop
	call_deferred("_start_command_loop")

func _find_my_player():
	"""Find my player node"""
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	if players and my_peer_id in players:
		my_player = players[my_peer_id]
		print("✅ Found my player: " + str(my_peer_id))
	else:
		print("❌ Player not found")

func _start_command_loop():
	"""Start processing movement commands"""
	print("🚀 Starting command processing...")
	
	# I'll manually send commands by modifying this
	await get_tree().create_timer(2.0).timeout
	move_up()
	
	await get_tree().create_timer(2.0).timeout
	move_right()
	
	await get_tree().create_timer(2.0).timeout
	move_down()
	
	await get_tree().create_timer(2.0).timeout
	move_left()
	
	await get_tree().create_timer(2.0).timeout
	jump()
	
	print("🏁 Demo commands completed!")

func move_up():
	"""Move player up"""
	if my_player:
		var new_pos = my_player.position + Vector2(0, -move_speed)
		my_player.position = new_pos
		print("⬆️ UP - Moving to: " + str(new_pos))

func move_down():
	"""Move player down"""
	if my_player:
		var new_pos = my_player.position + Vector2(0, move_speed)
		my_player.position = new_pos
		print("⬇️ DOWN - Moving to: " + str(new_pos))

func move_left():
	"""Move player left"""
	if my_player:
		var new_pos = my_player.position + Vector2(-move_speed, 0)
		my_player.position = new_pos
		print("⬅️ LEFT - Moving to: " + str(new_pos))

func move_right():
	"""Move player right"""
	if my_player:
		var new_pos = my_player.position + Vector2(move_speed, 0)
		my_player.position = new_pos
		print("➡️ RIGHT - Moving to: " + str(new_pos))

func jump():
	"""Make player jump (move up and back down)"""
	if my_player:
		var start_pos = my_player.position
		var jump_pos = start_pos + Vector2(0, -80)
		my_player.position = jump_pos
		print("🦘 JUMP - Up to: " + str(jump_pos))
		
		await get_tree().create_timer(0.5).timeout
		
		my_player.position = start_pos
		print("🦘 LAND - Back to: " + str(start_pos))