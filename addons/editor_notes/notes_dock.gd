@tool
extends Control

const RichEditor = preload("res://addons/editor_notes/rich_editor.gd")

var rich_editor: RichEditor
var render_display: RichTextLabel  # Original render mode
var render_context_menu: PopupMenu  # Context menu for render mode
var current_mode: int = 1  # 0 = source, 1 = render
var mode_toggle_btn: Button

# All buttons - will be found manually
var bold_btn: Button
var italic_btn: Button
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

const SAVE_PATH = "res://README.md"
var file_monitor_timer: Timer
var last_modified_time: int = 0

func _ready():
	setup_rich_editor()
	setup_render_display()
	setup_markdown_toolbar()  # New markdown-based toolbar
	setup_file_monitoring()
	load_notes()
	set_mode(current_mode)  # Set initial mode

func setup_rich_editor():
	# Create the rich editor
	rich_editor = RichEditor.new()
	rich_editor.name = "RichEditor"
	rich_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Ensure clipping is enabled
	rich_editor.clip_contents = true
	
	# Set proper mouse filter for dock integration
	rich_editor.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Force the control to respect container bounds
	rich_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rich_editor.custom_minimum_size = Vector2(0, 200)  # Minimum height for usability
	
	# Add to the main VBox container (which is now the root)
	add_child(rich_editor)
	
	# Explicitly ensure toolbar and header stay on top
	move_child($Header, 0)
	move_child($Toolbar, 1)
	move_child(rich_editor, 2)
	
	# Connect signals
	rich_editor.text_changed.connect(_on_text_changed)

func setup_render_display():
	# Create the original render display (RichTextLabel)
	render_display = RichTextLabel.new()
	render_display.name = "RenderDisplay"
	render_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	render_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	render_display.clip_contents = true
	render_display.bbcode_enabled = true
	render_display.scroll_following = false
	
	# Enable text selection in render mode
	render_display.selection_enabled = true
	
	# Enable clickable links
	render_display.meta_clicked.connect(_on_link_clicked)
	
	# Try to get Godot's editor monospace font for better code rendering
	var editor_settings = EditorInterface.get_editor_settings()
	if editor_settings:
		var code_font = editor_settings.get_setting("interface/editor/code_font")
		if code_font:
			render_display.add_theme_font_override("mono_font", code_font)
	
	# Set proper mouse filter for dock integration
	render_display.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Force the control to respect container bounds
	render_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	render_display.custom_minimum_size = Vector2(0, 200)  # Minimum height for usability
	
	# Setup context menu for render display
	setup_render_context_menu()
	
	# Add to main container
	add_child(render_display)
	
	# Ensure proper z-order
	move_child($Header, 0)
	move_child($Toolbar, 1)
	move_child(rich_editor, 2)
	move_child(render_display, 3)


func setup_legacy_toolbar():
	# LEGACY: Find all toolbar buttons manually - this is the old rich text approach
	bold_btn = get_node_or_null("Toolbar/BoldBtn")
	italic_btn = get_node_or_null("Toolbar/ItalicBtn")
	strikethrough_btn = get_node_or_null("Toolbar/StrikethroughBtn")
	code_btn = get_node_or_null("Toolbar/CodeBtn")
	heading_btn = get_node_or_null("Toolbar/HeadingBtn")
	list_btn = get_node_or_null("Toolbar/ListBtn")
	quote_btn = get_node_or_null("Toolbar/QuoteBtn")
	code_block_btn = get_node_or_null("Toolbar/CodeBlockBtn")
	hr_btn = get_node_or_null("Toolbar/HRBtn")
	link_btn = get_node_or_null("Toolbar/LinkBtn")
	image_btn = get_node_or_null("Toolbar/ImageBtn")
	table_btn = get_node_or_null("Toolbar/TableBtn")
	clear_btn = get_node_or_null("Toolbar/ClearBtn")
	
	# Formatting buttons - with null checks
	if bold_btn:
		bold_btn.pressed.connect(func(): toggle_formatting_legacy("bold"))
	else:
		print("ERROR: bold_btn is null!")
	
	if italic_btn:
		italic_btn.pressed.connect(func(): toggle_formatting_legacy("italic"))
	if strikethrough_btn:
		strikethrough_btn.pressed.connect(func(): toggle_formatting_legacy("strikethrough"))
	if code_btn:
		code_btn.pressed.connect(func(): toggle_formatting_legacy("code"))
	
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

