@tool
extends EditorScript

# Procedurally scatters spruce trees across the Terrain3D regions.
# Run from the editor (Cmd+Shift+X) with scenes/world.tscn open, then save.

const TREE_MESH_IDS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]  # Spruce1-9
const TREE_COUNT := 4000 # How many trees to place
const AREA_HALF := 500.0 # Scatter within this many meters of origin
const MIN_SCALE := 1.0
const MAX_SCALE := 2.0
const MAX_SLOPE_DEGREES := 30.0 # Wont place on slope steeper than this
const MAX_TILT_DEGREES := 6.0 # Random lean
const NORMAL_ALIGN := 0.0 # 0 = always upright, 1 = fully follow ground slope

func _run() -> void:
	var terrain: Terrain3D = get_scene().find_child("Terrain3D", true, false)
	if terrain == null:
		push_error("Open scenes/world.tscn first.")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 123456

	var batches := {}
	for id in TREE_MESH_IDS:
		batches[id] = [] as Array[Transform3D]

	var placed := 0
	var attempts := 0
	while placed < TREE_COUNT and attempts < TREE_COUNT * 10:
		attempts += 1
		var x := rng.randf_range(-AREA_HALF, AREA_HALF)
		var z := rng.randf_range(-AREA_HALF, AREA_HALF)
		var pos := Vector3(x, 0, z)

		# Snap to terrain. NAN = skip.
		var h := terrain.data.get_height(pos)
		if is_nan(h):
			continue
		pos.y = h

		# Surface normal: used to reject steep slopes and (optionally) to tilt
		# trees so they follow the ground. Fall back to straight up if invalid.
		var normal: Vector3 = terrain.data.get_normal(pos)
		if is_nan(normal.x):
			normal = Vector3.UP
		else:
			var slope := rad_to_deg(acos(normal.dot(Vector3.UP)))
			if slope > MAX_SLOPE_DEGREES:
				continue

		# Build the transform:
		var up := Vector3.UP.slerp(normal, NORMAL_ALIGN).normalized()
		var basis := _basis_from_up(up, rng.randf_range(0, TAU))

		if MAX_TILT_DEGREES > 0.0:
			var tilt_dir := rng.randf_range(0, TAU)
			var tilt_amt := rng.randf_range(0.0, deg_to_rad(MAX_TILT_DEGREES))
			var lean_axis := Vector3(cos(tilt_dir), 0.0, sin(tilt_dir))
			basis = Basis(lean_axis, tilt_amt) * basis

		basis = basis.scaled(Vector3.ONE * rng.randf_range(MIN_SCALE, MAX_SCALE))

		var mesh_id: int = TREE_MESH_IDS[rng.randi() % TREE_MESH_IDS.size()]
		batches[mesh_id].push_back(Transform3D(basis, pos))
		placed += 1

	# Push each batch to the instancer.
	for id in batches:
		if batches[id].size() > 0:
			terrain.instancer.clear_by_mesh(id)   # remove old before re-adding
			terrain.instancer.add_transforms(id, batches[id])

	print("Placed ", placed, " trees (", attempts, " attempts).")
	print("SAVE (Cmd+S) to bake into terrain data.")


func _basis_from_up(up: Vector3, yaw: float) -> Basis:
	up = up.normalized()
	var reference := Vector3.FORWARD
	if absf(up.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var x_axis := reference.cross(up).normalized()
	var z_axis := up.cross(x_axis).normalized()
	var basis := Basis(x_axis, up, z_axis)
	return basis * Basis(Vector3.UP, yaw)
