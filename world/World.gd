extends Node2D
class_name World

@export var noise : FastNoiseLite
@export var map : TileMapLayer
@export var gnereation_seed : int
## Entity data and IDs.
var entities : Dictionary[int, Entity] = {}
## The chunk coordinates of chunks that should be saved.
var used_chunks : Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 0)]

const chunk_size : Vector2i = Vector2i(16, 16)

func _input(_event):
	if Input.is_action_just_pressed("save"): save_file()
	if Input.is_action_just_pressed("load"): load_file()

#func _process(_delta):
	#if Input.is_action_pressed("regenerate"):
		#var cxy : Vector2i = local_to_chunk(get_local_mouse_position())
		#print(cxy)
		#generate_chunk(cxy)


#region save/load
func save_file():
	var chunks : Dictionary[String, Dictionary] = {}
	
	for cxy : Vector2i in used_chunks:
		chunks[str("[", cxy[0], ", ", cxy[1], "]")] = {
			"entities" = [],
			"tiles" = serialize_chunk_tiles(map, cxy)
		}

	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.WRITE)
	file.store_string(JSON.stringify(chunks, "\t"))
	file.close()

func load_file():
	var file : FileAccess = FileAccess.open(str("user://", name, ".dat"), FileAccess.READ)
	var chunks : Dictionary = JSON.parse_string(file.get_as_text())
	
	map.clear()
	used_chunks.clear()
	used_chunks.resize(chunks.size())
	
	var i : int = 0
	for c in chunks:
		var arr : Array = JSON.parse_string(c) #can't json vectors, parse an array instead
		var cxy : Vector2i = Vector2i(arr[0], arr[1])
		
		deserialize_chunk_tiles(map, cxy, chunks[c]["tiles"])
		used_chunks[i] = cxy
		i += 1
		
#endregion


#region (de)serialization
#TODO switch to byte output
static func deserialize_chunk_tiles(tilemap:TileMapLayer, cxy:Vector2i, chunk:Array) -> void:
	var xy : Vector2i = Vector2i()
	for x in chunk_size[0]: for y in chunk_size[1]:
		xy[0] = cxy[0] * chunk_size[0] + x
		xy[1] = cxy[1] * chunk_size[1] + y
		if chunk[x][y]:
			tilemap.set_cell(xy, 0, Vector2i.ZERO)
		else: tilemap.erase_cell(xy)

#TODO switch to byte output
static func serialize_chunk_tiles(tilemap:TileMapLayer, cxy:Vector2i) -> Array[Array]:
	var xy : Vector2i = Vector2i()
	var chunk : Array[Array]
	chunk.resize(chunk_size[0])
	
	for x in chunk_size[0]:
		var tiles : Array[bool] = []
		tiles.resize(chunk_size[1])
		
		for y in chunk_size[1]:
			xy[0] = cxy[0] * chunk_size[0] + x
			xy[1] = cxy[1] * chunk_size[1] + y
			tiles[y] = tilemap.get_cell_atlas_coords(xy).x != -1
			
		chunk[x] = tiles
	return chunk

@warning_ignore("unused_parameter")
static func serialize_tile(tilemap:TileMapLayer, x:int, y:int):
	return # TODO turn into bytes and shit out

@warning_ignore("unused_parameter")
static func deserialize_tile(tilemap:TileMapLayer, x:int, y:int, tile):
	pass # TODO something something decipher bytes and place tile from that
#endregion


#region networking
func send_or_generate_chunk(cxy:Vector2i):
	if !cxy in used_chunks: 
		generate_chunk(cxy)
	elif multiplayer.get_unique_id() == 1:
		send_chunk.rpc(serialize_chunk_tiles(map, cxy), cxy) ##TODO should be rpc_id()

@rpc("authority", "call_remote", "reliable")
func send_chunk(chunk:Array[Array], cxy:Vector2i): deserialize_chunk_tiles(map, cxy, chunk)


##TODO send only to players who are loading these chunks
##TODO send serialized tile
@rpc("any_peer", "call_local", "reliable")
func place_tile(xy:Vector2i):
	map.set_cell(xy, 0, Vector2i.ZERO)
	mark_chunk_used_map(xy)

##TODO send only to players who are loading these chunks
@rpc("any_peer", "call_local", "reliable")
func remove_tile(xy:Vector2i):
	map.erase_cell(xy)
	mark_chunk_used_map(xy)
#endregion


#region generation
func generate_chunk(cxy:Vector2i) -> void:
	var xy : Vector2i = Vector2i()
	for x in chunk_size[0]: for y in chunk_size[1]:
		xy[0] = cxy[0] * chunk_size[0] + x
		xy[1] = cxy[1] * chunk_size[1] + y
		
		if noise.get_noise_1d(xy[0]) * 10 + xy[1] > 0:
			map.set_cell(xy, 0, Vector2i.ZERO)
		else: map.erase_cell(xy)
#endregion


#region utility
func mark_chunk_used(cxy:Vector2i): if !cxy in used_chunks: used_chunks.append(cxy)
func mark_chunk_used_map(xy:Vector2): mark_chunk_used(map_to_chunk(xy))

func map_to_chunk(xy:Vector2) -> Vector2i: return Vector2i((xy / (chunk_size as Vector2).floor()))
func local_to_chunk(xy:Vector2) -> Vector2i: return map_to_chunk(map.local_to_map(xy))
func global_to_chunk(xy:Vector2) -> Vector2i: return local_to_chunk(map.to_local(xy))

func global_to_map(xy:Vector2) -> Vector2i: return map.local_to_map(map.to_local(xy))
#endregion


#region entities

#endregion
