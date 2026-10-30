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

func _ready() -> void:
	_make_world()
	player = _make_actor(Color(0.9, 0.9, 0.95), Vector3(-4, 0, 0), false)
	enemy = _make_actor(Color(0.12, 0.12, 0.17), Vector3(4, 0, 0), true)
	_make_camera()
	_make_hud()

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
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	mesh.mesh = capsule
	mesh.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	actor.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	actor.add_child(collider)
	add_child(actor)
	return actor

func _make_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 17, 15)
	camera.rotation_degrees.x = -48
	camera.current = true
	add_child(camera)

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.text = "ESPÍAS EN GUERRA | Mueve: WASD o joystick | Trampa: ESPACIO"
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
