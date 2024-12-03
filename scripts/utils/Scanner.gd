class_name Scanner
extends Node

# Hidden directories and files are excluded via the property `include_hidden` set
# to the `DirAccess` object
var excluded_dirs = [
	"/[...]",
	"/Heroic",
	"/node_modules",
	"/installer_files",
	"/dist",
	"/build",
	"/target",
]
var counter_searched_files = 0
var depth_counter = 0
var total = 0

func start(path: String, depth: int) -> Array:
	if path.is_empty(): return []
	var home_path = Utils.get_home_dir_path()
	if home_path.is_empty(): return []
	
	counter_searched_files = 0

	var file_list = []
	var tag_list = []
	get_files(path, depth, file_list, tag_list)
	
	# Print all file name
	for metadata in file_list:
		print("	", metadata.file_name)
	
	# Print all tags
	for tag_name in tag_list:
		print("	", tag_name)
	
	tag_list.sort()
	file_list.sort_custom(func(a, b): return a.file_name.naturalnocasecmp_to(b.file_name) < 0)
	
	return [file_list, tag_list]

func get_files(directory: String, depth: int, file_list: Array, tag_list: Array) -> void:
	var dir = DirAccess.open(directory)
	if not dir:
		print(error_string(DirAccess.get_open_error()))
		return
		
	dir.include_hidden = false
	dir.include_navigational = false
	dir.list_dir_begin()
	
	var skip = false
	while true:
		skip = false
		var file_name = dir.get_next()
		print_debug("Elaborating file/dir %s" % file_name)
		if file_name.strip_edges().is_empty(): break
		if dir.current_is_dir():
			var current_dir = dir.get_current_dir()
			print_debug("Current dir: ", current_dir)
			for excluded_dir in excluded_dirs:
				if excluded_dir in current_dir:
					print_debug("	Skipping %s because contains %s" % [current_dir, excluded_dir])
					skip = true
					break

			if skip: continue
			if depth > 0:
				if depth_counter == depth:
					depth_counter = 0
					continue
				depth_counter += 1
			var slash = "" if file_name.begins_with("/") || directory.ends_with("/") else "/"
			var new_directory = directory + slash + file_name
			get_files(new_directory, depth, file_list, tag_list)
		else:
			counter_searched_files += 1
			var slash = "" if file_name.begins_with("/") || directory.ends_with("/") else "/"
			var file_directory = directory + slash + file_name
			var metadata := {
				"file_name": file_name,
				"file_directory": file_directory,
				"is_tagged": false,
			}
			var tags_state = TagUtils.has_tags(file_name, true)
			match tags_state:
				TagUtils.TAGS_STATE.NO_TAGS_AFTER_SEPARATOR, \
				TagUtils.TAGS_STATE.MULTIPLE_SEPARATORS, \
				TagUtils.TAGS_STATE.NO_SEPARATOR:
					metadata["is_tagged"] = false
					file_list.append(metadata)
					continue

			var file_tags_list = TagUtils.extract_tags(file_name) 
			for tag in file_tags_list:
				tag_list.append(tag)
				
			metadata["is_tagged"] = true
			file_list.append(metadata)
	dir.list_dir_end()

func get_number_of_files_to_analyze(depth: int, directory: String, is_recursive := false) -> int:
	if not is_recursive: total = 0
	
	var dir = DirAccess.open(directory)
	if not dir:
		print(error_string(DirAccess.get_open_error()))
		return 0
		
	dir.include_hidden = false
	dir.include_navigational = false
	dir.list_dir_begin()
	
	while true:
		var file_name = dir.get_next()
		if file_name.strip_edges().is_empty(): break
		if dir.current_is_dir():
			for excluded_dir in excluded_dirs:
				if excluded_dir in dir.get_current_dir():
					continue
			if depth > 0:
				if depth_counter == depth:
					depth_counter = 0
					continue
				depth_counter += 1
			var slash = "" if file_name.begins_with("/") || directory.ends_with("/") else "/"
			var new_directory = directory + slash + file_name
			get_number_of_files_to_analyze(depth, new_directory, true)
		else:
			total += 1
			
	dir.list_dir_end()
	return total
