extends Control

@onready var icon_tag = preload("res://icons/tag.svg")
@onready var icon_star = preload("res://icons/star.svg")

@onready var node_tags_item_list: ItemList = %TagItemList
@onready var node_tags_history_item_list: ItemList = %TagHistoryItemList
@onready var node_files_item_list: ItemList = %FilesItemList
@onready var edit_container: Control = %EditBox
@onready var tags_search_bar: HBoxContainer = %TagsSearchBar
@onready var search_tag_line_edit: LineEdit = tags_search_bar.get_node("%SearchTagLineEdit")
@onready var top_bar: HBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer/TopBar
@onready var bottom_bar: HBoxContainer = %BottomBar
@onready var directory_line_edit: LineEdit = bottom_bar.get_node("%DirectoryLineEdit")
@onready var recent_dirs_option: OptionButton = bottom_bar.get_node("%RecentDirsOption")
@onready var directory_scan_file_dialog: FileDialog = %DirectoryScanFileDialog
@onready var confirmation_dialog: ConfirmationDialog = %ConfirmationDialog
@onready var status_bar: HBoxContainer = get_node("%StatusBar")
@onready var status_label: Label = status_bar.get_node("%StatusLabel")

const ALL_FILES := "All files (not tagged)"

var files_item_list_names: PackedStringArray
var file_list_start: Array
var tag_list_start: Array
var last_tag_history := ""
var target_dir: String
var scanner := Scanner.new()

func _ready() -> void:
	SignalBus.connect("scan_requested", _on_scan_requested)
	SignalBus.connect("count_requested", _on_count_requested)
	SignalBus.connect("status_change_requested", _on_status_change_requested)
	SignalBus.connect("delete_directory_requested", _on_delete_directory_requested)
	SignalBus.connect("delete_tag_requested", _on_delete_tag_requested)
	SignalBus.connect("delete_file_requested", _on_delete_file_requested)
	SignalBus.connect("open_directory_requested", _open_directory_requested)
	search_tag_line_edit.connect("text_changed", _on_search_tag_line_edit_text_changed)
	directory_line_edit.grab_focus()
	edit_container.visible = false
	add_all_files_tag_to_tags_list()
	set_recent_dirs()
	
	target_dir = SettingsManager.get_setting(
		SettingsConstants.SECTION_SETTINGS,
		SettingsConstants.KEY_TARGET_FOLDER,
		""
	)
	if target_dir:
		directory_line_edit.text = target_dir
	else:
		var last_dirs = SettingsManager.get_setting(
			SettingsConstants.SECTION_UI,
			SettingsConstants.KEY_LAST_DIR_SELECTED,
			[]
		)
		if last_dirs.size() > 0:
			target_dir = last_dirs[0]
		
	#SETT: scan default dir at startup
	#index(target_dir)

func _open_directory_requested(dir := ""):
	dir = dir.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir): return
	OS.shell_open(dir)

func _on_scan_requested(dir := ""):
	if dir.is_empty(): return
	if not DirAccess.dir_exists_absolute(dir):
		printerr("dir %s doesn't exists" % dir)
		SignalBus.emit_signal("forget_directory_requested", dir)
		return
	#TODO: sometimes it doesn't render until is resized 
	#node_tags_item_list.reset_size()
	directory_line_edit.text = dir
	directory_line_edit.grab_focus()
	target_dir = dir
	SettingsManager.save_setting(
		SettingsConstants.SECTION_SETTINGS,
		"last_dir_selected",
		dir
	)
	reset()
	index(dir)
	save_recent_dirs(dir)
	set_recent_dirs()
	node_tags_item_list.grab_focus()
	node_tags_item_list.select(0)

func _on_count_requested(path := ""):
	path = directory_line_edit.text.strip_edges()
	if path.is_empty(): return

	SignalBus.status_change_requested.emit("Counting files...")
	await get_tree().process_frame
	await get_tree().process_frame
	var total = scanner.get_number_of_files_to_analyze(-1, path)
	SignalBus.status_change_requested.emit("Found %s files" % str(total))

