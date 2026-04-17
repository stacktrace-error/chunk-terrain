extends Node

var settings : Dictionary = {
	"uid" = "",
	"player_name" = "",
	"player_color" = "33ff33",
	"last_join_ip" = "",
	"last_host_port" = ""
}

func write(key:String, value:String) -> void:
	var file : FileAccess = FileAccess.open("user://settings.json", FileAccess.WRITE)
	settings[key] = value
	file.store_string(JSON.stringify(settings, ""))
	file.close()

## Doesn't actually read from the file, name is just for consistency.
func read(key:String, default:String="") -> String:
	var s : String = settings.get(key, "")
	return default if s.is_empty() else s

func _ready() -> void:
	var file : FileAccess = FileAccess.open("user://settings.json", FileAccess.READ)
	if file: 
		settings = JSON.parse_string(file.get_as_text())
		file.close()
	
	if settings.get("uid", "").is_empty(): settings["uid"] = str(randi())
