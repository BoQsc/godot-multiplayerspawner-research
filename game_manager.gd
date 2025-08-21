extends Node 

const PORT = 4443
var players = {}  # peer_id -> player_node
var player_persistent_ids = {}  # peer_id -> persistent_player_id

# NPC Management
var npcs = {}  # npc_id -> npc_node
var next_npc_id: int = 1
var network_manager: NetworkManager
var world_manager: WorldManager
var user_identity: UserIdentity
var register: Register
var login: Login

# Automatic position saving
var save_timer: float = 0.0
var save_interval: float = 5.0  # Save every 5 seconds

# UI window tracking
var device_binding_ui: Control = null
var register_ui: Control = null
var custom_join_ui: Control = null
var player_list_ui: Control = null
var reconnection_ui: Control = null

# Connection and reconnection tracking
enum ConnectionState { DISCONNECTED, CONNECTING, CONNECTED, RECONNECTING }
var connection_state: ConnectionState = ConnectionState.DISCONNECTED
var last_server_ip: String = "127.0.0.1"
var last_server_port: int = 4443
var reconnection_attempts: int = 0
var max_reconnection_attempts: int = 10
var reconnection_delay: float = 3.0
var reconnection_timer: float = 0.0
var is_client_mode: bool = false
var last_rpc_debug_time: float = 0.0

# Server-side device binding validation
var server_device_bindings: Dictionary = {}  # player_id -> device_fingerprint
const SERVER_DEVICE_BINDINGS_FILE = "user://server_device_bindings.json"

# Connection monitoring
var connection_timeout: float = 10.0  # 10 seconds timeout
var last_heartbeat_time: float = 0.0
var heartbeat_interval: float = 2.0   # Send heartbeat every 2 seconds

func _ready() -> void:
	# Find NetworkManager, WorldManager, UserIdentity, Register, and Login systems
	network_manager = get_tree().get_first_node_in_group("network_manager")
	world_manager = get_tree().get_first_node_in_group("world_manager")
	user_identity = get_tree().get_first_node_in_group("user_identity")
	register = get_tree().get_first_node_in_group("register_system")
	login = get_tree().get_first_node_in_group("login_system")
	
	# Setup systems with user identity references
	if register and user_identity:
		register.user_identity = user_identity
		print("GameManager: Connected register system to user identity")
	
	if login and register and user_identity:
		login.register = register
		login.user_identity = user_identity
		print("GameManager: Connected login system to register and user identity")
	
	if "--server" in OS.get_cmdline_args():
		print("Creating server")
		connection_state = ConnectionState.CONNECTED
		
		# Load server device bindings
		_load_server_device_bindings()
		
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(PORT)
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_on_player_connected)
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
		
		# Spawn server player (ID 1) with persistent data
		await get_tree().process_frame
		# Wait for user identity to be ready
		if user_identity:
			# SERVER DEVICE BINDING VALIDATION
			var server_chosen_num = user_identity.get_chosen_player_number()
			if server_chosen_num != -1:
				var player_id = "player_" + str(server_chosen_num)
				var server_device_fingerprint = user_identity.get_device_fingerprint()
				
				# Check if this player is already bound to a different device
				if player_id in server_device_bindings:
					var bound_device = server_device_bindings[player_id]
					if bound_device != server_device_fingerprint:
						print("ERROR: Server cannot use player ", server_chosen_num, " - bound to different device")
						print("Bound device: ", bound_device.substr(0, 16), "...")
						print("Server device: ", server_device_fingerprint.substr(0, 16), "...")
						get_tree().quit()
						return
				else:
					# First time using this player number - bind to server device
					server_device_bindings[player_id] = server_device_fingerprint
					_save_server_device_bindings()
					print("SERVER: Bound player ", server_chosen_num, " to server device ", server_device_fingerprint.substr(0, 16), "...")
			
			var server_client_id = user_identity.get_client_id()
			var server_persistent_id = _register_player_with_client_id(1, server_client_id, server_chosen_num)
			var server_spawn_pos = _get_player_spawn_position(server_persistent_id)
			_spawn_player(1, server_spawn_pos, server_persistent_id)
		else:
			print("Warning: UserIdentity not found, using fallback spawn")
	else:
		print("Creating Client")
		is_client_mode = true
		
		# Check device binding access for client too
		if user_identity and not user_identity.can_access_current_uuid():
			print("ERROR: Cannot access UUID player - bound to different device")
			print("Use F1 to open device binding settings and transfer if needed")
			_show_access_denied_message()
			return
		
		_connect_to_server(last_server_ip, last_server_port)

func _process(delta):
	# Auto-save player positions periodically
	save_timer += delta
	if save_timer >= save_interval:
		_auto_save_all_player_positions()
		save_timer = 0.0
	
	# Handle reconnection logic for clients
	if is_client_mode and connection_state == ConnectionState.RECONNECTING:
		reconnection_timer -= delta
		if reconnection_timer <= 0.0:
			_attempt_reconnection()
	
	# Connection monitoring for clients
	if is_client_mode and connection_state == ConnectionState.CONNECTED:
		_monitor_connection(delta)

