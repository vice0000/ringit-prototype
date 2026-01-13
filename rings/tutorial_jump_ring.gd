extends "res://rings/jump_ring.gd"

func on_picked_up() -> void:
	if not find_child("Button Hint"): return
	$"Button Hint".queue_free()
