extends Node

# Connect Test Client to Your Existing Server
# Bypasses server creation and connects directly as client

func _ready():
	print("=== CONNECTING TO YOUR SERVER ===")
	print("Attempting to join your running local server...")
	print("")
	
	# Wait a moment then connect
	await get_tree().create_timer(1.0).timeout
	_connect_as_client()

func _connect_as_client():
	"""Connect as client to existing server"""
	print("Creating client connection...")
	
	var client_peer = ENetMultiplayerPeer.new()
	var result = client_peer.create_client("127.0.0.1", 4443)
	
	if result == OK:
		print("✅ Client creation successful")
		multiplayer.multiplayer_peer = client_peer
		
		# Wait for connection
		print("Connecting to your server at localhost:4443...")
		var connection_timeout = 10.0
		var start_time = Time.get_ticks_msec()
		
		while client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			await get_tree().process_frame
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			if elapsed > connection_timeout:
				print("❌ Connection timeout after " + str(connection_timeout) + " seconds")
				print("Is your server running on localhost:4443?")
				return
		
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("🎉 SUCCESSFULLY CONNECTED TO YOUR SERVER!")
			print("Client ID: " + str(multiplayer.get_unique_id()))
			print("")
			print("🎮 You should now see a new player in your game!")
			print("")
			_start_walking_demo()
		else:
			print("❌ Connection failed. Status: " + str(client_peer.get_connection_status()))
			print("Make sure your server is running and accepting connections.")
	else:
		print("❌ Failed to create client: " + str(result))

func _start_walking_demo():
	"""Demo walking around your world"""
	print("🚶 Starting walking demo...")
	print("The test client will now walk around your world!")
	print("")
	
	# Simulate player movement
	var positions = [
		Vector2(100, 100),
		Vector2(200, 150),
		Vector2(300, 200),
		Vector2(250, 300),
		Vector2(150, 250),
		Vector2(200, 200)
	]
	
	for pos in positions:
		print("🎯 Walking to position (" + str(pos.x) + ", " + str(pos.y) + ")...")
		
		# Here you would normally call your player movement system
		# For demonstration, we'll just announce the movement
		_simulate_movement(pos)
		
		# Wait between movements
		await get_tree().create_timer(3.0).timeout
	
	print("")
	print("🏁 Walking demo completed!")
	print("The test client should have moved around your game world.")
	print("You can extend this to test pickup collection, interactions, etc.")

func _simulate_movement(position: Vector2):
	"""Simulate moving to a position (placeholder)"""
	print("   📍 Simulating movement to " + str(position))
	
	# In a real implementation, this would:
	# 1. Find the player entity in the game world
	# 2. Update its position
	# 3. Sync with the server
	# 4. Trigger any movement-related game logic
	
	# For now, just show what would happen
	print("   ✅ Movement command sent")
	
	# If you have RPC methods for movement, you could call them here:
	# rpc("move_player", position)

func _on_connected_to_server():
	"""Called when connected to server"""
	print("🔗 Connection established with server!")

func _on_connection_failed():
	"""Called when connection fails"""
	print("💥 Failed to connect to server")

func _on_server_disconnected():
	"""Called when disconnected from server"""
	print("🔌 Disconnected from server")