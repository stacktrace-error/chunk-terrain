extends CharacterBody2D
class_name PlayerBody

signal surface_changed(surface:Surface)

@export var name_label : RichTextLabel

var id : int:
	set(x):
		id = x
		set_multiplayer_authority(id)

var surface : Surface:
	set(x):
		if surface != x:
			surface = x
			surface_changed.emit(x)
var cxy : Vector2i

const chunk_radius : int = 8

static func create(peer_id:int) -> PlayerBody:
	var player : Player = Lobby.players[peer_id]
	var body : PlayerBody = preload("res://entities/player/player_body.tscn").instantiate()
	
	body.id = peer_id
	body.name = str(player.id)
	body.name_label.text = player.colored_name()
	
	body.surface_changed.connect(Surfaces.set_active_surface)
	player.disconnecting.connect(body.on_player_disconnecting)
	
	return body

func _enter_tree() -> void:
	surface = Surfaces.get_parent_surface(self)
	if multiplayer.get_unique_id() == id: Camera.target = self
	Lobby.players[id].body = self
	load_chunks()

func on_player_disconnecting(peer_id:int) -> void:
	if peer_id == get_multiplayer_authority():
		queue_free()

func _process(delta:float) -> void:
	velocity.y = lerp(velocity.y, 300.0, delta * 3)
	
	if is_multiplayer_authority():
		velocity.x = lerp(velocity.x, Input.get_axis("left", "right") * 300, 0.1)
		
		if Input.is_action_pressed("up"): velocity.y = -500
		if Input.is_action_pressed("down"): velocity.y = 1000
		
		if Input.is_action_pressed("place_tile"):
			surface.rpc_place_tile.rpc(surface.global_to_map(get_global_mouse_position()), 1)
		elif Input.is_action_pressed("remove_tile"):
			surface.rpc_place_tile.rpc(surface.global_to_map(get_global_mouse_position()), -1)
	
	move_and_slide()
	
	load_chunks()

func load_chunks() -> void:
	var last_chunk : Vector2i = cxy
	cxy = surface.global_to_chunk(global_position)
	if cxy != last_chunk: surface.request_chunks(get_multiplayer_authority(), cxy, chunk_radius)


#func serialize_save() -> Dictionary[String, Variant]:
#	return serialize_sync()

func serialize_sync() -> Dictionary[String, Variant]:
	return {
		"scene_file_path" = scene_file_path,
		"name" = name,
		"x" = position.x,
		"y" = position.y,
		"id" = id,
		"name_label" = name_label.text
	}

func deserialize(data:Dictionary) -> void:
	position.x = data["x"]
	position.y = data["y"]
	id = data["id"]
	name_label.text = data["name_label"]
