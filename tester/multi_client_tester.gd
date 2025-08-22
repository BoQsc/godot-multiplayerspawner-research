extends Node
class_name MultiClientTester

# Multi-Client Test System for Multiplayer Testing
# Spawns multiple headless test clients for comprehensive testing

var test_clients: Array = []
var server_instance: Node = null
var max_clients: int = 10
var client_scenes: Array = []

# Test scenarios
var active_test_scenario: String = ""
var test_results: Dictionary = {}

func _ready():
	print("=== Multi-Client Test System ===")
	print("Commands available:")
	print("  start_server [port] - Start local test server")
	print("  spawn_clients <count> [ip] [port] - Spawn multiple test clients")
	print("  client <id> <command> - Send command to specific client")
	print("  broadcast <command> - Send command to all clients") 
	print("  run_scenario <name> - Run predefined test scenario")
	print("  list_clients - Show all active clients")
	print("  list_scenarios - Show available test scenarios")
	print("  stop_clients - Stop all test clients")
	print("  stop_server - Stop test server")
	print("  results - Show test results")
	print("  help - Show this help")
	print("  quit - Exit tester")
	print("=================================")

func process_command(command_line: String):
	"""Process a command string"""
	if command_line.is_empty():
		return
	
	var parts = command_line.split(" ", false)
	var cmd = parts[0].to_lower()
	
	match cmd:
		"start_server":
			_cmd_start_server(parts)
		"spawn_clients":
			_cmd_spawn_clients(parts)
		"client":
			_cmd_client(parts)
		"broadcast":
			_cmd_broadcast(parts)
		"run_scenario":
			_cmd_run_scenario(parts)
		"list_clients":
			_cmd_list_clients()
		"list_scenarios":
			_cmd_list_scenarios()
		"stop_clients":
			_cmd_stop_clients()
		"stop_server":
			_cmd_stop_server()
		"results":
			_cmd_results()
		"help":
			_cmd_help()
		"quit":
			_cmd_quit()
		_:
			print("Unknown command: " + cmd + ". Type 'help' for available commands.")

func _cmd_start_server(parts: Array):
	"""Start a local test server with its own player"""
	var port = 4443
	if parts.size() > 1:
		port = int(parts[1])
	
	print("Starting test server on port " + str(port) + " with server player...")
	
	# Create a new scene instance for the server
	var server_scene = load("res://main_scene.tscn")
	if not server_scene:
		print("ERROR: Could not load main_scene.tscn")
		return
	
	server_instance = server_scene.instantiate()
	if not server_instance:
		print("ERROR: Could not instantiate server scene")
		return
	
	server_instance.name = "TestServer"
	get_tree().root.add_child(server_instance)
	
	# Wait for initialization then start server
	await get_tree().process_frame
	var server_gm = server_instance.get_node_or_null("GameManager")
	if not server_gm:
		# Try alternative paths
		server_gm = server_instance.get_node_or_null("Game Manager")
		if not server_gm:
			server_gm = server_instance.get_children().filter(func(child): return "game" in child.name.to_lower())
			if server_gm.size() > 0:
				server_gm = server_gm[0]
			else:
				server_gm = null
	
	if server_gm and server_gm.has_method("start_server"):
		server_gm.start_server(port)
		print("Test server started on port " + str(port))
		
		# Add server as a special client entry for tracking
		test_clients.append({
			"id": "server",
			"instance": server_instance,
			"client": null,  # Server doesn't use TestClient
			"connected": true,
			"is_server": true
		})
		
		print("Server player initialized (acts as client 'server')")
	else:
		print("ERROR: Failed to start test server - GameManager not found or missing start_server method")
		if server_gm:
			print("Found node: " + server_gm.name + " but no start_server method")
		else:
			print("GameManager node not found in server scene")

func _cmd_spawn_clients(parts: Array):
	"""Spawn multiple test clients"""
	if parts.size() < 2:
		print("Usage: spawn_clients <count> [ip] [port]")
		return
	
	var count = int(parts[1])
	var ip = "127.0.0.1"
	var port = 4443
	
	if parts.size() > 2:
		ip = parts[2]
	if parts.size() > 3:
		port = int(parts[3])
	
	if count > max_clients:
		print("ERROR: Maximum " + str(max_clients) + " clients allowed")
		return
	
	print("Spawning " + str(count) + " test clients connecting to " + ip + ":" + str(port))
	
	for i in range(count):
		await _spawn_test_client(i, ip, port)
		# Small delay between spawns to avoid overwhelming the server
		await get_tree().create_timer(0.5).timeout
	
	print("Spawned " + str(count) + " test clients")