func setup_markdown_toolbar():
	# NEW: Markdown-based toolbar - inserts markdown syntax instead of rich formatting
	
	# Find all toolbar buttons manually
	bold_btn = get_node_or_null("Toolbar/BoldBtn")
	italic_btn = get_node_or_null("Toolbar/ItalicBtn")
	strikethrough_btn = get_node_or_null("Toolbar/StrikethroughBtn")
	code_btn = get_node_or_null("Toolbar/CodeBtn")
	heading_btn = get_node_or_null("Toolbar/HeadingBtn")
	list_btn = get_node_or_null("Toolbar/ListBtn")
	quote_btn = get_node_or_null("Toolbar/QuoteBtn")
	code_block_btn = get_node_or_null("Toolbar/CodeBlockBtn")
	hr_btn = get_node_or_null("Toolbar/HRBtn")
	link_btn = get_node_or_null("Toolbar/LinkBtn")
	image_btn = get_node_or_null("Toolbar/ImageBtn")
	table_btn = get_node_or_null("Toolbar/TableBtn")
	clear_btn = get_node_or_null("Toolbar/ClearBtn")
	mode_toggle_btn = get_node_or_null("Toolbar/ModeToggleBtn")
	
	# Add transparent normal state to all buttons
	add_transparent_normal_style(bold_btn)
	add_transparent_normal_style(italic_btn)
	add_transparent_normal_style(strikethrough_btn)
	add_transparent_normal_style(code_btn)
	add_transparent_normal_style(heading_btn)
	add_transparent_normal_style(list_btn)
	add_transparent_normal_style(quote_btn)
	add_transparent_normal_style(code_block_btn)
	add_transparent_normal_style(hr_btn)
	add_transparent_normal_style(link_btn)
	add_transparent_normal_style(image_btn)
	add_transparent_normal_style(table_btn)
	add_transparent_normal_style(clear_btn)
	add_transparent_normal_style(mode_toggle_btn)
	
	# Connect formatting buttons that work in both modes
	if bold_btn:
		bold_btn.pressed.connect(_apply_bold_formatting)
	if italic_btn:
		italic_btn.pressed.connect(_apply_italic_formatting)
	if strikethrough_btn:
		strikethrough_btn.pressed.connect(_apply_strikethrough_formatting)
	if code_btn:
		code_btn.pressed.connect(_apply_code_formatting)
	
	# Setup heading menu for markdown
	setup_markdown_heading_menu()
	
	# Setup list menu for markdown
	setup_markdown_list_menu()
	
	# Structure buttons for markdown
	if quote_btn:
		quote_btn.pressed.connect(_insert_markdown_blockquote)
	if code_block_btn:
		code_block_btn.pressed.connect(_insert_markdown_code_block)
	if hr_btn:
		hr_btn.pressed.connect(_insert_markdown_horizontal_rule)
	
	# Insert buttons for markdown
	if link_btn:
		link_btn.pressed.connect(_insert_markdown_link)
	if image_btn:
		image_btn.pressed.connect(_insert_markdown_image)
	if table_btn:
		table_btn.pressed.connect(_insert_markdown_table)
	if clear_btn:
		clear_btn.pressed.connect(_clear_all)
	
	# Mode toggle button
	if mode_toggle_btn:
		mode_toggle_btn.pressed.connect(_toggle_mode)

