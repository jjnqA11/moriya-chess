extends Control

signal reserve_clicked(slot_index)

const CELL_SIZE = 55
const SPRITE_SIZE = 34

const PIECE_TEXTURE = preload(
	"res://Assets/Chess/32x32 Chess Detailed (SpriteSheet).png"
)

const LOCK_TEXTURE = preload(
	"res://Assets/PadLock/Small Oval Padlock - GOLD - 0000.png"
)

const RESERVE_PIECES = [
	Globals.PIECE_TYPES.QUEEN,
	Globals.PIECE_TYPES.BISHOP,
	Globals.PIECE_TYPES.ROOK
]

@onready var reserve_tutorial: Control = $"."
@onready var reserve_slots: HBoxContainer = $ReserveSlots
@onready var reserve_highlight_cell: Panel = $ReserveHighlightCell

var reserve_highlights = []
var selected_slot_index = -1
var available_reserve_slots = []


func _ready() -> void:
	create_reserve_slots()


func create_reserve_slots():
	var i = 0

	for piece_type in RESERVE_PIECES:
		var slot = ColorRect.new()
		
		slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		slot.color = Color(0.8, 0.6, 0.4)

		# Lớp làm tối khi đang khóa
		var overlay = ColorRect.new()
		overlay.name = "LockOverlay"
		overlay.color = Color(0, 0, 0, 0.35)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 2
		slot.add_child(overlay)

		# Ổ khóa
		var lock_sprite = Sprite2D.new()
		lock_sprite.name = "LockSprite"
		lock_sprite.texture = LOCK_TEXTURE
		lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock_sprite.position = Vector2(
			CELL_SIZE / 2,
			CELL_SIZE / 2
		)
		lock_sprite.scale = Vector2(1.5, 1.5)
		lock_sprite.z_index = 3
		slot.add_child(lock_sprite)

		# Quân dự bị
		var piece_sprite = Sprite2D.new()
		piece_sprite.name = "ReservePiece"
		piece_sprite.texture = PIECE_TEXTURE
		piece_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		piece_sprite.position = Vector2(
			CELL_SIZE / 2,
			CELL_SIZE / 2
		)
		piece_sprite.scale = Vector2(1.5, 1.5)

		var region_pos = Globals.SPRITE_MAPPING[
			Globals.COLORS.WHITE
		][piece_type]

		piece_sprite.region_enabled = true
		piece_sprite.region_rect = Rect2(
			region_pos.x * SPRITE_SIZE,
			region_pos.y * SPRITE_SIZE,
			SPRITE_SIZE,
			SPRITE_SIZE
		)

		piece_sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)

		slot.add_child(piece_sprite)

		# Index của ô dự bị
		slot.set_meta("reserve_index", i)
		slot.set_meta("piece_type", piece_type)
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))

		reserve_slots.add_child(slot)

		i += 1

func unlock():
	for slot in reserve_slots.get_children():
		var overlay = slot.get_node("LockOverlay")
		var lock_sprite = slot.get_node("LockSprite")
		var piece_sprite = slot.get_node("ReservePiece")

		overlay.hide()
		lock_sprite.hide()
		piece_sprite.modulate = Color.WHITE

func highlight_reserve():
	for slot in reserve_slots.get_children():
		slot.modulate = Color(1.2, 1.2, 1.2)

func highlight_reserve_slot(slot):
	var highlight = reserve_highlight_cell.duplicate()

	slot.add_child(highlight)

	highlight.position = Vector2.ZERO
	highlight.visible = true
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 20

	highlight.modulate.a = 0.0

	var tween = create_tween()

	tween.tween_property(
		highlight,
		"modulate:a",
		1.0,
		0.3
	)

	tween.tween_interval(1.4)

	tween.tween_property(
		highlight,
		"modulate:a",
		0.0,
		0.3
	)

	reserve_highlights.append(highlight)

func _on_slot_gui_input(event, slot):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var slot_index = slot.get_meta("reserve_index")

			if slot_index not in available_reserve_slots:
				return

			print("🖱️ Chọn quân dự bị: ", slot_index)

			reserve_clicked.emit(slot_index)

			accept_event()

func select_slot(slot_index):
	selected_slot_index = slot_index

	for slot in reserve_slots.get_children():
		var piece_sprite = slot.get_node("ReservePiece")
		piece_sprite.scale = Vector2(1.5, 1.5)

	var selected_slot = reserve_slots.get_child(slot_index)
	var selected_piece = selected_slot.get_node("ReservePiece")
	selected_piece.scale = Vector2(1.7, 1.7)

func clear_reserve_highlights():
	for highlight in reserve_highlights:
		highlight.queue_free()

	reserve_highlights.clear()

func show_reserve_highlight(slot):
	var highlight = reserve_highlight_cell.duplicate()

	slot.add_child(highlight)

	highlight.position = Vector2.ZERO
	highlight.visible = true
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 20

	# Hiển thị luôn, không fade out
	highlight.modulate.a = 1.0

	reserve_highlights.append(highlight)

func show_swap_highlights(piece_type):
	clear_reserve_highlights()
	available_reserve_slots.clear()

	# Vua không thể thay
	if piece_type == Globals.PIECE_TYPES.KING:
		return

	for i in range(reserve_slots.get_child_count()):
		var slot = reserve_slots.get_child(i)
		var reserve_piece_type = slot.get_meta("piece_type")

		if reserve_piece_type == piece_type:
			continue

		available_reserve_slots.append(i)
		show_reserve_highlight(slot)
