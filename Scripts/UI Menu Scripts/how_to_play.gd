extends Control

@onready var instruction_label = $TutorialPanel/MainContainer/InstructionLabel
@onready var back_button = $BackButton
@onready var board_tutorial = $TutorialPanel/MainContainer/BoardContainer/BoardTutorial
@onready var highlight_cell = $TutorialPanel/MainContainer/BoardContainer/BoardTutorial/HighlightCell
@onready var phase_image_container = $TutorialPanel/PhaseImageContainer
@onready var full_move_image: TextureRect = $TutorialPanel/PhaseImageContainer/FullMoveImage
@onready var move_phase_image = $TutorialPanel/PhaseImageContainer/MovePhaseImage
@onready var dice_phase_image = $TutorialPanel/PhaseImageContainer/DicePhaseImage
@onready var move_phase_2_image: TextureRect = $TutorialPanel/PhaseImageContainer/MovePhase2Image
@onready var reserve_tutorial = $TutorialPanel/ReserveTutorial
@onready var next_button: Button = $NextButton

const LOCK_TEXTURE = preload("res://Assets/PadLock/Small Oval Padlock - GOLD - 0000.png")	
const CELL_SIZE = 60
const TYPE_SPEED = 0.04

var tutorial_step = 0
var typing_id = 0
var is_typing = false
var skip_typing = false
var tutorial_highlights = []
var selected_tutorial_piece = null
var selected_swap_piece = null
var selected_reserve_slot = -1
const INTERACTION_STEPS: Array[int] = [6, 18, 20, 23, 24, 25, 27, 28, 31, 33, 43]

# Luu hai quan dong minh da di chuyen trong bai hoc mo khoa Vua.
var king_preparation_pieces: Array = []

# Huong Vua vua dung de bat quan, dung de yeu cau doi huong.
var king_capture_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	board_tutorial.hide()
	board_tutorial.piece_clicked.connect(_on_tutorial_piece_clicked)
	board_tutorial.cell_clicked.connect(_on_tutorial_cell_clicked)
	reserve_tutorial.reserve_clicked.connect(_on_reserve_clicked)
	phase_image_container.hide()
	reserve_tutorial.hide()
	update_tutorial_text()
	next_button.pressed.connect(_on_next_button_pressed)
	
#func _input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
#
			## Nếu click vào BackButton thì không xử lý tiếp
			#if back_button.get_global_rect().has_point(event.position):
				#return
#
			## Nếu câu đang chạy typing → hoàn thành câu trước
			#if is_typing:
				#skip_typing = true
				#return
				#
			## Step 3 là bước tương tác với quân cờ,
			## không được click tự do để chuyển bước.
			## Cac buoc bat buoc phai tuong tac voi ban co hoac quan du bi.
			#if tutorial_step in [
				#6, 18, 20,
				#23, 24, 25, 27, 28,
				#31, 33, 43
			#]:
				#return
			## Nếu câu đã hiện xong → sang bước tiếp theo
			#tutorial_step += 1
			#update_tutorial_text()

func show_tutorial_pieces():
	for piece in board_tutorial.pieces:
		piece.show()

func show_phase_image(image):
	full_move_image.hide()
	move_phase_image.hide()
	dice_phase_image.hide()
	move_phase_2_image.hide()
	phase_image_container.show()
	image.show()

