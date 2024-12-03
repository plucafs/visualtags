extends Node

var path = ProjectSettings.globalize_path("user://visualtags.cfg")

var SETTINGS_LIST := [
	{
		"id": SettingsConstants.KEY_TAG_SEARCH_BUTTON_VISIBILITY,
		"type": "toggle",
		"title": "Toggle tag search",
		"description": "Toggle the tag search box on top of the tags list",
		"tags": ["tag", "search", "box", "ui"]
	},
	{
		"id": SettingsConstants.KEY_TAG_HISTORY_VISIBILITY,
		"type": "toggle",
		"title": "Toggle tag history",
		"description": "Toggle the tag history box showing the last selected tags",
		"tags": ["tags", "search", "box", "ui"]
	},
	{
		"id": SettingsConstants.KEY_TARGET_FOLDER,
		"type": "select_path",
		"title": "Select target scan",
		"description": "Select the path that will be scanned when the application starts",
		"tags": ["path", "directories", "search", "scan"]
	},
	{
		"id": SettingsConstants.KEY_EXCLUDED_PATHS	,
		"type": "pool_paths",
		"title": "Select excluded paths",
		"description": "Select the paths that will be skipped during the scan",
		"tags": ["path", "directories", "search", "scan", "exclude"]
	},
	{
		"id": SettingsConstants.KEY_EXCLUDED_FILES_AND_FOLDERS, # and folders
		"type": "pool_paths",
		"title": "Select excluded files",
		"description": "Select the files or directories that will be skipped during the scan",
		"tags": ["path", "directories", "search", "scan", "include"]
	},
	{
		"id": SettingsConstants.KEY_THEME,
		"type": "select_theme",
		"title": "Select a theme",
		"description": "Select and apply the color theme",
		"tags": ["theme", "dark", "light", "ui"]
	},
		{
		"id": SettingsConstants.KEY_FAVORITE_TAGS,
		"type": "pool_names",
		"title": "Select the preferred tags",
		"description": "Select the tags to pin at the top of the tags list",
		"tags": ["tags", "lists", "favorites"]
	},
]

func get_setting(section: String, key: String, default):
	var config = load_config()
	var value = config.get_value(section, key, default)
	return value

func save_setting(section, key, value):
	var config = load_config()
	print("Saving\n	%s\n	%s\n	%s" % [section, key, value])
	config.set_value(section, key, value)
	config.save(path)

func load_config() -> ConfigFile:
	var config = ConfigFile.new()
	var err = config.load(path)
	if err != OK:
		return create_config()
	return config

func create_config() -> ConfigFile:
	var config = ConfigFile.new()
	config.save(path)
	return config

#func get_default_value_from_key(key):
	#for setting_dict in SETTINGS_LIST:
		#if not setting_dict.has(key): continue
		#match key:
			#["select_theme", "excluded_files"]:
				#return ""
			#"tag_search_button_visibility"
			#_:
				#pass
