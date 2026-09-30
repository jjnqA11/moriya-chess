extends Control

const CELL_SIZE = 55
const SPRITE_SIZE = 34
@onready var black_reserve: HBoxContainer = $BlackReserve
@onready var white_reserve: HBoxContainer = $WhiteReserve
@onready var game_handle = $".."
@onready var reserve_highlight_cell: Panel = $ReserveHighlightCell
@onready var notification_layer: Control = $NotificationLayer

const PIECE_TEXTURE = preload("res://Assets/Chess/32x32 Chess Detailed (SpriteSheet).png")
const LOCK_TEXTURE = preload("res://Assets/PadLock/Small Oval Padlock - GOLD - 0000.png")	
const RESERVE_PIECES = [
	Globals.PIECE_TYPES.ROOK,
	Globals.PIECE_TYPES.BISHOP,
	Globals.PIECE_TYPES.QUEEN
]

var black_reserve_unlocked = false
var white_reserve_unlocked = false
var selected_reserve_type = null
var selected_reserve_slot = null
var reserve_highlights = []

func _ready():
	print("UI G.D. ĐÃ CHẠY!")
	create_reserve_slots()
	#unlock_black_reserve()
	#unlock_white_reserve()
	
func get_current_player_reserve():
	if game_handle.current_player == Globals.COLORS.BLACK:
		return black_reserve
	else:
		return white_reserve
		
func get_current_player_reserve_slots():
	var reserve = get_current_player_reserve()
	return reserve.get_children()
	
func create_reserve_slots():
	for i in range(3):
		var slot = ColorRect.new()

		slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		slot.color = Color(0.8, 0.6, 0.4) if i % 2 == 0 else Color(0.4, 0.3, 0.2)
		
		var overlay = ColorRect.new()
		overlay.name = "LockOverlay"
		overlay.color = Color(0, 0, 0, 0.35)
		overlay.size = Vector2(CELL_SIZE, CELL_SIZE)
		overlay.z_index = 10
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(overlay)
		
		var lock_sprite = Sprite2D.new()
		lock_sprite.name = "LockSprite"
		lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock_sprite.texture = LOCK_TEXTURE
		lock_sprite.position = Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
		lock_sprite.modulate = Color(1, 1, 1, 1)
		lock_sprite.scale = Vector2(1.5, 1.5)
		lock_sprite.z_index = 10
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(lock_sprite)
		
		var piece_type = RESERVE_PIECES[i]
		slot.set_meta("piece_type", piece_type)
		slot.gui_input.connect(_on_reserve_slot_input.bind(slot))
		
		create_reserve_piece(
			slot,
			Globals.COLORS.BLACK,
			piece_type
		)

		$BlackReserve.add_child(slot)
	for i in range(3):
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		slot.color = Color(0.8, 0.6, 0.4) if i % 2 == 0 else Color(0.4, 0.3, 0.2)
		
		var overlay = ColorRect.new()
		overlay.name = "LockOverlay"
		overlay.color = Color(0, 0, 0, 0.35)
		overlay.size = Vector2(CELL_SIZE, CELL_SIZE)
		overlay.z_index = 10
		slot.add_child(overlay)

		var lock_sprite = Sprite2D.new()
		lock_sprite.name = "LockSprite"
		lock_sprite.texture = LOCK_TEXTURE
		lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock_sprite.position = Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
		lock_sprite.modulate = Color(1, 1, 1, 1)
		lock_sprite.scale = Vector2(1.5, 1.5)
		lock_sprite.z_index = 10
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(lock_sprite)
		
		var piece_type = RESERVE_PIECES[2 - i]
		slot.set_meta("piece_type", piece_type)
		slot.gui_input.connect(_on_reserve_slot_input.bind(slot))
		create_reserve_piece(
			slot,
			Globals.COLORS.WHITE,
			piece_type
		)

		$WhiteReserve.add_child(slot)

func create_reserve_piece(slot, color, piece_type):
	var piece_sprite = Sprite2D.new()
	piece_sprite.name = "ReservePiece"
	piece_sprite.texture = PIECE_TEXTURE
	piece_sprite.scale = Vector2(1.5, 1.5)
	piece_sprite.position = Vector2(27, 27)

	var region_pos = Globals.SPRITE_MAPPING[color][piece_type]

	piece_sprite.region_enabled = true
	piece_sprite.region_rect = Rect2(
		region_pos.x * SPRITE_SIZE,
		region_pos.y * SPRITE_SIZE,
		SPRITE_SIZE,
		SPRITE_SIZE
	)

	slot.add_child(piece_sprite)

