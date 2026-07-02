extends Resource
class_name AbstractRegistry

# Lazily built id -> entry lookup so get_entry()/has_entry() are O(1) instead of
# scanning the backing array on every call. The array returned by _get_entries()
# remains the source of truth; the index is (re)built from it on first use.
var _index: Dictionary = {}
var _index_built := false


func get_entry(id: StringName) -> Resource:
	if not _index_built:
		_build_index()
	return _index.get(id, null)


func has_entry(id: StringName) -> bool:
	if not _index_built:
		_build_index()
	return _index.has(id)


func add_entry(entry: Resource) -> void:
	if entry == null:
		return

	var id: StringName = entry.get(&"id")
	if id == &"":
		push_warning("Registry entry is missing an id.")
		return

	if not _index_built:
		_build_index()

	var entries := _get_entries()
	var existing = _index.get(id, null)
	if existing != null:
		entries[entries.find(existing)] = entry
	else:
		entries.append(entry)
	_index[id] = entry


func _build_index() -> void:
	_index.clear()
	for entry in _get_entries():
		if entry != null:
			_index[entry.get(&"id")] = entry
	_index_built = true


func _get_entries() -> Array:
	push_error("%s must override _get_entries()." % get_script().resource_path)
	return []