func _unhandled_key_input(event):
	# Handle UI toggles
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:  # ESC to close all UI windows
			_close_all_ui_windows()
		elif event.keycode == KEY_F1:  # F1 to toggle device binding settings
			_toggle_device_binding_ui()
		elif event.keycode == KEY_F2:  # F2 to toggle registration/login
			_toggle_register_ui()
		elif event.keycode == KEY_F3:  # F3 to toggle custom IP join
			_toggle_custom_join_ui()
		elif event.keycode == KEY_F4:  # F4 to toggle player list
			_toggle_player_list_ui()
		
		# NPC Debug Controls (Server Only)
		elif event.keycode == KEY_F5:  # F5 to spawn test NPC
			debug_spawn_test_npc()
		elif event.keycode == KEY_F6:  # F6 to list all NPCs
			debug_list_npcs()

func _show_device_binding_ui():
	# Show device binding UI for anonymous players
	if user_identity and user_identity.can_access_current_uuid():
		var ui_scene = preload("res://Account/device_binding_ui.gd")
		device_binding_ui = ui_scene.show_device_binding_ui(get_parent(), user_identity)
		device_binding_ui.ui_closed.connect(_on_device_binding_ui_closed)
		print("GameManager: Showing device binding UI (F1)")
	else:
		print("GameManager: Cannot access UUID or user identity not available")

func _on_device_binding_ui_closed():
	device_binding_ui = null
	print("GameManager: Device binding UI closed")

func _show_register_ui():
	# Show registration/login UI
	if register and login and user_identity:
		var ui_scene = preload("res://Account/signin_ui.gd")
		register_ui = ui_scene.show_signin_ui(get_parent(), register, login, user_identity)
		register_ui.ui_closed.connect(_on_register_ui_closed)
		print("GameManager: Showing signin UI (F2)")
	else:
		print("GameManager: Auth systems or user identity not available")

func _on_register_ui_closed():
	register_ui = null
	print("GameManager: Registration UI closed")

func _close_all_ui_windows():
	# Close all open UI windows
	if device_binding_ui:
		device_binding_ui.queue_free()
		device_binding_ui = null
		print("GameManager: Device binding UI closed (ESC)")
	
	if register_ui:
		register_ui.queue_free()
		register_ui = null
		print("GameManager: Registration UI closed (ESC)")
	
	if custom_join_ui:
		custom_join_ui.queue_free()
		custom_join_ui = null
		print("GameManager: Custom join UI closed (ESC)")
	
	if player_list_ui:
		player_list_ui.queue_free()
		player_list_ui = null
		print("GameManager: Player list UI closed (ESC)")
	
	if reconnection_ui:
		reconnection_ui.queue_free()
		reconnection_ui = null
		print("GameManager: Reconnection UI closed (ESC)")

func _toggle_device_binding_ui():
	if device_binding_ui:
		# Close if already open
		device_binding_ui.queue_free()
		device_binding_ui = null
		print("GameManager: Device binding UI closed (F1 toggle)")
	else:
		# Open if not already open
		_show_device_binding_ui()

func _toggle_register_ui():
	if register_ui:
		# Close if already open
		register_ui.queue_free()
		register_ui = null
		print("GameManager: Registration UI closed (F2 toggle)")
	else:
		# Open if not already open
		_show_register_ui()

func _toggle_custom_join_ui():
	if custom_join_ui:
		# Close if already open
		custom_join_ui.queue_free()
		custom_join_ui = null
		print("GameManager: Custom join UI closed (F3 toggle)")
	else:
		# Open if not already open
		_show_custom_join_ui()

func _toggle_player_list_ui():
	if player_list_ui:
		# Close if already open
		player_list_ui.queue_free()
		player_list_ui = null
		print("GameManager: Player list UI closed (F4 toggle)")
	else:
		# Open if not already open
		_show_player_list_ui()

func _show_custom_join_ui():
	# Create custom IP join UI
	custom_join_ui = Control.new()
	custom_join_ui.name = "CustomJoinUI"
	
	# Background panel
	var bg_panel = Panel.new()
	bg_panel.name = "Panel"
	bg_panel.position = Vector2(50, 10)  # F3 - Top-left corner, offset from F1/F2
	custom_join_ui.add_child(bg_panel)
	
	# VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	bg_panel.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Join Custom Server"
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# Spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# IP input
	var ip_label = Label.new()
	ip_label.text = "Server IP:"
	vbox.add_child(ip_label)
	
	var ip_input = LineEdit.new()
	ip_input.name = "IPInput"
	ip_input.text = "192.168.0.90"
	ip_input.placeholder_text = "Enter server IP address"
	ip_input.custom_minimum_size = Vector2(340, 35)
	vbox.add_child(ip_input)
	
	# Spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Port input
	var port_label = Label.new()
	port_label.text = "Port:"
	vbox.add_child(port_label)
	
	var port_input = LineEdit.new()
	port_input.name = "PortInput"
	port_input.text = "4443"
	port_input.placeholder_text = "Enter port number"
	port_input.custom_minimum_size = Vector2(340, 35)
	vbox.add_child(port_input)
	
	# Spacing
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	
	# Button container
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	# Connect button
	var connect_btn = Button.new()
	connect_btn.text = "Connect"
	connect_btn.custom_minimum_size = Vector2(120, 35)
	button_hbox.add_child(connect_btn)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 35)
	button_hbox.add_child(cancel_btn)
	
	get_parent().get_node("UILayer").add_child(custom_join_ui)
	
	# Connect button signals
	connect_btn.pressed.connect(_on_custom_connect_pressed.bind(custom_join_ui))
	cancel_btn.pressed.connect(_on_custom_join_cancel.bind(custom_join_ui))
	
	# Handle enter key for quick connect
	ip_input.text_submitted.connect(_on_custom_connect_enter.bind(custom_join_ui))
	port_input.text_submitted.connect(_on_custom_connect_enter.bind(custom_join_ui))
	
	# Set focus to IP input
	ip_input.grab_focus()
	
	print("GameManager: Showing custom join UI (F3)")

