extends Node

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene = load("res://entities/player/player.tscn")

func _ready() -> void:
	var args : PackedStringArray = OS.get_cmdline_args()
	if "--host" in args: host()
	elif "--join" in args: join()


func _on_join_button_pressed() -> void:
	var split : PackedStringArray = %JoinAddress.text.rsplit(":", false, 1)
	var port : int = 13500
	
	if split.size() > 1: port = split[1].to_int()
	join(split[0], port)


func _on_host_button_pressed() -> void:
	var port : int = 13500
	if %HostPort.text != "": port = %HostPort.text.to_int()
	
	host(port)


func host(port:int=13500) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	DisplayServer.window_set_title.call_deferred("hosting")
	%NetworkPanel.hide()

func join(address:String="localhost", port:int=13500) -> void:
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	DisplayServer.window_set_title.call_deferred("joined")
	%NetworkPanel.hide()

func add_player(id : int = 1) -> void:
	var player : Player = player_scene.instantiate()
	player.name = str("Player ", id)
	GameWorld.add_child.call_deferred(player)
