extends HBoxContainer

@onready var directory_line_edit: LineEdit = %ActiveDirectoryLineEdit

func _on_open_dir_button_pressed() -> void:
	var dir = directory_line_edit.text
	if dir.strip_edges().is_empty(): return
	SignalBus.emit_signal("open_directory_requested", dir)