func unlock_black_reserve():
	black_reserve_unlocked = true
	
	for slot in $BlackReserve.get_children():
		var overlay = slot.get_node("LockOverlay")
		var lock_sprite = slot.get_node("LockSprite")

		overlay.visible = false
		lock_sprite.visible = false

func unlock_white_reserve():
	white_reserve_unlocked = true
	
	for slot in $WhiteReserve.get_children():
		var overlay = slot.get_node("LockOverlay")
		var lock_sprite = slot.get_node("LockSprite")

		overlay.visible = false
		lock_sprite.visible = false

func _on_reserve_slot_input(event, slot):
	if game_handle.game_ended:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var board = $"../Board"
			if game_handle.phase != Globals.PHASE.MOVEMENT:
				print("❌ Chỉ được thay quân trong phase di chuyển!")
				board.deselect_piece()
				return
			if board.selected_piece != null:
				if not is_current_player_reserve_unlocked():
					board.deselect_piece()
					print("❌ Quân dự bị chưa được mở khóa!")
					return
				if slot in board.used_reserve_slots:
					board.deselect_piece()
					board.clear_highlight_cells()
					board.clear_highlight_cells()
					deselect_reserve()

					print("❌ Quân dự bị này đã được sử dụng!")
					return
				var reserve_type = slot.get_meta("piece_type")

				board.swap_with_reserve(
					board.selected_piece,
					reserve_type,
					slot
				)
				return
			var _current_player = get_parent().current_player
			#if slot in board_handle.used_reserve_slots:
				#return

			# Nếu click lại quân đang chọn → bỏ chọn
			if selected_reserve_slot == slot:
				var old_piece_sprite = slot.get_node("ReservePiece")
				old_piece_sprite.modulate = Color.WHITE

				selected_reserve_slot = null
				selected_reserve_type = null

				print("Đã bỏ chọn dự bị")
				return

			# Bỏ chọn quân dự bị cũ
			if selected_reserve_slot != null:
				var old_piece_sprite = selected_reserve_slot.get_node("ReservePiece")
				old_piece_sprite.modulate = Color.WHITE
			# Kiểm tra Reserve đã mở chưa
			if not is_current_player_reserve_unlocked():
				board.deselect_piece()
				board.clear_highlight_cells()
				clear_reserve_highlights()

				notification_layer.show_notification("❌ Quân dự bị chưa được mở khóa!")
				return
			
			# Chọn quân mới
			var piece_type = slot.get_meta("piece_type")
			var piece_sprite = slot.get_node("ReservePiece")

			selected_reserve_type = piece_type
			selected_reserve_slot = slot

			piece_sprite.modulate = Color.RED

			print("Đã chọn dự bị: ", selected_reserve_type)

func highlight_reserve_slot(slot):
	var highlight = reserve_highlight_cell.duplicate()

	slot.add_child(highlight)

	highlight.position = Vector2.ZERO
	highlight.visible = true
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 20

	highlight.modulate.a = 0.0

	var tween = create_tween()

	# Fade in
	tween.tween_property(
		highlight,
		"modulate:a",
		1.0,
		0.3
	)

	# Giữ sáng 2 giây
	tween.tween_interval(1.4)

	# Fade out
	tween.tween_property(
		highlight,
		"modulate:a",
		0.0,
		0.3
	)

	reserve_highlights.append(highlight)
	
func clear_reserve_highlights():
	for highlight in reserve_highlights:
		highlight.queue_free()

	reserve_highlights.clear()

func deselect_reserve():
	if selected_reserve_slot != null:
		var piece_sprite = selected_reserve_slot.get_node("ReservePiece")
		piece_sprite.modulate = Color.WHITE

	selected_reserve_slot = null
	selected_reserve_type = null

func is_current_player_reserve_unlocked():
	if game_handle.current_player == Globals.COLORS.BLACK:
		return black_reserve_unlocked
	else:
		return white_reserve_unlocked

#func _on_reserve_slot_input(event, slot):
	#if game_handle.game_ended:
		#return
#
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#var board = $"../Board"
#
			#if game_handle.phase != Globals.PHASE.MOVEMENT:
				#print("❌ Chỉ được thay quân trong phase di chuyển!")
				#board.deselect_piece()
				#return
#
			#if not is_current_player_reserve_unlocked():
				#board.deselect_piece()
				#board.clear_highlight_cells()
				#clear_reserve_highlights()
				#print("❌ Quân dự bị chưa được mở khóa!")
				#return