func update_tutorial_text():
	var text = ""

	match tutorial_step:
		0:
			text = "Mục Tiêu: Bắt Vua đối phương để chiến thắng."
			board_tutorial.hide()
			
		1:
			text = "Đây là bàn cờ của bạn."
			board_tutorial.show()
			reserve_tutorial.show()
		2:
			text = "Đây là những quân cờ bạn có thể sử dụng."
			show_tutorial_pieces()
		3:
			text = "Đây là Xe. Xe di chuyển theo đường thẳng."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.ROOK,
				Globals.COLORS.WHITE
			)
		4:
			text = "Trong phase Di chuyển, Xe chỉ được chọn một hướng. Muốn đi theo hướng khác, phải chờ lượt tiếp theo."
			board_tutorial.show()
			#board_tutorial.clear_tutorial_highlights()
		5:
			text = "Quân đồng minh đang chặn đường. Xe không thể đi xuyên qua quân của mình."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		6:
			text = "Hãy bấm vào Xe, sau đó chọn một ô bất kỳ để di chuyển."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(Globals.PIECE_TYPES.ROOK, Globals.COLORS.WHITE)
		7:
			text = "Nếu Xe bắt quân địch, Xe dừng lại và không thể di chuyển thêm trong lượt này."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()

		8:
			text = "Mỗi lượt kéo dài 40 giây."
			board_tutorial.hide()
			reserve_tutorial.hide()
			board_tutorial.clear_tutorial_highlights()

		9:
			text = "Mỗi lượt gồm 2 giai đoạn: Di chuyển và Tung xúc xắc."
			board_tutorial.hide()
			board_tutorial.clear_tutorial_highlights()
			show_phase_image(full_move_image)
		10:
			text = "Đầu tiên là giai đoạn Di chuyển.\n Giai đoạn di chuyển kéo dài 30s \n Bạn có thể bỏ qua nếu muốn chuyển sang Tung xúc xắc. "
			phase_image_container.hide()
			show_phase_image(move_phase_image)
		11:
			text = "Hết giai đoạn Di chuyển là giai đoạn Tung xúc xắc."
			phase_image_container.hide()
			show_phase_image(dice_phase_image)
		12:
			text = "Bạn có 10 giây để tung xúc xắc.\nSố điểm bạn tung được sẽ chuyển cho đối thủ."
			phase_image_container.hide()
			show_phase_image(dice_phase_image)
		13:
			text = "Khi đối thủ tung xúc xắc, số điểm đó sẽ được chuyển cho bạn."
			phase_image_container.hide()
			show_phase_image(move_phase_2_image)
		14:
			text = "Trong giai đoạn Di chuyển, bạn có thể di chuyển nhiều quân khác nhau, miễn là bạn còn đủ điểm."
			reserve_tutorial.show()
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			phase_image_container.hide()
		15:
			text = "Không di chuyển quân nào trong giai đoạn Di chuyển sẽ nhận 1 lỗi."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		16:
			text = "Nếu số lỗi đạt 3, bạn sẽ thua."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		17:
			text = "Tượng có thể đi theo đường chéo."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			phase_image_container.hide()
		18:
			text = "Hãy bấm vào Tượng, sau đó chọn một ô được đánh dấu."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.BISHOP,
				Globals.COLORS.WHITE
			)
		19:
			text = "Hậu có thể đi ngang, dọc hoặc theo đường chéo."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		20:
			text = "Hãy bấm vào Hậu, sau đó chọn một ô được đánh dấu."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.QUEEN,
				Globals.COLORS.WHITE
			)
		21:
			text = "Vua có thể di chuyển ngang, dọc hoặc chéo giống Hậu. Số điểm tiêu hao bằng khoảng cách di chuyển"
			board_tutorial.show()
			reserve_tutorial.show()
			king_preparation_pieces.clear()
			selected_tutorial_piece = null
			king_capture_direction = Vector2.ZERO
		22:
			text = "Vua không thể di chuyển ngay. Trước khi Vua đi, bạn phải di chuyển 2 quân đồng minh KHÁC NHAU trong cùng lượt."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		23:
			text = "Bước 1/2: Hãy chọn một quân Trắng bất kỳ, trừ Vua. Sau đó chọn một ô trống được đánh dấu để di chuyển."
			board_tutorial.show()
			board_tutorial.reset_tutorial_board()
			selected_tutorial_piece = null
			highlight_king_preparation_candidates()
		24:
			text = "Bước 2/2: HHãy chọn một quân Trắng KHÁC quân vừa di chuyển ở bước trước. Sau đó chọn một ô trống được đánh dấu."
			board_tutorial.show()
			selected_tutorial_piece = null
			highlight_king_preparation_candidates()
		25:
			text = "Bạn đã di chuyển 2 quân khác nhau. Vua đã đủ điều kiện di chuyển. Hãy chọn Vua rồi chọn một ô trống được đánh dấu."
			board_tutorial.show()
			selected_tutorial_piece = null
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.KING,
				Globals.COLORS.WHITE
			)
		26:
			text = "Vua có thể bắt quân địch khi di chuyển vào ô của quân đó. Trong tình huống tiếp theo, điều kiện mở khóa Vua đã được thỏa mãn."
			selected_tutorial_piece = null
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		27:
			text = "Hãy chọn Vua trắng trước, sau đó chọn quân được đánh dấu để bắt."
			board_tutorial.show()
			board_tutorial.reset_tutorial_board()
			selected_tutorial_piece = null
			king_preparation_pieces.clear()
			board_tutorial.setup_king_capture_scenario()
			highlight_king_capture_pieces()
		28:
			text = "Vua vừa bắt quân địch nên có thể đổi hướng trong cùng lượt. Hãy chọn một ô trống được đánh dấu theo hướng KHÁC với hướng vừa bắt."
			board_tutorial.show()
			show_king_new_direction_choices()
		29:
			text = "Tiếp theo, hãy tìm hiểu cách di chuyển của Tốt."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		30:
			text = "Tốt có thể di chuyển 1 ô về phía trước."
			board_tutorial.reset_tutorial_board()
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			reserve_tutorial.show()
		31:
			text = "Hãy bấm vào Tốt, sau đó chọn ô được đánh dấu."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.PAWN,
				Globals.COLORS.WHITE
			)
		32:
			text = "Tốt có thể bắt quân địch theo đường chéo."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
		33:
			text = "Hãy bấm vào Tốt, sau đó chọn quân địch được đánh dấu."
			board_tutorial.show()
			board_tutorial.setup_pawn_capture_scenario()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.PAWN,
				Globals.COLORS.WHITE
			)
			reserve_tutorial.show()
		34:
			text = "Sau khi di chuyển, Tốt không thể di chuyển thêm."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			reserve_tutorial.show()
		35:
			text = "Bạn đã mất 2 Tốt. Quân dự bị đã được mở khóa."

			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()

			reserve_tutorial.show()

			board_tutorial.simulate_two_pawn_losses()
			reserve_tutorial.unlock()
		36:
			text = "Quân dự bị có thể thay thế một quân đang có trên bàn."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			reserve_tutorial.show()
		37:
			text = "Mỗi lần thay dự bị sẽ tiêu hao toàn bộ số điểm bạn hiện có."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			reserve_tutorial.show()
		38:
			text = "Tốt có thể được thay thế bằng bất kỳ quân dự bị nào."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.PAWN,
				Globals.COLORS.WHITE
			)

			phase_image_container.hide()
			reserve_tutorial.show()
			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.PAWN
			)
		39:
			text = "Xe có thể được thay thế bằng Hậu hoặc Tượng. Xe không thể thay bằng Xe dự bị."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.ROOK,
				Globals.COLORS.WHITE
			)

			phase_image_container.hide()
			reserve_tutorial.show()
			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.ROOK
			)
		40:
			text = "Tượng có thể được thay thế bằng Hậu hoặc Xe. Tượng không thể thay bằng Tượng dự bị."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.BISHOP,
				Globals.COLORS.WHITE
			)

			phase_image_container.hide()
			reserve_tutorial.show()
			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.BISHOP
			)
		41:
			text = "Hậu có thể được thay thế bằng Xe hoặc Tượng. Hậu không thể thay bằng Hậu dự bị."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.QUEEN,
				Globals.COLORS.WHITE
			)

			phase_image_container.hide()
			reserve_tutorial.show()
			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.QUEEN
			)
		42:
			text = "Vua không thể được thay thế bằng quân dự bị."
			board_tutorial.show()
			board_tutorial.highlight_tutorial_piece(
				Globals.PIECE_TYPES.KING,
				Globals.COLORS.WHITE
			)

			phase_image_container.hide()
			reserve_tutorial.show()
			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.KING
			)
		43:
			text = "Bây giờ hãy thử thay một quân trên bàn bằng quân dự bị."
			board_tutorial.show()
			board_tutorial.clear_tutorial_highlights()
			reserve_tutorial.show()
			reserve_tutorial.clear_reserve_highlights()
		44:
			text = "Thay quân thành công! Quân dự bị đã thay thế quân được chọn."
			board_tutorial.show()
			reserve_tutorial.show()
			reserve_tutorial.clear_reserve_highlights()
			board_tutorial.clear_tutorial_highlights()
		45:
			text = "Thay quân sẽ tiêu tốn toàn bộ điểm di chuyển còn lại trong lượt."
			board_tutorial.show()
			reserve_tutorial.show()
			reserve_tutorial.clear_reserve_highlights()
			board_tutorial.clear_tutorial_highlights()
		46:
			text = "Mỗi lượt, bạn chỉ có thể thay quân dự bị một lần."
			board_tutorial.show()
			reserve_tutorial.show()
		47:
			text = "Quân dự bị đã được sử dụng sẽ không thể dùng lại."
		48:
			text = "Đó là cách sử dụng quân dự bị trong Mệnh Cờ."
		_:
			text = "Hãy bắt Vua đối phương để chiến thắng!"

	type_text(text)

