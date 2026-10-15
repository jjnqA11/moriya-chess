extends Node

# Module xu ly rieng cho do kho Hard.
const HARD_BOT_SCRIPT = preload("res://Scripts/hard_bot.gd")

var game_handle
var board_handle
var hard_bot_instance


# Nhan tham chieu den game va ban co; khoi tao Hard Bot neu chua co.
func setup(game, board) -> void:
	game_handle = game
	board_handle = board

	if hard_bot_instance == null:
		hard_bot_instance = HARD_BOT_SCRIPT.new()
		add_child(hard_bot_instance)

	hard_bot_instance.setup(game_handle, board_handle)


# Easy: chon ngau nhien cac nuoc di hop le cho den khi het diem.
func easy_move() -> void:
	while game_handle.dice.remaining_points > 0 and not game_handle.game_ended:
		var possible_moves: Array = get_all_possible_moves()

		if possible_moves.is_empty():
			print("🤖 Bot không còn nước đi! → Skip phần điểm còn lại.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		var random_move: Dictionary = possible_moves.pick_random()
		var piece = random_move["piece"]
		var target_position: Vector2 = random_move["target"]

		print("🤖 Bot chọn: ", piece.piece_type, " -> ", target_position)
		board_handle.highlight_bot_move(piece, target_position)
		await get_tree().create_timer(0.7).timeout
		board_handle.clear_highlight_cells()

		if game_handle.game_ended:
			return

		board_handle.execute_move(piece, target_position)

		if game_handle.game_ended:
			return

		# Cho nguoi choi thoi gian quan sat nuoc di cua Bot.
		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(2.0).timeout


# Medium: uu tien an quan co gia tri cao nhat; neu khong an duoc thi di ngau nhien.
func medium_move() -> void:
	while game_handle.dice.remaining_points > 0 and not game_handle.game_ended:
		var possible_moves: Array = get_all_possible_moves()

		if possible_moves.is_empty():
			print("🟡 Medium không còn nước đi! → Bỏ qua điểm còn lại.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		var best_move = null
		var best_value: int = -1

		for move in possible_moves:
			var target_piece = board_handle.get_piece_at(move["target"])

			# Co quan Trang tai o dich thi day la nuoc an.
			if target_piece != null and target_piece.color != Globals.COLORS.BLACK:
				var value: int = get_piece_value(target_piece.piece_type)
				if value > best_value:
					best_value = value
					best_move = move

		if best_move == null:
			best_move = possible_moves.pick_random()

		var piece = best_move["piece"]
		var target_position: Vector2 = best_move["target"]

		print("🟡 Medium chọn: ", piece.piece_type, " -> ", target_position)
		board_handle.highlight_bot_move(piece, target_position)
		await get_tree().create_timer(0.7).timeout
		board_handle.clear_highlight_cells()

		if game_handle.game_ended:
			return

		board_handle.execute_move(piece, target_position)

		if game_handle.game_ended:
			return

		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(1.0).timeout


# Hard: chuyen toan bo viec lua chon va thuc hien chien thuat cho hard_bot.gd.
func hard_move() -> void:
	if hard_bot_instance == null:
		hard_bot_instance = HARD_BOT_SCRIPT.new()
		add_child(hard_bot_instance)
		hard_bot_instance.setup(game_handle, board_handle)

	await hard_bot_instance.take_turn()


# Lay tat ca nuoc di hop le cua quan Den theo so diem con lai.
# Duoc Easy va Medium su dung.
func get_all_possible_moves() -> Array:
	var possible_moves: Array = []

	for piece in board_handle.pieces:
		if piece.color != Globals.COLORS.BLACK:
			continue

		var scan_result = piece.scan_piece(game_handle.dice.remaining_points)
		for result in scan_result:
			for target_position in result["positions"]:
				possible_moves.append({
					"piece": piece,
					"target": target_position
				})

	return possible_moves


# Lay cac phuong an doi quan du bi cua Den.
# Giu lai de tranh pha vo cac noi goi ben ngoai (neu co); Hard Bot moi co logic rieng.
func get_all_possible_swaps() -> Array:
	var possible_swaps: Array = []

	if not board_handle.ui.black_reserve_unlocked:
		return possible_swaps

	if game_handle.has_swapped_this_turn:
		return possible_swaps

	var black_reserve = board_handle.ui.black_reserve
	for reserve_slot in black_reserve.get_children():
		if reserve_slot in board_handle.used_reserve_slots:
			continue
		if not reserve_slot.has_meta("piece_type"):
			continue

		var reserve_type = reserve_slot.get_meta("piece_type")
		for piece in board_handle.pieces:
			if piece.color != Globals.COLORS.BLACK:
				continue
			if not board_handle.can_swap_piece(piece, reserve_type):
				continue

			possible_swaps.append({
				"piece": piece,
				"reserve_type": reserve_type,
				"reserve_slot": reserve_slot
			})

	return possible_swaps


# Tra ve gia tri quy uoc cua tung loai quan; Medium dung de uu tien muc tieu an.
func get_piece_value(piece_type: int) -> int:
	match piece_type:
		Globals.PIECE_TYPES.KING:
			return 10000
		Globals.PIECE_TYPES.QUEEN:
			return 900
		Globals.PIECE_TYPES.ROOK:
			return 500
		Globals.PIECE_TYPES.BISHOP:
			return 300
		Globals.PIECE_TYPES.PAWN:
			return 100

	return 0


# Diem vao chinh cua AI: dieu phoi theo do kho dang duoc chon.
func make_move() -> void:
	match Globals.ai_difficulty:
		Globals.AI_DIFFICULTY.EASY:
			await easy_move()
		Globals.AI_DIFFICULTY.MEDIUM:
			await medium_move()
		Globals.AI_DIFFICULTY.HARD:
			await hard_move()
		Globals.AI_DIFFICULTY.INSANE:
			print("🟣 Insane chưa phát triển")
		Globals.AI_DIFFICULTY.EXTREME:
			print("💀 Extreme chưa phát triển")
