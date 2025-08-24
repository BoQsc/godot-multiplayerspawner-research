extends Node

# Meet the player at their location

func _ready():
	print("=== MEET PLAYER TEST ===")
	print("Connecting and moving to your location...")
	
	await get_tree().create_timer(1.0).timeout
	_connect_and_meet()

func _connect_and_meet():
	"""Connect to server and move to player location"""
	print("Creating client connection...")
	
	var client_peer = ENetMultiplayerPeer.new()
	var result = client_peer.create_client("127.0.0.1", 4443)
	
	if result == OK:
		print("✅ Client creation successful")
		multiplayer.multiplayer_peer = client_peer
		
		# Wait for connection
		print("Connecting to your server...")
		var connection_timeout = 10.0
		var start_time = Time.get_ticks_msec()
		
		while client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			await get_tree().process_frame
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			if elapsed > connection_timeout:
				print("❌ Connection timeout")
				return
		
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("🎉 CONNECTED! Client ID: " + str(multiplayer.get_unique_id()))
			print("📍 Moving to your location: (315.9, 185.9)")
			await _move_to_player()
		else:
			print("❌ Connection failed")
	else:
		print("❌ Failed to create client: " + str(result))

func _move_to_player():
	"""Move near the player's location and stay there"""
	var your_position = Vector2(315.9, 185.9)
	
	# Move to positions around the player
	var positions = [
		your_position + Vector2(20, 0),    # Right of you
		your_position + Vector2(-20, 0),   # Left of you  
		your_position + Vector2(0, 20),    # Below you
		your_position + Vector2(0, -20),   # Above you
		your_position,                      # Same spot
	]
	
	print("🚶 Moving near your location...")
	print("Look around position (315.9, 185.9) - I should be nearby!")
	
	for i in range(positions.size()):
		var pos = positions[i]
		print("📍 Move " + str(i+1) + ": (" + str(pos.x) + ", " + str(pos.y) + ")")
		_simulate_movement(pos)
		await get_tree().create_timer(3.0).timeout
	
	print("✋ Staying at your location for 1 minute...")
	print("Look for me at position (315.9, 185.9)!")
	
	# Stay at player position for a minute
	for j in range(20):  # 20 movements over 1 minute
		_simulate_movement(your_position)
		await get_tree().create_timer(3.0).timeout
	
	print("⏰ 1 minute completed - disconnecting")

func _simulate_movement(position: Vector2):
	"""Simulate moving to a position"""
	print("   🎯 Moving to (" + str(position.x) + ", " + str(position.y) + ")")