func update_next_button_state() -> void:
	if not is_instance_valid(next_button):
		return

	# Nút luôn xuất hiện trên màn hình
	next_button.visible = true

	# Chỉ khóa nút khi bước hiện tại yêu cầu thao tác
	next_button.disabled = tutorial_step in INTERACTION_STEPS

func type_text(text: String):
	update_next_button_state()
	if is_instance_valid(next_button):
		next_button.disabled = true
	if is_instance_valid(next_button):
		next_button.disabled = tutorial_step in INTERACTION_STEPS
	typing_id += 1
	var current_typing_id = typing_id

	is_typing = true
	skip_typing = false

	instruction_label.text = text
	instruction_label.visible_characters = 0

	for i in text.length():
		if current_typing_id != typing_id:
			return

		if skip_typing:
			break

		instruction_label.visible_characters = i + 1
		await get_tree().create_timer(TYPE_SPEED).timeout

	if current_typing_id != typing_id:
		return

	instruction_label.visible_characters = -1
	is_typing = false
	
	update_next_button_state()
	

func _on_tutorial_piece_clicked(piece):
	if is_typing:
		return

	print("📢 HowToPlay nhận signal piece_clicked!")
	print("Quân nhận được: ", piece)
	print("Type: ", piece.piece_type, " | Color: ", piece.color)
	print("Tutorial step hiện tại: ", tutorial_step)

	if tutorial_step == 6:
		if piece.piece_type == Globals.PIECE_TYPES.ROOK \
		and piece.color == Globals.COLORS.WHITE:

			print("✅ Người chơi đã chọn đúng Xe!")

			selected_tutorial_piece = piece

			board_tutorial.show_rook_tutorial_moves(piece)

			type_text("Hãy chọn một ô được đánh dấu.")

	elif tutorial_step == 18:
		if piece.piece_type == Globals.PIECE_TYPES.BISHOP \
		and piece.color == Globals.COLORS.WHITE:

			print("✅ Người chơi đã chọn đúng Tượng!")

			selected_tutorial_piece = piece

			board_tutorial.show_bishop_tutorial_moves(piece)

			type_text("Hãy chọn một ô được đánh dấu.")
		
	elif tutorial_step == 20:
		if piece.piece_type == Globals.PIECE_TYPES.QUEEN \
		and piece.color == Globals.COLORS.WHITE:

			print("✅ Người chơi đã chọn đúng Hậu!")

			selected_tutorial_piece = piece

			board_tutorial.show_queen_tutorial_moves(piece)

			type_text("Hãy chọn một ô được đánh dấu.")
	
	elif tutorial_step == 23 or tutorial_step == 24:
		# Hai buoc chuan bi: chi chap nhan quan Trang khac Vua.
		if piece.color != Globals.COLORS.WHITE \
		or piece.piece_type == Globals.PIECE_TYPES.KING:
			type_text("Hay chon mot quan Trang khac Vua.")
			return

		if piece in king_preparation_pieces or piece.moved:
			type_text("Quan nay da di chuyen roi. Hay chon mot quan Trang KHAC.")
			return

		selected_tutorial_piece = piece

		board_tutorial.show_tutorial_piece_moves(
			piece,
			1,
			false
		)

		type_text("Hay chon mot o trong duoc danh dau.")

	elif tutorial_step == 25:
		if piece.piece_type == Globals.PIECE_TYPES.KING \
		and piece.color == Globals.COLORS.WHITE:

			if not board_tutorial.can_king_move_this_turn(piece):
				type_text("Vua chua du dieu kien. Hay di chuyen hai quan dong minh khac nhau truoc.")
				return

			selected_tutorial_piece = piece
			board_tutorial.show_king_tutorial_moves(piece)
			type_text("Hay chon mot o trong duoc danh dau.")

		else:
			type_text("Hay chon Vua Trang de thuc hanh di chuyen.")

	elif tutorial_step == 27:
		if selected_tutorial_piece == null:
			if piece.piece_type == Globals.PIECE_TYPES.KING \
			and piece.color == Globals.COLORS.WHITE:

				selected_tutorial_piece = piece
				highlight_king_capture_pieces()
				type_text("Tot! Bay gio hay chon Tot Den de bat.")

			else:
				type_text("Hay chon Vua Trang truoc.")

		else:
			if piece.piece_type == Globals.PIECE_TYPES.PAWN \
			and piece.color == Globals.COLORS.BLACK:

				var white_king = selected_tutorial_piece
				var from_position: Vector2 = white_king.board_position
				var target_position: Vector2 = piece.board_position

				var move_cost = tutorial_move_cost(
					from_position,
					target_position
				)

				if move_cost > board_tutorial.tutorial_points:
					type_text("Khong du diem de thuc hien nuoc di nay.")
					return

				king_capture_direction = Vector2(
					sign(target_position.x - from_position.x),
					sign(target_position.y - from_position.y)
				)

				board_tutorial.tutorial_points -= move_cost
				white_king.move_direction = Vector2.ZERO
				white_king.captured_this_turn = true
				white_king.moved = true

				board_tutorial.tutorial_input_locked = true
				board_tutorial.capture_tutorial_piece(
					white_king,
					target_position
				)

				# Cho hoat anh bat quan hoan tat truoc khi sang buoc moi.
				await get_tree().create_timer(0.35).timeout
				board_tutorial.tutorial_input_locked = false

				# Giu Vua duoc chon de tiep tuc di chuyen o buoc 28.
				selected_tutorial_piece = white_king
				tutorial_step = 28
				update_tutorial_text()

			else:
				type_text("Hay chon Tot Den duoc danh dau de Vua bat.")

	elif tutorial_step == 28:
		type_text("Hay chon mot o trong duoc danh dau, khong phai mot quan co.")

	elif tutorial_step == 31:
		if piece.piece_type == Globals.PIECE_TYPES.PAWN \
		and piece.color == Globals.COLORS.WHITE:

			print("✅ Người chơi đã chọn đúng Tốt!")

			selected_tutorial_piece = piece

			board_tutorial.show_pawn_tutorial_moves(piece)

			type_text("Hãy chọn một ô được đánh dấu.")
	elif tutorial_step == 33:
		if piece.piece_type == Globals.PIECE_TYPES.PAWN \
		and piece.color == Globals.COLORS.WHITE:

			print("✅ Người chơi đã chọn đúng Tốt!")

			selected_tutorial_piece = piece

			board_tutorial.show_pawn_tutorial_moves(piece)

			type_text("Hãy chọn quân địch được đánh dấu.")
		else:
			if piece.color != selected_tutorial_piece.color:
				print("✅ Tốt đã chọn quân địch để bắt!")

				board_tutorial.capture_tutorial_piece(
					selected_tutorial_piece,
					piece.board_position
				)

				selected_tutorial_piece = null

				tutorial_step = 34
				update_tutorial_text()
	elif tutorial_step == 43:
		if piece.piece_type == Globals.PIECE_TYPES.KING:
			selected_swap_piece = null
			selected_reserve_slot = -1

			board_tutorial.highlight_tutorial_piece(
				piece.piece_type,
				piece.color
			)

			reserve_tutorial.show_swap_highlights(
				Globals.PIECE_TYPES.KING
			)

			instruction_label.text = "Vua không thể được thay thế bằng quân dự bị."
			instruction_label.visible_characters = -1

			return

		selected_swap_piece = piece
		selected_reserve_slot = -1

		board_tutorial.highlight_tutorial_piece(
			piece.piece_type,
			piece.color
		)

		reserve_tutorial.show_swap_highlights(
			piece.piece_type
		)

		instruction_label.text = "Hãy chọn một quân dự bị đang được highlight."
		instruction_label.visible_characters = -1
		return
