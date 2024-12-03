extends OptionButton

func _ready() -> void:
	SignalBus.connect("forget_directory_requested", _on_forget_directory_requested)
	connect("item_selected", _on_item_selected)

func _on_item_selected(index):
	var dir = get_item_text(index)
	SignalBus.emit_signal("scan_requested", dir)
	#TODO: long directories expands too much the tags list column
	text = dir
	
func _on_forget_directory_requested(dir):
	var recent_dirs = SettingsManager.get_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_RECENT_DIRS,
		[]
	)
	recent_dirs.erase(dir)
	SettingsManager.save_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_RECENT_DIRS,
		recent_dirs
	)
	
