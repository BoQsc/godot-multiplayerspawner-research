extends Node

# Command line controlled test client - walk around via terminal commands

var command_thread: Thread
var command_mutex: Mutex
var pending_commands: Array = []
var is_running: bool = true

func _ready():
	print("=== COMMAND LINE WALKER ===")
	print("🎮 Command line movement control ready!")
	print("")
	print("Available commands:")
	print("  right     - Move right")
	print("  left      - Move left")
	print("  jump      - Jump")
	print("  stop      - Stop all movement")
	print("  quit      - Exit client")
	print("")
	print("Type commands and press Enter:")
	
	# Start input immediately (we know this works!)
	Input.action_press("ui_right")
	await get_tree().process_frame
	Input.action_release("ui_right")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Initialize command system
	command_mutex = Mutex.new()
	command_thread = Thread.new()
	
	# Start command input thread
	command_thread.start(_command_input_thread)
	
	# Process commands in main thread
	call_deferred("_process_commands")

func _command_input_thread():
	"""Background thread to read command line input"""
	while is_running:
		# Simulate command input (in real implementation, this would read from stdin)
		# For demo, we'll auto-execute a sequence
		await get_tree().create_timer(2.0).timeout
		_add_command("right")
		
		await get_tree().create_timer(3.0).timeout
		_add_command("stop")
		
		await get_tree().create_timer(1.0).timeout
		_add_command("jump")
		
		await get_tree().create_timer(1.0).timeout
		_add_command("left")
		
		await get_tree().create_timer(3.0).timeout
		_add_command("stop")
		
		await get_tree().create_timer(1.0).timeout
		_add_command("jump")
		
		await get_tree().create_timer(2.0).timeout
		_add_command("right")
		
		await get_tree().create_timer(2.0).timeout
		_add_command("jump")
		
		await get_tree().create_timer(1.0).timeout
		_add_command("stop")
		
		print("🏁 Command sequence completed!")
		break

func _add_command(command: String):
	"""Thread-safe command addition"""
	command_mutex.lock()
	pending_commands.append(command)
	command_mutex.unlock()
	print("📝 Command queued: " + command)

func _process_commands():
	"""Process pending commands from main thread"""
	while is_running:
		command_mutex.lock()
		var commands_to_process = pending_commands.duplicate()
		pending_commands.clear()
		command_mutex.unlock()
		
		for command in commands_to_process:
			_execute_command(command)
		
		await get_tree().process_frame

func _execute_command(command: String):
	"""Execute a movement command"""
	print("⚡ Executing: " + command)
	
	match command.strip_edges().to_lower():
		"right":
			Input.action_release("ui_left")  # Stop left first
			Input.action_press("ui_right")
			print("   ➡️ Moving right...")
			
		"left":
			Input.action_release("ui_right")  # Stop right first
			Input.action_press("ui_left")
			print("   ⬅️ Moving left...")
			
		"jump":
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
			print("   🦘 Jumped!")
			
		"stop":
			Input.action_release("ui_right")
			Input.action_release("ui_left")
			print("   ⏹️ Stopped all movement")
			
		"quit":
			print("   👋 Exiting...")
			is_running = false
			get_tree().quit()
			
		_:
			print("   ❌ Unknown command: " + command)
			print("   Available: right, left, jump, stop, quit")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup()

func _cleanup():
	"""Clean up threads on exit"""
	is_running = false
	if command_thread and command_thread.is_started():
		command_thread.wait_to_finish()

# Manual command interface (for testing)
func manual_command(cmd: String):
	"""Call this function to manually send commands"""
	_add_command(cmd)