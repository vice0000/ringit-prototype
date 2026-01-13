extends StaticBody2D
var breaking := false
@export var time_till_break = 0.5
@onready var world_hitbox := $world_hitbox
@onready var texture := $texture

func _ready() -> void:
	var _on_area_entered = func(b):
		if breaking: return
		if b.get_parent():
			if b.get_parent().is_in_group("character"):
				break_block()
	world_hitbox.area_entered.connect(_on_area_entered)

func break_block() -> void:
	breaking = true
	texture.color.v /= 3
	await get_tree().create_timer(time_till_break).timeout
	self.queue_free()
