extends Node2D

@export var pieces = []
@export var movable_pieces = []
@export var highlight_timer: Timer
@export var piece_scene = preload("res://Scenes/Pieces.tscn")
@onready var highlight_cell = $HighlightCell
@export var white_king_pos: Vector2
@export var black_king_pos: Vector2
@onready var ui: Control = $"../UI"
@onready var notification_layer: Control = $"../UI/NotificationLayer"

const BOARD_WIDTH = 6   # số cột
const BOARD_HEIGHT = 8  # số hàng
const CELL_SIZE = 60

var selected_piece = null
var selecting_target = false
var target_position = Vector2.ZERO
var game_handle
var highlight_cells = []
var black_pawns_captured = 0
var white_pawns_captured = 0
var selected_swap_piece = null
var used_reserve_slots = []

func _ready():
	draw_board()
	init_pieces()

	highlight_timer = Timer.new()
	highlight_timer.wait_time = 2.0
	highlight_timer.one_shot = true
	add_child(highlight_timer)
	
	highlight_timer.timeout.connect(_on_highlight_timer_timeout)
	
	highlight_cell.visible = false

func draw_board():
	for x in range(Globals.BOARD_WIDTH):
		for y in range(Globals.BOARD_HEIGHT):
			draw_cell(x, y)

func draw_cell(x, y):
	var rect = ColorRect.new()
	rect.color = Color(0.8, 0.6, 0.4) if (x + y) % 2 == 0 else Color(0.4, 0.3, 0.2)
	rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	rect.position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE #ô bàn cờ chỉ hiển thị, đừng nhận chuột
	rect.z_index = -100
	add_child(rect)

func init_pieces():
	for piece_tuple in Globals.INITIAL_PIECE_SET_SINGLE:
		var piece_type = piece_tuple[0]

		# Quân đen
		var black_piece_pos = Vector2(
			piece_tuple[1],
			piece_tuple[2]
		)

		var black_piece = piece_scene.instantiate()
		add_child(black_piece)

		black_piece.init_piece(
			piece_type,
			Globals.COLORS.BLACK,
			black_piece_pos,
			self
		)

		pieces.append(black_piece)


		# Quân trắng
		var white_piece_pos = Vector2(
			Globals.BOARD_WIDTH - 1 - piece_tuple[1],
			Globals.BOARD_HEIGHT - 1 - piece_tuple[2]
		)

		var white_piece = piece_scene.instantiate()
		add_child(white_piece)

		white_piece.init_piece(
			piece_type,
			Globals.COLORS.WHITE,
			white_piece_pos,
			self
		)
		pieces.append(white_piece)

	# ===== DEBUG TEST =====

	var test_piece_1 = piece_scene.instantiate()
	add_child(test_piece_1)

	test_piece_1.init_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.BLACK,
		Vector2(4, 5),
		self
	)

	pieces.append(test_piece_1)
#
#
	#var test_piece_2 = piece_scene.instantiate()
	#add_child(test_piece_2)
#
	#test_piece_2.init_piece(
		#Globals.PIECE_TYPES.PAWN,
		#Globals.COLORS.BLACK,
		#Vector2(5, 5),
		#self
	#)
#
	#pieces.append(test_piece_2)
	#var test_rook = piece_scene.instantiate()
	#add_child(test_rook)
#
	#test_rook.init_piece(
		#Globals.PIECE_TYPES.KING,
		#Globals.COLORS.WHITE,
		#Vector2(3, 4),
		#self
	#)
#
	#pieces.append(test_rook)

func select_piece(piece):
	if selected_piece != null:
		selected_piece.set_selected(false)
		
	selected_piece = piece
	selected_piece.set_selected(true)
	
	for movable_piece in movable_pieces:
		if movable_piece != selected_piece:
			movable_piece.set_highlighted(false)
	
	clear_highlight_cells()
	
	var scan_result = selected_piece.scan_piece(
		game_handle.dice.remaining_points
	)
	
	for result in scan_result:
		highlight_cells_at(result["positions"])
	selecting_target = true