func _on_delete_directory_requested(dir := ""):
	dir = directory_line_edit.text.strip_edges()
	print_debug("_on_delete_button_pressed :: WARNING\nremoving folder %s" % [dir])
	var err = DirAccess.remove_absolute(dir)
	if err:
		print_debug("_on_delete_button_pressed :: WARNING\ndelete of folder %s failed" % dir)

func _on_delete_tag_requested(id := ""):
	pass
	
func _on_delete_file_requested(path_file := ""):
	var file_exists := FileAccess.file_exists(path_file)
	if not file_exists: return
	confirmation_dialog.dialog_text = path_file + "\nwill be removed. Are you sure?"
	confirmation_dialog.popup_centered()
	confirmation_dialog.show()
		
func _on_delete_file_requested_confirmed(path_file := ""):
	var err := DirAccess.remove_absolute(path_file)
	if err:
		print(error_string(err))

func check(tag):
	tag = tag.to_lower().strip_edges()
	if tag.is_empty(): return ""
	return tag

func tags_list_from_string(tags_list_string: String) -> PackedStringArray:
	tags_list_string = tags_list_string.to_lower().strip_edges()
	if tags_list_string.is_empty(): return []
	
	tags_list_string = TagUtils.remove_extension(tags_list_string)
	var tags_list_unprocessed = Array(tags_list_string.split(" "))
	var tags_list: PackedStringArray = tags_list_unprocessed \
		.filter(func(tag): return not tag.to_lower() \
			.strip_edges()\
			.is_empty() || tag.strip_edges().begins_with(".")
		)\
		.map(check)
	return tags_list

# Adds an Item node to the ItemList node starting
# based on the selected tag
func add_files_to_files_list(index: int):
	for file_data in file_list_start:
		var tag = node_tags_item_list.get_item_text(index).to_lower().strip_edges()
		var file_name = file_data.file_name
		if not file_name.contains("--"): continue
		
		var tags_list_string = file_name.split("--")[1] 
		var tags_list = tags_list_from_string(tags_list_string)
		
		if tags_list.size() < 1:
			continue
		elif tag in tags_list:
			var new_index = node_files_item_list.add_item(file_data.file_name)
			node_files_item_list.set_item_metadata(new_index, file_data.file_directory)
			node_files_item_list.set_item_tooltip_enabled(new_index, false)
	return

const MAX_TAG_HISTORY_ITEM = 50;
func add_tag_to_tags_history_list(index):
	var item_count = node_tags_history_item_list.item_count
	var current_tag = node_tags_item_list.get_item_text(index)
		
	if item_count > 0:
		if last_tag_history == current_tag:
			return
		
		last_tag_history = current_tag
		var index_added_item = node_tags_history_item_list.add_item(current_tag)
		node_tags_history_item_list.select(index_added_item)
		node_tags_history_item_list.ensure_current_is_visible()
	else:
		last_tag_history = current_tag
		var index_added_item = node_tags_history_item_list.add_item(current_tag)
		node_tags_history_item_list.select(index_added_item)
		node_tags_history_item_list.ensure_current_is_visible()

	if item_count > MAX_TAG_HISTORY_ITEM:
		print("MAX_TAG_HISTORY_ITEM reached")

func index(path: String = ""):
	if path.strip_edges().is_empty():
		path = target_dir

	if not DirAccess.dir_exists_absolute(path):
		printerr("path %s doesn't exists" % path)
		return

	reset()
	_on_status_change_requested("Scanning files...")
	# Wait some frames to view the ui update
	await get_tree().process_frame
	await get_tree().process_frame
	
	var lists = scanner.start(path, -1)
	if lists.is_empty():
		return
	
	var file_list = lists[0]
	var tag_list = lists[1]
	SignalBus.global_tags_list_built.emit(tag_list)
	
	for file_data in file_list:
		file_list_start.append(file_data)
		if file_data.is_tagged: continue
		var i = node_files_item_list.add_item(file_data.file_name)
		node_files_item_list.set_item_metadata(i, file_data.file_directory)
		node_files_item_list.set_item_tooltip_enabled(i, false)
	
	for tag in tag_list:
		if not tag in tag_list_start:
			tag_list_start.append(tag)
			#var i = node_tags_item_list.add_item(tag, icon_tag)
			# Test without tag icon
			var i = node_tags_item_list.add_item(tag)
			node_tags_item_list.set_item_tooltip_enabled(i, false)
	
	tag_list_start = ArrayUtils.array_unique(tag_list_start)
	_on_status_change_requested("Scan complete")

