extends TabContainer

func _ready() -> void:
	var args : Dictionary[String, String] = Util.launch_args
	
	if "host" in args: Multiplayer.host_parse_port(args["host"])
	elif "join" in args: Multiplayer.join_parse_port(args["host"])

func _on_join_button_pressed() -> void:
	Multiplayer.join_parse_port(%JoinAddress.text)
	hide()

func _on_host_button_pressed() -> void:
	Multiplayer.host_parse_port(%HostPort.text)
	hide()