func _spawn_test_client(client_id: int, ip: String, port: int) -> TestClient:
	"""Spawn a single test client"""
	# Create new scene instance for client
	var client_scene = load("res://main_scene.tscn")
	if not client_scene:
		print("ERROR: Could not load main_scene.tscn for client")
		return null
	
	var client_instance = client_scene.instantiate()
	if not client_instance:
		print("ERROR: Could not instantiate client scene")
		return null
	
	client_instance.name = "TestClient_" + str(client_id)
	get_tree().root.add_child(client_instance)
	
	# Add TestClient script to the scene
	var client_gm = client_instance.get_node_or_null("GameManager")
	if not client_gm:
		# Try alternative paths or use the root
		client_gm = client_instance.get_node_or_null("Game Manager") 
		if not client_gm:
			client_gm = client_instance  # Use root as fallback
	
	var test_client = TestClient.new()
	test_client.name = "TestClient"
	client_gm.add_child(test_client)
	
	# Store reference
	test_clients.append({
		"id": client_id,
		"instance": client_instance,
		"client": test_client,
		"connected": false
	})
	
	# Auto-connect the client
	await get_tree().process_frame
	test_client.process_input_command("connect " + ip + " " + str(port))
	
	print("Spawned test client " + str(client_id))
	return test_client

func _cmd_client(parts: Array):
	"""Send command to specific client or server"""
	if parts.size() < 3:
		print("Usage: client <id|server> <command>")
		print("Example: client 0 move 100 100")
		print("Example: client server spawn_pickup health_potion 150 150")
		return
	
	var client_id_str = parts[1]
	var command = " ".join(parts.slice(2))
	
	# Handle server commands
	if client_id_str == "server":
		var server_data = _find_client("server")
		if server_data:
			print("Sending to server: " + command)
			_execute_server_command(command, server_data.instance)
		else:
			print("ERROR: Server not running")
		return
	
	# Handle regular client commands
	var client_id = int(client_id_str)
	var client_data = _find_client(client_id)
	if client_data:
		print("Sending to client " + str(client_id) + ": " + command)
		if client_data.client:
			client_data.client.process_input_command(command)
		else:
			print("ERROR: Client has no TestClient interface")
	else:
		print("ERROR: Client " + str(client_id) + " not found")

func _cmd_broadcast(parts: Array):
	"""Send command to all clients"""
	if parts.size() < 2:
		print("Usage: broadcast <command>")
		return
	
	var command = " ".join(parts.slice(1))
	print("Broadcasting to all clients: " + command)
	
	for client_data in test_clients:
		if client_data.has("is_server") and client_data.is_server:
			# Send to server
			_execute_server_command(command, client_data.instance)
		elif client_data.client:
			# Send to regular client
			client_data.client.process_input_command(command)

func _cmd_run_scenario(parts: Array):
	"""Run a predefined test scenario"""
	if parts.size() < 2:
		print("Usage: run_scenario <name>")
		_cmd_list_scenarios()
		return
	
	var scenario_name = parts[1]
	active_test_scenario = scenario_name
	test_results[scenario_name] = {"started": Time.get_ticks_msec(), "status": "running"}
	
	match scenario_name:
		"basic_connection":
			await _scenario_basic_connection()
		"movement_sync":
			await _scenario_movement_sync()
		"pickup_competition":
			await _scenario_pickup_competition()
		"world_persistence":
			await _scenario_world_persistence()
		"stress_test":
			await _scenario_stress_test()
		_:
			print("Unknown scenario: " + scenario_name)
			return
	
	test_results[scenario_name]["status"] = "completed"
	test_results[scenario_name]["duration"] = Time.get_ticks_msec() - test_results[scenario_name]["started"]
	print("Scenario '" + scenario_name + "' completed")

func _scenario_basic_connection():
	"""Test basic client connections"""
	print("=== SCENARIO: Basic Connection Test ===")
	
	# Start server
	await _cmd_start_server([])
	await get_tree().create_timer(2.0).timeout
	
	# Spawn 3 clients
	await _spawn_test_client(0, "127.0.0.1", 4443)
	await _spawn_test_client(1, "127.0.0.1", 4443)
	await _spawn_test_client(2, "127.0.0.1", 4443)
	
	# Wait for connections
	await get_tree().create_timer(3.0).timeout
	
	# Check status of all clients
	for client_data in test_clients:
		client_data.client.process_input_command("status")
	
	print("=== Basic Connection Test Complete ===")

