extends AnimatedSprite2D

func _ready():
	# Giữ hình ảnh pixel không bị nhòe
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Cập nhật kích thước khi cửa sổ thay đổi
	get_viewport().size_changed.connect(_fit_background)

	_fit_background()
	play("default")


func _fit_background():
	if sprite_frames == null:
		return

	if sprite_frames.get_frame_count("default") == 0:
		return

	var texture = sprite_frames.get_frame_texture("default", 0)
	if texture == null:
		return

	var frame_size = texture.get_size()
	var viewport_size = get_viewport_rect().size

	# Phóng ảnh đủ để phủ kín cửa sổ
	var fit_scale = max(
		viewport_size.x / frame_size.x,
		viewport_size.y / frame_size.y
	)

	scale = Vector2.ONE * fit_scale
	position = viewport_size / 2
