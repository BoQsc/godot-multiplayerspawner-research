@tool
extends Control
class_name RichEditor

# Text formatting data structure
class TextSegment:
	var text: String
	var bold: bool = false
	var italic: bool = false
	var underline: bool = false
	var code: bool = false
	
	func _init(txt: String = "", b: bool = false, i: bool = false, u: bool = false, c: bool = false):
		text = txt
		bold = b
		italic = i
		underline = u
		code = c
	
	func copy() -> TextSegment:
		return TextSegment.new(text, bold, italic, underline, code)

# Editor state
var segments: Array[TextSegment] = []
var cursor_position: int = 0
var selection_start: int = -1
var selection_end: int = -1
var current_format: TextSegment = TextSegment.new()

# Line number drag state
var line_drag_active: bool = false
var line_drag_start_line: int = -1

# Undo/Redo system
class UndoState:
	var segments_data: Array[TextSegment]
	var cursor_pos: int
	var selection_start_pos: int
	var selection_end_pos: int
	
	func _init(segs: Array[TextSegment], cursor: int, sel_start: int, sel_end: int):
		segments_data = []
		for seg in segs:
			segments_data.append(seg.copy())
		cursor_pos = cursor
		selection_start_pos = sel_start
		selection_end_pos = sel_end

var undo_stack: Array[UndoState] = []
var redo_stack: Array[UndoState] = []
var max_undo_steps: int = 100

# Fonts and styling
var base_font: Font
var bold_font: Font  
var italic_font: Font
var bold_italic_font: Font
var code_font: Font

# Visual properties
var font_size: int = 16
var line_height: float = 20.0
var line_number_width: float = 40.0  # Width of line number sidebar
var margin: Vector2 = Vector2(10, 2)
var text_margin: Vector2 = Vector2(50, 2)  # Text starts after line numbers
var cursor_blink_time: float = 0.0
var cursor_visible: bool = true

# Signals
signal text_changed()

# Context menu
var context_menu: Control
var context_menu_just_shown: bool = false

# Mouse tracking for drag detection
var mouse_down_position: Vector2
var drag_threshold: float = 3.0  # Minimum pixels to start selection
var intentional_empty_line_selection: bool = false  # Track if empty line was selected intentionally

func _ready():
	setup_fonts()
	setup_initial_text()
	setup_context_menu()
	
	# Enable input handling
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	
	# Make sure we can receive focus
	focus_mode = Control.FOCUS_ALL
	
	# Connect focus signals to hide context menu when unfocused
	focus_exited.connect(_on_focus_exited)
	
	# Set mouse cursor to text edit cursor
	mouse_default_cursor_shape = Control.CURSOR_IBEAM
	
	# Auto-focus when ready
	call_deferred("grab_focus")

func setup_fonts():
	# Get the actual editor interface theme and code editor font
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	
	if editor_theme:
		# Try to get the code editor font
		base_font = editor_theme.get_font("source", "EditorFonts")
		if not base_font:
			# Fallback to main editor font
			base_font = editor_theme.get_font("main", "EditorFonts")
		if not base_font:
			# Final fallback
			base_font = ThemeDB.fallback_font
		
		# Get font size from editor settings
		font_size = editor_theme.get_font_size("source_size", "EditorFonts")
		if font_size <= 0:
			font_size = 16  # Fallback size
	else:
		base_font = ThemeDB.fallback_font
		font_size = 16
	
	# Create variations for different styles
	# Note: In a real implementation, you'd load actual bold/italic font files
	bold_font = base_font
	italic_font = base_font
	bold_italic_font = base_font
	code_font = base_font
	
	# Update line height based on font
	line_height = base_font.get_height(font_size) + 4

func setup_initial_text():
	# Start with a single empty segment
	segments = [TextSegment.new("")]
	cursor_position = 0

func setup_context_menu():
	# Create custom control that forwards events (non-modal)
	context_menu = Control.new()
	add_child(context_menu)
	context_menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	context_menu.size = Vector2(120, 120)
	context_menu.visible = false
	
	# Re-enable input handler for double-click forwarding
	context_menu.gui_input.connect(_on_context_menu_input)
	
	# Create background panel with PopupMenu styling
	var panel = Panel.new()
	context_menu.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block button clicks
	
	# Style panel to match PopupMenu
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	var panel_bg = Color(0.2, 0.23, 0.31)  # Default dark theme
	
	if editor_theme:
		var theme_bg = editor_theme.get_color("panel_bg", "PopupMenu")
		if theme_bg != Color.BLACK:
			panel_bg = theme_bg
		else:
			theme_bg = editor_theme.get_color("bg", "Panel")
			if theme_bg != Color.BLACK:
				panel_bg = theme_bg
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = panel_bg
	panel_style.set_border_width_all(1)
	panel_style.border_color = panel_bg.darkened(0.2)
	panel_style.set_corner_radius_all(0)
	panel_style.shadow_size = 4
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create vertical container for menu items
	var vbox = VBoxContainer.new()
	context_menu.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow clicks through to buttons
	
	# Add menu buttons
	create_menu_item(vbox, "Cut", func(): cut_selection(); context_menu.hide())
	create_menu_item(vbox, "Copy", func(): copy_selection(); context_menu.hide())
	create_menu_item(vbox, "Paste", func(): paste_from_clipboard(); context_menu.hide())
	
	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	create_menu_item(vbox, "Select All", func(): select_all(); context_menu.hide())

