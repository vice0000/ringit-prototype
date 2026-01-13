extends CharacterBody2D
## https://www.youtube.com/watch?v=2S3g8CgBG1g

@export var max_speed: float = 250.0
@export var acceleration: float = 1250.0
@export var turning_acceleration : float = 10000
@export var deceleration: float = 10000.0
@export var gravity_acceleration : float = 1000.0
@export var gravity_max : float = 1250.0
@export_range(-360.0, 360.0, 0.01, "degrees") var gravity_angle_deg : float = 0
@export var rotation_speed : float = 720.0
@export var jump_force : float = 375.0
var jump_enabled := true
var is_jumping : bool = false
@onready var sprite : Node2D = $Sprite
@onready var world_hitbox : Area2D = $"World Hitbox"

var jump_smoke := preload("res://Player/jump_smoke.tscn")
var jump_trail := preload("res://Player/jump_trail.tscn")

var grab_slot : Node2D = null
var ring_buffer_unused = true

func _ready() -> void:
	add_to_group("character")

func gravity_angle():
	return deg_to_rad(gravity_angle_deg)

class PlayerInput:
	var movement:Vector2
	var just_interact:bool
	var just_jump:bool
	var jump:bool
	var released_jump:bool

func get_input() -> PlayerInput:
	var input := PlayerInput.new()
	input.movement = Input.get_vector("movement_left", "movement_right",
		"movement_up", "movement_down").normalized()
	input.just_interact = Input.is_action_just_pressed("player_interact")
	input.just_jump = Input.is_action_just_pressed("movement_jump")
	input.jump = Input.is_action_pressed("movement_jump")
	input.released_jump = Input.is_action_just_released("movement_jump")
	return input

func do_gravity(virtual_velocity_y:float, grav_accel:float,
		grav_max:float, delta:float) -> float:
	var vel_y := virtual_velocity_y
	vel_y += grav_accel * delta
	vel_y = clamp(vel_y, -INF, grav_max)
	return vel_y

func do_x_movement(virtual_velocity_x:float, virtual_movement_x:float, 
				   accel:float, decel:float, delta:float, max_vel:float,
				   turn_accel) -> float:
	var vel_x := virtual_velocity_x
	var mov_x := virtual_movement_x
	
	if mov_x < 0.1 and mov_x > -0.1:
		mov_x = 0.0
	
	if sign(mov_x) != 0.0:
		if sign(mov_x) + sign(vel_x) == 0.0: # then player is steering the other direction
			vel_x = move_toward(vel_x, max_vel * sign(mov_x), turn_accel * delta)
		else:
			vel_x = move_toward(vel_x, max_vel * sign(mov_x), accel * delta)
	else:
		vel_x = move_toward(vel_x, 0.0, decel * delta)
	return vel_x

func do_jump_start(virtual_velocity_y:float,
				   force_of_jump:float, _delta:float) -> float:
	if !jump_enabled: return virtual_velocity_y
	var vel_y := virtual_velocity_y
	vel_y = -force_of_jump
	return vel_y

func any_collisions_in_group(groupname:String) -> bool:
	for coll in world_hitbox.get_overlapping_areas():
		if coll.is_in_group(groupname): return true
	return false

func do_recall_laser():
	for coll in world_hitbox.get_overlapping_areas():
		if coll.is_in_group("recall_laser"):
			grab_slot = null
			break

func touching_jump_ring() -> Array:
	for coll in world_hitbox.get_overlapping_areas():
		if (coll.is_in_group("jump_ring") and
				coll.get_parent().ring_enabled):
			return [true, coll.get_parent()]
	return [false, null]
	
func touching_gravity_ring() -> Array:
	for coll in world_hitbox.get_overlapping_areas():
		if (coll.is_in_group("gravity_ring") and
				coll.get_parent().ring_enabled):
			return [true, coll.get_parent()]
	return [false, null]
	
