extends Node2D
@onready var Ring := $Ring
var orb_use_particles := preload("res://rings/orb_use_particles.tscn")
var ring_enabled := true
var ring_being_carried := false
var ring_can_pickup := true
var ring_pickup_cooldown_after_use := 0.5

@onready var texture_gradient = $Ring/Texture3
var wish_opacity = 1.0
var blink_frequency = clamp(randf() * 6.0, 3.0, 5.0)

var orb_use_sound := preload("res://Sound/yellow_ring_use.wav")
var orb_take_sound := preload("res://Sound/ring_take.wav")
var orb_place_sound := preload("res://Sound/ring_place.wav")

func on_picked_up() -> void:
	pass

func set_ring_global_position(pos:Vector2) -> void:
	Ring.global_position = pos
	
func do_ring_particles():
	if not orb_use_particles: return
	var particle:CPUParticles2D = orb_use_particles.instantiate()
	particle.emitting = true
	Ring.add_child(particle)
	await particle.finished
	particle.queue_free()

func message(msg:String, _sender:Node = null):
	match msg:
		"picked_up":
			ring_enabled = false
			ring_being_carried = true
			
			on_picked_up()
			
			var sound := AudioStreamPlayer.new()
			sound.stream = orb_take_sound
			sound.volume_db -= 10
			sound.pitch_scale += randf_range(-0.25, 0.25)
			sound.finished.connect(func(): sound.queue_free())
			add_child(sound)
			sound.play()
			
		"released":
			ring_enabled = true
			ring_being_carried = false
			
			var sound := AudioStreamPlayer.new()
			sound.stream = orb_place_sound
			sound.volume_db -= 10
			sound.pitch_scale += randf_range(-0.25, 0.25)
			sound.finished.connect(func(): sound.queue_free())
			add_child(sound)
			sound.play()
			
		"used":
			do_ring_particles()
			var sound := AudioStreamPlayer.new()
			sound.stream = orb_use_sound
			sound.volume_db -= 12
			sound.pitch_scale += randf_range(-0.6, -0.4)
			sound.finished.connect(func(): sound.queue_free())
			add_child(sound)
			sound.play()
			
			texture_gradient.self_modulate.a = 1.0
			texture_gradient.modulate.v = 1.0
			if not ring_can_pickup: return
			ring_can_pickup = false
			await get_tree().create_timer(ring_pickup_cooldown_after_use).timeout
			ring_can_pickup = true
		"recalled":
			recall_ring()
			ring_can_pickup = true
			ring_enabled = true
			ring_being_carried = false

func recall_ring() -> void:
	Ring.global_position = self.global_position

func _ready() -> void:
	texture_gradient.self_modulate.a = 0.75
	Ring.add_to_group("jump_ring")
	Ring.add_to_group("ring")

func _physics_process(delta:float) -> void:
	texture_gradient.self_modulate.a = move_toward(
		texture_gradient.self_modulate.a, wish_opacity, delta / blink_frequency
	)
	texture_gradient.modulate.v = move_toward(
		texture_gradient.modulate.v, 0.33, delta
	)
	if texture_gradient.self_modulate.a == 1.0:
		wish_opacity = 0.75
	elif texture_gradient.self_modulate.a == 0.75:
		wish_opacity = 1.0
	
	
