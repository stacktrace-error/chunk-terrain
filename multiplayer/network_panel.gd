extends Control

func _ready() -> void:
	Multiplayer.hosted.connect(hide)
	multiplayer.connected_to_server.connect(hide)
	
	var args : Dictionary[String, String] = Util.launch_args
	if "host" in args: Multiplayer.host_parse_port(args["host"])
	elif "join" in args: Multiplayer.join_parse_port(args["join"])

func _on_host_submit() -> void:
	Multiplayer.host_parse_port(%HostPort.text)

func _on_join_submit() -> void:
	Multiplayer.join_parse_port(%JoinAddress.text)

func update_status(status:MultiplayerPeer.ConnectionStatus):
	%StatusText.show()
	match status:
		MultiplayerPeer.CONNECTION_DISCONNECTED: %StatusText.text = "Not Connected."
		MultiplayerPeer.CONNECTION_CONNECTING: %StatusText.text = "Connecting."
		MultiplayerPeer.CONNECTION_CONNECTED: %StatusText.text = "Connected."