func insert_markdown_formatting(start_marker: String, end_marker: String = ""):
	if not rich_editor:
		return
	
	# If no end marker provided, use the same as start (for **bold**, *italic*, etc.)
	var end_mark = end_marker if end_marker != "" else start_marker
	
	if rich_editor.has_selection():
		# Wrap selected text with markdown syntax
		var selected_text = rich_editor.get_selected_text()
		var formatted_text = start_marker + selected_text + end_mark
		rich_editor.delete_selection()
		insert_text(formatted_text)
	else:
		# Insert markers at cursor position and place cursor between them
		var placeholder = "text"
		var formatted_text = start_marker + placeholder + end_mark
		insert_text(formatted_text)
		# Move cursor to select the placeholder
		var cursor_pos = rich_editor.cursor_position
		rich_editor.cursor_position = cursor_pos - placeholder.length() - end_mark.length()
		rich_editor.selection_start = cursor_pos - placeholder.length() - end_mark.length()
		rich_editor.selection_end = cursor_pos - end_mark.length()

func add_button_hover_effect(button: Button):
	if not button:
		return
	
	# Create a visible hover background
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)  # Dark gray with transparency
	hover_style.corner_radius_top_left = 3
	hover_style.corner_radius_top_right = 3
	hover_style.corner_radius_bottom_left = 3
	hover_style.corner_radius_bottom_right = 3
	
	button.add_theme_stylebox_override("hover", hover_style)

func add_transparent_normal_style(button: Button):
	if not button:
		return
	
	# Create transparent normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0, 0, 0, 0)  # Completely transparent
	normal_style.border_width_left = 0
	normal_style.border_width_right = 0
	normal_style.border_width_top = 0
	normal_style.border_width_bottom = 0
	
	button.add_theme_stylebox_override("normal", normal_style)

func insert_text(text: String):
	if not rich_editor:
		return
	
	# Insert text at current cursor position
	var cursor_pos = rich_editor.cursor_position
	var current_text = rich_editor.get_text()
	var new_text = current_text.insert(cursor_pos, text)
	rich_editor.set_text(new_text)
	rich_editor.cursor_position = cursor_pos + text.length()
	
	# Manually trigger save since set_text() doesn't emit text_changed signal
	call_deferred("save_notes")

func toggle_formatting_legacy(format_type: String):
	# LEGACY: Rich text formatting approach
	if not rich_editor:
		return
	
	# Toggle the specific formatting type
	match format_type:
		"bold":
			rich_editor.toggle_formatting_type("bold")
		"italic":
			rich_editor.toggle_formatting_type("italic")
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
	match current_mode:
		1: # Render mode
			call_deferred("update_render_display")

func save_notes():
	if not rich_editor:
		return
	
	var content = rich_editor.get_text()
	
	# Auto-create README.md on first note (when content is not empty)
	if not FileAccess.file_exists(SAVE_PATH) and content.strip_edges() != "":
		print("Auto-creating README.md with first note")
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		print("ERROR: Could not open ", SAVE_PATH, " for writing")

func load_notes():
	if not FileAccess.file_exists(SAVE_PATH):
		# README.md doesn't exist - will be auto-created on first note
		if rich_editor:
			rich_editor.set_text("")
		last_modified_time = 0
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		last_modified_time = FileAccess.get_modified_time(SAVE_PATH)
		file.close()
		
		if rich_editor:
			rich_editor.set_text(content)
			match current_mode:
				1: # Render mode
					call_deferred("update_render_display")

func setup_file_monitoring():
	# Create timer for file monitoring
	file_monitor_timer = Timer.new()
	file_monitor_timer.timeout.connect(_check_file_changes)
	file_monitor_timer.wait_time = 1.0  # Check every second
	file_monitor_timer.autostart = true
	add_child(file_monitor_timer)

func _check_file_changes():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var current_modified_time = FileAccess.get_modified_time(SAVE_PATH)
	if current_modified_time > last_modified_time:
		# File was modified externally - reload it
		print("README.md was modified externally, reloading...")
		load_notes_without_losing_cursor()

