extends Node

func get_home_dir_path() -> String:
	match OS.get_name():
		"Windows":
			var cache_dir := OS.get_cache_dir()
			if cache_dir.is_empty(): return ""
			var home_dir := cache_dir.split("/")
			home_dir.resize(home_dir.size() - 1) # /local
			home_dir.resize(home_dir.size() - 1) # /appdata
			print("Found home dir at path: ", "/".join(home_dir))
			return  "/".join(home_dir)
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			var output := []
			OS.execute("xdg-user-dir", [], output)
			if output.is_empty(): return ""
			print("Found home dir at path: ", output[0])
			return output[0].left(output[0].length() - 1) # strips the new line
		_:
			return ""
