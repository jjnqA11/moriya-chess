extends Node2D


signal piece_clicked(piece)
signal cell_clicked(board_position)
@onready var highlight_cell = $HighlightCell

const CELL_SIZE = 60
var piece_scene = preload("res://Scenes/Pieces.tscn")
var pieces = []

var tutorial_highlights = []
var tutorial_highlight_positions = []

var initial_piece_positions = {}
var tutorial_points = 6

var tutorial_move_tween: Tween = null
var tutorial_input_locked = false

func _ready():
	draw_board()
	init_tutorial_pieces()
	for piece in pieces:
		piece.hide()

func _input(event):
	if tutorial_input_locked:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			var mouse_position = get_global_mouse_position()
			var local_position = to_local(mouse_position)

			var board_position = Vector2(
				floor(local_position.x / CELL_SIZE),
				floor(local_position.y / CELL_SIZE)
			)

			# Kiểm tra có quân nào ở ô vừa click không
			for piece in pieces:
				if piece.visible and piece.board_position == board_position:
					print(
						"🖱️ Click quân: type = ",
						piece.piece_type,
						" | color = ",
						piece.color,
						" | position = ",
						piece.board_position
					)

					piece_clicked.emit(piece)
					return

			# Nếu không click quân thì kiểm tra ô highlight
			if board_position in tutorial_highlight_positions:
				print("🟨 Click ô highlight: ", board_position)
				cell_clicked.emit(board_position)

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
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 0
	add_child(rect)

func create_tutorial_piece(piece_type, color, position):
	var piece = piece_scene.instantiate()
	add_child(piece)

	piece.init_piece(
		piece_type,
		color,
		position,
		self,
		false
	)
	piece.set_highlighted(true)
	
	piece.set_process_input(false)
	piece.set_process_unhandled_input(false)

	var area = piece.get_node("Area2D")
	area.input_pickable = false
	
	initial_piece_positions[piece] = position
	pieces.append(piece)

func can_king_move_this_turn(king_piece) -> bool:
	if king_piece == null:
		return false

	if not is_instance_valid(king_piece):
		return false

	if king_piece.piece_type != Globals.PIECE_TYPES.KING:
		return false

	var friendly_piece_count := 0
	var moved_friendly_piece_count := 0

	for piece in pieces:
		# Bo qua node da bi huy hoac quan dang an.
		if not is_instance_valid(piece) or not piece.visible:
			continue

		# Chi dem quan cung phe voi Vua dang kiem tra.
		if piece.color != king_piece.color:
			continue

		# Khong tinh chinh quan Vua.
		if piece.piece_type == Globals.PIECE_TYPES.KING:
			continue

		friendly_piece_count += 1

		if piece.moved:
			moved_friendly_piece_count += 1

	# Con tu 2 quan dong minh: can 2 quan khac nhau da di chuyen.
	# Con 1 quan dong minh: chi can quan do da di chuyen.
	# Chi con Vua: khong can quan nao di chuyen truoc.
	var required_moves := mini(2, friendly_piece_count)

	return moved_friendly_piece_count >= required_moves

func init_tutorial_pieces():
	# ===== PHE TRẮNG =====

	create_tutorial_piece(
		Globals.PIECE_TYPES.ROOK,
		Globals.COLORS.WHITE,
		Vector2(1, 6)
	)

	create_tutorial_piece(
		Globals.PIECE_TYPES.BISHOP,
		Globals.COLORS.WHITE,
		Vector2(2, 6)
	)

	create_tutorial_piece(
		Globals.PIECE_TYPES.QUEEN,
		Globals.COLORS.WHITE,
		Vector2(3, 6)
	)

	create_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.WHITE,
		Vector2(4, 6)
	)

	create_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.WHITE,
		Vector2(3, 5)
	)

	# ===== PHE ĐEN =====

	create_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.BLACK,
		Vector2(4, 1)
	)

	create_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK,
		Vector2(3, 2)
	)

func highlight_tutorial_cell(board_position, clickable = true):
	var cell = highlight_cell.duplicate()
	add_child(cell)

	cell.position = Vector2(
		board_position.x * CELL_SIZE,
		board_position.y * CELL_SIZE
	)

	cell.visible = true

	tutorial_highlights.append(cell)

	if clickable:
		tutorial_highlight_positions.append(board_position)

func highlight_tutorial_piece(piece_type, color):
	clear_tutorial_highlights()

	for piece in pieces:
		if piece.piece_type == piece_type and piece.color == color:
			highlight_tutorial_cell(piece.board_position)
			break

