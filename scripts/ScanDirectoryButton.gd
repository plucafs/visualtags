extends TextureButton

@onready var directory_line_edit: LineEdit = %DirectoryLineEdit

func _ready() -> void:
	connect("pressed", _on_pressed)

func _on_pressed() -> void:
	SignalBus.scan_requested.emit(directory_line_edit.text)
