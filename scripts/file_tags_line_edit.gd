@icon("res://AutocompleteLineEdit.svg")
extends LineEdit

const SPACE := " "
## Eases adding new words on linedit focus
@export var on_enter_focus_caret_to_the_end := true
@export var tags_list := PackedStringArray([])

## You need to take care to add the spaces
@export var words_separator := SPACE

var text_buffer := ""
var is_key_backspace_pressed := false
var is_key_delete_pressed := false

func _ready() -> void:
	connect("text_changed", _on_text_changed)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	
	var _text := text
	match event.keycode:
		KEY_DELETE:
			is_key_delete_pressed = true
			return
		KEY_BACKSPACE:
			is_key_backspace_pressed = true
			return
		KEY_ENTER:
			if get_selected_text().length() == 0: return
			caret_column = _text.length()
			text_buffer = _text
			deselect()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			if get_selected_text().length() == 0: return
			caret_column = _text.length()
			text_buffer = _text
			deselect()
			get_viewport().set_input_as_handled()
		_:
			text_buffer = _text
			is_key_backspace_pressed = false
			is_key_delete_pressed = false
	
## Handles only lowercase words
func _on_text_changed(_text: String) -> void:
	tags_list.sort()
	_text = _text.strip_edges().to_lower()
	var has_words_separator = _text.contains(words_separator)
	var other_tags := []

	if has_words_separator:
		var words_separator_in_text = _text.count(words_separator)
		if words_separator_in_text == _text.length():
			text = ""; return

		var all_text_tags := _text.split(words_separator, false)
		_text = all_text_tags[-1]
		all_text_tags.resize(all_text_tags.size() - 1)
		other_tags = all_text_tags

	if _text.contains(SPACE):
		text = text_buffer
		caret_column = text_buffer.length()
		return

	text_buffer = _text
	
	if is_key_backspace_pressed: return

	if is_key_delete_pressed: return
		
	var ordered_words_list = Array(tags_list)\
		.filter(func(word): return word.begins_with(_text) && not word == _text)
	
	if ordered_words_list.is_empty(): return

	var _text_length = _text.length()
	if _text_length == 0: return
		
	var suggestion_single_tag = _text + ordered_words_list[0].erase(0, _text_length)
	var suggestion_multi_tags = ordered_words_list[0].erase(0, _text_length)
	
	if has_words_separator:
		text = words_separator.join(other_tags) + words_separator + _text
		var start_caret_column = text.length()
		text += suggestion_multi_tags
		select(start_caret_column, -1)
		caret_column = start_caret_column
		return

	text = suggestion_single_tag
	select(_text_length, -1)
	caret_column = _text_length


func _on_focus_entered() -> void:
	if on_enter_focus_caret_to_the_end:
		caret_column = text.length()
