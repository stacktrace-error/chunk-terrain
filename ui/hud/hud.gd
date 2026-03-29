extends CanvasLayer

@onready var chat : Chat = %Chat
@onready var warp_panel : WarpPanel = %WarpPanel
@export var warp_button : Button

func _ready() -> void:
	for child : Control in get_children():
		child.hide()
	chat.show()
