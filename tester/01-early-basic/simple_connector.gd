extends Node

# Simple connector that just stays connected in one spot

func _ready():
	print("=== SIMPLE CONNECTION TEST ===")
	print("Connecting and staying in one location...")
	
	await get_tree().create_timer(1.0).timeout
	_connect_and_stay()

func _connect_and_stay():
	"""Connect to server and stay put"""
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
			print("✋ Staying connected at spawn location for 2 minutes...")
			print("Look for a new player/entity in your game world!")
			
			# Stay connected for 2 minutes
			await get_tree().create_timer(120.0).timeout
			
			print("⏰ 2 minutes completed - disconnecting")
		else:
			print("❌ Connection failed")
	else:
		print("❌ Failed to create client: " + str(result))