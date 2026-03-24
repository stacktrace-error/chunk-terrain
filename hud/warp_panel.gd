class_name WarpPanel extends Control

func _ready() -> void:
	Surfaces.loaded.connect(setup)

func setup() -> void:
	if is_multiplayer_authority():
		%WarpButton.pressed.connect(Surfaces.warper.start_warp)
	else:
		%WarpButton.text = "Request warp"
		%WarpButton.pressed.connect(func()->void:
			HUD.chat.send_anonymous_message(
				str("[color=yellow]", multiplayer.get_unique_id(), " would like to warp.[/color]")
			)
		)
