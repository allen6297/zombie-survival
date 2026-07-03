extends Resource
class_name BlockbenchModel

## Loads a Blockbench (.bbmodel) file and turns its box elements into a real
## Godot mesh + collision. Blockbench works in a 16-unit cube; we map that to a
## 1-unit block centred on X/Z with Y running 0..1 (recentred to -0.5..0.5), so
## the result drops straight into a unit-cell block.

const UNIT := 16.0

var source_path: String
## Each entry is { "min": Vector3, "max": Vector3 } in local block units.
var elements: Array = []


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
		var from = element.get("from")
		var to = element.get("to")
		if not (from is Array and to is Array and from.size() == 3 and to.size() == 3):
			continue
		var a := model._to_local(from)
		var b := model._to_local(to)
		model.elements.append({
			"min": Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z)),
			"max": Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z)),
		})

	return model


func is_empty() -> bool:
	return elements.is_empty()


func build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for element in elements:
		_add_box(st, element["min"], element["max"])
	return st.commit()


func build_collision() -> ConcavePolygonShape3D:
	return build_mesh().create_trimesh_shape()


func _to_local(v: Array) -> Vector3:
	return Vector3(float(v[0]) / UNIT, float(v[1]) / UNIT - 0.5, float(v[2]) / UNIT)


func _add_box(st: SurfaceTool, m: Vector3, x: Vector3) -> void:
	var p000 := Vector3(m.x, m.y, m.z)
	var p100 := Vector3(x.x, m.y, m.z)
	var p110 := Vector3(x.x, x.y, m.z)
	var p010 := Vector3(m.x, x.y, m.z)
	var p001 := Vector3(m.x, m.y, x.z)
	var p101 := Vector3(x.x, m.y, x.z)
	var p111 := Vector3(x.x, x.y, x.z)
	var p011 := Vector3(m.x, x.y, x.z)

	_add_face(st, p001, p101, p111, p011, Vector3(0, 0, 1))
	_add_face(st, p100, p000, p010, p110, Vector3(0, 0, -1))
	_add_face(st, p101, p100, p110, p111, Vector3(1, 0, 0))
	_add_face(st, p000, p001, p011, p010, Vector3(-1, 0, 0))
	_add_face(st, p010, p011, p111, p110, Vector3(0, 1, 0))
	_add_face(st, p000, p100, p101, p001, Vector3(0, -1, 0))


func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(b)
	st.set_normal(n)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)

	st.set_normal(n)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)
	st.set_normal(n)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(d)
