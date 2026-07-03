extends Resource
class_name BlockbenchModel

## Loads a Blockbench (.bbmodel) file and turns its geometry into a Godot mesh +
## collision. Handles both element kinds:
##   - cube elements (from/to box bounds)
##   - mesh elements (vertices + faces), e.g. after "Convert to Mesh"
## Blockbench works in a 16-unit cube; we map that to a 1-unit block centred on
## X/Z with Y recentred to -0.5..0.5, so it drops into a unit cell.

const UNIT := 16.0

var source_path: String
## Each face is a PackedVector3Array of 3-4 local-space vertices.
var faces: Array = []


static func load_from_file(path: String) -> BlockbenchModel:
	var model := BlockbenchModel.new()
	model.source_path = path

	if not FileAccess.file_exists(path):
		push_error("Blockbench model does not exist: %s" % path)
		return model

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to read Blockbench model: %s" % path)
		return model

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Blockbench model must contain an object: %s" % path)
		return model

	for element in parsed.get("elements", []):
		if not element is Dictionary:
			continue
		if element.get("type", "cube") == "mesh":
			model._parse_mesh(element)
		elif element.has("from") and element.has("to"):
			model._parse_cube(element["from"], element["to"])

	return model


func is_empty() -> bool:
	return faces.is_empty()


func face_count() -> int:
	return faces.size()


func build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		_add_polygon(st, face)
	return st.commit()


func build_collision() -> ConcavePolygonShape3D:
	return build_mesh().create_trimesh_shape()


func _to_local(v) -> Vector3:
	return Vector3(float(v[0]) / UNIT, float(v[1]) / UNIT - 0.5, float(v[2]) / UNIT)


func _parse_mesh(element: Dictionary) -> void:
	var vertices := {}
	var raw_vertices = element.get("vertices", {})
	if raw_vertices is Dictionary:
		for key in raw_vertices:
			var v = raw_vertices[key]
			if v is Array and v.size() == 3:
				vertices[key] = _to_local(v)

	var raw_faces = element.get("faces", {})
	if not raw_faces is Dictionary:
		return
	for key in raw_faces:
		var face = raw_faces[key]
		if not face is Dictionary:
			continue
		var poly := PackedVector3Array()
		for vk in face.get("vertices", []):
			if vertices.has(vk):
				poly.append(vertices[vk])
		if poly.size() >= 3:
			faces.append(poly)


func _parse_cube(from, to) -> void:
	if not (from is Array and to is Array and from.size() == 3 and to.size() == 3):
		return
	var a := _to_local(from)
	var b := _to_local(to)
	var m := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var x := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	# 6 quad faces
	faces.append(PackedVector3Array([Vector3(m.x, m.y, x.z), Vector3(x.x, m.y, x.z), Vector3(x.x, x.y, x.z), Vector3(m.x, x.y, x.z)]))  # +Z
	faces.append(PackedVector3Array([Vector3(x.x, m.y, m.z), Vector3(m.x, m.y, m.z), Vector3(m.x, x.y, m.z), Vector3(x.x, x.y, m.z)]))  # -Z
	faces.append(PackedVector3Array([Vector3(x.x, m.y, x.z), Vector3(x.x, m.y, m.z), Vector3(x.x, x.y, m.z), Vector3(x.x, x.y, x.z)]))  # +X
	faces.append(PackedVector3Array([Vector3(m.x, m.y, m.z), Vector3(m.x, m.y, x.z), Vector3(m.x, x.y, x.z), Vector3(m.x, x.y, m.z)]))  # -X
	faces.append(PackedVector3Array([Vector3(m.x, x.y, m.z), Vector3(m.x, x.y, x.z), Vector3(x.x, x.y, x.z), Vector3(x.x, x.y, m.z)]))  # +Y
	faces.append(PackedVector3Array([Vector3(m.x, m.y, m.z), Vector3(x.x, m.y, m.z), Vector3(x.x, m.y, x.z), Vector3(m.x, m.y, x.z)]))  # -Y


func _add_polygon(st: SurfaceTool, poly: PackedVector3Array) -> void:
	var normal := _face_normal(poly)
	# Fan-triangulate the (convex) polygon.
	for i in range(1, poly.size() - 1):
		for p in [poly[0], poly[i], poly[i + 1]]:
			st.set_normal(normal)
			st.set_uv(_planar_uv(p, normal))
			st.add_vertex(p)


func _face_normal(poly: PackedVector3Array) -> Vector3:
	var n := (poly[1] - poly[0]).cross(poly[2] - poly[0])
	return n.normalized() if n.length() > 0.0 else Vector3.UP


func _planar_uv(pos: Vector3, normal: Vector3) -> Vector2:
	var a := normal.abs()
	if a.y >= a.x and a.y >= a.z:
		return Vector2(pos.x, pos.z) + Vector2(0.5, 0.5)
	if a.x >= a.z:
		return Vector2(pos.z, pos.y) + Vector2(0.5, 0.5)
	return Vector2(pos.x, pos.y) + Vector2(0.5, 0.5)
