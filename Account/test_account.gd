extends Node

# Simple test script for Phase 2 registration system
# Run with: godot --headless --script Account/test_account.gd

var register: Register
var login: Login
var user_identity: UserIdentity

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
	
	# Create user identity
	user_identity = UserIdentity.new()
	add_child(user_identity)
	await get_tree().process_frame
	
	# Create register system
	register = Register.new()
	register.user_identity = user_identity
	add_child(register)
	
	# Create login system
	login = Login.new()
	login.register = register
	login.user_identity = user_identity
	add_child(login)
	
	print("✓ Test environment set up")

func test_user_registration():
	print("\n--- Testing User Registration ---")
	
	var test_username = "testuser123"
	var test_password = "testpass456"
	
	# Test registration success
	var result = register.register_current_player(test_username, test_password)
	if result:
		print("✓ Registration successful")
	else:
		print("✗ Registration failed!")
		return
	
	# Verify account was created
	if login.is_logged_in():
		print("✓ User is logged in after registration")
	else:
		print("✗ User should be logged in after registration!")
	
	# Verify username
	if login.get_current_username() == test_username:
		print("✓ Current username matches registered username")
	else:
		print("✗ Username mismatch!")
	
	# Test duplicate registration
	var duplicate_result = register.register_current_player(test_username, "different_pass")
	if not duplicate_result:
		print("✓ Duplicate registration correctly rejected")
	else:
		print("✗ Duplicate registration should be rejected!")

func test_user_login():
	print("\n--- Testing User Login ---")
	
	var test_username = "logintest789"
	var test_password = "loginpass321"
	
	# Register first user
	register.register_current_player(test_username, test_password)
	
	# Logout
	login.logout_current_user()
	if not login.is_logged_in():
		print("✓ User logged out successfully")
	else:
		print("✗ User should be logged out!")
	
	# Test successful login
	var login_result = login.login_user(test_username, test_password)
	if login_result and login.is_logged_in():
		print("✓ Login successful")
	else:
		print("✗ Login should succeed!")
	
	# Test failed login (wrong password)
	login.logout_current_user()
	var bad_login = login.login_user(test_username, "wrong_password")
	if not bad_login:
		print("✓ Bad password correctly rejected")
	else:
		print("✗ Bad password should be rejected!")
	
	# Test failed login (non-existent user)
	var no_user_login = login.login_user("nonexistent", "password")
	if not no_user_login:
		print("✓ Non-existent user correctly rejected")
	else:
		print("✗ Non-existent user should be rejected!")

func test_device_binding_disable():
	print("\n--- Testing Device Binding Auto-Disable ---")
	
	# Check initial device binding state
	if user_identity.is_uuid_device_binding_enabled():
		print("✓ Device binding initially enabled (auto-enabled)")
	else:
		print("✗ Device binding should be auto-enabled for new players!")
	
	# Register user (should disable device binding)
	register.register_current_player("devicetest", "password")
	
	# Check device binding after registration
	if not user_identity.is_uuid_device_binding_enabled():
		print("✓ Device binding correctly disabled after registration")
	else:
		print("✗ Device binding should be disabled after registration!")

func test_authentication_state():
	print("\n--- Testing Authentication State Management ---")
	
	# Test anonymous state
	login.logout_current_user()
	if user_identity.is_anonymous_player():
		print("✓ Player correctly identified as anonymous when logged out")
	else:
		print("✗ Player should be anonymous when logged out!")
	
	# Test registered state
	login.login_user("devicetest", "password")
	if not user_identity.is_anonymous_player():
		print("✓ Player correctly identified as registered when logged in")
	else:
		print("✗ Player should be registered when logged in!")
	
	# Test display username
	var display_name = user_identity.get_display_username()
	if display_name == "devicetest":
		print("✓ Display username shows registered username")
	else:
		print("✗ Display username should show registered username, got: ", display_name)
	
	# Test UUID access
	var uuid_player = user_identity.get_uuid_player_id()
	var auth_uuid = login.get_current_uuid_player()
	if uuid_player == auth_uuid:
		print("✓ UUID player ID matches between user identity and auth system")
	else:
		print("✗ UUID mismatch between systems!")

func _exit_tree():
	print("Registration system tests completed.")