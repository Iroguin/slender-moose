class_name Player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity: float = 0.002

@export_group("Head Bob")
@export var bob_frequency: float = 4.0
@export var bob_vertical_amplitude: float = 0.06 # meters
@export var bob_horizontal_amplitude: float = 0.1 # meters
@export var bob_roll_amplitude: float = 0.5 # degrees
@export var bob_yaw_amplitude: float = 0.8 # degrees
@export var bob_smoothing: float = 10.0

@onready var camera: Camera3D = $Camera3D

var min_pitch: float = deg_to_rad(-89)
var max_pitch: float = deg_to_rad(89)

var camera_rest_position: Vector3
var bob_time: float = 0.0
var bob_blend: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_rest_position = camera.position

func _unhandled_input(event: InputEvent) -> void:
	# handle mouse movement for camera looking
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, min_pitch, max_pitch)

func _process(_delta: float) -> void:
	# release/re-capture the mouse cursor for menu
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	_update_headbob(delta)

func _update_headbob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and horizontal_speed > 0.1
	var target_blend := 1.0 if moving else 0.0
	bob_blend = move_toward(bob_blend, target_blend, bob_smoothing * delta)

	if moving:
		var speed_ratio := horizontal_speed / SPEED
		bob_time += delta * bob_frequency * speed_ratio

	var vertical := sin(bob_time * 2.0) * bob_vertical_amplitude
	var horizontal := cos(bob_time) * bob_horizontal_amplitude
	var roll := cos(bob_time) * deg_to_rad(bob_roll_amplitude)
	var yaw := cos(bob_time) * deg_to_rad(bob_yaw_amplitude)

	camera.position = camera_rest_position + Vector3(horizontal, vertical, 0.0) * bob_blend
	camera.rotation.z = roll * bob_blend
	camera.rotation.y = yaw * bob_blend
