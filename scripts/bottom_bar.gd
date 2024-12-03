extends HBoxContainer

@onready var directory_scan_file_dialog: FileDialog = get_node("../%DirectoryScanFileDialog")
@onready var directory_line_edit: LineEdit = %DirectoryLineEdit
@onready var recent_dirs_option: OptionButton = %RecentDirsOption

var scanner = Scanner.new()

func _ready() -> void:
	directory_line_edit.connect("text_submitted", _on_text_submitted)

# todo
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select_dir_select"):
		directory_line_edit.grab_focus()
		accept_event()

func _on_select_directory_button_pressed() -> void:
	print("_on_select_directory_button_pressed")
	var last_dir_selected = SettingsManager.get_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_LAST_DIR_SELECTED,
		""
	)
	if last_dir_selected:
		directory_scan_file_dialog.current_dir = last_dir_selected
	directory_scan_file_dialog.visible = true

func _on_text_submitted(dir: String):
	if dir.strip_edges().is_empty(): return
	SignalBus.emit_signal("scan_requested", dir)

func _on_history_directories_button_pressed() -> void:
	pass
