extends Node

var command_file_path = "res://client_commands.txt"
var last_command = ""
var position_timer: Timer
var hunt_timer: Timer
var last_target_pos = Vector2.ZERO
var target_not_moved_count = 0

func _ready():
	print("=== SMART HUNTER CLIENT ===")
	print("Analyzing movement patterns...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	call_deferred("_start_systems")

func _start_systems():
	await get_tree().create_timer(3.0).timeout
	
	print("🎯 Smart hunting mode active")
	
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 0.5
	position_timer.timeout.connect(_track_positions)
	position_timer.start()
	
	hunt_timer = Timer.new()
	add_child(hunt_timer)
	hunt_timer.wait_time = 0.1
	hunt_timer.timeout.connect(_smart_hunt)
	hunt_timer.start()

func _track_positions():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			for peer_id in game_manager.players:
				if peer_id == 1:
					var current_pos = game_manager.players[peer_id].global_position
					if current_pos.distance_to(last_target_pos) < 10:
						target_not_moved_count += 1
					else:
						target_not_moved_count = 0
					last_target_pos = current_pos

func _smart_hunt():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			var my_pos = Vector2.ZERO
			var target_pos = Vector2.ZERO
			var found = false
			
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					my_pos = player.global_position
				elif peer_id == 1:
					target_pos = player.global_position
					found = true
			
			if found:
				var diff = target_pos - my_pos
				var distance = diff.length()
				
				# If target hasn't moved, predict where they might go
				if target_not_moved_count > 4:
					# Jump repeatedly if target is above and not moving
					if diff.y < -50:
						Input.action_press("ui_accept")
						await get_tree().process_frame
						Input.action_release("ui_accept")
						return
				
				# Smart movement based on distance and direction
				if distance < 50:
					print("🎯 VERY CLOSE! Final jump attack!")
					Input.action_press("ui_accept")
					await get_tree().process_frame  
					Input.action_release("ui_accept")
				elif abs(diff.x) > 100:
					# Prioritize horizontal movement when far apart
					if diff.x > 0:
						Input.action_release("ui_left")
						Input.action_press("ui_right")
					else:
						Input.action_release("ui_right")
						Input.action_press("ui_left")
				elif abs(diff.y) > 100:
					# Jump when target is significantly above
					Input.action_press("ui_accept")
					await get_tree().process_frame
					Input.action_release("ui_accept")
				else:
					# Close range - rapid alternating movement
					if randf() > 0.7:
						Input.action_press("ui_accept")
						await get_tree().process_frame
						Input.action_release("ui_accept")
					elif diff.x > 0:
						Input.action_release("ui_left")
						Input.action_press("ui_right")
					else:
						Input.action_release("ui_right")
						Input.action_press("ui_left")