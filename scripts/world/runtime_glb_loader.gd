extends RefCounted

static func load_scene(base64_path: String) -> Node3D:
	if not FileAccess.file_exists(base64_path):
		push_warning("GLB payload missing: " + base64_path)
		return null
	var encoded: String = FileAccess.get_file_as_string(base64_path).strip_edges()
	if encoded.is_empty():
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		push_warning("GLB payload could not be decoded: " + base64_path)
		return null
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var error: Error = gltf.append_from_buffer(bytes, "", state)
	if error != OK:
		push_warning("GLB parse failed (%s): %s" % [error, base64_path])
		return null
	return gltf.generate_scene(state)
