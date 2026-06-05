extends Node3D


enum States{IDLE, NOTICE, CHARGE}

@export_category("Charge")
@export var charge_min := 5.0
@export var charge_max := 50.0

var current_state: States = States.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func moose_charge():
	pass


func _on_moose_charge_timer_timeout() -> void:
	%MooseChargeTimer.start(randf_range(charge_min, charge_max))
