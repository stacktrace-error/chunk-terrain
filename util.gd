extends Node

## Contains launch arguments in an easily accessible format. Ignores leading gibberish.
## Arguments like " ggffa!!!!! --host 6567 8882 --scene=gtgftgdff" are turned into
## {
##     "host" = "6567 8882",
##     "scene" = "gtgftgdff"
## }
var launch_args : Dictionary[String, String] = {}

func _ready() -> void:
	var args : PackedStringArray = OS.get_cmdline_args()
	var last_key : String
	var i : int = 0
	
	while i < args.size():
		var arg : String = args[i]
		
		if arg.contains("--"):
			var key : String = arg
			var value : String = ""
			
			if arg.contains("="): 
				var split = arg.split("=", false, 1)
				key = split[0]
				value = split[1]

			key = key.trim_prefix("--")
			last_key = key
			launch_args[key] = value
		elif last_key:
			if launch_args[last_key] != "": arg = " " + arg
			launch_args[last_key] += arg
		
		i += 1
