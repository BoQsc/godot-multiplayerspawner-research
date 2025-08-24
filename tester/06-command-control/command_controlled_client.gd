extends Node

# Command-controlled client that works exactly like other clients but accepts commands

var current_commands = {
	"right": false,
	"left": false,
	"up": false,
	"down": false,
	"jump": false
}

var command_queue = []

func _ready():
	print("=== COMMAND CONTROLLED CLIENT ===")
	print("This client works exactly like normal clients but accepts command line input")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_command_system")

func _start_command_system():
	await get_tree().create_timer(8.0).timeout
	
	print("🎮 Command system ready!")
	print("Player ID: " + str(multiplayer.get_unique_id()))
	print("")
	print("Available commands:")
	print("  move_right - Start moving right")
	print("  move_left - Start moving left")  
	print("  jump - Jump once")
	print("  stop - Stop all movement")
	print("")
	
	# Start command processing
	_start_command_processing()

func _start_command_processing():
	"""Start processing movement commands"""
	# Extended demo sequence
	print("🚀 Starting EXTENDED demo command sequence...")
	
	# Move right for 5 seconds
	print("📝 Command: move_right (5 seconds)")
	execute_command("move_right")
	await get_tree().create_timer(5.0).timeout
	
	print("📝 Command: stop")
	execute_command("stop")
	await get_tree().create_timer(1.0).timeout
	
	# Jump 3 times
	print("📝 Command: jump (3x)")
	for i in range(3):
		execute_command("jump")
		await get_tree().create_timer(1.5).timeout
	
	# Move left for 6 seconds
	print("📝 Command: move_left (6 seconds)")
	execute_command("move_left")
	await get_tree().create_timer(6.0).timeout
	
	print("📝 Command: stop")
	execute_command("stop")
	await get_tree().create_timer(1.0).timeout
	
	# Move right while jumping
	print("📝 Command: move_right + jump combo")
	execute_command("move_right")
	await get_tree().create_timer(1.0).timeout
	execute_command("jump")
	await get_tree().create_timer(1.0).timeout
	execute_command("jump")
	await get_tree().create_timer(2.0).timeout
	
	print("📝 Command: stop")
	execute_command("stop")
	await get_tree().create_timer(1.0).timeout
	
	# Final sequence - zigzag pattern
	print("📝 Command: zigzag pattern")
	for i in range(4):
		execute_command("move_right")
		await get_tree().create_timer(1.5).timeout
		execute_command("stop")
		execute_command("jump")
		await get_tree().create_timer(1.0).timeout
		execute_command("move_left")
		await get_tree().create_timer(1.5).timeout
		execute_command("stop")
		execute_command("jump")
		await get_tree().create_timer(1.0).timeout
	
	print("🏁 EXTENDED demo sequence completed!")
	print("💡 Client stays running for manual commands")

func execute_command(command: String):
	"""Execute a movement command"""
	match command:
		"move_right":
			current_commands.right = true
			current_commands.left = false
			print("   ➡️ Moving right...")
		"move_left":
			current_commands.left = true
			current_commands.right = false
			print("   ⬅️ Moving left...")
		"jump":
			current_commands.jump = true
			print("   🦘 Jumping...")
			# Reset jump after one frame
			await get_tree().process_frame
			current_commands.jump = false
		"stop":
			current_commands.right = false
			current_commands.left = false
			print("   ⏹️ Stopped movement")

func _input(event):
	"""Process input based on current commands"""
	# Override normal input with our command state
	
	# Handle movement
	if current_commands.right:
		Input.action_press("ui_right")
	else:
		Input.action_release("ui_right")
		
	if current_commands.left:
		Input.action_press("ui_left")
	else:
		Input.action_release("ui_left")
	
	# Handle jump (one-shot)
	if current_commands.jump:
		Input.action_press("ui_accept")
	else:
		Input.action_release("ui_accept")