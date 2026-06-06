extends Node3D


const MOOSE_MARK = preload("uid://c4atbox6duvyv")
const WIN = preload("uid://36br8yfpbi0r")
const GAME_OVER = preload("uid://cu3inaq04pjs5")

var signs_placed := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for mark in 3:
		var moose_mark := MOOSE_MARK.instantiate() as MooseMark
		moose_mark.position = Vector3(randf_range(-500, 500), 0, randf_range(-500, 500))
		moose_mark.area_marked.connect(_on_sign_placed)
		add_child(moose_mark)
		print_debug("spawned moose mark at ", moose_mark.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_moose_hit_player() -> void:
	get_tree().change_scene_to_packed(GAME_OVER)


func _on_sign_placed():
	signs_placed += 1
	if signs_placed >= 3:
		get_tree().change_scene_to_packed(WIN)
