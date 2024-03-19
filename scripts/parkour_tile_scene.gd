extends Node2D

const SEED = 1234567891
const TILEMAP_SPACING = 20
const LOADING_DISTANCE = 60

# dict of array of the data
var parkour_tiles: Dictionary

# used when creaitng the json
func _as_list(tm: TileMap):
	var positions = tm.get_used_cells(0)
	var retlist = []
	for pos in positions:
		var td: TileData = tm.get_cell_tile_data(0, pos)
		var ac = tm.get_cell_atlas_coords(0, pos)
		var islava = td.get_custom_data("is_lava")
		var di: Dictionary = {"position": pos, "atlas_coords": ac}
		if islava:
			di["is_lava"] = true 
		retlist.append(di)
	return retlist
	
func _ready():
	var file = FileAccess.open("res://data/parkour_tiles.json", FileAccess.READ)
	parkour_tiles = JSON.parse_string(file.get_as_text())

func _str_to_vec2i(value: String) -> Vector2i:
	var a = value.split(",")
	return Vector2i(int(a[0]), int(a[1]))

# creates tilemap from tile
func _create_tilemap_from_tile(tile: Array, offset: Vector2i):
	var tm = TileMap.new()
	tm.tile_set = $TileMap.tile_set

	for t in tile:
		var _atlas = _str_to_vec2i(t["atlas_coords"])
		var _pos = _str_to_vec2i(t["position"]) + offset
		tm.set_cell(0, _pos, 0, _atlas)

	tm.name = str(offset.x)
	$TileMap.add_child(tm)

func update_with_position(_pos: Vector2):
	var pos = $TileMap.local_to_map(_pos/2)

	var min_tilemap_x = max(0, int((pos.x - LOADING_DISTANCE) / TILEMAP_SPACING) * TILEMAP_SPACING)
	var max_tilemap_x = int((pos.x + LOADING_DISTANCE) / TILEMAP_SPACING) * TILEMAP_SPACING

	# create within loading range
	for tilemap_x in range(min_tilemap_x, max_tilemap_x + TILEMAP_SPACING, TILEMAP_SPACING):
		if not $TileMap.has_node(str(tilemap_x)):
			# Create the tilemap (same logic as before)
			var v = rand_from_seed(SEED + tilemap_x)
			var tile_definition = parkour_tiles[str(v[0] % len(parkour_tiles))]
			_create_tilemap_from_tile(tile_definition, Vector2i(tilemap_x, 0)) 

	# remove if outside loading range
	for child in $TileMap.get_children():
		if child is TileMap:
			var child_x = int(str(child.name))
			if child_x < min_tilemap_x or child_x > max_tilemap_x:
				child.queue_free()
	pass
