extends CharacterBody3D

const SPEED := 5.5
func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var world := get_parent()
	if world.joy.length() > 0.08:
		input = world.joy
	var direction := Vector3(input.x, 0, input.y)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	velocity.y -= 20.0 * delta
	if direction.length() > 0.1:
		rotation.y = atan2(direction.x, direction.z)
	move_and_slide()
	if Input.is_action_just_pressed("place_trap"):
		world.place_trap()