func load_notes_without_losing_cursor():
	# Save current cursor position
	var cursor_pos = 0
	var selection_start = -1
	var selection_end = -1
	
	if rich_editor:
		cursor_pos = rich_editor.cursor_position
		selection_start = rich_editor.selection_start
		selection_end = rich_editor.selection_end
	
	# Load new content
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		last_modified_time = FileAccess.get_modified_time(SAVE_PATH)
		file.close()
		
		if rich_editor:
			# Update content without triggering save
			rich_editor.set_text(content)
			
			# Restore cursor position (clamped to new content length)
			var max_pos = rich_editor.get_total_text_length()
			rich_editor.cursor_position = clamp(cursor_pos, 0, max_pos)
			
			# Restore selection if it was valid
			if selection_start != -1 and selection_end != -1:
				rich_editor.selection_start = clamp(selection_start, 0, max_pos)
				rich_editor.selection_end = clamp(selection_end, 0, max_pos)
			
			rich_editor.queue_redraw()
			match current_mode:
				1: # Render mode
					call_deferred("update_render_display")

func setup_markdown_heading_menu():
	if not heading_btn:
		return
	var popup = heading_btn.get_popup()
	popup.clear()  # Clear any existing items
	popup.add_item("# H1", 1)
	popup.add_item("## H2", 2)
	popup.add_item("### H3", 3)
	popup.add_item("#### H4", 4)
	popup.add_item("##### H5", 5)
	popup.add_item("###### H6", 6)
	popup.id_pressed.connect(_on_markdown_heading_selected)

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

func setup_markdown_list_menu():
	if not list_btn:
		return
	var popup = list_btn.get_popup()
	popup.clear()  # Clear any existing items
	popup.add_item("- Bullet List", 0)
	popup.add_item("1. Numbered List", 1)
	popup.add_item("- [ ] Checklist", 2)
	popup.id_pressed.connect(_on_markdown_list_selected)

func setup_list_menu():
	if not list_btn:
		return
	var popup = list_btn.get_popup()
	popup.add_item("• Bullet List", 0)
	popup.add_item("1. Numbered List", 1)
	popup.add_item("☐ Checklist", 2)
	popup.id_pressed.connect(_on_list_selected)

func _on_markdown_heading_selected(id: int):
	if not rich_editor or current_mode == 1:  # Don't format in render mode
		return
	
	# Insert markdown heading syntax
	var heading_markers = ["", "#", "##", "###", "####", "#####", "######"]
	if id >= 1 and id <= 6:
		insert_line_start_formatting(heading_markers[id] + " ")

func _on_heading_selected(id: int):
	if not rich_editor:
		return
	var heading_level = id + 1
	rich_editor.insert_heading(heading_level)

func _on_markdown_list_selected(id: int):
	if not rich_editor or current_mode == 1:  # Don't format in render mode
		return
	
	match id:
		0: # Bullet list
			insert_line_start_formatting("- ")
		1: # Numbered list
			insert_line_start_formatting("1. ")
		2: # Checklist
			insert_line_start_formatting("- [ ] ")

func insert_line_start_formatting(prefix: String):
	if not rich_editor:
		return
	
	# Get current cursor position and find start of line
	var cursor_pos = rich_editor.cursor_position
	var text = rich_editor.get_text()
	var line_start = cursor_pos
	
	# Find the start of current line
	while line_start > 0 and text[line_start - 1] != '\n':
		line_start -= 1
	
	# Insert prefix at start of line
	var new_text = text.insert(line_start, prefix)
	rich_editor.set_text(new_text)
	rich_editor.cursor_position = cursor_pos + prefix.length()

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

func _insert_markdown_blockquote():
	if current_mode == 1:  # Don't format in render mode
		return
	insert_line_start_formatting("> ")

func _insert_markdown_code_block():
	if current_mode == 1:  # Don't format in render mode
		return
	var code_block = "```\ncode here\n```\n"
	insert_text(code_block)
	# Move cursor to select "code here"
	var cursor_pos = rich_editor.cursor_position
	rich_editor.cursor_position = cursor_pos - code_block.length() + 4  # After "```\n"
	rich_editor.selection_start = cursor_pos - code_block.length() + 4
	rich_editor.selection_end = cursor_pos - 4  # Before "\n```"

