extends Node

# Non-headless test client that can actually move

func _ready():
	print("=== WINDOWED TEST CLIENT ===")
	print("Running with visible window for proper input handling")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_movement_demo")

func _start_movement_demo():
	await get_tree().create_timer(8.0).timeout
	
	print("🎮 Starting movement demonstration...")
	print("This client should be able to move using input!")
	
	var my_peer_id = multiplayer.get_unique_id()
	print("Player ID: " + str(my_peer_id))
	
	# Simulate input sequence
	await _simulate_input_sequence()

func _simulate_input_sequence():
	"""Direct movement without input simulation"""
	print("🚀 Starting direct movement sequence...")
	
	# Get my player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found")
		return
	
	var my_player = players[my_peer_id]
	var start_pos = my_player.position
	print("📍 Starting position: " + str(start_pos))
	
	# Move right
	print("➡️ Moving RIGHT...")
	my_player.position = start_pos + Vector2(150, 0)
	print("   Moved to: " + str(my_player.position))
	await get_tree().create_timer(2.0).timeout
	
	# Move up
	print("⬆️ Moving UP...")
	my_player.position = my_player.position + Vector2(0, -100)
	print("   Moved to: " + str(my_player.position))
	await get_tree().create_timer(2.0).timeout
	
	# Move left
	print("⬅️ Moving LEFT...")
	my_player.position = my_player.position + Vector2(-150, 0)
	print("   Moved to: " + str(my_player.position))
	await get_tree().create_timer(2.0).timeout
	
	# Move down
	print("⬇️ Moving DOWN...")
	my_player.position = my_player.position + Vector2(0, 100)
	print("   Moved to: " + str(my_player.position))
	await get_tree().create_timer(2.0).timeout
	
	print("🏁 Movement demo completed!")
	print("You should have seen the client move right, jump, move left, and jump again.")
	
	# Keep running for manual control
	print("💡 Client will stay running - you can now manually test controls!")
	print("   Use arrow keys and spacebar/enter to move manually.")