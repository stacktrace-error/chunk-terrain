class_name Player extends Node

var id : int
var nickname : String:
	get:
		if id == 1: return "Nullevoy"
		return "fuckass bum"
var color : Color = Color.GRAY
var body : PlayerBody

func _ready() -> void:
	id = name.to_int()
	set_multiplayer_authority(id)
	HUD.chat.add_message(tr("msg_player_connected") % nickname)
	
	if is_multiplayer_authority():
		Lobby.player_ready.emit()
	
	if Surfaces.active_surface == null:
		Surfaces.loaded.connect(spawn_body, CONNECT_ONE_SHOT)
	else: 
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
	return str("[color=", color.to_html(false), "]", nickname, "[/color]")

func remove() -> void:
	HUD.chat.add_message(tr("msg_player_disconnected") % nickname)
	body.queue_free()
	queue_free()
