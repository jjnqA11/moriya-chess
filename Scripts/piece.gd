extends Node2D

@onready var sprite = $Sprite2D
@onready var area = $Area2D

const SPRITE_SIZE = 34
const CELL_SIZE = 60

@export var piece_type: Globals.PIECE_TYPES
@export var color: Globals.COLORS
@export var board_position: Vector2
@export var captured_this_turn: bool

var board_handle
var game_handle

@export var moved: bool

var selected: bool = false
var highlighted: bool = false
var move_direction = Vector2.ZERO

func _ready():
	area.input_event.connect(_on_area_input_event)

func _on_area_input_event(
	_viewport,
	event,
	_shape_idx
):
	if game_handle.game_ended:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if color != game_handle.current_player:
				print("Chưa tới lượt quân này!")
				return
				
			if not board_handle.can_select_piece(self):
				print("Quân này hiện không có nước đi hợp lệ!")
				return
			set_highlighted(false)
			board_handle.select_piece(self)
			
			var scan_result = scan_piece(game_handle.dice.remaining_points)
			print("SCAN RESULT: ", scan_result)
			
			get_viewport().set_input_as_handled()

func init_piece(
	type: Globals.PIECE_TYPES,
	col: Globals.COLORS,
	board_pos: Vector2,
	board
):
	piece_type = type
	color = col
	board_position = board_pos
	board_handle = board
	game_handle = board.get_parent()
	moved = false
	captured_this_turn = false
	
	update_sprite()

	position = Vector2(
		board_position.x * CELL_SIZE + CELL_SIZE / 2,
		board_position.y * CELL_SIZE + CELL_SIZE / 2
	)


func update_sprite():
	if sprite:
		var region_pos = Globals.SPRITE_MAPPING[color][piece_type]

		sprite.region_rect = Rect2(
			region_pos.x * SPRITE_SIZE,
			region_pos.y * SPRITE_SIZE,
			SPRITE_SIZE,
			SPRITE_SIZE
		)

func set_selected(value: bool):
	selected = value
	if selected:
		sprite.modulate = Color.RED
	else:
		sprite.modulate = Color.WHITE
		
func set_highlighted(value):
	highlighted = value
	#sprite.modulate = Color.YELLOW if highlighted else Color.WHITE
	if selected:
		sprite.modulate = Color.RED
	else:
		sprite.modulate = Color.YELLOW if highlighted else Color.WHITE
	
func move_to(target: Vector2):
	board_position = target

	position = Vector2(
		board_position.x * CELL_SIZE + CELL_SIZE / 2,
		board_position.y * CELL_SIZE + CELL_SIZE / 2
		)

	print("Quân đã di chuyển tới: ", board_position)

func is_valid_move(target: Vector2) -> bool:
	var move_distance = max(
	abs(target.x - board_position.x),
	abs(target.y - board_position.y)
	)
	
	if move_distance > board_handle.get_remaining_points():
		board_handle.deselect_piece()
		print("Không đủ điểm để đi tới ô này.")
		return false
		
	if piece_type == Globals.PIECE_TYPES.PAWN:
		return pawn_rule(target)
	if piece_type == Globals.PIECE_TYPES.ROOK:
		return rook_rule(target)
	if piece_type == Globals.PIECE_TYPES.BISHOP:
		return bishop_rule(target)
	if piece_type == Globals.PIECE_TYPES.QUEEN:
		return queen_rule(target)
	if piece_type == Globals.PIECE_TYPES.KING:
		return king_rule(target)
	return false

func pawn_rule(target: Vector2) -> bool:
	if moved:
		print("❌ Tốt này đã di chuyển trong lượt này!")
		return false

	var direction = -1 if color == Globals.COLORS.WHITE else 1

	# Đi thẳng 1 ô
	if target.x == board_position.x:
		if target.y == board_position.y + direction:
			var target_piece = board_handle.get_piece_at(target)
			
			if target_piece == null:
				return true
	# Ăn chéo
	if abs(target.x - board_position.x) == 1:
		if target.y == board_position.y + direction:
			var target_piece = board_handle.get_piece_at(target)

			if target_piece != null:
				if target_piece.color != color:
					return true
	return false

