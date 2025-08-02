extends CharacterBody2D
class_name Player

var cxy : Vector2i

const chunk_radius : int = 8

func _enter_tree():
	set_multiplayer_authority(name.trim_prefix("Player ").to_int())
	if is_multiplayer_authority():
		Camera.reparent(self, false)
	
	if multiplayer.get_unique_id() != 1: GameWorld.map.clear()
	
	load_chunks()

func _process(delta) -> void:
	velocity.y = lerp(velocity.y, 300.0, delta * 3)
	
	if is_multiplayer_authority():
		velocity.x = lerp(velocity.x, Input.get_axis("left", "right") * 300, 0.1)
		
		if Input.is_action_pressed("up"):
			velocity.y = -500
		if Input.is_action_pressed("down"):
			velocity.y = 1000
		
		if Input.is_action_pressed("place_tile"):
			GameWorld.place_tile.rpc(GameWorld.global_to_map(get_global_mouse_position()))
		elif Input.is_action_pressed("remove_tile"):
			GameWorld.remove_tile.rpc(GameWorld.global_to_map(get_global_mouse_position()))
	
	move_and_slide()
	
	var last_chunk : Vector2i = cxy
	cxy	= GameWorld.global_to_chunk(global_position)
	if cxy != last_chunk: load_chunks()

func load_chunks() -> void:
	if !(is_multiplayer_authority() or multiplayer.get_unique_id() == 1): return
	
	var range : PackedInt32Array = range(1 - chunk_radius, chunk_radius)
	
	var offset_xy : Vector2i
	for offset_x : int in range: for offset_y : int in range:
		offset_xy[0] = offset_x + cxy[0]
		offset_xy[1] = offset_y + cxy[1]
		GameWorld.send_or_generate_chunk(offset_xy)