func deselect_piece():
	if selected_piece != null:
		selected_piece.set_selected(false)

	selected_piece = null
	selecting_target = false

func _unhandled_input(event):
	if game_handle.game_ended:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = get_local_mouse_position()
			if (
				mouse_position.x < 0
				or mouse_position.y < 0
				or mouse_position.x >= BOARD_WIDTH * CELL_SIZE
				or mouse_position.y >= BOARD_HEIGHT * CELL_SIZE
			):
				deselect_piece()
				ui.deselect_reserve()
				return
			var board_x = int(mouse_position.x / CELL_SIZE)
			var board_y = int(mouse_position.y / CELL_SIZE)

			var clicked_position = Vector2(board_x, board_y)
			if not is_valid_position(clicked_position):
				deselect_piece()
				clear_highlight_cells()
				ui.clear_reserve_highlights()
				ui.deselect_reserve()
				get_viewport().set_input_as_handled()
				return
				
			#print("Điểm còn lại: ", get_remaining_points())
			var piece_at_target = get_piece_at(clicked_position)

			if ui.selected_reserve_type != null:
				if game_handle.has_swapped_this_turn:
					var old_piece_sprite = ui.selected_reserve_slot.get_node("ReservePiece")
					old_piece_sprite.modulate = Color.WHITE

					ui.selected_reserve_slot = null
					ui.selected_reserve_type = null

					print("❌ Đã thay quân dự bị trong lượt này!")
					get_viewport().set_input_as_handled()
					return
				if piece_at_target == null:
					deselect_piece()
					ui.deselect_reserve()
					print("Ô trống")
				else:
					print("🔄 Đang chọn quân dự bị: ", ui.selected_reserve_type)
					print("Quân trên bàn được click: ", piece_at_target.piece_type)
					print("Màu quân: ", piece_at_target.color)
					if ui.selected_reserve_slot in used_reserve_slots:
						print("❌ Quân dự bị này đã được sử dụng!")

						var old_piece_sprite = ui.selected_reserve_slot.get_node("ReservePiece")
						old_piece_sprite.modulate = Color.WHITE

						ui.selected_reserve_slot = null
						ui.selected_reserve_type = null

						get_viewport().set_input_as_handled()
						return
					var can_swap = can_swap_piece(
						piece_at_target,
						ui.selected_reserve_type
					)
					print("Có thể thay quân? ", can_swap)
					if game_handle.dice.remaining_points <= 0:
						ui.deselect_reserve()
						deselect_piece()
						print("❌ Không còn điểm di chuyển, không thể thay quân dự bị!")
						get_viewport().set_input_as_handled()
						return
					if can_swap:
						if game_handle.has_swapped_this_turn:
							deselect_piece()
							print("❌ Đã thay quân dự bị trong lượt này!")
							return
						var swap_position = piece_at_target.board_position
						var swap_color = game_handle.current_player
						var swap_type = ui.selected_reserve_type
						
						game_handle.dice.remaining_points = 0
						game_handle.update_movement_points_ui(game_handle.current_player)
						
						print("✅ Có thể Swap!")
						print("Vị trí Swap: ", swap_position)
						
						movable_pieces.erase(piece_at_target)
						pieces.erase(piece_at_target)
						piece_at_target.queue_free()
						
						var new_piece = piece_scene.instantiate()
						add_child(new_piece)

						new_piece.init_piece(
							swap_type,
							swap_color,
							swap_position,
							self
						)
						pieces.append(new_piece)
						print("🆕 Đã tạo quân dự bị mới!")
						used_reserve_slots.append(ui.selected_reserve_slot)
						ui.selected_reserve_slot.get_node("ReservePiece").visible = false
						var piece_sprite = ui.selected_reserve_slot.get_node("ReservePiece")
						piece_sprite.modulate = Color.WHITE
						
						ui.selected_reserve_slot.get_node("LockOverlay").visible = true
						ui.selected_reserve_slot.get_node("LockSprite").visible = true
						
						ui.selected_reserve_slot = null
						ui.selected_reserve_type = null
						game_handle.has_swapped_this_turn = true
					else:
						var old_piece_sprite = ui.selected_reserve_slot.get_node("ReservePiece")
						old_piece_sprite.modulate = Color.WHITE
						ui.selected_reserve_slot = null
						ui.selected_reserve_type = null
						#ui.deselect_reserve()
						#deselect_piece()
						print("❌ Không thể thay quân dự bị!")
						
				get_viewport().set_input_as_handled()
				return
			if piece_at_target != null:
				if piece_at_target.color == game_handle.current_player:
					if piece_at_target == selected_piece: #xử lý select quân nếu như đã select rồi
						deselect_piece()
						clear_highlight_cells()
						ui.clear_reserve_highlights()
						get_viewport().set_input_as_handled()
						return
					select_piece(piece_at_target)
					
					ui.clear_reserve_highlights()
					
					var reserve_slots = ui.get_current_player_reserve_slots()
					if not game_handle.has_swapped_this_turn and ui.is_current_player_reserve_unlocked():
						for slot in reserve_slots:
							if slot in used_reserve_slots:
								continue
							var reserve_type = slot.get_meta("piece_type")
							if can_swap_piece(piece_at_target, reserve_type):
								ui.highlight_reserve_slot(slot)
						
					get_viewport().set_input_as_handled()
					return
			if piece_at_target != null:
				pass
				#print(
					#"Ô ",
					#clicked_position,
					#" có quân: ",
					#piece_at_target.piece_type,
					#" | Màu: ",
					#piece_at_target.color
				#)
			else:
				#print("Ô ", clicked_position, " đang trống")
				pass
			if selecting_target and selected_piece != null:
				target_position = clicked_position

				if piece_at_target != null:
					if piece_at_target.color == selected_piece.color:
						select_piece(piece_at_target)
						get_viewport().set_input_as_handled()
						return	
				
				print(
					"Quân đang chọn: ",
					selected_piece.board_position,
					" -> Ô đích: ",
					target_position
				)
				if selected_piece.is_valid_move(target_position):
					execute_move(selected_piece, target_position)
				get_viewport().set_input_as_handled()

