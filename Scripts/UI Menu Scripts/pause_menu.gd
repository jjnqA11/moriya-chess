extends Control

@onready var pause_button = get_parent().get_node("PauseButton")
@onready var resume_button = $PausePanel/MainContainer/ButtonContainer/ResumeButton
@onready var pause_panel = $PausePanel

@onready var restart_button = $PausePanel/MainContainer/ButtonContainer/RestartButton
@onready var restart_confirm = $RestartConfirm
@onready var confirm_restart_button = $RestartConfirm/MainContainer/ButtonContainer/ConfirmRestartButton
@onready var cancel_restart_button = $RestartConfirm/MainContainer/ButtonContainer/CancelRestartButton
@onready var restart_blur = $RestartBlur

@onready var back_to_menu_button = $PausePanel/MainContainer/ButtonContainer/MenuButton
@onready var menu_confirm = $MenuConfirm
@onready var confirm_menu_button = $MenuConfirm/MainContainer/ButtonContainer/ConfirmMenuButton
@onready var cancel_menu_button = $MenuConfirm/MainContainer/ButtonContainer/CancelMenuButton
func _ready():
	# PauseMenu vẫn nhận input kể cả khi game đang pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ban đầu chưa pause
	visible = false
	restart_blur.hide()
	restart_confirm.hide()
	
	# Kết nối nút
	pause_button.pressed.connect(open_pause)
	resume_button.pressed.connect(close_pause)
	restart_button.pressed.connect(show_restart_confirm)
	confirm_restart_button.pressed.connect(confirm_restart)
	cancel_restart_button.pressed.connect(cancel_restart)
	
	back_to_menu_button.pressed.connect(show_menu_confirm)
	confirm_menu_button.pressed.connect(confirm_back_to_menu)
	cancel_menu_button.pressed.connect(cancel_back_to_menu)

	menu_confirm.hide()
	restart_blur.hide()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			close_pause()
		else:
			open_pause()


func open_pause():
	visible = true
	pause_button.hide()
	get_tree().paused = true


func close_pause():
	visible = false
	pause_button.show()
	get_tree().paused = false

	print("=== RESUME ===")
	print("Tree paused: ", get_tree().paused)

	var board = get_parent().get_parent().get_node("Board")
	print("Board process mode: ", board.process_mode)
	print("Board visible: ", board.visible)


func show_restart_confirm():
	$PausePanel.hide()
	restart_blur.show()
	restart_confirm.show()


func cancel_restart():
	restart_blur.hide()
	restart_confirm.hide()
	$PausePanel.show()


func confirm_restart():
	restart_blur.hide()
	restart_confirm.hide()

	get_tree().paused = false
	get_tree().reload_current_scene()

func show_menu_confirm():
	pause_panel.hide()
	restart_blur.show()
	menu_confirm.show()


func cancel_back_to_menu():
	restart_blur.hide()
	menu_confirm.hide()
	pause_panel.show()


func confirm_back_to_menu():
	restart_blur.hide()
	menu_confirm.hide()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn")
