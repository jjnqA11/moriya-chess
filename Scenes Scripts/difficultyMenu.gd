extends Control


func _on_easy_button_pressed() -> void:
	Globals.ai_difficulty = Globals.AI_DIFFICULTY.EASY
	Globals.player_2_type = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _on_medium_button_pressed() -> void:
	Globals.ai_difficulty = Globals.AI_DIFFICULTY.MEDIUM
	Globals.player_2_type = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_hard_button_pressed() -> void:
	Globals.ai_difficulty = Globals.AI_DIFFICULTY.HARD
	Globals.player_2_type = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_insane_button_pressed() -> void:
	print("🟣 Insane - Đang phát triển")


func _on_extreme_button_pressed() -> void:
	print("💀 Extreme - Đang phát triển")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn")
