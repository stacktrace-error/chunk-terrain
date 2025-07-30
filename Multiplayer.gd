extends Node

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene = load("res://entities/player/player.tscn")

func _ready() -> void:
	var args : PackedStringArray = OS.get_cmdline_args()
	if "--host" in args: _on_host_pressed()
	elif "--join" in args: _on_join_pressed()

func _on_host_pressed() -> void:
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	DisplayServer.window_set_title.call_deferred("hosting")

func _on_join_pressed() -> void:
	peer.create_client("localhost", 135)
	multiplayer.multiplayer_peer = peer
	DisplayServer.window_set_title.call_deferred("joined")

func add_player(id : int = 1) -> void:
	var player : Player = player_scene.instantiate()
	player.name = str("Player ", id)
	GameWorld.add_child.call_deferred(player)
