extends Node2D

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ping"):
		place_marker.rpc(multiplayer.get_unique_id(), get_global_mouse_position())

@rpc("any_peer", "call_local")
func place_marker(player:int, g_pos:Vector2, radius:float=-1, lifetime:float=20) -> void:
	add_child(PingMarker.create(player, g_pos, radius, lifetime))
