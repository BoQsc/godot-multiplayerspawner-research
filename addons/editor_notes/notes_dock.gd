@tool
extends Control

enum Mode { RENDER, EDIT, SOURCE }

@onready var render_view: RichTextLabel = $VBoxContainer/Content/RenderView
@onready var edit_view: HSplitContainer = $VBoxContainer/Content/EditView
@onready var edit_field: TextEdit = $VBoxContainer/Content/EditView/EditField
@onready var live_preview: RichTextLabel = $VBoxContainer/Content/EditView/LivePreview
@onready var source_field: TextEdit = $VBoxContainer/Content/SourceField
@onready var mode_button: Button = $VBoxContainer/Header/ModeButton
@onready var edit_button: Button = $VBoxContainer/Header/EditButton
@onready var toolbar: HBoxContainer = $VBoxContainer/Toolbar

const SAVE_PATH = "user://editor_notes.txt"
var current_mode = Mode.RENDER
var markdown_content = ""

func _ready():
	setup_connections()
	load_notes()
	update_display()

func setup_connections():
	mode_button.pressed.connect(_cycle_mode)
	edit_button.pressed.connect(_toggle_edit)
	
	# Formatting buttons
	$VBoxContainer/Toolbar/BoldBtn.pressed.connect(func(): format_text("**", "**"))
	$VBoxContainer/Toolbar/ItalicBtn.pressed.connect(func(): format_text("*", "*"))
	$VBoxContainer/Toolbar/UnderlineBtn.pressed.connect(func(): format_text("_", "_"))
	$VBoxContainer/Toolbar/CodeBtn.pressed.connect(func(): format_text("`", "`"))
	$VBoxContainer/Toolbar/ClearBtn.pressed.connect(_clear_all)
	
	# Text change handling
	edit_field.text_changed.connect(_on_edit_changed)
	source_field.text_changed.connect(_on_source_changed)

func _cycle_mode():
	match current_mode:
		Mode.RENDER:
			current_mode = Mode.SOURCE
		Mode.EDIT:
			current_mode = Mode.SOURCE
		Mode.SOURCE:
			current_mode = Mode.RENDER
	
	update_display()

func _toggle_edit():
	if current_mode == Mode.RENDER:
		current_mode = Mode.EDIT
	elif current_mode == Mode.EDIT:
		current_mode = Mode.RENDER
	
	update_display()

func update_display():
	match current_mode:
		Mode.RENDER:
			_show_render_mode()
		Mode.EDIT:
			_show_edit_mode()
		Mode.SOURCE:
			_show_source_mode()

func _show_render_mode():
	render_view.visible = true
	edit_view.visible = false
	source_field.visible = false
	toolbar.visible = false
	
	mode_button.text = "Render"
	mode_button.tooltip_text = "Viewing formatted text"
	edit_button.text = "Edit"
	edit_button.visible = true
	
	# Update rendered content
	render_view.text = _markdown_to_bbcode(markdown_content)

func _show_edit_mode():
	render_view.visible = false
	edit_view.visible = true
	source_field.visible = false
	toolbar.visible = true
	
	mode_button.text = "Edit"
	mode_button.tooltip_text = "Editing with live preview"
	edit_button.text = "View"
	edit_button.visible = true
	
	# Show markdown in edit field with live preview
	edit_field.text = markdown_content
	live_preview.text = _markdown_to_bbcode(markdown_content)
	edit_field.placeholder_text = "Type here and see formatted preview on the right"

func _show_source_mode():
	render_view.visible = false
	edit_view.visible = false
	source_field.visible = true
	toolbar.visible = true
	
	mode_button.text = "Source"
	mode_button.tooltip_text = "Raw markdown editing"
	edit_button.visible = false
	
	# Show markdown in source field
	source_field.text = markdown_content

func format_text(prefix: String, suffix: String):
	var target_field: TextEdit
	
	match current_mode:
		Mode.EDIT:
			target_field = edit_field
		Mode.SOURCE:
			target_field = source_field
		_:
			return
	
	var selected_text = target_field.get_selected_text()
	
	if selected_text.is_empty():
		# No selection - insert empty formatting
		target_field.insert_text_at_caret(prefix + suffix)
		var pos = target_field.get_caret_column()
		target_field.set_caret_column(pos - suffix.length())
	else:
		# Wrap selection
		target_field.insert_text_at_caret(prefix + selected_text + suffix)

func _clear_all():
	match current_mode:
		Mode.EDIT:
			edit_field.clear()
		Mode.SOURCE:
			source_field.clear()
	
	markdown_content = ""
	render_view.clear()
	if live_preview:
		live_preview.clear()
	save_notes()

func _on_edit_changed():
	markdown_content = edit_field.text
	# Update live preview immediately
	live_preview.text = _markdown_to_bbcode(markdown_content)
	call_deferred("save_notes")

func _on_source_changed():
	markdown_content = source_field.text
	call_deferred("save_notes")

func _markdown_to_bbcode(markdown: String) -> String:
	var bbcode = markdown
	var regex = RegEx.new()
	
	# Convert markdown to BBCode
	regex.compile("\\*\\*(.*?)\\*\\*")
	bbcode = regex.sub(bbcode, "[b]$1[/b]", true)
	
	regex.compile("(?<!\\*)\\*([^*]+)\\*(?!\\*)")
	bbcode = regex.sub(bbcode, "[i]$1[/i]", true)
	
	regex.compile("_([^_]+)_")
	bbcode = regex.sub(bbcode, "[u]$1[/u]", true)
	
	regex.compile("`([^`]+)`")
	bbcode = regex.sub(bbcode, "[code]$1[/code]", true)
	
	return bbcode

func save_notes():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(markdown_content)
		file.close()

func load_notes():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			markdown_content = file.get_as_text()
			file.close()
			if edit_field:
				edit_field.text = markdown_content
			if source_field:
				source_field.text = markdown_content