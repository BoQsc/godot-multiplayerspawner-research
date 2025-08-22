extends Node

# Simple Test Runner for basic testing without full game scene dependencies
# Use this for initial testing and validation

func _ready():
	print("=== SIMPLE MULTIPLAYER TESTER ===")
	print("Basic testing without full game scene dependencies")
	print("Commands:")
	print("  test_basic - Test basic functionality")
	print("  test_connections - Test connection logic") 
	print("  validate_setup - Validate test environment")
	print("  help - Show available commands")
	print("=====================================")
	
	# Auto-run basic validation
	_validate_setup()

func _validate_setup():
	"""Validate test environment setup"""
	print("\n--- VALIDATING TEST SETUP ---")
	
	# Check if core files exist
	var required_files = [
		"res://tester/test_client.gd",
		"res://tester/multi_client_tester.gd", 
		"res://tester/automated_test_runner.gd",
		"res://tester/problem_isolator.gd"
	]
	
	var missing_files = []
	for file_path in required_files:
		if not FileAccess.file_exists(file_path):
			missing_files.append(file_path)
	
	if missing_files.is_empty():
		print("✅ All test system files found")
	else:
		print("❌ Missing files:")
		for file_path in missing_files:
			print("   - " + file_path)
	
	# Check if main scene exists
	var main_scene_paths = [
		"res://Main.tscn",
		"res://main_scene.tscn",
		"res://Main Scene.tscn"
	]
	
	var main_scene_found = false
	for scene_path in main_scene_paths:
		if FileAccess.file_exists(scene_path):
			print("✅ Main scene found: " + scene_path)
			main_scene_found = true
			break
	
	if not main_scene_found:
		print("⚠️  Main scene not found - full testing may not work")
		print("   Expected one of: " + str(main_scene_paths))
	
	# Check Godot version compatibility
	var version = Engine.get_version_info()
	print("✅ Godot version: " + str(version.major) + "." + str(version.minor) + "." + str(version.patch))
	
	if version.major >= 4:
		print("✅ Godot 4+ detected - test system compatible")
	else:
		print("⚠️  Godot 3.x detected - some features may not work")
	
	print("--- SETUP VALIDATION COMPLETE ---\n")

func process_command(command: String):
	"""Process simple test commands"""
	var parts = command.split(" ", false)
	var cmd = parts[0].to_lower()
	
	match cmd:
		"test_basic":
			_test_basic()
		"test_connections":
			_test_connections()
		"validate_setup":
			_validate_setup()
		"help":
			_show_help()
		_:
			print("Unknown command: " + cmd + ". Type 'help' for available commands.")

func _test_basic():
	"""Test basic functionality"""
	print("\n--- BASIC FUNCTIONALITY TEST ---")
	
	# Test core classes can be instantiated
	print("Testing core class instantiation...")
	
	var test_client = TestClient.new()
	if test_client:
		print("✅ TestClient class works")
		test_client.queue_free()
	else:
		print("❌ TestClient class failed")
	
	var multi_tester = MultiClientTester.new()
	if multi_tester:
		print("✅ MultiClientTester class works")
		multi_tester.queue_free()
	else:
		print("❌ MultiClientTester class failed")
	
	var auto_runner = AutomatedTestRunner.new()
	if auto_runner:
		print("✅ AutomatedTestRunner class works")
		auto_runner.queue_free()
	else:
		print("❌ AutomatedTestRunner class failed")
	
	var isolator = ProblemIsolator.new()
	if isolator:
		print("✅ ProblemIsolator class works")
		isolator.queue_free()
	else:
		print("❌ ProblemIsolator class failed")
	
	print("--- BASIC TEST COMPLETE ---\n")

func _test_connections():
	"""Test connection-related functionality"""
	print("\n--- CONNECTION TEST ---")
	
	# Test multiplayer peer creation
	var peer = ENetMultiplayerPeer.new()
	if peer:
		print("✅ ENetMultiplayerPeer can be created")
		
		# Test server creation
		var result = peer.create_server(4443, 10)
		if result == OK:
			print("✅ Test server can be created on port 4443")
			peer.close()
		else:
			print("❌ Failed to create test server: " + str(result))
	else:
		print("❌ Failed to create ENetMultiplayerPeer")
	
	print("--- CONNECTION TEST COMPLETE ---\n")

func _show_help():
	"""Show available commands"""
	print("\n--- AVAILABLE COMMANDS ---")
	print("test_basic - Test basic class instantiation")
	print("test_connections - Test connection functionality") 
	print("validate_setup - Validate test environment")
	print("help - Show this help")
	print("-------------------------\n")