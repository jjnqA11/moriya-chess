extends Node

var player := AudioStreamPlayer.new()

func _ready() -> void:
	player.bus = "SFX"
	player.stream = preload("res://Assets/Sounds/click_stereo.ogg")
	add_child(player)

func play_click() -> void:
	player.play(0.07)
