extends LineEdit

func _ready() -> void:
	select_all_on_focus = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("focus_search_tag_bar"):
		grab_focus()