func message(msg:String, sender:Node = null):
	match msg:
		"force_release":
			if grab_slot and sender == grab_slot:
				grab_slot = null
			elif sender == null:
				grab_slot = null

func do_hazard() -> void:
	if !get_parent(): return
	for coll in world_hitbox.get_overlapping_areas():
		if coll.is_in_group("hazard"):
			get_parent().message("restart")

func do_goal_flag_check() -> void:
	if !get_parent(): return
	for coll in world_hitbox.get_overlapping_areas():
		if coll.is_in_group("goal"):
			get_parent().message("nextlevel")
	pass

func _physics_process(delta: float) -> void:
	do_goal_flag_check()
	do_hazard()
	
	if get_input().released_jump:
		ring_buffer_unused = true
		
	if grab_slot != null:
		grab_slot.set_ring_global_position(global_position)
	if get_input().just_interact:
		var prev_grab_slot := grab_slot
		if grab_slot:
			grab_slot.message("released")
			grab_slot = null
		for coll in world_hitbox.get_overlapping_areas():
			if coll.is_in_group("ring"):
				if coll.get_parent() == prev_grab_slot: continue
				if not coll.get_parent().ring_can_pickup: continue
				grab_slot = coll.get_parent()
				grab_slot.message("picked_up")
				break
	
	up_direction = Vector2.UP.rotated(-gravity_angle())
	rotation_degrees = -gravity_angle_deg
	var virtual_velocity := velocity.rotated(gravity_angle())
	var virtual_movement := get_input().movement.rotated(gravity_angle())
	
	var do_jump_smoke = func():
		var smoke:CPUParticles2D = jump_smoke.instantiate()
		smoke.position.y += 15
		smoke.rotation = sprite.rotation
		add_child(smoke)
		smoke.emitting = true
		await smoke.finished
		smoke.queue_free()
	var do_jump_trail = func():
		var trail:CPUParticles2D = jump_trail.instantiate()
		trail.rotation = sprite.rotation
		trail.direction = -(velocity.normalized())
		add_child(trail)
		trail.emitting = true
		await trail.finished
		trail.queue_free()
	
	if (get_input().jump and ring_buffer_unused) and touching_jump_ring()[0]:
		do_jump_trail.call()
		ring_buffer_unused = false
		var this_ring = touching_jump_ring()[1]
		this_ring.message("used")
		virtual_velocity.y = do_jump_start(virtual_velocity.y,
										   jump_force, delta)
	elif (get_input().jump and ring_buffer_unused) and touching_gravity_ring()[0]:
		ring_buffer_unused = false
		do_jump_trail.call()
		var this_ring = touching_gravity_ring()[1]
		this_ring.message("used")
		if gravity_angle_deg == this_ring.angle_A:
			var prev_angle = gravity_angle_deg
			gravity_angle_deg = this_ring.angle_B
			virtual_velocity = virtual_velocity.rotated(
				deg_to_rad(prev_angle - gravity_angle_deg))
			virtual_velocity.y = 100
		elif gravity_angle_deg == this_ring.angle_B:
			var prev_angle = gravity_angle_deg
			gravity_angle_deg = this_ring.angle_A
			virtual_velocity = virtual_velocity.rotated(
				deg_to_rad(prev_angle - gravity_angle_deg))
			virtual_velocity.y = 100
	elif get_input().jump and is_on_floor():
		do_jump_smoke.call()
		do_jump_trail.call()
		ring_buffer_unused = false
		virtual_velocity.y = do_jump_start(virtual_velocity.y,
										   jump_force, delta)
	
	if not is_on_floor():
		virtual_velocity.y = do_gravity(virtual_velocity.y,
										gravity_acceleration, gravity_max,
										delta)
	
	virtual_velocity.x = do_x_movement(virtual_velocity.x, virtual_movement.x,
									   acceleration, deceleration, delta,
									   max_speed, turning_acceleration)
	
	velocity = virtual_velocity.rotated(-gravity_angle())
	move_and_slide()
