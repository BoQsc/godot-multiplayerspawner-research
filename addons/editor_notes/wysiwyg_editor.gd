@tool
extends Control
class_name WysiwygEditor

# Custom WYSIWYG rich text editor that renders markdown visually while allowing direct editing

# Text content and formatting
var content: String = ""
var formatted_segments: Array[FormattedSegment] = []
var cursor_position: int = 0
var selection_start: int = -1
var selection_end: int = -1

# Visual properties
var font: Font
var bold_font: Font
var italic_font: Font
var bold_italic_font: Font
var code_font: Font
var font_size: int = 16
var line_height: float = 20.0
var margin: Vector2 = Vector2(10, 10)

# Colors
var text_color: Color = Color.WHITE
var selection_color: Color = Color(0.2, 0.4, 0.8, 0.5)
var cursor_color: Color = Color.WHITE
var header_color: Color = Color(0.9, 0.9, 1.0)
var code_color: Color = Color(0.8, 1.0, 0.8)
var link_color: Color = Color(0.6, 0.8, 1.0)

# Cursor blink
var cursor_blink_time: float = 0.0
var cursor_visible: bool = true
var cursor_blink_speed: float = 1.0

# Input handling
var mouse_pressed: bool = false

# Signals
signal text_changed()
signal formatting_applied(type: String, start: int, end: int)

class FormattedSegment:
	var text: String
	var start_pos: int
	var end_pos: int
	var formatting: Dictionary = {}
	
	func _init(txt: String, start: int, end: int):
		text = txt
		start_pos = start
		end_pos = end
	
	func has_formatting(type: String) -> bool:
		return formatting.has(type) and formatting[type]
	
	func set_formatting(type: String, enabled: bool):
		formatting[type] = enabled

func _ready():
	set_focus_mode(Control.FOCUS_ALL)
	load_fonts()
	parse_content()
	
func load_fonts():
	# Use theme fonts or create default ones
	font = ThemeDB.fallback_font
	bold_font = ThemeDB.fallback_font
	italic_font = ThemeDB.fallback_font  
	bold_italic_font = ThemeDB.fallback_font
	code_font = ThemeDB.fallback_font

func _draw():
	draw_background()
	draw_text_content()
	draw_cursor()
	draw_selection()

func draw_background():
	var bg_color = Color(0.1, 0.1, 0.1, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)

func draw_text_content():
	if formatted_segments.is_empty():
		return
		
	var pos = margin
	var current_line_height = line_height
	
	for segment in formatted_segments:
		if segment.text == "\n":
			pos.y += current_line_height
			pos.x = margin.x
			current_line_height = line_height
			continue
			
		var segment_font = get_font_for_segment(segment)
		var segment_color = get_color_for_segment(segment)
		var segment_size = get_font_size_for_segment(segment)
		
		# Handle line wrapping
		var text_width = segment_font.get_string_size(segment.text, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size).x
		if pos.x + text_width > size.x - margin.x:
			pos.y += current_line_height
			pos.x = margin.x
			current_line_height = line_height
		
		# Draw text
		draw_string(segment_font, pos, segment.text, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size, segment_color)
		
		# Update position
		pos.x += text_width
		
		# Update line height for headers
		if segment.has_formatting("header"):
			current_line_height = max(current_line_height, segment_size * 1.2)

func get_font_for_segment(segment: FormattedSegment) -> Font:
	var is_bold = segment.has_formatting("bold")
	var is_italic = segment.has_formatting("italic")
	var is_code = segment.has_formatting("code")
	
	if is_code:
		return code_font
	elif is_bold and is_italic:
		return bold_italic_font
	elif is_bold:
		return bold_font
	elif is_italic:
		return italic_font
	else:
		return font

func get_color_for_segment(segment: FormattedSegment) -> Color:
	if segment.has_formatting("header"):
		return header_color
	elif segment.has_formatting("code"):
		return code_color
	elif segment.has_formatting("link"):
		return link_color
	else:
		return text_color

