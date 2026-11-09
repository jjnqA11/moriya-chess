extends RefCounted

# Hard Bot Calculator
# Bo may tinh toan doc lap, khong truy cap SceneTree, Node, Sprite2D,
# board_handle, piece node hay Autoload Globals.
# Du lieu dau vao/ra chi su dung Array, Dictionary va cac kieu gia tri co ban.

const BOARD_WIDTH := 6
const BOARD_HEIGHT := 8
const MAX_SEARCH_NODES_PER_DICE := 180

# Gia tri enum duoc doi chieu tu Scripts/globals.gd.
const COLOR_BLACK := 0
const COLOR_WHITE := 1

const PIECE_ROOK := 0
const PIECE_BISHOP := 1
const PIECE_QUEEN := 2
const PIECE_KING := 3
const PIECE_PAWN := 4

const ACTION_MOVE := "move"
const ACTION_SWAP := "swap"

const SEARCH_UNKNOWN := -1
const SEARCH_SAFE := 0
const SEARCH_THREAT := 1
const SEARCH_CANCELLED := -2

# API cong khai se duoc hard_bot.gd goi o giai doan ket noi WorkerThreadPool.
#
# board_snapshot co dang:
# {
#     "pieces": [
#         {
#             "id": int,
#             "color": int,
#             "type": int,
#             "x": int,
#             "y": int,
#             "direction_x": int,
#             "direction_y": int,
#             "moved": bool,
#             "captured_this_turn": bool
#         }
#     ]
# }
#
# action_candidates co dang:
# Move: {"type": "move", "piece_id": int, "target_x": int, "target_y": int}
# Swap: {"type": "swap", "piece_id": int, "reserve_type": int}
#
# Thu tu action_candidates phai duoc hard_bot.gd sap xep truoc khi goi ham nay.

func calculate_actions(
	board_snapshot: Dictionary,
	action_candidates: Array,
	force_full_dice_evaluation: bool = false,
	cancel_holder: Array = [],
	cancel_mutex: Mutex = null
) -> Dictionary:

	var validation_error := _validate_input(
		board_snapshot,
		action_candidates
	)

	if not validation_error.is_empty():
		return {
			"success": false,
			"cancelled": false,
			"error": validation_error,
			"evaluations": []
		}

	var snapshot_pieces: Array = board_snapshot["pieces"]
	var evaluations: Array = []
	var best_risk_so_far := 7

	for action_index in range(action_candidates.size()):

		if _is_cancel_requested(cancel_holder, cancel_mutex):
			return {
				"success": false,
				"cancelled": true,
				"error": "Calculation cancelled.",
				"evaluations": []
			}

		var action: Dictionary = action_candidates[action_index]

		var evaluation := _evaluate_action(
			snapshot_pieces,
			action,
			best_risk_so_far,
			force_full_dice_evaluation,
			cancel_holder,
			cancel_mutex
		)

		if bool(evaluation.get("cancelled", false)):
			return {
				"success": false,
				"cancelled": true,
				"error": "Calculation cancelled.",
				"evaluations": []
			}

		evaluation["action_index"] = action_index
		evaluations.append(evaluation)

		best_risk_so_far = mini(
			best_risk_so_far,
			int(evaluation["risk_count"])
		)

	return {
		"success": true,
		"cancelled": false,
		"error": "",
		"evaluations": evaluations
	}


func calculate_actions_into(
	result_holder: Array,
	result_mutex: Mutex,
	board_snapshot: Dictionary,
	action_candidates: Array,
	force_full_dice_evaluation: bool = false,
	cancel_holder: Array = [],
	cancel_mutex: Mutex = null
) -> void:

	var calculation_result: Dictionary = calculate_actions(
		board_snapshot,
		action_candidates,
		force_full_dice_evaluation,
		cancel_holder,
		cancel_mutex
	)

	# Ghi ket qua vao vung du lieu dung chung.
	result_mutex.lock()
	result_holder[0] = calculation_result
	result_mutex.unlock()

