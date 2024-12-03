extends ItemList

@onready var edit_box: MarginContainer = %EditBox

func _input(event: InputEvent) -> void:
	if not has_focus(): return
	if is_anything_selected():
		edit_box.hide()
		return
	select(0)
	emit_signal("item_selected", 0)
