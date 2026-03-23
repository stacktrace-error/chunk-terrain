extends Node

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene = load("res://entities/player/player.tscn")

func host_parse_port(port_string:String="") -> void:
	var port : int = 13500
	if !port_string.is_empty(): port = port_string.to_int()
	host(port)

func host(port:int=13500) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	DisplayServer.window_set_title.call_deferred("hosting")

func join_parse_port(address:String="localhost") -> void:
	var split : PackedStringArray = address.rsplit(":", false, 1)
	var port : int = 13500
	
	if split.size() > 1: port = split[1].to_int()
	join(split[0], port)

func join(address:String="localhost", port:int=13500) -> void:
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	DisplayServer.window_set_title.call_deferred("joined")

func add_player(id : int = 1) -> void:
	var player : Player = player_scene.instantiate()
	player.name = str("Player ", id)
	GameWorld.add_child.call_deferred(player)
