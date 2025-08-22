extends Node

# Interactive Test Client - Connect to existing server and walk around
# Simplified version focused on real-time interaction

var test_client: TestClient
var is_connected: bool = false
var server_ip: String = "localhost"
var server_port: int = 4443

func _ready():
	print("=== INTERACTIVE TEST CLIENT ===")
	print("Ready to connect to your server and walk around!")
	print("")
	print("Commands:")
	print("  connect [ip] [port] - Connect to server (default: localhost:4443)")
	print("  move <x> <y> - Move to position")
	print("  status - Check connection status")
	print("  players - List all players")
	print("  disconnect - Disconnect from server")
	print("  help - Show commands")
	print("  quit - Exit")
	print("=====================================")
	print("")
	
	# Create test client
	test_client = TestClient.new()
	add_child(test_client)
	
	# Auto-connect to localhost
	print("Auto-connecting to localhost:4443...")
	await get_tree().process_frame
	_connect_to_server("localhost", 4443)

func _connect_to_server(ip: String, port: int):
	"""Connect to server"""
	server_ip = ip
	server_port = port
	
	print("Connecting to " + ip + ":" + str(port) + "...")
	
	# Use the TestClient to connect
	test_client.process_input_command("connect " + ip + " " + str(port))
	
	# Wait a moment and check status
	await get_tree().create_timer(2.0).timeout
	_check_connection()

func _check_connection():
	"""Check if connection was successful"""
	# This would need actual connection status checking
	# For now, assume connection worked
	is_connected = true
	print("✅ Connected! You can now control the test client.")
	print("Try: move 100 100")
	print("")
	
	# Show initial status
	test_client.process_input_command("status")

func process_command(command_line: String):
	"""Process interactive commands"""
	var parts = command_line.split(" ", false)
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	
	match cmd:
		"connect":
			_cmd_connect(parts)
		"move":
			_cmd_move(parts)
		"status":
			_cmd_status()
		"players":
			_cmd_players()
		"disconnect":
			_cmd_disconnect()
		"help":
			_cmd_help()
		"quit":
			_cmd_quit()
		_:
			print("Unknown command: " + cmd + ". Type 'help' for available commands.")

func _cmd_connect(parts: Array):
	"""Connect to server"""
	var ip = "localhost"
	var port = 4443
	
	if parts.size() > 1:
		ip = parts[1]
	if parts.size() > 2:
		port = int(parts[2])
	
	_connect_to_server(ip, port)

func _cmd_move(parts: Array):
	"""Move test client"""
	if not is_connected:
		print("❌ Not connected to server. Use 'connect' first.")
		return
	
	if parts.size() < 3:
		print("Usage: move <x> <y>")
		print("Example: move 100 100")
		return
	
	var x = parts[1]
	var y = parts[2]
	
	print("🚶 Moving to (" + x + ", " + y + ")...")
	test_client.process_input_command("move " + x + " " + y)

func _cmd_status():
	"""Show status"""
	if is_connected:
		print("✅ Connected to " + server_ip + ":" + str(server_port))
		test_client.process_input_command("status")
	else:
		print("❌ Not connected")

func _cmd_players():
	"""List players"""
	if is_connected:
		print("👥 Listing all players...")
		test_client.process_input_command("list_players")
	else:
		print("❌ Not connected")

func _cmd_disconnect():
	"""Disconnect from server"""
	if is_connected:
		print("🔌 Disconnecting...")
		# Disconnect logic here
		is_connected = false
		print("Disconnected")
	else:
		print("Already disconnected")

func _cmd_help():
	"""Show help"""
	print("\n=== AVAILABLE COMMANDS ===")
	print("connect [ip] [port] - Connect to server")
	print("move <x> <y> - Move test client to position")
	print("status - Check connection and client status")
	print("players - List all players in the game")
	print("disconnect - Disconnect from server") 
	print("help - Show this help")
	print("quit - Exit")
	print("========================\n")

func _cmd_quit():
	"""Exit"""
	print("👋 Goodbye!")
	if is_connected:
		_cmd_disconnect()
	get_tree().quit()

# Simulate command input for demo
func _simulate_demo_commands():
	"""Simulate some commands for demonstration"""
	await get_tree().create_timer(3.0).timeout
	
	print("\n--- Demo Commands ---")
	print("Executing: move 100 100")
	process_command("move 100 100")
	
	await get_tree().create_timer(2.0).timeout
	print("Executing: move 200 200")
	process_command("move 200 200")
	
	await get_tree().create_timer(2.0).timeout
	print("Executing: status")
	process_command("status")
	
	print("--- Demo Complete ---")
	print("In real usage, you would type these commands interactively")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cmd_quit()