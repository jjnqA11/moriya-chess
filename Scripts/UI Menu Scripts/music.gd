extends Node

const MUSIC_SCENES := [
	"res://Scenes/TestMenu.tscn",
	"res://Scenes/HowToPlay.tscn",
	"res://Scenes/Settings.tscn",
	"res://Scenes/DifficultyMenu.tscn",
]

var player := AudioStreamPlayer.new()
var last_scene_path := ""
var in_music_zone := false   # đang ở trong nhóm scene có nhạc hay không

func _ready() -> void:
	player.bus = "Music"
	player.stream = preload("res://Assets/Sounds/soundtrack_1.ogg")
	player.volume_db = -5.0
	add_child(player)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return   # đang trong lúc đổi scene, bỏ qua frame này

	var path := scene.scene_file_path
	if path == last_scene_path:
		return
	last_scene_path = path

	var should_play := path in MUSIC_SCENES

	if should_play and not in_music_zone:
		player.play()    # vừa BƯỚC VÀO vùng nhạc: phát từ đầu
	elif not should_play and in_music_zone:
		player.stop()    # vừa RỜI vùng nhạc: dừng

	in_music_zone = should_play
