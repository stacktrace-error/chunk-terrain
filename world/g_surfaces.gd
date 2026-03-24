extends Node

signal surface_created

var spawn_point : Node2D

func _ready() -> void:
	Multiplayer.game_started.connect(create_surface)

func create_surface() -> void:
	var s : Surface = Surface.new()
	s.tile_set = load("res://assets/tiles/tileset.tres")
	s.noise = load("res://assets/new_fast_noise_lite.tres")
	s.generation_seed = 3
	spawn_point = s
	surface_created.emit()
	add_child(s)

func get_parent_surface(node:Node) -> Surface:
	while node:
		if node is Surface: 
			return node
		node = node.get_parent()
	return null
