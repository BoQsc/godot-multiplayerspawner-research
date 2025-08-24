extends Node

# Command-line controlled test client

var command_file_path = "res://client_commands.txt"
var last_command = ""

func _ready():
	print("=== COMMAND LINE CLIENT ===")
	print("Listening for commands in: " + command_file_path)
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	# Start command processing after connection
	call_deferred("_start_command_loop")

func _start_command_loop():
	# Wait for connection
	await get_tree().create_timer(3.0).timeout
	
	print("📡 Ready for commands! Write commands to:", command_file_path)
	print("Available commands: right, left, jump, stop, chase, find")
	
	# Start checking for commands
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1
	timer.timeout.connect(_check_commands)
	timer.start()

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
	print("🎮 Executing command: ", command)
	
	match command.to_lower():
		"right":
			Input.action_release("ui_left")
			Input.action_press("ui_right")
			print("➡️ Moving right")
		"left":
			Input.action_release("ui_right") 
			Input.action_press("ui_left")
			print("⬅️ Moving left")
		"jump":
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
			print("🦘 Jumping")
		"stop":
			Input.action_release("ui_right")
			Input.action_release("ui_left")
			print("⏹️ Stopped")
		"status":
			_report_status()
		"chase":
			_start_chase()
		"find":
			_find_and_navigate()
		_:
			print("❌ Unknown command: ", command)

func _report_status():
	# Try to find our player and other players
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			
			# Print all players
			print("👥 All players in world:")
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					print("📍 Me (", peer_id, ") at position: ", player.global_position)
				else:
					print("  Player ", peer_id, " at position: ", player.global_position)
			
			if game_manager.players.size() == 0:
				print("❌ No players found in game_manager.players")
		else:
			print("❌ Could not find game manager")
	else:
		print("❌ Could not find main scene")

func _start_chase():
	print("🎯 Starting chase mode...")
	var chase_timer = Timer.new()
	add_child(chase_timer)
	chase_timer.wait_time = 0.2
	chase_timer.timeout.connect(_chase_step)
	chase_timer.start()

func _chase_step():
	var main_scene = get_tree().root.get_node("Node2D")
	if main_scene:
		var game_manager = main_scene.get_node("GameManager")
		if game_manager:
			var my_id = multiplayer.get_unique_id()
			var my_pos = Vector2.ZERO
			var target_pos = Vector2.ZERO
			var found_target = false
			
			# Find my position and target
			for peer_id in game_manager.players:
				var player = game_manager.players[peer_id]
				if peer_id == my_id:
					my_pos = player.global_position
				elif peer_id == 1: # Target player 1
					target_pos = player.global_position
					found_target = true
			
			if found_target:
				var diff = target_pos - my_pos
				print("🎯 Distance to target: ", diff.length())
				
				# Navigate towards target with obstacle handling
				if abs(diff.x) > 50:
					if diff.x > 0:
						Input.action_release("ui_left")
						Input.action_press("ui_right")
					else:
						Input.action_release("ui_right")
						Input.action_press("ui_left")
				else:
					Input.action_release("ui_right")
					Input.action_release("ui_left")
				
				# Jump if target is above or to get over obstacles
				if diff.y < -100 or (abs(diff.x) < 100 and diff.y < -50):
					Input.action_press("ui_accept")
					await get_tree().process_frame
					Input.action_release("ui_accept")
				
				# Stop chasing when very close
				if diff.length() < 30:
					print("🎯 Reached target!")
					get_child(get_child_count()-1).queue_free() # Stop timer
			else:
				print("❌ Target not found")

func _find_and_navigate():
	print("🔍 Finding optimal path...")
	_report_status()
	await get_tree().create_timer(0.5).timeout
	_start_chase()
