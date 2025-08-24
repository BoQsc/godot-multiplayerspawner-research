extends Node

# Properly timed movement client - waits for actual spawning before moving

func _ready():
	print("=== PROPERLY TIMED CLIENT ===")
	print("🎮 Waiting for proper spawn before movement!")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_wait_for_spawn_then_move")

func _wait_for_spawn_then_move():
	print("⏳ Waiting for player to spawn...")
	
	# Wait for multiplayer to be ready
	while not multiplayer.multiplayer_peer:
		await get_tree().process_frame
	print("🔗 Multiplayer peer ready")
	
	# Wait for spawning to complete
	await get_tree().create_timer(10.0).timeout
	print("👤 Player should be spawned now")
	
	# Check if we can find our player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found in game - waiting longer...")
		await get_tree().create_timer(3.0).timeout
		players = game_manager.get("players")
		if not players or not (my_peer_id in players):
			print("❌ Still no player found - aborting")
			return
	
	print("✅ Player found! Starting movement...")
	print("🚀 Player ID: " + str(my_peer_id))
	
	# NOW start the movement sequence - player is actually spawned
	_execute_movement_sequence()

func _execute_movement_sequence():
	print("➡️ MOVING RIGHT NOW!")
	Input.action_press("ui_right")
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_right")
	print("⏹️ Stopped right")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🦘 JUMPING NOW!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	
	print("⬅️ MOVING LEFT NOW!")
	Input.action_press("ui_left")
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_left")
	print("⏹️ Stopped left")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🦘 JUMPING AGAIN!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	
	print("➡️🦘 RIGHT + JUMP COMBO!")
	Input.action_press("ui_right")
	await get_tree().create_timer(1.0).timeout
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("ui_right")
	
	print("🏁 MOVEMENT SEQUENCE COMPLETED!")
	print("✨ All movements executed with proper timing!")