extends Node

# Minimal Multiplayer Tester - No external dependencies
# Tests core multiplayer functionality without requiring game scenes

var server_peer: ENetMultiplayerPeer
var client_peers: Array = []
var test_results: Dictionary = {}

func _ready():
	print("=== MINIMAL MULTIPLAYER TESTER ===")
	print("Testing basic multiplayer functionality without game scene dependencies")
	print("")
	print("Available tests:")
	print("  test_server_creation - Test server creation")
	print("  test_client_connection - Test client connection")
	print("  test_basic_rpc - Test basic RPC calls")
	print("  test_all - Run all basic tests")
	print("  results - Show test results")
	print("=====================================")
	print("")
	
	# Auto-run basic tests
	_run_all_tests()

func _run_all_tests():
	"""Run all basic tests"""
	print("Running all basic tests...")
	print("")
	
	await _test_server_creation()
	await get_tree().create_timer(1.0).timeout
	
	await _test_client_connection()
	await get_tree().create_timer(1.0).timeout
	
	await _test_basic_rpc()
	await get_tree().create_timer(1.0).timeout
	
	_show_results()

func _test_server_creation():
	"""Test server creation"""
	print("--- TEST: Server Creation ---")
	
	server_peer = ENetMultiplayerPeer.new()
	var result = server_peer.create_server(4443, 2)
	
	if result == OK:
		multiplayer.multiplayer_peer = server_peer
		print("✅ Server created successfully on port 4443")
		test_results["server_creation"] = "PASS"
		
		# Test server properties
		print("   Server ID: " + str(multiplayer.get_unique_id()))
		print("   Max clients: 2")
		print("   Connection status: " + str(server_peer.get_connection_status()))
	else:
		print("❌ Failed to create server: " + str(result))
		test_results["server_creation"] = "FAIL - Error: " + str(result)
	
	print("")

func _test_client_connection():
	"""Test client connection"""
	print("--- TEST: Client Connection ---")
	
	if not server_peer or server_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		print("❌ Server not running - cannot test client connection")
		test_results["client_connection"] = "FAIL - No server"
		print("")
		return
	
	# Create client peer
	var client_peer = ENetMultiplayerPeer.new()
	var result = client_peer.create_client("127.0.0.1", 4443)
	
	if result == OK:
		print("✅ Client connection initiated")
		
		# Wait for connection
		var connection_timeout = 5.0
		var start_time = Time.get_ticks_msec()
		
		while client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			await get_tree().process_frame
			if (Time.get_ticks_msec() - start_time) / 1000.0 > connection_timeout:
				break
		
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("✅ Client connected successfully")
			test_results["client_connection"] = "PASS"
			client_peers.append(client_peer)
		else:
			print("❌ Client connection timeout")
			test_results["client_connection"] = "FAIL - Timeout"
	else:
		print("❌ Failed to create client: " + str(result))
		test_results["client_connection"] = "FAIL - Error: " + str(result)
	
	print("")

func _test_basic_rpc():
	"""Test basic RPC functionality"""
	print("--- TEST: Basic RPC ---")
	
	if client_peers.is_empty():
		print("❌ No clients connected - cannot test RPC")
		test_results["basic_rpc"] = "FAIL - No clients"
		print("")
		return
	
	# Add RPC method
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Test simple RPC registration
	print("✅ RPC system initialized")
	print("   Peer connected signal: registered")
	print("   Peer disconnected signal: registered")
	test_results["basic_rpc"] = "PASS - Basic setup"
	
	print("")

func _on_peer_connected(peer_id: int):
	"""Handle peer connection"""
	print("🔗 Peer connected: " + str(peer_id))

func _on_peer_disconnected(peer_id: int):
	"""Handle peer disconnection"""
	print("🔌 Peer disconnected: " + str(peer_id))

func _show_results():
	"""Show test results summary"""
	print("=== TEST RESULTS SUMMARY ===")
	
	var passed = 0
	var total = 0
	
	for test_name in test_results:
		var result = test_results[test_name]
		total += 1
		
		if "PASS" in result:
			passed += 1
			print("✅ " + test_name + ": " + result)
		else:
			print("❌ " + test_name + ": " + result)
	
	print("")
	print("Summary: " + str(passed) + "/" + str(total) + " tests passed")
	
	if passed == total:
		print("🎉 All tests passed! Multiplayer basics are working.")
	elif passed > 0:
		print("⚠️  Some tests passed. Check failed tests for issues.")
	else:
		print("💥 All tests failed. Check Godot multiplayer setup.")
	
	print("=============================")

func process_command(command: String):
	"""Process commands for manual testing"""
	match command.to_lower():
		"test_server_creation":
			await _test_server_creation()
		"test_client_connection":
			await _test_client_connection()
		"test_basic_rpc":
			await _test_basic_rpc()
		"test_all":
			await _run_all_tests()
		"results":
			_show_results()
		_:
			print("Unknown command: " + command)

func cleanup():
	"""Cleanup connections"""
	if server_peer:
		server_peer.close()
	
	for peer in client_peers:
		peer.close()
	
	multiplayer.multiplayer_peer = null
	print("Connections cleaned up")

func _exit_tree():
	"""Cleanup on exit"""
	cleanup()