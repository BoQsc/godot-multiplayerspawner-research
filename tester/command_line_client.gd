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
	print("Available commands: right, left, jump, stop")
	
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
		_:
			print("❌ Unknown command: ", command)