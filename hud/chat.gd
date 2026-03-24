extends Control

var full : bool = false:
	set(x):
		full = x
		%Full.visible = x
		%Recent.visible = !x
		if full: %ChatInput.grab_focus()

var recent : Array[String] = ["[color=gray]Press [Enter] to open or close in-game chat.[/color]"]
var fade_tween : Tween

const max_recent : int = 7
const recent_fade_time : float = 10

func _ready() -> void:
	Multiplayer.game_started.connect(show_recent)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"): 
		full = !full
	if event.is_action_pressed("ui_cancel"): 
		full = false
		get_viewport().set_input_as_handled()

func show_recent() -> void:
	if !full: %Recent.show()
	%Recent.modulate = Color.WHITE
	
	if fade_tween: fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(%Recent, "modulate", Color.TRANSPARENT, recent_fade_time)
	fade_tween.tween_callback(%Recent.hide)

@rpc("any_peer", "call_local")
func send_message(player:int, message:String) -> void:
	var final : String = str("[color=gray]", player, "[/color]: ", message)
	
	if recent.size() >= max_recent: recent.pop_front()
	recent.append(final)
	
	%RecentChat.clear()
	var br : String = ""
	for line : String in recent:
		%RecentChat.append_text(br + line)
		br = "\n"
	
	%ChatText.append_text("\n" + final)
	show_recent()

func _on_chat_input_text_submitted(new_text: String) -> void:
	if new_text != "":
		send_message.rpc(multiplayer.get_unique_id(), new_text)
	
	%ChatInput.clear()
	full = false