func _scenario_movement_sync():
	"""Test player movement synchronization"""
	print("=== SCENARIO: Movement Sync Test ===")
	
	if test_clients.size() < 2:
		print("Need at least 2 clients for movement sync test")
		return
	
	# Move client 0 to different positions
	var positions = [Vector2(100, 100), Vector2(200, 150), Vector2(300, 200)]
	
	for pos in positions:
		test_clients[0].client.process_input_command("move " + str(pos.x) + " " + str(pos.y))
		await get_tree().create_timer(1.0).timeout
		
		# Check if other clients see the movement
		for i in range(1, test_clients.size()):
			test_clients[i].client.process_input_command("list_players")
		await get_tree().create_timer(0.5).timeout
	
	print("=== Movement Sync Test Complete ===")

func _scenario_pickup_competition():
	"""Test pickup collection between multiple clients"""
	print("=== SCENARIO: Pickup Competition Test ===")
	
	if test_clients.size() < 2:
		print("Need at least 2 clients for pickup test")
		return
	
	# Spawn pickups
	test_clients[0].client.process_input_command("spawn_pickup health_potion 150 150")
	test_clients[0].client.process_input_command("spawn_pickup star_item 250 150")
	test_clients[0].client.process_input_command("spawn_pickup gem_blue 350 150")
	
	await get_tree().create_timer(1.0).timeout
	
	# Move clients to compete for pickups
	test_clients[0].client.process_input_command("move 150 150")
	test_clients[1].client.process_input_command("move 250 150")
	if test_clients.size() > 2:
		test_clients[2].client.process_input_command("move 350 150")
	
	await get_tree().create_timer(2.0).timeout
	
	# Check pickup status
	for client_data in test_clients:
		client_data.client.process_input_command("list_pickups")
	
	print("=== Pickup Competition Test Complete ===")

func _scenario_world_persistence():
	"""Test world save/load functionality"""
	print("=== SCENARIO: World Persistence Test ===")
	
	if test_clients.size() < 1:
		print("Need at least 1 client for persistence test")
		return
	
	# Create world state
	test_clients[0].client.process_input_command("spawn_pickup health_potion 100 100")
	test_clients[0].client.process_input_command("spawn_pickup star_item 200 100")
	test_clients[0].client.process_input_command("move 150 100")
	
	await get_tree().create_timer(1.0).timeout
	
	# Save world
	test_clients[0].client.process_input_command("save_world")
	await get_tree().create_timer(1.0).timeout
	
	# Modify world state
	test_clients[0].client.process_input_command("move 300 300")
	await get_tree().create_timer(0.5).timeout
	
	# Load world
	test_clients[0].client.process_input_command("load_world")
	await get_tree().create_timer(1.0).timeout
	
	# Check if state was restored
	test_clients[0].client.process_input_command("status")
	test_clients[0].client.process_input_command("list_pickups")
	
	print("=== World Persistence Test Complete ===")

func _scenario_stress_test():
	"""Stress test with multiple clients and rapid actions"""
	print("=== SCENARIO: Stress Test ===")
	
	# Spawn maximum clients
	var stress_client_count = min(5, max_clients)
	for i in range(test_clients.size(), stress_client_count):
		await _spawn_test_client(i, "127.0.0.1", 4443)
		await get_tree().create_timer(0.2).timeout
	
	# Rapid movement and pickup spawning
	for round in range(10):
		print("Stress test round " + str(round + 1) + "/10")
		
		# All clients move randomly
		for client_data in test_clients:
			var x = randf_range(0, 500)
			var y = randf_range(0, 300)
			client_data.client.process_input_command("move " + str(x) + " " + str(y))
		
		# Spawn random pickups
		if test_clients.size() > 0:
			var types = ["health_potion", "star_item", "gem_blue"]
			var type = types[randi() % types.size()]
			var x = randf_range(50, 450)
			var y = randf_range(50, 250)
			test_clients[0].client.process_input_command("spawn_pickup " + type + " " + str(x) + " " + str(y))
		
		await get_tree().create_timer(0.5).timeout
	
	# Final status check
	for client_data in test_clients:
		client_data.client.process_input_command("status")
	
	print("=== Stress Test Complete ===")

func _cmd_list_clients():
	"""List all active test clients and server"""
	print("=== ACTIVE CLIENTS ===")
	for client_data in test_clients:
		var status = "CONNECTED" if client_data.connected else "DISCONNECTED"
		var client_type = " [SERVER]" if client_data.has("is_server") and client_data.is_server else " [CLIENT]"
		print("Client " + str(client_data.id) + ": " + status + client_type)
	print("Total: " + str(test_clients.size()) + " instances")
	print("======================")

func _cmd_list_scenarios():
	"""List available test scenarios"""
	print("=== TEST SCENARIOS ===")
	print("basic_connection - Test client connections")
	print("movement_sync - Test player movement synchronization")
	print("pickup_competition - Test pickup collection between clients")
	print("world_persistence - Test save/load functionality")
	print("stress_test - Stress test with multiple rapid actions")
	print("======================")

