extends Control

@onready var setting = preload("res://scenes/setting_row.tscn")
@onready var tag_buttons_container: HFlowContainer = %TagButtonsContainer
@onready var search_setting_line_edit: LineEdit = %SearchSettingLineEdit
@onready var settings_container: VBoxContainer = %SettingsContainer
@onready var reset_toggles_button: TextureButton = %ResetTogglesButton

const TYPE_POOL_PATHS = "pool_paths"
const TYPE_SELECT_MULTIPLE = "select_multiple_paths"
const TYPE_SELECT_PATH = "select_path"
const TYPE_TOGGLE = "toggle"

var settings_tag_list: PackedStringArray
var tags_buffer: Array

func _ready() -> void:
	#reset_toggles_button.connect("reset_tag_buffer", _on_reset_tag_buffer)
	tag_buttons_container.hide()
	search_setting_line_edit.grab_focus()
	for dict in SettingsManager.SETTINGS_LIST:
		settings_tag_list.append_array(dict.tags)
		add_setting(dict)
		
	settings_tag_list = ArrayUtils.array_unique(settings_tag_list)
	settings_tag_list.sort()
	for tag in settings_tag_list:
		add_tag(tag)

func get_setting(dict: Dictionary):
	var setting_row: SettingRow = setting.instantiate()
	var type = dict.type
	if type == TYPE_TOGGLE:
		setting_row.is_toggle = true
		var is_toggled = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS, 
			dict.id, 
			false
		)
		setting_row.is_toggled = is_toggled
	elif type == TYPE_SELECT_PATH:
		setting_row.is_select_path = true
		var path = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS,
			dict.id, 
			""
		)
		setting_row.path = path
	elif type == TYPE_SELECT_MULTIPLE:
		setting_row.is_select_multiple_paths = true
		var multiple_paths = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS,
			dict.id,
			[""]
		)
		setting_row.multiple_paths = multiple_paths
	elif type == TYPE_POOL_PATHS:
		setting_row.is_select_pool_path = true
		var multiple_paths = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS,
			dict.id,
			[""]
		)
		setting_row.multiple_paths = multiple_paths
		
	setting_row.title = dict.title
	setting_row.description = dict.description
	setting_row.tags = dict.tags
	setting_row.id = dict.id
	
	return setting_row

func add_setting(dict: Dictionary):
	var setting_node: SettingRow = get_setting(dict)
	settings_container.add_child(setting_node)
	
func add_tag(tag: String):
	var toggle_button = Button.new()
	toggle_button.toggle_mode = true
	toggle_button.text = tag
	toggle_button.toggled.connect(_on_button_toggled.bind(tag))
	tag_buttons_container.add_child(toggle_button)

func clear_settings():
	for setting_node in settings_container.get_children():
		setting_node.queue_free()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_reset_toggles_button_pressed() -> void:
	tags_buffer.clear()
	print("var tag_buffer was cleared")

func _on_button_toggled(toggled, tag_name):
	print("Button toggled\n	%s %s" % [toggled, tag_name])
	if toggled == true: tags_buffer.append(tag_name)
	else: tags_buffer.erase(tag_name)
	
	if tags_buffer.is_empty():
		for setting_node in settings_container.get_children():
			setting_node.show()
		return

	for setting_node in settings_container.get_children():
		if setting_node.is_class("HSeparator"): continue
		print(setting_node.tags)
		var is_match: bool = ArrayUtils.arrays_contains_array(setting_node.tags, tags_buffer)
		if is_match: setting_node.show()
		else: setting_node.hide()

func _on_search_setting_line_edit_text_changed(new_text: String) -> void:
	pass # Replace with function body.

func _on_tags_button_pressed() -> void:
	tag_buttons_container.visible = !tag_buttons_container.visible
