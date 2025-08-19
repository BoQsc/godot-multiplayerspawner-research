@tool
extends Control

const RichEditor = preload("res://addons/editor_notes/rich_editor.gd")

var rich_editor: RichEditor

# Formatting buttons
@onready var bold_btn: Button = $VBoxContainer/Toolbar/FormattingRow/BoldBtn
@onready var italic_btn: Button = $VBoxContainer/Toolbar/FormattingRow/ItalicBtn
@onready var underline_btn: Button = $VBoxContainer/Toolbar/FormattingRow/UnderlineBtn
@onready var strikethrough_btn: Button = $VBoxContainer/Toolbar/FormattingRow/StrikethroughBtn
@onready var code_btn: Button = $VBoxContainer/Toolbar/FormattingRow/CodeBtn

# Structure buttons
@onready var heading_btn: MenuButton = $VBoxContainer/Toolbar/StructureRow/HeadingBtn
@onready var list_btn: MenuButton = $VBoxContainer/Toolbar/StructureRow/ListBtn
@onready var quote_btn: Button = $VBoxContainer/Toolbar/StructureRow/QuoteBtn
@onready var code_block_btn: Button = $VBoxContainer/Toolbar/StructureRow/CodeBlockBtn
@onready var hr_btn: Button = $VBoxContainer/Toolbar/StructureRow/HRBtn

# Insert buttons
@onready var link_btn: Button = $VBoxContainer/Toolbar/InsertRow/LinkBtn
@onready var image_btn: Button = $VBoxContainer/Toolbar/InsertRow/ImageBtn
@onready var table_btn: Button = $VBoxContainer/Toolbar/InsertRow/TableBtn
@onready var clear_btn: Button = $VBoxContainer/Toolbar/InsertRow/ClearBtn

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
	# Formatting buttons
	bold_btn.pressed.connect(func(): toggle_formatting("bold"))
	italic_btn.pressed.connect(func(): toggle_formatting("italic"))
	underline_btn.pressed.connect(func(): toggle_formatting("underline"))
	strikethrough_btn.pressed.connect(func(): toggle_formatting("strikethrough"))
	code_btn.pressed.connect(func(): toggle_formatting("code"))
	
	# Setup heading menu
	setup_heading_menu()
	
	# Setup list menu  
	setup_list_menu()
	
	# Structure buttons
	quote_btn.pressed.connect(_insert_blockquote)
	code_block_btn.pressed.connect(_insert_code_block)
	hr_btn.pressed.connect(_insert_horizontal_rule)
	
	# Insert buttons
	link_btn.pressed.connect(_insert_link)
	image_btn.pressed.connect(_insert_image)
	table_btn.pressed.connect(_insert_table)
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
	var popup = heading_btn.get_popup()
	popup.add_item("H1", 0)
	popup.add_item("H2", 1)
	popup.add_item("H3", 2)
	popup.add_item("H4", 3)
	popup.add_item("H5", 4)
	popup.add_item("H6", 5)
	popup.id_pressed.connect(_on_heading_selected)

func setup_list_menu():
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