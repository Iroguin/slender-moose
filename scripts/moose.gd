extends Node3D


signal hit_player

enum States{IDLE, NOTICE, CHARGE}

@export var player: Player
@export_category("Charge")
@export var charge_time := 5.0
@export var charge_delay_min := 5.0
@export var charge_delay_max := 50.0

var current_state: States = States.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Sprite3D.modulate = Color.WHITE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Makes the Moose charge to ´where´.
func moose_charge(where: Vector3):
	var charge_tween := get_tree().create_tween()
	where = Vector3(where.x, 0, where.z)
	charge_tween.set_trans(Tween.TRANS_CUBIC)
	charge_tween.set_ease(Tween.EASE_IN)
	charge_tween.tween_property(self, "global_position", where, charge_time)
	charge_tween.tween_property(%Sprite3D, "modulate", Color.TRANSPARENT, 0.5)


func warp_to_random_spot_near_player():
	var rand_position = (Vector3.FORWARD * 40).rotated(Vector3.UP, randf_range(0, 360))
	var new_position = player.position + rand_position
	print_debug(new_position)
	position = new_position


# TODO make this warn and charge toward the player
## Makes the moose charge when the timer runs out
func _on_moose_charge_timer_timeout() -> void:
	if player == null:
		var rand_x := randf_range(-30, 30)
		var rand_z := randf_range(-30, 30)
		moose_charge(Vector3(rand_x, 0, rand_z))
		push_warning("player variable hasn't been set in Moose")
		return
	
	warp_to_random_spot_near_player()
	%MooseSound.play()
	%Sprite3D.modulate = Color.WHITE
	await get_tree().create_timer(2).timeout
	var charge_distance := global_position.distance_to(player.global_position)
	var charge_dir := global_position.direction_to(player.global_position)
	var charge_pos := global_position + charge_dir * (charge_distance * 2)
	moose_charge(charge_pos)
	%MooseChargeTimer.start(randf_range(charge_delay_min, charge_delay_max))


func _on_charge_area_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	
	hit_player.emit()
