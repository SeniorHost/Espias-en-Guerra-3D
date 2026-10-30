extends CharacterBody3D

const RUN_SPEED := 5.5
const WALK_SPEED := 2.8
const SNEAK_SPEED := 1.25
const ACCELERATION := 16.0
const FRICTION := 21.0
const JUMP_VELOCITY := 6.0
const GRAVITY := 20.0

func _physics_process(delta: float) -> void:
	var world = get_parent()
	var axis: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if world.touch_id != -1:
		axis = world.joy
	var camera: Camera3D = world.follow_camera
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * axis.x - forward * axis.y).normalized()
	var strength := clampf(axis.length(), 0.0, 1.0)
	var speed := RUN_SPEED
	if strength < 0.36:
		speed = SNEAK_SPEED
	elif strength < 0.76:
		speed = WALK_SPEED
	var target := direction * speed * strength
	var rate := ACCELERATION if strength > 0.08 else FRICTION
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1
	if (world.jump_requested or Input.is_action_just_pressed("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	world.jump_requested = false
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), clampf(12.0 * delta, 0.0, 1.0))
	move_and_slide()
	if Input.is_action_just_pressed("place_trap"):
		world.place_trap()
