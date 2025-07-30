extends Camera2D

#func _process(delta):
	#position += Input.get_vector("left", "right", "up", "down") * delta * 200

func _input(event):
	if event.is_action("zoom_in"):
		zoom += Vector2.ONE * 0.5
	elif event.is_action("zoom_out"):
		zoom -= Vector2.ONE * 0.5
