extends Node2D
class_name World

@export var noise : FastNoiseLite
@export var map : TileMapLayer
@export var seed : int
## Entity data and IDs.
var entities : Dictionary[int, Entity] = {}
## The chunk coordinates of chunks that should be saved.
var used_chunks : Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 0)]

const chunk_size : Vector2i = Vector2i(16, 16)

func _input(_event):
	if Input.is_action_just_pressed("save"): save_file()
	if Input.is_action_just_pressed("load"): load_file()

func _process(delta):
	if Input.is_action_pressed("regenerate"):
		var cxy : Vector2i = local_to_chunk(get_local_mouse_position())
		print(cxy)
		generate_chunk(cxy[0], cxy[1])

#region save/load
func save_file():
	var chunks : Dictionary[String, Dictionary] = {}
	
	for cxy : Vector2i in used_chunks:
		chunks[str("[", cxy[0], ", ", cxy[1], "]")] = {
			"entities" = [],
			"tiles" = serialize_chunk_tiles(map, cxy[0], cxy[1])
		}

	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.WRITE)
	file.store_string(JSON.stringify(chunks, "\t"))
	file.close()

func load_file():
	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.READ)
	var chunks : Dictionary = JSON.parse_string(file.get_as_text())
	
	map.clear()
	for c in chunks:
		var cxy : Array = JSON.parse_string(c) #can't json vectors, parse an array instead
		deserialize_chunk_tiles(map, chunks[c]["tiles"], cxy[0], cxy[1])
#endregion

#region tile (de)serialization
static func deserialize_chunk_tiles(tilemap:TileMapLayer, chunk:Array, cx:int, cy:int) -> void:
	var xy : Vector2i = Vector2i()
	for x in chunk_size[0]: for y in chunk_size[1]:
		xy[0] = cx * chunk_size[0] + x
		xy[1] = cy * chunk_size[1] + y
		if chunk[x][y]:
			tilemap.set_cell(xy, 0, Vector2i.ZERO)

static func serialize_chunk_tiles(tilemap:TileMapLayer, cx:int, cy:int) -> Array[Array]:
	var xy : Vector2i = Vector2i()
	var chunk : Array[Array]
	chunk.resize(chunk_size[0])
	
	for x in chunk_size[0]:
		var tiles : Array[bool] = []
		tiles.resize(chunk_size[1])
		
		for y in chunk_size[1]:
			xy[0] = cx * chunk_size[0] + x
			xy[1] = cy * chunk_size[1] + y
			tiles[y] = tilemap.get_cell_atlas_coords(xy).x != -1
			
		chunk[x] = tiles
	return chunk
#endregion

#region generation
func generate_chunk(cx:int, cy:int) -> void:
	clear_chunk(cx, cy)
	
	var xy : Vector2i = Vector2i()
	for x in chunk_size[0]: for y in chunk_size[1]:
		xy[0] = cx * chunk_size[0] + x
		xy[1] = cy * chunk_size[1] + y
		
		if noise.get_noise_1d(xy[0]) * 10 + xy[1] > 0:
			map.set_cell(xy, 0, Vector2i.ZERO)
		else: map.erase_cell(xy)
#endregion

#region utility
func clear_chunk(cx:int, cy:int):
	pass

func map_to_chunk(xy:Vector2) -> Vector2i: return Vector2i(floor(xy / (chunk_size as Vector2)))

func local_to_chunk(xy:Vector2) -> Vector2i: return map_to_chunk(map.local_to_map(xy))
#endregion

#region entities
