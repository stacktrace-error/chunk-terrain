extends CanvasLayer

func _ready() -> void:
	%QuitButton.pressed.connect(Lobby.quit)
	%SaveButton.pressed.connect(Surfaces.save)
	%SaveAsButton.pressed.connect(%SaveDialog.popup_centered_clamped)
	
	%SaveDialog.file_selected.connect(Surfaces.save_as)
	
	Surfaces.world_closed.connect(hide)
	hide()


func on_host_submitted() -> void:
	Lobby.host_parse_port(%HostPort.text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		visible = !visible
