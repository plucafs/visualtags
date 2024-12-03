extends Node
class_name TagUtils

enum TAGS_STATE {
	NO_TAGS_AFTER_SEPARATOR = 0,
	MULTIPLE_SEPARATORS = 1,
	NO_SEPARATOR = 2
}

static func has_tags(file_name: String, return_state: bool = false):
	var file_name_has_tags_separator = file_name.contains("--")
	
	if not file_name_has_tags_separator:
		#print("Not found the separator (--) in ", file_name)
		if return_state:
			return TAGS_STATE.NO_SEPARATOR
		else: return false

	# ["file_name", "tags_list"]
	var file_name_splitted = file_name.split("--", false)
	
	var file_name_ext = file_name.get_extension()
	if file_name_splitted[1].strip_edges() == "" || \
	file_name_splitted.size() <= 1 || \
	file_name_splitted[1].strip_edges() == "." + file_name_ext:
		#print("Tag not found: not found the tags after the separator (--) in ", file_name)
		if return_state:
			return TAGS_STATE.NO_TAGS_AFTER_SEPARATOR
		else: return false
		
	if file_name_splitted.size() > 2:
		#print("Tag not found: found multiple separators (--) in ", file_name)
		if return_state:
			return TAGS_STATE.MULTIPLE_SEPARATORS
		else: return false
	
	return true

static func extract_tags(file_name: String) -> PackedStringArray:
	var tags: PackedStringArray = file_name.split("--")[1].split(" ")
	tags.remove_at(0)
	if tags.is_empty(): return []
	tags[-1] = tags[-1].split(".")[0]
	return tags

static func remove_extension(file_path: String) -> String:
	var dot_index = file_path.rfind(".")
	if dot_index > 0:
		return file_path.substr(0, dot_index)
	else:
		return file_path
