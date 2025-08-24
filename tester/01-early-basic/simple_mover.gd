extends Node

# Simple test client that definitely moves

func _ready():
	print("=== SIMPLE MOVER TEST ===")
	
	# Load and instantiate the main scene
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Start movement after connection
	call_deferred("_start_moving")

func _start_moving():
	"""Start moving after connection"""
	await get_tree().create_timer(8.0).timeout  # Wait for connection
	
	print("🤖 Starting movement behaviors!")
	
	# Simple movement loop
	for i in range(20):  # Move 20 times
		var target = Vector2(
			randf_range(-300, 300),
			randf_range(-300, 300)
		)
		print("🚶 Move " + str(i+1) + ": Going to " + str(target))
		
		# Find my player and move
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			var players = game_manager.get("players")
			var my_peer_id = multiplayer.get_unique_id()
			if players and my_peer_id in players:
				var my_player = players[my_peer_id]
				if my_player:
					my_player.position = target
					print("✅ Moved to " + str(target))
				else:
					print("❌ No player node found")
			else:
				print("❌ Not in players list")
		else:
			print("❌ No GameManager")
		
		await get_tree().create_timer(2.0).timeout
	
	print("🏁 Finished 20 moves!")