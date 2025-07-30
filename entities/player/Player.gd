extends CharacterBody2D
class_name Player


func _ready():
	set_multiplayer_authority(name.trim_prefix("Player ").to_int())
	if is_multiplayer_authority():
		Camera.reparent(self, false)

func _process(delta):
	velocity.y = lerp(velocity.y, 300.0, delta * 3)
	
	if is_multiplayer_authority():
		velocity.x = lerp(velocity.x, Input.get_axis("left", "right") * 100, 0.1)
		
		if Input.is_action_just_pressed("up"):
			velocity.y = -500
	
	move_and_slide()
