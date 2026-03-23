extends Camera2D

#func _process(delta):
	#position += Input.get_vector("left", "right", "up", "down") * delta * 200

func _unhandled_input(event:InputEvent) -> void:
	var change = Input.get_axis("zoom_out", "zoom_in") * 0.2
	if change: zoom += Vector2.ONE * change * zoom.x
	