func highlight_king_target_pawn():
	var pawn = get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK
	)

	if pawn != null:
		clear_tutorial_highlights()
		highlight_tutorial_cell(pawn.board_position, false)

func highlight_king_capture_target():
	clear_tutorial_highlights()

	var pawn = get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK
	)

	if pawn != null:
		highlight_tutorial_cell(pawn.board_position, false)

func clear_tutorial_highlights():
	for cell in tutorial_highlights:
		cell.queue_free()

	tutorial_highlights.clear()
	tutorial_highlight_positions.clear()


func move_tutorial_piece(piece, target_position):
	if piece == null or not is_instance_valid(piece):
		return

	clear_tutorial_highlights()
	tutorial_input_locked = true

	if tutorial_move_tween != null and tutorial_move_tween.is_valid():
		tutorial_move_tween.kill()

	# Xac dinh huong tu vi tri cu truoc khi cap nhat toa do.
	var next_direction: Vector2 = piece.move_direction

	match piece.piece_type:
		Globals.PIECE_TYPES.ROOK:
			next_direction = piece.get_move_direction(target_position)

		Globals.PIECE_TYPES.BISHOP:
			next_direction = piece.get_bishop_direction(target_position)

		Globals.PIECE_TYPES.QUEEN, Globals.PIECE_TYPES.KING:
			next_direction = piece.get_queen_direction(target_position)

	# Cap nhat trang thai logic cua quan.
	piece.board_position = target_position
	piece.moved = true

	# Tinh huong di chuyen cho cac quan co khoa huong.
	if piece.piece_type != Globals.PIECE_TYPES.PAWN:
		piece.move_direction = next_direction

	var target_pixel_position = Vector2(
		target_position.x * CELL_SIZE + CELL_SIZE / 2,
		target_position.y * CELL_SIZE + CELL_SIZE / 2
	)

	tutorial_move_tween = create_tween()
	tutorial_move_tween.tween_property(
		piece,
		"position",
		target_pixel_position,
		0.3
	)

	await tutorial_move_tween.finished

	tutorial_move_tween = null
	tutorial_input_locked = false

func get_piece_at(board_position):
	for piece in pieces:
		if piece.visible and piece.board_position == board_position:
			return piece

	return null

func show_rook_tutorial_moves(piece):
	clear_tutorial_highlights()

	var pos = piece.board_position

	# Sang trái
	for x in range(int(pos.x) - 1, -1, -1):
		if not add_rook_move_cell(piece, Vector2(x, pos.y)):
			break

	# Sang phải
	for x in range(int(pos.x) + 1, Globals.BOARD_WIDTH):
		if not add_rook_move_cell(piece, Vector2(x, pos.y)):
			break

	# Lên
	for y in range(int(pos.y) - 1, -1, -1):
		if not add_rook_move_cell(piece, Vector2(pos.x, y)):
			break

	# Xuống
	for y in range(int(pos.y) + 1, Globals.BOARD_HEIGHT):
		if not add_rook_move_cell(piece, Vector2(pos.x, y)):
			break

func add_rook_move_cell(piece, board_position):
	var blocking_piece = get_piece_at(board_position)

	# Ô trống → có thể đi tiếp
	if blocking_piece == null:
		highlight_tutorial_cell(board_position)
		return true

	# Quân đồng minh → bị chặn, không được đi vào
	if blocking_piece.color == piece.color:
		return false

	# Quân địch → có thể đi vào để bắt, nhưng dừng tại đây
	highlight_tutorial_cell(board_position)
	return false

func show_bishop_tutorial_moves(piece):
	clear_tutorial_highlights()

	var pos = piece.board_position

	# ↖
	for i in range(1, 10):
		var board_position = pos + Vector2(-i, -i)

		if not add_bishop_move_cell(piece, board_position):
			break

	# ↗
	for i in range(1, 10):
		var board_position = pos + Vector2(i, -i)

		if not add_bishop_move_cell(piece, board_position):
			break

	# ↙
	for i in range(1, 10):
		var board_position = pos + Vector2(-i, i)

		if not add_bishop_move_cell(piece, board_position):
			break

	# ↘
	for i in range(1, 10):
		var board_position = pos + Vector2(i, i)

		if not add_bishop_move_cell(piece, board_position):
			break

