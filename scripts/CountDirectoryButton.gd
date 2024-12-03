extends TextureButton

func _ready() -> void:
	connect("pressed", _on_pressed)

func _on_pressed():
	SignalBus.count_requested.emit()
