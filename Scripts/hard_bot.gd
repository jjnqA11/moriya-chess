extends Node

# Hard Bot - Giai doan 1
# Muc tieu: uu tien giam nguy co Vua Den bi bat trong luot tiep theo.
# Khong dung Minimax/Alpha-Beta. Khong thay doi luat trong board.gd/piece.gd.

const BOARD_WIDTH := 6
const BOARD_HEIGHT := 8
const MAX_SEARCH_NODES_PER_DICE := 180
# Bat log chi tiet de kiem tra cach bot danh gia tung ung vien.
# Tat thanh false sau khi tim duoc nguyen nhan neu log qua nhieu.
const DEBUG_ACTION_EVALUATION := false
const FORCE_FULL_DICE_EVALUATION := false

const SEARCH_UNKNOWN := -1
const SEARCH_SAFE := 0
const SEARCH_THREAT := 1

var game_handle
var board_handle
var hard_turn_count: int = 0
# Bang tra cuu tam thoi cho cac trang thai gia lap.
# Key la Vector2i(x, y), value la piece node dang o o do.
var _sim_grid: Dictionary = {}


func setup(game, board) -> void:
	game_handle = game
	board_handle = board
	hard_turn_count = 0

# Ham duoc bot.gd goi khi den luot Hard.
func take_turn() -> void:
	hard_turn_count += 1

	print("\n[Hard][TurnCount] Luot bot: ", hard_turn_count)
	
	# KIEM THU TAM THOI: kiem tra kha nang bat Vua voi 1-6 diem.
	while game_handle.dice.remaining_points > 0 and not game_handle.game_ended:
		var actions: Array = []
		var possible_moves = _get_real_board_moves(Globals.COLORS.BLACK, game_handle.dice.remaining_points)

		for move in possible_moves:
			actions.append({"type": "move", "data": move})

		for swap in _get_possible_black_swaps():
			actions.append({"type": "swap", "data": swap})

		if actions.is_empty():
			print("[Hard] Khong con hanh dong hop le; bo qua diem con lai.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			return

		# Neu co the bat Vua Trang ngay, thuc hien ngay va ket thuc.
		var winning_action = _find_immediate_win(actions)
		var chosen_action: Dictionary = {}
		var chosen_risk := 7
		var chosen_tactical := -INF
		var chosen_unknown := 0

		if DEBUG_ACTION_EVALUATION:
			print("\n[Hard][Turn] Diem con lai: ", game_handle.dice.remaining_points,
				" | So ung vien: ", actions.size())
			print("[Hard][Turn] Vua Den: ", _king_position(Globals.COLORS.BLACK),
				" | Vua Trang: ", _king_position(Globals.COLORS.WHITE))

		if not winning_action.is_empty():
			chosen_action = winning_action
			print("[Hard] Tim thay nuoc bat Vua Trang: ", _describe_action(winning_action))
		else:
			# Danh gia nuoc an quan truoc, sau do den nuoc di Vua,
			# de co co hoi tim duoc phuong an an toan tot som hon.
			actions.sort_custom(Callable(self, "_compare_action_order"))
			var candidate_index := 0

			for action in actions:
				candidate_index += 1
				var evaluation = _evaluate_action(action, chosen_risk, FORCE_FULL_DICE_EVALUATION)
				var risk_count: int = evaluation["risk_count"]
				var tactical_score: float = evaluation["tactical_score"]
				var unknown_count: int = evaluation["unknown_count"]
				var decision_note := ""

				# So sanh theo dung thu tu da thong nhat:
				# 1) it ket qua xuc xac nguy hiem hon;
				# 2) neu ngang nhau, diem chien thuat cao hon.
				if chosen_action.is_empty() or risk_count < chosen_risk:
					chosen_action = action
					chosen_risk = risk_count
					chosen_tactical = tactical_score
					chosen_unknown = unknown_count
					decision_note = "TAM THOI CHON: nguy co thap hon / ung vien dau tien"
				elif risk_count == chosen_risk and tactical_score > chosen_tactical:
					chosen_action = action
					chosen_tactical = tactical_score
					chosen_unknown = unknown_count
					decision_note = "TAM THOI CHON: nguy co ngang nhau, diem chien thuat cao hon"
				elif risk_count == chosen_risk and is_equal_approx(tactical_score, chosen_tactical):
					# Giu nguyen cach chon ngau nhien giua cac phuong an ngang diem.
					if randi_range(0, 1) == 1:
						chosen_action = action
						chosen_tactical = tactical_score
						chosen_unknown = unknown_count
						decision_note = "TAM THOI CHON: ngang diem, boc tham ngau nhien"
					else:
						decision_note = "KHONG CHON: ngang diem, boc tham khong chon"
				else:
					if risk_count > chosen_risk:
						decision_note = "KHONG CHON: so ket qua nguy hiem cao hon"
					else:
						decision_note = "KHONG CHON: nguy co ngang nhau nhung diem chien thuat thap hon"

				if DEBUG_ACTION_EVALUATION:
					print("[Hard][Eval ", candidate_index, "/", actions.size(), "] ", _describe_action(action),
						" | Rui ro: ", risk_count, "/6",
						" | Chua ket luan: ", unknown_count,
						" | Diem chien thuat: ", tactical_score,
						" (goc=", evaluation["base_tactical_score"],
						", dieu chinh an toan=", evaluation["exposure_adjustment"], ")",
						" | Ket qua tung xuc xac: ", _format_dice_results(evaluation["dice_results"]),
						" | Nut tim kiem: ", evaluation["nodes_used"],
						" | ", decision_note)

			if chosen_action.is_empty():
				return

			if DEBUG_ACTION_EVALUATION:
				print("[Hard][Chosen] ", _describe_action(chosen_action),
					" | Rui ro: ", chosen_risk, "/6",
					" | Chua ket luan: ", chosen_unknown,
					" | Diem chien thuat: ", chosen_tactical)
			
				print(
					"[Hard] Ket qua xuc xac can than trong (de doa hoac chua the chung minh an toan): ", chosen_risk, "/6",
					" | Chua ket luan do gioi han tim kiem: ", chosen_unknown,
					" | Diem chien thuat: ", chosen_tactical
				)

		await _execute_action(chosen_action)

		if game_handle.game_ended:
			return

		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(1.2).timeout

func _get_real_board_moves(color: int, points_left: int) -> Array:
	var moves: Array = []
	for piece in board_handle.pieces:
		if piece.color != color:
			continue
		var scan_results = piece.scan_piece(points_left)
		for result in scan_results:
			for target_position in result["positions"]:
				moves.append({"piece": piece, "target": target_position})
	return moves


func _get_possible_black_swaps() -> Array:
	var possible_swaps: Array = []
	if not board_handle.ui.black_reserve_unlocked:
		return possible_swaps
	if game_handle.has_swapped_this_turn:
		return possible_swaps

	var reserve = board_handle.ui.black_reserve
	for reserve_slot in reserve.get_children():
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


func _find_immediate_win(actions: Array) -> Dictionary:
	for action in actions:
		if action["type"] != "move":
			continue
		var move = action["data"]
		var target_piece = board_handle.get_piece_at(move["target"])
		if target_piece != null \
		and target_piece.color == Globals.COLORS.WHITE \
		and target_piece.piece_type == Globals.PIECE_TYPES.KING:
			return action
	return {}


func _compare_action_order(a: Dictionary, b: Dictionary) -> bool:
	return _preliminary_action_priority(a) > _preliminary_action_priority(b)


func _preliminary_action_priority(action: Dictionary) -> int:
	# Thu tu nay chi de thu cac ung vien co kha nang phong thu/tac chien tot som hon.
	# Ket qua cuoi cung van do nguy co mat Vua quyet dinh.
	if action["type"] == "move":
		var move = action["data"]
		var target_piece = board_handle.get_piece_at(move["target"])
		if target_piece != null and target_piece.color == Globals.COLORS.WHITE:
			return 2000 + _piece_value(target_piece.piece_type)
		if move["piece"].piece_type == Globals.PIECE_TYPES.KING:
			return 1000
		return 0
	return -100


func _evaluate_action(action: Dictionary, current_best_risk: int, debug_full_check: bool = false) -> Dictionary:
	var before = _snapshot_board_state()
	var base_tactical_score: float = _base_tactical_score(action)
	var tactical_score: float = base_tactical_score
	var exposure_adjustment: float = 0.0
	var acted_piece = action["data"]["piece"]

	_sim_grid = _build_sim_grid()
	if action["type"] == "move":
		_apply_simulated_move(action["data"])
	else:
		var swap = action["data"]
		acted_piece.piece_type = swap["reserve_type"]
		acted_piece.move_direction = Vector2.ZERO
		acted_piece.captured_this_turn = false
		acted_piece.moved = false

	var after_action = _snapshot_board_state()

	# Danh gia chien thuat phu: neu quan vua di co the bi an ngay bang 1 diem,
	# tru gia tri quan; neu khong, cong mot diem nho cho nuoc di an toan.
	_reset_simulated_turn_states()
	_sim_grid = _build_sim_grid()
	if _is_piece_capturable_by_white(acted_piece.board_position, 1):
		exposure_adjustment = -float(_piece_value(acted_piece.piece_type))
	else:
		exposure_adjustment = 50.0
	tactical_score += exposure_adjustment

	var risk_count := 0
	var unknown_count := 0
	var dice_results: Array = []
	var nodes_used := 0
	for dice_value in range(1, 7):
		_restore_board_state(after_action)
		_reset_simulated_turn_states()
		_sim_grid = _build_sim_grid()

		var visited: Dictionary = {}
		var budget: Array = [MAX_SEARCH_NODES_PER_DICE]
		var result: int = _search_white_king_capture(dice_value, visited, budget)
		var used_this_dice: int = MAX_SEARCH_NODES_PER_DICE - int(budget[0])
		nodes_used += used_this_dice
		dice_results.append({
			"dice": dice_value,
			"result": result,
			"nodes": used_this_dice
		})

		if result != SEARCH_SAFE:
			# Neu cham gioi han tim kiem, tinh ket qua nay la nguy co
			# de bot khong tu nhan rang mot trang thai chua duoc kiem chung la an toan.
			risk_count += 1
		if result == SEARCH_UNKNOWN:
			unknown_count += 1

		# Neu da co nhieu ket qua nguy hiem hon phuong an tot nhat hien tai,
		# khong can danh gia tiep cac ket qua xuc xac con lai cua ung vien nay.
		if not debug_full_check and risk_count > current_best_risk:
			break

	_restore_board_state(before)
	_sim_grid = _build_sim_grid()
	return {
		"risk_count": risk_count,
		"unknown_count": unknown_count,
		"tactical_score": tactical_score,
		"base_tactical_score": base_tactical_score,
		"exposure_adjustment": exposure_adjustment,
		"dice_results": dice_results,
		"nodes_used": nodes_used
	}


func _describe_action(action: Dictionary) -> String:
	if action.is_empty():
		return "<rong>"
	if action["type"] == "move":
		var move = action["data"]
		var piece = move["piece"]
		var target_position: Vector2 = move["target"]
		var destination_piece = board_handle.get_piece_at(target_position)
		var target_text := "o trong"
		if destination_piece != null:
			target_text = "an " + _piece_type_name(destination_piece.piece_type) \
				+ (" Trang" if destination_piece.color == Globals.COLORS.WHITE else " Den")
		return "DI CHUYEN " + _piece_type_name(piece.piece_type) \
			+ (" Den" if piece.color == Globals.COLORS.BLACK else " Trang") \
			+ " tu " + str(piece.board_position) + " den " + str(target_position) \
			+ " | chi phi=" + str(_move_cost(piece.board_position, target_position)) \
			+ " | dich=" + target_text
	var swap = action["data"]
	return "DOI QUAN o " + str(swap["piece"].board_position) \
		+ ": " + _piece_type_name(swap["piece"].piece_type) \
		+ " -> " + _piece_type_name(swap["reserve_type"])


func _piece_type_name(piece_type: int) -> String:
	match piece_type:
		Globals.PIECE_TYPES.KING:
			return "Vua"
		Globals.PIECE_TYPES.QUEEN:
			return "Hau"
		Globals.PIECE_TYPES.ROOK:
			return "Xe"
		Globals.PIECE_TYPES.BISHOP:
			return "Tuong"
		Globals.PIECE_TYPES.PAWN:
			return "Tot"
	return "Loai(" + str(piece_type) + ")"


func _king_position(color: int) -> String:
	for piece in board_handle.pieces:
		if piece.color == color and piece.piece_type == Globals.PIECE_TYPES.KING:
			return str(piece.board_position)
	return "KHONG TIM THAY"


func _format_dice_results(results: Array) -> String:
	var labels: Array[String] = []
	for item in results:
		var outcome := "?"
		match int(item["result"]):
			SEARCH_SAFE:
				outcome = "AN TOAN"
			SEARCH_THREAT:
				outcome = "CO THE BAT VUA"
			SEARCH_UNKNOWN:
				outcome = "CHUA KET LUAN"
		labels.append(str(item["dice"]) + ":" + outcome + "(" + str(item["nodes"]) + " nut)")
	return "[" + ", ".join(labels) + "]"


func _base_tactical_score(action: Dictionary) -> float:
	if action["type"] == "move":
		var move = action["data"]
		var target_piece = board_handle.get_piece_at(move["target"])
		if target_piece != null and target_piece.color == Globals.COLORS.WHITE:
			if target_piece.piece_type == Globals.PIECE_TYPES.KING:
				return 1000000000.0
			return float(_piece_value(target_piece.piece_type))
		return 0.0

	var swap = action["data"]
	var old_value = _piece_value(swap["piece"].piece_type)
	var new_value = _piece_value(swap["reserve_type"])
	return float(int((new_value - old_value) * 0.5))


func _execute_action(action: Dictionary) -> void:
	if action["type"] == "move":
		var move = action["data"]
		var piece = move["piece"]
		var target_position = move["target"]
		print("[Hard] Di chuyen: ", piece.piece_type, " -> ", target_position)
		board_handle.highlight_bot_move(piece, target_position)
		await get_tree().create_timer(0.6).timeout
		board_handle.clear_highlight_cells()
		board_handle.ui.clear_reserve_highlights()
		if game_handle.game_ended:
			return
		board_handle.execute_move(piece, target_position)
	else:
		var swap = action["data"]
		print("[Hard] Doi quan: ", swap["piece"].piece_type, " -> ", swap["reserve_type"])
		board_handle.highlight_bot_swap(swap["piece"], swap["reserve_slot"])
		await get_tree().create_timer(0.8).timeout
		board_handle.clear_highlight_cells()
		board_handle.ui.clear_reserve_highlights()
		if game_handle.game_ended:
			return
		board_handle.swap_with_reserve(
			swap["piece"],
			swap["reserve_type"],
			swap["reserve_slot"]
		)


# ------------------------------------------------------------------
# Mo phong nuoc di: chi thay doi du lieu logic trong thoi gian dong bo.
# Khong goi execute_move/swap_with_reserve, khong di chuyen Sprite2D,
# khong queue_free node that trong luc tinh toan.
# ------------------------------------------------------------------

func _snapshot_board_state() -> Dictionary:
	var piece_list: Array = board_handle.pieces.duplicate()
	var states: Array = []
	for piece in piece_list:
		states.append({
			"piece": piece,
			"piece_type": piece.piece_type,
			"board_position": piece.board_position,
			"move_direction": piece.move_direction,
			"captured_this_turn": piece.captured_this_turn,
			"moved": piece.moved
		})
	return {"piece_list": piece_list, "states": states}


func _restore_board_state(snapshot: Dictionary) -> void:
	board_handle.pieces.clear()
	for piece in snapshot["piece_list"]:
		board_handle.pieces.append(piece)
	for state in snapshot["states"]:
		var piece = state["piece"]
		piece.piece_type = state["piece_type"]
		piece.board_position = state["board_position"]
		piece.move_direction = state["move_direction"]
		piece.captured_this_turn = state["captured_this_turn"]
		piece.moved = state["moved"]
	_sim_grid = _build_sim_grid()


func _build_sim_grid() -> Dictionary:
	var grid: Dictionary = {}
	for piece in board_handle.pieces:
		grid[_cell_key(piece.board_position)] = piece
	return grid


func _cell_key(position_on_board: Vector2) -> Vector2i:
	return Vector2i(int(position_on_board.x), int(position_on_board.y))


func _is_inside_board(position_on_board: Vector2) -> bool:
	return position_on_board.x >= 0 and position_on_board.x < BOARD_WIDTH \
		and position_on_board.y >= 0 and position_on_board.y < BOARD_HEIGHT


func _reset_simulated_turn_states() -> void:
	# Giong board.reset_piece_directions() khi bat dau luot moi.
	for piece in board_handle.pieces:
		piece.move_direction = Vector2.ZERO
		piece.moved = false
		piece.captured_this_turn = false


func _generate_simulated_moves(color: int, points_left: int) -> Array:
	var moves: Array = []
	if points_left <= 0:
		return moves
	for piece in board_handle.pieces:
		if piece.color != color:
			continue
		for target_position in _generate_simulated_piece_targets(piece, points_left):
			moves.append({"piece": piece, "target": target_position})
	return moves


func _generate_simulated_piece_targets(piece, points_left: int) -> Array:
	var targets: Array = []
	if points_left <= 0:
		return targets
	
	# Vua chỉ được mô phỏng di chuyển khi đã đủ điều kiện.
	if piece.piece_type == Globals.PIECE_TYPES.KING:
		if not board_handle.can_king_move_this_turn(piece):
			return targets
	
	# Tot: di thang 1 o neu trong; an cheo 1 o; moi luot chi di mot lan.
	if piece.piece_type == Globals.PIECE_TYPES.PAWN:
		if piece.moved:
			return targets
		var forward_y := -1 if piece.color == Globals.COLORS.WHITE else 1
		var forward_position: Vector2 = piece.board_position + Vector2(0, forward_y)
		if _is_inside_board(forward_position) and not _sim_grid.has(_cell_key(forward_position)):
			targets.append(forward_position)
		for dx in [-1, 1]:
			var capture_position: Vector2 = piece.board_position + Vector2(dx, forward_y)
			if not _is_inside_board(capture_position):
				continue
			var target_piece = _sim_grid.get(_cell_key(capture_position))
			if target_piece != null and target_piece.color != piece.color:
				targets.append(capture_position)
		return targets

	# Cac quan khac Vua khong di tiep duoc sau khi an quan trong cung luot.
	if piece.piece_type != Globals.PIECE_TYPES.KING and piece.captured_this_turn:
		return targets

	var directions: Array = []
	if piece.move_direction != Vector2.ZERO:
		directions.append(piece.move_direction)
	else:
		match piece.piece_type:
			Globals.PIECE_TYPES.ROOK:
				directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
			Globals.PIECE_TYPES.BISHOP:
				directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
			Globals.PIECE_TYPES.QUEEN, Globals.PIECE_TYPES.KING:
				directions = [
					Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
					Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
				]
			_:
				return targets

	for direction in directions:
		for distance in range(1, points_left + 1):
			var target_position: Vector2 = piece.board_position + direction * distance
			if not _is_inside_board(target_position):
				break
			var target_piece = _sim_grid.get(_cell_key(target_position))
			if target_piece == null:
				targets.append(target_position)
				continue
			if target_piece.color != piece.color:
				targets.append(target_position)
			break
	return targets


func _search_white_king_capture(points_left: int, visited: Dictionary, budget: Array) -> int:
	if points_left <= 0:
		return SEARCH_SAFE

	var state_key = _make_search_state_key(points_left)
	if visited.has(state_key):
		return int(visited[state_key])
	if budget[0] <= 0:
		visited[state_key] = SEARCH_UNKNOWN
		return SEARCH_UNKNOWN
	budget[0] -= 1

	var moves = _generate_simulated_moves(Globals.COLORS.WHITE, points_left)

	# Kiem tra truoc cac nuoc bat Vua truc tiep, tranh mo rong nhanh khong can thiet.
	for move in moves:
		var target_piece = _sim_grid.get(_cell_key(move["target"]))
		if target_piece != null \
		and target_piece.color == Globals.COLORS.BLACK \
		and target_piece.piece_type == Globals.PIECE_TYPES.KING:
			visited[state_key] = SEARCH_THREAT
			return SEARCH_THREAT

	var saw_unknown := false
	# Thu cac nuoc an quan truoc, vi chung co the mo duong tan cong.
	for capture_pass in range(2):
		for move in moves:
			var target_piece = _sim_grid.get(_cell_key(move["target"]))
			var is_capture = target_piece != null
			if capture_pass == 0 and not is_capture:
				continue
			if capture_pass == 1 and is_capture:
				continue

			var move_cost = _move_cost(move["piece"].board_position, move["target"])
			if move_cost >= points_left:
				continue

			var undo_state = _apply_simulated_move(move)
			var result = _search_white_king_capture(points_left - move_cost, visited, budget)
			_undo_simulated_move(undo_state)

			if result == SEARCH_THREAT:
				visited[state_key] = SEARCH_THREAT
				return SEARCH_THREAT
			if result == SEARCH_UNKNOWN:
				saw_unknown = true
			if budget[0] <= 0:
				visited[state_key] = SEARCH_UNKNOWN
				return SEARCH_UNKNOWN

	var final_result := SEARCH_UNKNOWN if saw_unknown else SEARCH_SAFE
	visited[state_key] = final_result
	return final_result

func _make_search_state_key(points_left: int) -> String:
	var pieces_key = str(points_left)
	for piece in board_handle.pieces:
		pieces_key += ";" + str(piece.get_instance_id()) \
			+ "," + str(piece.piece_type) \
			+ "," + str(piece.board_position.x) \
			+ "," + str(piece.board_position.y) \
			+ "," + str(piece.move_direction.x) \
			+ "," + str(piece.move_direction.y) \
			+ "," + str(int(piece.moved)) \
			+ "," + str(int(piece.captured_this_turn))
	return pieces_key


func _apply_simulated_move(move: Dictionary) -> Dictionary:
	var piece = move["piece"]
	var target_position: Vector2 = move["target"]
	var old_position: Vector2 = piece.board_position
	var old_direction: Vector2 = piece.move_direction
	var old_captured: bool = piece.captured_this_turn
	var old_moved: bool = piece.moved
	var target_key = _cell_key(target_position)
	var captured_piece = _sim_grid.get(target_key)
	var captured_index := -1
	if captured_piece != null:
		captured_index = board_handle.pieces.find(captured_piece)
		if captured_index >= 0:
			board_handle.pieces.remove_at(captured_index)
		_sim_grid.erase(target_key)

	var next_direction = old_direction
	match piece.piece_type:
		Globals.PIECE_TYPES.ROOK:
			next_direction = piece.get_move_direction(target_position)
		Globals.PIECE_TYPES.BISHOP:
			next_direction = piece.get_bishop_direction(target_position)
		Globals.PIECE_TYPES.QUEEN:
			next_direction = piece.get_queen_direction(target_position)
		Globals.PIECE_TYPES.KING:
			if captured_piece != null:
				next_direction = Vector2.ZERO
			else:
				next_direction = piece.get_queen_direction(target_position)

	_sim_grid.erase(_cell_key(old_position))
	piece.board_position = target_position
	piece.move_direction = next_direction
	piece.moved = true
	if captured_piece != null:
		piece.captured_this_turn = true
	_sim_grid[target_key] = piece

	return {
		"piece": piece,
		"old_position": old_position,
		"old_direction": old_direction,
		"old_captured": old_captured,
		"old_moved": old_moved,
		"captured_piece": captured_piece,
		"captured_index": captured_index,
		"target_position": target_position
	}


func _undo_simulated_move(state: Dictionary) -> void:
	var piece = state["piece"]
	var target_position: Vector2 = state["target_position"]
	_sim_grid.erase(_cell_key(target_position))
	piece.board_position = state["old_position"]
	piece.move_direction = state["old_direction"]
	piece.captured_this_turn = state["old_captured"]
	piece.moved = state["old_moved"]
	_sim_grid[_cell_key(piece.board_position)] = piece

	var captured_piece = state["captured_piece"]
	if captured_piece != null:
		var insert_index: int = clampi(state["captured_index"], 0, board_handle.pieces.size())
		board_handle.pieces.insert(insert_index, captured_piece)
		_sim_grid[_cell_key(captured_piece.board_position)] = captured_piece


func _move_cost(from_position: Vector2, to_position: Vector2) -> int:
	return int(max(abs(to_position.x - from_position.x), abs(to_position.y - from_position.y)))


func _is_piece_capturable_by_white(target_position: Vector2, points: int) -> bool:
	for move in _generate_simulated_moves(Globals.COLORS.WHITE, points):
		if move["target"] == target_position:
			return true
	return false


func _piece_value(piece_type: int) -> int:
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
