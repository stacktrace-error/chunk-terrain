extends Node

signal world_created
signal world_closed

var file_path : String = ""

#var spawn_point : Node2D:
	#get:
		#return active_surface
#var warper : Warper

var has_world : bool:
	set(x):
		if has_world != x:
			has_world = x
			if has_world:
				world_created.emit()
			else: world_closed.emit()
var active_surface : Surface:
	set(x):
		if active_surface:
			active_surface.collision_enabled = false
			active_surface.hide()
		active_surface = x
		x.collision_enabled = true
		x.show()

func _ready() -> void:
	var args : Dictionary[String, String] = Util.launch_args
	
	if args.has("load"): 
		load_from(args["load"])
		Lobby.start_game()
	elif args.has("new-game"): 
		new_game()
		Lobby.start_game()


func on_peer_connected(id:int) -> void:
	if has_world and !id == 1: 
		rpc_add_stubs.rpc_id(id, to_stubs())
		
		for player : int in Lobby.players:
			rpc_spawn_body.rpc_id(id, player)
		
		rpc_spawn_body.rpc(id)

func on_game_started() -> void:
	rpc_add_stubs.rpc(to_stubs())
	for player : int in Lobby.players:
		rpc_spawn_body.rpc(player)

@rpc("call_local")
func rpc_spawn_body(id:int) -> void:
	active_surface.add_child(PlayerBody.create(id, multiplayer))

#region creation/deserialization
func new_game() -> void:
	var s : Surface = Surface.create("nauvis", 3)
	active_surface = s
	add_child(s)
	
	#spawn_point = warper
	#active_surface.add_child.call_deferred(warper)
	
	file_path = ""
	has_world = true

func load_from(path:String) -> void:
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	var surfaces : Array = JSON.parse_string(file.get_as_text())
	
	for surface : String in surfaces: add_child(Surface.deserialize(surface))
	active_surface = get_child(0)
	
	file.close()
	file_path = path
	has_world = true

@rpc
func rpc_add_stubs(stubs:Array[String]) -> void:
	if has_world: return
	
	for surface : String in stubs: add_child(Surface.deserialize(surface))
	active_surface = get_child(0)
	has_world = true
#endregion

#region serializiation
func save() -> void:
	if !file_path.is_empty(): save_as(file_path)

func save_as(path:String) -> void:
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	var surfaces : Array[String] = []
	
	for child : Node in get_children():
		if child is Surface:
			surfaces.append(child.serialize())
	
	#print(JSON.stringify(surfaces, ""))
	file.store_string(JSON.stringify(surfaces, ""))
	file.close()
	file_path = path

func to_stubs() -> Array[String]:
	var stubs : Array[String] = []
	
	for child : Node in get_children():
		if child is Surface:
			stubs.append(child.to_stub())
	return stubs
#endregion

func clear() -> void:
	for child : Node in get_children(): child.free()
	
	has_world = false
	
	#spawn_point = null
	#warper = null

func get_parent_surface(node:Node) -> Surface:
	while node:
		if node is Surface: 
			return node
		node = node.get_parent()
	return null

func set_active_surface(surface:Surface) -> void: active_surface = surface
