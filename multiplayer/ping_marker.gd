class_name PingMarker extends Node2D

const points : PackedVector2Array = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
const fade_time : float = 5
const default_radius : float = 50

static func create(player:int, g_pos:Vector2, radius:float=-1, lifetime:float=20) -> Node2D:
	var ping : PingMarker = preload("res://multiplayer/ping_marker.tscn").instantiate()
	ping.setup(player, g_pos, radius, lifetime)
	return ping

func setup(player:int, g_pos:Vector2, radius:float=-1, lifetime:float=20) -> void:
	global_position = g_pos
	
	if radius < 0: radius = default_radius
	
	%Text.text = Lobby.get_colored_name(player)
	%Text.position.y = -50 - radius * 0.44
	
	var p : PackedVector2Array = points.duplicate()
	for i : int in p.size(): p[i] *= radius
	
	%Circle.points = p
	%CircleColor.points = p
	%CircleColor.default_color = Color(Lobby.players[player].nickname_color)
	
	var tween : Tween = create_tween()
	tween.tween_interval(lifetime - fade_time)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_time)
	tween.tween_callback(self.free)