func _on_tutorial_cell_clicked(board_position):
	if is_typing:
		return

	print("📢 HowToPlay nhận click ô: ", board_position)
	print("Quân đang được lưu: ", selected_tutorial_piece)

	if selected_tutorial_piece == null:
		print("❌ Không có quân nào được lưu!")
		return

	# ===== THỰC HÀNH XE =====
	if tutorial_step == 6:
		print("✅ Người chơi đã chọn ô cho Xe!")

		board_tutorial.move_tutorial_piece(
			selected_tutorial_piece,
			board_position
		)
		selected_tutorial_piece = null
		tutorial_step = 7
		update_tutorial_text()

	# ===== THỰC HÀNH TƯỢNG =====
	elif tutorial_step == 18:
		print("✅ Người chơi đã chọn ô cho Tượng!")

		board_tutorial.move_tutorial_piece(
			selected_tutorial_piece,
			board_position
		)
		selected_tutorial_piece = null
		tutorial_step = 19
		update_tutorial_text()
	elif tutorial_step == 20:
		print("✅ Người chơi đã chọn ô cho Hậu!")

		await board_tutorial.move_tutorial_piece(
			selected_tutorial_piece,
			board_position
		)

		selected_tutorial_piece = null

		tutorial_step = 21
		update_tutorial_text()

	elif tutorial_step == 23 or tutorial_step == 24:
		var moving_piece = selected_tutorial_piece
		var from_position: Vector2 = moving_piece.board_position

		var move_cost = tutorial_move_cost(
			from_position,
			board_position
		)

		if move_cost > board_tutorial.tutorial_points:
			type_text("Khong du diem di chuyen. Hay chon o gan hon.")
			return

		await board_tutorial.move_tutorial_piece(
			moving_piece,
			board_position
		)

		board_tutorial.tutorial_points -= move_cost

		if moving_piece not in king_preparation_pieces:
			king_preparation_pieces.append(moving_piece)

		selected_tutorial_piece = null

		if tutorial_step == 23:
			tutorial_step = 24
		else:
			tutorial_step = 25

		update_tutorial_text()
		return

	elif tutorial_step == 25:
		var white_king = selected_tutorial_piece
		var from_position: Vector2 = white_king.board_position

		var move_cost = tutorial_move_cost(
			from_position,
			board_position
		)

		if move_cost > board_tutorial.tutorial_points:
			type_text("Khong du diem di chuyen. Hay chon o gan hon.")
			return

		await board_tutorial.move_tutorial_piece(
			white_king,
			board_position
		)

		board_tutorial.tutorial_points -= move_cost
		selected_tutorial_piece = null

		tutorial_step = 26
		update_tutorial_text()
		return

	elif tutorial_step == 28:
		var white_king = selected_tutorial_piece
		var from_position: Vector2 = white_king.board_position

		var direction = Vector2(
			sign(board_position.x - from_position.x),
			sign(board_position.y - from_position.y)
		)

		# Kiem tra lai huong de tranh nuoc di sai luat bai hoc.
		if direction == king_capture_direction:
			type_text("Vua phai chon mot huong KHAC huong vua dung de bat Tot.")
			show_king_new_direction_choices()
			return

		var move_cost = tutorial_move_cost(
			from_position,
			board_position
		)

		if move_cost > board_tutorial.tutorial_points:
			type_text("Khong du diem di chuyen. Hay chon o gan hon.")
			return

		await board_tutorial.move_tutorial_piece(
			white_king,
			board_position
		)

		board_tutorial.tutorial_points -= move_cost
		selected_tutorial_piece = null

		tutorial_step = 29
		update_tutorial_text()
		return

	elif tutorial_step == 31:
		print("✅ Người chơi đã chọn ô cho Tốt!")
		board_tutorial.move_tutorial_piece(selected_tutorial_piece, board_position)

		await get_tree().create_timer(0.35).timeout

		tutorial_step = 32
		update_tutorial_text()

		return

