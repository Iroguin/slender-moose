@tool
class_name TrafficPath
extends Path3D

@export var car_scenes: Array[PackedScene] = []
@export var car_count: int = 4
@export var minspeed: float = 6.0
@export var maxspeed: float = 12.0
@export var orient_to_path: bool = true
@export var height_offset: float = 0.0
@export var preview_in_editor: bool = false:
	set(value):
		preview_in_editor = value
		if Engine.is_editor_hint():
			_rebuild()

var followers: Array[PathFollow3D] = []
var speeds: Array[float] = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		_rebuild()


func _rebuild() -> void:
	for f in followers:
		if is_instance_valid(f):
			f.queue_free()
	followers.clear()
	speeds.clear()

	var path_length := curve.get_baked_length()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in car_count:
		var follower := PathFollow3D.new()
		follower.loop = true
		follower.rotation_mode = PathFollow3D.ROTATION_XYZ if orient_to_path else PathFollow3D.ROTATION_NONE
		follower.v_offset = height_offset
		follower.progress = (path_length / car_count) * i + rng.randf_range(0.0, path_length / car_count * 0.5)
		add_child(follower)
		if Engine.is_editor_hint():
			follower.owner = get_tree().edited_scene_root

		var car := _make_car(rng)
		follower.add_child(car)
		if Engine.is_editor_hint():
			_set_owner_recursive(car, get_tree().edited_scene_root)

		followers.append(follower)
		speeds.append(rng.randf_range(minspeed, maxspeed))


func _make_car(rng: RandomNumberGenerator) -> Node3D:
	if not car_scenes.is_empty():
		var scene: PackedScene = car_scenes[rng.randi() % car_scenes.size()]
		if scene != null:
			return scene.instantiate()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.8, 1.4, 4.2)
	box.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(rng.randf(), 0.5, 0.8)
	box.material_override = mat
	box.position.y = 0.7
	return box


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for i in followers.size():
		var f := followers[i]
		if is_instance_valid(f):
			f.progress += speeds[i] * delta

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	node.owner = scene_owner
	for child in node.get_children():
		_set_owner_recursive(child, scene_owner)
