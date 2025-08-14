extends Node

# Future registration system placeholder
# This system will allow players to:
# 1. Register with username/password/email
# 2. Link their UUID-based player to a human-readable account
# 3. Login with credentials instead of remembering UUIDs
# 4. Recover access to their player data

const ACCOUNTS_FILE = "user://player_accounts.dat"

# Account data structure
class PlayerAccount:
	var username: String
	var email: String
	var password_hash: String  # Hashed password for security
	var uuid_player_id: String  # Links to existing player_<uuid> 
	var created_at: String
	var last_login: String

var accounts: Dictionary = {}  # username -> PlayerAccount

func _ready():
	load_accounts()

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

# Register a new account and link it to existing UUID player
func register_account(username: String, email: String, password: String, uuid_player_id: String) -> bool:
	if username in accounts:
		print("Username already exists: ", username)
		return false
	
	# Hash password for security (simple example - use proper hashing in production)
	var password_hash = password.hash()
	
	var account = PlayerAccount.new()
	account.username = username
	account.email = email
	account.password_hash = str(password_hash)
	account.uuid_player_id = uuid_player_id
	account.created_at = Time.get_datetime_string_from_system()
	account.last_login = account.created_at
	
	accounts[username] = account
	save_accounts()
	
	print("Registered new account: ", username, " -> ", uuid_player_id)
	return true

# Login with username/password and return the linked UUID player ID
func login_account(username: String, password: String) -> String:
	if not username in accounts:
		print("Account not found: ", username)
		return ""
	
	var account = accounts[username]
	var password_hash = str(password.hash())
	
	if account.password_hash != password_hash:
		print("Invalid password for: ", username)
		return ""
	
	# Update last login time
	account.last_login = Time.get_datetime_string_from_system()
	save_accounts()
	
	print("Successful login: ", username, " -> ", account.uuid_player_id)
	return account.uuid_player_id

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