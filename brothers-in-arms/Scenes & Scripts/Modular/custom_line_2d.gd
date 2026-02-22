@tool
extends Line2D
class_name RopeLine2D

# -------------------
# Exported Textures
# -------------------
@export_group("Rope Sprites")

@export var cap_start: Texture2D:
	set(value):
		cap_start = value
		_rebuild_tiles()

@export var mid: Texture2D:
	set(value):
		mid = value
		_rebuild_tiles()

@export var cap_end_1: Texture2D:
	set(value):
		cap_end_1 = value
		_rebuild_tiles()

@export var cap_end_2: Texture2D:
	set(value):
		cap_end_2 = value
		_rebuild_tiles()

# -------------------
# Tiling
# -------------------
@export_group("Tiling")
@export var mid_tile_px: float = 16.0:
	set(value):
		mid_tile_px = maxf(value, 1.0)
		_rebuild_tiles()

@export var pixel_snap: bool = true:
	set(value):
		pixel_snap = value
		_update_tiles_transform()

@export var seam_offset_px: float = 0.0:
	set(value):
		seam_offset_px = value
		_update_tiles_transform()

# -------------------
# Visual
# -------------------
@export_group("Visual")
@export var rotate_to_rope: bool = true:
	set(value):
		rotate_to_rope = value
		_update_tiles_transform()

@export var tile_scale: Vector2 = Vector2.ONE:
	set(value):
		tile_scale = value
		_update_tiles_scale()

@export var tiles_z_index: int = 0:
	set(value):
		tiles_z_index = value
		_update_tiles_z()

# -------------------
# Runtime
# -------------------
var _tiles_root: Node2D
var _tile_sprites: Array[Sprite2D] = []

func _ready() -> void:
	# We use Line2D only for endpoints; sprites handle visuals.
	texture = null
	width = 0.0

	if _tiles_root == null or not is_instance_valid(_tiles_root):
		_tiles_root = Node2D.new()
		_tiles_root.name = "Tiles"
		add_child(_tiles_root)

	_rebuild_tiles()

func _process(_delta: float) -> void:
	if points.size() < 2:
		return
	_update_tiles_transform()

# -------------------
# Build / Update
# -------------------
func _rebuild_tiles() -> void:
	if _tiles_root == null or not is_instance_valid(_tiles_root):
		return

	# Clear old sprites
	for s: Sprite2D in _tile_sprites:
		if is_instance_valid(s):
			s.queue_free()
	_tile_sprites.clear()

	# Need all textures
	if cap_start == null or mid == null or cap_end_1 == null or cap_end_2 == null:
		return

	# Minimum set: cap_start + mid + cap_end_1 + cap_end_2
	_make_sprite(cap_start)
	_make_sprite(mid)
	_make_sprite(cap_end_1)
	_make_sprite(cap_end_2)

	_update_tiles_scale()
	_update_tiles_z()
	_update_tiles_transform()

func _make_sprite(tex: Texture2D) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.scale = tile_scale
	s.z_index = tiles_z_index
	_tiles_root.add_child(s)
	_tile_sprites.append(s)

func _update_tiles_scale() -> void:
	for s: Sprite2D in _tile_sprites:
		if is_instance_valid(s):
			s.scale = tile_scale

func _update_tiles_z() -> void:
	for s: Sprite2D in _tile_sprites:
		if is_instance_valid(s):
			s.z_index = tiles_z_index

func _ensure_mid_count(target_mid_count: int) -> void:
	# Layout:
	# [0] cap_start
	# [1 .. mid_count] mid tiles
	# [last-1] cap_end_1
	# [last] cap_end_2

	# Current mid count:
	var current_mid_count: int = max(_tile_sprites.size() - 3, 1)

	while current_mid_count < target_mid_count:
		var s: Sprite2D = Sprite2D.new()
		s.texture = mid
		s.centered = true
		s.scale = tile_scale
		s.z_index = tiles_z_index

		var insert_index: int = _tile_sprites.size() - 2 # before cap_end_1 & cap_end_2
		_tiles_root.add_child(s)
		_tiles_root.move_child(s, insert_index)
		_tile_sprites.insert(insert_index, s)
		current_mid_count += 1

	while current_mid_count > target_mid_count and current_mid_count > 1:
		var remove_index: int = _tile_sprites.size() - 3
		var s2: Sprite2D = _tile_sprites[remove_index]
		_tile_sprites.remove_at(remove_index)
		if is_instance_valid(s2):
			s2.queue_free()
		current_mid_count -= 1

func _update_tiles_transform() -> void:
	if _tile_sprites.is_empty():
		return
	if points.size() < 2:
		return

	var start: Vector2 = points[0]
	var end_index: int = points.size() - 1
	var endp: Vector2 = points[end_index]

	var rope_vec: Vector2 = endp - start
	var rope_length: float = rope_vec.length()
	if rope_length <= 0.001:
		return

	var dir: Vector2 = rope_vec / rope_length

	# Decide number of slots based on rope length and mid_tile_px.
	var step: float = mid_tile_px + seam_offset_px
	step = maxf(step, 1.0)

	var total_slots: int = int(floor(rope_length / step))
	total_slots = max(total_slots, 4) # must fit 4 pieces at least

	var mid_count: int = max(total_slots - 3, 1)
	_ensure_mid_count(mid_count)

	# Place each tile
	for i: int in range(_tile_sprites.size()):
		var s: Sprite2D = _tile_sprites[i]
		if not is_instance_valid(s):
			continue

		var pos: Vector2 = start + dir * (float(i) * step)
		if pixel_snap:
			pos = pos.round()

		s.position = pos
		s.rotation = dir.angle() if rotate_to_rope else 0.0

# Optional convenience (if you ever want to drive it directly)
func set_endpoints_world(p1_world: Vector2, p2_world: Vector2) -> void:
	points = PackedVector2Array([to_local(p1_world), to_local(p2_world)])
	_update_tiles_transform()
