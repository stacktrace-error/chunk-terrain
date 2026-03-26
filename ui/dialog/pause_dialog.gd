extends CanvasLayer

func _ready() -> void:
	#%SaveButton
	#%LoadButton
	%QuitButton.pressed.connect(Lobby.quit)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		visible = !visible
