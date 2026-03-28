extends CanvasLayer


func _ready() -> void:
	if Lobby.has_started: hide()
	
	Lobby.game_started.connect(hide)
	Lobby.game_quitted.connect(show)
	
	visibility_changed.connect(on_visibility_changed)
	on_visibility_changed()

func on_join_submitted() -> void:
	Lobby.join_parse_port(%JoinAddress.text)

func on_visibility_changed() -> void:
	if visible:
		DisplayServer.window_set_title.call_deferred("main menu")


func _on_load_dialog_file_selected(path: String) -> void:
	Surfaces.load_from(path)
	Lobby.rpc_start_game.rpc()

func _on_new_game_pressed() -> void:
	Surfaces.new_game()
	Lobby.rpc_start_game.rpc()
