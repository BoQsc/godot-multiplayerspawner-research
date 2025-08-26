extends Node
class_name Register

# Registration system for new user accounts
# Handles username/password registration with cross-device access

const ACCOUNTS_FILE = "user://player_accounts.dat"

# Account data structure
class PlayerAccount:
	var username: String
	var password_hash: String  # SHA256 hashed password
	var uuid_player_id: String  # Links to existing player_<uuid> 
	var created_at: String
	var last_login: String
	var is_logged_in: bool = false

var accounts: Dictionary = {}  # username -> PlayerAccount
var user_identity: UserIdentity  # Reference to user identity

# Signals for UI updates
signal registration_success(username: String)
signal registration_failed(error: String)

func _ready():
	load_accounts()
	print("Register: Loaded ", accounts.size(), " registered accounts")

# Load existing accounts from file
func load_accounts():
	if FileAccess.file_exists(ACCOUNTS_FILE):
		var file = FileAccess.open(ACCOUNTS_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				accounts = json.data
				print("Loaded ", accounts.size(), " player accounts")
			else:
				print("Failed to parse accounts file")
	else:
		print("No existing accounts file found")

# Save accounts to file
func save_accounts():
	var file = FileAccess.open(ACCOUNTS_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(accounts)
		file.store_string(json_string)
		file.close()
		print("Saved ", accounts.size(), " player accounts")
	else:
		print("Failed to save accounts file")

# Register current anonymous player with username/password
func register_current_player(username: String, password: String) -> bool:
	# Validate input
	if username.strip_edges() == "":
		registration_failed.emit("Username cannot be empty")
		return false
	
	if password.length() < 4:
		registration_failed.emit("Password must be at least 4 characters")
		return false
	
	if username in accounts:
		registration_failed.emit("Username already taken")
		return false
	
	if not user_identity:
		registration_failed.emit("No user identity available")
		return false
	
	# Get current UUID player
	var uuid_player = user_identity.get_uuid_player_id()
	if uuid_player == "":
		registration_failed.emit("No UUID player found")
		return false
	
	# Create account
	var account = PlayerAccount.new()
	account.username = username
	account.password_hash = password.sha256_text()
	account.uuid_player_id = uuid_player
	account.created_at = Time.get_datetime_string_from_system()
	account.last_login = account.created_at
	account.is_logged_in = true
	
	accounts[username] = account
	save_accounts()
	
	# Disable device binding (no longer needed)
	user_identity.disable_device_binding_after_registration()
	
	print("Register: Registered ", username, " -> ", uuid_player)
	registration_success.emit(username)
	return true

# Get account info by username
func get_account(username: String) -> PlayerAccount:
	if username in accounts:
		return accounts[username]
	return null

# Link existing UUID player to account (for retroactive registration)
func link_uuid_to_account(username: String, uuid_player_id: String) -> bool:
	if not username in accounts:
		print("Account not found: ", username)
		return false
	
	accounts[username].uuid_player_id = uuid_player_id
	save_accounts()
	
	print("Linked UUID player to account: ", username, " -> ", uuid_player_id)
	return true

# Check if username exists
func username_exists(username: String) -> bool:
	return username in accounts

# Future features to implement:
# - Email verification
# - Account recovery
# - Social login (Google, Discord, etc.)
# - Account linking (merge multiple UUID players)
# - Account suspension/moderation tools