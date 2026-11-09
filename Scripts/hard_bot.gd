extends Node

# Hard Bot - Giai doan 1
# Muc tieu: uu tien giam nguy co Vua Den bi bat trong luot tiep theo.
# Khong dung Minimax/Alpha-Beta. Khong thay doi luat trong board.gd/piece.gd.

# Bat log chi tiet de kiem tra cach bot danh gia tung ung vien.
# Tat thanh false sau khi tim duoc nguyen nhan neu log qua nhieu.
const DEBUG_ACTION_EVALUATION := false
const FORCE_FULL_DICE_EVALUATION := false
const HARD_BOT_CALCULATOR = preload("res://Scripts/hard_bot_calculator.gd")
var calculator: RefCounted = null

# =========================
# WORKER TASK MANAGEMENT
# =========================

# ID cua Worker Task hien tai.
var _worker_task_id: int = -1

# Trang thai Worker dang hoat dong.
var _worker_task_active: bool = false

# Du lieu dung chung de gui yeu cau huy.
var _worker_cancel_holder: Array = []
var _worker_cancel_mutex: Mutex

# Du lieu dung chung de nhan ket qua.
var _worker_result_holder: Array = []
var _worker_result_mutex: Mutex

const SEARCH_UNKNOWN := -1
const SEARCH_SAFE := 0
const SEARCH_THREAT := 1

var game_handle
var board_handle
var hard_turn_count: int = 0

func setup(game, board) -> void:
	game_handle = game
	board_handle = board
	hard_turn_count = 0
	calculator = HARD_BOT_CALCULATOR.new()
	print("[Hard] Calculator da khoi tao.")

# Tao ban sao trang thai ban co duoi dang du lieu thuần.
# Khong truyen tham chieu Node sang Calculator hoac Worker Thread.
func _build_board_snapshot() -> Dictionary:
	var snapshot_pieces: Array[Dictionary] = []

	for piece in board_handle.pieces:
		# Bo qua Node khong con hop le.
		if not is_instance_valid(piece):
			continue

		var piece_position: Vector2 = piece.board_position
		var piece_direction: Vector2 = piece.move_direction

		var piece_data: Dictionary = {
			"id": int(piece.get_instance_id()),
			"color": int(piece.color),
			"type": int(piece.piece_type),

			"x": int(piece_position.x),
			"y": int(piece_position.y),

			"direction_x": int(piece_direction.x),
			"direction_y": int(piece_direction.y),

			"moved": bool(piece.moved),
			"captured_this_turn": bool(piece.captured_this_turn)
		}

		snapshot_pieces.append(piece_data)

	return {
		"pieces": snapshot_pieces
	}

