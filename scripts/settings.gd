extends Panel

func _on_toggle_tag_search_button_toggled(toggled_on: bool) -> void:
	toggle_tag_search(toggled_on)

func toggle_tag_search(toggled_on):
	var search_tag = get_node("../SearchTagLineEdit")
	search_tag.visible = toggled_on
	SettingsManager.save_setting("settings", "tag_search_button_visibility", toggled_on)

func _on_toggle_tag_history_button_toggled(toggled_on: bool) -> void:
	toggle_tag_history(toggled_on)

func toggle_tag_history(toggled_on):
	var tag_history = get_node("../../TagHistoryItemList")
	tag_history.visible = toggled_on
	SettingsManager.save_setting("settings", "tag_history_visibility", toggled_on)

func _on_reload_current_button_pressed() -> void:
	pass # Replace with function body.

func _on_setting_page_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_page.tscn")