func add_bishop_move_cell(piece, board_position):
	# Ra ngoài bàn
	if board_position.x < 0 \
	or board_position.x >= Globals.BOARD_WIDTH \
	or board_position.y < 0 \
	or board_position.y >= Globals.BOARD_HEIGHT:
		return false

	var blocking_piece = get_piece_at(board_position)

	# Ô trống
	if blocking_piece == null:
		highlight_tutorial_cell(board_position)
		return true

	# Quân đồng minh chặn đường
	if blocking_piece.color == piece.color:
		return false

	# Quân địch có thể bị bắt, nhưng không đi xuyên qua
	highlight_tutorial_cell(board_position)
	return false

func show_queen_tutorial_moves(piece):
	clear_tutorial_highlights()

	var pos = piece.board_position

	# Ngang
	for x in range(int(pos.x) - 1, -1, -1):
		if not add_queen_move_cell(piece, Vector2(x, pos.y)):
			break

	for x in range(int(pos.x) + 1, Globals.BOARD_WIDTH):
		if not add_queen_move_cell(piece, Vector2(x, pos.y)):
			break

	# Dọc
	for y in range(int(pos.y) - 1, -1, -1):
		if not add_queen_move_cell(piece, Vector2(pos.x, y)):
			break

	for y in range(int(pos.y) + 1, Globals.BOARD_HEIGHT):
		if not add_queen_move_cell(piece, Vector2(pos.x, y)):
			break

	# Chéo
	for i in range(1, 10):
		if not add_queen_move_cell(piece, pos + Vector2(-i, -i)):
			break

	for i in range(1, 10):
		if not add_queen_move_cell(piece, pos + Vector2(i, -i)):
			break

	for i in range(1, 10):
		if not add_queen_move_cell(piece, pos + Vector2(-i, i)):
			break

	for i in range(1, 10):
		if not add_queen_move_cell(piece, pos + Vector2(i, i)):
			break
			
func add_queen_move_cell(piece, board_position):
	if board_position.x < 0 \
	or board_position.x >= Globals.BOARD_WIDTH \
	or board_position.y < 0 \
	or board_position.y >= Globals.BOARD_HEIGHT:
		return false

	var blocking_piece = get_piece_at(board_position)

	if blocking_piece == null:
		highlight_tutorial_cell(board_position)
		return true

	if blocking_piece.color == piece.color:
		return false

	highlight_tutorial_cell(board_position)
	return false

func show_tutorial_piece_moves(
	piece,
	max_points: int = -1,
	include_captures: bool = true
) -> void:
	clear_tutorial_highlights()

	if piece == null or not is_instance_valid(piece):
		return

	if not piece.visible:
		return

	var points_to_use: int = tutorial_points

	if max_points >= 0:
		points_to_use = max_points

	if points_to_use <= 0:
		return

	# Su dung luat quet nuoc di that tu piece.gd.
	var scan_results = piece.scan_piece(points_to_use)

	for result in scan_results:
		for target_position in result["positions"]:
			var target_piece = get_piece_at(target_position)

			# Khong hien thi o da co quan dong minh.
			if target_piece != null:
				if target_piece.color == piece.color:
					continue

				# Cho phep an quan chi khi buoc tutorial yeu cau.
				if not include_captures:
					continue

			highlight_tutorial_cell(target_position)

func show_king_tutorial_moves(piece):
	show_tutorial_piece_moves(
		piece,
		tutorial_points,
		false
	)
	clear_tutorial_highlights()

	var scan_results = piece.scan_king(tutorial_points)

	for result in scan_results:
		for board_position in result["positions"]:
			highlight_tutorial_cell(board_position)


func setup_king_capture_scenario():
	clear_tutorial_highlights()
	tutorial_points = 6

	var white_king = get_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.WHITE
	)
	var white_rook = get_tutorial_piece(
		Globals.PIECE_TYPES.ROOK,
		Globals.COLORS.WHITE
	)
	var white_bishop = get_tutorial_piece(
		Globals.PIECE_TYPES.BISHOP,
		Globals.COLORS.WHITE
	)
	var black_pawn = get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK
	)
	var black_king = get_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.BLACK
	)

	if white_king == null or white_rook == null \
	or white_bishop == null or black_pawn == null \
	or black_king == null:
		print("Tutorial: Khong du quan de tao tinh huong Vua bat Tot.")
		return

	# Dat lai trang thai cua cac quan trong tinh huong rieng.
	for piece in pieces:
		if not is_instance_valid(piece):
			continue

		piece.moved = false
		piece.captured_this_turn = false
		piece.move_direction = Vector2.ZERO
		piece.set_selected(false)
		piece.show()

	# Bo tri lai de khong co hai quan chong len nhau.
	set_tutorial_piece_position(white_rook, Vector2(0, 6))
	set_tutorial_piece_position(white_king, Vector2(1, 6))
	set_tutorial_piece_position(white_bishop, Vector2(2, 6))
	set_tutorial_piece_position(black_pawn, Vector2(2, 5))
	set_tutorial_piece_position(black_king, Vector2(4, 1))

	# Tinh huong nay mo phong viec hai quan dong minh da di chuyen truoc.
	white_rook.moved = true
	white_bishop.moved = true

	white_king.move_direction = Vector2.ZERO
	white_king.captured_this_turn = false


