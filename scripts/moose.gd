extends Node3D


enum States{IDLE, NOTICE, CHARGE}

@export_category("Charge")
@export var charge_time := 5.0
@export var charge_delay_min := 5.0
@export var charge_delay_max := 50.0

var current_state: States = States.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Charge on press if debug
	if Input.is_action_just_pressed("ui_accept") and OS.is_debug_build():
		var rand_x := randf_range(-30, 30)
		var rand_z := randf_range(-30, 30)
		moose_charge(Vector3(rand_x, 0, rand_z))


func moose_warning():
	pass


## Makes the Moose charge to ´where´.
func moose_charge(where: Vector3):
	var charge_tween := get_tree().create_tween()
	charge_tween.tween_property(self, "global_position", where, charge_time)


func _on_moose_charge_timer_timeout() -> void:
	%MooseChargeTimer.start(randf_range(charge_delay_min, charge_delay_max))