func get_piece_at(position: Vector2):
	for piece in pieces:
		if piece.board_position == position:
			return piece

	return null

func remove_piece(piece):
	if piece.piece_type == Globals.PIECE_TYPES.KING:
		var winner = Globals.COLORS.WHITE if piece.color == Globals.COLORS.BLACK else Globals.COLORS.BLACK
		pieces.erase(piece)
		piece.queue_free()
		game_handle.game_over(winner)
		print("👑 KING ", piece.color, " BỊ ĂN!")
		print("🏆 Người thắng: ", winner)
		return
	if piece.piece_type == Globals.PIECE_TYPES.PAWN:
		if piece.color == Globals.COLORS.BLACK:
			black_pawns_captured += 1
			print("Pawn Đen bị ăn: ", black_pawns_captured)
			if black_pawns_captured == 2:
				ui.unlock_black_reserve()
		else:
			white_pawns_captured += 1
			print("Pawn Trắng bị ăn: ", white_pawns_captured)
			if white_pawns_captured == 2:
				ui.unlock_white_reserve()

	pieces.erase(piece)
	piece.queue_free()

func is_valid_position(position: Vector2) -> bool:
	if position.x >= 0 and position.x < Globals.BOARD_WIDTH:
		if position.y >= 0 and position.y < Globals.BOARD_HEIGHT:
			return true

	return false

func get_remaining_points() -> int:
	return game_handle.dice.remaining_points

