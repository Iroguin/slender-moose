class_name Player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity: float = 0.002

# --- Visual head-bob / sway (cosmetic only, does not affect movement) ---
@export_group("Head Bob")
## How fast the bob cycles while walking (steps feel; lower = slower walk).
@export var bob_frequency: float = 4.0
## Vertical bounce amount, in meters.
@export var bob_vertical_amplitude: float = 0.06
## Side-to-side horizontal sway amount, in meters.
@export var bob_horizontal_amplitude: float = 0.1
## Roll tilt as the camera sways, in degrees.
@export var bob_roll_amplitude: float = 0.5
## Subtle yaw wobble (head turning slightly with each step), in degrees.
@export var bob_yaw_amplitude: float = 0.8
## How quickly the bob eases in/out as you start/stop moving.
@export var bob_smoothing: float = 10.0

@onready var camera: Camera3D = $Camera3D

var min_pitch: float = deg_to_rad(-89)
var max_pitch: float = deg_to_rad(89)

# Resting local position of the camera; bob is applied as an offset from this.
var _camera_rest_position: Vector3
# Phase accumulator that only advances while actually walking on the ground.
var _bob_time: float = 0.0
# Eases 0..1 so the bob fades in/out instead of snapping on.
var _bob_blend: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_rest_position = camera.position

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

	_update_head_bob(delta)

# Cosmetic camera bob/sway. Operates purely on the camera's local transform,
# so the body keeps moving in a straight line.
func _update_head_bob(delta: float) -> void:
	# Horizontal speed drives the bob; standing or airborne -> no bob.
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and horizontal_speed > 0.1

	# Ease the bob in/out so it doesn't pop on/off.
	var target_blend := 1.0 if moving else 0.0
	_bob_blend = move_toward(_bob_blend, target_blend, bob_smoothing * delta)

	# Advance phase proportional to speed only while moving.
	if moving:
		var speed_ratio := horizontal_speed / SPEED
		_bob_time += delta * bob_frequency * speed_ratio

	# Vertical bounces at double frequency (foot down on each step);
	# horizontal sway + roll run at the base frequency (one per stride).
	var vertical := sin(_bob_time * 2.0) * bob_vertical_amplitude
	var horizontal := cos(_bob_time) * bob_horizontal_amplitude
	var roll := cos(_bob_time) * deg_to_rad(bob_roll_amplitude)
	var yaw := cos(_bob_time) * deg_to_rad(bob_yaw_amplitude)

	camera.position = _camera_rest_position + Vector3(horizontal, vertical, 0.0) * _bob_blend
	# Roll (z) and yaw (y) are free: mouse-look owns x (pitch) and yaws the BODY,
	# not the camera, so these local rotations never fight it.
	camera.rotation.z = roll * _bob_blend
	camera.rotation.y = yaw * _bob_blend