func rook_rule(target: Vector2) -> bool:
	if captured_this_turn:
		print("❌ Xe đã ăn quân trong lượt này, không thể di chuyển tiếp!")
		return false
	var direction = get_move_direction(target)
	if move_direction != Vector2.ZERO:
		if direction != move_direction:
			print("❌ Xe không được đổi hướng trong lượt này!")
			return false
			
	print("Hướng Xe đang muốn đi: ", direction)
	print("Hướng đã lưu: ", move_direction)
	
	if move_direction == Vector2.ZERO:
		move_direction = direction
		
	
	if target.x == board_position.x:
		return is_path_clear(target)

	if target.y == board_position.y:
		return is_path_clear(target)

	return false

func bishop_rule(target: Vector2) -> bool:
	
	if captured_this_turn:
		print("❌ Tượng đã ăn quân trong lượt này, không thể di chuyển tiếp!")
		return false
	
	var direction = get_bishop_direction(target)

	if direction == Vector2.ZERO:
		return false

	if move_direction != Vector2.ZERO:
		if direction != move_direction:
			print("❌ Tượng không được đổi hướng trong lượt này!")
			return false

	var distance_x = abs(target.x - board_position.x)
	var distance_y = abs(target.y - board_position.y)

	if distance_x != distance_y:
		return false
		
	if not is_bishop_path_clear(target):
		print("❌ Tượng bị quân khác chặn đường!")
		return false
		
	return true

func queen_rule(target: Vector2) -> bool:
	if captured_this_turn:
		print("❌ Hậu đã ăn quân trong lượt này, không thể di chuyển tiếp!")
		return false
	
	var direction = get_queen_direction(target)

	print("Hướng Hậu muốn đi: ", direction)
	print("Hướng Hậu đang khóa: ", move_direction)
	
	if direction == Vector2.ZERO:
		return false
	
	if move_direction != Vector2.ZERO:
		if direction != move_direction:
			print("❌ Hậu không được đổi hướng trong lượt này!")
			return false
	
	if direction == Vector2(1, 0) or direction == Vector2(-1, 0) \
	or direction == Vector2(0, 1) or direction == Vector2(0, -1):
		if not is_path_clear(target):
			print("❌ Hậu bị quân khác chặn đường!")
			return false
	
	return true

func king_rule(target: Vector2) -> bool:
	var direction = get_queen_direction(target)

	if direction == Vector2.ZERO:
		return false
		
	if not is_king_path_clear(target):
		print("❌ Hướng của vua bị chặn!")
		return false
		
	if move_direction != Vector2.ZERO:
		if direction != move_direction:
			print("❌ Vua không được đổi hướng trong lượt này!")
			return false
	return true

func is_path_clear(target: Vector2) -> bool:
	var direction = get_move_direction(target)

	#print("Direction trong is_path_clear: ", direction)

	var next_position = board_position + direction
	
	while next_position != target:
		var next_piece = board_handle.get_piece_at(next_position)
	
		#print("Đang kiểm tra ô: ", next_position)
		#print("Quân ở ô này: ", next_piece)
	
		if next_piece != null:
			print("❌ Có quân chặn đường!")
			return false
		
		next_position += direction
		
		#print("Vị trí tiếp theo sau khi cộng: ", next_position)
	return true

func get_move_direction(target: Vector2) -> Vector2:
	var direction = target - board_position

	if direction.x > 0:
		return Vector2(1, 0)

	if direction.x < 0:
		return Vector2(-1, 0)

	if direction.y > 0:
		return Vector2(0, 1)

	if direction.y < 0:
		return Vector2(0, -1)

	return Vector2.ZERO