func _validate_input(board_snapshot: Dictionary, action_candidates: Array) -> String:
	if not board_snapshot.has("pieces"):
		return "board_snapshot thieu truong pieces."

	if typeof(board_snapshot["pieces"]) != TYPE_ARRAY:
		return "board_snapshot.pieces phai la Array."

	var seen_ids: Dictionary = {}
	for piece_index in range(board_snapshot["pieces"].size()):
		var piece_data = board_snapshot["pieces"][piece_index]
		if typeof(piece_data) != TYPE_DICTIONARY:
			return "Piece tai vi tri %d khong phai Dictionary." % piece_index

		for required_key in [
			"id", "color", "type", "x", "y",
			"direction_x", "direction_y", "moved", "captured_this_turn"
		]:
			if not piece_data.has(required_key):
				return "Piece tai vi tri %d thieu truong %s." % [piece_index, required_key]

		var piece_id := int(piece_data["id"])
		if seen_ids.has(piece_id):
			return "Piece id bi trung: %d." % piece_id
		seen_ids[piece_id] = true

		if int(piece_data["color"]) not in [COLOR_BLACK, COLOR_WHITE]:
			return "Piece %d co color khong hop le." % piece_id
		if int(piece_data["type"]) not in [PIECE_ROOK, PIECE_BISHOP, PIECE_QUEEN, PIECE_KING, PIECE_PAWN]:
			return "Piece %d co type khong hop le." % piece_id
		if not _is_inside_board(Vector2i(int(piece_data["x"]), int(piece_data["y"]))):
			return "Piece %d nam ngoai ban co." % piece_id

	for action_index in range(action_candidates.size()):
		var action = action_candidates[action_index]
		if typeof(action) != TYPE_DICTIONARY:
			return "Action tai vi tri %d khong phai Dictionary." % action_index
		if not action.has("type") or not action.has("piece_id"):
			return "Action tai vi tri %d thieu type hoac piece_id." % action_index

		var action_type: String = str(action["type"])
		var piece_id := int(action["piece_id"])
		if not seen_ids.has(piece_id):
			return "Action tai vi tri %d tham chieu piece_id khong ton tai." % action_index

		if action_type == ACTION_MOVE:
			if not action.has("target_x") or not action.has("target_y"):
				return "Move action tai vi tri %d thieu target_x/target_y." % action_index
			var target := Vector2i(int(action["target_x"]), int(action["target_y"]))
			if not _is_inside_board(target):
				return "Move action tai vi tri %d co dich nam ngoai ban co." % action_index
		elif action_type == ACTION_SWAP:
			if not action.has("reserve_type"):
				return "Swap action tai vi tri %d thieu reserve_type." % action_index
			if int(action["reserve_type"]) not in [PIECE_ROOK, PIECE_BISHOP, PIECE_QUEEN, PIECE_KING, PIECE_PAWN]:
				return "Swap action tai vi tri %d co reserve_type khong hop le." % action_index
		else:
			return "Action tai vi tri %d co type khong ho tro: %s." % [action_index, action_type]

	return ""


