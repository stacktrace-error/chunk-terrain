extends CanvasLayer

func _ready() -> void:
	hide()
	Multiplayer.game_started.connect(show)
