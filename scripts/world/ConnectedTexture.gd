extends RefCounted
class_name ConnectedTexture

## Connected-texture (CTM) lookup for a 12x4, 47-tile atlas.
##
## The mask->tile mapping is GENERATED from quadrant states, not hardcoded:
## every face is 4 quadrants, each quadrant is one of {outer, edge-a, edge-b,
## inner, full} decided by its 2 adjacent edges + diagonal (with the corner
## rule: a diagonal only counts if both its edges connect). Scanning all 256
## neighbour masks yields exactly 47 distinct quadrant signatures -> tiles 0..46.
##
## TILE_LAYOUT then maps each canonical tile index to a slot in the atlas image,
## derived from assets/textures/block/texture.png. Three cases (canonical 5, 32,
## 43) have no unique art in the current WIP atlas and fall back to the fully
## connected tile; replace those entries once the art exists.

const COLS := 12
const ROWS := 4

# canonical tile index -> linear atlas slot (row * COLS + col)
const TILE_LAYOUT: Array[int] = [
	0, 36, 1, 16, 37, 26, 12, 4, 6, 30, 13, 28, 25, 3, 17, 2,
	18, 40, 5, 19, 7, 46, 8, 31, 9, 23, 15, 43, 29, 10, 34, 14,
	26, 45, 39, 42, 38, 41, 20, 11, 35, 33, 27, 26, 32, 44, 26,
]

# 8-neighbour bit order.
const N := 1
const NE := 2
const E := 4
const SE := 8
const S := 16
const SW := 32
const W := 64
const NW := 128

static var _mask_to_tile: PackedInt32Array
static var _tile_count := 0


static func tile_index(mask: int) -> int:
	if _mask_to_tile.is_empty():
		_build()
	return _mask_to_tile[mask & 0xFF]


static func tile_count() -> int:
	if _mask_to_tile.is_empty():
		_build()
	return _tile_count


## UV rect for a canonical tile index, with a half-texel inset to stop bleeding.
static func tile_uv(index: int, atlas_px: Vector2 = Vector2(96, 32)) -> Rect2:
	var slot: int = TILE_LAYOUT[clampi(index, 0, TILE_LAYOUT.size() - 1)]
	var col := slot % COLS
	var row := slot / COLS
	var tile := Vector2(1.0 / COLS, 1.0 / ROWS)
	var inset := Vector2(0.5, 0.5) / atlas_px
	return Rect2(Vector2(col, row) * tile + inset, tile - inset * 2.0)


static func _quadrant(edge_a: bool, edge_b: bool, diagonal: bool) -> int:
	if not edge_a and not edge_b:
		return 0                       # outer corner
	if edge_a and not edge_b:
		return 1                       # edge along a
	if edge_b and not edge_a:
		return 2                       # edge along b
	return 4 if diagonal else 3        # full / inner corner


static func _signature(mask: int) -> int:
	var n := bool(mask & N)
	var e := bool(mask & E)
	var s := bool(mask & S)
	var w := bool(mask & W)
	# corner rule: a diagonal only counts if both its edges connect
	var ne := bool(mask & NE) and n and e
	var se := bool(mask & SE) and s and e
	var sw := bool(mask & SW) and s and w
	var nw := bool(mask & NW) and n and w
	var tl := _quadrant(n, w, nw)
	var tr := _quadrant(n, e, ne)
	var br := _quadrant(s, e, se)
	var bl := _quadrant(s, w, sw)
	return tl | (tr << 3) | (br << 6) | (bl << 9)


static func _build() -> void:
	_mask_to_tile.resize(256)
	var signature_to_index := {}
	for mask in range(256):
		var signature := _signature(mask)
		if not signature_to_index.has(signature):
			signature_to_index[signature] = signature_to_index.size()
		_mask_to_tile[mask] = signature_to_index[signature]
	_tile_count = signature_to_index.size()
