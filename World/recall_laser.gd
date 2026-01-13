extends Area2D

@onready var player:CharacterBody2D = null
@onready var particles:CPUParticles2D = $particles
@onready var glow:Sprite2D = $glow

var fizzle_sound := preload("res://Sound/fizzle.mp3")

func _ready() -> void:
	var world = find_parent("World")
	if world: player = world.find_child("Player")
	add_to_group("recall_laser")

func recall_animation() -> void:
	glow.self_modulate.a += 0.2
	particles.speed_scale = 2.0
	
	var sound := AudioStreamPlayer.new()
	sound.stream = fizzle_sound
	sound.volume_db += 1
	#sound.pitch_scale += randf_range(-0.25, 0.25)
	sound.finished.connect(func(): sound.queue_free())
	add_child(sound)
	sound.play()
	
	await get_tree().create_timer(1.0).timeout
	particles.speed_scale = 1.0
	glow.self_modulate.a -= 0.2

func _physics_process(_delta: float) -> void:
	if not player:
		var world = find_parent("World")
		if world: player = world.find_child("Player")
	for coll in get_overlapping_areas():
		if coll.is_in_group("ring"):
			coll.get_parent().message("recalled")
			recall_animation()
			if player:
				player.message("force_release", coll.get_parent())
			break
