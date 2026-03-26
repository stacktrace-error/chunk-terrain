extends Control

func _ready() -> void:
	Lobby.player_ready.connect(hide)
	
	var args : Dictionary[String, String] = Util.launch_args
	if "host" in args: Lobby.host_parse_port(args["host"])
	elif "join" in args: Lobby.join_parse_port(args["join"])

func _on_host_submit() -> void:
	Lobby.host_parse_port(%HostPort.text)

func _on_join_submit() -> void:
	Lobby.join_parse_port(%JoinAddress.text)

func update_status(status:MultiplayerPeer.ConnectionStatus) -> void:
	%StatusText.show()
	match status:
		MultiplayerPeer.CONNECTION_DISCONNECTED: %StatusText.text = "Not Connected."
		MultiplayerPeer.CONNECTION_CONNECTING: %StatusText.text = "Connecting."
		MultiplayerPeer.CONNECTION_CONNECTED: %StatusText.text = "Connected."