func _evaluate_action(
	board_pieces: Array,
	action: Dictionary,
	current_best_risk: int,
	debug_full_check: bool = false,
	cancel_holder: Array = [],
	cancel_mutex: Mutex = null
) -> Dictionary:
	# Moi ung vien co mot ban sao rieng. Khong sua du lieu dau vao.
	var initial_pieces: Array = board_pieces.duplicate(true)
	var base_tactical_score: float = _base_tactical_score(initial_pieces, action)
	var tactical_score: float = base_tactical_score
	var exposure_adjustment: float = 0.0

	var simulated_pieces: Array = initial_pieces.duplicate(true)
	var simulated_grid: Dictionary = _build_grid(simulated_pieces)
	var acted_piece: Dictionary = _find_piece_by_id(simulated_pieces, int(action["piece_id"]))

	if action["type"] == ACTION_MOVE:
		_apply_simulated_move(simulated_pieces, simulated_grid, action)
	else:
		# Swap chi thay doi loai quan va trang thai cua quan duoc doi.
		acted_piece["type"] = int(action["reserve_type"])
		acted_piece["direction_x"] = 0
		acted_piece["direction_y"] = 0
		acted_piece["captured_this_turn"] = false
		acted_piece["moved"] = false

	var after_action_pieces: Array = simulated_pieces.duplicate(true)

	# Danh gia chien thuat phu tren trang thai dau luot cua ben Trang.
	var exposure_pieces: Array = after_action_pieces.duplicate(true)
	_reset_simulated_turn_states(exposure_pieces)
	var exposure_grid := _build_grid(exposure_pieces)
	var exposed_piece: Dictionary = _find_piece_by_id(exposure_pieces, int(action["piece_id"]))
	var exposed_position := Vector2i(int(exposed_piece["x"]), int(exposed_piece["y"]))

	if _is_piece_capturable_by_white(exposure_pieces, exposure_grid, exposed_position, 1):
		exposure_adjustment = -float(_piece_value(int(exposed_piece["type"])))
	else:
		exposure_adjustment = 50.0
	tactical_score += exposure_adjustment

	var risk_count := 0
	var unknown_count := 0
	var dice_results: Array = []
	var nodes_used := 0

	for dice_value in range(1, 7):
		if _is_cancel_requested(cancel_holder, cancel_mutex):
			return {"cancelled": true}
		# Moi ket qua xuc xac bat dau tu mot ban sao trang thai rieng.
		var dice_pieces: Array = after_action_pieces.duplicate(true)
		_reset_simulated_turn_states(dice_pieces)
		var dice_grid := _build_grid(dice_pieces)

		var visited: Dictionary = {}
		var budget: Array = [MAX_SEARCH_NODES_PER_DICE]
		var result: int = _search_white_king_capture(
			dice_pieces,
			dice_grid,
			dice_value,
			visited,
			budget,
			cancel_holder,
			cancel_mutex
		)
		if result == SEARCH_CANCELLED:
			return {"cancelled": true}
		var used_this_dice: int = MAX_SEARCH_NODES_PER_DICE - int(budget[0])
		nodes_used += used_this_dice
		dice_results.append({
			"dice": dice_value,
			"result": result,
			"nodes": used_this_dice
		})

		if result != SEARCH_SAFE:
			# UNKNOWN van duoc tinh la nguy co, giong thuat toan cu.
			risk_count += 1
		if result == SEARCH_UNKNOWN:
			unknown_count += 1

		if not debug_full_check and risk_count > current_best_risk:
			break

	return {
		"risk_count": risk_count,
		"unknown_count": unknown_count,
		"tactical_score": tactical_score,
		"base_tactical_score": base_tactical_score,
		"exposure_adjustment": exposure_adjustment,
		"dice_results": dice_results,
		"nodes_used": nodes_used
	}


func _base_tactical_score(pieces: Array, action: Dictionary) -> float:
	if action["type"] == ACTION_MOVE:
		var grid := _build_grid(pieces)
		var target := Vector2i(int(action["target_x"]), int(action["target_y"]))
		var target_piece = grid.get(target)
		if target_piece != null and int(target_piece["color"]) == COLOR_WHITE:
			if int(target_piece["type"]) == PIECE_KING:
				return 1000000000.0
			return float(_piece_value(int(target_piece["type"])))
		return 0.0

	var swap_piece: Dictionary = _find_piece_by_id(pieces, int(action["piece_id"]))
	var old_value := _piece_value(int(swap_piece["type"]))
	var new_value := _piece_value(int(action["reserve_type"]))
	return float(int((new_value - old_value) * 0.5))


func _generate_simulated_moves(
	pieces: Array,
	grid: Dictionary,
	color: int,
	points_left: int
) -> Array:
	var moves: Array = []
	if points_left <= 0:
		return moves

	for piece in pieces:
		if int(piece["color"]) != color:
			continue
		for target in _generate_simulated_piece_targets(piece, pieces, grid, points_left):
			moves.append({
				"piece_id": int(piece["id"]),
				"target_x": target.x,
				"target_y": target.y
			})
	return moves


