class_name Warper extends Area2D

func start_warp() -> void:
	if is_multiplayer_authority():
		rpc_warp.rpc(randi())

@rpc("authority", "call_local")
func rpc_warp(_seed:int) -> void:
	var s : Surface = Surfaces.create_surface(_seed)
	Surfaces.set_active_surface(s)
	for body : Node2D in get_overlapping_bodies():
		body.reparent(s)