func get_files_name_from_files_list() -> PackedStringArray:
	var array_strings := [] 
	for i in range(0, node_files_item_list.item_count):
		var file_item_name = node_files_item_list.get_item_text(i)
		if file_item_name.is_empty(): continue
		array_strings.append(file_item_name)
	return array_strings

func add_all_files_tag_to_tags_list(select := false):
	var i = node_tags_item_list.add_item(ALL_FILES)
	node_tags_item_list.set_item_tooltip_enabled(i, false)
	if select: node_tags_item_list.select(0)
	
func reset():
	file_list_start = []
	tag_list_start = []
	
	node_files_item_list.clear()
	node_tags_item_list.clear()
	node_tags_history_item_list.clear()
	
	add_all_files_tag_to_tags_list()

func _on_status_change_requested(text: String):
	text = text.strip_edges()
	if text.is_empty(): return
	status_label.set_text(text)

func _on_tag_item_list_multi_selected(i: int, _selected: bool) -> void:
	print("MULTI SELECT TRIGGERED")
	add_tag_to_tags_history_list(i)
	# all tags
	if i == 0:
		node_files_item_list.clear()
		for metadata in file_list_start:
			if metadata.file_name.contains("--"): continue
			var new_index = node_files_item_list.add_item(metadata.file_name)
			node_files_item_list.set_item_metadata(new_index, metadata.file_directory)
			node_files_item_list.set_item_tooltip_enabled(i, false)
		return
	
	node_files_item_list.clear()
	var selected_items = node_tags_item_list.get_selected_items()
	# handle only one item for now
	if selected_items.size() != 1: return
	add_files_to_files_list(i)
		
func _on_directory_scan_file_dialog_dir_selected(dir: String) -> void:
	directory_line_edit.text = dir
	directory_line_edit.grab_focus()
	target_dir = dir

# Double clicked or enter pressed
func _on_files_item_list_item_activated(i: int) -> void:
	print("\nItemList: files\n	item activated")
	var dir = node_files_item_list.get_item_metadata(i)
	if not dir: return
	if not FileAccess.file_exists(dir):
		printerr()
		print_debug()
		return
	OS.shell_open(dir)

# On name or tags rename
func _on_edit_rename_completed() -> void:
	var dir = directory_line_edit.text
	index(dir)
	node_tags_item_list.grab_focus()
	edit_container.visible = false

func _on_scan_directory_button_pressed() -> void:
	var dir = directory_line_edit.text
	if dir.strip_edges().is_empty(): return
	index(dir)

func _on_tag_item_list_item_activated(index: int) -> void:
	print("Tag activated")
	# Disable starred tags
	return

	# Return if its the "All files" item
	if index == 0: return
	
	var item_name = node_tags_item_list.get_item_text(index)
	node_tags_item_list.remove_item(index)
	var new_index = node_tags_item_list.add_item(item_name, icon_star)
	node_tags_item_list.set_item_tooltip_enabled(new_index, false)
	node_tags_item_list.move_item(new_index, 1)
	node_tags_item_list.select(new_index)
	var favorite_tags = SettingsManager.get_setting(
		SettingsConstants.SECTION_SETTINGS,
		SettingsConstants.KEY_FAVORITE_TAGS,
		[]
	)
	favorite_tags.append(item_name)
	SettingsManager.save_setting(
		SettingsConstants.SECTION_SETTINGS,
		SettingsConstants.KEY_FAVORITE_TAGS,
		favorite_tags
	)

func _on_tag_history_item_list_item_selected(index: int) -> void:
	const is_from_tag_history_item_list = true
	_on_tag_item_list_item_selected(index)

