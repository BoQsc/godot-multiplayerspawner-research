extends Node

# Simple test script for Phase 2 registration system
# Run with: godot --headless --script test_registration.gd

var register_system: AccountSystem
var login_identity: LoginIdentity

func _ready():
	print("=== Phase 2 Registration Test Suite ===")
	setup_test_environment()
	test_user_registration()
	test_user_login()
	test_device_binding_disable()
	test_authentication_state()
	print("=== All Registration Tests Complete ===")
	get_tree().quit()

func setup_test_environment():
	print("\n--- Setting Up Test Environment ---")
	
	# Create client identity
	login_identity = LoginIdentity.new()
	add_child(login_identity)
	await get_tree().process_frame
	
	# Create auth system
	register_system = RegisterSystem.new()
	register_system.login_identity = login_identity
	add_child(register_system)
	
	print("✓ Test environment set up")

func test_user_registration():
	print("\n--- Testing User Registration ---")
	
	var test_username = "testuser123"
	var test_password = "testpass456"
	
	# Test registration success
	var result = register_system.register_current_player(test_username, test_password)
	if result:
		print("✓ Registration successful")
	else:
		print("✗ Registration failed!")
		return
	
	# Verify account was created
	if register_system.is_logged_in():
		print("✓ User is logged in after registration")
	else:
		print("✗ User should be logged in after registration!")
	
	# Verify username
	if register_system.get_current_username() == test_username:
		print("✓ Current username matches registered username")
	else:
		print("✗ Username mismatch!")
	
	# Test duplicate registration
	var duplicate_result = register_system.register_current_player(test_username, "different_pass")
	if not duplicate_result:
		print("✓ Duplicate registration correctly rejected")
	else:
		print("✗ Duplicate registration should be rejected!")

func test_user_login():
	print("\n--- Testing User Login ---")
	
	var test_username = "logintest789"
	var test_password = "loginpass321"
	
	# Register first user
	register_system.register_current_player(test_username, test_password)
	
	# Logout
	register_system.logout_current_user()
	if not register_system.is_logged_in():
		print("✓ User logged out successfully")
	else:
		print("✗ User should be logged out!")
	
	# Test successful login
	var login_result = register_system.login_user(test_username, test_password)
	if login_result and register_system.is_logged_in():
		print("✓ Login successful")
	else:
		print("✗ Login should succeed!")
	
	# Test failed login (wrong password)
	register_system.logout_current_user()
	var bad_login = register_system.login_user(test_username, "wrong_password")
	if not bad_login:
		print("✓ Bad password correctly rejected")
	else:
		print("✗ Bad password should be rejected!")
	
	# Test failed login (non-existent user)
	var no_user_login = register_system.login_user("nonexistent", "password")
	if not no_user_login:
		print("✓ Non-existent user correctly rejected")
	else:
		print("✗ Non-existent user should be rejected!")

func test_device_binding_disable():
	print("\n--- Testing Device Binding Auto-Disable ---")
	
	# Check initial device binding state
	if login_identity.is_uuid_device_binding_enabled():
		print("✓ Device binding initially enabled (auto-enabled)")
	else:
		print("✗ Device binding should be auto-enabled for new players!")
	
	# Register user (should disable device binding)
	register_system.register_current_player("devicetest", "password")
	
	# Check device binding after registration
	if not login_identity.is_uuid_device_binding_enabled():
		print("✓ Device binding correctly disabled after registration")
	else:
		print("✗ Device binding should be disabled after registration!")

func test_authentication_state():
	print("\n--- Testing Authentication State Management ---")
	
	# Test anonymous state
	register_system.logout_current_user()
	if login_identity.is_anonymous_player():
		print("✓ Player correctly identified as anonymous when logged out")
	else:
		print("✗ Player should be anonymous when logged out!")
	
	# Test registered state
	register_system.login_user("devicetest", "password")
	if not login_identity.is_anonymous_player():
		print("✓ Player correctly identified as registered when logged in")
	else:
		print("✗ Player should be registered when logged in!")
	
	# Test display username
	var display_name = login_identity.get_display_username()
	if display_name == "devicetest":
		print("✓ Display username shows registered username")
	else:
		print("✗ Display username should show registered username, got: ", display_name)
	
	# Test UUID access
	var uuid_player = login_identity.get_uuid_player_id()
	var auth_uuid = register_system.get_current_uuid_player()
	if uuid_player == auth_uuid:
		print("✓ UUID player ID matches between client identity and auth system")
	else:
		print("✗ UUID mismatch between systems!")

func _exit_tree():
	print("Registration system tests completed.")