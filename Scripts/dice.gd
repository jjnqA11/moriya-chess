
extends Node2D

# Thời gian tung xúc xắc
const ROLL_DURATION: float = 2.0

# Khoảng thời gian giữa các lần đổi mặt
const FAST_INTERVAL: float = 0.045
const SLOW_INTERVAL: float = 0.28

var value: int = 0
var remaining_points: int = 0
var is_rolling: bool = false


func roll(dice_display: TextureRect) -> int:
	# Không cho phép tung nhiều lần cùng lúc
	if is_rolling:
		return value

	is_rolling = true

	# Tính kết quả thật trước khi chạy animation
	value = randi_range(1, 6)
	remaining_points = value

	# Chạy hiệu ứng tung xúc xắc
	await _animate_roll(dice_display, value)

	is_rolling = false

	print("Dice rolled: ", value)
	print("Remaining points: ", remaining_points)

	return value


func _animate_roll(dice_display: TextureRect, final_value: int) -> void:
	var elapsed: float = 0.0
	var previous_face: int = 0

	while elapsed < ROLL_DURATION:
		# Tính tiến độ animation từ 0 đến 1
		var progress: float = elapsed / ROLL_DURATION

		# Tăng khoảng nghỉ dần theo thời gian
		var interval: float = lerpf(
			FAST_INTERVAL,
			SLOW_INTERVAL,
			progress * progress
		)

		# Không để tổng thời gian vượt quá 2 giây
		interval = minf(interval, ROLL_DURATION - elapsed)

		# Chọn mặt xúc xắc ngẫu nhiên
		var random_face: int = randi_range(1, 6)

		# Hạn chế xuất hiện liên tiếp cùng một mặt
		while random_face == previous_face:
			random_face = randi_range(1, 6)

		dice_display.texture = Globals.DICE_TEXTURES[random_face]
		previous_face = random_face

		await get_tree().create_timer(interval).timeout
		elapsed += interval

	# Hiển thị chính xác kết quả đã được tính
	dice_display.texture = Globals.DICE_TEXTURES[final_value]
