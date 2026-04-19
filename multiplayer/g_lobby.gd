extends Node

@warning_ignore("unused_signal")
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)

@warning_ignore("int_as_enum_without_cast")
var connection_status : MultiplayerPeer.ConnectionStatus = 0:
	set(x):
		if(connection_status != x):
			connection_status = x
			connection_status_changed.emit(x)

var players : Dictionary[int, Player] = {}

const default_port : int = 13500


func _ready() -> void:
	var args : Dictionary[String, PackedStringArray] = Util.launch_args
	if args.has("host"): host(args["host"][0])
	elif args.has("join"): join(args["join"][0])
	
	if args.has("load") or args.has("new_game"): start_game()


func _process(_delta: float) -> void:
	var p : MultiplayerPeer = multiplayer.multiplayer_peer
	if p is ENetMultiplayerPeer and !multiplayer.is_server(): connection_status = p.get_connection_status()


func host(port_var:Variant=default_port) -> void:
	var port : int = int(port_var)
	if !port: port = default_port
	
	Settings.write("last_host_port", str(port))
	
	var sm : SceneMultiplayer = multiplayer as SceneMultiplayer
	sm.auth_callback = auth_serverside
	sm.peer_connected.connect(on_peer_connected)
	sm.peer_disconnected.connect(on_peer_disconnected)
	sm.peer_authenticating.connect(on_peer_authenticating)
	
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_server(port) == OK:
		multiplayer.multiplayer_peer = peer
		
		DisplayServer.window_set_title.call_deferred("hosting")
	else:
		disconnect_signals()


func join(address_with_optional_port:String=str("localhost:",default_port)) -> void:
	quit()
	
	Settings.write("last_join_ip", address_with_optional_port)
	var split : PackedStringArray = address_with_optional_port.rsplit(":", false, 1)
	var address : String = address_with_optional_port
	var port : int = default_port
	if split.size() > 1: 
		address = split[0]
		port = int(split[1])
	
	var sm : SceneMultiplayer = multiplayer as SceneMultiplayer
	sm.auth_callback = auth_clientside
	sm.server_disconnected.connect(quit)
	
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_client(address, port) == OK: 
		multiplayer.multiplayer_peer = peer
		
		DisplayServer.window_set_title.call_deferred(str(address, ":", port))
		
		@warning_ignore("int_as_enum_without_cast")
		connection_status = 1
	else:
		disconnect_signals()


func auth_serverside(id:int, data:PackedByteArray) -> void:
	if data and !data.is_empty() and data[0] == 255:
		multiplayer.complete_auth(id)
		spawn_player(id, data)

func auth_clientside(id:int, _data:PackedByteArray) -> void:
	multiplayer.send_auth(id, Player.create_as_packet())
	multiplayer.complete_auth(id)

func spawn_player(id:int, player_packet:PackedByteArray) -> void:
	if !multiplayer.is_server(): return
	
	var p : Player = Player.from_packet(player_packet)
	p.id = id
	p.name = str(id)
	add_child(p, true)

func on_peer_authenticating(id:int) -> void:
	multiplayer.send_auth(id, "g".to_utf8_buffer())

func on_peer_connected(id:int) -> void:
	Surfaces.on_peer_connected(id)

func on_peer_disconnected(id:int) -> void:
	if players.has(id):
		players[id].queue_free()

func start_game() -> void:
	if players.is_empty(): 
		spawn_player(1, Player.create_as_packet())
		Surfaces.on_peer_connected(1)

## ffs. 
func disconnect_signals() -> void:
	Util.check_disconnect(multiplayer.server_disconnected, quit)
	Util.check_disconnect(multiplayer.peer_connected, on_peer_connected)
	Util.check_disconnect(multiplayer.peer_disconnected, on_peer_disconnected)
	Util.check_disconnect(multiplayer.peer_authenticating, on_peer_authenticating)

func quit() -> void:
	disconnect_signals()
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	for player : Player in players.values(): player.queue_free()
	players.clear()
	Surfaces.clear()

func local_player() -> Player:
	return players.get(multiplayer.get_unique_id())
