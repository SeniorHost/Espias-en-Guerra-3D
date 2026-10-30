extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
var player: CharacterBody3D
var enemy: CharacterBody3D
var traps: Array[Area3D] = []
var joy := Vector2.ZERO
var touch_origin := Vector2.ZERO
var touch_id := -1
var hud: Label
var follow_camera: Camera3D
var jump_requested := false
var camera_yaw := 0.0
var camera_pitch := -0.28
var camera_distance := 4.5
var camera_smoothing := 7.0
var camera_touch_id := -1
var camera_collision: SpringArm3D
var joystick_base: Control
var joystick_knob: Control

func _ready() -> void:
	_make_world()
	player = _make_actor(Color(0.9, 0.9, 0.95), Vector3(-4, 0, 0), false)
	enemy = _make_actor(Color(0.12, 0.12, 0.17), Vector3(4, 0, 0), true)
	_make_camera()
	_make_hud()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(follow_camera):
		return
	var focus := player.global_position + Vector3(0, 1.35, 0)
	var offset := Vector3(sin(camera_yaw) * cos(camera_pitch), -sin(camera_pitch), cos(camera_yaw) * cos(camera_pitch)) * camera_distance
	var desired := focus + offset
	var query := PhysicsRayQueryParameters3D.create(focus, desired)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = focus + (hit.position - focus).normalized() * maxf(0.35, focus.distance_to(hit.position) - 0.2)
	follow_camera.global_position = follow_camera.global_position.lerp(desired, clampf(delta * camera_smoothing, 0.0, 1.0))
	follow_camera.look_at(focus, Vector3.UP)
	_animate_spy(player, delta)
	_animate_spy(enemy, delta)
	if is_instance_valid(joystick_knob):
		joystick_knob.position = Vector2(joy.x, joy.y) * 42.0 + Vector2(49, 49)

func _animate_spy(actor: CharacterBody3D, delta: float) -> void:
	if not is_instance_valid(actor):
		return
	var visual := actor.get_node_or_null("SpyVisual") as Node3D
	if visual == null:
		return
	var horizontal_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var moving := horizontal_speed > 0.12 and actor.is_on_floor()
	var sneaking := horizontal_speed < 1.2
	var walking := horizontal_speed < 3.2
	var cadence := 3.2 if sneaking else (5.2 if walking else 8.5)
	var amplitude := 0.24 if sneaking else (0.44 if walking else 0.75)
	var time := float(actor.get_meta("step_clock", 0.0))
	if moving:
		time += delta * cadence
	actor.set_meta("step_clock", time)
	var weight := clampf(horizontal_speed / 1.5, 0.0, 1.0) if moving else 0.0
	var stride := sin(time) * amplitude * weight
	var arm_swing := stride * (0.35 if sneaking else 0.72)
	var settle := clampf(delta * 12.0, 0.0, 1.0)
	for name in ["LegL", "LegR", "ArmL", "ArmR"]:
		var joint := visual.get_node_or_null(name) as Node3D
		if joint == null:
			continue
		var side := 1.0 if name.ends_with("L") else -1.0
		var target := stride * side if name.begins_with("Leg") else -arm_swing * side
		joint.rotation.x = lerpf(joint.rotation.x, target, settle)
	var crouch := -0.10 if moving and sneaking else 0.0
	var bob := absf(sin(time)) * (0.025 if sneaking else (0.045 if walking else 0.075)) * weight
	visual.position.y = lerpf(visual.position.y, crouch + bob, settle)
	visual.rotation.z = lerpf(visual.rotation.z, sin(time) * 0.025 * weight, settle)
	visual.rotation.x = lerpf(visual.rotation.x, -0.08 if moving and sneaking else 0.0, settle)

func _make_world() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	add_child(light)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.35, 0.45)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.8)
	env.environment = e
	add_child(env)
	_make_box(Vector3(0,-0.25,0), Vector3(24,0.5,24), Color(0.43,0.46,0.48))
	for i in range(5):
		_make_box(Vector3(-8+i*4,1,-11), Vector3(1.5,2,1), Color(0.57,0.36,0.25))
	for p in [Vector3(-5,0.6,-5), Vector3(5,0.6,-5), Vector3(-6,0.6,5), Vector3(6,0.6,4)]:
		_make_box(p, Vector3(2.5,1.2,1.5), Color(0.28,0.38,0.48))
	for x in [-12.0, 12.0]:
		_make_box(Vector3(x,1,0), Vector3(0.5,2,24), Color(0.65,0.64,0.59))
	for z in [-12.0, 12.0]:
		_make_box(Vector3(0,1,z), Vector3(24,2,0.5), Color(0.65,0.64,0.59))

func _make_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mesh.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)