# Gui yeu cau tinh toan sang Worker Thread va quan ly vong doi task.
func _calculate_actions_on_worker(
	board_snapshot: Dictionary,
	action_candidates: Array,
	force_full_dice_evaluation: bool = false
) -> Dictionary:

	if calculator == null:
		return {
			"success": false,
			"cancelled": false,
			"error": "Calculator chua duoc khoi tao.",
			"evaluations": []
		}

	# Khong cho phep tao Worker Task moi khi task cu chua duoc thu hoi.
	if _worker_task_active or _worker_task_id != -1:
		return {
			"success": false,
			"cancelled": false,
			"error": "Worker Task truoc van dang hoat dong.",
			"evaluations": []
		}

	if not calculator.has_method("calculate_actions_into"):
		return {
			"success": false,
			"cancelled": false,
			"error": "Khong tim thay calculate_actions_into().",
			"evaluations": []
		}

	# Khoi tao cac vung du lieu dung chung.
	_worker_result_holder = [{}]
	_worker_result_mutex = Mutex.new()

	_worker_cancel_holder = [false]
	_worker_cancel_mutex = Mutex.new()

	# Tao Callable cho Worker Thread.
	var worker_callable := Callable(
		calculator,
        "calculate_actions_into"
	).bind(
		_worker_result_holder,
		_worker_result_mutex,
		board_snapshot,
		action_candidates,
		force_full_dice_evaluation,
		_worker_cancel_holder,
		_worker_cancel_mutex
	)

	if not worker_callable.is_valid():
		return {
			"success": false,
			"cancelled": false,
			"error": "Worker Callable khong hop le.",
			"evaluations": []
		}

	# Bat dau Worker Task.
	var start_usec := Time.get_ticks_usec()

	_worker_task_id = WorkerThreadPool.add_task(
		worker_callable,
		false,
        "Moriya Chess - Hard Bot Calculator"
	)

	if _worker_task_id < 0:
		_worker_task_id = -1
		return {
			"success": false,
			"cancelled": false,
			"error": "Khong the khoi tao Worker Task.",
			"evaluations": []
		}

	_worker_task_active = true

	print(
		"[Hard][Worker] Da gui tac vu. ID: ",
		_worker_task_id
	)

	# Cho Worker hoan thanh theo tung frame.
	# Main Thread van tiep tuc xu ly giao dien.
	while not WorkerThreadPool.is_task_completed(_worker_task_id):
		await get_tree().process_frame

	# Chi thu hoi task sau khi da hoan thanh.
	var completed_task_id: int = _worker_task_id

	var wait_error: Error = WorkerThreadPool.wait_for_task_completion(
		completed_task_id
	)

	# Danh dau task da duoc thu hoi.
	_worker_task_id = -1
	_worker_task_active = false
	if wait_error != OK:
		push_error(
			"[Hard][Worker] Khong the thu hoi task: "
			+ str(wait_error)
		)

		_worker_result_holder.clear()
		_worker_cancel_holder.clear()
		_worker_result_mutex = null
		_worker_cancel_mutex = null

		return {
			"success": false,
			"cancelled": false,
			"error": "Worker Task completion failed.",
			"evaluations": []
		}

	# Doc ket qua Calculator.
	_worker_result_mutex.lock()
	var raw_result: Variant = _worker_result_holder[0]
	var calculation_result: Dictionary = {}

	if typeof(raw_result) == TYPE_DICTIONARY:
		calculation_result = raw_result.duplicate(true)

	_worker_result_mutex.unlock()

	# Kiem tra co yeu cau huy hay khong.
	_worker_cancel_mutex.lock()
	var was_cancelled: bool = bool(_worker_cancel_holder[0])
	_worker_cancel_mutex.unlock()

	var elapsed_ms := float(
		Time.get_ticks_usec() - start_usec
	) / 1000.0

	print(
		"[Hard][Worker] Hoan thanh sau ",
		elapsed_ms,
        " ms."
	)

	# Neu da co yeu cau huy, khong su dung ket qua tinh toan.
	if was_cancelled:
		calculation_result = {
			"success": false,
			"cancelled": true,
			"error": "Calculation cancelled.",
			"evaluations": []
		}

	# Worker da hoan thanh va task da duoc thu hoi.
	# Bay gio co the giai phong cac tham chieu du lieu dung chung.
	_worker_result_holder.clear()
	_worker_cancel_holder.clear()

	_worker_result_mutex = null
	_worker_cancel_mutex = null

	if calculation_result.is_empty():
		return {
			"success": false,
			"cancelled": false,
			"error": "Calculator khong tra ve ket qua.",
			"evaluations": []
		}

	return calculation_result

