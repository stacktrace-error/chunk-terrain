extends Node2D
class_name Entity

func _enter_tree():
	var world = get_parent()
	if world is World:
		world.entities[name.to_int()] = self

func to_chunk() -> Vector2i:
	return floor(position) / World.chunk_size #TODO get current world's chunk size