func _make_actor(color: Color, pos: Vector3, is_enemy: bool) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.position = pos
	actor.set_script(EnemyScript if is_enemy else PlayerScript)
	var visual := Node3D.new()
	visual.name = "SpyVisual"
	actor.add_child(visual)
	var coat := color
	var dark := Color(0.12, 0.12, 0.15)
	var skin := Color(0.91, 0.85, 0.75)
	var accent := Color(0.17, 0.17, 0.20) if is_enemy else Color(0.96, 0.96, 0.92)
	# Smooth torso and coat, with articulated limbs and rounded silhouettes.
	_spy_ellipsoid(visual, Vector3(0, 1.15, 0), Vector3(0.79, 1.05, 0.54), coat)
	_spy_ellipsoid(visual, Vector3(0, 0.73, 0.06), Vector3(0.80, 0.54, 0.56), coat)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0.0 else "ArmR"
		arm.position = Vector3(side * 0.42, 1.42, 0)
		visual.add_child(arm)
		_spy_ellipsoid(arm, Vector3(side * 0.04, -0.31, 0), Vector3(0.27, 0.70, 0.30), coat)
		_spy_ellipsoid(arm, Vector3(side * 0.05, -0.68, -0.02), Vector3(0.26, 0.22, 0.29), accent)
		var leg := Node3D.new()
		leg.name = "LegL" if side < 0.0 else "LegR"
		leg.position = Vector3(side * 0.20, 0.75, 0)
		visual.add_child(leg)
		_spy_ellipsoid(leg, Vector3(0, -0.31, 0), Vector3(0.29, 0.67, 0.31), coat)
		_spy_ellipsoid(leg, Vector3(0, -0.65, -0.12), Vector3(0.31, 0.20, 0.50), accent)
	_spy_ellipsoid(visual, Vector3(0, 1.72, 0), Vector3(0.50, 0.55, 0.49), skin)
	for x in [-0.14, 0.14]:
		_spy_ellipsoid(visual, Vector3(x, 1.79, -0.235), Vector3(0.16, 0.18, 0.10), dark)
	_spy_beak(visual, skin)
	_spy_cylinder(visual, Vector3(0, 2.08, 0), 0.62, 0.075, coat)
	_spy_cylinder(visual, Vector3(0, 2.23, 0), 0.34, 0.30, coat)
	_spy_cylinder(visual, Vector3(0, 2.14, 0), 0.348, 0.075, accent)
	_spy_ellipsoid(visual, Vector3(0, 1.14, -0.29), Vector3(0.11, 0.38, 0.05), accent)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	actor.add_child(collider)
	add_child(actor)
	return actor

func _spy_part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)

func _spy_ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.position = pos
	node.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	parent.add_child(node)

func _spy_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	parent.add_child(node)

func _spy_beak(parent: Node3D, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = 0.20
	mesh.height = 0.68
	mesh.radial_segments = 12
	node.mesh = mesh
	node.position = Vector3(0, 1.65, -0.51)
	node.rotation_degrees.x = -90
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	parent.add_child(node)

func _make_camera() -> void:
	follow_camera = Camera3D.new()
	follow_camera.position = player.position + Vector3(0, 2.6, camera_distance)
	follow_camera.fov = 68.0
	follow_camera.current = true
	add_child(follow_camera)
	follow_camera.look_at(player.position + Vector3(0, 1.35, 0), Vector3.UP)

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.text = "ESPÍAS EN GUERRA 3D | Izquierda: mover | Derecha: cámara"
	hud.position = Vector2(18, 18)
	hud.add_theme_font_size_override("font_size", 21)
	layer.add_child(hud)
	joystick_base = Control.new()
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.position = Vector2(42, 510)
	joystick_base.size = Vector2(140, 140)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joystick_base)
	var ring := Panel.new()
	ring.position = Vector2.ZERO
	ring.size = Vector2(140, 140)
	ring.modulate = Color(0.6, 0.8, 1.0, 0.35)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(ring)
	joystick_knob = Panel.new()
	joystick_knob.size = Vector2(42, 42)
	joystick_knob.position = Vector2(49, 49)
	joystick_knob.modulate = Color(0.8, 0.9, 1.0, 0.75)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)
	var jump_button := Button.new()
	jump_button.text = "SALTAR"
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.offset_left = -210
	jump_button.offset_top = -225
	jump_button.offset_right = -22
	jump_button.offset_bottom = -143
	jump_button.pressed.connect(func(): jump_requested = true)
	layer.add_child(jump_button)
	var trap_button := Button.new()
	trap_button.text = "TRAMPA"
	trap_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	trap_button.offset_left = -210
	trap_button.offset_top = -122
	trap_button.offset_right = -22
	trap_button.offset_bottom = -38
	trap_button.pressed.connect(place_trap)
	layer.add_child(trap_button)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.48 and touch_id == -1:
				touch_id = event.index
				touch_origin = event.position
				joy = Vector2.ZERO
			elif event.position.x >= get_viewport().get_visible_rect().size.x * 0.48 and camera_touch_id == -1:
				camera_touch_id = event.index
		else:
			if event.index == touch_id:
				touch_id = -1
				joy = Vector2.ZERO
			if event.index == camera_touch_id:
				camera_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			joy = ((event.position - touch_origin) / 95.0).limit_length(1.0)
		elif event.index == camera_touch_id:
			camera_yaw -= event.relative.x * 0.005
			camera_pitch = clampf(camera_pitch + event.relative.y * 0.004, -0.85, 0.4)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_yaw -= event.relative.x * 0.005
		camera_pitch = clampf(camera_pitch + event.relative.y * 0.004, -0.85, 0.4)

func place_trap() -> void:
	if not is_instance_valid(player):
		return
	var trap := Area3D.new()
	trap.position = player.position + Vector3(0,0.12,0)
	var visual := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.65
	cylinder.bottom_radius = 0.65
	cylinder.height = 0.16
	visual.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.ORANGE_RED
	visual.material_override = mat
	trap.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.7
	collision.shape = shape
	trap.add_child(collision)
	add_child(trap)
	traps.append(trap)
	trap.body_entered.connect(func(body: Node3D):
		if body == enemy:
			enemy.position = Vector3(4,0,0)
			hud.text = "¡TRAMPA ACTIVADA! Enemigo reiniciado"
			traps.erase(trap)
			trap.queue_free()
	)
