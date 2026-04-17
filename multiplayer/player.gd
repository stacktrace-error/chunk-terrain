class_name Player extends Node

@export var id : int
@export var uid : int
@export var nickname : String
@export var color : Color


static func create_as_byte_array() -> PackedByteArray:
	var bytes : PackedByteArray = PackedByteArray()
	
	var override : bool = Util.launch_args.has("uid")
	var u : String = Util.launch_args["uid"][0] if override else Settings.read("uid")
	var col : Color = Color.GRAY if override else Color(Settings.read("player_color"))
	var nick : String = Util.launch_args["uid"][1] if override else Settings.read("player_name")
	
	bytes.resize(8)
	bytes.encode_u32(0, u.to_int())
	bytes.encode_s32(4, col.to_rgba32())
	bytes.append_array(nick.to_utf8_buffer())
	
	return bytes

static func from_byte_array(data:PackedByteArray) -> Player:
	var player : Player = new()
	
	player.uid = data.decode_u32(0)
	player.color = Color(data.decode_u32(4))
	player.nickname = data.slice(8).get_string_from_utf8()
	
	return player

func colored_name() -> String:
	return str("[color=", color.to_html(), "]", nickname, "[/color]")