func get_font_size_for_segment(segment: FormattedSegment) -> int:
	if segment.has_formatting("header"):
		var level = segment.formatting.get("header_level", 1)
		match level:
			1: return font_size + 12
			2: return font_size + 8
			3: return font_size + 4
			4: return font_size + 2
			5: return font_size + 1
			6: return font_size
			_: return font_size
	else:
		return font_size

func draw_cursor():
	if not has_focus() or not cursor_visible:
		return
		
	var cursor_pos = get_visual_position_for_char(cursor_position)
	draw_line(cursor_pos, cursor_pos + Vector2(0, line_height), cursor_color, 2)

func draw_selection():
	if selection_start == -1 or selection_end == -1 or selection_start == selection_end:
		return
		
	var start_pos = get_visual_position_for_char(min(selection_start, selection_end))
	var end_pos = get_visual_position_for_char(max(selection_start, selection_end))
	
	# Simple selection rectangle (can be improved for multi-line)
	var selection_rect = Rect2(start_pos, end_pos - start_pos + Vector2(0, line_height))
	draw_rect(selection_rect, selection_color)

func get_visual_position_for_char(char_index: int) -> Vector2:
	var pos = margin
	var char_count = 0
	
	for segment in formatted_segments:
		if segment.text == "\n":
			if char_count >= char_index:
				return pos
			pos.y += line_height
			pos.x = margin.x
			char_count += 1
			continue
			
		var segment_font = get_font_for_segment(segment)
		var segment_size = get_font_size_for_segment(segment)
		
		if char_count + segment.text.length() >= char_index:
			# Character is in this segment
			var offset = char_index - char_count
			var partial_text = segment.text.substr(0, offset)
			var text_width = segment_font.get_string_size(partial_text, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size).x
			return Vector2(pos.x + text_width, pos.y)
		
		# Move past this segment
		var text_width = segment_font.get_string_size(segment.text, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size).x
		pos.x += text_width
		char_count += segment.text.length()
	
	return pos

