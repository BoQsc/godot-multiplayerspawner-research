extends Node
class_name Login

# Login/logout system for existing user accounts
# Handles authentication and session management

var register: Register  # Reference to registration system
var user_identity: UserIdentity  # Reference to user identity
var current_logged_in_user: String = ""  # Currently logged in username

# Signals for UI updates
signal login_success(username: String, uuid_player: String)
signal login_failed(error: String)
signal logout_complete()

func _ready():
	print("Login: Login system ready")

# Login with username/password
func login_user(username: String, password: String) -> bool:
	# Validate input
	if username.strip_edges() == "" or password == "":
		login_failed.emit("Username and password required")
		return false
	
	if not register:
		login_failed.emit("No registration system available")
		return false
	
	if not register.username_exists(username):
		login_failed.emit("Account not found")
		return false
	
	var account = register.get_account(username)
	if account.password_hash != password.sha256_text():
		login_failed.emit("Invalid password")
		return false
	
	if not user_identity:
		login_failed.emit("No user identity available")
		return false
	
	# Update login state
	account.last_login = Time.get_datetime_string_from_system()
	account.is_logged_in = true
	current_logged_in_user = username
	register.save_accounts()
	
	# Disable device binding (no longer needed)
	user_identity.disable_device_binding_after_registration()
	
	print("Login: Login successful ", username, " -> ", account.uuid_player_id)
	login_success.emit(username, account.uuid_player_id)
	return true

# Logout current user
func logout_current_user():
	if current_logged_in_user != "" and register:
		var account = register.get_account(current_logged_in_user)
		if account:
			account.is_logged_in = false
			register.save_accounts()
			print("Login: Logged out ", current_logged_in_user)
	
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
	if current_logged_in_user != "" and register:
		var account = register.get_account(current_logged_in_user)
		if account:
			return account.uuid_player_id
	return ""

# Future features to implement:
# - Password reset via email
# - Two-factor authentication
# - Session timeout
# - Multiple concurrent sessions
# - Login history tracking