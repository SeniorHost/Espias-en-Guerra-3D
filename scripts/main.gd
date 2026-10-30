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

func _ready() -> void:
	_make_world()
	player = _make_actor(Color(0.9, 0.9, 0.95), Vector3(-4, 0, 0), false)
	enemy = _make_actor(Color(0.12, 0.12, 0.17), Vector3(4, 0, 0), true)
	_make_camera()
	_make_hud()

func _process(delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(follow_camera):
		var desired := player.global_position + Vector3(0, 4.1, 7.5)
		follow_camera.global_position = follow_camera.global_position.lerp(desired, clampf(delta * 5.0, 0.0, 1.0))
		follow_camera.look_at(player.global_position + Vector3(0, 1.25, 0), Vector3.UP)

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
	_spy_part(visual, Vector3(0, 0.94, 0), Vector3(0.72, 0.88, 0.4), color)
	_spy_part(visual, Vector3(0, 1.58, 0), Vector3(0.48, 0.48, 0.46), Color(0.96, 0.79, 0.64))
	_spy_part(visual, Vector3(0, 1.91, 0), Vector3(0.8, 0.13, 0.73), color)
	_spy_part(visual, Vector3(0, 2.03, 0), Vector3(0.47, 0.25, 0.47), color)
	_spy_part(visual, Vector3(-0.49, 1.03, 0), Vector3(0.23, 0.72, 0.27), color)
	_spy_part(visual, Vector3(0.49, 1.03, 0), Vector3(0.23, 0.72, 0.27), color)
	_spy_part(visual, Vector3(-0.2, 0.38, 0), Vector3(0.27, 0.72, 0.31), color)
	_spy_part(visual, Vector3(0.2, 0.38, 0), Vector3(0.27, 0.72, 0.31), color)
	_spy_part(visual, Vector3(0, 1.62, -0.25), Vector3(0.54, 0.16, 0.1), Color(0.08,0.08,0.1))
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

func _make_camera() -> void:
	follow_camera = Camera3D.new()
	follow_camera.position = player.position + Vector3(0, 4.1, 7.5)
	follow_camera.fov = 68.0
	follow_camera.current = true
	add_child(follow_camera)
	follow_camera.look_at(player.position + Vector3(0, 1.25, 0), Vector3.UP)

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.text = "ESPÍAS EN GUERRA 3D | Tercera persona | Joystick izquierdo | Trampa"
	hud.position = Vector2(18, 18)
	hud.add_theme_font_size_override("font_size", 24)
	layer.add_child(hud)
	var button := Button.new()
	button.text = "PONER TRAMPA"
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = -235
	button.offset_top = -115
	button.offset_right = -20
	button.offset_bottom = -25
	button.pressed.connect(place_trap)
	layer.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.5 and touch_id == -1:
			touch_id = event.index
			touch_origin = event.position
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			joy = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == touch_id:
		joy = ((event.position - touch_origin) / 90.0).limit_length(1.0)

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
