extends Node

# Test client using server's existing update_player_position RPC

func _ready():
	print("=== SERVER MOVEMENT CLIENT ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_server_movement")

func _start_server_movement():
	await get_tree().create_timer(8.0).timeout
	
	var my_peer_id = multiplayer.get_unique_id()
	print("🎮 Starting server movement commands for peer " + str(my_peer_id))
	
	# Get my starting position
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	var start_pos = Vector2.ZERO
	
	if game_manager:
		var players = game_manager.get("players")
		if players and my_peer_id in players:
			start_pos = players[my_peer_id].position
			print("📍 Starting position: " + str(start_pos))
	
	# Execute movement commands using the server's RPC
	await _execute_movement_sequence(my_peer_id, start_pos)

func _execute_movement_sequence(peer_id: int, start_pos: Vector2):
	"""Execute movement using server's update_player_position RPC"""
	print("🚀 Starting movement sequence using server RPC...")
	
	# Move right
	var right_pos = start_pos + Vector2(100, 0)
	print("➡️ MOVE RIGHT to " + str(right_pos))
	rpc_id(1, "update_player_position", peer_id, right_pos)
	await get_tree().create_timer(2.0).timeout
	
	# Move up
	var up_pos = right_pos + Vector2(0, -80)
	print("⬆️ MOVE UP to " + str(up_pos))
	rpc_id(1, "update_player_position", peer_id, up_pos)
	await get_tree().create_timer(2.0).timeout
	
	# Move left
	var left_pos = up_pos + Vector2(-100, 0)
	print("⬅️ MOVE LEFT to " + str(left_pos))
	rpc_id(1, "update_player_position", peer_id, left_pos)
	await get_tree().create_timer(2.0).timeout
	
	# Move down
	var down_pos = left_pos + Vector2(0, 80)
	print("⬇️ MOVE DOWN to " + str(down_pos))
	rpc_id(1, "update_player_position", peer_id, down_pos)
	await get_tree().create_timer(2.0).timeout
	
	# Jump (move up quickly then back down)
	var jump_pos = down_pos + Vector2(0, -120)
	print("🦘 JUMP UP to " + str(jump_pos))
	rpc_id(1, "update_player_position", peer_id, jump_pos)
	await get_tree().create_timer(1.0).timeout
	
	print("🦘 LAND at " + str(down_pos))
	rpc_id(1, "update_player_position", peer_id, down_pos)
	
	print("🏁 Movement sequence completed!")
	print("Final position should be: " + str(down_pos))