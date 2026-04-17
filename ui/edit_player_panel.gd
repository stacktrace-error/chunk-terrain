extends HBoxContainer

func _ready() -> void:
	%ColorPickerButton.color = Color(Settings.read("player_color"))
	%Nickname.text = Settings.read("player_name")

func _on_nickname_text_changed(new_text: String) -> void:
	Settings.write("player_name", new_text)

func _on_color_picker_button_color_changed(color: Color) -> void:
	Settings.write("player_color", color.to_html(false))
