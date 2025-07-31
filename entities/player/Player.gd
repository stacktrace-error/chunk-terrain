extends CharacterBody2D
class_name Player

var cxy : Vector2i

func _ready() -> void:
	set_multiplayer_authority(name.trim_prefix("Player ").to_int())
	if is_multiplayer_authority():
		Camera.reparent(self, false)

func _process(delta) -> void:
	velocity.y = lerp(velocity.y, 300.0, delta * 3)
	
	if is_multiplayer_authority():
		velocity.x = lerp(velocity.x, Input.get_axis("left", "right") * 300, 0.1)
		
		if Input.is_action_just_pressed("up"):
			velocity.y = -500
	
	move_and_slide()
	
	var last_chunk : Vector2i = cxy
	cxy	= GameWorld.global_to_chunk(global_position)
	if cxy != last_chunk: load_chunks()

func load_chunks() -> void:
	if !(is_multiplayer_authority() or multiplayer.get_unique_id() == 1): return
	
	var gxy : Vector2i
	for x : int in range(-1, 2): for y : int in range(-1, 2):
		gxy[0] = x + cxy[0]
		gxy[1] = y + cxy[1]
		GameWorld.generate_unused(gxy)