func setup_pawn_capture_scenario():
	clear_tutorial_highlights()

	var white_pawn = get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.WHITE
	)

	var black_pawn = get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK
	)

	if white_pawn == null or black_pawn == null:
		return

	set_tutorial_piece_position(
		white_pawn,
		Vector2(3, 5)
	)

	set_tutorial_piece_position(
		black_pawn,
		Vector2(4, 4)
	)

	white_pawn.moved = false

func get_tutorial_piece(piece_type, color):
	for piece in pieces:
		if piece.piece_type == piece_type and piece.color == color:
			return piece
	return null

func get_tutorial_pieces(piece_type, color):
	var result = []

	for piece in pieces:
		if piece.piece_type == piece_type and piece.color == color:
			result.append(piece)

	return result

func set_tutorial_piece_position(piece, board_position):
	piece.board_position = board_position

	piece.position = Vector2(
		board_position.x * CELL_SIZE + CELL_SIZE / 2,
		board_position.y * CELL_SIZE + CELL_SIZE / 2
	)

	piece.show()

func capture_tutorial_piece(piece, target_position):
	clear_tutorial_highlights()

	var target_piece = get_piece_at(target_position)

	if target_piece != null:
		target_piece.hide()

	piece.board_position = target_position

	var target_pixel_position = Vector2(
		target_position.x * CELL_SIZE + CELL_SIZE / 2,
		target_position.y * CELL_SIZE + CELL_SIZE / 2
	)

	var tween = create_tween()

	tween.tween_property(
		piece,
		"position",
		target_pixel_position,
		0.3
	)

func show_king_new_direction():
	clear_tutorial_highlights()

	var white_king = get_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.WHITE
	)

	white_king.move_direction = Vector2.ZERO

	var scan_results = white_king.scan_king(tutorial_points)

	for result in scan_results:
		for board_position in result["positions"]:
			highlight_tutorial_cell(board_position)

func show_pawn_tutorial_moves(piece):
	clear_tutorial_highlights()

	var scan_results = piece.scan_pawn(6)

	for result in scan_results:
		for board_position in result["positions"]:
			highlight_tutorial_cell(board_position)

func simulate_two_pawn_losses():
	var white_pawns = get_tutorial_pieces(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.WHITE
	)

	if white_pawns.size() < 2:
		print("❌ Không đủ 2 Tốt trắng để mô phỏng mất quân.")
		return

	white_pawns[0].hide()
	white_pawns[1].hide()

func reset_tutorial_board():
	#dừng tween đang chạy
	if tutorial_move_tween != null and tutorial_move_tween.is_valid():
		tutorial_move_tween.kill()
		
	tutorial_move_tween = null
	tutorial_input_locked = false
	
	clear_tutorial_highlights()

	for piece in pieces:
		var original_position = initial_piece_positions[piece]

		set_tutorial_piece_position(
			piece,
			original_position
		)

		piece.show()
		piece.set_selected(false)

		piece.moved = false
		piece.move_direction = Vector2.ZERO
	tutorial_points = 6

func swap_tutorial_piece(piece, reserve_type):
	var swap_position = piece.board_position
	var swap_color = piece.color

	# Lưu vị trí ban đầu của quân cũ
	var original_position = initial_piece_positions[piece]

	# Xóa quân cũ
	pieces.erase(piece)
	initial_piece_positions.erase(piece)
	piece.queue_free()

	# Tạo quân mới giống cách Board.gd đang làm
	var new_piece = piece_scene.instantiate()
	add_child(new_piece)

	new_piece.init_piece(
		reserve_type,
		swap_color,
		swap_position,
		self
	)

	# Tutorial không cho Piece tự xử lý input
	new_piece.set_process_input(false)
	new_piece.set_process_unhandled_input(false)

	var area = new_piece.get_node("Area2D")
	area.input_pickable = false

	new_piece.set_selected(false)

	pieces.append(new_piece)

	# Giữ vị trí gốc để sau này reset tutorial
	initial_piece_positions[new_piece] = original_position

	return new_piece