func _insert_markdown_horizontal_rule():
	if current_mode == 1:  # Don't format in render mode
		return
	insert_text("\n---\n")

func _insert_markdown_link():
	if current_mode == 1:  # Don't format in render mode
		return
	if rich_editor.has_selection():
		var selected_text = rich_editor.get_selected_text()
		var link_text = "[" + selected_text + "](url)"
		rich_editor.delete_selection()
		insert_text(link_text)
		# Select "url" part for easy editing
		var cursor_pos = rich_editor.cursor_position
		rich_editor.selection_start = cursor_pos - 4  # Start of "url)"
		rich_editor.selection_end = cursor_pos - 1   # End of "url"
	else:
		var link_text = "[text](url)"
		insert_text(link_text)
		# Select "text" part for easy editing
		var cursor_pos = rich_editor.cursor_position
		rich_editor.selection_start = cursor_pos - link_text.length() + 1  # After "["
		rich_editor.selection_end = cursor_pos - 6  # Before "]"

func _insert_markdown_image():
	if current_mode == 1:  # Don't format in render mode
		return
	var image_text = "![alt text](image_url)"
	insert_text(image_text)
	# Select "alt text" for easy editing
	var cursor_pos = rich_editor.cursor_position
	rich_editor.selection_start = cursor_pos - image_text.length() + 2  # After "!["
	rich_editor.selection_end = cursor_pos - 13  # Before "]"

func _insert_markdown_table():
	if current_mode == 1:  # Don't format in render mode
		return
	var table_text = """| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

"""
	insert_text(table_text)

# Legacy functions
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

# Two-mode functions
func _toggle_mode():
	current_mode = (current_mode + 1) % 2
	set_mode(current_mode)

func set_mode(mode: int):
	current_mode = mode
	
	# Hide all displays first
	rich_editor.visible = false
	render_display.visible = false
	
	match current_mode:
		0: # Source mode
			rich_editor.visible = true
			if mode_toggle_btn:
				mode_toggle_btn.text = "👁"
				mode_toggle_btn.tooltip_text = "Switch to Render Mode"
		1: # Render mode
			render_display.visible = true
			update_render_display()
			if mode_toggle_btn:
				mode_toggle_btn.text = "✏️"
				mode_toggle_btn.tooltip_text = "Switch to Source Mode"

func update_render_display():
	if not render_display or not rich_editor:
		return
	
	var markdown_text = rich_editor.get_text()
	var bbcode_text = markdown_to_bbcode(markdown_text)
	render_display.text = bbcode_text


