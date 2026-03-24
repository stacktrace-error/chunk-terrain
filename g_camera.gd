extends Camera2D

var target : Node2D

func _unhandled_input(_event:InputEvent) -> void:
	var change : float = Input.get_axis("zoom_out", "zoom_in") * 0.2
	if change: zoom = Vector2.ONE * clampf(zoom.x + change * zoom.x, 0.1, 3)

func _physics_process(_delta: float) -> void:
	if target: global_position = target.global_position

#func _process(delta):
	#position += Input.get_vector("left", "right", "up", "down") * delta * 200