func _generate_simulated_piece_targets(
	piece: Dictionary,
	pieces: Array,
	grid: Dictionary,
	points_left: int
) -> Array:
	var targets: Array = []
	if points_left <= 0:
		return targets

	var piece_type := int(piece["type"])
	var color := int(piece["color"])
	var position := Vector2i(int(piece["x"]), int(piece["y"]))
	var move_direction := Vector2i(int(piece["direction_x"]), int(piece["direction_y"]))

	# Vua chi duoc di khi du so quan cung mau da di chuyen.
	if piece_type == PIECE_KING and not _can_king_move_this_turn(piece, pieces):
		return targets

	# Tot chi di mot o, di thang neu trong va an cheo neu co dich.
	if piece_type == PIECE_PAWN:
		if bool(piece["moved"]):
			return targets

		var forward_y := -1 if color == COLOR_WHITE else 1
		var forward_position := position + Vector2i(0, forward_y)
		if _is_inside_board(forward_position) and not grid.has(forward_position):
			targets.append(forward_position)

		for dx in [-1, 1]:
			var capture_position := position + Vector2i(dx, forward_y)
			if not _is_inside_board(capture_position):
				continue
			var target_piece = grid.get(capture_position)
			if target_piece != null and int(target_piece["color"]) != color:
				targets.append(capture_position)
		return targets

	# Cac quan khac Vua khong duoc di tiep sau khi an quan trong cung luot.
	if piece_type != PIECE_KING and bool(piece["captured_this_turn"]):
		return targets

	var directions: Array = []
	if move_direction != Vector2i.ZERO:
		directions.append(move_direction)
	else:
		match piece_type:
			PIECE_ROOK:
				directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			PIECE_BISHOP:
				directions = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
			PIECE_QUEEN, PIECE_KING:
				directions = [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
			]
			_:
				return targets

	for direction in directions:
		for distance in range(1, points_left + 1):
			var target_position: Vector2i = position + direction * distance
			if not _is_inside_board(target_position):
				break

			var target_piece = grid.get(target_position)
			if target_piece == null:
				targets.append(target_position)
				continue
			if int(target_piece["color"]) != color:
				targets.append(target_position)
			break

	return targets


func _search_white_king_capture(
	pieces: Array,
	grid: Dictionary,
	points_left: int,
	visited: Dictionary,
	budget: Array,
	cancel_holder: Array = [],
	cancel_mutex: Mutex = null
) -> int:
	if points_left <= 0:
		return SEARCH_SAFE
	if _is_cancel_requested(cancel_holder, cancel_mutex):
		return SEARCH_CANCELLED
	var state_key := _make_search_state_key(pieces, points_left)
	if visited.has(state_key):
		return int(visited[state_key])
	if int(budget[0]) <= 0:
		visited[state_key] = SEARCH_UNKNOWN
		return SEARCH_UNKNOWN
	budget[0] = int(budget[0]) - 1

	var moves := _generate_simulated_moves(pieces, grid, COLOR_WHITE, points_left)

	# Kiem tra truoc cac nuoc bat Vua truc tiep.
	for move in moves:
		var target := Vector2i(int(move["target_x"]), int(move["target_y"]))
		var target_piece = grid.get(target)
		if target_piece != null \
		and int(target_piece["color"]) == COLOR_BLACK \
		and int(target_piece["type"]) == PIECE_KING:
			visited[state_key] = SEARCH_THREAT
			return SEARCH_THREAT

	var saw_unknown := false

	# Thu cac nuoc an quan truoc, sau do den cac nuoc di thuong.
	for capture_pass in range(2):
		for move in moves:
			var target := Vector2i(int(move["target_x"]), int(move["target_y"]))
			var target_piece = grid.get(target)
			var is_capture: bool = target_piece != null
			if capture_pass == 0 and not is_capture:
				continue
			if capture_pass == 1 and is_capture:
				continue

			var moving_piece: Dictionary = _find_piece_by_id(pieces, int(move["piece_id"]))
			var from_position := Vector2i(int(moving_piece["x"]), int(moving_piece["y"]))
			var move_cost := _move_cost(from_position, target)
			if move_cost >= points_left:
				continue

			var undo_state := _apply_simulated_move(pieces, grid, move)
			var result := _search_white_king_capture(
				pieces,
				grid,
				points_left - move_cost,
				visited,
				budget,
				cancel_holder,
				cancel_mutex
			)
			_undo_simulated_move(pieces, grid, undo_state)
			# Phai hoan tac nuoc di truoc khi dung tim kiem.
			if result == SEARCH_CANCELLED:
				return SEARCH_CANCELLED
			if result == SEARCH_THREAT:
				visited[state_key] = SEARCH_THREAT
				return SEARCH_THREAT
			if result == SEARCH_UNKNOWN:
				saw_unknown = true
			if int(budget[0]) <= 0:
				visited[state_key] = SEARCH_UNKNOWN
				return SEARCH_UNKNOWN

	var final_result := SEARCH_UNKNOWN if saw_unknown else SEARCH_SAFE
	visited[state_key] = final_result
	return final_result


