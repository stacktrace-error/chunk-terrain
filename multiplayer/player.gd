class_name Player extends Node

var body : PlayerBody

func _ready() -> void:
	set_multiplayer_authority(name.trim_prefix("Player ").to_int())
	spawn_body()

func spawn_body() -> void:
	if body: return
	
	body = preload("res://entities/player/player_body.tscn").instantiate()
	body.set_multiplayer_authority(get_multiplayer_authority())
	body.global_position = Surfaces.spawn_point.global_position
	
	body.surface_changed.connect(Surfaces.set_active_surface)
	
	if is_multiplayer_authority(): Camera.target = body
	
	Surfaces.spawn_point.add_child(body)
