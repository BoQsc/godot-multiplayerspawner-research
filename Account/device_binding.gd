extends Node
class_name DeviceBinding

# Device binding system for anonymous UUID players only
# Protects anonymous players from others accessing their UUID on shared computers

const DEVICE_BINDINGS_FILE = "user://anonymous_device_bindings.dat"

var anonymous_bindings: Dictionary = {}  # uuid_player -> device_fingerprint
var current_device_fingerprint: String = ""

signal device_binding_changed(uuid_player: String, enabled: bool)

func _ready():
	generate_device_fingerprint()
	load_anonymous_bindings()
	print("DeviceBinding: Device fingerprint: ", current_device_fingerprint.substr(0, 16), "...")

func generate_device_fingerprint() -> String:
	"""Generate unique device fingerprint based on hardware characteristics"""
	var factors = []
	
	# Hardware identifiers
	factors.append(OS.get_unique_id())
	factors.append(OS.get_processor_name())
	factors.append(str(OS.get_processor_count()))
	
	# System information
	factors.append(OS.get_model_name())
	factors.append(OS.get_name())
	factors.append(OS.get_version())
	
	# Display information (if available)
	if DisplayServer.get_name() != "headless":
		factors.append(str(DisplayServer.screen_get_size()))
		if DisplayServer.screen_get_dpi() > 0:
			factors.append(str(DisplayServer.screen_get_dpi()))
	
	# Environment information
	factors.append(OS.get_environment("USERNAME"))
	factors.append(OS.get_environment("COMPUTERNAME"))
	
	# Create fingerprint hash
	var fingerprint_data = "|".join(factors)
	current_device_fingerprint = fingerprint_data.sha256_text()
	
	return current_device_fingerprint

func get_device_fingerprint() -> String:
	"""Get current device fingerprint"""
	if current_device_fingerprint == "":
		generate_device_fingerprint()
	return current_device_fingerprint

func load_anonymous_bindings():
	"""Load existing anonymous device bindings from file"""
	if FileAccess.file_exists(DEVICE_BINDINGS_FILE):
		var file = FileAccess.open(DEVICE_BINDINGS_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				anonymous_bindings = json.data
				print("DeviceBinding: Loaded ", anonymous_bindings.size(), " anonymous bindings")
			else:
				print("DeviceBinding: Failed to parse bindings file")
				anonymous_bindings = {}
		else:
			print("DeviceBinding: Could not open bindings file for reading")
			anonymous_bindings = {}
	else:
		print("DeviceBinding: No existing bindings file found")
		anonymous_bindings = {}

func save_anonymous_bindings():
	"""Save anonymous device bindings to file"""
	var file = FileAccess.open(DEVICE_BINDINGS_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(anonymous_bindings)
		file.store_string(json_string)
		file.close()
		print("DeviceBinding: Saved ", anonymous_bindings.size(), " anonymous bindings")
	else:
		print("DeviceBinding: Failed to save anonymous bindings")

func enable_device_binding(uuid_player: String, enabled: bool):
	"""Enable or disable device binding for anonymous UUID player"""
	if enabled:
		anonymous_bindings[uuid_player] = current_device_fingerprint
		print("DeviceBinding: Enabled binding for ", uuid_player)
	else:
		if uuid_player in anonymous_bindings:
			anonymous_bindings.erase(uuid_player)
			print("DeviceBinding: Disabled binding for ", uuid_player)
	
	save_anonymous_bindings()
	device_binding_changed.emit(uuid_player, enabled)

func is_device_binding_enabled(uuid_player: String) -> bool:
	"""Check if device binding is enabled for UUID player"""
	return uuid_player in anonymous_bindings

func can_access_uuid_on_this_device(uuid_player: String) -> bool:
	"""Check if current device can access the UUID player"""
	if uuid_player in anonymous_bindings:
		var bound_device = anonymous_bindings[uuid_player]
		var current_device = get_device_fingerprint()
		return bound_device == current_device
	
	# No binding = open access
	return true

func get_bound_device_info(uuid_player: String) -> Dictionary:
	"""Get information about device binding for UUID player"""
	if uuid_player in anonymous_bindings:
		var bound_device = anonymous_bindings[uuid_player]
		return {
			"bound": true,
			"device_fingerprint": bound_device,
			"is_current_device": bound_device == current_device_fingerprint,
			"short_fingerprint": bound_device.substr(0, 16) + "..."
		}
	else:
		return {
			"bound": false,
			"device_fingerprint": "",
			"is_current_device": true,
			"short_fingerprint": "No binding"
		}

func transfer_uuid_to_this_device(uuid_player: String):
	"""Transfer UUID player binding to current device (for device migration)"""
	if uuid_player in anonymous_bindings:
		anonymous_bindings[uuid_player] = current_device_fingerprint
		save_anonymous_bindings()
		print("DeviceBinding: Transferred ", uuid_player, " to current device")
		device_binding_changed.emit(uuid_player, true)

func get_all_bound_uuids() -> Array:
	"""Get all UUID players bound to current device"""
	var bound_uuids = []
	var current_device = get_device_fingerprint()
	
	for uuid_player in anonymous_bindings.keys():
		if anonymous_bindings[uuid_player] == current_device:
			bound_uuids.append(uuid_player)
	
	return bound_uuids

func get_binding_statistics() -> Dictionary:
	"""Get statistics about device bindings"""
	var current_device = get_device_fingerprint()
	var bound_to_this_device = 0
	var bound_to_other_devices = 0
	
	for device_fp in anonymous_bindings.values():
		if device_fp == current_device:
			bound_to_this_device += 1
		else:
			bound_to_other_devices += 1
	
	return {
		"total_bindings": anonymous_bindings.size(),
		"bound_to_this_device": bound_to_this_device,
		"bound_to_other_devices": bound_to_other_devices,
		"current_device_fingerprint": current_device.substr(0, 16) + "..."
	}

# Debug functions
func clear_all_bindings():
	"""Clear all anonymous device bindings (debug/admin function)"""
	anonymous_bindings.clear()
	save_anonymous_bindings()
	print("DeviceBinding: Cleared all anonymous bindings")

func print_debug_info():
	"""Print debug information about device bindings"""
	print("=== Device Binding Debug Info ===")
	print("Current device: ", current_device_fingerprint.substr(0, 32), "...")
	print("Total bindings: ", anonymous_bindings.size())
	
	for uuid_player in anonymous_bindings.keys():
		var bound_device = anonymous_bindings[uuid_player]
		var is_current = bound_device == current_device_fingerprint
		print("  ", uuid_player, " -> ", bound_device.substr(0, 16), "... ", "(current)" if is_current else "(other)")