func get_char_index_for_position(position: Vector2) -> int:
	var pos = margin
	var char_count = 0
	var current_line_start = char_count
	
	for segment in formatted_segments:
		if segment.text == "\n":
			if position.y <= pos.y + line_height:
				return char_count
			pos.y += line_height
			pos.x = margin.x
			char_count += 1
			current_line_start = char_count
			continue
			
		var segment_font = get_font_for_segment(segment)
		var segment_size = get_font_size_for_segment(segment)
		var text_width = segment_font.get_string_size(segment.text, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size).x
		
		if position.y <= pos.y + line_height and position.x <= pos.x + text_width:
			# Find character within this segment
			for i in range(segment.text.length()):
				var partial_width = segment_font.get_string_size(segment.text.substr(0, i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, segment_size).x
				if position.x <= pos.x + partial_width:
					return char_count + i
			return char_count + segment.text.length()
		
		pos.x += text_width
		char_count += segment.text.length()
	
	return char_count

func parse_content():
	# Parse markdown content into formatted segments
	formatted_segments.clear()
	
	if content.is_empty():
		formatted_segments.append(FormattedSegment.new("", 0, 0))
		return
	
	var lines = content.split("\n", true)
	var char_pos = 0
	
	for line_idx in range(lines.size()):
		var line = lines[line_idx]
		parse_line(line, char_pos)
		char_pos += line.length()
		
		# Add newline segment except for last line
		if line_idx < lines.size() - 1:
			var newline_segment = FormattedSegment.new("\n", char_pos, char_pos + 1)
			formatted_segments.append(newline_segment)
			char_pos += 1

func parse_line(line: String, start_pos: int):
	var pos = 0
	var char_pos = start_pos
	
	# Handle headers
	if line.begins_with("#"):
		var header_level = 0
		while pos < line.length() and line[pos] == "#":
			header_level += 1
			pos += 1
		
		if pos < line.length() and line[pos] == " ":
			pos += 1  # Skip space after #
			var header_text = line.substr(pos)
			var segment = FormattedSegment.new(header_text, char_pos + pos, char_pos + line.length())
			segment.set_formatting("header", true)
			segment.set_formatting("header_level", header_level)
			formatted_segments.append(segment)
			return
	
	# Parse inline formatting
	parse_inline_formatting(line, char_pos)

func parse_inline_formatting(text: String, start_pos: int):
	var pos = 0
	var char_pos = start_pos
	
	while pos < text.length():
		var segment_start = pos
		var segment_text = ""
		var formatting = {}
		
		# Look for formatting markers
		if pos + 1 < text.length() and text.substr(pos, 2) == "**":
			# Bold text
			pos += 2
			var end_pos = text.find("**", pos)
			if end_pos != -1:
				segment_text = text.substr(pos, end_pos - pos)
				formatting["bold"] = true
				pos = end_pos + 2
			else:
				segment_text = text.substr(segment_start, 2)
				pos += 2
		elif text[pos] == "*":
			# Italic text
			pos += 1
			var end_pos = text.find("*", pos)
			if end_pos != -1:
				segment_text = text.substr(pos, end_pos - pos)
				formatting["italic"] = true
				pos = end_pos + 1
			else:
				segment_text = text.substr(segment_start, 1)
		elif text[pos] == "`":
			# Code text
			pos += 1
			var end_pos = text.find("`", pos)
			if end_pos != -1:
				segment_text = text.substr(pos, end_pos - pos)
				formatting["code"] = true
				pos = end_pos + 1
			else:
				segment_text = text.substr(segment_start, 1)
		else:
			# Regular text - find next formatting marker
			var next_format = text.length()
			for marker in ["**", "*", "`"]:
				var marker_pos = text.find(marker, pos)
				if marker_pos != -1 and marker_pos < next_format:
					next_format = marker_pos
			
			segment_text = text.substr(pos, next_format - pos)
			pos = next_format
		
		if not segment_text.is_empty():
			var segment = FormattedSegment.new(segment_text, char_pos, char_pos + segment_text.length())
			for key in formatting:
				segment.set_formatting(key, formatting[key])
			formatted_segments.append(segment)
			char_pos += segment_text.length()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				grab_focus()
				mouse_pressed = true
				var char_index = get_char_index_for_position(event.position)
				set_cursor_position(char_index)
				clear_selection()
			else:
				mouse_pressed = false
		queue_redraw()
		
	elif event is InputEventMouseMotion and mouse_pressed:
		var char_index = get_char_index_for_position(event.position)
		if selection_start == -1:
			selection_start = cursor_position
		selection_end = char_index
		cursor_position = char_index
		queue_redraw()
		
	elif event is InputEventKey and event.pressed:
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	match event.keycode:
		KEY_LEFT:
			move_cursor(-1, event.shift_pressed)
		KEY_RIGHT:
			move_cursor(1, event.shift_pressed)
		KEY_HOME:
			move_cursor_to_line_start(event.shift_pressed)
		KEY_END:
			move_cursor_to_line_end(event.shift_pressed)
		KEY_BACKSPACE:
			delete_backward()
		KEY_DELETE:
			delete_forward()
		KEY_ENTER:
			insert_text("\n")
		KEY_A:
			if event.ctrl_pressed:
				select_all()
		KEY_C:
			if event.ctrl_pressed:
				copy_selection()
		KEY_V:
			if event.ctrl_pressed:
				paste_text()
		KEY_X:
			if event.ctrl_pressed:
				cut_selection()
		_:
			if event.unicode > 0 and event.unicode < 128:
				var char = char(event.unicode)
				if char.is_valid_unicode():
					insert_text(char)

func set_cursor_position(pos: int):
	cursor_position = clamp(pos, 0, content.length())
	queue_redraw()

func move_cursor(delta: int, extend_selection: bool = false):
	var new_pos = clamp(cursor_position + delta, 0, content.length())
	
	if extend_selection:
		if selection_start == -1:
			selection_start = cursor_position
		selection_end = new_pos
	else:
		clear_selection()
	
	cursor_position = new_pos
	queue_redraw()

func move_cursor_to_line_start(extend_selection: bool = false):
	var line_start = content.rfind("\n", cursor_position - 1)
	line_start = line_start + 1 if line_start != -1 else 0
	
	if extend_selection:
		if selection_start == -1:
			selection_start = cursor_position
		selection_end = line_start
	else:
		clear_selection()
	
	cursor_position = line_start
	queue_redraw()

func move_cursor_to_line_end(extend_selection: bool = false):
	var line_end = content.find("\n", cursor_position)
	line_end = line_end if line_end != -1 else content.length()
	
	if extend_selection:
		if selection_start == -1:
			selection_start = cursor_position
		selection_end = line_end
	else:
		clear_selection()
	
	cursor_position = line_end
	queue_redraw()

func clear_selection():
	selection_start = -1
	selection_end = -1

func select_all():
	selection_start = 0
	selection_end = content.length()
	cursor_position = content.length()
	queue_redraw()

func has_selection() -> bool:
	return selection_start != -1 and selection_end != -1 and selection_start != selection_end

func get_selected_text() -> String:
	if not has_selection():
		return ""
	var start = min(selection_start, selection_end)
	var end = max(selection_start, selection_end)
	return content.substr(start, end - start)

func delete_selection():
	if not has_selection():
		return
	
	var start = min(selection_start, selection_end)
	var end = max(selection_start, selection_end)
	
	content = content.substr(0, start) + content.substr(end)
	cursor_position = start
	clear_selection()
	parse_content()
	queue_redraw()
	text_changed.emit()

func insert_text(text: String):
	if has_selection():
		delete_selection()
	
	content = content.insert(cursor_position, text)
	cursor_position += text.length()
	parse_content()
	queue_redraw()
	text_changed.emit()

func delete_backward():
	if has_selection():
		delete_selection()
	elif cursor_position > 0:
		content = content.substr(0, cursor_position - 1) + content.substr(cursor_position)
		cursor_position -= 1
		parse_content()
		queue_redraw()
		text_changed.emit()

func delete_forward():
	if has_selection():
		delete_selection()
	elif cursor_position < content.length():
		content = content.substr(0, cursor_position) + content.substr(cursor_position + 1)
		parse_content()
		queue_redraw()
		text_changed.emit()

func copy_selection():
	if has_selection():
		DisplayServer.clipboard_set(get_selected_text())

func paste_text():
	var clipboard_text = DisplayServer.clipboard_get()
	if not clipboard_text.is_empty():
		insert_text(clipboard_text)

func cut_selection():
	if has_selection():
		copy_selection()
		delete_selection()

func set_text(new_text: String):
	content = new_text
	cursor_position = clamp(cursor_position, 0, content.length())
	clear_selection()
	parse_content()
	queue_redraw()

func get_text() -> String:
	return content

func apply_formatting(format_type: String, start_marker: String, end_marker: String = ""):
	var end_mark = end_marker if end_marker != "" else start_marker
	
	if has_selection():
		var start = min(selection_start, selection_end)
		var end = max(selection_start, selection_end)
		var selected_text = content.substr(start, end - start)
		var formatted_text = start_marker + selected_text + end_mark
		
		content = content.substr(0, start) + formatted_text + content.substr(end)
		cursor_position = start + formatted_text.length()
		clear_selection()
	else:
		var placeholder = "text"
		var formatted_text = start_marker + placeholder + end_mark
		content = content.insert(cursor_position, formatted_text)
		
		# Select the placeholder
		selection_start = cursor_position + start_marker.length()
		selection_end = selection_start + placeholder.length()
		cursor_position = selection_end
	
	parse_content()
	queue_redraw()
	text_changed.emit()

func _process(delta):
	# Handle cursor blinking
	cursor_blink_time += delta
	if cursor_blink_time >= cursor_blink_speed:
		cursor_visible = not cursor_visible
		cursor_blink_time = 0.0
		if has_focus():
			queue_redraw()

func _notification(what):
	if what == NOTIFICATION_FOCUS_ENTER:
		cursor_visible = true
		queue_redraw()
	elif what == NOTIFICATION_FOCUS_EXIT:
		cursor_visible = false
		queue_redraw()