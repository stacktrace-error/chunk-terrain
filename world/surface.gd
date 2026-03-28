extends TileMapLayer
class_name Surface

@export var noise : FastNoiseLite
@export var generation_seed : int
## Entity data and IDs.
var entities : Dictionary[int, Entity] = {}
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

func serialize_stub() -> String:
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
			s.used_chunks[cxy] = null
	return s


func deserialize_chunk_tiles(cxy:Vector2i, chunk:Array) -> void:
	var mxy : Vector2i = Vector2i()
	for mx in chunk_size[0]: for my in chunk_size[1]:
		mxy[0] = cxy[0] * chunk_size[0] + mx
		mxy[1] = cxy[1] * chunk_size[1] + my
		deserialize_tile(mxy, chunk[mx][my])

func serialize_chunk_tiles(cxy:Vector2i) -> Array[Array]:
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


func serialize_tile(mxy:Vector2i) -> int:
	return get_cell_source_id(mxy)

func deserialize_tile(mxy:Vector2i, tile:int) -> void:
	if tile != -1:
		set_cell(mxy, tile, Vector2i.ZERO)
	else: erase_cell(mxy)
#endregion


#region networking
func send_or_generate_chunk(peer_id:int, cxy:Vector2i) -> void:
	if !cxy in used_chunks: 
		generate_chunk(cxy)
	elif multiplayer.get_unique_id() == 1 && peer_id != 1:
		rpc_send_chunk.rpc_id(peer_id, serialize_chunk_tiles(cxy), cxy)

@rpc("authority", "call_remote", "reliable")
func rpc_send_chunk(chunk:Array[Array], cxy:Vector2i) -> void: deserialize_chunk_tiles(cxy, chunk)


##TODO send only to players who are loading these chunks
##TODO send serialized tile
@rpc("any_peer", "call_local", "reliable")
func rpc_place_tile(mxy:Vector2i) -> void:
	set_cell(mxy, 1, Vector2i.ZERO)
	mark_chunk_used_map(mxy)

##TODO send only to players who are loading these chunks
@rpc("any_peer", "call_local", "reliable")
func rpc_remove_tile(mxy:Vector2i) -> void:
	erase_cell(mxy)
	mark_chunk_used_map(mxy)
#endregion


#region generation
func generate_chunk(cxy:Vector2i) -> void:
	noise.seed = generation_seed
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

func map_to_chunk(mxy:Vector2) -> Vector2i: return (mxy / (chunk_size as Vector2)).floor()
func local_to_chunk(lxy:Vector2) -> Vector2i: return map_to_chunk(local_to_map(lxy))
func global_to_chunk(xy:Vector2) -> Vector2i: return local_to_chunk(to_local(xy))

func global_to_map(xy:Vector2) -> Vector2i: return local_to_map(to_local(xy))
#endregion


#region entities

#endregion