# Ham duoc bot.gd goi khi den luot Hard.
func take_turn() -> void:
	hard_turn_count += 1

	print("\n[Hard][TurnCount] Luot bot: ", hard_turn_count)
	
	# Lap lai qua trinh danh gia cho den khi het diem di chuyen.
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
			# Neu co the bat Vua Trang ngay, thuc hien ngay.
			chosen_action = winning_action
			print("[Hard] Tim thay nuoc bat Vua Trang: ", _describe_action(winning_action))

		else:
			# Sap xep truoc khi tao danh sach ung vien.
			actions.sort_custom(Callable(self, "_compare_action_order"))

			# A. Tao ban sao ban co.
			var board_snapshot: Dictionary = _build_board_snapshot()

			# B. Tao danh sach hanh dong du lieu thuan.
			var action_candidates: Array = _build_action_candidates(actions)

			print("[Hard][Candidates] Actions: ", actions.size())
			print("[Hard][Candidates] Candidates: ", action_candidates.size())

			# Kiem tra du lieu dau vao.
			if action_candidates.size() != actions.size():
				push_error("[Hard] So luong actions va candidates khong khop!")

				game_handle.dice.remaining_points = 0
				game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
				return

			# Luu trang thai truoc khi gui Worker.
			var points_before_calculation: int = game_handle.dice.remaining_points

			# C. Gui yeu cau tinh toan sang Worker Thread.
			var worker_result: Dictionary = await _calculate_actions_on_worker(
				board_snapshot,
				action_candidates,
				FORCE_FULL_DICE_EVALUATION
			)

			# D. Kiem tra trang thai game sau khi Worker hoan thanh.
			if game_handle.game_ended:
				return

			if game_handle.current_player != Globals.COLORS.BLACK:
				return

			if game_handle.phase != Globals.PHASE.MOVEMENT:
				return

			# Neu so diem thay doi trong luc Worker dang tinh,
			# bo ket qua cu va tao lai yeu cau o vong while tiep theo.
			if game_handle.dice.remaining_points != points_before_calculation:
				continue

			# Neu ban co da thay doi, khong su dung ket qua cu.
			if _build_board_snapshot() != board_snapshot:
				continue

			# E. Xu ly truong hop Calculator duoc yeu cau dung.
			if bool(worker_result.get("cancelled", false)):
				print("[Hard] Calculator da huy tinh toan.")
				return

			# F. Kiem tra ket qua Calculator.
			if not bool(worker_result.get("success", false)):
				push_error(
					"[Hard][Worker] Calculator that bai: "
					+ str(worker_result.get("error", "Unknown error"))
				)

				game_handle.dice.remaining_points = 0
				game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
				return

			var evaluations: Array = worker_result.get("evaluations", [])

			# Dam bao Calculator tra ve du ket qua va dung thu tu.
			var evaluations_valid := evaluations.size() == actions.size()

			if evaluations_valid:
				for i in range(evaluations.size()):
					var evaluation_check: Variant = evaluations[i]

					if typeof(evaluation_check) != TYPE_DICTIONARY:
						evaluations_valid = false
						break

					var evaluation_dict: Dictionary = evaluation_check

					if int(evaluation_dict.get("action_index", -1)) != i:
						evaluations_valid = false
						break

			if not evaluations_valid:
				push_error("[Hard][Worker] Danh sach evaluations khong hop le!")

				game_handle.dice.remaining_points = 0
				game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
				return

			# G. Lua chon ung vien bang dung quy tac cu.
			var candidate_index := 0

			for evaluation_index in range(evaluations.size()):
				candidate_index += 1

				var evaluation: Dictionary = evaluations[evaluation_index]
				var action_index: int = int(evaluation["action_index"])

				# Lay lai action goc co chua Node that.
				var action: Dictionary = actions[action_index]

				var risk_count: int = int(evaluation["risk_count"])
				var tactical_score: float = float(evaluation["tactical_score"])
				var unknown_count: int = int(evaluation["unknown_count"])
				var decision_note := ""

				# 1. Uu tien it ket qua xuc xac nguy hiem hon.
				if chosen_action.is_empty() or risk_count < chosen_risk:
					chosen_action = action
					chosen_risk = risk_count
					chosen_tactical = tactical_score
					chosen_unknown = unknown_count
					decision_note = "CHON: nguy co thap hon / ung vien dau tien"

				# 2. Neu nguy co bang nhau, uu tien diem chien thuat cao.
				elif risk_count == chosen_risk and tactical_score > chosen_tactical:
					chosen_action = action
					chosen_tactical = tactical_score
					chosen_unknown = unknown_count
					decision_note = "CHON: nguy co ngang nhau, diem chien thuat cao hon"

				# 3. Neu tiep tuc bang diem, boc tham ngau nhien.
				elif risk_count == chosen_risk and is_equal_approx(tactical_score, chosen_tactical):
					if randi_range(0, 1) == 1:
						chosen_action = action
						chosen_tactical = tactical_score
						chosen_unknown = unknown_count
						decision_note = "CHON: ngang diem, boc tham ngau nhien"
					else:
						decision_note = "KHONG CHON: ngang diem, boc tham khong chon"

				else:
					if risk_count > chosen_risk:
						decision_note = "KHONG CHON: so ket qua nguy hiem cao hon"
					else:
						decision_note = "KHONG CHON: diem chien thuat thap hon"

				if DEBUG_ACTION_EVALUATION:
					print(
						"[Hard][Eval ", candidate_index, "/", actions.size(), "] ",
						_describe_action(action),
						" | Rui ro: ", risk_count, "/6",
						" | Chua ket luan: ", unknown_count,
						" | Diem chien thuat: ", tactical_score,
						" (goc=", evaluation["base_tactical_score"],
						", dieu chinh an toan=", evaluation["exposure_adjustment"], ")",
						" | Ket qua tung xuc xac: ",
						_format_dice_results(evaluation["dice_results"]),
						" | Nut tim kiem: ", evaluation["nodes_used"],
						" | ", decision_note
					)

			if chosen_action.is_empty():
				return

			if DEBUG_ACTION_EVALUATION:
				print(
					"[Hard][Chosen] ",
					_describe_action(chosen_action),
					" | Rui ro: ", chosen_risk, "/6",
					" | Chua ket luan: ", chosen_unknown,
					" | Diem chien thuat: ", chosen_tactical
				)

				print(
					"[Hard] Ket qua xuc xac can than trong: ",
					chosen_risk, "/6",
					" | Chua ket luan: ", chosen_unknown,
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

func _build_action_candidates(actions: Array) -> Array:
	var candidates: Array = []
	for action_index in range(actions.size()):
		var action: Dictionary = actions[action_index]
		var action_type: String = str(action["type"])
		var action_data: Dictionary = action["data"]

		var piece = action_data["piece"]

		# Kiem tra Node quan co con hop le hay khong.
		if not is_instance_valid(piece):
			push_error(
                "[Hard] Piece khong hop le tai action_index: "
				+ str(action_index)
			)
			return []

		var piece_id: int = int(piece.get_instance_id())

		match action_type:
			"move":
				var target: Vector2 = action_data["target"]

				candidates.append({
					"type": "move",
					"piece_id": piece_id,
					"target_x": int(target.x),
					"target_y": int(target.y)
				})

			"swap":
				candidates.append({
					"type": "swap",
					"piece_id": piece_id,
					"reserve_type": int(action_data["reserve_type"])
				})
			_:
				push_error(
                    "[Hard] Action khong duoc ho tro: "
					+ action_type
				)
				return []
	return candidates

# Gui yeu cau dung Calculator khi luot choi khong con hop le.
func request_calculation_cancel() -> void:

	if not _worker_task_active:
		return

	if _worker_task_id == -1:
		return

	if _worker_cancel_holder.is_empty():
		return

	if _worker_cancel_mutex == null:
		return

	# Bao ve du lieu dung chung.
	_worker_cancel_mutex.lock()
	_worker_cancel_holder[0] = true
	_worker_cancel_mutex.unlock()

	print("[Hard][Worker] Da gui yeu cau huy Calculator.")

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

# Ham tinh chi phi di chuyen, dung trong mo ta hanh dong.
func _move_cost(from_position: Vector2, to_position: Vector2) -> int:
	return int(max(abs(to_position.x - from_position.x), abs(to_position.y - from_position.y)))

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