func _on_custom_connect_pressed(ui_container: Control):
	var ip_input = ui_container.get_node("Panel/IPInput")
	var port_input = ui_container.get_node("Panel/PortInput")
	
	var ip = ip_input.text.strip_edges()
	var port_text = port_input.text.strip_edges()
	
	# Validate inputs
	if ip == "":
		print("Error: IP address cannot be empty")
		return
	
	if port_text == "":
		print("Error: Port cannot be empty")
		return
	
	var port = port_text.to_int()
	if port <= 0 or port > 65535:
		print("Error: Invalid port number (must be 1-65535)")
		return
	
	# Close UI
	ui_container.queue_free()
	custom_join_ui = null
	
	# Connect to custom server
	_connect_to_custom_server(ip, port)

func _on_custom_join_cancel(ui_container: Control):
	ui_container.queue_free()
	custom_join_ui = null
	print("GameManager: Custom join cancelled")

func _on_custom_connect_enter(ui_container: Control):
	"""Handle enter key in input fields"""
	_on_custom_connect_pressed(ui_container)

func _connect_to_custom_server(ip: String, port: int):
	print("Connecting to custom server: ", ip, ":", port)
	_connect_to_server(ip, port)

func _show_player_list_ui():
	# Create player list UI
	player_list_ui = Control.new()
	player_list_ui.name = "PlayerListUI"
	
	# Background panel
	var bg_panel = Panel.new()
	bg_panel.name = "Panel"
	bg_panel.position = Vector2(70, 10)  # F4 - Top-left corner, offset from F1/F2/F3
	player_list_ui.add_child(bg_panel)
	
	# VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	bg_panel.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Online Players"
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# Spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	# Scroll container for player list
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(440, 280)
	vbox.add_child(scroll_container)
	
	# VBoxContainer to hold player entries
	var player_list_container = VBoxContainer.new()
	player_list_container.name = "PlayerListContainer"
	scroll_container.add_child(player_list_container)
	
	# Populate player list
	_populate_player_list(player_list_container)
	
	# Spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	# Button container
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	# Refresh button
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.custom_minimum_size = Vector2(120, 35)
	button_hbox.add_child(refresh_btn)
	
	# Spacer between buttons
	var button_spacer = Control.new()
	button_spacer.custom_minimum_size = Vector2(20, 0)
	button_hbox.add_child(button_spacer)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 35)
	button_hbox.add_child(close_btn)
	
	get_parent().get_node("UILayer").add_child(player_list_ui)
	
	# Connect button signals
	refresh_btn.pressed.connect(_on_player_list_refresh.bind(player_list_container))
	close_btn.pressed.connect(_on_player_list_close)
	
	print("GameManager: Showing player list UI (F4)")

func _populate_player_list(container: VBoxContainer):
	# Clear existing entries
	for child in container.get_children():
		child.queue_free()
	
	# Add header
	var header_label = Label.new()
	header_label.text = "Connected Players (" + str(players.size()) + "):"
	header_label.add_theme_font_size_override("font_size", 16)
	header_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Solid white text
	container.add_child(header_label)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	# Add each player
	for peer_id in players.keys():
		var player_info = HBoxContainer.new()
		
		# Player ID label
		var id_label = Label.new()
		id_label.text = "ID: " + str(peer_id)
		id_label.custom_minimum_size = Vector2(80, 0)
		id_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Solid white text
		
		# Player persistent ID
		var persistent_id = player_persistent_ids.get(peer_id, "Unknown")
		var persistent_label = Label.new()
		persistent_label.text = "Player: " + persistent_id
		persistent_label.custom_minimum_size = Vector2(150, 0)
		persistent_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Solid white text
		
		# Player position
		var pos = players[peer_id].position
		var pos_label = Label.new()
		pos_label.text = "Pos: (" + str(int(pos.x)) + ", " + str(int(pos.y)) + ")"
		pos_label.custom_minimum_size = Vector2(120, 0)
		pos_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Solid white text
		
		# Connection status
		var status_label = Label.new()
		if peer_id == 1:
			status_label.text = "[SERVER]"
			status_label.modulate = Color(0.0, 1.0, 1.0, 1.0)  # Solid cyan
		elif peer_id == multiplayer.get_unique_id():
			status_label.text = "[YOU]"
			status_label.modulate = Color(0.0, 1.0, 0.0, 1.0)  # Solid green
		else:
			status_label.text = "[CLIENT]"
			status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Solid white
		
		player_info.add_child(id_label)
		player_info.add_child(persistent_label)
		player_info.add_child(pos_label)
		player_info.add_child(status_label)
		
		container.add_child(player_info)

