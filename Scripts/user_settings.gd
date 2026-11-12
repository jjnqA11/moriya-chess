extends Node

const SAVE_PATH := "user://settings.cfg"
const SUPPORTED_LANGUAGES := ["vi", "en"]

var music_enabled := true
var music_volume := 100.0   # phần trăm, 0..200
var sfx_enabled := true
var sfx_volume := 100.0
var language := "vi"        # chừa sẵn cho thành viên làm ngôn ngữ

func _ready() -> void:
	load_settings()
	apply_audio()
	apply_language()

	print("Current locale: ", TranslationServer.get_locale())
	print("Test translation: ", TranslationServer.translate("SETTINGS_TITLE"))

func apply_audio() -> void:
	_apply_bus("Music", music_enabled, music_volume)
	_apply_bus("SFX", sfx_enabled, sfx_volume)

func _apply_bus(bus_name: String, enabled: bool, percent: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, not enabled or percent <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(percent / 100.0, 0.0001)))

# Áp dụng ngôn ngữ hiện tại cho toàn bộ dự án
func apply_language() -> void:
	# Nếu ngôn ngữ không hợp lệ, quay về tiếng Việt
	if not SUPPORTED_LANGUAGES.has(language):
		language = "vi"

	TranslationServer.set_locale(language)

# Thay đổi ngôn ngữ và lưu lựa chọn
func set_language(new_language: String) -> void:
	# Kiểm tra ngôn ngữ có được hỗ trợ không
	if not SUPPORTED_LANGUAGES.has(new_language):
		push_warning("Ngôn ngữ không được hỗ trợ: " + new_language)
		return

	language = new_language

	apply_language()
	save_settings()

func save_settings() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("general", "language", language)
	return cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return   # lần chạy đầu: dùng mặc định 100%
	music_enabled = cfg.get_value("audio", "music_enabled", true)
	music_volume = cfg.get_value("audio", "music_volume", 100.0)
	sfx_enabled = cfg.get_value("audio", "sfx_enabled", true)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 100.0)
	language = cfg.get_value("general", "language", "vi")
