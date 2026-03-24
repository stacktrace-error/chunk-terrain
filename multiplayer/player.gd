class_name Player extends Node

var nickname : String
var color : Color = Color.GRAY
var body : PlayerBody

func _ready() -> void:
	var id : int = name.trim_prefix("Player ").to_int()
	set_multiplayer_authority(id)
	HUD.chat.add_message(tr("msg_player_connected") % nickname)
	spawn_body()

func spawn_body() -> void:
	if body: return
	
	body = preload("res://entities/player/player_body.tscn").instantiate()
	body.set_multiplayer_authority(get_multiplayer_authority())
	body.global_position = Surfaces.spawn_point.global_position
	
	body.surface_changed.connect(Surfaces.set_active_surface)
	
	if is_multiplayer_authority(): Camera.target = body
	
	Surfaces.spawn_point.add_child(body)

func get_colored_name() -> String:
	return str("[color=", color, "]", nickname, "[/color]")
