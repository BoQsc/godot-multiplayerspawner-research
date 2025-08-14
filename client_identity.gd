extends Node
class_name ClientIdentity

# Client identity management with device binding support for anonymous players

const CLIENT_ID_FILE_SERVER = "user://server_identity.dat"
var client_identity_file: String

var client_id: String = ""
var is_server_role: bool = false
var device_binding: DeviceBinding

# Device binding settings for anonymous players
var device_binding_enabled: bool = false
var uuid_player_id: String = ""

func _ready():
	# Initialize device binding system
	device_binding = DeviceBinding.new()
	add_child(device_binding)
	
	# Detect if we're running as server or client
	is_server_role = "--server" in OS.get_cmdline_args()
	
	# Check for manual player selection first
	var chosen_player = get_chosen_player_from_args()
	if chosen_player != -1:
		# User manually chose which player to be
		if is_server_role:
			client_identity_file = "user://server_player_" + str(chosen_player) + ".dat"
		else:
			client_identity_file = "user://client_player_" + str(chosen_player) + ".dat"
		print("ClientIdentity: User chose to be player ", chosen_player)
	else:
		# Fallback to automatic assignment
		if is_server_role:
			client_identity_file = CLIENT_ID_FILE_SERVER
		else:
			var client_slot = claim_next_available_client_slot()
			client_identity_file = "user://client_slot_" + str(client_slot) + ".dat"
			print("ClientIdentity: Auto-assigned client slot ", client_slot)
	
	load_or_create_client_id()
	setup_device_binding_for_uuid()

func get_chosen_player_from_args() -> int:
	# Check command line for --player=X (supports any positive integer)
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--player="):
			var player_num = int(arg.split("=")[1])
			if player_num >= 1:  # Accept any positive number
				return player_num
	return -1

func claim_next_available_client_slot() -> int:
	# Find the first available slot (1, 2, 3, 4...)
	for slot in range(1, 1000):  # Support up to 999 clients
		var slot_file = "user://client_slot_" + str(slot) + ".dat"
		if not FileAccess.file_exists(slot_file):
			# This slot is available
			return slot
	
	# All slots have files, return next number
	return 1000


func load_or_create_client_id():
	var identity_file = client_identity_file
	
	if FileAccess.file_exists(identity_file):
		# Load existing client ID
		var file = FileAccess.open(identity_file, FileAccess.READ)
		if file:
			var stored_data = file.get_as_text()
			file.close()
			client_id = stored_data.strip_edges()
			print("ClientIdentity: Loaded existing ID: ", client_id)
			return
	
	# Generate new client ID
	var role_prefix = "server_" if is_server_role else "client_"
	client_id = role_prefix + generate_random_id()
	save_client_id()
	print("ClientIdentity: Created new ID: ", client_id)

func generate_random_id() -> String:
	# Generate UUID v4 (random) - industry standard unique identifier
	return generate_uuid_v4()

func generate_uuid_v4() -> String:
	# UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
	# where x is random hex digit, y is 8,9,A,B
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid += "-"
		
		if i == 12:
			# Version 4 identifier
			uuid += "4"
		elif i == 16:
			# Variant bits (10xx)
			uuid += ["8", "9", "a", "b"][randi() % 4]
		else:
			uuid += hex_chars[randi() % 16]
	
	return uuid

func save_client_id():
	var identity_file = client_identity_file
	var file = FileAccess.open(identity_file, FileAccess.WRITE)
	if file:
		file.store_string(client_id)
		file.close()
		print("ClientIdentity: Saved client ID to file")
	else:
		print("ClientIdentity: Failed to save client ID")

func get_client_id() -> String:
	return client_id

func get_display_name() -> String:
	# For now, just return the client ID
	# Later this could be expanded to allow custom usernames
	return client_id

func get_chosen_player_number() -> int:
	# Return the chosen player number if one was specified
	return get_chosen_player_from_args()

# Device binding functions for anonymous players
func setup_device_binding_for_uuid():
	"""Setup device binding for the current UUID player"""
	# Extract UUID from client_id for device binding
	if client_id.begins_with("client_") or client_id.begins_with("server_"):
		uuid_player_id = "player_" + client_id.split("_", false, 1)[1]
	else:
		uuid_player_id = "player_" + client_id
	
	# Check if device binding is enabled for this UUID
	device_binding_enabled = device_binding.is_device_binding_enabled(uuid_player_id)
	
	# AUTO-ENABLE device binding for new anonymous players
	if not device_binding_enabled:
		device_binding.enable_device_binding(uuid_player_id, true)
		device_binding_enabled = true
		print("ClientIdentity: Auto-enabled device binding for new anonymous player")
	
	print("ClientIdentity: UUID player ID: ", uuid_player_id)
	print("ClientIdentity: Device binding enabled: ", device_binding_enabled)

func can_access_current_uuid() -> bool:
	"""Check if current device can access this UUID player"""
	if not device_binding:
		return true
	return device_binding.can_access_uuid_on_this_device(uuid_player_id)

func enable_uuid_device_binding(enabled: bool):
	"""Enable or disable device binding for current UUID player"""
	if device_binding:
		device_binding_enabled = enabled
		device_binding.enable_device_binding(uuid_player_id, enabled)
		print("ClientIdentity: Device binding ", "enabled" if enabled else "disabled", " for ", uuid_player_id)

func is_uuid_device_binding_enabled() -> bool:
	"""Check if device binding is enabled for current UUID"""
	return device_binding_enabled

func get_device_binding_info() -> Dictionary:
	"""Get device binding information for current UUID"""
	if device_binding:
		return device_binding.get_bound_device_info(uuid_player_id)
	return {"bound": false, "device_fingerprint": "", "is_current_device": true}

func transfer_uuid_to_this_device():
	"""Transfer UUID player to current device (for device migration)"""
	if device_binding:
		device_binding.transfer_uuid_to_this_device(uuid_player_id)
		device_binding_enabled = true
		print("ClientIdentity: Transferred ", uuid_player_id, " to current device")

func get_uuid_player_id() -> String:
	"""Get the UUID player ID for this client"""
	return uuid_player_id

func disable_device_binding_after_registration():
	"""Disable device binding after successful registration/login"""
	if device_binding and device_binding_enabled:
		device_binding.enable_device_binding(uuid_player_id, false)
		device_binding_enabled = false
		print("ClientIdentity: Device binding disabled after registration/login")
		print("ClientIdentity: Cross-device access now enabled")

func is_anonymous_player() -> bool:
	"""Check if this is still an anonymous (unregistered) player"""
	# In Phase 2, this will check if user has registered account
	# For now, all players are anonymous
	return true