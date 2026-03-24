extends CanvasLayer

@onready var chat : Chat = %Chat
@onready var warp_panel : WarpPanel = %WarpPanel
@export var warp_button : Button

func _ready() -> void:
	hide()
	Multiplayer.game_started.connect(show)