func get_bishop_direction(target: Vector2) -> Vector2:
	var direction = target - board_position

	if direction.x > 0 and direction.y > 0:
		return Vector2(1, 1)

	if direction.x < 0 and direction.y > 0:
		return Vector2(-1, 1)

	if direction.x > 0 and direction.y < 0:
		return Vector2(1, -1)

	if direction.x < 0 and direction.y < 0:
		return Vector2(-1, -1)

	return Vector2.ZERO

func is_bishop_path_clear(target: Vector2) -> bool:
	var direction = get_bishop_direction(target)
	var next_position = board_position + direction

	while next_position != target:
		var next_piece = board_handle.get_piece_at(next_position)

		if next_piece != null:
			return false

		next_position += direction

	return true

func is_king_path_clear(target: Vector2) -> bool:
	var direction = get_queen_direction(target)
	var next_position = board_position + direction

	while next_position != target:
		var next_piece = board_handle.get_piece_at(next_position)

		if next_piece != null:
			return false

		next_position += direction

	return true

func get_queen_direction(target: Vector2) -> Vector2:
	var direction = target - board_position

	# Đi ngang hoặc đi dọc
	if direction.x == 0 or direction.y == 0:
		return get_move_direction(target)

	# Đi chéo đúng 45 độ
	if abs(direction.x) == abs(direction.y):
		return get_bishop_direction(target)

	# Không phải ngang, dọc hay chéo
	return Vector2.ZERO

func scan_rook(max_points: int):
	var scan_results = []

	if captured_this_turn:
		return scan_results

	var directions = []

	if move_direction != Vector2.ZERO:
		directions.append(move_direction)
	else:
		directions = [
			Vector2(1, 0),
			Vector2(-1, 0),
			Vector2(0, 1),
			Vector2(0, -1)
		]

	for direction in directions:
		var positions = []
		var current_position = board_position + direction

		for i in range(max_points):

			if current_position.x < 0 or current_position.x >= 6:
				break

			if current_position.y < 0 or current_position.y >= 8:
				break

			var target_piece = board_handle.get_piece_at(current_position)

			if target_piece == null:
				positions.append(current_position)
				current_position += direction
				continue

			if target_piece.color != color:
				positions.append(current_position)

			break

		if positions.is_empty():
			continue

		scan_results.append({
			"direction": direction,
			"max_distance": positions.size(),
			"positions": positions
		})

	return scan_results

func scan_pawn(max_points: int):
	var scan_results = []
	
	if max_points <= 0:
		return scan_results
		
	if moved:
		return scan_results

	var direction = -1 if color == Globals.COLORS.WHITE else 1

	# Đi thẳng
	var forward_position = board_position + Vector2(0, direction)

	if forward_position.y >= 0 and forward_position.y < 8:
		var target_piece = board_handle.get_piece_at(forward_position)

		if target_piece == null:
			scan_results.append({
				"direction": Vector2(0, direction),
				"max_distance": 1,
				"positions": [forward_position]
			})

	# Ăn chéo trái
	var left_position = board_position + Vector2(-1, direction)

	if left_position.x >= 0 and left_position.x < 6:
		var target_piece = board_handle.get_piece_at(left_position)

		if target_piece != null and target_piece.color != color:
			scan_results.append({
				"direction": Vector2(-1, direction),
				"max_distance": 1,
				"positions": [left_position]
			})

	# Ăn chéo phải
	var right_position = board_position + Vector2(1, direction)

	if right_position.x >= 0 and right_position.x < 6:
		var target_piece = board_handle.get_piece_at(right_position)

		if target_piece != null and target_piece.color != color:
			scan_results.append({
				"direction": Vector2(1, direction),
				"max_distance": 1,
				"positions": [right_position]
			})

	return scan_results

