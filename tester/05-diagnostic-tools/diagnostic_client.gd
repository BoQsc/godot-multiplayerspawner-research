extends Node

# Diagnostic client to check what's wrong with movement

func _ready():
	print("=== DIAGNOSTIC CLIENT ===")
	print("🔍 Checking why movement stopped working...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_diagnose_movement")

func _diagnose_movement():
	await get_tree().create_timer(8.0).timeout
	print("🔍 Starting diagnostic...")
	
	# Check 1: Is multiplayer working?
	print("1. Multiplayer check:")
	print("   Unique ID: " + str(multiplayer.get_unique_id()))
	print("   Has peer: " + str(multiplayer.multiplayer_peer != null))
	if multiplayer.multiplayer_peer:
		print("   Connection status: " + str(multiplayer.multiplayer_peer.get_connection_status()))
	
	# Check 2: Can we find game manager?
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	print("2. Game manager check:")
	print("   Found: " + str(game_manager != null))
	
	if game_manager:
		var players = game_manager.get("players")
		print("   Players dict: " + str(players != null))
		if players:
			print("   Player count: " + str(players.size()))
			var my_id = multiplayer.get_unique_id()
			print("   My ID in players: " + str(my_id in players))
			
			if my_id in players:
				var my_player = players[my_id]
				print("   My player node: " + str(my_player))
				print("   Player is_local: " + str(my_player.get("is_local_player")))
				print("   Player position: " + str(my_player.position))
				
				# Check 3: Test input directly
				print("3. Testing input...")
				print("   Before: is_action_pressed('ui_right'): " + str(Input.is_action_pressed("ui_right")))
				
				Input.action_press("ui_right")
				await get_tree().process_frame
				print("   After press: is_action_pressed('ui_right'): " + str(Input.is_action_pressed("ui_right")))
				print("   Input.get_axis result: " + str(Input.get_axis("ui_left", "ui_right")))
				
				# Wait and check if player moved
				var start_pos = my_player.position
				await get_tree().create_timer(2.0).timeout
				var end_pos = my_player.position
				print("   Start position: " + str(start_pos))
				print("   End position: " + str(end_pos))
				print("   Did move: " + str(start_pos != end_pos))
				
				Input.action_release("ui_right")
				print("   Released ui_right")
	
	print("🏁 Diagnostic complete!")