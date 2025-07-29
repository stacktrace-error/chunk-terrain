extends Node2D
class_name Entity

func _enter_tree():
	var world = get_parent()
	if world is World:
		world.entities[name.to_int()] = self
