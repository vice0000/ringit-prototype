extends Node2D

var can_restart := true

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		if not can_restart: return
		if self.get_parent(): self.get_parent().message("restart")

func message(msg:String, _sender:Node = null):
	match msg:
		"restart":
			if not can_restart: return
			if self.get_parent(): self.get_parent().message("restart")
		"pause":
			pass
		"nextlevel":
			if self.get_parent(): self.get_parent().message("nextlevel")