func _on_next_button_pressed() -> void:
	
	 # Nếu chữ đang chạy, chỉ hiển thị đầy đủ nội dung.
	if is_typing:
		skip_typing = true
		return
	# Không cho phép bỏ qua bước yêu cầu thao tác.
	if tutorial_step in INTERACTION_STEPS:
		return
	tutorial_step += 1
	update_tutorial_text()
	# Chuyển phần xử lý chuyển bước hiện tại từ _input()
	# sang đây, bao gồm tăng tutorial_step và cập nhật nội dung.

func highlight_king_preparation_candidates(excluded_piece = null) -> void:
	board_tutorial.clear_tutorial_highlights()

	for piece in board_tutorial.pieces:
		if not is_instance_valid(piece) or not piece.visible:
			continue

		if piece.color != Globals.COLORS.WHITE:
			continue

		if piece.piece_type == Globals.PIECE_TYPES.KING:
			continue

		if piece in king_preparation_pieces:
			continue

		if piece == excluded_piece:
			continue

		board_tutorial.highlight_tutorial_cell(
			piece.board_position,
			false
		)


func highlight_king_capture_pieces() -> void:
	board_tutorial.clear_tutorial_highlights()

	var white_king = board_tutorial.get_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.WHITE
	)

	var black_pawn = board_tutorial.get_tutorial_piece(
		Globals.PIECE_TYPES.PAWN,
		Globals.COLORS.BLACK
	)

	if white_king != null:
		board_tutorial.highlight_tutorial_cell(
			white_king.board_position,
			false
		)

	if black_pawn != null:
		board_tutorial.highlight_tutorial_cell(
			black_pawn.board_position,
			false
		)


