class_name Chat extends Control

var full : bool = false:
	set(x):
		if x:
			var p : Dictionary = Lobby.local_player()
			if !p: return # Cannot open chat if not in a game.
			%ChatInput.grab_focus()
			%ChatInput.placeholder_text = p.nickname + ":"
		full = x
		%Full.visible = x
		%Recent.visible = !x

var recent : Array[String] = [tr(&"chat_hint_open")]
var fade_tween : Tween

const max_recent : int = 7
const recent_fade_time : float = 10

func _ready() -> void:
	hide_parts()
	Surfaces.world_created.connect(show_recent)
	Surfaces.world_closed.connect(clear)
	Surfaces.world_closed.connect(hide_parts)

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

func send_message(player:int, message:String) -> void:
	rpc_msg.rpc(str(Lobby.get_colored_name(player), ": ", message))

func send_unsigned_message(message:String) -> void:
	rpc_msg.rpc(message)

@rpc("any_peer", "call_local")
func rpc_msg(message:String) -> void:
	#multiplayer.get_remote_sender_id()
	add_message(message)

func add_message(message:String) -> void:
	if recent.size() >= max_recent: recent.pop_front()
	recent.append(message)
	
	%RecentChat.clear()
	var br : String = ""
	for line : String in recent:
		%RecentChat.append_text(br + line)
		br = "\n"
	
	%ChatText.append_text("\n" + message)
	show_recent()

func _on_chat_input_text_submitted(new_text: String) -> void:
	if new_text != "":
		send_message(multiplayer.get_unique_id(), new_text)
	
	%ChatInput.clear()
	full = false

func clear() -> void:
	recent.clear()
	%RecentChat.clear()
	%ChatText.clear()

func hide_parts() -> void:
	%Recent.hide()
	%Full.hide()
