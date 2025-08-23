extends SceneTree

# Command sender script - can be run to send commands to the running client

func _init():
	var args = OS.get_cmdline_user_args()
	if args.size() == 0:
		print("Usage: godot --script send_command.gd <command>")
		print("Commands: right, left, jump, stop, status, quit")
		quit()
		return
	
	var command = args[0]
	print("Sending command: " + command)
	
	# In a real implementation, this would send the command via IPC
	# For now, just demonstrate the concept
	_send_command_to_client(command)
	quit()

func _send_command_to_client(command: String):
	print("📤 Command sent: " + command)
	# This would send the command to the running client via file, network, or IPC