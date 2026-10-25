extends Control

@onready var music_toggle: CheckButton = %MusicToggle
@onready var music_slider: HSlider = %MusicSlider
@onready var music_percent: Label = %MusicPercent
@onready var sfx_toggle: CheckButton = %SfxToggle
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_percent: Label = %SfxPercent

func _ready() -> void:
	# đặt giá trị hiện tại trước, rồi mới nối signal
	music_toggle.button_pressed = UserSettings.music_enabled
	music_slider.value = UserSettings.music_volume
	music_slider.editable = UserSettings.music_enabled
	music_percent.text = "%d%%" % UserSettings.music_volume

	sfx_toggle.button_pressed = UserSettings.sfx_enabled
	sfx_slider.value = UserSettings.sfx_volume
	sfx_slider.editable = UserSettings.sfx_enabled
	sfx_percent.text = "%d%%" % UserSettings.sfx_volume

	music_toggle.toggled.connect(_on_music_toggled)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_slider.drag_ended.connect(func(_c): Sfx.play_click())   # nghe thử mức âm lượng
	for s in [music_slider, sfx_slider]:
		var mat: ShaderMaterial = s.get_node("Track").material
		s.mouse_entered.connect(func(): _tint(mat, Color(1.0, 0.85, 0.2)))
		s.mouse_exited.connect(func(): _tint(mat, Color.WHITE))

func _on_music_toggled(on: bool) -> void:
	UserSettings.music_enabled = on
	music_slider.editable = on          # tắt thì khóa thanh trượt
	UserSettings.apply_audio()
	UserSettings.save_settings()

func _on_music_changed(v: float) -> void:
	UserSettings.music_volume = v
	music_percent.text = "%d%%" % v
	UserSettings.apply_audio()
	UserSettings.save_settings()

func _on_sfx_toggled(on: bool) -> void:
	UserSettings.sfx_enabled = on
	sfx_slider.editable = on
	UserSettings.apply_audio()
	UserSettings.save_settings()

func _on_sfx_changed(v: float) -> void:
	UserSettings.sfx_volume = v
	sfx_percent.text = "%d%%" % v
	UserSettings.apply_audio()
	UserSettings.save_settings()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn") 

func _tint(mat: ShaderMaterial, c: Color) -> void:
	var t := create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("line_color", v),
		mat.get_shader_parameter("line_color"), c, 0.15)
