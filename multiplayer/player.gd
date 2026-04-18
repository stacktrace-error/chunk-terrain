class_name Player extends Node

signal disconnecting

@export var id : int
@export var uid : int
@export var nickname : String
@export var color : Color

static func create_as_packet() -> PackedByteArray:
	var bytes : PackedByteArray = PackedByteArray()
	
	var override : bool = Util.launch_args.has("uid")
	var u : String = Util.launch_args["uid"][0] if override else Settings.read("uid")
	var col : Color = Color.GRAY if override else Color(Settings.read("player_color"))
	var nick : String = Util.launch_args["uid"][1] if override else Settings.read("player_name")
	
	bytes.resize(9)
	bytes[0] = 255 #packet "type" byte
	bytes.encode_u32(1, u.to_int())
	bytes.encode_s32(5, col.to_rgba32())
	bytes.append_array(nick.to_utf8_buffer())
	
	return bytes

static func from_packet(data:PackedByteArray) -> Player:
	var player : Player = preload("res://multiplayer/player.tscn").instantiate()
	
	player.uid = data.decode_u32(1)
	player.color = Color(data.decode_u32(5))
	player.nickname = data.slice(9).get_string_from_utf8()
	
	return player

func _ready() -> void:
	if !Lobby.players.has(id):
		Lobby.players[id] = self
		HUD.chat.add_message(tr("msg_player_connected") % nickname)
	else:
		print("attempted to spawn duplicate player for " + str(id))
		queue_free()

func free() -> void:
	disconnecting.emit()
	HUD.chat.add_message(tr("msg_player_disconnected") % nickname)
	Lobby.players.erase(id)
	super.free()

func colored_name() -> String:
	return str("[color=", color.to_html(), "]", nickname, "[/color]")
