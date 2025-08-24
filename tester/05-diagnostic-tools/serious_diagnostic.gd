extends Node

# SERIOUS DIAGNOSTIC - Find out exactly why movement stopped working

func _ready():
	print("=== SERIOUS DIAGNOSTIC ===")
	print("Investigating movement failure...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_investigate_movement")

func _investigate_movement():
	print("🔍 STARTING INVESTIGATION...")
	
	# Wait for everything to be ready
	await get_tree().create_timer(5.0).timeout
	
	print("📊 SYSTEM STATE CHECK:")
	print("   Multiplayer unique ID: " + str(multiplayer.get_unique_id()))
	print("   Multiplayer peer exists: " + str(multiplayer.multiplayer_peer != null))
	if multiplayer.multiplayer_peer:
		print("   Connection status: " + str(multiplayer.multiplayer_peer.get_connection_status()))
	
	# Find game manager and player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	print("   GameManager found: " + str(game_manager != null))
	
	if not game_manager:
		print("❌ CRITICAL: No GameManager - ABORTING")
		return
		
	var players = game_manager.get("players")
	print("   Players dict exists: " + str(players != null))
	
	if not players:
		print("❌ CRITICAL: No players dict - ABORTING")
		return
		
	print("   Total players: " + str(players.size()))
	
	var my_id = multiplayer.get_unique_id()
	print("   My ID in players: " + str(my_id in players))
	
	if not (my_id in players):
		print("❌ CRITICAL: Player not spawned - ABORTING")
		return
		
	var my_player = players[my_id]
	print("   My player node valid: " + str(my_player != null))
	print("   Player class: " + str(my_player.get_script()))
	print("   Player position: " + str(my_player.position))
	
	if my_player.has_method("get"):
		print("   is_local_player: " + str(my_player.get("is_local_player")))
		print("   player_id: " + str(my_player.get("player_id")))
	
	print("📊 INPUT SYSTEM TEST:")
	print("   Before press - ui_right pressed: " + str(Input.is_action_pressed("ui_right")))
	print("   Before press - get_axis result: " + str(Input.get_axis("ui_left", "ui_right")))
	
	print("🧪 PRESSING ui_right...")
	Input.action_press("ui_right")
	await get_tree().process_frame
	
	print("   After press - ui_right pressed: " + str(Input.is_action_pressed("ui_right")))
	print("   After press - get_axis result: " + str(Input.get_axis("ui_left", "ui_right")))
	
	# Check if player actually processes input
	var start_pos = my_player.position
	print("   Starting position: " + str(start_pos))
	
	# Wait several frames
	for i in range(10):
		await get_tree().process_frame
		var current_pos = my_player.position
		if current_pos != start_pos:
			print("   ✅ MOVEMENT DETECTED at frame " + str(i))
			print("   New position: " + str(current_pos))
			break
	
	var final_pos = my_player.position
	print("   Final position: " + str(final_pos))
	print("   Position changed: " + str(start_pos != final_pos))
	
	# Release input
	Input.action_release("ui_right")
	print("   Released ui_right")
	
	print("🏁 DIAGNOSTIC COMPLETE")
	
	if start_pos == final_pos:
		print("❌ MOVEMENT FAILED - Player did not move despite input")
		print("🔍 Possible causes:")
		print("   - Player physics not processing")
		print("   - Input system not working")
		print("   - Player authority issues")
		print("   - Network synchronization problems")
	else:
		print("✅ MOVEMENT SUCCESS - Player moved as expected")