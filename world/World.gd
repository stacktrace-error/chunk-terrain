extends Node2D
class_name World

@export var noise : FastNoiseLite
@export var map : TileMapLayer
@export var gnereation_seed : int
## Entity data and IDs.
var entities : Dictionary[int, Entity] = {}
## The chunk coordinates of chunks that should be saved.
var used_chunks : Array[Vector2i] = []

const chunk_size : Vector2i = Vector2i(16, 16)

func _input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed("save"): save_file()
	if Input.is_action_just_pressed("load"): load_file()

#func _process(_delta):
	#if Input.is_action_pressed("regenerate"):
		#var cxy : Vector2i = local_to_chunk(get_local_mouse_position())
		#print(cxy)
		#generate_chunk(cxy)

#func _draw():
	#pass

#region save/load
func save_file() -> void:
	var chunks : Dictionary[String, Dictionary] = {}
	
	for cxy : Vector2i in used_chunks:
		chunks[str("[", cxy[0], ", ", cxy[1], "]")] = {
			"entities" = [],
			"tiles" = serialize_chunk_tiles(map, cxy)
		}

	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.WRITE)
	file.store_string(JSON.stringify(chunks, "\t"))
	file.close()

func load_file() -> void:
	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.READ)
	var chunks : Dictionary = JSON.parse_string(file.get_as_text())
	
	map.clear()
	used_chunks.clear()
	used_chunks.resize(chunks.size())
	
	var i : int = 0
	for c : String in chunks:
		var arr : Array = JSON.parse_string(c) #can't json vectors, parse an array instead
		var cxy : Vector2i = Vector2i(arr[0], arr[1])
		
		deserialize_chunk_tiles(map, cxy, chunks[c]["tiles"])
		used_chunks[i] = cxy
		i += 1
		
#endregion


#region (de)serialization
static func deserialize_chunk_tiles(tilemap:TileMapLayer, cxy:Vector2i, chunk:Array) -> void:
	var mxy : Vector2i = Vector2i()
	for mx in chunk_size[0]: for my in chunk_size[1]:
		mxy[0] = cxy[0] * chunk_size[0] + mx
		mxy[1] = cxy[1] * chunk_size[1] + my
		deserialize_tile(tilemap, mxy, chunk[mx][my])

static func serialize_chunk_tiles(tilemap:TileMapLayer, cxy:Vector2i) -> Array[Array]:
	var mxy : Vector2i = Vector2i()
	var chunk : Array[Array]
	chunk.resize(chunk_size[0])
	
	for mx in chunk_size[0]:
		var tiles : Array[int] = []
		tiles.resize(chunk_size[1])
		
		for my in chunk_size[1]:
			mxy[0] = cxy[0] * chunk_size[0] + mx
			mxy[1] = cxy[1] * chunk_size[1] + my
			tiles[my] = serialize_tile(tilemap, mxy)
			
		chunk[mx] = tiles
	return chunk

static func serialize_tile(tilemap:TileMapLayer, mxy:Vector2i) -> int:
	return tilemap.get_cell_source_id(mxy)

static func deserialize_tile(tilemap:TileMapLayer, mxy:Vector2i, tile:int) -> void:
	if tile != -1:
		tilemap.set_cell(mxy, tile, Vector2i.ZERO)
	else: tilemap.erase_cell(mxy)
#endregion


#region networking
func send_or_generate_chunk(cxy:Vector2i) -> void:
	if !cxy in used_chunks: 
		generate_chunk(cxy)
	elif multiplayer.get_unique_id() == 1:
		send_chunk.rpc(serialize_chunk_tiles(map, cxy), cxy) ##TODO should be rpc_id()

@rpc("authority", "call_remote", "reliable")
func send_chunk(chunk:Array[Array], cxy:Vector2i) -> void: deserialize_chunk_tiles(map, cxy, chunk)


##TODO send only to players who are loading these chunks
##TODO send serialized tile
@rpc("any_peer", "call_local", "reliable")
func place_tile(mxy:Vector2i) -> void:
	map.set_cell(mxy, 1, Vector2i.ZERO)
	mark_chunk_used_map(mxy)

##TODO send only to players who are loading these chunks
@rpc("any_peer", "call_local", "reliable")
func remove_tile(mxy:Vector2i) -> void:
	map.erase_cell(mxy)
	mark_chunk_used_map(mxy)
#endregion


#region generation
func generate_chunk(cxy:Vector2i) -> void:
	var mxy : Vector2i = Vector2i()
	for mx in chunk_size[0]: for my in chunk_size[1]:
		mxy[0] = cxy[0] * chunk_size[0] + mx
		mxy[1] = cxy[1] * chunk_size[1] + my
		
		if noise.get_noise_1d(mxy[0]) * 20 + mxy[1] > 0:
			map.set_cell(mxy, 0, Vector2i.ZERO)
		else: map.erase_cell(mxy)
#endregion


#region utility
func mark_chunk_used(cxy:Vector2i) -> void: if !cxy in used_chunks: used_chunks.append(cxy)
func mark_chunk_used_map(mxy:Vector2) -> void: mark_chunk_used(map_to_chunk(mxy))

func map_to_chunk(mxy:Vector2) -> Vector2i: return (mxy / (chunk_size as Vector2)).floor()
func local_to_chunk(lxy:Vector2) -> Vector2i: return map_to_chunk(map.local_to_map(lxy))
func global_to_chunk(xy:Vector2) -> Vector2i: return local_to_chunk(map.to_local(xy))

func global_to_map(xy:Vector2) -> Vector2i: return map.local_to_map(map.to_local(xy))
#endregion


#region entities

#endregion
