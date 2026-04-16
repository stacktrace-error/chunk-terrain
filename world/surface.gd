extends TileMapLayer
class_name Surface

@export var noise : FastNoiseLite
@export var generation_seed : int

## The chunk coordinates of chunks that are currently loaded.
var loaded_chunks : Dictionary[Vector2i, Variant] = {}
## The chunk coordinates of chunks that should be saved.
var used_chunks : Dictionary[Vector2i, Variant] = {}


const chunk_size : Vector2i = Vector2i(16, 16)

#func _process(_delta):
	#if Input.is_action_pressed("regenerate"):
		#var cxy : Vector2i = local_to_chunk(get_local_mouse_position())
		#print(cxy)
		#generate_chunk(cxy)

static func create(_name:String, _seed:int) -> Surface:
	var s : Surface = Surface.new()
	s.tile_set = load("res://assets/tiles/tileset.tres")
	s.noise = load("res://assets/new_fast_noise_lite.tres")
	s.generation_seed = _seed
	s.name = _name
	return s


#region (de)serialization
#region full map
func serialize() -> String:
	var chunks : Dictionary[String, Dictionary] = {}
	for cxy : Vector2i in used_chunks:
		chunks[str("[", cxy[0], ", ", cxy[1], "]")] = {
			"entities" = [],
			"tiles" = serialize_chunk_tiles(cxy)
		}
	
	return JSON.stringify({
		"name" = name,
		"seed" = generation_seed,
		"chunks" = chunks
	})

## Serialize this surface as a stub, meaning that it will have no chunks inside.
func to_stub() -> String:
	return JSON.stringify({
		"name" = name,
		"seed" = generation_seed,
	})

static func deserialize(json:String) -> Surface:
	var surface : Dictionary = JSON.parse_string(json)
	var s : Surface = create(surface["name"], surface["seed"])
	
	if surface.has("chunks"):
		for c : String in surface["chunks"]:
			var arr : Array = JSON.parse_string(c) #can't json vectors, parse an array instead
			var cxy : Vector2i = Vector2i(arr[0], arr[1])
			
			s.deserialize_chunk_tiles(cxy, surface["chunks"][c]["tiles"])
	return s
#endregion


#region chunks
## Puts chunk data into a format that can be sent over network. 
## Returns empty data when the chunk can be generated.
func serialize_chunk_tiles(cxy:Vector2i) -> Array:
	if !used_chunks.has(cxy): return Array()
	
	var mxy : Vector2i = Vector2i()
	var chunk : Array[Array]
	chunk.resize(chunk_size[0])
	
	for mx in chunk_size[0]:
		var tiles : Array[int] = []
		tiles.resize(chunk_size[1])
		
		for my in chunk_size[1]:
			mxy[0] = cxy[0] * chunk_size[0] + mx
			mxy[1] = cxy[1] * chunk_size[1] + my
			tiles[my] = serialize_tile(mxy)
			
		chunk[mx] = tiles
	return chunk

## Places tiles from serialized chunk data.
## If chunk data is empty, generates the chunk instead.
func deserialize_chunk_tiles(cxy:Vector2i, chunk:Array) -> void:
	if chunk.is_empty(): 
		generate_chunk(cxy)
		return
	
	mark_chunk_used(cxy)
	mark_chunk_loaded(cxy)
	
	var mxy : Vector2i = Vector2i()
	for mx in chunk_size[0]: for my in chunk_size[1]:
		mxy[0] = cxy[0] * chunk_size[0] + mx
		mxy[1] = cxy[1] * chunk_size[1] + my
		deserialize_tile(mxy, chunk[mx][my])

## Has to be called from the server's side. TODO bad name
func request_chunks(peer_id:int, cxy:Vector2i, c_radius:int) -> void:
	if !multiplayer.is_server(): return
	
	var rnge : PackedInt32Array = range(1 - c_radius, c_radius)
	
	var offset_xy : Vector2i
	for offset_x : int in rnge: for offset_y : int in rnge:
		offset_xy[0] = offset_x + cxy[0]
		offset_xy[1] = offset_y + cxy[1]
		request_chunk(peer_id, offset_xy)

## Has to be called from the server's side. TODO bad name
func request_chunk(peer_id:int, cxy:Vector2i) -> void:
	if multiplayer.is_server() and !loaded_chunks.has(cxy):
		# Client can place blocks in empty chunks and override the whole damn thing otherwise.
		if !used_chunks.has(cxy): generate_chunk(cxy)
		
		rpc_place_chunk.rpc_id(peer_id, cxy, serialize_chunk_tiles(cxy))

@rpc("call_local")
func rpc_place_chunk(cxy:Vector2i, chunk:Array) -> void: deserialize_chunk_tiles(cxy, chunk)
#endregion chunks


#region tiles
func serialize_tile(mxy:Vector2i) -> int:
	return get_cell_source_id(mxy)

func deserialize_tile(mxy:Vector2i, tile:int) -> void:
	if tile != -1:
		set_cell(mxy, tile, Vector2i.ZERO)
	else: erase_cell(mxy)

## Place a tile over network. A tile index of -1 will remove it instead.
#TODO the client cannot be trusted. make authority
#TODO send only to players who are loading these chunks
@rpc("any_peer", "call_local")
func rpc_place_tile(mxy:Vector2i, tile:int) -> void:
	deserialize_tile(mxy, tile)
	mark_chunk_used_map(mxy)
#endregion tiles
#endregion (de)serialization


#region generation
## (Re-)generate a chunk at this location. A used chunk will be unmarked.
func generate_chunk(cxy:Vector2i) -> void:
	noise.seed = generation_seed
	used_chunks.erase(cxy)
	var mxy : Vector2i = Vector2i()
	for mx in chunk_size[0]: for my in chunk_size[1]:
		mxy[0] = cxy[0] * chunk_size[0] + mx
		mxy[1] = cxy[1] * chunk_size[1] + my
		
		if noise.get_noise_1d(mxy[0]) * 20 + mxy[1] > 10:
			set_cell(mxy, 0, Vector2i.ZERO)
		else: erase_cell(mxy)
#endregion


#region utility
func mark_chunk_used(cxy:Vector2i) -> void: if !cxy in used_chunks: used_chunks[cxy] = null
func mark_chunk_used_map(mxy:Vector2) -> void: mark_chunk_used(map_to_chunk(mxy))

func mark_chunk_loaded(cxy:Vector2i) -> void: if !cxy in loaded_chunks: loaded_chunks[cxy] = null
func mark_chunk_loaded_map(mxy:Vector2) -> void: mark_chunk_loaded(map_to_chunk(mxy))

func map_to_chunk(mxy:Vector2) -> Vector2i: return (mxy / (chunk_size as Vector2)).floor()
func local_to_chunk(lxy:Vector2) -> Vector2i: return map_to_chunk(local_to_map(lxy))
func global_to_chunk(xy:Vector2) -> Vector2i: return local_to_chunk(to_local(xy))

func global_to_map(xy:Vector2) -> Vector2i: return local_to_map(to_local(xy))
#endregion
