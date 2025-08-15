extends Control
class_name RegisterUI

# Simple registration and login UI for Phase 2 authentication

var register_system: RegisterSystem
var login_identity: LoginIdentity

# UI Elements
var main_panel: Panel
var title_label: Label
var username_input: LineEdit
var password_input: LineEdit
var register_button: Button
var login_button: Button
var logout_button: Button
var status_label: Label
var close_button: Button
var info_label: Label

# State
var is_registration_mode: bool = true

signal ui_closed()

func _ready():
	create_ui()
	update_ui_state()

func create_ui():
	"""Create the registration/login UI elements"""
	# Main panel
	main_panel = Panel.new()
	main_panel.size = Vector2(450, 400)
	main_panel.position = Vector2(30, 10)  # F2 - Top-left corner, slight offset from F1
	add_child(main_panel)
	
	# VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(410, 360)
	main_panel.add_child(vbox)
	
	# Title label
	title_label = Label.new()
	title_label.text = "Player Registration & Login"
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# Info label
	info_label = Label.new()
	info_label.text = "Register to claim this character and enable cross-device access"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(410, 40)
	vbox.add_child(info_label)
	
	# Spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Username input
	var username_label = Label.new()
	username_label.text = "Username:"
	vbox.add_child(username_label)
	
	username_input = LineEdit.new()
	username_input.placeholder_text = "Enter username (4+ characters)"
	username_input.custom_minimum_size = Vector2(400, 35)
	vbox.add_child(username_input)
	
	# Spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Password input
	var password_label = Label.new()
	password_label.text = "Password:"
	vbox.add_child(password_label)
	
	password_input = LineEdit.new()
	password_input.placeholder_text = "Enter password (4+ characters)"
	password_input.secret = true
	password_input.custom_minimum_size = Vector2(400, 35)
	vbox.add_child(password_input)
	
	# Spacing
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	
	# Button container
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	# Register button
	register_button = Button.new()
	register_button.text = "Register"
	register_button.custom_minimum_size = Vector2(120, 35)
	register_button.pressed.connect(_on_register_pressed)
	button_hbox.add_child(register_button)
	
	# Login button
	login_button = Button.new()
	login_button.text = "Login"
	login_button.custom_minimum_size = Vector2(120, 35)
	login_button.pressed.connect(_on_login_pressed)
	button_hbox.add_child(login_button)
	
	# Logout button
	logout_button = Button.new()
	logout_button.text = "Logout"
	logout_button.custom_minimum_size = Vector2(120, 35)
	logout_button.pressed.connect(_on_logout_pressed)
	button_hbox.add_child(logout_button)
	
	# Spacing
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer4)
	
	# Status label
	status_label = Label.new()
	status_label.text = "Enter username and password to register or login"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(410, 60)
	vbox.add_child(status_label)
	
	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(100, 35)
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)
	
	# Handle enter key for quick registration/login
	username_input.text_submitted.connect(_on_text_submitted)
	password_input.text_submitted.connect(_on_text_submitted)
	
	# Handle escape key to close
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_ui()

func set_register_system(system: RegisterSystem):
	"""Set the registration system reference"""
	register_system = system
	if register_system:
		# Connect to register system signals
		register_system.registration_success.connect(_on_registration_success)
		register_system.registration_failed.connect(_on_registration_failed)
		register_system.login_success.connect(_on_login_success)
		register_system.login_failed.connect(_on_login_failed)
		register_system.logout_complete.connect(_on_logout_complete)
	update_ui_state()

func set_login_identity(identity: LoginIdentity):
	"""Set the login identity reference"""
	login_identity = identity
	update_ui_state()

func update_ui_state():
	"""Update UI elements based on current authentication state"""
	if not register_system:
		return
	
	var is_logged_in = register_system.is_logged_in()
	var current_user = register_system.get_current_username()
	
	# Update visibility and enabled state
	username_input.visible = not is_logged_in
	password_input.visible = not is_logged_in
	register_button.visible = not is_logged_in
	login_button.visible = not is_logged_in
	logout_button.visible = is_logged_in
	
	# Update info text
	if is_logged_in:
		info_label.text = "Logged in as: " + current_user + "\nDevice binding disabled - you can login from any device"
		status_label.text = "✅ Account registered and logged in successfully!\nYour character is now linked to your username."
	else:
		if login_identity:
			var uuid_player = login_identity.get_uuid_player_id()
			info_label.text = "Register to claim: " + uuid_player + "\nEnable cross-device access with username/password"
		else:
			info_label.text = "Register to claim this character and enable cross-device access"
		status_label.text = "Enter username and password to register or login"

func _on_text_submitted(text: String):
	"""Handle enter key in input fields"""
	if username_input.text.strip_edges() != "" and password_input.text != "":
		_attempt_register_or_login()

func _on_register_pressed():
	"""Handle register button press"""
	_attempt_register_or_login()

func _on_login_pressed():
	"""Handle login button press"""
	_attempt_login()

func _on_logout_pressed():
	"""Handle logout button press"""
	if register_system:
		register_system.logout_current_user()

func _attempt_register_or_login():
	"""Try registration first, then login if username exists"""
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	if username == "" or password == "":
		status_label.text = "❌ Please enter both username and password"
		return
	
	if register_system:
		# Try registration first
		register_system.register_current_player(username, password)

func _attempt_login():
	"""Attempt login only"""
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	if username == "" or password == "":
		status_label.text = "❌ Please enter both username and password"
		return
	
	if register_system:
		register_system.login_user(username, password)

# Auth system signal handlers
func _on_registration_success(username: String):
	status_label.text = "✅ Registration successful! Welcome " + username
	username_input.text = ""
	password_input.text = ""
	update_ui_state()

func _on_registration_failed(error: String):
	if "already taken" in error.to_lower():
		# Username exists, try login instead
		_attempt_login()
	else:
		status_label.text = "❌ Registration failed: " + error

func _on_login_success(username: String, _uuid_player: String):
	status_label.text = "✅ Login successful! Welcome back " + username
	username_input.text = ""
	password_input.text = ""
	update_ui_state()

func _on_login_failed(error: String):
	status_label.text = "❌ Login failed: " + error

func _on_logout_complete():
	status_label.text = "Logged out successfully"
	update_ui_state()

func _on_close_pressed():
	"""Handle close button"""
	close_ui()

func close_ui():
	"""Close the UI and emit signal"""
	ui_closed.emit()
	queue_free()

func show_ui():
	"""Show the registration UI"""
	visible = true
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()
	if username_input:
		username_input.grab_focus()

func hide_ui():
	"""Hide the registration UI"""
	visible = false

# Static function to create and show registration UI
static func show_register_ui(parent: Node, reg_sys: RegisterSystem, login_id: LoginIdentity) -> RegisterUI:
	"""Create and show registration UI"""
	var ui = RegisterUI.new()
	parent.get_node("UILayer").add_child(ui)
	ui.set_register_system(reg_sys)
	ui.set_login_identity(login_id)
	ui.show_ui()
	return ui
