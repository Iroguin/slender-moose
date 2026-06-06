class_name MooseMark
extends Node3D


signal area_marked

@export var marked := false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player and not marked:
		marked = true
		%Mark.hide()
		%Sign.show()
		area_marked.emit()
