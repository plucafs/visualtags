extends TextureButton

func _ready() -> void:
	connect("pressed", _on_pressed)
	
func _on_pressed():
	OS.shell_open("https://github.com/plucafs/visualtags")
