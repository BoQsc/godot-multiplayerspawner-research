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

# Fonts and styling
var base_font: Font
var bold_font: Font  
var italic_font: Font
var bold_italic_font: Font
var code_font: Font

# Visual properties
var font_size: int = 16
var line_height: float = 20.0
var margin: Vector2 = Vector2(10, 10)
var cursor_blink_time: float = 0.0
var cursor_visible: bool = true

# Signals
signal text_changed()

func _ready():
	setup_fonts()
	setup_initial_text()
	
	# Enable input handling
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	
	# Make sure we can receive focus
	focus_mode = Control.FOCUS_ALL
	
	# Auto-focus when ready
	call_deferred("grab_focus")

func setup_fonts():
	# Get default system font
	base_font = ThemeDB.fallback_font
	
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

func _draw():
	draw_background()
	draw_selection()  # Draw selection behind text
	draw_text_segments()
	draw_cursor()  # Draw cursor on top

func draw_background():
	# Draw editor background
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, false, 1.0)

func draw_text_segments():
	var pos = margin
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
				font.draw_string(get_canvas_item(), text_pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
				pos.x += font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			
			# Move to next line if there's a newline
			if line_idx < segment_lines.size() - 1:
				pos.x = margin.x
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
	if segment.code:
		return Color.DARK_GREEN
	else:
		return Color.BLACK

func draw_cursor():
	if not cursor_visible:
		return
		
	var cursor_pos = get_visual_position(cursor_position)
	draw_line(cursor_pos, cursor_pos + Vector2(0, line_height), Color.BLACK, 2.0)

func draw_selection():
	if selection_start == -1 or selection_end == -1:
		return
		
	var start_pos = min(selection_start, selection_end)
	var end_pos = max(selection_start, selection_end)
	
	if start_pos == end_pos:
		return
	
	var start_visual = get_visual_position(start_pos)
	var end_visual = get_visual_position(end_pos)
	
	# Handle single-line and multi-line selections
	if abs(start_visual.y - end_visual.y) < line_height:
		# Single line selection
		var rect = Rect2(start_visual, Vector2(end_visual.x - start_visual.x, line_height))
		draw_rect(rect, Color(0.3, 0.6, 1.0, 0.3))
	else:
		# Multi-line selection
		var current_y = start_visual.y
		
		# First line (from start to end of line)
		var first_line_end = Vector2(size.x - margin.x, current_y)
		draw_rect(Rect2(start_visual, Vector2(first_line_end.x - start_visual.x, line_height)), Color(0.3, 0.6, 1.0, 0.3))
		current_y += line_height
		
		# Middle lines (full width)
		while current_y < end_visual.y:
			draw_rect(Rect2(Vector2(margin.x, current_y), Vector2(size.x - 2 * margin.x, line_height)), Color(0.3, 0.6, 1.0, 0.3))
			current_y += line_height
		
		# Last line (from start of line to end position)
		if current_y <= end_visual.y:
			draw_rect(Rect2(Vector2(margin.x, end_visual.y), Vector2(end_visual.x - margin.x, line_height)), Color(0.3, 0.6, 1.0, 0.3))

func get_visual_position(text_pos: int) -> Vector2:
	# Calculate position by rendering text segments up to cursor position
	text_pos = clamp(text_pos, 0, get_total_text_length())
	
	var pos = margin
	var current_pos = 0
	
	for segment in segments:
		if current_pos >= text_pos:
			break
			
		var font = get_segment_font(segment)
		var segment_text = segment.text
		var chars_to_process = min(segment_text.length(), text_pos - current_pos)
		
		# Process character by character within this segment
		for i in range(chars_to_process):
			var char = segment_text[i]
			if char == '\n':
				pos.x = margin.x
				pos.y += line_height
			else:
				# Use same method as drawing for consistency
				var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				pos.x += char_size.x
		
		current_pos += segment_text.length()
	
	return pos

func _process(delta):
	# Handle cursor blinking
	cursor_blink_time += delta
	if cursor_blink_time >= 1.0:
		cursor_visible = not cursor_visible
		cursor_blink_time = 0.0
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
		KEY_C:
			if ctrl_pressed:
				copy_selection()
		KEY_V:
			if ctrl_pressed:
				paste_from_clipboard()
		KEY_X:
			if ctrl_pressed:
				cut_selection()
		_:
			# Handle printable characters
			if event.unicode > 31 and event.unicode < 127:
				if has_selection():
					delete_selection()
				var char_str = char(event.unicode)
				insert_character(char_str)

func handle_mouse_input(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		var click_pos = get_text_position_at(event.position)
		if event.pressed:
			cursor_position = click_pos
			# Start selection on mouse down
			selection_start = click_pos
			selection_end = click_pos
		else:
			# End selection on mouse up
			if selection_start == selection_end:
				clear_selection()
		queue_redraw()

func handle_mouse_motion(event: InputEventMouseMotion):
	# Handle drag selection
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and selection_start != -1:
		var drag_pos = get_text_position_at(event.position)
		selection_end = drag_pos
		cursor_position = drag_pos
		queue_redraw()

func get_text_position_at(visual_pos: Vector2) -> int:
	# Convert visual position back to text position using same method as get_visual_position
	var pos = margin
	var text_pos = 0
	
	# If click is above text area, return position 0
	if visual_pos.y < margin.y:
		return 0
	
	for segment in segments:
		var font = get_segment_font(segment)
		for i in range(segment.text.length()):
			var char = segment.text[i]
			
			# Check if we're on the right line and close to the character
			if visual_pos.y >= pos.y and visual_pos.y < pos.y + line_height:
				if char == '\n':
					# If clicking at end of line, position cursor at end of line
					if visual_pos.x >= pos.x:
						return text_pos
					else:
						return text_pos
				else:
					var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
					# Check if click is within this character's bounds
					if visual_pos.x >= pos.x and visual_pos.x < pos.x + char_size.x:
						# Click closer to start or end of character?
						if visual_pos.x < pos.x + char_size.x / 2:
							return text_pos
						else:
							return text_pos + 1
					elif visual_pos.x < pos.x:
						return text_pos
			
			# Move to next character position
			if char == '\n':
				pos.x = margin.x
				pos.y += line_height
			else:
				var char_size = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				pos.x += char_size.x
			
			text_pos += 1
	
	# If clicked beyond all text, return end position
	return text_pos

func move_cursor(delta: int):
	cursor_position = max(0, min(get_total_text_length(), cursor_position + delta))
	cursor_visible = true
	cursor_blink_time = 0.0
	queue_redraw()

func insert_character(char: String):
	var segment_info = find_segment_at_position(cursor_position)
	var segment = segment_info.segment
	var local_pos = segment_info.local_position
	
	# Insert character with current formatting
	segment.text = segment.text.insert(local_pos, char)
	cursor_position += 1
	
	text_changed.emit()
	queue_redraw()

func delete_character(delta: int):
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

func apply_formatting_to_selection(bold: bool, italic: bool, underline: bool, code: bool):
	# This would split segments and apply formatting to the selected range
	# Complex implementation needed for proper selection formatting
	pass

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
	queue_redraw()

func select_all():
	selection_start = 0
	selection_end = get_total_text_length()
	cursor_position = selection_end
	queue_redraw()

func delete_selection():
	if not has_selection():
		return
	
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
		copy_selection()
		delete_selection()

func paste_from_clipboard():
	var clipboard_text = DisplayServer.clipboard_get()
	if clipboard_text.length() > 0:
		if has_selection():
			delete_selection()
		for char in clipboard_text:
			insert_character(char)

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