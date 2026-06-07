class_name TreeColliders
extends Node3D


@export var trunk_data: TreeTrunkData
@export var trunk_radius: float = 0.35
@export var trunk_height: float = 6.0 # at tree scale 1.0
@export_flags_3d_physics var collision_layer: int = 1


func _ready() -> void:
	if trunk_data == null:
		push_warning("TreeColliders: no trunk_data assigned — no tree collision.")
		return

	for xform in trunk_data.transforms:
		var scale: float = maxf(absf(xform.basis.get_scale().y), 0.01)

		var body := StaticBody3D.new()
		body.collision_layer = collision_layer
		body.collision_mask = 0
		body.position = xform.origin

		var shape_node := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = trunk_radius * scale
		cyl.height = trunk_height * scale
		shape_node.shape = cyl
		shape_node.position.y = (trunk_height * scale) * 0.5

		body.add_child(shape_node)
		add_child(body)
