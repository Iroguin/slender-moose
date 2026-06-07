extends Node3D


signal hit_player

@export var car_meshes: Array[Mesh] = []
@export var flip_facing: bool = true

@onready var _mesh_instance: MeshInstance3D = $RigidBody3D/MeshInstance3D


func _ready() -> void:
	if not car_meshes.is_empty() and _mesh_instance != null:
		var pick: Mesh = car_meshes[randi() % car_meshes.size()]
		if pick != null:
			_mesh_instance.mesh = pick
			_mesh_instance.material_override = null
			_align_mesh(pick)


func _align_mesh(mesh: Mesh) -> void:
	var center := mesh.get_aabb().get_center()
	_mesh_instance.position = Vector3(-center.x, _mesh_instance.position.y, -center.z)
	_mesh_instance.rotation.y = PI if flip_facing else 0.0


func _on_hit_area_body_entered(body: Node3D) -> void:
	if body is Player:
		hit_player.emit()