func markdown_to_bbcode(markdown: String) -> String:
	var bbcode = markdown
	
	# Process line by line for easier regex handling
	var lines = bbcode.split("\n")
	var processed_lines = []
	
	for line in lines:
		var processed_line = line
		
		# Headers (process first)
		if line.begins_with("######"):
			processed_line = "[font_size=14][b]" + line.substr(6).strip_edges() + "[/b][/font_size]"
		elif line.begins_with("#####"):
			processed_line = "[font_size=16][b]" + line.substr(5).strip_edges() + "[/b][/font_size]"
		elif line.begins_with("####"):
			processed_line = "[font_size=18][b]" + line.substr(4).strip_edges() + "[/b][/font_size]"
		elif line.begins_with("###"):
			processed_line = "[font_size=20][b]" + line.substr(3).strip_edges() + "[/b][/font_size]"
		elif line.begins_with("##"):
			processed_line = "[font_size=24][b]" + line.substr(2).strip_edges() + "[/b][/font_size]"
		elif line.begins_with("#"):
			processed_line = "[font_size=28][b]" + line.substr(1).strip_edges() + "[/b][/font_size]"
		
		# Blockquotes
		elif line.begins_with("> "):
			processed_line = "[i]> " + line.substr(2) + "[/i]"
		
		# Lists
		elif line.begins_with("- [ ] "):
			processed_line = "☐ " + line.substr(6)
		elif line.begins_with("- [x] "):
			processed_line = "☑ " + line.substr(6)
		elif line.begins_with("- "):
			processed_line = "• " + line.substr(2)
		elif line.length() > 3 and line[0].is_valid_int() and line.find(". ") > 0:
			var regex = RegEx.new()
			regex.compile("^([0-9]+)\\. (.*)")
			var result = regex.search(line)
			if result:
				processed_line = result.get_string(1) + ". " + result.get_string(2)
		
		# Horizontal rules
		elif line.begins_with("---"):
			processed_line = "─────────────────────"
		
		processed_lines.append(processed_line)
	
	bbcode = "\n".join(processed_lines)
	
	# Inline formatting (process globally)
	var regex: RegEx
	
	# Bold **text**
	regex = RegEx.new()
	regex.compile("\\*\\*([^*]+)\\*\\*")
	bbcode = regex.sub(bbcode, "[b]$1[/b]", true)
	
	# Italic *text*
	regex = RegEx.new()
	regex.compile("\\*([^*]+)\\*")
	bbcode = regex.sub(bbcode, "[i]$1[/i]", true)
	
	# Strikethrough ~~text~~
	regex = RegEx.new()
	regex.compile("~~([^~]+)~~")
	bbcode = regex.sub(bbcode, "[s]$1[/s]", true)
	
	# Code blocks ```text``` - process FIRST to avoid conflicts with inline code
	# Clean pattern to avoid extra highlighted spaces
	regex = RegEx.new()
	regex.compile("```\\s*\\n([\\s\\S]*?)\\n\\s*```")
	bbcode = regex.sub(bbcode, "[bgcolor=#0d1117][color=#e6edf3]$1[/color][/bgcolor]", true)
	
	# Inline code `text` - process after code blocks
	regex = RegEx.new()
	regex.compile("`([^`]+)`")
	bbcode = regex.sub(bbcode, "[bgcolor=#1a1a1a][color=#f0f0f0] $1 [/color][/bgcolor]", true)
	
	# Links [text](url)
	regex = RegEx.new()
	regex.compile("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	bbcode = regex.sub(bbcode, "[url=$2]$1[/url]", true)
	
	return bbcode


# Formatting functions that work in both modes
func _apply_bold_formatting():
	match current_mode:
		0: # Source mode
			insert_markdown_formatting("**")
		1: # Render mode (display only - do nothing)
			return

func _apply_italic_formatting():
	match current_mode:
		0: # Source mode
			insert_markdown_formatting("*")
		1: # Render mode (display only - do nothing)
			return


func _apply_strikethrough_formatting():
	match current_mode:
		0: # Source mode
			insert_markdown_formatting("~~")
		1: # Render mode (display only - do nothing)
			return

func _apply_code_formatting():
	match current_mode:
		0: # Source mode
			insert_markdown_formatting("`")
		1: # Render mode (display only - do nothing)
			return

# Context menu for render display
func setup_render_context_menu():
	render_context_menu = PopupMenu.new()
	render_context_menu.name = "RenderContextMenu"
	add_child(render_context_menu)
	
	# Add copy option
	render_context_menu.add_item("Copy", 0)
	render_context_menu.add_item("Select All", 1)
	
	# Connect menu signals
	render_context_menu.id_pressed.connect(_on_render_context_menu_selected)
	
	# Connect right-click on render display
	render_display.gui_input.connect(_on_render_display_input)

func _on_render_display_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# Show context menu at mouse position
			render_context_menu.position = get_global_mouse_position()
			render_context_menu.popup()

func _on_render_context_menu_selected(id: int):
	match id:
		0: # Copy
			_copy_render_selection()
		1: # Select All
			_select_all_render()

func _copy_render_selection():
	if render_display.get_selected_text() != "":
		DisplayServer.clipboard_set(render_display.get_selected_text())

func _select_all_render():
	render_display.select_all()

func _on_link_clicked(meta):
	# Open URL in the default system browser
	OS.shell_open(str(meta))