func _on_tag_item_list_item_selected(index: int) -> void:
	print("TagItemsList: item selected", index)
	add_tag_to_tags_history_list(index)
	edit_container.reset()
	# If it's the first "All files" element
	if index == 0:
		node_files_item_list.clear()
		for metadata in file_list_start:
			# TODO add option
			var tags_state = TagUtils.has_tags(metadata.file_name, true)
			match tags_state:
				TagUtils.TAGS_STATE.NO_TAGS_AFTER_SEPARATOR, \
				TagUtils.TAGS_STATE.MULTIPLE_SEPARATORS, \
				TagUtils.TAGS_STATE.NO_SEPARATOR:
					pass
				_: continue
			#if metadata.file_name.contains("--"): continue
			var new_index = node_files_item_list.add_item(metadata.file_name)
			node_files_item_list.set_item_metadata(new_index, metadata.file_directory)
			node_files_item_list.set_item_tooltip_enabled(index, false)
		return
	node_files_item_list.clear()
	var selected_items = node_tags_item_list.get_selected_items()
	# handle only one item for now
	if selected_items.size() != 1: return
	add_files_to_files_list(index)

func _on_files_item_list_item_selected(index: int) -> void:
	print("\nItemList: files\n	item selected")
	on_file_item_selected(index)

func _on_search_tag_line_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		node_tags_item_list.clear()
		add_all_files_tag_to_tags_list(true)
		for item in tag_list_start: 
			node_tags_item_list.add_item(item)
		return
		
	node_tags_item_list.clear()
	add_all_files_tag_to_tags_list()
	for item in tag_list_start:
		if item.to_lower().contains(new_text.to_lower()):
			node_tags_item_list.add_item(item)

# Clicked by any mouse button
func _on_files_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	print("\nItemList: files\n clicked or scrolled", )
	if mouse_button_index == MOUSE_BUTTON_WHEEL_DOWN or \
		mouse_button_index == MOUSE_BUTTON_WHEEL_UP:
			return
	on_file_item_selected(index)
	node_files_item_list.ensure_current_is_visible()

func _on_directory_line_edit_text_submitted(path: String) -> void:
	reset()
	index(path)

#func _on_tag_history_item_list_item_selected(index: int) -> void:
	# #bug Index mismatch
	# Add to the tag metadata the actual index
	#_on_tag_item_list_item_selected(index)

func on_file_item_selected(i: int):
	print("	START on_file_item_selected")
	
	if not typeof(i) == TYPE_INT: return
	print("	Index %s" % index)
	
	var file_name = node_files_item_list.get_item_text(i)
	var metadata = node_files_item_list.get_item_metadata(i)
	print("	Selected file name and metadata\n		%s\n		%s" % [file_name, metadata])
	
	var tags = []
	if TagUtils.has_tags(file_name):
		tags = TagUtils.extract_tags(file_name)
	print("	Found tags\n		%s" % " ".join(tags))
		
	if tags.size() > 0: file_name = file_name.split("--")[0]
	print("	Final file name\n		%s" % file_name)
	
	SignalBus.active_file_name_selected.emit(file_name)
	SignalBus.active_tags_selected.emit(tags)
	SignalBus.active_directory_selected.emit(metadata)

func save_recent_dirs(dir: String):
	if dir.is_empty(): return
	const MAX_HISTORY_SIZE = 10
	var recent_dirs: Array = SettingsManager.get_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_RECENT_DIRS,
		[]
	)
	if recent_dirs.has(dir):
		recent_dirs.erase(dir)

	var recent_dir_size = recent_dirs.size();
	if recent_dir_size == MAX_HISTORY_SIZE:
		recent_dirs.resize(MAX_HISTORY_SIZE - 1)
	
	if recent_dir_size > MAX_HISTORY_SIZE:
		recent_dirs.resize(9)
	
	recent_dirs.push_front(dir)

	SettingsManager.save_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_RECENT_DIRS,
		recent_dirs
	)

func set_recent_dirs():
	recent_dirs_option.clear()
	var recent_dirs = SettingsManager.get_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_RECENT_DIRS,
		[]
	)
	var i = 0
	for dir in recent_dirs:
		recent_dirs_option.add_item(dir, ++i)

func _on_confirmation_dialog_confirmed() -> void:
	_on_delete_file_requested_confirmed()
