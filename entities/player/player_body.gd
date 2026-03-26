extends CharacterBody2D
class_name PlayerBody

signal surface_changed(surface:Surface)

var surface : Surface:
	set(x):
		if surface != x:
			surface = x
			surface_changed.emit(x)
var cxy : Vector2i

const chunk_radius : int = 8

func _enter_tree() -> void:
	surface = Surfaces.get_parent_surface(self)
	load_chunks()

func _process(delta:float) -> void:
	velocity.y = lerp(velocity.y, 300.0, delta * 3)
	
	if is_multiplayer_authority():
		velocity.x = lerp(velocity.x, Input.get_axis("left", "right") * 300, 0.1)
		
		if Input.is_action_pressed("up"):
			velocity.y = -500
		if Input.is_action_pressed("down"):
			velocity.y = 1000
		
		if Input.is_action_pressed("place_tile"):
			surface.rpc_place_tile.rpc(surface.global_to_map(get_global_mouse_position()))
		elif Input.is_action_pressed("remove_tile"):
			surface.rpc_remove_tile.rpc(surface.global_to_map(get_global_mouse_position()))
	
	move_and_slide()
	
	var last_chunk : Vector2i = cxy
	cxy	= surface.global_to_chunk(global_position)
	if cxy != last_chunk: load_chunks()

func load_chunks() -> void:
	var peer_id : int = multiplayer.get_unique_id()
	if !(is_multiplayer_authority() or peer_id == 1): return
	
	var rnge : PackedInt32Array = range(1 - chunk_radius, chunk_radius)
	
	var offset_xy : Vector2i
	for offset_x : int in rnge: for offset_y : int in rnge:
		offset_xy[0] = offset_x + cxy[0]
		offset_xy[1] = offset_y + cxy[1]
		surface.send_or_generate_chunk(peer_id, offset_xy)
