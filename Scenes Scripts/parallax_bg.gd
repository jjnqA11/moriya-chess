extends TextureRect

@export var max_offset: float = 20.0
@export var smoothing: float = 2.0

func _ready() -> void:
	offset_transform_position = Globals.bg_offset   # tiếp tục từ vị trí cũ

func _process(delta: float) -> void:
	var screen := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	var dir := ((mouse - screen / 2.0) / (screen / 2.0)).clamp(Vector2(-1, -1), Vector2.ONE)
	var target := -dir * max_offset
	offset_transform_position = offset_transform_position.lerp(target, 1.0 - exp(-smoothing * delta))
	Globals.bg_offset = offset_transform_position   # lưu lại cho scene sau
