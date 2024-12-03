extends LineEdit

func _ready() -> void:
	SignalBus.connect("active_directory_selected", _on_active_directory_selected)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select_dir_bar"):
		grab_focus()
		select()

func _on_active_directory_selected(dir := ""):
	if not typeof(dir) == TYPE_STRING: 
		printerr("dir is not a string")
		
	dir = dir.strip_edges()
	text = dir
