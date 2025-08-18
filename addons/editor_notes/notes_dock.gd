@tool
extends Control

@onready var text_edit: TextEdit = $VBoxContainer/EditorContainer/TextEdit
@onready var rich_text_label: RichTextLabel = $VBoxContainer/EditorContainer/RichTextLabel
@onready var toggle_button: Button = $VBoxContainer/TitleContainer/ToggleButton

const NOTES_SAVE_PATH = "user://editor_notes.txt"
var is_source_mode = true

func _ready():
	# Connect buttons with lambda functions for immediate execution
	$VBoxContainer/Toolbar/BoldButton.pressed.connect(func(): wrap_selection("**", "**"))
	$VBoxContainer/Toolbar/ItalicButton.pressed.connect(func(): wrap_selection("*", "*"))
	$VBoxContainer/Toolbar/UnderlineButton.pressed.connect(func(): wrap_selection("_", "_"))
	$VBoxContainer/Toolbar/CodeButton.pressed.connect(func(): wrap_selection("`", "`"))
	$VBoxContainer/Toolbar/ClearButton.pressed.connect(func(): text_edit.clear())
	toggle_button.pressed.connect(_on_toggle_pressed)
	
	# Load notes and setup auto-save
	load_notes()
	text_edit.text_changed.connect(_on_text_changed)

func wrap_selection(prefix: String, suffix: String):
	# Get all the info we need IMMEDIATELY
	var full_text = text_edit.text
	var selection_from = text_edit.get_selection_from_column()
	var selection_to = text_edit.get_selection_to_column() 
	var selected_text = text_edit.get_selected_text()
	var caret_line = text_edit.get_caret_line()
	var caret_col = text_edit.get_caret_column()
	
	# Simple check: if no selected text, insert empty formatting
	if selected_text.is_empty():
		text_edit.insert_text_at_caret(prefix + suffix)
		# Move cursor between the formatting
		text_edit.set_caret_column(text_edit.get_caret_column() - suffix.length())
	else:
		# Calculate character positions manually
		var char_start = 0
		for i in range(text_edit.get_selection_from_line()):
			char_start += text_edit.get_line(i).length() + 1
		char_start += selection_from
		
		var char_end = 0  
		for i in range(text_edit.get_selection_to_line()):
			char_end += text_edit.get_line(i).length() + 1
		char_end += selection_to
		
		# Build new text by replacing the selection
		var new_text = full_text.substr(0, char_start) + prefix + selected_text + suffix + full_text.substr(char_end)
		
		# Set the new text
		text_edit.text = new_text
		
		# Position cursor after the formatted text  
		var new_cursor_pos = char_start + prefix.length() + selected_text.length() + suffix.length()
		
		# Convert back to line/column
		var line = 0
		var pos = 0
		while line < text_edit.get_line_count() and pos + text_edit.get_line(line).length() < new_cursor_pos:
			pos += text_edit.get_line(line).length() + 1
			line += 1
		
		text_edit.set_caret_line(line)
		text_edit.set_caret_column(new_cursor_pos - pos)

func _on_toggle_pressed():
	is_source_mode = !is_source_mode
	
	if is_source_mode:
		text_edit.visible = true
		rich_text_label.visible = false
		toggle_button.text = "Source"
		$VBoxContainer/Toolbar.visible = true
	else:
		text_edit.visible = false
		rich_text_label.visible = true
		toggle_button.text = "Render"
		$VBoxContainer/Toolbar.visible = false
		update_render()

func update_render():
	var text = text_edit.text
	
	# Simple regex replacements for markdown to BBCode
	var regex = RegEx.new()
	
	regex.compile("\\*\\*(.*?)\\*\\*")
	text = regex.sub(text, "[b]$1[/b]", true)
	
	regex.compile("\\*(.*?)\\*")  
	text = regex.sub(text, "[i]$1[/i]", true)
	
	regex.compile("_(.*?)_")
	text = regex.sub(text, "[u]$1[/u]", true)
	
	regex.compile("`(.*?)`")
	text = regex.sub(text, "[code]$1[/code]", true)
	
	rich_text_label.text = text

func _on_text_changed():
	call_deferred("save_notes")
	if not is_source_mode:
		update_render()

func save_notes():
	var file = FileAccess.open(NOTES_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(text_edit.text)
		file.close()

func load_notes():
	if FileAccess.file_exists(NOTES_SAVE_PATH):
		var file = FileAccess.open(NOTES_SAVE_PATH, FileAccess.READ)
		if file:
			text_edit.text = file.get_as_text()
			file.close()