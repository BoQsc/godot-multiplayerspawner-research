extends Control
class_name DeviceBindingUI

# Simple in-game UI for device binding settings (anonymous players only)

var client_identity: ClientIdentity
var device_binding_panel: Panel
var binding_checkbox: CheckBox
var info_label: Label
var transfer_button: Button
var close_button: Button

signal ui_closed()

func _ready():
	create_ui()
	update_ui()

func create_ui():
	"""Create the device binding UI elements"""
	# Main panel
	device_binding_panel = Panel.new()
	device_binding_panel.size = Vector2(400, 300)
	device_binding_panel.position = Vector2(50, 50)
	add_child(device_binding_panel)
	
	# VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(360, 260)
	device_binding_panel.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Anonymous Player Device Binding"
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	
	# Spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Device binding checkbox
	binding_checkbox = CheckBox.new()
	binding_checkbox.text = "Protect this character on this device only (recommended)"
	binding_checkbox.toggled.connect(_on_binding_toggled)
	vbox.add_child(binding_checkbox)
	
	# Info label
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(360, 100)
	vbox.add_child(info_label)
	
	# Spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Button container
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	# Transfer button (for device migration)
	transfer_button = Button.new()
	transfer_button.text = "Transfer to This Device"
	transfer_button.pressed.connect(_on_transfer_pressed)
	button_hbox.add_child(transfer_button)
	
	# Spacer between buttons
	var button_spacer = Control.new()
	button_spacer.custom_minimum_size = Vector2(20, 0)
	button_hbox.add_child(button_spacer)
	
	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_pressed)
	button_hbox.add_child(close_button)
	
	# Handle escape key to close
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_ui()

func set_client_identity(identity: ClientIdentity):
	"""Set the client identity reference"""
	client_identity = identity
	update_ui()

func update_ui():
	"""Update UI elements based on current state"""
	if not client_identity:
		return
	
	var binding_info = client_identity.get_device_binding_info()
	var can_access = client_identity.can_access_current_uuid()
	
	# Update checkbox state
	binding_checkbox.set_pressed_no_signal(client_identity.is_uuid_device_binding_enabled())
	
	# Update info text
	var info_text = ""
	info_text += "UUID Player: " + client_identity.get_uuid_player_id() + "\n"
	info_text += "Device: " + binding_info.get("short_fingerprint", "Unknown") + "\n\n"
	
	if binding_info.get("bound", false):
		if binding_info.get("is_current_device", false):
			info_text += "🔐 This character is automatically protected on this device.\n"
			info_text += "Others cannot access it from different computers.\n"
			info_text += "Device binding will be disabled if you register an account."
		else:
			info_text += "🔒 This character is bound to a different device.\n"
			info_text += "Use 'Transfer to This Device' to move it here."
	else:
		info_text += "⚠️ This character is NOT protected.\n"
		info_text += "Others can access it from any computer.\n"
		info_text += "Enable binding to restrict access to this device only."
	
	info_label.text = info_text
	
	# Update transfer button visibility
	transfer_button.visible = binding_info.get("bound", false) and not binding_info.get("is_current_device", false)
	
	# Disable controls if we can't access this UUID
	binding_checkbox.disabled = not can_access
	if not can_access:
		info_label.text += "\n❌ ACCESS DENIED: This UUID is bound to another device."

func _on_binding_toggled(pressed: bool):
	"""Handle device binding checkbox toggle"""
	if client_identity:
		client_identity.enable_uuid_device_binding(pressed)
		update_ui()

func _on_transfer_pressed():
	"""Handle transfer to this device button"""
	if client_identity:
		client_identity.transfer_uuid_to_this_device()
		update_ui()

func _on_close_pressed():
	"""Handle close button"""
	close_ui()

func close_ui():
	"""Close the UI and emit signal"""
	ui_closed.emit()
	queue_free()

func show_ui():
	"""Show the device binding UI"""
	visible = true
	# Set focus mode and grab focus for keyboard input
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()

func hide_ui():
	"""Hide the device binding UI"""
	visible = false

# Static function to create and show device binding UI
static func show_device_binding_ui(parent: Node, client_id: ClientIdentity) -> DeviceBindingUI:
	"""Create and show device binding UI"""
	var ui = DeviceBindingUI.new()
	parent.add_child(ui)
	ui.set_client_identity(client_id)
	ui.show_ui()
	return ui