func create_menu_item(parent: VBoxContainer, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.flat = false
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 24
	btn.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button captures mouse events
	btn.focus_mode = Control.FOCUS_NONE  # Don't steal focus but allow clicks
	
	# Get actual PopupMenu colors from editor theme
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	
	var menu_bg_color: Color = Color(0.2, 0.23, 0.31)  # Default dark theme
	var menu_hover_color: Color = Color(0.26, 0.32, 0.46)  # Default hover
	var menu_font_color: Color = Color(0.875, 0.875, 0.875)  # Default text
	var menu_font_hover_color: Color = Color.WHITE  # Default hover text
	
	if editor_theme:
		# Try extracting actual PopupMenu colors
		var theme_bg = editor_theme.get_color("panel_bg", "PopupMenu")
		if theme_bg != Color.BLACK:
			menu_bg_color = theme_bg
		else:
			# Try Panel as fallback
			theme_bg = editor_theme.get_color("bg", "Panel")
			if theme_bg != Color.BLACK:
				menu_bg_color = theme_bg
		
		var theme_hover = editor_theme.get_color("hover", "PopupMenu")
		if theme_hover != Color.BLACK:
			menu_hover_color = theme_hover
		else:
			# Try Button hover as fallback
			theme_hover = editor_theme.get_color("hover", "Button")
			if theme_hover != Color.BLACK:
				menu_hover_color = theme_hover
		
		var theme_font = editor_theme.get_color("font_color", "PopupMenu")
		if theme_font != Color.BLACK:
			menu_font_color = theme_font
		else:
			# Try Label font color as fallback
			theme_font = editor_theme.get_color("font_color", "Label")
			if theme_font != Color.BLACK:
				menu_font_color = theme_font
	
	# Create button states with theme colors - ensure flat appearance like PopupMenu
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = menu_bg_color
	normal_style.set_border_width_all(0)
	normal_style.set_corner_radius_all(0)
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = menu_hover_color
	hover_style.set_border_width_all(0)
	hover_style.set_corner_radius_all(0)
	hover_style.content_margin_left = 8
	hover_style.content_margin_right = 8
	hover_style.content_margin_top = 4
	hover_style.content_margin_bottom = 4
	
	# Apply states with proper PopupMenu styling
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus", normal_style)
	
	# Apply font colors
	btn.add_theme_color_override("font_color", menu_font_color)
	btn.add_theme_color_override("font_hover_color", menu_font_hover_color)
	btn.add_theme_color_override("font_pressed_color", menu_font_hover_color)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _on_focus_exited():
	# Hide context menu when editor loses focus
	if context_menu and context_menu.visible:
		context_menu.hide()
		context_menu_just_shown = false

func _on_context_menu_input(event):
	# With proper mouse filtering, this should only receive unhandled events
	# (events that didn't hit buttons, since buttons have MOUSE_FILTER_STOP)
	if event is InputEventMouseButton and event.pressed:
		# Calculate the position relative to the text editor
		var editor_pos = event.position + context_menu.position
		
		# Create new event with correct position
		var new_event = InputEventMouseButton.new()
		new_event.button_index = event.button_index
		new_event.pressed = event.pressed
		new_event.double_click = event.double_click
		new_event.position = editor_pos
		
		# Close context menu and process the event
		context_menu.hide()
		context_menu_just_shown = false
		handle_mouse_input(new_event)

func _draw():
	draw_background()
	draw_line_numbers()
	draw_selection()  # Draw selection behind text
	draw_text_segments()
	draw_cursor()  # Draw cursor on top

func draw_background():
	# Get the actual editor interface theme
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	
	var bg_color: Color
	var line_number_bg_color: Color
	if editor_theme:
		# Use the darker panel/input background color like console and scene tree
		bg_color = editor_theme.get_color("dark_color_2", "Editor")
		if bg_color == Color.BLACK:  # Try alternative darker color
			bg_color = editor_theme.get_color("dark_color_1", "Editor")
		if bg_color == Color.BLACK:  # Try LineEdit background
			bg_color = editor_theme.get_color("base_color", "LineEdit")
		if bg_color == Color.BLACK:  # Final fallback
			bg_color = Color(0.14, 0.17, 0.22)  # Darker editor panel color
		
		# Line number background should be slightly darker
		line_number_bg_color = bg_color.darkened(0.1)
	else:
		bg_color = Color(0.14, 0.17, 0.22)  # Fallback
		line_number_bg_color = Color(0.12, 0.15, 0.20)  # Darker fallback
	
	# Draw main text area background
	draw_rect(Rect2(Vector2(line_number_width, 0), Vector2(size.x - line_number_width, size.y)), bg_color)
	
	# Draw line number area background
	draw_rect(Rect2(Vector2.ZERO, Vector2(line_number_width, size.y)), line_number_bg_color)
	
	# Draw current line highlight
	draw_current_line_highlight(bg_color)
	
	# Draw separator line between line numbers and text
	var separator_color: Color
	if editor_theme:
		separator_color = editor_theme.get_color("font_color", "Editor")
		separator_color.a = 0.2
	else:
		separator_color = Color(0.4, 0.4, 0.4, 0.2)
	
	draw_line(Vector2(line_number_width, 0), Vector2(line_number_width, size.y), separator_color, 1.0)
	
	# Draw subtle border
	var border_color: Color
	if editor_theme:
		border_color = editor_theme.get_color("font_color", "Editor")
		border_color.a = 0.1  # Very subtle
	else:
		border_color = Color(0.35, 0.35, 0.35, 0.1)
	
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)

func draw_current_line_highlight(bg_color: Color):
	
	# Find which line the cursor is on
	var text_content = get_text()
	var cursor_line = 1
	for i in range(min(cursor_position, text_content.length())):
		if text_content[i] == '\n':
			cursor_line += 1
	
	# Calculate the Y position for this line
	var current_line_y = text_margin.y + (cursor_line - 1) * line_height
	
	# Create a subtle highlight color (lighter than background)
	var highlight_color = bg_color.lightened(0.03)  # Very subtle highlight
	highlight_color.a = 0.8
	
	# Draw highlight across entire line (both line number area and text area)
	var highlight_rect = Rect2(Vector2(0, current_line_y), Vector2(size.x, line_height))
	draw_rect(highlight_rect, highlight_color)

func draw_line_numbers():
	# Get the actual editor interface theme
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	
	var line_number_color: Color
	if editor_theme:
		line_number_color = editor_theme.get_color("font_color", "Editor")
		line_number_color.a = 0.5  # Make line numbers more subtle
	else:
		line_number_color = Color(0.6, 0.6, 0.6, 0.5)
	
	# Count lines in text
	var text_content = get_text()
	var line_count = 1
	for i in range(text_content.length()):
		if text_content[i] == '\n':
			line_count += 1
	
	# Ensure at least one line number is shown
	line_count = max(1, line_count)
	
	# Draw line numbers
	var line_number_font = base_font
	for line_num in range(1, line_count + 1):
		var y_pos = text_margin.y + (line_num - 1) * line_height + line_number_font.get_ascent(font_size)
		var line_text = str(line_num)
		var text_width = line_number_font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x_pos = line_number_width - text_width - 5  # Right-align with 5px margin
		
		line_number_font.draw_string(get_canvas_item(), Vector2(x_pos, y_pos), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, line_number_color)

