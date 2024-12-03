extends ItemList

func _on_tags_views_split_container_dragged(offset: int) -> void:
	ensure_current_is_visible()
	
