extends Node

const world_files = [
	preload("res://Maps/0.tscn"),
	preload("res://Maps/1.tscn"),
	preload("res://Maps/2.tscn"),
	preload("res://Maps/3.tscn"),
	preload("res://Maps/4.tscn"),
	preload("res://Maps/5.tscn"),
	preload("res://Maps/6.tscn"),
	preload("res://Maps/7.tscn"),
	preload("res://Maps/8.tscn"),
	preload("res://Maps/9.tscn"),
	preload("res://Maps/10.tscn"),
	preload("res://Maps/11.tscn"),
	preload("res://Maps/12.tscn"),
	preload("res://Maps/13.tscn"),
	preload("res://Maps/14.tscn"),
	preload("res://Maps/15.tscn"),
	preload("res://Maps/16.tscn"),
	preload("res://Maps/17.tscn"),
	preload("res://Maps/18.tscn"),
	preload("res://Maps/end.tscn"),
]
@export var current_world_index : int = 0

var success_sound := preload("res://Sound/success.wav")
var world:Node = null
func _ready() -> void:
	if not current_world_index < len(world_files):
		var control := Control.new()
		add_child(control)
		var rich_text_label := RichTextLabel.new()
		rich_text_label.size.x = 1064.0
		rich_text_label.size.y = 160.0
		rich_text_label.position.x = 424.0
		rich_text_label.position.y = 448.0
		rich_text_label.fit_content = true
		rich_text_label.bbcode_enabled = true
		rich_text_label.text = "[font_size=50]INVALID MAP INDEX! :(\nthis message shouldn't appear.[/font_size]"
		control.add_child(rich_text_label)
		return
	if !world_files[current_world_index]:
		var control := Control.new()
		add_child(control)
		var rich_text_label := RichTextLabel.new()
		rich_text_label.size.x = 1064.0
		rich_text_label.size.y = 160.0
		rich_text_label.position.x = 424.0
		rich_text_label.position.y = 448.0
		rich_text_label.fit_content = true
		rich_text_label.bbcode_enabled = true
		rich_text_label.text = "[font_size=50]MISSING MAP FILE! :(\ndid you delete a map from the game files?[/font_size]"
		control.add_child(rich_text_label)
		return
	world = world_files[current_world_index].instantiate()
	add_child(world)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("window_screenmode"):
		swap_fullscreen_mode()

func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func message(msg:String, _sender:Node = null):
	match msg:
		"restart":
			world.can_restart = false
			world.queue_free()
			await get_tree().create_timer(0.15).timeout
			world = world_files[current_world_index].instantiate()
			add_child(world)
			world.can_restart = true
		"nextlevel":
			current_world_index += 1
			if current_world_index >= len(world_files):
				current_world_index -= 1
				return
			if not world_files[current_world_index]:
				current_world_index -= 1
				return
			
			var sound:AudioStreamPlayer = AudioStreamPlayer.new()
			sound.autoplay = true
			sound.stream = success_sound
			add_child(sound)
			sound.finished.connect(func(): sound.queue_free())
			sound.play()
			
			world.can_restart = false
			world.queue_free()
			await get_tree().create_timer(0.5).timeout
			world = world_files[current_world_index].instantiate()
			add_child(world)
			world.can_restart = true
