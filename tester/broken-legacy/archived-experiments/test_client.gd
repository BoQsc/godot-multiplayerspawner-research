extends Node
class_name TestClient

# CLI Test Client for Multiplayer World Testing
# Usage: Run with --headless flag and connect via stdin commands

const DEFAULT_PORT = 4443
var game_manager: Node
var network_manager: NetworkManager
var world_manager: WorldManager
var is_connected: bool = false
var local_player_id: int = 0
var command_history: Array = []
var auto_commands: Array = []
var auto_command_index: int = 0

# Command processing
var stdin_thread: Thread
var should_process_input: bool = true

func _ready():
	print("=== Multiplayer Test Client ===")
	print("Commands available:")
	print("  connect <ip> [port] - Connect to server")
	print("  disconnect - Disconnect from server")
	print("  move <x> <y> - Move player to position")
	print("  spawn_pickup <type> <x> <y> - Spawn pickup")
	print("  list_players - Show all players")
	print("  list_pickups - Show all pickups")
	print("  save_world - Save world state")
	print("  load_world - Load world state")
	print("  auto <file> - Run commands from file")
	print("  status - Show connection status")
	print("  help - Show this help")
	print("  quit - Exit client")
	print("=====================================")
	
	# Setup core managers
	_setup_managers()
	
	# Start input processing
	_start_input_thread()

func _setup_managers():
	"""Setup core game managers for testing"""
	# Create GameManager if it doesn't exist
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		var gm_scene = load("res://GameManager.tscn")
		if gm_scene:
			game_manager = gm_scene.instantiate()
			get_tree().root.add_child(game_manager)
			game_manager.add_to_group("game_manager")
		else:
			print("ERROR: Could not load GameManager scene")
			return
	
	# Get references to other managers
	network_manager = get_tree().get_first_node_in_group("network_manager")
	world_manager = get_tree().get_first_node_in_group("world_manager")
	
	print("Managers setup completed")

func _start_input_thread():
	"""Start background thread to process stdin input"""
	stdin_thread = Thread.new()
	stdin_thread.start(_input_thread_func)

func _input_thread_func():
	"""Background thread function to read stdin"""
	while should_process_input:
		# Note: In Godot, we can't directly read from stdin in a thread
		# This would need to be implemented differently, possibly using
		# a timer-based approach or external process communication
		OS.delay_msec(100)

func _process(_delta):
	"""Process auto commands and check connection status"""
	if auto_commands.size() > 0 and auto_command_index < auto_commands.size():
		# Process one auto command per frame to avoid blocking
		var command = auto_commands[auto_command_index]
		print("Auto-executing: " + command)
		_process_command(command)
		auto_command_index += 1
		
		if auto_command_index >= auto_commands.size():
			auto_commands.clear()
			auto_command_index = 0
			print("Auto commands completed")

func process_input_command(command_line: String):
	"""Process a command from external input (called by main scene)"""
	_process_command(command_line.strip_edges())

func _process_command(command_line: String):
	"""Process a command string"""
	if command_line.is_empty():
		return
	
	command_history.append(command_line)
	var parts = command_line.split(" ", false)
	var cmd = parts[0].to_lower()
	
	match cmd:
		"connect":
			_cmd_connect(parts)
		"disconnect":
			_cmd_disconnect()
		"move":
			_cmd_move(parts)
		"spawn_pickup":
			_cmd_spawn_pickup(parts)
		"list_players":
			_cmd_list_players()
		"list_pickups":
			_cmd_list_pickups()
		"save_world":
			_cmd_save_world()
		"load_world":
			_cmd_load_world()
		"auto":
			_cmd_auto(parts)
		"status":
			_cmd_status()
		"help":
			_cmd_help()
		"quit":
			_cmd_quit()
		_:
			print("Unknown command: " + cmd + ". Type 'help' for available commands.")

func _cmd_connect(parts: Array):
	"""Connect to server"""
	if parts.size() < 2:
		print("Usage: connect <ip> [port]")
		return
	
	var ip = parts[1]
	var port = DEFAULT_PORT
	if parts.size() > 2:
		port = int(parts[2])
	
	print("Connecting to " + ip + ":" + str(port) + "...")
	
	if game_manager and game_manager.has_method("join_server"):
		game_manager.join_server(ip, port)
		# Wait a moment and check connection
		await get_tree().create_timer(1.0).timeout
		_check_connection_status()
	else:
		print("ERROR: GameManager not available or missing join_server method")

func _cmd_disconnect():
	"""Disconnect from server"""
	print("Disconnecting...")
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	is_connected = false
	local_player_id = 0
	print("Disconnected")

func _cmd_move(parts: Array):
	"""Move local player to position"""
	if not is_connected:
		print("ERROR: Not connected to server")
		return
	
	if parts.size() < 3:
		print("Usage: move <x> <y>")
		return
	
	var x = float(parts[1])
	var y = float(parts[2])
	var new_pos = Vector2(x, y)
	
	print("Moving player to (" + str(x) + ", " + str(y) + ")")
	
	# Find local player and move them
	if game_manager and local_player_id in game_manager.players:
		var player = game_manager.players[local_player_id]
		player.position = new_pos
		# Force network sync
		if network_manager:
			network_manager.force_sync_player(local_player_id)
		print("Player moved to " + str(new_pos))
	else:
		print("ERROR: Local player not found")

