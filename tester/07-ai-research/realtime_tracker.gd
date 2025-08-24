extends Node

# Real-time position tracking client with manual controls

var command_file_path = "res://client_commands.txt"
var last_command = ""
var position_timer: Timer

func _ready():
	print("=== REALTIME TRACKER CLIENT ===")
	print("Real-time position tracking enabled")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	call_deferred("_start_systems")

func _start_systems():
	# Wait for connection
	await get_tree().create_timer(3.0).timeout
	
	print("📡 Ready! Commands: right, left, jump, stop")
	print("🎯 Real-time position tracking active")
	
	# Start position tracking
	position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 1.0  # Every second
	position_timer.timeout.connect(_report_positions)
	position_timer.start()
	
	# Start command checking
	var command_timer = Timer.new()
	add_child(command_timer)
	command_timer.wait_time = 0.1
	command_timer.timeout.connect(_check_commands)
	command_timer.start()

func _report_positions():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					print("📍 Me: ", player.global_position)
				elif peer_id == 1:
					var my_pos = game_manager.players[my_id].global_position
					var target_pos = player.global_position
					var distance = my_pos.distance_to(target_pos)
					var direction = ""
					
					if target_pos.x > my_pos.x + 50:
						direction += "RIGHT "
					elif target_pos.x < my_pos.x - 50:
						direction += "LEFT "
					
					if target_pos.y < my_pos.y - 50:
						direction += "UP "
					elif target_pos.y > my_pos.y + 50:
						direction += "DOWN "
					
					if direction == "":
						direction = "VERY CLOSE! "
					
					print("🎯 YOU: ", target_pos, " | Distance: ", int(distance), " | Go: ", direction)

func _check_commands():
	if FileAccess.file_exists(command_file_path):
		var file = FileAccess.open(command_file_path, FileAccess.READ)
		if file:
			var command = file.get_as_text().strip_edges()
			file.close()
			
			if command != last_command and command != "":
				last_command = command
				_execute_command(command)

func _execute_command(command: String):
	print("🎮 ", command)
	
	match command.to_lower():
		"right":
			Input.action_release("ui_left")
			Input.action_press("ui_right")
		"left":
			Input.action_release("ui_right") 
			Input.action_press("ui_left")
		"jump":
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
		"stop":
			Input.action_release("ui_right")
			Input.action_release("ui_left")
		_:
			print("❌ Unknown: ", command)