func show_king_new_direction_choices() -> void:
	board_tutorial.clear_tutorial_highlights()

	var white_king = board_tutorial.get_tutorial_piece(
		Globals.PIECE_TYPES.KING,
		Globals.COLORS.WHITE
	)

	if white_king == null:
		return

	var scan_results = white_king.scan_king(
		board_tutorial.tutorial_points
	)

	for result in scan_results:
		for target_position in result["positions"]:
			# Chi cho chon o trong trong bai hoc nay.
			if board_tutorial.get_piece_at(target_position) != null:
				continue

			# Loai huong Vua vua dung de bat Tot.
			var direction = Vector2(
				sign(target_position.x - white_king.board_position.x),
				sign(target_position.y - white_king.board_position.y)
			)

			if direction == king_capture_direction:
				continue

			board_tutorial.highlight_tutorial_cell(target_position)


func tutorial_move_cost(
	from_position: Vector2,
	to_position: Vector2
) -> int:
	return int(max(
		abs(to_position.x - from_position.x),
		abs(to_position.y - from_position.y)
	))


func _on_reserve_clicked(slot_index):
	if tutorial_step != 43:
		return

	if selected_swap_piece == null:
		return

	if slot_index not in reserve_tutorial.available_reserve_slots:
		return

	selected_reserve_slot = slot_index

	var slot = reserve_tutorial.reserve_slots.get_child(slot_index)
	var reserve_piece_type = slot.get_meta("piece_type")

	print(
		"🔃 Tutorial swap: ",
		selected_swap_piece.piece_type,
		" -> ",
		reserve_piece_type
	)

	board_tutorial.swap_tutorial_piece(
		selected_swap_piece,
		reserve_piece_type
	)
	mark_tutorial_reserve_slot_used(slot_index)
	reserve_tutorial.clear_reserve_highlights()

	selected_swap_piece = null
	selected_reserve_slot = -1

	instruction_label.text = "Đã thay quân thành công."
	instruction_label.visible_characters = -1
	tutorial_step = 44
	update_next_button_state()

