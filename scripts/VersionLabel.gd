extends Label

const VERSION_CONFIG_PATH = "application/config/version"

func _ready() -> void:
	var version = ProjectSettings.get_setting(VERSION_CONFIG_PATH)
	self.text = "Version " + version
