# UPnP Implementation for Godot Multiplayer
# Extracted from MultiplayerSpawner script for easy reading and reference
# 
# This file contains all UPnP-related functionality used in the project
# for automatic port forwarding in multiplayer games.

extends Node

# UPnP related variables
var upnp: UPNP
var upnp_thread: Thread
var upnp_setup_complete: bool = false

# Signals for UPnP status
signal upnp_completed(success: bool, error: String)

# Server configuration
@export var server_port: int = 8910

func _ready():
	# Connect to UPnP completion signal
	upnp_completed.connect(_on_upnp_completed)

# ============================================================================
# UPnP Setup Functions
# ============================================================================

func start_upnp_setup():
	"""Start UPnP port forwarding setup in a background thread"""
	print("Starting UPnP port forwarding setup...")
	upnp_thread = Thread.new()
	upnp_thread.start(_upnp_setup_threaded)

func _upnp_setup_threaded():
	"""Threaded UPnP setup process - runs in background"""
	upnp = UPNP.new()
	
	print("Discovering UPnP devices...")
	var discover_result = upnp.discover()
	
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		var error_msg = "UPnP discovery failed: " + _get_upnp_error_string(discover_result)
		call_deferred("_emit_upnp_completed", false, error_msg)
		return
	
	print("Found ", upnp.get_device_count(), " UPnP devices")
	
	var gateway = upnp.get_gateway()
	if not gateway or not gateway.is_valid_gateway():
		call_deferred("_emit_upnp_completed", false, "No valid UPnP gateway found")
		return
	
	print("Found valid gateway: ", gateway.get_description_url())
	
	# Add port mappings for both UDP and TCP
	var udp_result = upnp.add_port_mapping(server_port, server_port, 
		ProjectSettings.get_setting("application/config/name", "Godot Game"), "UDP")
	var tcp_result = upnp.add_port_mapping(server_port, server_port, 
		ProjectSettings.get_setting("application/config/name", "Godot Game"), "TCP")
	
	if udp_result != UPNP.UPNP_RESULT_SUCCESS:
		var error_msg = "Failed to map UDP port: " + _get_upnp_error_string(udp_result)
		call_deferred("_emit_upnp_completed", false, error_msg)
		return
		
	if tcp_result != UPNP.UPNP_RESULT_SUCCESS:
		var error_msg = "Failed to map TCP port: " + _get_upnp_error_string(tcp_result)
		call_deferred("_emit_upnp_completed", false, error_msg)
		return
	
	# Get external IP
	var external_ip = upnp.query_external_address()
	var success_msg = "Port forwarding successful! External IP: " + external_ip
	call_deferred("_emit_upnp_completed", true, success_msg)

func _emit_upnp_completed(success: bool, message: String):
	"""Emit UPnP completion signal from main thread"""
	upnp_setup_complete = true
	upnp_completed.emit(success, message)

# ============================================================================
# UPnP Event Handlers
# ============================================================================

func _on_upnp_completed(success: bool, message: String):
	"""Handle UPnP setup completion"""
	if success:
		print("✅ UPnP Success: ", message)
		print("Players can connect to your external IP on port ", server_port)
	else:
		print("❌ UPnP Failed: ", message)
		print("You may need to manually forward port ", server_port, " on your router")
		print("Players on your local network can still connect to: ", IP.get_local_addresses())

# ============================================================================
# UPnP Error Handling
# ============================================================================

func _get_upnp_error_string(error_code: UPNP.UPNPResult) -> String:
	"""Convert UPnP error codes to human-readable strings"""
	match error_code:
		UPNP.UPNP_RESULT_SUCCESS:
			return "Success"
		UPNP.UPNP_RESULT_NOT_AUTHORIZED:
			return "Not authorized (UPnP may be disabled on router)"
		UPNP.UPNP_RESULT_PORT_MAPPING_NOT_FOUND:
			return "Port mapping not found"
		UPNP.UPNP_RESULT_INCONSISTENT_PARAMETERS:
			return "Inconsistent parameters"
		UPNP.UPNP_RESULT_NO_SUCH_ENTRY_IN_ARRAY:
			return "No such entry in array"
		UPNP.UPNP_RESULT_ACTION_FAILED:
			return "Action failed"
		UPNP.UPNP_RESULT_INVALID_GATEWAY:
			return "Invalid gateway"
		UPNP.UPNP_RESULT_INVALID_PORT:
			return "Invalid port"
		UPNP.UPNP_RESULT_INVALID_PROTOCOL:
			return "Invalid protocol"
		UPNP.UPNP_RESULT_NO_GATEWAY:
			return "No gateway available"
		UPNP.UPNP_RESULT_NO_DEVICES:
			return "No UPnP devices found"
		_:
			return "Unknown error (" + str(error_code) + ")"

# ============================================================================
# Cleanup Functions
# ============================================================================

func cleanup_upnp():
	"""Clean up UPnP port mappings when done"""
	if upnp and upnp_setup_complete:
		print("Cleaning up UPnP port mappings...")
		upnp.delete_port_mapping(server_port, "UDP")
		upnp.delete_port_mapping(server_port, "TCP")
	
	# Wait for UPnP thread to finish
	if upnp_thread and upnp_thread.is_started():
		upnp_thread.wait_to_finish()

func _exit_tree():
	"""Automatically cleanup when node is removed from tree"""
	cleanup_upnp()

# ============================================================================
# Public API
# ============================================================================

func setup_port_forwarding(port: int = 8910):
	"""Public function to start UPnP port forwarding setup"""
	server_port = port
	start_upnp_setup()

func is_upnp_complete() -> bool:
	"""Check if UPnP setup is complete"""
	return upnp_setup_complete

func get_external_ip() -> String:
	"""Get the external IP address if UPnP is successful"""
	if upnp and upnp_setup_complete:
		return upnp.query_external_address()
	return ""

# ============================================================================
# Usage Example (commented out)
# ============================================================================

# Example of how to use this UPnP implementation:
#
# func _ready():
#     var upnp_handler = preload("res://upnp.gd").new()
#     add_child(upnp_handler)
#     
#     # Connect to the completion signal
#     upnp_handler.upnp_completed.connect(_on_upnp_done)
#     
#     # Start port forwarding for port 8910
#     upnp_handler.setup_port_forwarding(8910)
#
# func _on_upnp_done(success: bool, message: String):
#     if success:
#         print("UPnP successful: ", message)
#     else:
#         print("UPnP failed: ", message)