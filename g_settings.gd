extends Node

var settings : Dictionary = {
	"nickname" = "",
	"nickname_color" = "33ff33",
	"last_join_ip" = "",
	"last_host_port" = ""
}

func write_setting(key:String, value:String) -> void:
	var file : FileAccess = FileAccess.open("user://settings.json", FileAccess.WRITE)
	settings[key] = value
	file.store_string(JSON.stringify(settings, ""))
	file.close()

## Doesn't actually read, name is just for consistency.
func read_setting(key:String) -> String:
	return settings.get(key, "")

func get_player() -> Dictionary:
	return {
		"nickname" = settings["nickname"],
		"nickname_color" = settings["nickname_color"],
	} if !Util.launch_args.has("no-name") else {
		"nickname" = str(multiplayer.get_unique_id()),
		"nickname_color" = "bebebe"
	}

func _ready() -> void:
	var file : FileAccess = FileAccess.open("user://settings.json", FileAccess.READ)
	if file: 
		settings = JSON.parse_string(file.get_as_text())
		file.close()
