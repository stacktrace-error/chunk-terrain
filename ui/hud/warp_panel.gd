class_name WarpPanel extends Control

#func _ready() -> void:
	#Surfaces.world_created.connect(setup)
#
#func setup() -> void:
	#if is_multiplayer_authority():
		#%WarpButton.pressed.connect(Surfaces.warper.start_warp)
	#else:
		#%WarpButton.text = "Request warp"
		#%WarpButton.pressed.connect(func()->void:
			#HUD.chat.send_unsigned_message(
				#tr(&"msg_request_warp") % multiplayer.get_unique_id()
			#)
		#)
