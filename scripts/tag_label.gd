extends PanelContainer

func _on_delete_tag_button_pressed() -> void:
	SignalBus.emit_signal("delete_tag_requested", get_node("%Label").text)