func draw_text_segments():
	var pos = text_margin  # Use text_margin instead of margin
	var current_pos = 0
	
	for segment in segments:
		if segment.text.is_empty():
			continue
			
		var font = get_segment_font(segment)
		var color = get_segment_color(segment)
		
		# Draw the entire segment at once for better alignment
		var segment_lines = segment.text.split('\n')
		
		for line_idx in range(segment_lines.size()):
			var line = segment_lines[line_idx]
			
			if line.length() > 0:
				# Draw text with baseline offset - this aligns text with cursor
				var text_pos = Vector2(pos.x, pos.y + font.get_ascent(font_size))
				
				# Draw background for code segments - calculate width character by character
				if segment.code:
					var line_width = 0.0
					for char_idx in range(line.length()):
						var char = line[char_idx]
						var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
						line_width += char_size.x
					var code_bg_color = color.lerp(Color.BLACK, 0.3)
					code_bg_color.a = 0.2
					draw_rect(Rect2(Vector2(pos.x - 2, pos.y), Vector2(line_width + 4, line_height)), code_bg_color)
				
				# Draw the text character by character for consistent positioning
				var char_pos = pos
				for char_idx in range(line.length()):
					var char = line[char_idx]
					var char_text_pos = Vector2(char_pos.x, char_pos.y + font.get_ascent(font_size))
					
					# Draw the character with styling effects
					if segment.bold and not segment.code:
						# Simulate bold by drawing text multiple times with slight offset
						font.draw_string(get_canvas_item(), char_text_pos, char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
						font.draw_string(get_canvas_item(), char_text_pos + Vector2(0.5, 0), char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
						if segment.italic:
							# Also add italic effect with skew simulation
							font.draw_string(get_canvas_item(), char_text_pos + Vector2(1, 0), char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
					elif segment.italic and not segment.code:
						# Simulate italic with slight color variation and offset
						var italic_color = color.lerp(Color.WHITE, 0.1)
						font.draw_string(get_canvas_item(), char_text_pos, char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, italic_color)
					else:
						# Normal text
						font.draw_string(get_canvas_item(), char_text_pos, char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
					
					# Draw underline if needed
					if segment.underline and not segment.code:
						var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
						var underline_y = char_text_pos.y + 2
						draw_line(Vector2(char_pos.x, underline_y), Vector2(char_pos.x + char_size.x, underline_y), color, 1.0)
					
					# Move to next character position using same method as positioning
					var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
					char_pos.x += char_size.x
				
				pos.x = char_pos.x
			
			# Move to next line if there's a newline
			if line_idx < segment_lines.size() - 1:
				pos.x = text_margin.x  # Use text_margin instead of margin
				pos.y += line_height
		
		current_pos += segment.text.length()

func get_segment_font(segment: TextSegment) -> Font:
	if segment.code:
		return code_font
	elif segment.bold and segment.italic:
		return bold_italic_font
	elif segment.bold:
		return bold_font
	elif segment.italic:
		return italic_font
	else:
		return base_font

func get_segment_color(segment: TextSegment) -> Color:
	# Get the actual editor theme
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	
	if segment.code:
		# Use a themed color for code text
		var code_color: Color
		if editor_theme:
			code_color = editor_theme.get_color("font_color", "Editor")
			code_color = code_color.lerp(Color.GREEN, 0.3)  # Tint towards green
		else:
			code_color = Color.LIGHT_GREEN  # Fallback
		return code_color
	else:
		# Use editor theme font color
		var text_color: Color
		if editor_theme:
			text_color = editor_theme.get_color("font_color", "Editor")
		else:
			text_color = Color(0.9, 0.9, 0.9)  # Fallback
		return text_color

func draw_cursor():
	if not cursor_visible:
		return
		
	var cursor_pos = get_visual_position(cursor_position)
	
	# Get cursor color from editor theme
	var editor_interface = Engine.get_singleton("EditorInterface")
	var editor_theme = editor_interface.get_editor_theme() if editor_interface else null
	var cursor_color: Color
	if editor_theme:
		cursor_color = editor_theme.get_color("font_color", "Editor")
	else:
		cursor_color = Color.WHITE  # Fallback
	
	# Make cursor smaller - reduced height and thickness
	var cursor_height = line_height * 0.8  # 80% of line height instead of full height
	var cursor_offset = line_height * 0.1  # Small offset from top
	draw_line(cursor_pos + Vector2(0, cursor_offset), cursor_pos + Vector2(0, cursor_offset + cursor_height), cursor_color, 1.0)  # Thickness 1.0 instead of 2.0

func draw_selection():
	if selection_start == -1 or selection_end == -1:
		return
		
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	# Handle zero-width selections (empty lines) specially - only for intentional selections
	if start_pos == end_pos and intentional_empty_line_selection:
		draw_empty_line_selection(start_pos)
		return
		
	# Use the comprehensive multi-line drawing for actual selections
	draw_multi_line_selection(start_pos, end_pos)

func draw_empty_line_selection(pos: int):
	# Draw selection for empty line (zero-width selection)
	var visual_pos = get_visual_position(pos)
	var space_width = base_font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var selection_color = Color(0.3, 0.6, 1.0, 0.3)
	draw_rect(Rect2(visual_pos, Vector2(space_width, line_height)), selection_color)

func draw_multi_line_selection(start_pos: int, end_pos: int):
	var text_content = get_text()
	var selection_color = Color(0.3, 0.6, 1.0, 0.3)
	var space_width = base_font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# Draw selection line by line for better empty line handling
	var current_pos = start_pos
	var current_line_start = start_pos
	
	# Find the start of the current line
	while current_line_start > 0 and text_content[current_line_start - 1] != '\n':
		current_line_start -= 1
	
	while current_pos <= end_pos:
		# Find the end of current line
		var line_end = current_pos
		while line_end < text_content.length() and text_content[line_end] != '\n':
			line_end += 1
		
		# Calculate visual positions
		var line_start_visual = get_visual_position(max(current_pos, start_pos))
		var selection_start_in_line = max(current_pos, start_pos)
		var selection_end_in_line = min(line_end, end_pos)
		
		if selection_start_in_line <= selection_end_in_line:
			if selection_start_in_line == line_end:
				# Empty line or newline character - show space width highlight
				draw_rect(Rect2(line_start_visual, Vector2(space_width, line_height)), selection_color)
			else:
				# Line has content
				var selection_end_visual = get_visual_position(selection_end_in_line)
				var width = max(space_width, selection_end_visual.x - line_start_visual.x)
				draw_rect(Rect2(line_start_visual, Vector2(width, line_height)), selection_color)
		
		# Move to next line
		current_pos = line_end + 1
		if line_end >= text_content.length():
			break

func get_visual_position(text_pos: int) -> Vector2:
	# Calculate position by rendering text segments up to cursor position
	text_pos = clamp(text_pos, 0, get_total_text_length())
	
	var pos = text_margin
	var char_count = 0
	
	# Build the complete text first to ensure consistency
	var full_text = get_text()
	
	# Process each character up to the target position
	for i in range(min(text_pos, full_text.length())):
		var char = full_text[i]
		if char == '\n':
			pos.x = text_margin.x
			pos.y += line_height
		else:
			# Find which segment this character belongs to for proper font
			var segment_info = find_segment_at_position(i)
			var font = get_segment_font(segment_info.segment)
			var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			pos.x += char_size.x
	
	return pos

func _process(delta):
	# Handle cursor blinking - faster blink rate, only when focused
	if has_focus():
		cursor_blink_time += delta
		if cursor_blink_time >= 0.5:  # Changed from 1.0 to 0.5 for faster blinking
			cursor_visible = not cursor_visible
			cursor_blink_time = 0.0
			queue_redraw()
	else:
		# When not focused, hide cursor completely
		if cursor_visible != false:
			cursor_visible = false
			queue_redraw()

func _gui_input(event):
	if event is InputEventKey and event.pressed:
		handle_key_input(event)
		accept_event()
	elif event is InputEventMouseButton:
		handle_mouse_input(event)
		accept_event()
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
		accept_event()

func _unhandled_input(event):
	# Handle global mouse motion for selection even when outside bounds
	if event is InputEventMouseMotion and selection_start != -1 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Convert global mouse position to local coordinates
		var local_pos = get_global_mouse_position() - global_position
		var drag_pos = get_text_position_at_extended(local_pos)
		selection_end = drag_pos
		cursor_position = drag_pos
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	
	if not has_focus():
		return
		
	if event is InputEventKey and event.pressed:
		handle_key_input(event)
		get_viewport().set_input_as_handled()

func handle_key_input(event: InputEventKey):
	var shift_pressed = event.shift_pressed
	var ctrl_pressed = event.ctrl_pressed
	
	match event.keycode:
		KEY_LEFT:
			if shift_pressed:
				start_selection()
			move_cursor(-1)
			if shift_pressed:
				update_selection()
			else:
				clear_selection()
		KEY_RIGHT:
			if shift_pressed:
				start_selection()
			move_cursor(1)
			if shift_pressed:
				update_selection()
			else:
				clear_selection()
		KEY_HOME:
			move_cursor_to_line_start()
		KEY_END:
			move_cursor_to_line_end()
		KEY_BACKSPACE:
			if has_selection():
				delete_selection()
			else:
				delete_character(-1)
		KEY_DELETE:
			if has_selection():
				delete_selection()
			else:
				delete_character(1)
		KEY_ENTER:
			if has_selection():
				delete_selection()
			insert_character('\n')
		KEY_A:
			if ctrl_pressed:
				select_all()
			else:
				# Let it fall through to unicode handling
				if event.unicode > 31 and event.unicode < 127:
					if has_selection():
						delete_selection()
					var char_str = char(event.unicode)
					insert_character(char_str)
		KEY_C:
			if ctrl_pressed:
				copy_selection()
			else:
				# Let it fall through to unicode handling
				if event.unicode > 31 and event.unicode < 127:
					if has_selection():
						delete_selection()
					var char_str = char(event.unicode)
					insert_character(char_str)
		KEY_V:
			if ctrl_pressed:
				paste_from_clipboard()
			else:
				# Let it fall through to unicode handling
				if event.unicode > 31 and event.unicode < 127:
					if has_selection():
						delete_selection()
					var char_str = char(event.unicode)
					insert_character(char_str)
		KEY_X:
			if ctrl_pressed:
				cut_selection()
			else:
				# Let it fall through to unicode handling
				if event.unicode > 31 and event.unicode < 127:
					if has_selection():
						delete_selection()
					var char_str = char(event.unicode)
					insert_character(char_str)
		KEY_Z:
			if ctrl_pressed:
				if shift_pressed:
					redo()  # Ctrl+Shift+Z for redo
				else:
					undo()  # Ctrl+Z for undo
		KEY_Y:
			if ctrl_pressed:
				redo()  # Ctrl+Y for redo (alternative)
		_:
			# Handle printable characters
			if event.unicode > 31 and event.unicode < 127:
				if has_selection():
					delete_selection()
				var char_str = char(event.unicode)
				insert_character(char_str)

func handle_mouse_input(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		# If context menu is visible and wasn't just shown, hide it and continue processing
		if context_menu.visible and not context_menu_just_shown:
			context_menu.hide()
		context_menu_just_shown = false
		
		grab_focus()
		
		# Check if click is in line number area
		if event.position.x < line_number_width:
			if event.pressed and event.double_click:
				# Double-click on line number - select entire line
				var line_number = get_line_number_at_y(event.position.y)
				select_entire_line(line_number)
				line_drag_active = false  # Reset drag state
				queue_redraw()
				return
			elif event.pressed:
				# Single click on line number - start line drag selection
				var line_number = get_line_number_at_y(event.position.y)
				line_drag_active = true
				line_drag_start_line = line_number
				select_entire_line(line_number)
				queue_redraw()
				return
			else:
				# Mouse release in line number area - end line drag
				line_drag_active = false
				return
		
		# Regular text area click handling
		line_drag_active = false  # Reset line drag state when clicking in text area
		var click_pos = get_text_position_at(event.position)
		if event.pressed:
			# Clear the context menu flag when actually clicking in text area
			context_menu_just_shown = false
			# Check for double-click
			if event.double_click:
				select_word_at_position(click_pos)
			else:
				cursor_position = click_pos
				# Clear any existing selection on click
				clear_selection()
				# Reset empty line selection flag for regular text clicks
				intentional_empty_line_selection = false
				# Store mouse down position for drag detection
				mouse_down_position = event.position
				# Capture mouse to continue tracking even outside bounds
				Input.set_default_cursor_shape(Input.CURSOR_IBEAM)
		else:
			# End selection on mouse up
			if selection_start == selection_end:
				clear_selection()
		queue_redraw()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		grab_focus()
		
		# Check if right-click is outside current selection
		var click_pos = get_text_position_at(event.position)
		var selection_active = has_selection()
		var click_in_selection = false
		
		if selection_active:
			var start_pos = min(selection_start, selection_end)
			var end_pos = max(selection_start, selection_end)
			click_in_selection = click_pos >= start_pos and click_pos <= end_pos
		
		# If clicking outside selection or no selection exists, move cursor and clear selection
		if not click_in_selection:
			cursor_position = click_pos
			clear_selection()
			queue_redraw()
		
		# Show custom context menu with offset at mouse tip level
		var mouse_global_pos = get_global_mouse_position()
		context_menu.position = mouse_global_pos + Vector2(-5, 0) - global_position
		context_menu.visible = true
		context_menu.move_to_front()
		context_menu_just_shown = true

func handle_mouse_motion(event: InputEventMouseMotion):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if line_drag_active:
			# Handle line number drag selection with improved accuracy
			var current_line = get_line_number_at_y(event.position.y)
			
			# Only update if line actually changed to reduce flicker
			var text_content = get_text()
			var expected_start = min(line_drag_start_line, current_line)
			var expected_end = max(line_drag_start_line, current_line)
			
			# Check if selection needs updating
			var needs_update = false
			if selection_start == -1 or selection_end == -1:
				needs_update = true
			else:
				# Convert current selection back to line numbers to check if they changed
				var current_start_line = get_line_at_position(selection_start)
				var current_end_line = get_line_at_position(selection_end - 1) # -1 because selection_end is exclusive
				
				if current_start_line != expected_start or current_end_line != expected_end:
					needs_update = true
			
			if needs_update:
				select_line_range(line_drag_start_line, current_line)
				queue_redraw()
		else:
			# Handle regular text drag selection - only start if we've moved enough
			if selection_start == -1:
				# Check if we've moved far enough to start a selection
				var distance = event.position.distance_to(mouse_down_position)
				if distance >= drag_threshold:
					# Start new selection at original mouse down position
					var start_pos = get_text_position_at(mouse_down_position)
					selection_start = start_pos
					selection_end = start_pos
				else:
					# Not enough movement, don't start selection yet
					return
			
			# Handle regular text drag selection with better out-of-bounds handling
			var drag_pos = get_text_position_at_extended(event.position)
			
			# Only update selection if it would actually create a meaningful selection
			if drag_pos != selection_start:
				selection_end = drag_pos
				cursor_position = drag_pos
				queue_redraw()
			else:
				# If drag_pos equals selection_start, we have a zero-width selection
				# Clear the selection instead of showing a meaningless highlight
				clear_selection()
				cursor_position = drag_pos
				queue_redraw()

func get_text_position_at(visual_pos: Vector2) -> int:
	# Convert visual position back to text position with proper bounds handling
	var pos = text_margin
	var text_pos = 0
	
	# Clamp the visual position to editor bounds
	var clamped_pos = Vector2(
		clamp(visual_pos.x, text_margin.x, size.x),
		clamp(visual_pos.y, text_margin.y, size.y)
	)
	
	# If click is above text area, return position 0
	if visual_pos.y < text_margin.y:
		return 0
	
	# If click is in line number area, clamp to start of the line at that Y position
	if visual_pos.x < text_margin.x:
		var line_index = int((clamped_pos.y - text_margin.y) / line_height)
		return get_line_start_position(line_index)
	
	# If click is below text area, return end of text
	var full_text = get_text()
	if visual_pos.y > size.y:
		return full_text.length()
	
	# If click is to the right of text area, find end of the line at that Y position
	if visual_pos.x > size.x:
		var line_index = int((clamped_pos.y - text_margin.y) / line_height)
		return get_line_end_position(line_index)
	
	# Use the same approach as get_visual_position for consistency with clamped position
	# full_text already declared above
	
	for i in range(full_text.length()):
		var char = full_text[i]
		
		# Check if we're on the right line and close to the character
		if clamped_pos.y >= pos.y and clamped_pos.y < pos.y + line_height:
			if char == '\n':
				# If clicking at end of line, position cursor at end of line
				if clamped_pos.x >= pos.x:
					return i
				else:
					return i
			else:
				# Find which segment this character belongs to for proper font
				var segment_info = find_segment_at_position(i)
				var font = get_segment_font(segment_info.segment)
				var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				
				# Check if click is within this character's bounds
				if clamped_pos.x >= pos.x and clamped_pos.x < pos.x + char_size.x:
					# Click closer to start or end of character?
					if clamped_pos.x < pos.x + char_size.x / 2:
						return i
					else:
						return i + 1
				elif clamped_pos.x < pos.x:
					return i
		
		# Move to next character position
		if char == '\n':
			pos.x = text_margin.x
			pos.y += line_height
		else:
			# Find which segment this character belongs to for proper font
			var segment_info = find_segment_at_position(i)
			var font = get_segment_font(segment_info.segment)
			var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			pos.x += char_size.x
	
	# If clicked beyond all text, return end position
	return full_text.length()

func get_text_position_at_extended(visual_pos: Vector2) -> int:
	# Extended version that handles out-of-bounds positions smoothly for selection
	var full_text = get_text()
	
	# Handle positions above text area
	if visual_pos.y < text_margin.y:
		return 0
	
	# Handle positions in line number area - clamp to start of line
	if visual_pos.x < text_margin.x:
		var line_index = int((visual_pos.y - text_margin.y) / line_height)
		return get_line_start_position(line_index)
	
	# Handle positions below text area - return end of text
	if visual_pos.y > size.y:
		return full_text.length()
	
	# Handle positions to the right of text area - find end of line at that Y
	if visual_pos.x > size.x:
		var line_index = int((visual_pos.y - text_margin.y) / line_height)
		return get_line_end_position(line_index)
	
	# For positions within bounds, use regular calculation
	return get_text_position_at(visual_pos)

func get_line_start_position(line_index: int) -> int:
	# Get the text position at the start of the given line (0-based)
	if line_index <= 0:
		return 0
	
	var full_text = get_text()
	var current_line = 0
	var pos = 0
	
	for i in range(full_text.length()):
		if current_line == line_index:
			return pos
		if full_text[i] == '\n':
			current_line += 1
			pos = i + 1
		else:
			if current_line < line_index:
				pos = i + 1
	
	return pos

func get_line_end_position(line_index: int) -> int:
	# Get the text position at the end of the given line (0-based)
	var full_text = get_text()
	var current_line = 0
	var line_start = 0
	
	for i in range(full_text.length()):
		if current_line == line_index:
			# Found the target line, now find its end
			for j in range(i, full_text.length()):
				if full_text[j] == '\n':
					return j  # Return position just before newline
			return full_text.length()  # End of text if no newline found
		elif full_text[i] == '\n':
			current_line += 1
			line_start = i + 1
	
	# If line_index is beyond available lines, return end of text
	return full_text.length()

func move_cursor(delta: int):
	cursor_position = max(0, min(get_total_text_length(), cursor_position + delta))
	cursor_visible = true
	cursor_blink_time = 0.0
	queue_redraw()

func insert_character(char: String):
	save_state()  # Save state before modification
	
	var segment_info = find_segment_at_position(cursor_position)
	var segment = segment_info.segment
	var local_pos = segment_info.local_position
	
	# Insert character with current formatting
	segment.text = segment.text.insert(local_pos, char)
	cursor_position += 1
	
	text_changed.emit()
	queue_redraw()

func delete_character(delta: int):
	save_state()  # Save state before modification
	
	if delta < 0 and cursor_position > 0:
		# Backspace
		var segment_info = find_segment_at_position(cursor_position - 1)
		var segment = segment_info.segment
		var local_pos = segment_info.local_position
		
		segment.text = segment.text.erase(local_pos, 1)
		cursor_position -= 1
	elif delta > 0 and cursor_position < get_total_text_length():
		# Delete
		var segment_info = find_segment_at_position(cursor_position)
		var segment = segment_info.segment
		var local_pos = segment_info.local_position
		
		segment.text = segment.text.erase(local_pos, 1)
	
	text_changed.emit()
	queue_redraw()

func find_segment_at_position(pos: int) -> Dictionary:
	var current_pos = 0
	
	for i in range(segments.size()):
		var segment = segments[i]
		if current_pos + segment.text.length() > pos:
			return {"segment": segment, "segment_index": i, "local_position": pos - current_pos}
		current_pos += segment.text.length()
	
	# Return last segment if position is at end
	var last_segment = segments[-1]
	return {"segment": last_segment, "segment_index": segments.size() - 1, "local_position": last_segment.text.length()}

func get_total_text_length() -> int:
	var total = 0
	for segment in segments:
		total += segment.text.length()
	return total

func apply_formatting(bold: bool = false, italic: bool = false, underline: bool = false, code: bool = false):
	current_format.bold = bold
	current_format.italic = italic  
	current_format.underline = underline
	current_format.code = code
	
	# If there's a selection, apply formatting to selected text
	if selection_start != -1 and selection_end != -1:
		apply_formatting_to_selection(bold, italic, underline, code)
	
	queue_redraw()

func toggle_formatting_type(format_type: String):
	if not has_selection():
		# No selection - just toggle current format for new text
		match format_type:
			"bold":
				current_format.bold = not current_format.bold
			"italic":
				current_format.italic = not current_format.italic
			"underline":
				current_format.underline = not current_format.underline
			"code":
				current_format.code = not current_format.code
				# Code formatting is exclusive
				if current_format.code:
					current_format.bold = false
					current_format.italic = false
					current_format.underline = false
		return
	
	# Has selection - check current state and toggle
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	# Check if selected text already has this formatting
	var has_formatting = check_selection_has_formatting(format_type)
	
	# Apply opposite formatting
	match format_type:
		"bold":
			toggle_specific_formatting_in_selection("bold", not has_formatting)
		"italic":
			toggle_specific_formatting_in_selection("italic", not has_formatting)
		"underline":
			toggle_specific_formatting_in_selection("underline", not has_formatting)
		"code":
			apply_formatting_to_selection(false, false, false, not has_formatting)
	
	queue_redraw()

func check_selection_has_formatting(format_type: String) -> bool:
	if not has_selection():
		return false
	
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	var current_pos = 0
	
	# Check if any part of selection has this formatting
	for segment in segments:
		var segment_start = current_pos
		var segment_end = current_pos + segment.text.length()
		
		# Check if this segment overlaps with selection
		if segment_end > start_pos and segment_start < end_pos:
			match format_type:
				"bold":
					if segment.bold:
						return true
				"italic":
					if segment.italic:
						return true
				"underline":
					if segment.underline:
						return true
				"code":
					if segment.code:
						return true
		
		current_pos += segment.text.length()
	
	return false

func toggle_specific_formatting_in_selection(format_type: String, enable: bool):
	if not has_selection():
		return
	
	save_state()  # Save state before modification
	
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	var new_segments: Array[TextSegment] = []
	var current_pos = 0
	
	for segment in segments:
		var segment_start = current_pos
		var segment_end = current_pos + segment.text.length()
		
		if segment_end <= start_pos or segment_start >= end_pos:
			# Segment is outside selection - keep unchanged
			new_segments.append(segment.copy())
		elif segment_start >= start_pos and segment_end <= end_pos:
			# Segment is completely within selection - toggle specific formatting
			var new_segment = segment.copy()
			match format_type:
				"bold":
					new_segment.bold = enable
				"italic":
					new_segment.italic = enable
				"underline":
					new_segment.underline = enable
			new_segments.append(new_segment)
		else:
			# Segment is partially within selection - split it
			if segment_start < start_pos:
				# Part before selection
				var before_segment = segment.copy()
				before_segment.text = segment.text.substr(0, start_pos - segment_start)
				new_segments.append(before_segment)
			
			# Part within selection
			var selection_start_in_segment = max(0, start_pos - segment_start)
			var selection_end_in_segment = min(segment.text.length(), end_pos - segment_start)
			var selected_text = segment.text.substr(selection_start_in_segment, selection_end_in_segment - selection_start_in_segment)
			
			if selected_text.length() > 0:
				var selected_segment = segment.copy()
				selected_segment.text = selected_text
				match format_type:
					"bold":
						selected_segment.bold = enable
					"italic":
						selected_segment.italic = enable
					"underline":
						selected_segment.underline = enable
				new_segments.append(selected_segment)
			
			if segment_end > end_pos:
				# Part after selection
				var after_segment = segment.copy()
				after_segment.text = segment.text.substr(end_pos - segment_start)
				new_segments.append(after_segment)
		
		current_pos += segment.text.length()
	
	segments = new_segments
	text_changed.emit()
	queue_redraw()

func apply_formatting_to_selection(bold: bool, italic: bool, underline: bool, code: bool):
	if not has_selection():
		return
	
	save_state()  # Save state before modification
	
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	var new_segments: Array[TextSegment] = []
	var current_pos = 0
	
	for segment in segments:
		var segment_start = current_pos
		var segment_end = current_pos + segment.text.length()
		
		if segment_end <= start_pos or segment_start >= end_pos:
			# Segment is outside selection - keep unchanged
			new_segments.append(segment.copy())
		elif segment_start >= start_pos and segment_end <= end_pos:
			# Segment is completely within selection - apply formatting
			var new_segment = segment.copy()
			new_segment.bold = bold
			new_segment.italic = italic
			new_segment.underline = underline
			new_segment.code = code
			new_segments.append(new_segment)
		else:
			# Segment is partially within selection - split it
			if segment_start < start_pos:
				# Part before selection
				var before_segment = segment.copy()
				before_segment.text = segment.text.substr(0, start_pos - segment_start)
				new_segments.append(before_segment)
			
			# Part within selection
			var selection_start_in_segment = max(0, start_pos - segment_start)
			var selection_end_in_segment = min(segment.text.length(), end_pos - segment_start)
			var selected_text = segment.text.substr(selection_start_in_segment, selection_end_in_segment - selection_start_in_segment)
			
			if selected_text.length() > 0:
				var selected_segment = segment.copy()
				selected_segment.text = selected_text
				selected_segment.bold = bold
				selected_segment.italic = italic
				selected_segment.underline = underline
				selected_segment.code = code
				new_segments.append(selected_segment)
			
			if segment_end > end_pos:
				# Part after selection
				var after_segment = segment.copy()
				after_segment.text = segment.text.substr(end_pos - segment_start)
				new_segments.append(after_segment)
		
		current_pos += segment.text.length()
	
	segments = new_segments
	text_changed.emit()
	queue_redraw()

func get_text() -> String:
	var result = ""
	for segment in segments:
		result += segment.text
	return result

func set_text(text: String):
	segments = [TextSegment.new(text)]
	cursor_position = 0
	queue_redraw()

# Selection functions
func has_selection() -> bool:
	return selection_start != -1 and selection_end != -1 and selection_start != selection_end

func start_selection():
	if selection_start == -1:
		selection_start = cursor_position

func update_selection():
	selection_end = cursor_position

func clear_selection():
	selection_start = -1
	selection_end = -1
	intentional_empty_line_selection = false
	queue_redraw()

func select_all():
	selection_start = 0
	selection_end = get_total_text_length()
	cursor_position = selection_end
	queue_redraw()

func delete_selection():
	if not has_selection():
		return
	
	save_state()  # Save state before modification
	
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	# Find segments affected by deletion
	var new_segments: Array[TextSegment] = []
	var current_pos = 0
	
	for segment in segments:
		var segment_start = current_pos
		var segment_end = current_pos + segment.text.length()
		
		if segment_end <= start_pos:
			# Segment is completely before selection - keep it
			new_segments.append(segment.copy())
		elif segment_start >= end_pos:
			# Segment is completely after selection - keep it
			new_segments.append(segment.copy())
		elif segment_start < start_pos and segment_end > end_pos:
			# Selection is within this segment - split it
			var before_text = segment.text.substr(0, start_pos - segment_start)
			var after_text = segment.text.substr(end_pos - segment_start)
			var new_segment = segment.copy()
			new_segment.text = before_text + after_text
			new_segments.append(new_segment)
		elif segment_start < start_pos and segment_end > start_pos:
			# Selection starts within this segment
			var before_text = segment.text.substr(0, start_pos - segment_start)
			if before_text.length() > 0:
				var new_segment = segment.copy()
				new_segment.text = before_text
				new_segments.append(new_segment)
		elif segment_start < end_pos and segment_end > end_pos:
			# Selection ends within this segment
			var after_text = segment.text.substr(end_pos - segment_start)
			if after_text.length() > 0:
				var new_segment = segment.copy()
				new_segment.text = after_text
				new_segments.append(new_segment)
		# Segments completely within selection are deleted (not added)
		
		current_pos += segment.text.length()
	
	# Ensure we have at least one segment
	if new_segments.is_empty():
		new_segments.append(TextSegment.new(""))
	
	segments = new_segments
	cursor_position = start_pos
	clear_selection()
	text_changed.emit()

func get_selected_text() -> String:
	if not has_selection():
		return ""
	
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	var text_content = get_text()
	return text_content.substr(start_pos, end_pos - start_pos)

# Clipboard functions
func copy_selection():
	if has_selection():
		DisplayServer.clipboard_set(get_selected_text())

func cut_selection():
	if has_selection():
		save_state()  # Save state before modification
		copy_selection()
		delete_selection()

func paste_from_clipboard():
	save_state()  # Save state before modification
	
	var clipboard_text = DisplayServer.clipboard_get()
	if clipboard_text.length() > 0:
		if has_selection():
			delete_selection()
		
		# Insert entire text as single operation without calling save_state for each character
		var segment_info = find_segment_at_position(cursor_position)
		var segment = segment_info.segment
		var local_pos = segment_info.local_position
		
		# Insert clipboard text with current formatting
		segment.text = segment.text.insert(local_pos, clipboard_text)
		cursor_position += clipboard_text.length()
		
		text_changed.emit()
		queue_redraw()

# Navigation functions
func move_cursor_to_line_start():
	# Move cursor to start of current line
	var text_content = get_text()
	var pos = cursor_position
	while pos > 0 and text_content[pos - 1] != '\n':
		pos -= 1
	cursor_position = pos
	queue_redraw()

func move_cursor_to_line_end():
	# Move cursor to end of current line
	var text_content = get_text()
	var pos = cursor_position
	while pos < text_content.length() and text_content[pos] != '\n':
		pos += 1
	cursor_position = pos
	queue_redraw()

func _can_drop_data(position, data):
	return false

func _drop_data(position, data):
	pass


func select_word_at_position(pos: int):
	var text_content = get_text()
	if text_content.is_empty():
		return
	
	pos = clamp(pos, 0, text_content.length())
	
	# Find word boundaries
	var word_start = pos
	var word_end = pos
	
	# Find start of word
	while word_start > 0 and is_word_char(text_content[word_start - 1]):
		word_start -= 1
	
	# Find end of word
	while word_end < text_content.length() and is_word_char(text_content[word_end]):
		word_end += 1
	
	# Select the word
	if word_start < word_end:
		selection_start = word_start
		selection_end = word_end
		cursor_position = word_end
		queue_redraw()

func is_word_char(char: String) -> bool:
	# Consider alphanumeric characters and underscore as word characters
	var code = char.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code == 95

func get_line_number_at_y(y_pos: float) -> int:
	# Convert Y position to line number (1-based)
	# Handle edge cases and bounds properly
	
	# If above text area, return line 1
	if y_pos < text_margin.y:
		return 1
	
	# Calculate line based on position
	var line_index = int((y_pos - text_margin.y) / line_height)
	var calculated_line = line_index + 1
	
	# Get actual line count to prevent going beyond available lines
	var text_content = get_text()
	var actual_line_count = 1
	for i in range(text_content.length()):
		if text_content[i] == '\n':
			actual_line_count += 1
	
	# Clamp to valid range
	return clamp(calculated_line, 1, actual_line_count)

func get_line_at_position(text_pos: int) -> int:
	# Convert text position to line number (1-based)
	var text_content = get_text()
	var line_number = 1
	
	for i in range(min(text_pos, text_content.length())):
		if text_content[i] == '\n':
			line_number += 1
	
	return line_number

# Undo/Redo system functions
func save_state():
	# Save current state to undo stack
	var state = UndoState.new(segments, cursor_position, selection_start, selection_end)
	undo_stack.append(state)
	
	# Limit undo stack size
	if undo_stack.size() > max_undo_steps:
		undo_stack.pop_front()
	
	# Clear redo stack when new action is performed
	redo_stack.clear()

func undo():
	if undo_stack.is_empty():
		return
	
	# Save current state to redo stack
	var current_state = UndoState.new(segments, cursor_position, selection_start, selection_end)
	redo_stack.append(current_state)
	
	# Restore previous state
	var prev_state = undo_stack.pop_back()
	restore_state(prev_state)

func redo():
	if redo_stack.is_empty():
		return
	
	# Save current state to undo stack
	var current_state = UndoState.new(segments, cursor_position, selection_start, selection_end)
	undo_stack.append(current_state)
	
	# Restore next state
	var next_state = redo_stack.pop_back()
	restore_state(next_state)

func restore_state(state: UndoState):
	# Restore segments
	segments.clear()
	for seg in state.segments_data:
		segments.append(seg.copy())
	
	# Restore cursor and selection
	cursor_position = state.cursor_pos
	selection_start = state.selection_start_pos
	selection_end = state.selection_end_pos
	
	# Update display
	text_changed.emit()
	queue_redraw()

func select_entire_line(line_number: int):
	# Select the entire line (1-based line number)
	var text_content = get_text()
	if text_content.is_empty():
		selection_start = 0
		selection_end = 0
		cursor_position = 0
		queue_redraw()
		return
	
	# Build line positions array for more reliable line finding
	var line_starts = [0]  # Start positions of each line
	for i in range(text_content.length()):
		if text_content[i] == '\n':
			line_starts.append(i + 1)
	
	# Check if line_number is valid
	if line_number < 1 or line_number > line_starts.size():
		# Invalid line number - clear selection
		selection_start = -1
		selection_end = -1
		cursor_position = 0
		queue_redraw()
		return
	
	# Get line boundaries
	var line_start = line_starts[line_number - 1]  # Convert to 0-based
	var line_end = line_start
	
	# Find end of this line
	if line_number < line_starts.size():
		# Not the last line - end is just before next line start
		line_end = line_starts[line_number] - 1  # -1 to exclude the newline
	else:
		# Last line - go to end of text
		line_end = text_content.length()
	
	# Set selection
	selection_start = line_start
	selection_end = line_end
	cursor_position = line_end
	
	# Set flag for intentional empty line selection if this is an empty line
	intentional_empty_line_selection = (line_start == line_end)
	
	queue_redraw()

func select_line_range(start_line: int, end_line: int):
	# Select a range of lines (1-based line numbers) using same logic as select_entire_line
	var text_content = get_text()
	if text_content.is_empty():
		selection_start = 0
		selection_end = 0
		cursor_position = 0
		queue_redraw()
		return
	
	# Build line positions array - same as select_entire_line
	var line_starts = [0]
	for i in range(text_content.length()):
		if text_content[i] == '\n':
			line_starts.append(i + 1)
	
	# Clamp line numbers to valid range
	start_line = clamp(start_line, 1, line_starts.size())
	end_line = clamp(end_line, 1, line_starts.size())
	
	# Determine direction
	var first_line = min(start_line, end_line)
	var last_line = max(start_line, end_line)
	
	# Get start position of first line
	var range_start = line_starts[first_line - 1]
	
	# Get end position of last line
	var range_end
	if last_line < line_starts.size():
		# Not the last line - end is just before next line start
		range_end = line_starts[last_line] - 1  # -1 to exclude the newline
	else:
		# Last line - go to end of text
		range_end = text_content.length()
	
	# Set selection
	selection_start = range_start
	selection_end = range_end
	cursor_position = range_end
	
	queue_redraw()