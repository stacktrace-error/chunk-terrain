extends Camera2D

#func _process(delta):
	#position += Input.get_vector("left", "right", "up", "down") * delta * 200

func _input(event):
	if event.is_action("zoom_in"):
		set_cam_zoom(zoom.x + 0.5)
	elif event.is_action("zoom_out"):
		set_cam_zoom(zoom.x - 0.5)

func set_cam_zoom(cam_zoom:float):
	var z : float = clampf(cam_zoom, 0.1, 10.0)
	zoom.x = z
	zoom.y = z
