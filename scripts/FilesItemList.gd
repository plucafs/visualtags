extends ItemList

func _on_focus_entered() -> void:
	if item_count == 0: return
	select(0) # Or when it grabs focus it doesn't highlight the item
	ensure_current_is_visible()
	emit_signal("item_selected", 0)
