extends HBoxContainer
class_name SettingRow

var is_toggled: bool
var path: String
var multiple_paths: PackedStringArray
var multiple_strings: PackedStringArray

var id: String
var is_toggle: bool
var is_select_multiple_paths: bool
var is_select_path: bool
var is_select_pool_path: bool
var title: String
var description: String
var tags: PackedStringArray

var icon = preload("res://icons/x.svg")
@onready var select_path_container = %SelectPathContainer as HBoxContainer
@onready var title_label = %TitleLabel as Label
@onready var description_label = %DescriptionLabel as Label
@onready var tags_label = %TagsLabel as Label
@onready var directory_scan_file_dialog = %DirectoryScanFileDialog as FileDialog
@onready var folder_line_edit = %FolderLineEdit as LineEdit
@onready var select_multiple_paths_container = %SelectMultiplePathsContainer as HBoxContainer
@onready var option_button: OptionButton = select_multiple_paths_container.get_node("./OptionButton")
@onready var check_button: CheckButton = %CheckButton
@onready var path_pool_container: HBoxContainer = %PathPoolContainer
@onready var paths_item_list: ItemList = path_pool_container.get_node("./PathsItemList")
@onready var strings_pool_container: VBoxContainer = %StringsPoolContainer
@onready var strings_item_list: ItemList = %StringsItemList
@onready var strings_pool_line_edit: LineEdit = %StringsPoolLineEdit

func _ready() -> void:
	if id.is_empty():
		printerr("Setting id is empty")
		return
	
	check_button.visible = false
	select_path_container.visible = false
	select_multiple_paths_container.visible = false
	path_pool_container.visible = false
	strings_pool_container.visible = false
	
	if is_toggle:
		check_button.visible = true
		check_button.button_pressed = is_toggled
	elif is_select_path:
		select_path_container.visible = true
		folder_line_edit.text = path
	elif is_select_multiple_paths:
		select_multiple_paths_container.visible = true
		for path in multiple_paths:
			option_button.add_item(path)
	elif is_select_pool_path:
		path_pool_container.visible = true
		for path in multiple_paths:
			paths_item_list.add_item(path, icon)
	elif is_select_pool_path:
		strings_pool_container.visible = true
		for string in multiple_strings:
			strings_item_list.add_item(string, icon)
			
	else:
		printerr("Select a setting mode")
	
	title_label.text = title
	description_label.text = description
	tags_label.text = ", ".join(tags)
	tags_label.tooltip_text = ", ".join(tags)

func _on_select_folder_button_pressed() -> void:
	directory_scan_file_dialog.visible = true

func _on_directory_scan_file_dialog_dir_selected(dir: String) -> void:
	folder_line_edit.text = dir
	if id == SettingsConstants.KEY_EXCLUDED_PATHS:
		var prev_array = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS, id, [])
		if dir in prev_array: return
		prev_array.append(dir)
		SettingsManager.save_setting(
			SettingsConstants.SECTION_SETTINGS, id, prev_array)
		paths_item_list.clear()
		for path in prev_array:
			paths_item_list.add_item(path, icon)
		
			
	if id == "target_folder":
		SettingsManager.save_setting(
			SettingsConstants.SECTION_SETTINGS, id, dir)

func _on_check_button_toggled(toggled_on: bool) -> void:
	SettingsManager.save_setting("settings", id, toggled_on)

func _on_folder_line_edit_text_changed(dir: String) -> void:
	SettingsManager.save_setting(
		SettingsConstants.SECTION_SETTINGS, id, dir)

func _on_paths_item_list_item_activated(index: int) -> void:
	paths_item_list.remove_item(index)
	if id == "excluded_paths":
		var previous_settings = SettingsManager.get_setting(
			SettingsConstants.SECTION_SETTINGS, id, []
		)
		previous_settings.remove_at(index)
		SettingsManager.save_setting("settings", id, previous_settings)
