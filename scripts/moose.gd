extends Node3D


enum States{IDLE, NOTICE, CHARGE}

@export var player: Player
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
	pass


## Makes the Moose charge to ´where´.
func moose_charge(where: Vector3):
	var charge_tween := get_tree().create_tween()
	where = Vector3(where.x, 0, where.z)
	charge_tween.tween_property(self, "global_position", where, charge_time)


# TODO make this warn and charge toward the player
## Makes the moose charge when the timer runs out
func _on_moose_charge_timer_timeout() -> void:
	%MooseSound.play()
	await get_tree().create_timer(2).timeout
	if player == null:
		var rand_x := randf_range(-30, 30)
		var rand_z := randf_range(-30, 30)
		moose_charge(Vector3(rand_x, 0, rand_z))
		push_warning("player variable hasn't been set in Moose")
	else:
		var charge_distance := global_position.distance_to(player.global_position)
		var charge_dir := global_position.direction_to(player.global_position)
		var charge_pos := global_position + charge_dir * (charge_distance * 2)
		moose_charge(charge_pos)
	%MooseChargeTimer.start(randf_range(charge_delay_min, charge_delay_max))
