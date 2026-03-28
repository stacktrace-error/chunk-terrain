extends Node

var file_path : String = ""
var spawn_point : Node2D:
	get:
		return active_surface
#var warper : Warper

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
		Lobby.rpc_start_game.rpc()
	elif args.has("new-game"): 
		new_game()
		Lobby.rpc_start_game.rpc()

func new_game() -> void:
	var s : Surface = Surface.create("nauvis", 3)
	active_surface = s
	add_child(s)
	
	#spawn_point = warper
	#active_surface.add_child.call_deferred(warper)
	
	file_path = ""

func load_from(path:String) -> void:
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	var surfaces : Array = JSON.parse_string(file.get_as_text())
	
	for surface : String in surfaces: add_child(Surface.deserialize(surface))
	active_surface = get_child(0)
	
	file.close()
	file_path = path


func save() -> void:
	if !file_path.is_empty(): save_as(file_path)

func save_as(path:String) -> void:
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	var surfaces : Array[String] = []
	
	for child : Node in get_children():
		if child is Surface:
			surfaces.append(child.serialize())
	
	print(JSON.stringify(surfaces, ""))
	file.store_string(JSON.stringify(surfaces, ""))
	file.close()
	file_path = path

func clear() -> void:
	for child : Node in get_children(): child.free()
	
	#spawn_point = null
	#warper = null


func get_parent_surface(node:Node) -> Surface:
	while node:
		if node is Surface: 
			return node
		node = node.get_parent()
	return null

func set_active_surface(surface:Surface) -> void: active_surface = surface