func reset_piece_directions():
	for piece in pieces:
		piece.move_direction = Vector2.ZERO
		piece.moved = false
		piece.captured_this_turn = false

func scan_board():
	if game_handle.game_ended:
		return
	clear_highlight_cells()
	
	for piece in movable_pieces:
		piece.set_highlighted(false)
	movable_pieces.clear()

	for piece in pieces:
		if piece.color != game_handle.current_player:
			continue

		var scan_result = piece.scan_piece(
			game_handle.dice.remaining_points
		)
		
		for result in scan_result:
			highlight_cells_at(result["positions"])
		if not scan_result.is_empty():
			movable_pieces.append(piece)
	
	if not game_handle.has_moved_this_turn:
		for piece in movable_pieces:
			piece.set_highlighted(true)

	highlight_timer.start()

func _on_highlight_timer_timeout():
	
	for piece in movable_pieces:
		#print(
			#"Quân: ", piece.piece_type,
			#" | selected = ", piece.selected,
			#" | highlighted = ", piece.highlighted
		#)
		piece.set_highlighted(false)
		
	fade_out_highlight_cells()
	
func can_select_piece(piece):
	return piece in movable_pieces

func highlight_cells_at(positions):
	for board_position in positions:
		#print("🟨 TẠO HIGHLIGHT: ", board_position)
		
		var cell = highlight_cell.duplicate()
		
		add_child(cell)
		
		cell.position = Vector2(
			board_position.x * 60,
			board_position.y * 60
		)
		
		cell.visible = true
		
		cell.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(cell, "modulate:a", 1.0, 0.3)
		
		highlight_cells.append(cell)

func highlight_bot_move(piece, target_position):
	var piece_highlight = highlight_cell.duplicate()
	add_child(piece_highlight)

	piece_highlight.position = Vector2(
		piece.board_position.x * 60,
		piece.board_position.y * 60
	)

	piece_highlight.visible = true
	piece_highlight.modulate = Color(1, 0.2, 0.2, 0.0)

	var tween1 = create_tween()
	tween1.tween_property(
		piece_highlight,
		"modulate:a",
		1.0,
		0.2
	)

	highlight_cells.append(piece_highlight)

	var target_highlight = highlight_cell.duplicate()
	add_child(target_highlight)

	target_highlight.position = Vector2(
		target_position.x * 60,
		target_position.y * 60
	)

	target_highlight.visible = true
	target_highlight.modulate.a = 0.0

	var tween2 = create_tween()
	tween2.tween_property(
		target_highlight,
		"modulate:a",
		1.0,
		0.2
	)

	highlight_cells.append(target_highlight)

func highlight_bot_swap(piece, reserve_slot):
	var piece_highlight = highlight_cell.duplicate()
	add_child(piece_highlight)

	piece_highlight.position = Vector2(
		piece.board_position.x * 60,
		piece.board_position.y * 60
	)

	piece_highlight.visible = true
	piece_highlight.modulate = Color(1, 0.2, 0.2, 0.0)

	var tween = create_tween()
	tween.tween_property(
		piece_highlight,
		"modulate:a",
		1.0,
		0.2
	)

	highlight_cells.append(piece_highlight)

	ui.highlight_bot_reserve_slot(reserve_slot)

func clear_highlight_cells():
	for cell in highlight_cells:
		cell.queue_free()

	highlight_cells.clear()

func fade_out_highlight_cells():
	for cell in highlight_cells:
		var tween = create_tween()
		tween.tween_property(cell, "modulate:a", 0.0, 0.5)
		tween.tween_callback(cell.queue_free)

	highlight_cells.clear()

func can_swap_piece(piece, reserve_type):
	if piece.color != game_handle.current_player:
		return false
	if piece.piece_type == Globals.PIECE_TYPES.KING:
		return false
	if piece.piece_type == reserve_type:
		return false
	return true

