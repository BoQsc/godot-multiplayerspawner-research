@tool
extends Control

const RichEditor = preload("res://addons/editor_notes/rich_editor.gd")

var rich_editor: RichEditor

# All buttons - will be found manually
var bold_btn: Button
var italic_btn: Button
var underline_btn: Button
var strikethrough_btn: Button
var code_btn: Button
var heading_btn: MenuButton
var list_btn: MenuButton
var quote_btn: Button
var code_block_btn: Button
var hr_btn: Button
var link_btn: Button
var image_btn: Button
var table_btn: Button
var clear_btn: Button

const SAVE_PATH = "user://editor_notes.txt"

func _ready():
	setup_rich_editor()
	setup_toolbar()
	load_notes()

func setup_rich_editor():
	# Create the rich editor
	rich_editor = RichEditor.new()
	rich_editor.name = "RichEditor"
	rich_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$VBoxContainer.add_child(rich_editor)
	
	# Connect signals
	rich_editor.text_changed.connect(_on_text_changed)

func setup_toolbar():
	# Find all toolbar buttons manually
	bold_btn = get_node_or_null("VBoxContainer/Toolbar/BoldBtn")
	italic_btn = get_node_or_null("VBoxContainer/Toolbar/ItalicBtn")
	underline_btn = get_node_or_null("VBoxContainer/Toolbar/UnderlineBtn")
	strikethrough_btn = get_node_or_null("VBoxContainer/Toolbar/StrikethroughBtn")
	code_btn = get_node_or_null("VBoxContainer/Toolbar/CodeBtn")
	heading_btn = get_node_or_null("VBoxContainer/Toolbar/HeadingBtn")
	list_btn = get_node_or_null("VBoxContainer/Toolbar/ListBtn")
	quote_btn = get_node_or_null("VBoxContainer/Toolbar/QuoteBtn")
	code_block_btn = get_node_or_null("VBoxContainer/Toolbar/CodeBlockBtn")
	hr_btn = get_node_or_null("VBoxContainer/Toolbar/HRBtn")
	link_btn = get_node_or_null("VBoxContainer/Toolbar/LinkBtn")
	image_btn = get_node_or_null("VBoxContainer/Toolbar/ImageBtn")
	table_btn = get_node_or_null("VBoxContainer/Toolbar/TableBtn")
	clear_btn = get_node_or_null("VBoxContainer/Toolbar/ClearBtn")
	
	# Formatting buttons - with null checks
	if bold_btn:
		bold_btn.pressed.connect(func(): toggle_formatting("bold"))
	else:
		print("ERROR: bold_btn is null!")
	
	if italic_btn:
		italic_btn.pressed.connect(func(): toggle_formatting("italic"))
	if underline_btn:
		underline_btn.pressed.connect(func(): toggle_formatting("underline"))
	if strikethrough_btn:
		strikethrough_btn.pressed.connect(func(): toggle_formatting("strikethrough"))
	if code_btn:
		code_btn.pressed.connect(func(): toggle_formatting("code"))
	
	# Setup heading menu
	setup_heading_menu()
	
	# Setup list menu  
	setup_list_menu()
	
	# Structure buttons - with null checks
	if quote_btn:
		quote_btn.pressed.connect(_insert_blockquote)
	if code_block_btn:
		code_block_btn.pressed.connect(_insert_code_block)
	if hr_btn:
		hr_btn.pressed.connect(_insert_horizontal_rule)
	
	# Insert buttons - with null checks
	if link_btn:
		link_btn.pressed.connect(_insert_link)
	if image_btn:
		image_btn.pressed.connect(_insert_image)
	if table_btn:
		table_btn.pressed.connect(_insert_table)
	if clear_btn:
		clear_btn.pressed.connect(_clear_all)

func toggle_formatting(format_type: String):
	if not rich_editor:
		return
	
	# Toggle the specific formatting type
	match format_type:
		"bold":
			rich_editor.toggle_formatting_type("bold")
		"italic":
			rich_editor.toggle_formatting_type("italic")
		"underline":
			rich_editor.toggle_formatting_type("underline")
		"strikethrough":
			rich_editor.toggle_formatting_type("strikethrough")
		"code":
			rich_editor.toggle_formatting_type("code")

func _clear_all():
	if rich_editor:
		rich_editor.save_state()  # Save state before clearing
		rich_editor.set_text("")
		save_notes()

func _on_text_changed():
	call_deferred("save_notes")

func save_notes():
	if not rich_editor:
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(rich_editor.get_text())
		file.close()

func load_notes():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		if rich_editor:
			rich_editor.set_text(content)

func setup_heading_menu():
	if not heading_btn:
		return
	var popup = heading_btn.get_popup()
	popup.add_item("H1", 0)
	popup.add_item("H2", 1)
	popup.add_item("H3", 2)
	popup.add_item("H4", 3)
	popup.add_item("H5", 4)
	popup.add_item("H6", 5)
	popup.id_pressed.connect(_on_heading_selected)

func setup_list_menu():
	if not list_btn:
		return
	var popup = list_btn.get_popup()
	popup.add_item("• Bullet List", 0)
	popup.add_item("1. Numbered List", 1)
	popup.add_item("☐ Checklist", 2)
	popup.id_pressed.connect(_on_list_selected)

func _on_heading_selected(id: int):
	if not rich_editor:
		return
	var heading_level = id + 1
	rich_editor.insert_heading(heading_level)

func _on_list_selected(id: int):
	if not rich_editor:
		return
	match id:
		0: # Bullet list
			rich_editor.insert_list_item("bullet")
		1: # Numbered list
			rich_editor.insert_list_item("numbered")
		2: # Checklist
			rich_editor.insert_list_item("checklist")

func _insert_blockquote():
	if rich_editor:
		rich_editor.insert_blockquote()

func _insert_code_block():
	if rich_editor:
		rich_editor.insert_code_block()

func _insert_horizontal_rule():
	if rich_editor:
		rich_editor.insert_horizontal_rule()

func _insert_link():
	if rich_editor:
		rich_editor.insert_link()

func _insert_image():
	if rich_editor:
		rich_editor.insert_image()

func _insert_table():
	if rich_editor:
		rich_editor.insert_table()