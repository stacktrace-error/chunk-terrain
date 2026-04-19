extends CanvasLayer


func _ready() -> void:
	Surfaces.world_created.connect(hide)
	Surfaces.world_closed.connect(show)
	
	hide()
	#visibility_changed.connect(on_visibility_changed)
	if !Surfaces.has_world: show()
	on_visibility_changed()
	
	%JoinAddress.text = Settings.read("last_join_ip")
	%HostPort.text = Settings.read("last_host_port")

func on_join_submitted() -> void:
	Lobby.join(%JoinAddress.text)

func on_visibility_changed() -> void:
	if visible && Lobby.connection_status == 0:
		DisplayServer.window_set_title.call_deferred("main menu")


func _on_load_dialog_file_selected(path: String) -> void:
	Surfaces.load_from(path)
	if(%HostCheckbox.button_pressed): Lobby.host(%HostPort.text)
	Lobby.start_game()

func _on_new_game_pressed() -> void:
	Surfaces.new_game()
	if(%HostCheckbox.button_pressed): Lobby.host(%HostPort.text)
	Lobby.start_game()
