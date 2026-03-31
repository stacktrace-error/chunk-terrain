extends CanvasLayer


func _ready() -> void:
	if Surfaces.has_world: hide()
	
	Surfaces.world_created.connect(hide)
	Surfaces.world_closed.connect(show)
	
	%JoinAddress.text = Settings.read_setting("last_join_ip")
	
	visibility_changed.connect(on_visibility_changed)
	on_visibility_changed()

func on_join_submitted() -> void:
	Lobby.join_parse_port(%JoinAddress.text)

func on_visibility_changed() -> void:
	if visible:
		DisplayServer.window_set_title.call_deferred("main menu")


func _on_load_dialog_file_selected(path: String) -> void:
	Surfaces.load_from(path)
	Lobby.start_game()

func _on_new_game_pressed() -> void:
	Surfaces.new_game()
	Lobby.start_game()