func _make_search_state_key(pieces: Array, points_left: int) -> String:
	var pieces_key := str(points_left)
	for piece in pieces:
		pieces_key += ";" + str(piece["id"]) \
			+ "," + str(piece["type"]) \
			+ "," + str(piece["x"]) \
			+ "," + str(piece["y"]) \
			+ "," + str(piece["direction_x"]) \
			+ "," + str(piece["direction_y"]) \
			+ "," + str(int(bool(piece["moved"]))) \
			+ "," + str(int(bool(piece["captured_this_turn"])))
	return pieces_key


func _apply_simulated_move(pieces: Array, grid: Dictionary, move: Dictionary) -> Dictionary:
	var piece_id := int(move["piece_id"])
	var piece: Dictionary = _find_piece_by_id(pieces, piece_id)
	var target_position := Vector2i(int(move["target_x"]), int(move["target_y"]))
	var old_position := Vector2i(int(piece["x"]), int(piece["y"]))
	var old_direction := Vector2i(int(piece["direction_x"]), int(piece["direction_y"]))
	var old_captured: bool = bool(piece["captured_this_turn"])
	var old_moved: bool = bool(piece["moved"])
	var target_piece = grid.get(target_position)
	var captured_index := -1

	if target_piece != null:
		captured_index = _find_piece_index_by_id(pieces, int(target_piece["id"]))
		if captured_index >= 0:
			pieces.remove_at(captured_index)
		grid.erase(target_position)

	var next_direction := old_direction
	match int(piece["type"]):
		PIECE_ROOK:
			next_direction = _get_move_direction(old_position, target_position)
		PIECE_BISHOP:
			next_direction = _get_bishop_direction(old_position, target_position)
		PIECE_QUEEN:
			next_direction = _get_queen_direction(old_position, target_position)
		PIECE_KING:
			if target_piece != null:
				next_direction = Vector2i.ZERO
			else:
				next_direction = _get_queen_direction(old_position, target_position)

	grid.erase(old_position)
	piece["x"] = target_position.x
	piece["y"] = target_position.y
	piece["direction_x"] = next_direction.x
	piece["direction_y"] = next_direction.y
	piece["moved"] = true
	if target_piece != null:
		piece["captured_this_turn"] = true
	grid[target_position] = piece

	return {
		"piece_id": piece_id,
		"old_position": old_position,
		"old_direction": old_direction,
		"old_captured": old_captured,
		"old_moved": old_moved,
		"captured_piece": target_piece,
		"captured_index": captured_index,
		"target_position": target_position
	}


func _undo_simulated_move(pieces: Array, grid: Dictionary, undo_state: Dictionary) -> void:
	var piece: Dictionary = _find_piece_by_id(pieces, int(undo_state["piece_id"]))
	var target_position: Vector2i = undo_state["target_position"]
	var old_position: Vector2i = undo_state["old_position"]

	grid.erase(target_position)
	piece["x"] = old_position.x
	piece["y"] = old_position.y
	var old_direction: Vector2i = undo_state["old_direction"]
	piece["direction_x"] = old_direction.x
	piece["direction_y"] = old_direction.y
	piece["captured_this_turn"] = undo_state["old_captured"]
	piece["moved"] = undo_state["old_moved"]
	grid[old_position] = piece

	var captured_piece = undo_state["captured_piece"]
	if captured_piece != null:
		var insert_index := clampi(int(undo_state["captured_index"]), 0, pieces.size())
		pieces.insert(insert_index, captured_piece)
		var captured_position := Vector2i(int(captured_piece["x"]), int(captured_piece["y"]))
		grid[captured_position] = captured_piece


