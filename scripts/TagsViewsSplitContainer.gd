extends VSplitContainer

func _on_dragged(offset: int) -> void:
	SettingsManager.save_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_TAG_ITEM_HISTORY_OFFSET,
		offset
	)

func _ready() -> void:
	var _offset = SettingsManager.get_setting(
		SettingsConstants.SECTION_UI,
		SettingsConstants.KEY_TAG_ITEM_HISTORY_OFFSET,
		0
	)
	split_offset = _offset
