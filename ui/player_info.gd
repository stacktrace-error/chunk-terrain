extends HBoxContainer

func _ready() -> void:
	%ColorPickerButton.color = Color(Settings.read_setting("nickname_color"))
	%Nickname.text = Settings.read_setting("nickname")


func _on_nickname_text_changed(new_text: String) -> void:
	Settings.write_setting("nickname", new_text)


func _on_color_picker_button_color_changed(color: Color) -> void:
	Settings.write_setting("nickname_color", color.to_html(false))
