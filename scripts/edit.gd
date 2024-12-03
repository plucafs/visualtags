extends MarginContainer

signal rename_completed

var tag_label = preload("res://scenes/tag_label.tscn")
@onready var file_name_line_edit = %FilesNameLineEdit as LineEdit
@onready var file_tags_line_edit = %FileTagsLineEdit as LineEdit
@onready var tags_container: HBoxContainer = %TagsLabelsContainer

const SPACE_DASH_DASH_SPACE_CHARS 	:= " -- "
const SPACE_CHAR 					:= " "
const DOT_CHAR 						:= "."

var active_dir 						:= ""
var working_element_index			:= 0
var show_more 						:= false
var file_ext 						:= ""

func _ready() -> void:
	SignalBus.connect("active_file_name_selected", _on_active_file_name_selected)
	SignalBus.connect("active_tags_selected", _on_active_tags_selected)
	SignalBus.connect("active_directory_selected", _on_active_directory_selected)
	SignalBus.connect("global_tags_list_built", _on_global_tags_list_built)

# !SIGNALS
func _on_active_directory_selected(dir := ""):
	if not visible: visible = true
	active_dir = dir

func _on_active_file_name_selected(file_name := ""):
	if not visible: visible = true
	file_name_line_edit.text = file_name
	
func _on_active_tags_selected(tags := []):
	if not visible: visible = true
	if tags.is_empty():
		file_tags_line_edit.text = ""
		return
	var tags_joined = " ".join(tags)
	file_tags_line_edit.text = tags_joined
	for child in tags_container.get_children():
		tags_container.remove_child(child)
	for tag in tags:
		var tag_label_instance = tag_label.instantiate()
		tag_label_instance.get_node("%Label").text = tag
		tags_container.add_child(tag_label_instance)

func _on_global_tags_list_built(tags_list):
	print_debug("Setting tags_list for tags_line_edit")
	file_tags_line_edit.tags_list = tags_list
# !SIGNALS

func reset():
	active_dir = ""
	working_element_index = 0
	file_name_line_edit.clear()
	file_tags_line_edit.clear()
	hide()

func set_working_element_index(index: int):
	working_element_index = index

func _on_files_name_line_edit_text_submitted(new_file_name: String) -> void:
	new_file_name = new_file_name.strip_edges()
	if new_file_name.is_empty():
		print("The submitted file name is empty. Returning.")
		return
	update_file_name(new_file_name)

func _on_file_tags_line_edit_text_submitted(new_tags: String) -> void:
	new_tags = new_tags.strip_edges()
	if new_tags.is_empty():
		print_debug("The submitted tags are empty. Continuing.")
	var new_tags_array = new_tags.split(SPACE_CHAR, false)
	update_file_tag(new_tags_array)

func _on_edit_minimize_button_toggled(toggled_on: bool) -> void:
	show_more = true
	self.visible = !visible

func update_file_name(new_name: String):
	var dir_parts := Array(active_dir.split("/"))
	dir_parts = dir_parts.filter(func(part: String): return part.to_lower().strip_edges() != "")
	var file_name = dir_parts[-1]

	var has_tags
	var tags_state = TagUtils.has_tags(file_name, true)
	match tags_state:
		TagUtils.TAGS_STATE.NO_TAGS_AFTER_SEPARATOR, \
		TagUtils.TAGS_STATE.MULTIPLE_SEPARATORS, \
		TagUtils.TAGS_STATE.NO_SEPARATOR:
			has_tags = false
		_: has_tags = true

	var tags := ""
	# Contains tags
	if has_tags:
		tags = file_name.split(SPACE_DASH_DASH_SPACE_CHARS)[-1]
		dir_parts.remove_at(dir_parts.size() - 1)
		dir_parts.push_back(
			new_name 					+
			SPACE_DASH_DASH_SPACE_CHARS +
			tags.strip_edges() 			+
			file_ext
		)
	else:
		# Remove the original name
		dir_parts.remove_at(dir_parts.size() - 1)
		# Push to the start the new name
		dir_parts.push_back(new_name)
		
		tags = ""
	
	var new_file_path = "/" + "/".join(dir_parts)
	
	print("New file name\n	%s\n	%s" % [active_dir, new_file_path])
	
	var err = DirAccess.rename_absolute(active_dir, new_file_path)
	if err == OK:
		emit_signal("rename_completed")
		working_element_index = 0
		active_dir = ""

func update_file_tag(new_tags: PackedStringArray):
	var extension = active_dir.get_extension()
	if extension.is_empty(): pass
	
		# -1: "abc -- d e f"
	var file_name_parts = active_dir.split("/", false)
		# ["abc", "d e f"]
	var name_and_tags = file_name_parts[-1].split(SPACE_DASH_DASH_SPACE_CHARS)
		# "abc"
	var old_file_name: String = name_and_tags[0]
		# "d e f"
	if name_and_tags.size() > 1:
		print("File has tags")
		file_name_parts.remove_at(file_name_parts.size() - 1)
		# If all the tags are deleted, remove also the SPACE_DASH_DASH_SPACE_CHARS
		# from the file name
		if new_tags.is_empty():
			file_name_parts.push_back(
				old_file_name 			+
				DOT_CHAR 					+
				extension
			)
		else:
			file_name_parts.push_back(
				old_file_name 			+
				SPACE_DASH_DASH_SPACE_CHARS 	+
				" ".join(new_tags) 		+
				DOT_CHAR 					+
				extension
			)
	else:
		print("File doesn't have tags")
		var old_file_name_parts = old_file_name.split(".")
		old_file_name_parts = old_file_name_parts.slice(0, -1)
		var file_name := "";
		if old_file_name_parts.size() > 1:
			file_name = ".".join(old_file_name_parts)
		else:
			file_name = old_file_name_parts[0]
		
		# Remove the original file name
		file_name_parts.remove_at(file_name_parts.size() - 1)
		# Push to the start the new name with tags and extension
		file_name_parts.push_back(
			file_name
			+ SPACE_DASH_DASH_SPACE_CHARS
			+ " ".join(new_tags)
			+ DOT_CHAR
			+ extension
		)

	var new_file_path = "/" + "/".join(file_name_parts)
	print("New tags\n	%s\n	%s" % [active_dir, new_file_path])
	
	var err := DirAccess.rename_absolute(active_dir, new_file_path)
	if err == OK:
		emit_signal("rename_completed")
		working_element_index = 0
		active_dir = ""
		return
	printerr("Error")
