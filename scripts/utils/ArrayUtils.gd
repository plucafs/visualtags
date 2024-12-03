extends Node
class_name ArrayUtils

# Thanks to
# https://forum.godotengine.org/t/checking-if-an-array-contains-all-elements-in-another-array/4045/2
static func arrays_contains_array(array1, array2):
	for item in array2:
		if not array1.has(item):
			return false
		if array2.count(item) != array1.count(item):
			return false
	return true

static func array_unique(array: Array) -> Array:
	var array_unique := []
	for item in array:
		
		if not array_unique.has(item):
			array_unique.append(item)
	return array_unique
