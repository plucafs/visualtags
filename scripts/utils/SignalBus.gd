extends Node

# Thanks to
# https://stackoverflow.com/questions/68675099/godot-listening-to-signals-from-multiple-instances-of-the-same-scene
signal scan_requested
signal count_requested

signal status_change_requested

signal open_directory_requested

signal delete_tag_requested
signal delete_directory_requested
signal forget_directory_requested
signal delete_file_requested

signal active_file_name_selected
signal active_tags_selected
signal active_directory_selected

signal global_tags_list_built