func _cmd_stop_clients():
	"""Stop all test clients"""
	print("Stopping all test clients...")
	for client_data in test_clients:
		if client_data.instance:
			client_data.instance.queue_free()
	test_clients.clear()
	print("All clients stopped")

func _cmd_stop_server():
	"""Stop the test server"""
	if server_instance:
		print("Stopping test server...")
		server_instance.queue_free()
		server_instance = null
		print("Test server stopped")
	else:
		print("No test server running")

func _cmd_results():
	"""Show test results"""
	print("=== TEST RESULTS ===")
	if test_results.is_empty():
		print("No test results available")
	else:
		for scenario in test_results:
			var result = test_results[scenario]
			var duration = result.get("duration", 0) / 1000.0
			print(scenario + ": " + result.status + " (" + str(duration) + "s)")
	print("====================")

func _cmd_help():
	"""Show help information"""
	print("=== MULTI-CLIENT TESTER COMMANDS ===")
	print("start_server [port] - Start local test server")
	print("spawn_clients <count> [ip] [port] - Spawn multiple test clients")
	print("client <id> <command> - Send command to specific client")
	print("broadcast <command> - Send command to all clients")
	print("run_scenario <name> - Run predefined test scenario")
	print("list_clients - Show all active clients")
	print("list_scenarios - Show available test scenarios")
	print("stop_clients - Stop all test clients")
	print("stop_server - Stop test server")
	print("results - Show test results")
	print("help - Show this help")
	print("quit - Exit tester")
	print("=====================================")

func _cmd_quit():
	"""Exit the multi-client tester"""
	print("Shutting down multi-client tester...")
	_cmd_stop_clients()
	_cmd_stop_server()
	get_tree().quit()

func _execute_server_command(command: String, server_instance: Node):
	"""Execute a command on the server instance"""
	var parts = command.split(" ", false)
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	var server_gm = server_instance.get_node_or_null("GameManager")
	if not server_gm:
		server_gm = server_instance.get_node_or_null("Game Manager")
		if not server_gm:
			var children = server_instance.get_children().filter(func(child): return "game" in child.name.to_lower())
			if children.size() > 0:
				server_gm = children[0]
	
	if not server_gm:
		print("ERROR: Server GameManager not found")
		return
	
	match cmd:
		"spawn_pickup":
			if parts.size() >= 4:
				var item_type = parts[1]
				var x = float(parts[2])
				var y = float(parts[3])
				var spawn_pos = Vector2(x, y)
				
				var config_data = {}
				match item_type:
					"health_potion":
						config_data["healing_amount"] = 25.0
					"star_item":
						config_data["pickup_value"] = 100.0
					"gem_blue":
						config_data["pickup_value"] = 50.0
				
				var item_id = server_gm.spawn_pickup(item_type, spawn_pos, config_data)
				print("Server spawned pickup: " + item_id + " at " + str(spawn_pos))
			else:
				print("Usage: spawn_pickup <type> <x> <y>")
		
		"list_players":
			print("=== SERVER PLAYERS ===")
			if server_gm.players:
				for player_id in server_gm.players:
					var player = server_gm.players[player_id]
					var pos = player.position
					print("Player " + str(player_id) + ": (" + str(pos.x) + ", " + str(pos.y) + ") [SERVER]")
			else:
				print("No players on server")
			print("======================")
		
		"list_pickups":
			print("=== SERVER PICKUPS ===")
			if server_gm.pickups:
				for item_id in server_gm.pickups:
					var pickup = server_gm.pickups[item_id]
					var pos = pickup.position
					var type = pickup.item_type
					var collected = pickup.is_collected
					var status = " [COLLECTED]" if collected else " [AVAILABLE]"
					print(item_id + " (" + type + "): " + str(pos) + status + " [SERVER]")
			else:
				print("No pickups on server")
			print("======================")
		
		"status":
			print("=== SERVER STATUS ===")
			print("Players: " + str(server_gm.players.size()))
			print("Pickups: " + str(server_gm.pickups.size()))
			print("NPCs: " + str(server_gm.npcs.size()))
			if multiplayer.multiplayer_peer:
				print("Server Status: " + str(multiplayer.multiplayer_peer.get_connection_status()))
			print("=====================")
		
		_:
			print("Unknown server command: " + cmd)
			print("Available: spawn_pickup, list_players, list_pickups, status")

func _find_client(client_id) -> Dictionary:
	"""Find client data by ID (supports int or string)"""
	for client_data in test_clients:
		if client_data.id == client_id:
			return client_data
	return {}

func _exit_tree():
	"""Cleanup when exiting"""
	_cmd_stop_clients()
	_cmd_stop_server()