extends Node

# RPC-based movement test client

var my_player = null
var game_manager = null

func _ready():
	print("=== RPC MOVEMENT CLIENT ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_setup_rpc_movement")

func _setup_rpc_movement():
	await get_tree().create_timer(8.0).timeout
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found")
		return
	
	my_player = players[my_peer_id]
	print("🎮 RPC Movement Client Ready!")
	print("Player ID: " + str(my_peer_id))
	print("Starting position: " + str(my_player.position))
	
	# Start movement commands
	await _execute_movement_commands()

func _execute_movement_commands():
	"""Execute a series of movement commands using RPC"""
	print("🚀 Starting RPC movement sequence...")
	
	# Move right
	print("➡️ MOVE RIGHT")
	rpc_move_right()
	await get_tree().create_timer(2.0).timeout
	
	# Move up  
	print("⬆️ MOVE UP")
	rpc_move_up()
	await get_tree().create_timer(2.0).timeout
	
	# Move left
	print("⬅️ MOVE LEFT") 
	rpc_move_left()
	await get_tree().create_timer(2.0).timeout
	
	# Move down
	print("⬇️ MOVE DOWN")
	rpc_move_down()
	await get_tree().create_timer(2.0).timeout
	
	# Jump
	print("🦘 JUMP")
	rpc_jump()
	await get_tree().create_timer(2.0).timeout
	
	print("🏁 Movement sequence completed!")

# RPC Movement Methods
@rpc("any_peer", "call_local", "reliable")
func rpc_move_right():
	"""Move right using velocity"""
	if my_player:
		my_player.velocity.x = 200
		print("   Set velocity.x = 200")

@rpc("any_peer", "call_local", "reliable")
func rpc_move_left():
	"""Move left using velocity"""
	if my_player:
		my_player.velocity.x = -200
		print("   Set velocity.x = -200")

@rpc("any_peer", "call_local", "reliable")
func rpc_move_up():
	"""Move up using position (since there's no up velocity in platformer)"""
	if my_player:
		my_player.position.y -= 50
		print("   Moved position.y -= 50")

@rpc("any_peer", "call_local", "reliable")
func rpc_move_down():
	"""Move down using position"""
	if my_player:
		my_player.position.y += 50
		print("   Moved position.y += 50")

@rpc("any_peer", "call_local", "reliable")
func rpc_jump():
	"""Jump using velocity"""
	if my_player:
		my_player.velocity.y = -400
		print("   Set velocity.y = -400")

@rpc("any_peer", "call_local", "reliable")
func rpc_stop():
	"""Stop all movement"""
	if my_player:
		my_player.velocity.x = 0
		my_player.velocity.y = 0
		print("   Stopped all movement")