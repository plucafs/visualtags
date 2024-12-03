extends TextureButton

@onready var tag_buttons_container: HFlowContainer = %TagButtonsContainer

signal _on_reset_toggles_button_pressed

func _on_pressed() -> void:
	reset_toggled_buttons()
	#emit_signal("_on_reset_toggles_button_pressed")

func reset_toggled_buttons():
	for button in tag_buttons_container.get_children():
		button.button_pressed = false
