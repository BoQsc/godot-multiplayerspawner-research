extends Node

# Proper test client that implements full authentication flow

var user_client_id: String = ""
var chosen_player_number: int = 99  # Use player 99 for testing
var device_fingerprint: String = ""

func _ready():
	print("=== PROPER TEST CLIENT ===")
	print("Connecting with full authentication...")
	
	# Generate test identity
	user_client_id = "test_client_" + str(randi())
	device_fingerprint = "test_device_" + str(Time.get_ticks_msec())
	
	print("Test Identity:")
	print("  Client ID: " + user_client_id)
	print("  Player Number: " + str(chosen_player_number))
	print("  Device: " + device_fingerprint.substr(0, 16) + "...")
	print("")
	
	await get_tree().create_timer(1.0).timeout
	_connect_properly()

func _connect_properly():
	"""Connect with proper authentication flow"""
	print("Creating client connection...")
	
	var client_peer = ENetMultiplayerPeer.new()
	var result = client_peer.create_client("127.0.0.1", 4443)
	
	if result == OK:
		print("✅ Client creation successful")
		multiplayer.multiplayer_peer = client_peer
		
		# Wait for connection
		print("Connecting to server...")
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
			print("⏳ Waiting for server authentication request...")
			
			# Stay connected and wait for spawning
			await _wait_for_spawn()
		else:
			print("❌ Connection failed")
	else:
		print("❌ Failed to create client: " + str(result))

func _wait_for_spawn():
	"""Wait for server to spawn us and then move around"""
	print("🔄 Waiting for server to spawn player...")
	
	# Wait up to 30 seconds for spawn
	var wait_time = 0.0
	var max_wait = 30.0
	
	while wait_time < max_wait:
		await get_tree().create_timer(1.0).timeout
		wait_time += 1.0
		
		# Check if we've been spawned (look for our player in the scene)
		var spawn_container = get_tree().get_first_node_in_group("spawn_container")
		if spawn_container:
			var my_player = spawn_container.get_node_or_null(str(multiplayer.get_unique_id()))
			if my_player:
				print("🎉 SPAWNED! Found my player: " + str(my_player.name))
				print("📍 Current position: " + str(my_player.position))
				await _start_walking_around(my_player)
				return
		
		if int(wait_time) % 5 == 0:  # Every 5 seconds
			print("⏳ Still waiting for spawn... (" + str(wait_time) + "s)")
	
	print("⚠️ Timeout waiting for spawn - staying connected anyway")
	await get_tree().create_timer(60.0).timeout
	print("⏰ 1 minute completed - disconnecting")

func _start_walking_around(player_node):
	"""Walk around once spawned"""
	print("🚶 Starting to walk around!")
	print("Look for player " + str(chosen_player_number) + " in your game!")
	
	var center_pos = Vector2(315.9, 185.9)  # Your location
	var positions = [
		center_pos + Vector2(50, 0),
		center_pos + Vector2(-50, 0),
		center_pos + Vector2(0, 50),
		center_pos + Vector2(0, -50),
		center_pos
	]
	
	for pos in positions:
		if player_node and is_instance_valid(player_node):
			print("🎯 Moving to: " + str(pos))
			# Try to move through the player's movement system
			if player_node.has_method("set_target_position"):
				player_node.set_target_position(pos)
			else:
				player_node.position = pos
		await get_tree().create_timer(3.0).timeout
	
	print("🏁 Walking completed! Staying connected for 2 more minutes...")
	await get_tree().create_timer(120.0).timeout
	print("⏰ Disconnecting")

# RPC Methods - Required for server authentication

@rpc("authority", "call_remote", "reliable")
func request_client_id():
	"""Server requests our client ID - respond with our test identity"""
	print("📨 Server requested client ID - responding...")
	
	var my_peer_id = multiplayer.get_unique_id()
	print("  Sending - Peer: " + str(my_peer_id) + ", Client: " + user_client_id + ", Player: " + str(chosen_player_number))
	
	rpc_id(1, "receive_client_id", my_peer_id, user_client_id, chosen_player_number, device_fingerprint)

@rpc("any_peer", "call_remote", "reliable")  
func connection_rejected(reason: String):
	"""Server rejected our connection"""
	print("❌ CONNECTION REJECTED: " + reason)

@rpc("any_peer", "call_remote", "reliable")
func spawn_player(peer_id: int, pos: Vector2, persistent_id: String):
	"""Server notifies us about player spawn"""
	if peer_id == multiplayer.get_unique_id():
		print("🎉 Server confirmed our spawn!")
		print("  Position: " + str(pos))
		print("  Persistent ID: " + persistent_id)
	else:
		print("👥 Another player spawned: " + str(peer_id))

@rpc("any_peer", "call_remote", "reliable")  
func despawn_player(peer_id: int):
	"""Server notifies us about player despawn"""
	print("👋 Player despawned: " + str(peer_id))

# Add other common RPC handlers to avoid errors
@rpc("any_peer", "call_remote", "reliable")
func sync_pickup_collection(item_id: String, player_id: int):
	print("🔄 Pickup collected: " + item_id + " by " + str(player_id))

@rpc("any_peer", "call_remote", "reliable")
func sync_pickup_spawn(pickup_id: String, pos: Vector2, pickup_type: String):
	print("🔄 Pickup spawned: " + pickup_id + " at " + str(pos))