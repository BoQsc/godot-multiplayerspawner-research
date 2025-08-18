@tool
extends Control

const RichEditor = preload("res://addons/editor_notes/rich_editor.gd")

var rich_editor: RichEditor
@onready var bold_btn: Button = $VBoxContainer/Toolbar/BoldBtn
@onready var italic_btn: Button = $VBoxContainer/Toolbar/ItalicBtn
@onready var underline_btn: Button = $VBoxContainer/Toolbar/UnderlineBtn
@onready var code_btn: Button = $VBoxContainer/Toolbar/CodeBtn
@onready var clear_btn: Button = $VBoxContainer/Toolbar/ClearBtn

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
	bold_btn.pressed.connect(func(): toggle_formatting("bold"))
	italic_btn.pressed.connect(func(): toggle_formatting("italic"))
	underline_btn.pressed.connect(func(): toggle_formatting("underline"))
	code_btn.pressed.connect(func(): toggle_formatting("code"))
	clear_btn.pressed.connect(_clear_all)

func toggle_formatting(format_type: String):
	if not rich_editor:
		return
	
	match format_type:
		"bold":
			rich_editor.apply_formatting(true, false, false, false)
		"italic":
			rich_editor.apply_formatting(false, true, false, false)
		"underline":
			rich_editor.apply_formatting(false, false, true, false)
		"code":
			rich_editor.apply_formatting(false, false, false, true)

func _clear_all():
	if rich_editor:
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