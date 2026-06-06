extends CanvasLayer

var game_paused := false
@onready var quit_button := $HBoxContainer/VBoxContainer/Quit_Button
@onready var continue_button := $HBoxContainer/VBoxContainer/Continue_Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			toggle_pause_menu()


func toggle_pause_menu():
	game_paused = !game_paused
	self.visible = game_paused
	get_tree().paused = game_paused
	if game_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		continue_button.grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_quit_button_pressed() -> void:
	#AudioHandler.play_click()
	await get_tree().create_timer(0.11).timeout
	get_tree().quit()


func _on_return_button_pressed() -> void:
	#AudioHandler.play_click()
	await get_tree().create_timer(0.11).timeout
	toggle_pause_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")



func _on_continue_button_pressed() -> void:
	#AudioHandler.play_click()
	await get_tree().create_timer(0.11).timeout
	toggle_pause_menu()
