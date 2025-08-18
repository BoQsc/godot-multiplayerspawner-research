@tool
extends Control

@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var toolbar: HBoxContainer = $VBoxContainer/Toolbar
@onready var bold_button: Button = $VBoxContainer/Toolbar/BoldButton
@onready var italic_button: Button = $VBoxContainer/Toolbar/ItalicButton
@onready var underline_button: Button = $VBoxContainer/Toolbar/UnderlineButton
@onready var code_button: Button = $VBoxContainer/Toolbar/CodeButton
@onready var clear_button: Button = $VBoxContainer/Toolbar/ClearButton

const NOTES_SAVE_PATH = "user://editor_notes.txt"

func _ready():
	setup_toolbar()
	load_notes()
	
	text_edit.text_changed.connect(_on_text_changed)

func setup_toolbar():
	bold_button.pressed.connect(_on_bold_pressed)
	italic_button.pressed.connect(_on_italic_pressed)
	underline_button.pressed.connect(_on_underline_pressed)
	code_button.pressed.connect(_on_code_pressed)
	clear_button.pressed.connect(_on_clear_pressed)

func _on_bold_pressed():
	text_edit.grab_focus()
	var selection = text_edit.get_selected_text()
	if selection != "":
		text_edit.insert_text_at_caret("**" + selection + "**")
	else:
		text_edit.insert_text_at_caret("****")
		text_edit.set_caret_column(text_edit.get_caret_column() - 2)
		
func _on_italic_pressed():
	text_edit.grab_focus()
	var selection = text_edit.get_selected_text()
	if selection != "":
		text_edit.insert_text_at_caret("*" + selection + "*")
	else:
		text_edit.insert_text_at_caret("**")
		text_edit.set_caret_column(text_edit.get_caret_column() - 1)

func _on_underline_pressed():
	text_edit.grab_focus()
	var selection = text_edit.get_selected_text()
	if selection != "":
		text_edit.insert_text_at_caret("_" + selection + "_")
	else:
		text_edit.insert_text_at_caret("__")
		text_edit.set_caret_column(text_edit.get_caret_column() - 1)

func _on_code_pressed():
	text_edit.grab_focus()
	var selection = text_edit.get_selected_text()
	if selection != "":
		text_edit.insert_text_at_caret("`" + selection + "`")
	else:
		text_edit.insert_text_at_caret("``")
		text_edit.set_caret_column(text_edit.get_caret_column() - 1)

func _on_clear_pressed():
	text_edit.clear()
	save_notes()

func _on_text_changed():
	save_notes()

func save_notes():
	var file = FileAccess.open(NOTES_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(text_edit.text)
		file.close()

func load_notes():
	if FileAccess.file_exists(NOTES_SAVE_PATH):
		var file = FileAccess.open(NOTES_SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			text_edit.text = content