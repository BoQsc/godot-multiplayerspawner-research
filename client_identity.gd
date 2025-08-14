extends Node
class_name ClientIdentity

# FIXED: Each instance gets unique identity file based on process ID
# This ensures each client gets a different player

const CLIENT_ID_FILE_SERVER = "user://server_identity.dat"
var client_identity_file: String

var client_id: String = ""
var is_server_role: bool = false

func _ready():
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