func get_swappable_pieces(reserve_type):
	var swappable_pieces = []

	for piece in pieces:
		if can_swap_piece(piece, reserve_type):
			swappable_pieces.append(piece)

	return swappable_pieces

func swap_with_reserve(piece, reserve_type, reserve_slot):
	if game_handle.phase != Globals.PHASE.MOVEMENT:
		deselect_piece()
		print("❌ Chỉ được thay quân trong phase di chuyển!")
		return
		
	if game_handle.has_swapped_this_turn:
		deselect_piece()
		print("❌ Đã thay quân dự bị trong lượt này!")
		return
		
	if reserve_slot in used_reserve_slots:
		print("❌ Quân dự bị này đã được sử dụng!")
		return

	if not can_swap_piece(piece, reserve_type):
		
		print("❌ Không thể thay quân này!")
		return
	if game_handle.dice.remaining_points == 0 and can_swap_piece(piece, reserve_type):
		notification_layer.show_notification("không thể thay dự bị zx")
		deselect_piece()
		return false

	print("🔄 Đang Swap!")
	print("Quân trên bàn: ", piece.piece_type)
	print("Quân dự bị: ", reserve_type)

	var swap_position = piece.board_position
	var swap_color = game_handle.current_player

	# Xóa quân cũ
	movable_pieces.erase(piece)
	pieces.erase(piece)
	piece.queue_free()

	# Tạo quân dự bị mới
	var new_piece = piece_scene.instantiate()
	add_child(new_piece)

	new_piece.init_piece(
		reserve_type,
		swap_color,
		swap_position,
		self
	)

	pieces.append(new_piece)

	# Đánh dấu quân dự bị đã dùng
	used_reserve_slots.append(reserve_slot)

	# Ẩn quân dự bị
	var reserve_piece_sprite = reserve_slot.get_node("ReservePiece")
	reserve_piece_sprite.visible = false
	reserve_piece_sprite.modulate = Color.WHITE
	
	ui.clear_reserve_highlights() #tắt highlight sau khi thay dự bị xong
	ui.deselect_reserve()
	game_handle.update_time_status()
	# Khóa lại ô dự bị
	reserve_slot.get_node("LockOverlay").visible = true
	reserve_slot.get_node("LockSprite").visible = true

	# Swap dùng toàn bộ điểm còn lại
	game_handle.dice.remaining_points = 0
	game_handle.update_movement_points_ui(game_handle.current_player)
	game_handle.has_swapped_this_turn = true
	print("✅ Swap thành công!")

func execute_move(piece, target_position):
	if piece.is_valid_move(target_position):
		var move_distance = max(
			abs(target_position.x - piece.board_position.x),
			abs(target_position.y - piece.board_position.y)
		)

		var target_piece = get_piece_at(target_position)
		var captured = false

		if target_piece != null:
			if target_piece.color != piece.color:
				remove_piece(target_piece)
				piece.captured_this_turn = true
				captured = true

		if piece.piece_type == Globals.PIECE_TYPES.BISHOP:
			piece.move_direction = piece.get_bishop_direction(target_position)

		if piece.piece_type == Globals.PIECE_TYPES.QUEEN:
			piece.move_direction = piece.get_queen_direction(target_position)

		if piece.piece_type == Globals.PIECE_TYPES.KING:
			if not captured:
				piece.move_direction = piece.get_queen_direction(target_position)
			else:
				piece.move_direction = Vector2.ZERO

		piece.move_to(target_position)
		piece.moved = true
		game_handle.has_moved_this_turn = true

		game_handle.dice.remaining_points -= move_distance
		game_handle.update_movement_points_ui(game_handle.current_player)

		scan_board()

		print("Còn lại ", game_handle.dice.remaining_points, " điểm.")

		deselect_piece()

		return true

	else:
		print("❌ Nước đi không hợp lệ!")
		deselect_piece()
		clear_highlight_cells()
		return false
