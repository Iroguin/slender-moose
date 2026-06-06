extends Node3D


const MOOSE_MARK = preload("uid://c4atbox6duvyv")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for mark in 3:
		var moose_mark := MOOSE_MARK.instantiate() as Node3D
		moose_mark.position = Vector3(randf_range(-500, 500), 0, randf_range(-500, 500))
		add_child(moose_mark)
		print_debug("spawned moose mark at ", moose_mark.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


#TODO Game over tähän
func _on_moose_hit_player() -> void:
	get_tree().change_scene_to_file("uid://cu3inaq04pjs5")
