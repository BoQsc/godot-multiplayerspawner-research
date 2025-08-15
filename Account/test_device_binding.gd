extends Node

# Simple test script for device binding functionality
# Run with: godot --headless --script Account/test_device_binding.gd

func _ready():
	print("=== Device Binding Test Suite ===")
	test_device_fingerprinting()
	test_uuid_binding()
	test_access_control()
	print("=== All Tests Complete ===")
	get_tree().quit()

func test_device_fingerprinting():
	print("\n--- Testing Device Fingerprinting ---")
	
	var device_binding = DeviceBinding.new()
	add_child(device_binding)
	
	var fingerprint = device_binding.get_device_fingerprint()
	print("✓ Generated device fingerprint: ", fingerprint.substr(0, 16), "...")
	
	# Test fingerprint consistency
	var fingerprint2 = device_binding.get_device_fingerprint()
	if fingerprint == fingerprint2:
		print("✓ Device fingerprint is consistent")
	else:
		print("✗ Device fingerprint inconsistent!")
	
	device_binding.queue_free()

func test_uuid_binding():
	print("\n--- Testing UUID Binding ---")
	
	var device_binding = DeviceBinding.new()
	add_child(device_binding)
	
	var test_uuid = "player_test-uuid-12345"
	
	# Test initial state (no binding)
	if device_binding.can_access_uuid_on_this_device(test_uuid):
		print("✓ UUID accessible without binding")
	else:
		print("✗ UUID should be accessible without binding!")
	
	# Enable binding
	device_binding.enable_device_binding(test_uuid, true)
	
	if device_binding.is_device_binding_enabled(test_uuid):
		print("✓ Device binding enabled successfully")
	else:
		print("✗ Device binding not enabled!")
	
	# Test access after binding
	if device_binding.can_access_uuid_on_this_device(test_uuid):
		print("✓ UUID still accessible on same device after binding")
	else:
		print("✗ UUID should be accessible on same device!")
	
	# Disable binding
	device_binding.enable_device_binding(test_uuid, false)
	
	if not device_binding.is_device_binding_enabled(test_uuid):
		print("✓ Device binding disabled successfully")
	else:
		print("✗ Device binding not disabled!")
	
	device_binding.queue_free()

func test_access_control():
	print("\n--- Testing Access Control ---")
	
	var device_binding = DeviceBinding.new()
	add_child(device_binding)
	
	var test_uuid = "player_test-access-67890"
	
	# Simulate binding to different device
	device_binding.anonymous_bindings[test_uuid] = "fake-device-fingerprint-different"
	
	if not device_binding.can_access_uuid_on_this_device(test_uuid):
		print("✓ UUID correctly blocked when bound to different device")
	else:
		print("✗ UUID should be blocked for different device!")
	
	# Test transfer to current device
	device_binding.transfer_uuid_to_this_device(test_uuid)
	
	if device_binding.can_access_uuid_on_this_device(test_uuid):
		print("✓ UUID accessible after transfer to current device")
	else:
		print("✗ UUID should be accessible after transfer!")
	
	# Test statistics
	var stats = device_binding.get_binding_statistics()
	print("✓ Binding statistics: ", stats)
	
	device_binding.queue_free()

func test_login_identity_integration():
	print("\n--- Testing Client Identity Integration ---")
	
	var login_identity = LoginIdentity.new()
	add_child(login_identity)
	
	# Wait for initialization
	await get_tree().process_frame
	
	var uuid_player = login_identity.get_uuid_player_id()
	print("✓ UUID Player ID: ", uuid_player)
	
	# Test device binding toggle
	login_identity.enable_uuid_device_binding(true)
	if login_identity.is_uuid_device_binding_enabled():
		print("✓ Client identity device binding enabled")
	else:
		print("✗ Client identity device binding not enabled!")
	
	# Test access
	if login_identity.can_access_current_uuid():
		print("✓ Can access current UUID through client identity")
	else:
		print("✗ Should be able to access current UUID!")
	
	login_identity.queue_free()

func _exit_tree():
	print("Device binding tests completed.")
