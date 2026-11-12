extends Control

@onready var music_toggle: CheckButton = %MusicToggle
@onready var music_slider: HSlider = %MusicSlider
@onready var music_percent: Label = %MusicPercent
@onready var sfx_toggle: CheckButton = %SfxToggle
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_percent: Label = %SfxPercent
@onready var language_label: Label = %LanguageLabel
@onready var language_option: OptionButton = %LanguageOption
@onready var audio_title: Label = %AudioTitle
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var back_button: Button = %BackButton
@onready var save_settings_button: Button = %SaveSettingsButton

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
	
	# Language settings
	var game_font: Font = load("res://Assets/Fonts/VVMAyuMincho-Regular.ttf")
	language_option.get_popup().add_theme_font_override("font", game_font)
	language_option.add_item("Tiếng Việt")
	language_option.add_item("English")
	# Hiển thị ngôn ngữ hiện tại
	language_option.select(
		0 if UserSettings.language == "vi" else 1
	)
	# Hiển thị nhãn theo ngôn ngữ hiện tại
	_update_localized_texts()
	language_option.item_selected.connect(_on_language_selected)

	music_toggle.toggled.connect(_on_music_toggled)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_slider.drag_ended.connect(func(_c): Sfx.play_click())   # nghe thử mức âm lượng
	for s in [music_slider, sfx_slider]:
		var mat: ShaderMaterial = s.get_node("Track").material
		s.mouse_entered.connect(func(): _tint(mat, Color(1.0, 0.85, 0.2)))
		s.mouse_exited.connect(func(): _tint(mat, Color.WHITE))
	save_settings_button.pressed.connect(_on_save_settings_pressed)
	save_settings_button.text = tr("SAVE_BUTTON")
	save_settings_button.disabled = false
	
func _on_music_toggled(on: bool) -> void:
	UserSettings.music_enabled = on
	music_slider.editable = on          # tắt thì khóa thanh trượt
	UserSettings.apply_audio()
	UserSettings.save_settings()
	_mark_settings_changed()

func _on_music_changed(v: float) -> void:
	UserSettings.music_volume = v
	music_percent.text = "%d%%" % v
	UserSettings.apply_audio()
	UserSettings.save_settings()
	_mark_settings_changed()

func _on_sfx_toggled(on: bool) -> void:
	UserSettings.sfx_enabled = on
	sfx_slider.editable = on
	UserSettings.apply_audio()
	UserSettings.save_settings()
	_mark_settings_changed()

func _on_sfx_changed(v: float) -> void:
	UserSettings.sfx_volume = v
	sfx_percent.text = "%d%%" % v
	UserSettings.apply_audio()
	UserSettings.save_settings()
	_mark_settings_changed()

func _on_language_selected(index: int) -> void:
	var selected_language := "vi" if index == 0 else "en"
	UserSettings.set_language(selected_language)
	_mark_settings_changed()

func _update_localized_texts() -> void:
	audio_title.text = tr("AUDIO_TITLE")
	music_label.text = tr("MUSIC_LABEL")
	sfx_label.text = tr("SFX_LABEL")
	language_label.text = tr("LANGUAGE_LABEL")
	save_settings_button.text = tr("SAVE_BUTTON")
	back_button.text = tr("BACK_BUTTON")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_node_ready():
			_update_localized_texts()

func _on_save_settings_pressed() -> void:
	var result: Error = UserSettings.save_settings()
	if result == OK:
		save_settings_button.text = tr("SAVE_BUTTON_STATE")
		save_settings_button.disabled = true
	else:
		save_settings_button.text = "Lưu thất bại!"
		save_settings_button.disabled = false
		push_error("Không thể lưu cài đặt!")

func _mark_settings_changed() -> void:
	save_settings_button.text = tr("SAVE_BUTTON")
	save_settings_button.disabled = false

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn") 

func _tint(mat: ShaderMaterial, c: Color) -> void:
	var t := create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("line_color", v),
		mat.get_shader_parameter("line_color"), c, 0.15)
