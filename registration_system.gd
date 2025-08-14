extends Node
class_name AuthenticationSystem

# Phase 2: Simple Username + Password Registration System
# No email required - just username and password for cross-device access
# Device binding automatically disabled after registration

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
var current_logged_in_user: String = ""  # Currently logged in username
var client_identity: ClientIdentity  # Reference to client identity

# Signals for UI updates
signal registration_success(username: String)
signal registration_failed(error: String)
signal login_success(username: String, uuid_player: String)
signal login_failed(error: String)
signal logout_complete()

func _ready():
	load_accounts()
	print("AuthenticationSystem: Loaded ", accounts.size(), " registered accounts")

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
	
	if not client_identity:
		registration_failed.emit("No client identity available")
		return false
	
	# Get current UUID player
	var uuid_player = client_identity.get_uuid_player_id()
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
	current_logged_in_user = username
	save_accounts()
	
	# Disable device binding (no longer needed)
	client_identity.disable_device_binding_after_registration()
	
	print("AuthenticationSystem: Registered ", username, " -> ", uuid_player)
	registration_success.emit(username)
	return true

# Login with username/password
func login_user(username: String, password: String) -> bool:
	# Validate input
	if username.strip_edges() == "" or password == "":
		login_failed.emit("Username and password required")
		return false
	
	if not username in accounts:
		login_failed.emit("Account not found")
		return false
	
	var account = accounts[username]
	if account.password_hash != password.sha256_text():
		login_failed.emit("Invalid password")
		return false
	
	if not client_identity:
		login_failed.emit("No client identity available")
		return false
	
	# Update login state
	account.last_login = Time.get_datetime_string_from_system()
	account.is_logged_in = true
	current_logged_in_user = username
	save_accounts()
	
	# Disable device binding (no longer needed)
	client_identity.disable_device_binding_after_registration()
	
	print("AuthenticationSystem: Login successful ", username, " -> ", account.uuid_player_id)
	login_success.emit(username, account.uuid_player_id)
	return true

# Logout current user
func logout_current_user():
	if current_logged_in_user != "" and current_logged_in_user in accounts:
		accounts[current_logged_in_user].is_logged_in = false
		save_accounts()
		print("AuthenticationSystem: Logged out ", current_logged_in_user)
	
	current_logged_in_user = ""
	logout_complete.emit()

# Check if user is currently logged in
func is_logged_in() -> bool:
	return current_logged_in_user != ""

# Get current logged in username
func get_current_username() -> String:
	return current_logged_in_user

# Get UUID player for current logged in user
func get_current_uuid_player() -> String:
	if current_logged_in_user in accounts:
		return accounts[current_logged_in_user].uuid_player_id
	return ""

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

# Future features to implement:
# - Email verification
# - Password reset via email
# - Account recovery
# - Two-factor authentication
# - Social login (Google, Discord, etc.)
# - Account linking (merge multiple UUID players)
# - Player statistics and achievements
# - Friends system
# - Account suspension/moderation tools