func _on_player_list_refresh(container: VBoxContainer):
	_populate_player_list(container)
	print("GameManager: Player list refreshed")

func _on_player_list_close():
	if player_list_ui:
		player_list_ui.queue_free()
		player_list_ui = null
		print("GameManager: Player list UI closed")

func _show_reconnection_ui():
	# Don't show multiple reconnection UIs
	if reconnection_ui:
		return
	
	# Create reconnection UI
	reconnection_ui = ColorRect.new()
	reconnection_ui.name = "ReconnectionUI"
	reconnection_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reconnection_ui.color = Color(0, 0, 0, 0.8)  # Solid dark background
	
	# Background panel
	var bg_panel = Panel.new()
	bg_panel.name = "Panel"
	bg_panel.position = Vector2(get_viewport().size.x / 2 - 250, get_viewport().size.y / 2 - 100)
	bg_panel.size = Vector2(500, 200)
	bg_panel.modulate = Color(0.15, 0.15, 0.15, 1.0)  # Solid dark panel
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Connection Lost"
	title_label.position = Vector2(200, 20)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.modulate = Color(1.0, 0.2, 0.2, 1.0)  # Red text
	
	# Status label
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Connection to the server is lost, reconnecting..."
	status_label.position = Vector2(50, 70)
	status_label.size = Vector2(400, 30)
	status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # White text
	
	# Attempts label
	var attempts_label = Label.new()
	attempts_label.name = "AttemptsLabel"
	attempts_label.text = "Attempt 1 of " + str(max_reconnection_attempts)
	attempts_label.position = Vector2(50, 100)
	attempts_label.size = Vector2(400, 30)
	attempts_label.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Light gray text
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Give Up"
	cancel_btn.position = Vector2(200, 140)
	cancel_btn.size = Vector2(100, 30)
	
	# Add all elements to panel
	bg_panel.add_child(title_label)
	bg_panel.add_child(status_label)
	bg_panel.add_child(attempts_label)
	bg_panel.add_child(cancel_btn)
	
	reconnection_ui.add_child(bg_panel)
	get_parent().get_node("UILayer").add_child(reconnection_ui)
	
	# Connect cancel button
	cancel_btn.pressed.connect(_on_reconnection_cancel)
	
	print("GameManager: Showing reconnection UI")

func _update_reconnection_ui():
	if reconnection_ui:
		var status_label = reconnection_ui.get_node("Panel/StatusLabel")
		var attempts_label = reconnection_ui.get_node("Panel/AttemptsLabel")
		
		if connection_state == ConnectionState.CONNECTING:
			status_label.text = "Attempting to reconnect..."
		elif connection_state == ConnectionState.RECONNECTING:
			var time_left = int(reconnection_timer)
			status_label.text = "Reconnecting in " + str(time_left + 1) + " seconds..."
		
		attempts_label.text = "Attempt " + str(reconnection_attempts + 1) + " of " + str(max_reconnection_attempts)

func _on_reconnection_cancel():
	if reconnection_ui:
		reconnection_ui.queue_free()
		reconnection_ui = null
	
	# Stop reconnection attempts
	connection_state = ConnectionState.DISCONNECTED
	reconnection_attempts = 0
	last_heartbeat_time = 0.0
	
	# Disconnect from server
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Clean up players when giving up
	_cleanup_all_players()
	
	print("GameManager: Reconnection cancelled by user")