func mark_tutorial_reserve_slot_used(slot_index: int) -> void:
	var slots = reserve_tutorial.reserve_slots

	if slot_index < 0 or slot_index >= slots.get_child_count():
		return
	
	var slot = slots.get_child(slot_index)

	if not (slot is Control):
		return

	# Xóa hình quân nếu hình được gắn trực tiếp lên slot
	if slot is TextureRect:
		slot.texture = null
	elif slot is TextureButton:
		slot.texture_normal = null
		slot.texture_pressed = null
		slot.texture_hover = null
		slot.texture_disabled = null
	elif slot is Button:
		slot.icon = null

	# Ẩn các nút/hình ảnh nằm bên trong slot
	for child in slot.get_children():
		if child is CanvasItem:
			child.hide()

	# Khong tao lop phu trung lap.
	if slot.has_meta("tutorial_reserve_used"):
		return

	slot.set_meta("tutorial_reserve_used", true)

	# Danh dau slot khong con duoc su dung.
	reserve_tutorial.available_reserve_slots.erase(slot_index)

	# Lop phu toi, ban trong suot.
	var overlay := ColorRect.new()
	overlay.name = "TutorialUsedOverlay"
	overlay.color = Color(0.05, 0.05, 0.05, 0.48)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.z_index = 100
	slot.add_child(overlay)

	# Bieu tuong khoa nam o giua slot.
	var lock_sprite = Sprite2D.new()
	lock_sprite.name = "LockSprite"
	lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_sprite.texture = LOCK_TEXTURE
	lock_sprite.position = slot.size / 2.0
	lock_sprite.modulate = Color(1, 1, 1, 1)
	lock_sprite.scale = Vector2(1.5, 1.5)
	lock_sprite.z_index = 3

	overlay.add_child(lock_sprite)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn")
