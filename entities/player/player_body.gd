extends CharacterBody2D
class_name PlayerBody

signal surface_changed(surface:Surface)

@export var name_label : RichTextLabel

var surface : Surface:
	set(x):
		if surface != x:
			surface = x
			surface_changed.emit(x)
var cxy : Vector2i

const chunk_radius : int = 8

static func create(id:int, mul_api:MultiplayerAPI) -> PlayerBody:
	var player : Player = Lobby.players[id]
	var body : PlayerBody = preload("res://entities/player/player_body.tscn").instantiate()
	
	body.set_multiplayer_authority(id)
	body.name = str(player.id)
	body.name_label.text = player.colored_name()
	
	body.surface_changed.connect(Surfaces.set_active_surface)
	player.disconnecting.connect(body.on_player_disconnecting)
	
	if mul_api.get_unique_id() == id: Camera.target = body
	
	return body

func _enter_tree() -> void:
	surface = Surfaces.get_parent_surface(self)
	load_chunks()

func on_player_disconnecting(id:int) -> void:
	if id == get_multiplayer_authority():
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

func serialize() -> Dictionary[String, Variant]:
	return {}

#func dese