func _connect_to_server(ip: String, port: int):
	print("Connecting to server: ", ip, ":", port)
	
	# Store server details for reconnection
	last_server_ip = ip
	last_server_port = port
	connection_state = ConnectionState.CONNECTING
	
	# Check device binding access
	if user_identity and not user_identity.can_access_current_uuid():
		print("ERROR: Cannot access UUID player - bound to different device")
		print("Use F1 to open device binding settings and transfer if needed")
		_show_access_denied_message()
		connection_state = ConnectionState.DISCONNECTED
		return
	
	# Create client connection
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	
	if result != OK:
		print("Failed to create client connection to ", ip, ":", port)
		connection_state = ConnectionState.DISCONNECTED
		_start_reconnection()
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Connect multiplayer signals for connection monitoring (only if not already connected)
	if not multiplayer.peer_connected.is_connected(_on_client_connected_to_server):
		multiplayer.peer_connected.connect(_on_client_connected_to_server)
	if not multiplayer.peer_disconnected.is_connected(_on_client_disconnected_from_server):
		multiplayer.peer_disconnected.connect(_on_client_disconnected_from_server)
	if not multiplayer.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer.connection_failed.connect(_on_client_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("Client attempting connection to ", ip, ":", port)

func _attempt_reconnection():
	if reconnection_attempts >= max_reconnection_attempts:
		print("Max reconnection attempts reached, giving up")
		connection_state = ConnectionState.DISCONNECTED
		_update_reconnection_ui()
		return
	
	reconnection_attempts += 1
	print("Reconnection attempt ", reconnection_attempts, " of ", max_reconnection_attempts)
	
	# Close existing connection if any
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Try to reconnect
	connection_state = ConnectionState.CONNECTING
	_update_reconnection_ui()
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(last_server_ip, last_server_port)
	
	if result != OK:
		print("Reconnection failed to create client")
		_schedule_next_reconnection()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Attempting reconnection to ", last_server_ip, ":", last_server_port)

func _start_reconnection():
	if not is_client_mode or connection_state == ConnectionState.RECONNECTING:
		return
	
	print("Starting reconnection process...")
	connection_state = ConnectionState.RECONNECTING
	reconnection_attempts = 0
	reconnection_timer = reconnection_delay
	
	# Show reconnection UI
	_show_reconnection_ui()
	_update_reconnection_ui()

func _schedule_next_reconnection():
	connection_state = ConnectionState.RECONNECTING
	reconnection_timer = reconnection_delay
	_update_reconnection_ui()

func _on_client_connected_to_server(peer_id):
	if peer_id == 1:  # Connected to server
		print("Successfully connected to server!")
		connection_state = ConnectionState.CONNECTED
		reconnection_attempts = 0
		last_heartbeat_time = 0.0  # Reset heartbeat timer
		
		# Close reconnection UI if it's open
		if reconnection_ui:
			reconnection_ui.queue_free()
			reconnection_ui = null

func _on_client_disconnected_from_server(peer_id):
	if peer_id == 1:  # Disconnected from server
		print("Disconnected from server")
		_handle_server_disconnection()

func _on_client_connection_failed():
	print("Failed to connect to server")
	_handle_connection_failure()

func _on_server_disconnected():
	print("Server disconnected unexpectedly")
	_handle_server_disconnection()

func _handle_server_disconnection():
	if not is_client_mode:
		return
	
	print("Server connection lost, starting reconnection...")
	
	# Clean up existing players to prevent duplicates
	_cleanup_all_players()
	
	_start_reconnection()

func _cleanup_all_players():
	# Remove all players from the scene to prevent duplicates on reconnection
	for peer_id in players.keys():
		_despawn_player(peer_id)
	players.clear()
	player_persistent_ids.clear()
	print("Cleaned up all players before reconnection")

func _cleanup_old_client_instances(client_id: String, new_peer_id: int):
	# Find and remove any existing players with the same client_id but different peer_id
	var peers_to_remove = []
	
	# Check world manager for client mappings to find old peer IDs
	if world_manager and world_manager.world_data:
		var world_data = world_manager.world_data
		
		# Look through peer mappings to find old peer IDs for this client
		for existing_peer_id in world_data.peer_to_client_mapping.keys():
			var existing_client_id = world_data.peer_to_client_mapping[existing_peer_id]
			
			# If same client but different peer ID, it's an old connection
			if existing_client_id == client_id and existing_peer_id != new_peer_id:
				peers_to_remove.append(existing_peer_id)
	
	# Also check local players dictionary for orphaned entries
	for existing_peer_id in players.keys():
		if existing_peer_id != new_peer_id:
			# Check if this peer might be an old instance of the same client
			var existing_persistent_id = player_persistent_ids.get(existing_peer_id, "")
			if existing_persistent_id != "":
				# Extract UUID from persistent ID to compare with client ID
				var existing_uuid = existing_persistent_id.replace("player_", "")
				var new_uuid = client_id.replace("client_", "")
				
				if existing_uuid == new_uuid:
					peers_to_remove.append(existing_peer_id)
	
	# Remove all old instances
	for old_peer_id in peers_to_remove:
		print("Cleaning up old instance of client ", client_id, " (old peer ID: ", old_peer_id, ", new peer ID: ", new_peer_id, ")")
		
		# Save player data before removing
		_save_player_data(old_peer_id)
		
		# Remove from world manager
		if world_manager and world_manager.world_data:
			world_manager.world_data.unregister_peer(old_peer_id)
		
		# Despawn and notify all clients
		_despawn_player(old_peer_id)
		rpc("despawn_player", old_peer_id)

func _cleanup_stale_connections():
	# Remove any players whose peer connections are no longer active
	var stale_peers = []
	
	# Get list of currently connected peer IDs
	var connected_peers = multiplayer.get_peers()
	connected_peers.append(1)  # Server is always peer 1
	
	# Find players whose peer IDs are not in the connected list
	for peer_id in players.keys():
		if not connected_peers.has(peer_id):
			stale_peers.append(peer_id)
			print("Found stale connection: peer ", peer_id, " is no longer connected")
	
	# Remove all stale players
	for stale_peer_id in stale_peers:
		print("Cleaning up stale player: ", stale_peer_id)
		
		# Save player data before removing
		_save_player_data(stale_peer_id)
		
		# Remove from world manager
		if world_manager and world_manager.world_data:
			world_manager.world_data.unregister_peer(stale_peer_id)
		
		# Despawn locally and notify all clients
		_despawn_player(stale_peer_id)
		rpc("despawn_player", stale_peer_id)
	
	if stale_peers.size() > 0:
		print("Cleaned up ", stale_peers.size(), " stale connections")

func _handle_connection_failure():
	if not is_client_mode:
		return
	
	print("Connection failed, scheduling reconnection...")
	_schedule_next_reconnection()

func _monitor_connection(delta: float):
	# Only monitor if we think we're connected
	if connection_state != ConnectionState.CONNECTED:
		return
	
	# Check if we've received any communication from server recently
	var _current_time = Time.get_ticks_msec() / 1000.0
	
	# Send periodic heartbeat to server
	last_heartbeat_time += delta
	if last_heartbeat_time >= heartbeat_interval:
		_send_heartbeat()
		last_heartbeat_time = 0.0
	
	# Check for connection timeout (simplified approach)
	# In a real implementation, you'd track when you last received data from server
	var peer = multiplayer.multiplayer_peer
	if peer and peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		print("Connection status changed, detected disconnection")
		_handle_server_disconnection()

func _send_heartbeat():
	# Send a lightweight heartbeat RPC to server
	if connection_state == ConnectionState.CONNECTED and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.get_unique_id() != 1:
		rpc_id(1, "client_heartbeat", multiplayer.get_unique_id())

@rpc("any_peer", "call_remote", "unreliable")
func client_heartbeat(_peer_id: int):
	# Server receives heartbeat from client
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED and multiplayer.is_server():
		# Simply acknowledge the heartbeat (could update last seen time)
		pass

func _show_access_denied_message():
	# Simple access denied message
	print("=== ACCESS DENIED ===")
	print("This UUID player is bound to a different device.")
	print("Press F1 to open device binding settings.")
	print("You can transfer the player to this device if you own it.")
	print("Or disable device binding to allow cross-device access.")
	print("========================")

func _notification(what):
	# Save positions when the application is about to quit
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_emergency_save_all_positions()

func _auto_save_all_player_positions():
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED and multiplayer.is_server() and world_manager and world_manager.world_data:
		var saved_count = 0
		for peer_id in players.keys():
			var persistent_id = player_persistent_ids.get(peer_id, "")
			if persistent_id != "":
				var current_pos = players[peer_id].position
				world_manager.world_data.update_player_position(persistent_id, current_pos)
				saved_count += 1
				print("Auto-saved ", persistent_id, " (peer ", peer_id, ") at ", current_pos)
		
		if saved_count > 0:
			# Save to file once after updating all positions
			world_manager.save_world_data()
			print("Auto-saved ", saved_count, " player positions to file")

func _emergency_save_all_positions():
	# Force save all player positions immediately
	if world_manager and world_manager.world_data:
		_auto_save_all_player_positions()
		print("Emergency save: Player positions saved before shutdown")

func _on_player_connected(id):
	print("Player connected: ", id)
	if multiplayer.is_server():
		# Request client ID from the connecting player
		rpc_id(id, "request_client_id")
	else:
		# Client side: send our client ID to server
		if user_identity:
			var my_client_id = user_identity.get_client_id()
			var my_chosen_player_num = user_identity.get_chosen_player_number()
			var my_device_fingerprint = user_identity.get_device_fingerprint()
			rpc_id(1, "receive_client_id", id, my_client_id, my_chosen_player_num, my_device_fingerprint)
		
func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	if multiplayer.is_server():
		# Save player data before despawning
		_save_player_data(id)
		_unregister_player(id)
		_despawn_player(id)
		rpc("despawn_player", id)

func _spawn_player(peer_id: int, pos: Vector2, persistent_id: String):
	var player = load("res://entities/players/player_entity.tscn").instantiate()
	player.name = str(peer_id)
	player.position = pos
	player.player_id = peer_id
	get_parent().get_node("SpawnContainer").add_child(player)
	players[peer_id] = player
	player_persistent_ids[peer_id] = persistent_id
	
	# Set the persistent ID on the player for label display
	player.set_persistent_id(persistent_id)
	
	# Immediately save the initial spawn position to persistent data
	if multiplayer.is_server() and world_manager and world_manager.world_data:
		world_manager.world_data.update_player_position(persistent_id, pos)

func _despawn_player(peer_id: int):
	if peer_id in players:
		players[peer_id].queue_free()
		players.erase(peer_id)
		player_persistent_ids.erase(peer_id)

@rpc("any_peer", "call_local", "reliable")
func spawn_player(peer_id: int, pos: Vector2, persistent_id: String):
	if not multiplayer.is_server():
		_spawn_player(peer_id, pos, persistent_id)

@rpc("any_peer", "call_local", "reliable") 
func despawn_player(id: int):
	if not multiplayer.is_server():
		_despawn_player(id)

# ==================== NPC SPAWNING SYSTEM ====================

func spawn_npc(npc_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String:
	"""Server-authoritative NPC spawning"""
	if not multiplayer.is_server():
		print("WARNING: Only server can spawn NPCs")
		return ""
	
	var npc_id = "npc_" + str(next_npc_id)
	next_npc_id += 1
	
	# Spawn locally first
	_spawn_npc_locally(npc_id, npc_type, spawn_pos, config_data)
	
	# Broadcast to all clients
	rpc("sync_npc_spawn", npc_id, npc_type, spawn_pos, config_data)
	
	print("Spawned NPC: ", npc_type, " with ID: ", npc_id, " at ", spawn_pos)
	return npc_id

func _spawn_npc_locally(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Spawn NPC locally on this client"""
	var npc_scene_path = "res://entities/npcs/" + npc_type + ".tscn"
	
	if not ResourceLoader.exists(npc_scene_path):
		print("ERROR: NPC scene not found: ", npc_scene_path)
		return
	
	var npc = load(npc_scene_path).instantiate()
	npc.name = npc_id
	npc.position = pos
	
	# Configure NPC with spawn data
	if npc.has_method("configure_npc"):
		npc.configure_npc(config)
	
	# Add to spawn container (same as players)
	get_parent().get_node("SpawnContainer").add_child(npc)
	npcs[npc_id] = npc
	
	print("Spawned NPC locally: ", npc_id, " at ", pos)

func despawn_npc(npc_id: String):
	"""Remove NPC (server authority)"""
	if not multiplayer.is_server():
		return
	
	_despawn_npc_locally(npc_id)
	rpc("sync_npc_despawn", npc_id)

func _despawn_npc_locally(npc_id: String):
	"""Remove NPC locally"""
	if npc_id in npcs:
		npcs[npc_id].queue_free()
		npcs.erase(npc_id)
		print("Despawned NPC: ", npc_id)

@rpc("authority", "call_local", "reliable")
func sync_npc_spawn(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Synchronize NPC spawn to clients"""
	if not multiplayer.is_server():
		_spawn_npc_locally(npc_id, npc_type, pos, config)

@rpc("authority", "call_local", "reliable")
func sync_npc_despawn(npc_id: String):
	"""Synchronize NPC despawn to clients"""
	if not multiplayer.is_server():
		_despawn_npc_locally(npc_id)

# ==================== DEBUG FUNCTIONS ====================

func debug_spawn_test_npc():
	"""Debug: Spawn a test NPC at a fixed location"""
	if not multiplayer.is_server():
		print("Only server can spawn NPCs")
		return
	
	var spawn_pos = Vector2(200, 100)  # Fixed test position
	spawn_npc("test_npc", spawn_pos, {"patrol_speed": 75})
	print("Debug: Spawned TestNPC at ", spawn_pos)

func debug_list_npcs():
	"""Debug: List all current NPCs"""
	print("=== NPC DEBUG INFO ===")
	print("Total NPCs: ", npcs.size())
	for npc_id in npcs:
		var npc = npcs[npc_id]
		print("  ", npc_id, ": ", npc.npc_type, " at ", npc.position)
	print("=====================")

@rpc("authority", "call_remote", "reliable")
func connection_rejected(reason: String):
	# Client receives rejection from server
	print("CONNECTION REJECTED: ", reason)
	print("Shutting down...")
	get_tree().quit()

@rpc("any_peer", "call_remote", "unreliable")
func update_player_position(id: int, pos: Vector2, timestamp: float = 0.0):
	# Direct position update with latency tracking
	if id in players:
		players[id].receive_network_position(pos, timestamp)
	
	# Update persistent world data (server only, periodically) 
	if multiplayer.is_server() and world_manager and world_manager.world_data:
		var persistent_id = player_persistent_ids.get(id, "")
		if persistent_id != "":
			world_manager.world_data.update_player_position(persistent_id, pos)

@rpc("any_peer", "call_remote", "reliable")
func request_terrain_modification(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int):
	# Server receives terrain modification request from client
	if multiplayer.is_server():
		if world_manager:
			world_manager.modify_terrain(coords, source_id, atlas_coords, alternative_tile)

@rpc("authority", "call_local", "reliable")
func sync_terrain_modification(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int):
	if world_manager:
		world_manager.sync_terrain_modification(coords, source_id, atlas_coords, alternative_tile)

# Client ID exchange RPCs
@rpc("authority", "call_remote", "reliable")
func request_client_id():
	# Client receives request for client ID from server
	if user_identity and not multiplayer.is_server():
		var my_client_id = user_identity.get_client_id()
		var my_peer_id = multiplayer.get_unique_id()
		var my_chosen_player_num = user_identity.get_chosen_player_number()
		var my_device_fingerprint = user_identity.get_device_fingerprint()
		rpc_id(1, "receive_client_id", my_peer_id, my_client_id, my_chosen_player_num, my_device_fingerprint)

@rpc("any_peer", "call_remote", "reliable")
func receive_client_id(peer_id: int, client_id: String, chosen_player_num: int = -1, device_fingerprint: String = ""):
	# Server receives client ID from connecting player
	if multiplayer.is_server():
		
		# SERVER-SIDE DEVICE BINDING VALIDATION
		if chosen_player_num != -1:
			var player_id = "player_" + str(chosen_player_num)
			
			# Check if this player is already bound to a different device
			if player_id in server_device_bindings:
				var bound_device = server_device_bindings[player_id]
				if bound_device != device_fingerprint:
					print("SERVER: REJECTING - Player ", chosen_player_num, " is bound to different device")
					print("SERVER: Bound device: ", bound_device.substr(0, 16), "...")
					print("SERVER: Requesting device: ", device_fingerprint.substr(0, 16), "...")
					rpc_id(peer_id, "connection_rejected", "Player " + str(chosen_player_num) + " is bound to a different device")
					multiplayer.disconnect_peer(peer_id)
					return
			else:
				# First time using this player number - bind to this device
				server_device_bindings[player_id] = device_fingerprint
				_save_server_device_bindings()
				print("SERVER: Bound player ", chosen_player_num, " to device ", device_fingerprint.substr(0, 16), "...")
		
		# Clean up any stale/disconnected players first
		_cleanup_stale_connections()
		
		# Clean up any old instances of this client before registering new one
		_cleanup_old_client_instances(client_id, peer_id)
		
		# Register the player with their client ID and chosen number
		var persistent_id = _register_player_with_client_id(peer_id, client_id, chosen_player_num)
		
		# Send world state to new player
		if world_manager:
			world_manager.send_world_state_to_client(peer_id)
		
		# Send existing players to new player
		for existing_peer_id in players.keys():
			var existing_persistent_id = player_persistent_ids[existing_peer_id]
			rpc_id(peer_id, "spawn_player", existing_peer_id, players[existing_peer_id].position, existing_persistent_id)
		
		# Spawn new player with persistent data and notify all clients
		var spawn_pos = _get_player_spawn_position(persistent_id)
		_spawn_player(peer_id, spawn_pos, persistent_id)
		rpc("spawn_player", peer_id, spawn_pos, persistent_id)

# Player persistence helper functions
func _register_player(peer_id: int) -> String:
	if world_manager and world_manager.world_data and user_identity:
		var client_id = user_identity.get_client_id()
		var chosen_num = user_identity.get_chosen_player_number()
		return world_manager.world_data.register_client(client_id, peer_id, chosen_num)
	else:
		print("Warning: No world manager or user identity available for player registration")
		return "player_" + str(peer_id)

func _register_player_with_client_id(peer_id: int, client_id: String, chosen_player_num: int = -1) -> String:
	if world_manager and world_manager.world_data:
		return world_manager.world_data.register_client(client_id, peer_id, chosen_player_num)
	else:
		print("Warning: No world manager available for player registration")
		return "player_" + str(peer_id)

func _unregister_player(peer_id: int):
	if world_manager and world_manager.world_data:
		world_manager.world_data.unregister_peer(peer_id)

func _get_player_spawn_position(persistent_id: String) -> Vector2:
	if world_manager and world_manager.world_data:
		var player_data = world_manager.world_data.get_player(persistent_id)
		print("Getting spawn position for ", persistent_id, ": ", player_data["position"])
		
		# Debug: Check if this is returning default data
		if player_data["position"] == Vector2(100, 100):
			print("WARNING: Player ", persistent_id, " not found in world data, using default spawn")
			print("Available players in world data: ", world_manager.world_data.player_data.keys())
		
		return player_data["position"]
	else:
		# Fallback to default spawn if no world data
		print("No persistent data found for player ", persistent_id, ", using default spawn")
		return Vector2(100, 100)

func _load_server_device_bindings():
	"""Load server device bindings from file"""
	if FileAccess.file_exists(SERVER_DEVICE_BINDINGS_FILE):
		var file = FileAccess.open(SERVER_DEVICE_BINDINGS_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				server_device_bindings = json.data
				print("GameManager: Loaded ", server_device_bindings.size(), " server device bindings")
			else:
				print("GameManager: Failed to parse server device bindings JSON")
		else:
			print("GameManager: Failed to read server device bindings file")
	else:
		print("GameManager: No existing server device bindings file")

func _save_server_device_bindings():
	"""Save server device bindings to file"""
	var file = FileAccess.open(SERVER_DEVICE_BINDINGS_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(server_device_bindings)
		file.store_string(json_string)
		file.close()
		print("GameManager: Saved ", server_device_bindings.size(), " server device bindings")
	else:
		print("GameManager: Failed to save server device bindings")

func _save_player_data(peer_id: int):
	if world_manager and world_manager.world_data and peer_id in players and peer_id in player_persistent_ids:
		var player = players[peer_id]
		var persistent_id = player_persistent_ids[peer_id]
		var current_pos = player.position
		
		# For now, just save position. Later we can expand to save health, inventory, etc.
		world_manager.world_data.save_player(persistent_id, current_pos)
		world_manager.save_world_data()  # Save to file
