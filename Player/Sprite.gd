extends Node2D
# This is a hacky way of doing animation
# I do not advise you using this in real projects
# Instead learn how to use a STATE MACHINE
# https://www.youtube.com/results?search_query=godot+state+machine
# Choose a video of your liking

@export var player_path : NodePath
@onready var Player := get_node(player_path)
@onready var Animator := $AnimationPlayer

var step := preload("res://Sound/step.wav")
var jump_whoosh := preload("res://Sound/jump_whoosh.mp3")

var previous_frame_velocity := Vector2(0,0)
var previous_frame_is_on_floor := false
# Avoid errors
func _ready() -> void:
	if Player == null:
		print("Sprite.gd is missing player_path")
		set_process(false)


func _process(_delta: float) -> void:
	if previous_frame_velocity.y >= 0 and Player.velocity.rotated(Player.gravity_angle()).y < 0.0:
		Animator.play("Jump")
		if previous_frame_is_on_floor:
			var sound := AudioStreamPlayer.new()
			sound.stream = jump_whoosh
			sound.volume_db -= 10
			sound.pitch_scale += randf_range(0.0, 0.6)
			sound.finished.connect(func(): sound.queue_free())
			add_child(sound)
			sound.play()
	elif previous_frame_velocity.y > 0.0 and Player.is_on_floor():
		Animator.play("Land")
		var sound := AudioStreamPlayer.new()
		sound.stream = step
		sound.volume_db += 3
		sound.pitch_scale += randf_range(0.3, 0.5)
		sound.finished.connect(func(): sound.queue_free())
		add_child(sound)
		sound.play()
	
	previous_frame_is_on_floor = Player.is_on_floor()
	previous_frame_velocity = Player.velocity.rotated(Player.gravity_angle())
