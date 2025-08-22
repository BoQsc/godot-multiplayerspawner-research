extends Node

# Test client that uses the main scene but only connects as client

func _ready():
	print("=== MAIN SCENE CLIENT TEST ===")
	print("Starting as client-only...")
	
	# Wait a moment then connect
	await get_tree().create_timer(2.0).timeout
	_start_as_client()

func _start_as_client():
	"""Start the game manager as a client"""
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		print("✅ Found GameManager - connecting as client...")
		
		# Simulate joining as client
		game_manager._join_as_client("127.0.0.1", 4443)
		
		# Wait for connection
		await get_tree().create_timer(5.0).timeout
		
		print("🔄 Should be connected now! Check your player list.")
		print("Look for a new player in your game world!")
		
		# Stay connected for 2 minutes
		await get_tree().create_timer(120.0).timeout
		print("⏰ 2 minutes completed")
	else:
		print("❌ Could not find GameManager")