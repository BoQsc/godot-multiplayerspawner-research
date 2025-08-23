extends Node

# Client that waits for camera to be enabled before moving

var movement_started = false

func _ready():
	print("=== WAIT FOR CAMERA CLIENT ===")
	print("Waiting for camera to be enabled before moving...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_monitor_for_camera")

func _monitor_for_camera():
	print("🔍 Monitoring for camera activation...")
	
	# Wait for multiplayer to be ready
	while not multiplayer.multiplayer_peer:
		await get_tree().process_frame
	
	# Wait for our player to be spawned and camera enabled
	var wait_count = 0
	while wait_count < 100:  # Max 10 seconds
		await get_tree().create_timer(0.1).timeout
		wait_count += 1
		
		# Check if we can find our player with camera
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			var players = game_manager.get("players")
			var my_peer_id = multiplayer.get_unique_id()
			
			if players and (my_peer_id in players):
				var my_player = players[my_peer_id]
				if my_player and my_player.has_method("get") and my_player.get("player_camera"):
					var camera = my_player.get("player_camera")
					if camera and camera.enabled:
						print("✅ Camera is enabled! Starting movement NOW!")
						_start_movement()
						return
	
	print("❌ Timeout waiting for camera - starting movement anyway")
	_start_movement()

func _start_movement():
	if movement_started:
		return
	movement_started = true
	
	print("🚀 MOVING RIGHT NOW!")
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
	
	print("🏁 Movement sequence complete!")