func _cmd_spawn_pickup(parts: Array):
	"""Spawn a pickup item"""
	if not is_connected:
		print("ERROR: Not connected to server")
		return
	
	if parts.size() < 4:
		print("Usage: spawn_pickup <type> <x> <y>")
		print("Types: health_potion, star_item, gem_blue")
		return
	
	var item_type = parts[1]
	var x = float(parts[2])
	var y = float(parts[3])
	var spawn_pos = Vector2(x, y)
	
	print("Spawning " + item_type + " at (" + str(x) + ", " + str(y) + ")")
	
	if game_manager and game_manager.has_method("spawn_pickup"):
		var config_data = {}
		match item_type:
			"health_potion":
				config_data["healing_amount"] = 25.0
			"star_item":
				config_data["pickup_value"] = 100.0
			"gem_blue":
				config_data["pickup_value"] = 50.0
		
		var item_id = game_manager.spawn_pickup(item_type, spawn_pos, config_data)
		if item_id != "":
			print("Spawned pickup with ID: " + item_id)
		else:
			print("ERROR: Failed to spawn pickup")
	else:
		print("ERROR: GameManager not available or missing spawn_pickup method")

func _cmd_list_players():
	"""List all connected players"""
	print("=== PLAYERS ===")
	if game_manager and game_manager.players:
		for player_id in game_manager.players:
			var player = game_manager.players[player_id]
			var pos = player.position
			var is_local = (player_id == local_player_id)
			var status = " [LOCAL]" if is_local else " [REMOTE]"
			print("Player " + str(player_id) + ": (" + str(pos.x) + ", " + str(pos.y) + ")" + status)
	else:
		print("No players found")
	print("===============")

func _cmd_list_pickups():
	"""List all pickups in the world"""
	print("=== PICKUPS ===")
	if game_manager and game_manager.pickups:
		for item_id in game_manager.pickups:
			var pickup = game_manager.pickups[item_id]
			var pos = pickup.position
			var type = pickup.item_type
			var value = pickup.pickup_value
			var collected = pickup.is_collected
			var status = " [COLLECTED]" if collected else " [AVAILABLE]"
			print(item_id + " (" + type + "): (" + str(pos.x) + ", " + str(pos.y) + ") value=" + str(value) + status)
	else:
		print("No pickups found")
	print("================")

func _cmd_save_world():
	"""Save world state"""
	print("Saving world state...")
	if world_manager and world_manager.has_method("save_world_data"):
		world_manager.save_world_data()
		print("World saved")
	else:
		print("ERROR: WorldManager not available")

func _cmd_load_world():
	"""Load world state"""
	print("Loading world state...")
	if world_manager and world_manager.has_method("load_world_data"):
		world_manager.load_world_data()
		print("World loaded")
	else:
		print("ERROR: WorldManager not available")

func _cmd_auto(parts: Array):
	"""Load and execute commands from file"""
	if parts.size() < 2:
		print("Usage: auto <filename>")
		return
	
	var filename = parts[1]
	var file_path = "user://" + filename + ".txt"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		auto_commands.clear()
		auto_command_index = 0
		
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if not line.is_empty() and not line.begins_with("#"):
				auto_commands.append(line)
		
		file.close()
		print("Loaded " + str(auto_commands.size()) + " commands from " + filename)
	else:
		print("ERROR: File not found: " + file_path)

func _cmd_status():
	"""Show connection and world status"""
	print("=== STATUS ===")
	print("Connected: " + str(is_connected))
	print("Local Player ID: " + str(local_player_id))
	if multiplayer.multiplayer_peer:
		print("Multiplayer Status: " + str(multiplayer.multiplayer_peer.get_connection_status()))
	else:
		print("Multiplayer Status: NO PEER")
	
	if game_manager:
		print("Players: " + str(game_manager.players.size()))
		print("Pickups: " + str(game_manager.pickups.size()))
		print("NPCs: " + str(game_manager.npcs.size()))
	
	if network_manager:
		var stats = network_manager.get_network_stats()
		print("Network Stats: " + str(stats))
	
	print("===============")

func _cmd_help():
	"""Show help information"""
	print("=== AVAILABLE COMMANDS ===")
	print("connect <ip> [port] - Connect to multiplayer server")
	print("disconnect - Disconnect from server")
	print("move <x> <y> - Move local player to coordinates")
	print("spawn_pickup <type> <x> <y> - Spawn pickup (health_potion, star_item, gem_blue)")
	print("list_players - List all connected players")
	print("list_pickups - List all pickups in world")
	print("save_world - Save current world state")
	print("load_world - Load saved world state")
	print("auto <filename> - Execute commands from user://filename.txt")
	print("status - Show connection and world status")
	print("help - Show this help")
	print("quit - Exit test client")
	print("===========================")

func _cmd_quit():
	"""Exit the test client"""
	print("Exiting test client...")
	should_process_input = false
	if stdin_thread and stdin_thread.is_started():
		stdin_thread.wait_to_finish()
	get_tree().quit()

func _check_connection_status():
	"""Check if connection was successful"""
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		is_connected = true
		local_player_id = multiplayer.get_unique_id()
		print("Connected successfully! Player ID: " + str(local_player_id))
	else:
		is_connected = false
		print("Connection failed")

func _notification(what):
	"""Handle application notifications"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cmd_quit()

# RPC handlers for multiplayer events
func _on_player_connected(peer_id: int):
	print("Player connected: " + str(peer_id))

func _on_player_disconnected(peer_id: int):
	print("Player disconnected: " + str(peer_id))

func _on_pickup_collected(item_id: String, player_id: int):
	print("Pickup collected: " + item_id + " by player " + str(player_id))

func _exit_tree():
	"""Cleanup when exiting"""
	should_process_input = false
	if stdin_thread and stdin_thread.is_started():
		stdin_thread.wait_to_finish()