extends Node

signal loaded

var spawn_point : Node2D
var warper : Warper

var active_surface : Surface:
	set(x):
		if active_surface:
			active_surface.collision_enabled = false
			active_surface.hide()
		active_surface = x
		x.collision_enabled = true
		x.show()

func _ready() -> void:
	Lobby.game_started.connect(on_game_start)

func on_game_start() -> void:
	set_active_surface(create_surface(3))
	
	warper = load("res://entities/warper.tscn").instantiate()
	spawn_point = warper
	active_surface.add_child.call_deferred(warper)
	
	loaded.emit()

func clear() -> void:
	for child : Node in get_children(): child.free()
	
	spawn_point = null
	warper = null

func create_surface(_seed:int) -> Surface:
	var s : Surface = Surface.new()
	s.tile_set = load("res://assets/tiles/tileset.tres")
	s.noise = load("res://assets/new_fast_noise_lite.tres")
	s.generation_seed = _seed
	add_child(s)
	return s

func get_parent_surface(node:Node) -> Surface:
	while node:
		if node is Surface: 
			return node
		node = node.get_parent()
	return null

func set_active_surface(surface:Surface) -> void: active_surface = surface
