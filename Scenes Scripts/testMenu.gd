extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pv_p_button_pressed() -> void:
	Globals.player_2_type = Globals.PLAYER_2_TYPE.HUMAN
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_pv_e_button_pressed() -> void:
	Globals.player_2_type = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://Scenes/DifficultyMenu.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Settings.tscn")
