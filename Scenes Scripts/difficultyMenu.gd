extends Control

@onready var title: Label = $MenuContainer/Title
@onready var easy_button: Button = $MenuContainer/EasyButton
@onready var medium_button: Button = $MenuContainer/MediumButton
@onready var hard_button: Button = $MenuContainer/HardButton
@onready var back_button: Button = $MenuContainer/BackButton

func _ready() -> void:
	_update_localized_texts()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_localized_texts()
		
func _update_localized_texts() -> void:
	title.text = tr("MENU_TITLE_DIFFICULTY")
	easy_button.text = tr("EASY_BUTTON")
	medium_button.text = tr("MEDIUM_BUTTON")
	hard_button.text = tr("HARD_BUTTON")
	back_button.text = tr("BACK_BUTTON")

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