func scan_bishop(max_points: int):
	var scan_results = []

	if max_points <= 0:
		return scan_results

	if captured_this_turn:
		return scan_results

	var directions = []

	if move_direction != Vector2.ZERO:
		directions.append(move_direction)
	else:
		directions = [
			Vector2(1, 1),
			Vector2(-1, 1),
			Vector2(1, -1),
			Vector2(-1, -1)
		]

	for direction in directions:
		var positions = []
		var current_position = board_position + direction

		for i in range(max_points):

			if current_position.x < 0 or current_position.x >= 6:
				break

			if current_position.y < 0 or current_position.y >= 8:
				break

			var target_piece = board_handle.get_piece_at(current_position)

			if target_piece == null:
				positions.append(current_position)
				current_position += direction
				continue

			if target_piece.color != color:
				positions.append(current_position)

			break

		if not positions.is_empty():
			scan_results.append({
				"direction": direction,
				"max_distance": positions.size(),
				"positions": positions
			})

	return scan_results

func scan_queen(max_points: int):
	var scan_results = []

	if max_points <= 0:
		return scan_results

	if captured_this_turn:
		return scan_results

	var directions = []

	if move_direction != Vector2.ZERO:
		directions.append(move_direction)
	else:
		directions = [
			Vector2(1, 0),
			Vector2(-1, 0),
			Vector2(0, 1),
			Vector2(0, -1),
			Vector2(1, 1),
			Vector2(-1, 1),
			Vector2(1, -1),
			Vector2(-1, -1)
		]

	for direction in directions:
		var positions = []
		var current_position = board_position + direction

		for i in range(max_points):

			if current_position.x < 0 or current_position.x >= 6:
				break

			if current_position.y < 0 or current_position.y >= 8:
				break

			var target_piece = board_handle.get_piece_at(current_position)

			if target_piece == null:
				positions.append(current_position)
				current_position += direction
				continue

			if target_piece.color != color:
				positions.append(current_position)

			break

		if not positions.is_empty():
			scan_results.append({
				"direction": direction,
				"max_distance": positions.size(),
				"positions": positions
			})

	return scan_results

func scan_king(max_points: int):
	var scan_results = []

	if max_points <= 0:
		return scan_results

	var directions = []

	if move_direction != Vector2.ZERO:
		directions.append(move_direction)
	else:
		directions = [
			Vector2(1, 0),
			Vector2(-1, 0),
			Vector2(0, 1),
			Vector2(0, -1),
			Vector2(1, 1),
			Vector2(-1, 1),
			Vector2(1, -1),
			Vector2(-1, -1)
		]

	for direction in directions:
		var positions = []
		var current_position = board_position + direction

		for i in range(max_points):

			if current_position.x < 0 or current_position.x >= 6:
				break

			if current_position.y < 0 or current_position.y >= 8:
				break

			var target_piece = board_handle.get_piece_at(current_position)

			if target_piece == null:
				positions.append(current_position)
				current_position += direction
				continue

			if target_piece.color != color:
				positions.append(current_position)

			break

		if not positions.is_empty():
			scan_results.append({
				"direction": direction,
				"max_distance": positions.size(),
				"positions": positions
			})

	return scan_results

func scan_piece(max_points: int):
	var scan_results = []

	#print("========== SCAN PIECE ==========")
	#print("Quân: ", piece_type)
	#print("Vị trí: ", board_position)
	#print("Điểm còn lại: ", max_points)

	if piece_type == Globals.PIECE_TYPES.ROOK:
		scan_results = scan_rook(max_points)
	
	if piece_type == Globals.PIECE_TYPES.PAWN:
		scan_results = scan_pawn(max_points)
		
	if piece_type == Globals.PIECE_TYPES.BISHOP:
		scan_results = scan_bishop(max_points)
		
	if piece_type == Globals.PIECE_TYPES.QUEEN:
		scan_results = scan_queen(max_points)
	if piece_type == Globals.PIECE_TYPES.KING:
		scan_results = scan_king(max_points)
	#print("Kết quả cuối: ", scan_results)
	#print("================================")

	return scan_results