func _reset_simulated_turn_states(pieces: Array) -> void:
	for piece in pieces:
		piece["direction_x"] = 0
		piece["direction_y"] = 0
		piece["moved"] = false
		piece["captured_this_turn"] = false


func _build_grid(pieces: Array) -> Dictionary:
	var grid: Dictionary = {}
	for piece in pieces:
		var position := Vector2i(int(piece["x"]), int(piece["y"]))
		grid[position] = piece
	return grid


func _find_piece_by_id(pieces: Array, piece_id: int) -> Dictionary:
	for piece in pieces:
		if int(piece["id"]) == piece_id:
			return piece
	return {}


func _find_piece_index_by_id(pieces: Array, piece_id: int) -> int:
	for index in range(pieces.size()):
		if int(pieces[index]["id"]) == piece_id:
			return index
	return -1


func _can_king_move_this_turn(king_piece: Dictionary, pieces: Array) -> bool:
	if king_piece.is_empty():
		return false
	if int(king_piece["type"]) != PIECE_KING:
		return false

	var friendly_piece_count := 0
	var moved_friendly_piece_count := 0

	for piece in pieces:
		if int(piece["color"]) != int(king_piece["color"]):
			continue
		if int(piece["type"]) == PIECE_KING:
			continue

		friendly_piece_count += 1
		if bool(piece["moved"]):
			moved_friendly_piece_count += 1

	var required_moves := mini(2, friendly_piece_count)
	return moved_friendly_piece_count >= required_moves


func _is_piece_capturable_by_white(
	pieces: Array,
	grid: Dictionary,
	target_position: Vector2i,
	points: int
) -> bool:
	for move in _generate_simulated_moves(pieces, grid, COLOR_WHITE, points):
		var move_target := Vector2i(int(move["target_x"]), int(move["target_y"]))
		if move_target == target_position:
			return true
	return false


func _is_inside_board(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < BOARD_WIDTH \
		and position.y >= 0 and position.y < BOARD_HEIGHT


func _get_move_direction(from_position: Vector2i, to_position: Vector2i) -> Vector2i:
	var direction := to_position - from_position
	if direction.x > 0:
		return Vector2i(1, 0)
	if direction.x < 0:
		return Vector2i(-1, 0)
	if direction.y > 0:
		return Vector2i(0, 1)
	if direction.y < 0:
		return Vector2i(0, -1)
	return Vector2i.ZERO


func _get_bishop_direction(from_position: Vector2i, to_position: Vector2i) -> Vector2i:
	var direction := to_position - from_position
	if direction.x > 0 and direction.y > 0:
		return Vector2i(1, 1)
	if direction.x < 0 and direction.y > 0:
		return Vector2i(-1, 1)
	if direction.x > 0 and direction.y < 0:
		return Vector2i(1, -1)
	if direction.x < 0 and direction.y < 0:
		return Vector2i(-1, -1)
	return Vector2i.ZERO


func _get_queen_direction(from_position: Vector2i, to_position: Vector2i) -> Vector2i:
	var direction := to_position - from_position
	if direction.x == 0 or direction.y == 0:
		return _get_move_direction(from_position, to_position)
	if absi(direction.x) == absi(direction.y):
		return _get_bishop_direction(from_position, to_position)
	return Vector2i.ZERO

func _move_cost(from_position: Vector2i, to_position: Vector2i) -> int:
	return maxi(absi(to_position.x - from_position.x), absi(to_position.y - from_position.y))

# Kiem tra yeu cau dung tu Main Thread.
# Moi lan doc deu phai khoa Mutex.
func _is_cancel_requested(
	cancel_holder: Array,
	cancel_mutex: Mutex
) -> bool:

	if cancel_mutex == null or cancel_holder.is_empty():
		return false

	cancel_mutex.lock()
	var requested: bool = bool(cancel_holder[0])
	cancel_mutex.unlock()

	return requested

func _piece_value(piece_type: int) -> int:
	match piece_type:
		PIECE_KING:
			return 10000
		PIECE_QUEEN:
			return 900
		PIECE_ROOK:
			return 500
		PIECE_BISHOP:
			return 300
		PIECE_PAWN:
			return 100
	return 0
