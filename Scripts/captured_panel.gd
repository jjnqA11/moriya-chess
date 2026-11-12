extends VBoxContainer

# Đổi thành đường dẫn spritesheet thật (xem ghi chú bên dưới)
const SHEET: Texture2D = preload("res://Assets/Chess/32x32 Chess Detailed (SpriteSheet).png")
const SPRITE_SIZE := 34

# Thứ tự icon trên mỗi hàng. Thêm KING vào đây nếu trưởng nhóm muốn đủ 5 ô.
var TYPES := [
	Globals.PIECE_TYPES.KING,
	Globals.PIECE_TYPES.QUEEN,
	Globals.PIECE_TYPES.ROOK,
	Globals.PIECE_TYPES.BISHOP,
	Globals.PIECE_TYPES.PAWN,
]

var labels := {}   # labels[color][type] = Label
var counts := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for color in [Globals.COLORS.BLACK, Globals.COLORS.WHITE]:
		labels[color] = {}
		counts[color] = {}
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		for type in TYPES:
			counts[color][type] = 0
			var slot := VBoxContainer.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(slot)

			var atlas := AtlasTexture.new()
			atlas.atlas = SHEET
			var pos: Vector2i = Globals.SPRITE_MAPPING[color][type]
			atlas.region = Rect2(pos.x * SPRITE_SIZE, pos.y * SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE)

			var icon := TextureRect.new()
			icon.texture = atlas
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.custom_minimum_size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)

			var label := Label.new()
			label.text = "0"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(label)
			labels[color][type] = label

func add_capture(color, type) -> void:
	if not counts.has(color) or not counts[color].has(type):
		return
	counts[color][type] += 1
	labels[color][type].text = str(counts[color][type])
