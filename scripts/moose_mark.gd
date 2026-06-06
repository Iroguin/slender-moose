extends Node3D


@export var marked := false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		marked = true
		%Mark.hide()
		%Sign.show()
