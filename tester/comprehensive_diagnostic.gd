extends Node

# COMPREHENSIVE DIAGNOSTIC - Check every possible cause

func _ready():
	print("=== COMPREHENSIVE DIAGNOSTIC ===")
	print("🔍 Deep investigation of movement failure...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_full_diagnostic")

func _full_diagnostic():
	await get_tree().create_timer(5.0).timeout
	
	print("🔍 STARTING COMPREHENSIVE DIAGNOSTIC")
	print("=====================================")
	
	# 1. MULTIPLAYER SYSTEM CHECK
	print("📡 MULTIPLAYER SYSTEM:")
	var peer_id = multiplayer.get_unique_id()
	print("   Unique ID: " + str(peer_id))
	print("   Peer exists: " + str(multiplayer.multiplayer_peer != null))
	if multiplayer.multiplayer_peer:
		print("   Connection status: " + str(multiplayer.multiplayer_peer.get_connection_status()))
		print("   Is server: " + str(multiplayer.is_server()))
	
	# 2. GAME MANAGER CHECK  
	print("\n🎮 GAME MANAGER:")
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	print("   Found: " + str(game_manager != null))
	if not game_manager:
		print("   ❌ CRITICAL FAILURE: No GameManager")
		return
	
	# 3. PLAYERS DICTIONARY CHECK
	print("\n👥 PLAYERS DICTIONARY:")
	var players = game_manager.get("players")
	print("   Exists: " + str(players != null))
	if players:
		print("   Total players: " + str(players.size()))
		print("   Player IDs: " + str(players.keys()))
		print("   My ID in players: " + str(peer_id in players))
	else:
		print("   ❌ CRITICAL FAILURE: No players dictionary")
		return
	
	if not (peer_id in players):
		print("   ❌ CRITICAL FAILURE: My player not in dictionary")
		return
	
	# 4. PLAYER OBJECT CHECK
	print("\n🤖 PLAYER OBJECT:")
	var my_player = players[peer_id]
	print("   Exists: " + str(my_player != null))
	print("   Node type: " + str(my_player.get_class()))
	print("   Script: " + str(my_player.get_script()))
	print("   Position: " + str(my_player.position))
	print("   Velocity: " + str(my_player.velocity if my_player.has_method("get") else "N/A"))
	
	# 5. CRITICAL PLAYER PROPERTIES
	print("\n🔑 CRITICAL PROPERTIES:")
	if my_player.has_method("get"):
		print("   is_local_player: " + str(my_player.get("is_local_player")))
		print("   player_id: " + str(my_player.get("player_id")))
		print("   max_speed: " + str(my_player.get("max_speed")))
		
		# Check if it's actually local
		var is_local = my_player.get("is_local_player")
		var player_id = my_player.get("player_id")
		print("   Expected local: " + str(player_id == peer_id))
		print("   Actual local: " + str(is_local))
		
		if not is_local:
			print("   ❌ CRITICAL ISSUE: Player not marked as local!")
			print("   🔧 ATTEMPTING FIX: Setting is_local_player = true")
			my_player.is_local_player = true
			print("   ✅ Fixed is_local_player")
	
	# 6. INPUT SYSTEM CHECK
	print("\n⌨️ INPUT SYSTEM:")
	print("   ui_right defined: " + str(InputMap.has_action("ui_right")))
	print("   ui_left defined: " + str(InputMap.has_action("ui_left")))
	print("   ui_accept defined: " + str(InputMap.has_action("ui_accept")))
	
	if InputMap.has_action("ui_right"):
		print("   ui_right events: " + str(InputMap.action_get_events("ui_right")))
	
	# 7. INITIAL INPUT STATE
	print("\n📊 INITIAL INPUT STATE:")
	print("   ui_right pressed: " + str(Input.is_action_pressed("ui_right")))
	print("   ui_left pressed: " + str(Input.is_action_pressed("ui_left")))
	print("   get_axis result: " + str(Input.get_axis("ui_left", "ui_right")))
	
	# 8. MOVEMENT SIMULATION TEST
	print("\n🧪 MOVEMENT TEST:")
	var start_pos = my_player.position
	var start_vel = my_player.velocity if my_player.has_method("get") else Vector2.ZERO
	print("   Start position: " + str(start_pos))
	print("   Start velocity: " + str(start_vel))
	
	# Press right
	print("   🔧 Pressing ui_right...")
	Input.action_press("ui_right")
	
	# Check immediate state
	await get_tree().process_frame
	print("   After press - ui_right: " + str(Input.is_action_pressed("ui_right")))
	print("   After press - get_axis: " + str(Input.get_axis("ui_left", "ui_right")))
	
	# Wait and check for movement
	for frame in range(30):  # Check for 30 frames
		await get_tree().process_frame
		var current_pos = my_player.position
		var current_vel = my_player.velocity if my_player.has_method("get") else Vector2.ZERO
		
		if current_pos != start_pos or current_vel != start_vel:
			print("   ✅ MOVEMENT DETECTED at frame " + str(frame))
			print("   New position: " + str(current_pos))
			print("   New velocity: " + str(current_vel))
			break
		
		if frame == 29:
			print("   ❌ NO MOVEMENT after 30 frames")
	
	# Release input
	print("   🔧 Releasing ui_right...")
	Input.action_release("ui_right")
	
	# 9. PHYSICS PROCESS CHECK
	print("\n⚙️ PHYSICS PROCESS:")
	if my_player.has_method("_physics_process"):
		print("   Has _physics_process: YES")
	else:
		print("   Has _physics_process: NO")
		
	if my_player.has_method("_custom_physics_process"):
		print("   Has _custom_physics_process: YES")
	else:
		print("   Has _custom_physics_process: NO")
		
	if my_player.has_method("_handle_player_input"):
		print("   Has _handle_player_input: YES")
	else:
		print("   Has _handle_player_input: NO")
	
	# 10. NETWORK MANAGER CHECK
	print("\n🌐 NETWORK MANAGER:")
	var network_manager = get_tree().get_first_node_in_group("network_manager")
	print("   Found: " + str(network_manager != null))
	if network_manager and network_manager.has_method("get_network_stats"):
		var stats = network_manager.get_network_stats()
		print("   Network stats: " + str(stats))
	
	print("\n🏁 DIAGNOSTIC COMPLETE")
	print("=====================================")
	
	# Keep running for observation
	print("🔄 Staying alive for manual observation...")
	while true:
		await get_tree().create_timer(5.0).timeout
		print("   Still alive - position: " + str(my_player.position))