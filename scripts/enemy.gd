extends CharacterBody3D

const SPEED := 2.7
func _physics_process(delta: float) -> void:
	var target: CharacterBody3D = get_parent().player
	if not is_instance_valid(target):
		return
	var direction := target.global_position - global_position
	direction.y = 0
	if direction.length() > 1.5:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 20.0 * delta
	move_and_slide()
