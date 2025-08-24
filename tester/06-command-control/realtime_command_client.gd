extends Node

# Real-time command line controlled client

var current_movement = {
	"right": false,
	"left": false
}

func _ready():
	print("=== REAL-TIME COMMAND CLIENT ===")
	print("🎮 Real-time command line control active!")
	print("")
	print("Commands (type and press Enter):")
	print("  right     - Start moving right")
	print("  left      - Start moving left") 
	print("  jump      - Jump once")
	print("  stop      - Stop all movement")
	print("  status    - Show current state")
	print("  quit      - Exit")
	print("")
	
	# Initialize movement immediately (our working pattern!)
	Input.action_press("ui_right")
	await get_tree().process_frame
	Input.action_release("ui_right")
	print("✅ Movement system initialized")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Start command processing
	call_deferred("_start_command_system")

func _start_command_system():
	print("🚀 Command system ready - waiting for commands...")
	
	# Demonstrate with auto-commands first, then wait for manual input
	await _demo_sequence()
	
	# In a real implementation, this would read from stdin
	# For now, simulate command input
	await _simulate_command_input()

func _demo_sequence():
	print("📺 Running demo sequence...")
	
	await get_tree().create_timer(1.0).timeout
	execute_command("right")
	
	await get_tree().create_timer(3.0).timeout
	execute_command("jump")
	
	await get_tree().create_timer(1.0).timeout
	execute_command("left")
	
	await get_tree().create_timer(3.0).timeout
	execute_command("stop")
	
	await get_tree().create_timer(0.5).timeout
	execute_command("status")
	
	print("📺 Demo completed - ready for real-time commands!")

func _simulate_command_input():
	print("💡 Simulating manual command input...")
	
	# Simulate user typing commands
	var commands = ["right", "jump", "stop", "left", "jump", "right", "stop", "status"]
	
	for cmd in commands:
		await get_tree().create_timer(2.0).timeout  # Simulate user thinking/typing
		print("📝 User input: " + cmd)
		execute_command(cmd)

func execute_command(command: String):
	"""Execute a real-time command"""
	var cmd = command.strip_edges().to_lower()
	print("⚡ Executing: " + cmd)
	
	match cmd:
		"right":
			# Stop left first, start right (our working pattern!)
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
			# Stop right first, start left
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
			# Jump works with our pattern!
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
			print("   🦘 Jumped!")
			
		"stop":
			# Stop all movement
			if current_movement.right:
				Input.action_release("ui_right")
				current_movement.right = false
			if current_movement.left:
				Input.action_release("ui_left")
				current_movement.left = false
			print("   ⏹️ Stopped all movement")
			
		"status":
			# Show current movement state
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
			# Clean stop before exit
			Input.action_release("ui_right")
			Input.action_release("ui_left")
			get_tree().quit()
			
		_:
			print("   ❌ Unknown command: " + command)
			print("   Available: right, left, jump, stop, status, quit")

# Public interface for external control
func cmd_right():
	execute_command("right")

func cmd_left():
	execute_command("left")

func cmd_jump():
	execute_command("jump")

func cmd_stop():
	execute_command("stop")

func cmd_status():
	execute_command("status")