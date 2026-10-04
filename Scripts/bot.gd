extends Node

var game_handle
var board_handle

func setup(game, board):
	game_handle = game
	board_handle = board


func easy_move():
	while game_handle.dice.remaining_points > 0:
		var possible_moves = get_all_possible_moves()

		if possible_moves.is_empty():
			print("🤖 Bot không còn nước đi! → Skip phần điểm còn lại.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		var random_move = possible_moves.pick_random()

		var piece = random_move["piece"]
		var target_position = random_move["target"]

		print("🤖 Bot chọn: ", piece.piece_type, " -> ", target_position)
		board_handle.highlight_bot_move(piece, target_position)
		await get_tree().create_timer(0.7).timeout
		board_handle.clear_highlight_cells()
		if game_handle.game_ended:
			return
		board_handle.execute_move(piece, target_position)

		# Chờ một chút để người chơi nhìn thấy Bot vừa đi
		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(2).timeout

func medium_move():
	while game_handle.dice.remaining_points > 0:
		var possible_moves = get_all_possible_moves()

		# Không còn nước đi
		if possible_moves.is_empty():
			print("🟡 Medium không còn nước đi! → Bỏ qua điểm còn lại.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		# Tìm nước ăn quân tốt nhất
		var best_move = null
		var best_value = -1

		for move in possible_moves:
			var target_position = move["target"]
			var target_piece = board_handle.get_piece_at(target_position)

			# Có quân đối phương ở ô đích → đây là nước ăn
			if target_piece != null and target_piece.color != Globals.COLORS.BLACK:
				var value = get_piece_value(target_piece.piece_type)

				if value > best_value:
					best_value = value
					best_move = move

		# Không ăn được quân nào → đi ngẫu nhiên
		if best_move == null:
			best_move = possible_moves.pick_random()

		var piece = best_move["piece"]
		var target_position = best_move["target"]

		print("🟡 Medium chọn: ", piece.piece_type, " -> ", target_position)
		board_handle.highlight_bot_move(piece, target_position)
		await get_tree().create_timer(0.7).timeout
		board_handle.clear_highlight_cells()
		if game_handle.game_ended:
			return
		board_handle.execute_move(piece, target_position)

		# Nếu vừa ăn King thì trận đấu đã kết thúc
		if game_handle.game_ended:
			return

		# Nếu vẫn còn điểm thì chờ một chút rồi tính tiếp
		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(1).timeout

func hard_move():
	while game_handle.dice.remaining_points > 0:
		var actions = []

		# ==========================================
		# 1. THÊM CÁC HÀNH ĐỘNG DI CHUYỂN
		# ==========================================
		var possible_moves = get_all_possible_moves()

		for move in possible_moves:
			var score = evaluate_hard_move(move)

			actions.append({
				"type": "move",
				"data": move,
				"score": score
			})

		# ==========================================
		# 2. THÊM CÁC HÀNH ĐỘNG SWAP
		# ==========================================
		var possible_swaps = get_all_possible_swaps()

		for swap in possible_swaps:
			var score = evaluate_hard_swap(swap)

			actions.append({
				"type": "swap",
				"data": swap,
				"score": score
			})

		# ==========================================
		# 3. KHÔNG CÒN HÀNH ĐỘNG
		# ==========================================
		if actions.is_empty():
			print("🔴 Hard không còn hành động! → Bỏ qua điểm còn lại.")

			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		# ==========================================
		# 4. TÌM HÀNH ĐỘNG CÓ ĐIỂM CAO NHẤT
		# ==========================================
		var best_score = -999999
		var best_actions = []

		for action in actions:
			print(
				"🔴 Hard đánh giá ",
				action["type"],
				"| Điểm: ",
				action["score"]
			)

			if action["score"] > best_score:
				best_score = action["score"]
				best_actions.clear()
				best_actions.append(action)

			elif action["score"] == best_score:
				best_actions.append(action)

		# Nếu nhiều hành động bằng điểm → chọn ngẫu nhiên
		var best_action = best_actions.pick_random()

		# ==========================================
			# 5. THỰC HIỆN HÀNH ĐỘNG ĐÃ CHỌN
		# ==========================================
		if best_action["type"] == "move":
			var move = best_action["data"]

			var piece = move["piece"]
			var target_position = move["target"]

			print(
				"🔴 Hard chọn DI CHUYỂN: ",
				piece.piece_type,
				" -> ",
				target_position,
				"| Điểm: ",
				best_score
			)
			board_handle.highlight_bot_move(piece, target_position)
			await get_tree().create_timer(1.2).timeout
			board_handle.clear_highlight_cells()
			board_handle.ui.clear_reserve_highlights()
			
			if game_handle.game_ended:
				return
			
			board_handle.execute_move( piece, target_position )

		elif best_action["type"] == "swap":
			var swap = best_action["data"]

			var piece = swap["piece"]
			var reserve_type = swap["reserve_type"]
			var reserve_slot = swap["reserve_slot"]

			print(
				"🔴 Hard chọn SWAP: ",
				piece.piece_type,
				" -> ",
				reserve_type,
				"| Điểm: ",
				best_score
			)

			# Highlight quân trên bàn + quân dự bị
			board_handle.highlight_bot_swap(piece, reserve_slot )

			# Cho người chơi thời gian nhìn
			await get_tree().create_timer(1.5).timeout

			# Xóa highlight
			board_handle.clear_highlight_cells()
			board_handle.ui.clear_reserve_highlights()

			if game_handle.game_ended:
				return

			# Thực hiện Swap
			board_handle.swap_with_reserve(piece, reserve_type, reserve_slot)

		# ==========================================
		# 6. GAME OVER
		# ==========================================
		if game_handle.game_ended:
			return

		# ==========================================
		# 7. CHỜ GIỮA CÁC NƯỚC
		# ==========================================
		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(2).timeout

func get_all_possible_moves():
	var possible_moves = []
	
	for piece in board_handle.pieces:
		# Chỉ lấy quân của Bot
		if piece.color != Globals.COLORS.BLACK:
			continue
		
		var scan_result = piece.scan_piece(
			game_handle.dice.remaining_points
		)
		
		for result in scan_result:
			for target_position in result["positions"]:
				possible_moves.append({
					"piece": piece,
					"target": target_position
				})
	
	return possible_moves

func get_all_possible_swaps():
	var possible_swaps = []

	# Chưa mở khóa dự bị → không thể Swap
	if not board_handle.ui.black_reserve_unlocked:
		return possible_swaps

	# Đã Swap trong lượt này → không thể tiếp tục Swap
	if game_handle.has_swapped_this_turn:
		return possible_swaps

	var black_reserve = board_handle.ui.black_reserve

	# Duyệt 3 ô dự bị: Xe / Tượng / Hậu
	for reserve_slot in black_reserve.get_children():

		# Slot đã sử dụng → bỏ qua
		if reserve_slot in board_handle.used_reserve_slots:
			continue

		var reserve_type = reserve_slot.get_meta("piece_type")

		# Tìm tất cả quân Đen có thể đổi
		for piece in board_handle.pieces:

			if not board_handle.can_swap_piece(
				piece,
				reserve_type
			):
				continue

			possible_swaps.append({
				"piece": piece,
				"reserve_type": reserve_type,
				"reserve_slot": reserve_slot
			})

	return possible_swaps

func get_future_opponent_capture_score(move):
	var piece = move["piece"]
	var target_position = move["target"]

	var old_position = piece.board_position
	var captured_piece = board_handle.get_piece_at(target_position)

	var captured_index = -1

	# ==========================================
	# GIẢ LẬP NƯỚC ĐI
	# ==========================================

	if captured_piece != null:
		captured_index = board_handle.pieces.find(
			captured_piece
		)

		board_handle.pieces.remove_at(
			captured_index
		)

	piece.board_position = target_position

	# ==========================================
	# THỬ 6 KẾT QUẢ XÚC XẮC
	# ==========================================

	var total_risk = 0.0

	for dice_value in range(1, 7):

		var best_capture = get_best_capture_value(
			Globals.COLORS.WHITE,
			Globals.COLORS.BLACK,
			dice_value
		)

		total_risk += best_capture

	# ==========================================
	# KHÔI PHỤC TRẠNG THÁI
	# ==========================================

	piece.board_position = old_position

	if captured_piece != null:
		board_handle.pieces.insert(
			captured_index,
			captured_piece
		)

	# Xúc xắc 1-6 có xác suất ngang nhau
	return total_risk / 6.0

func get_future_opponent_capture_score_after_swap(swap):
	var piece = swap["piece"]
	var reserve_type = swap["reserve_type"]

	var old_type = piece.piece_type
	var old_captured = piece.captured_this_turn
	var old_direction = piece.move_direction
	var old_moved = piece.moved

	# Giả lập quân mới
	piece.piece_type = reserve_type
	piece.captured_this_turn = false
	piece.move_direction = Vector2.ZERO
	piece.moved = false

	var total_risk = 0.0

	for dice_value in range(1, 7):

		var best_capture = get_best_capture_value(
			Globals.COLORS.WHITE,
			Globals.COLORS.BLACK,
			dice_value
		)

		total_risk += best_capture

	# Khôi phục
	piece.piece_type = old_type
	piece.captured_this_turn = old_captured
	piece.move_direction = old_direction
	piece.moved = old_moved

	return total_risk / 6.0

func get_piece_value(piece_type):
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

func evaluate_hard_move(move):
	var piece = move["piece"]

	var score = 0

	# ==========================================
	# VUA → ĐÁNH GIÁ CẢ CHUỖI ĂN
	# ==========================================

	if piece.piece_type == Globals.PIECE_TYPES.KING:

		score = evaluate_king_chain(move)

		# Có thể ăn Vua trong chuỗi
		if score >= 1000000:
			return 1000000

	else:

		# ======================================
		# QUÂN THƯỜNG → CÁCH TÍNH CŨ
		# ======================================

		var target_position = move["target"]

		var target_piece = board_handle.get_piece_at(target_position)

		if target_piece != null:
			if target_piece.color == Globals.COLORS.WHITE:

				if target_piece.piece_type == Globals.PIECE_TYPES.KING:
					return 1000000

				score += get_piece_value(target_piece.piece_type)

	# ==========================================
	# KIỂM TRA CÓ BỊ ĂN NGAY KHÔNG
	# ==========================================

	if is_move_dangerous(move):
		score -= get_piece_value(
			piece.piece_type
		)
	else:
		score += 50

	return score

func evaluate_hard_swap(swap):
	var piece = swap["piece"]
	var reserve_type = swap["reserve_type"]

	var old_value = get_piece_value(
		piece.piece_type
	)

	var new_value = get_piece_value(
		reserve_type
	)

	var score = 0

	# ==========================================
	# 1. GIÁ TRỊ QUÂN MỚI
	# ==========================================

	score += int(
		(new_value - old_value) * 0.5
	)

	# ==========================================
	# 2. KHẢ NĂNG TẤN CÔNG
	# ==========================================

	score += get_swap_capture_bonus(
		piece,
		reserve_type
	)

	# ==========================================
	# 3. NGUY CƠ SAU KHI SWAP
	# ==========================================

	var future_risk = get_future_opponent_capture_score_after_swap(
		swap
	)

	score -= int(future_risk)

	return score

func evaluate_king_chain(move):
	var piece = move["piece"]
	var target_position = move["target"]

	var direction = Vector2(
		sign(target_position.x - piece.board_position.x),
		sign(target_position.y - piece.board_position.y)
	)

	return simulate_king_move_for_chain(
		piece,
		target_position,
		direction,
		game_handle.dice.remaining_points
	)

func search_king_capture_chain(piece, points_left):
	if points_left <= 0:
		return 0

	var best_score = 0

	var scan_results = piece.scan_piece(points_left)

	for result in scan_results:
		var direction = result["direction"]

		for target_position in result["positions"]:
			var target_piece = board_handle.get_piece_at(
				target_position
			)

			# Chỉ quan tâm nước ĂN quân
			if target_piece == null:
				continue

			if target_piece.color != Globals.COLORS.WHITE:
				continue

			var move_cost = max(
				abs(
					target_position.x
					- piece.board_position.x
				),
				abs(
					target_position.y
					- piece.board_position.y
				)
			)

			if move_cost > points_left:
				continue

			var score = simulate_king_move_for_chain(
				piece,
				target_position,
				direction,
				points_left
			)

			if score > best_score:
				best_score = score

			# Đã tìm được đường ăn Vua
			if best_score >= 1000000:
				return best_score

	return best_score

func simulate_king_move_for_chain(
	piece,
	target_position,
	direction,
	points_left
):
	var old_position = piece.board_position
	var old_direction = piece.move_direction
	var old_captured = piece.captured_this_turn
	var old_moved = piece.moved

	var target_piece = board_handle.get_piece_at(
		target_position
	)

	var captured_index = -1
	var capture_score = 0

	# ==========================================
	# KIỂM TRA QUÂN BỊ ĂN
	# ==========================================

	if target_piece != null:

		if target_piece.color != Globals.COLORS.WHITE:
			return -999999

		# Ăn Vua = thắng
		if target_piece.piece_type == Globals.PIECE_TYPES.KING:
			return 1000000

		capture_score = get_piece_value(
			target_piece.piece_type
		)

		captured_index = board_handle.pieces.find(
			target_piece
		)

		board_handle.pieces.remove_at(
			captured_index
		)

	# ==========================================
	# GIẢ LẬP DI CHUYỂN
	# ==========================================

	piece.board_position = target_position
	piece.moved = true

	# ==========================================
	# CẬP NHẬT HƯỚNG GIỐNG GAME THẬT
	# ==========================================

	if target_piece != null:
		# Ăn quân → mở lại 8 hướng
		piece.move_direction = Vector2.ZERO
		piece.captured_this_turn = true
	else:
		# Không ăn → tiếp tục cùng hướng
		piece.move_direction = direction

	# ==========================================
	# TRỪ ĐIỂM
	# ==========================================

	var move_cost = max(
		abs(
			target_position.x
			- old_position.x
		),
		abs(
			target_position.y
			- old_position.y
		)
	)

	var remaining_points = points_left - move_cost

	var total_score = capture_score

	# ==========================================
	# CÒN ĐIỂM → TÌM NƯỚC ĂN TIẾP
	# ==========================================

	if remaining_points > 0:
		total_score += search_king_capture_chain(
			piece,
			remaining_points
		)

	# ==========================================
	# KHÔI PHỤC BÀN CỜ
	# ==========================================

	piece.board_position = old_position
	piece.move_direction = old_direction
	piece.captured_this_turn = old_captured
	piece.moved = old_moved

	if target_piece != null:
		board_handle.pieces.insert(
			captured_index,
			target_piece
		)

	return total_score

func get_swap_capture_bonus(piece, reserve_type):
	var bonus = 0

	# Lưu trạng thái cũ
	var old_type = piece.piece_type
	var old_captured = piece.captured_this_turn
	var old_direction = piece.move_direction
	var old_moved = piece.moved

	# Giả lập quân dự bị
	piece.piece_type = reserve_type
	piece.captured_this_turn = false
	piece.move_direction = Vector2.ZERO
	piece.moved = false

	var scan_result = piece.scan_piece(1)

	for result in scan_result:
		for position in result["positions"]:

			var target_piece = board_handle.get_piece_at(position)

			if target_piece != null:
				if target_piece.color == Globals.COLORS.WHITE:

					if target_piece.piece_type == Globals.PIECE_TYPES.KING:
						bonus += 10000
					else:
						bonus += int(
							get_piece_value(target_piece.piece_type) * 0.5
						)

	# Khôi phục
	piece.piece_type = old_type
	piece.captured_this_turn = old_captured
	piece.move_direction = old_direction
	piece.moved = old_moved

	return bonus

func get_best_capture_value(
	attacker_color,
	target_color,
	movement_points
):
	var best_value = 0

	for piece in board_handle.pieces:

		if piece.color != attacker_color:
			continue

		var scan_result = piece.scan_piece(movement_points)

		for result in scan_result:

			for position in result["positions"]:

				var target_piece = board_handle.get_piece_at(position)

				if target_piece == null:
					continue

				if target_piece.color != target_color:
					continue

				# Ăn Vua = giá trị cực lớn
				if target_piece.piece_type == Globals.PIECE_TYPES.KING:
					return 1000000

				var value = get_piece_value(
					target_piece.piece_type
				)

				if value > best_value:
					best_value = value

	return best_value

func is_move_dangerous(move):
	var piece = move["piece"]
	var target_position = move["target"]

	var old_position = piece.board_position
	var captured_piece = board_handle.get_piece_at(target_position)

	var captured_index = -1

	# Tạm thời bỏ quân sẽ bị ăn
	if captured_piece != null:
		captured_index = board_handle.pieces.find(
			captured_piece
		)

		board_handle.pieces.remove_at(
			captured_index
		)

	# Tạm di chuyển quân
	piece.board_position = target_position

	var dangerous = false

	# Xem quân Trắng có thể ăn ô này không
	for enemy_piece in board_handle.pieces:

		if enemy_piece.color != Globals.COLORS.WHITE:
			continue

		var scan_result = enemy_piece.scan_piece(1)

		for result in scan_result:

			if result["positions"].has(target_position):
				dangerous = true
				break

		if dangerous:
			break

	# Khôi phục
	piece.board_position = old_position

	if captured_piece != null:
		board_handle.pieces.insert(
			captured_index,
			captured_piece
		)

	return dangerous

func is_swap_dangerous(piece):
	var target_position = piece.board_position

	for enemy_piece in board_handle.pieces:

		if enemy_piece.color != Globals.COLORS.WHITE:
			continue

		var scan_result = enemy_piece.scan_piece(1)

		for result in scan_result:

			if result["positions"].has(target_position):
				return true

	return false

func make_move():
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
