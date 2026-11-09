extends Control

@onready var pve_button: Button = $MenuContainer/PvEButton
@onready var pvp_button: Button = $MenuContainer/PvPButton
@onready var tutorial_button: Button = $MenuContainer/HowToPlayButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var exit_button: Button = $MenuContainer/ExitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_localized_texts()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_localized_texts()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_localized_texts() -> void:
	pve_button.text = tr("MENU_PVE")
	pvp_button.text = tr("MENU_PVP")
	tutorial_button.text = tr("MENU_TUTORIAL")
	settings_button.text = tr("MENU_SETTINGS")
	exit_button.text = tr("MENU_EXIT")

func _on_pv_p_button_pressed() -> void:
	Globals.player_2_type = Globals.PLAYER_2_TYPE.HUMAN
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_pv_e_button_pressed() -> void:
	Globals.player_2_type = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://Scenes/DifficultyMenu.tscn")
	

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Settings.tscn")

func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/HowToPlay.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
