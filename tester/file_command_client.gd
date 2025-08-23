extends Node

# File-based command client - reads commands from a file in real-time

var current_movement = {
	"right": false,
	"left": false
}

var command_file = "user://commands.txt"
var last_command_time = 0.0

func _ready():
	print("=== FILE COMMAND CLIENT ===")
	print("🎮 Reading commands from: " + command_file)
	print("Write commands to commands.txt file!")
	print("")
	print("Available commands:")
	print("  right, left, jump, stop, status, quit")
	print("")
	
	# Initialize movement system (our working pattern!)
	Input.action_press("ui_right")
	await get_tree().process_frame
	Input.action_release("ui_right")
	print("✅ Movement system initialized")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Start command monitoring
	call_deferred("_monitor_commands")

func _monitor_commands():
	print("🚀 Command monitoring started - ready for file commands!")
	
	# Continuously monitor the command file
	while true:
		await get_tree().create_timer(0.5).timeout  # Check every 0.5 seconds
		_check_command_file()

func _check_command_file():
	"""Check if there are new commands in the file"""
	if FileAccess.file_exists(command_file):
		var file = FileAccess.open(command_file, FileAccess.READ)
		if file:
			var content = file.get_as_text().strip_edges()
			file.close()
			
			if content != "":
				# Process all commands in the file
				var commands = content.split("\n")
				for command in commands:
					if command.strip_edges() != "":
						execute_command(command.strip_edges())
				
				# Clear the file after processing
				_clear_command_file()

func _clear_command_file():
	"""Clear the command file after processing"""
	var file = FileAccess.open(command_file, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()

func execute_command(command: String):
	"""Execute a real-time command"""
	var cmd = command.strip_edges().to_lower()
	print("⚡ Executing: " + cmd + " (from file)")
	
	match cmd:
		"right":
			if current_movement.left:
				Input.action_release("ui_left")
				current_movement.left = false
			
			if not current_movement.right:
				Input.action_press("ui_right")  # This works!
				current_movement.right = true
				print("   ➡️ Started moving right")
			else:
				print("   ➡️ Already moving right")
				
		"left":
			if current_movement.right:
				Input.action_release("ui_right")
				current_movement.right = false
			
			if not current_movement.left:
				Input.action_press("ui_left")  # This works!
				current_movement.left = true
				print("   ⬅️ Started moving left")
			else:
				print("   ⬅️ Already moving left")
				
		"jump":
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
			print("   🦘 Jumped!")
			
		"stop":
			if current_movement.right:
				Input.action_release("ui_right")
				current_movement.right = false
			if current_movement.left:
				Input.action_release("ui_left")
				current_movement.left = false
			print("   ⏹️ Stopped all movement")
			
		"status":
			var status = "   📊 Status: "
			if current_movement.right:
				status += "Moving RIGHT "
			elif current_movement.left:
				status += "Moving LEFT "
			else:
				status += "STOPPED "
			print(status)
			
		"quit":
			print("   👋 Exiting...")
			Input.action_release("ui_right")
			Input.action_release("ui_left")
			get_tree().quit()
			
		_:
			print("   ❌ Unknown command: " + command)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Clean up on exit
		Input.action_release("ui_right")
		Input.action_release("ui_left")