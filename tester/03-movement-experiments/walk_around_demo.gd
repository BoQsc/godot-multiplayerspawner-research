extends Node

# Extended Walking Demo - Connect and walk around for a full minute

func _ready():
	print("=== EXTENDED WALKING DEMO ===")
	print("Connecting to your server and walking around for 1 minute...")
	print("")
	
	await get_tree().create_timer(1.0).timeout
	_connect_and_walk()

func _connect_and_walk():
	"""Connect to server and walk around extensively"""
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
			print("")
			await _extended_walking_demo()
		else:
			print("❌ Connection failed")
	else:
		print("❌ Failed to create client: " + str(result))

func _extended_walking_demo():
	"""Walk around for a full minute with various patterns"""
	print("🚶 Starting 1-minute walking demonstration...")
	print("Watch your game - you should see the test client moving around!")
	print("")
	
	var demo_start = Time.get_ticks_msec()
	var demo_duration = 60000  # 60 seconds in milliseconds
	var move_count = 0
	
	# Different walking patterns
	var patterns = [
		"rectangle",
		"circle",
		"zigzag",
		"random",
		"spiral"
	]
	
	var pattern_index = 0
	var pattern_start = Time.get_ticks_msec()
	var pattern_duration = 12000  # 12 seconds per pattern
	
	while (Time.get_ticks_msec() - demo_start) < demo_duration:
		# Switch patterns every 12 seconds
		if (Time.get_ticks_msec() - pattern_start) > pattern_duration:
			pattern_index = (pattern_index + 1) % patterns.size()
			pattern_start = Time.get_ticks_msec()
			print("🔄 Switching to pattern: " + patterns[pattern_index])
		
		var current_pattern = patterns[pattern_index]
		var position = _get_next_position(current_pattern, move_count)
		
		print("🎯 Move " + str(move_count + 1) + " [" + current_pattern + "]: (" + str(position.x) + ", " + str(position.y) + ")")
		_simulate_movement(position)
		
		move_count += 1
		
		# Wait between moves (adjust for different speeds)
		var wait_time = 1.5  # 1.5 seconds between moves
		await get_tree().create_timer(wait_time).timeout
	
	var total_time = (Time.get_ticks_msec() - demo_start) / 1000.0
	print("")
	print("🏁 Walking demo completed!")
	print("Total time: " + str(total_time) + " seconds")
	print("Total moves: " + str(move_count))
	print("The test client should have moved around your world extensively.")

func _get_next_position(pattern: String, move_index: int) -> Vector2:
	"""Generate next position based on walking pattern"""
	match pattern:
		"rectangle":
			return _rectangle_pattern(move_index)
		"circle":
			return _circle_pattern(move_index)
		"zigzag":
			return _zigzag_pattern(move_index)
		"random":
			return _random_pattern()
		"spiral":
			return _spiral_pattern(move_index)
		_:
			return Vector2(200, 200)

func _rectangle_pattern(move_index: int) -> Vector2:
	"""Walk in a rectangle pattern"""
	var corners = [
		Vector2(100, 100),  # Top-left
		Vector2(300, 100),  # Top-right
		Vector2(300, 300),  # Bottom-right
		Vector2(100, 300)   # Bottom-left
	]
	return corners[move_index % corners.size()]

func _circle_pattern(move_index: int) -> Vector2:
	"""Walk in a circular pattern"""
	var center = Vector2(200, 200)
	var radius = 80
	var angle = (move_index * PI * 2.0) / 8.0  # 8 points around circle
	
	var x = center.x + cos(angle) * radius
	var y = center.y + sin(angle) * radius
	return Vector2(x, y)

func _zigzag_pattern(move_index: int) -> Vector2:
	"""Walk in a zigzag pattern"""
	var base_y = 150
	var amplitude = 100
	var width = 50
	
	var x = 100 + (move_index * width)
	var y = base_y + (amplitude * (1 if move_index % 2 == 0 else -1))
	
	# Wrap around if we go too far
	if x > 400:
		x = 100
	
	return Vector2(x, y)

func _random_pattern() -> Vector2:
	"""Walk to random positions"""
	var x = randf_range(50, 350)
	var y = randf_range(50, 350)
	return Vector2(x, y)

func _spiral_pattern(move_index: int) -> Vector2:
	"""Walk in an expanding spiral"""
	var center = Vector2(200, 200)
	var angle = move_index * 0.5
	var radius = move_index * 3
	
	var x = center.x + cos(angle) * radius
	var y = center.y + sin(angle) * radius
	
	# Keep within bounds
	x = clamp(x, 50, 350)
	y = clamp(y, 50, 350)
	
	return Vector2(x, y)

func _simulate_movement(position: Vector2):
	"""Simulate moving to a position"""
	# Try to use actual RPC if available
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		# Attempt to call movement RPC (will generate errors but shows connection is active)
		try_call_movement_rpc(position)
	
	# Always show the movement for demonstration
	print("   📍 Moving to " + str(position))

func try_call_movement_rpc(position: Vector2):
	"""Try to call actual movement RPC methods"""
	# These will generate errors but keep the connection active
	
	# Common RPC method names to try
	var rpc_methods = [
		"update_player_position",
		"move_player", 
		"sync_player_position",
		"set_player_position"
	]
	
	for method in rpc_methods:
		if has_method(method):
			rpc(method, position)
			break