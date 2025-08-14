extends Node
class_name ClientIdentity

# This class manages persistent client identification without requiring registration
# Each machine gets a unique ID that persists across sessions

const CLIENT_ID_FILE_SERVER = "user://server_identity.dat"
const CLIENT_ID_FILE_CLIENT = "user://client_identity.dat"

var client_id: String = ""
var machine_fingerprint: String = ""
var is_server_role: bool = false

func _ready():
	# Detect if we're running as server or client
	is_server_role = "--server" in OS.get_cmdline_args()
	generate_machine_fingerprint()
	load_or_create_client_id()

func generate_machine_fingerprint() -> String:
	# Create a unique fingerprint for this machine using available system info
	var fingerprint_data = []
	
	# Use OS information
	fingerprint_data.append(OS.get_name())
	fingerprint_data.append(OS.get_model_name())
	
	# Use environment variables that are likely to be unique per machine
	var username = OS.get_environment("USERNAME")
	if username == "":
		username = OS.get_environment("USER")  # Unix systems
	fingerprint_data.append(username)
	
	var computer_name = OS.get_environment("COMPUTERNAME")
	if computer_name == "":
		computer_name = OS.get_environment("HOSTNAME")  # Unix systems
	fingerprint_data.append(computer_name)
	
	# Use processor count as additional identifier
	fingerprint_data.append(str(OS.get_processor_count()))
	
	# Add role to fingerprint for better separation
	var role = "server" if is_server_role else "client"
	fingerprint_data.append(role)
	
	# Combine all data and hash it
	var combined = "|".join(fingerprint_data)
	# Use SHA256 instead of simple hash for better collision resistance
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(combined.to_utf8_buffer())
	var result = ctx.finish()
	machine_fingerprint = result.hex_encode().substr(0, 16)  # Use first 16 chars
	
	print("ClientIdentity: Generated machine fingerprint: ", machine_fingerprint)
	return machine_fingerprint

func load_or_create_client_id():
	var identity_file = CLIENT_ID_FILE_SERVER if is_server_role else CLIENT_ID_FILE_CLIENT
	
	if FileAccess.file_exists(identity_file):
		# Load existing client ID
		var file = FileAccess.open(identity_file, FileAccess.READ)
		if file:
			var stored_data = file.get_as_text()
			file.close()
			
			var data_parts = stored_data.split("|")
			if data_parts.size() >= 2:
				var stored_fingerprint = data_parts[0]
				var stored_client_id = data_parts[1]
				
				# BACKWARDS COMPATIBILITY: Always use existing client ID if file exists
				# This prevents creating duplicate players when we update the fingerprint algorithm
				client_id = stored_client_id
				print("ClientIdentity: Loaded existing client ID: ", client_id, " (fingerprint compatibility mode)")
				
				# Update the stored fingerprint to new format for future use
				save_client_id()
				return
	
	# Generate new client ID with role prefix
	var role_prefix = "server_" if is_server_role else "client_"
	client_id = role_prefix + generate_random_id()
	save_client_id()
	print("ClientIdentity: Created new client ID: ", client_id)

func generate_random_id() -> String:
	# Generate a UUID-like random ID with better uniqueness
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var id = ""
	
	# Add timestamp component (first 4 chars) for temporal uniqueness
	var time_component = str(Time.get_unix_time_from_system()).hash()
	var time_hex = str(time_component).md5_text().substr(0, 4)
	id += time_hex
	
	# Add random component (remaining 8 chars) for collision resistance  
	for i in range(8):
		id += chars[randi() % chars.length()]
	
	return id

func save_client_id():
	var identity_file = CLIENT_ID_FILE_SERVER if is_server_role else CLIENT_ID_FILE_CLIENT
	var file = FileAccess.open(identity_file, FileAccess.WRITE)
	if file:
		var data_to_save = machine_fingerprint + "|" + client_id
		file.store_string(data_to_save)
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