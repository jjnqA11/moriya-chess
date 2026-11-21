extends Control

@onready var tutorial_title: Label = $Book/PagesMargin/Page/LeftPage/TextBox/TutorialTitle
@onready var instruction_label: Label = %InstructionLabel
@onready var next_button: Button = %NextButton
@onready var prev_button: Button = %PrevButton
@onready var back_button: Button = %BackButton
@onready var illustration_rect: TextureRect = $Book/PagesMargin/Page/RightPage/IllustrationRect

const CHESS_BOARD_TEXTURE: Texture2D = preload("res://Assets/Board/32x32 Chess Board (1).png")
const PIECES_TEXTURE: Texture2D = preload("res://Assets/Chess/32x32 Chess Detailed (SpriteSheet).png")
const SPRITE_SIZE := 34

@export_group("Căn chỉnh lưới bàn cờ")
@export var debug_draw_grid: bool = false:
	set(value):
		debug_draw_grid = value
		if is_instance_valid(grid_debug_node):
			grid_debug_node.queue_redraw()

## Bàn cờ thực tế gồm 6 cột x 8 hàng, sát mép ảnh
@export var board_cols: int = 6
@export var board_rows: int = 8

@export var grid_margin_left: float = 0.0
@export var grid_margin_top: float = 0.0
@export var grid_margin_right: float = 0.0
@export var grid_margin_bottom: float = 0.0

@export_group("Căn chỉnh quân cờ")
@export var piece_scale: float = 0.92
@export var piece_offset_y: float = -2.0

var board_overlay: Control
var grid_debug_node: Control
var demo_tween: Tween

var current_step: int = 0
var current_segment: int = 0
var is_typing: bool = false
var typing_tween: Tween

var gif_frames: Array[Dictionary] = []
var gif_frame_idx: int = 0
var gif_timer: float = 0.0
var gif_rect: TextureRect

var tutorial_steps := [
	{
		"title": "TUTORIAL_TITLE_0",
		"use_board": false,
		"image": "res://Assets/Images/mary_placeholder.png",
		"segments": [
			{ "text": "TUTORIAL_P0_S0" },
			{ "text": "TUTORIAL_P0_S1" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_1",
		"use_board": false,
		"segments": [
			{
				"text": "TUTORIAL_P1_S0",
				"image": "res://Assets/Tutorial/sanae_tent/turn_tortune/player_turn.png"
			},
			{
				"text": "TUTORIAL_P1_S1",
				"image": "res://Assets/Tutorial/sanae_tent/turn_tortune/example.png"
			}
		]
	},
	{
		"title": "TUTORIAL_TITLE_2",
		"use_board": false,
		"image": "res://Assets/Images/mary_placeholder.png",
		"segments": [
			{ "text": "TUTORIAL_P2_S0" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_3",
		"use_board": true,
		"segments": [
			{ "text": "TUTORIAL_P3_S0", "demo": "empty" },
			{ "text": "TUTORIAL_P3_S1", "demo": "pawn" },
			{ "text": "TUTORIAL_P3_S2", "demo": "rook" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_4",
		"use_board": true,
		"segments": [
			{ "text": "TUTORIAL_P4_S0", "demo": "bishop" },
			{ "text": "TUTORIAL_P4_S1", "demo": "queen" },
			{ "text": "TUTORIAL_P4_S2", "demo": "king_unlock" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_5",
		"use_board": true,
		"segments": [
			{ "text": "TUTORIAL_P5_S0", "demo": "lock_dir_intro" },
			{ "text": "TUTORIAL_P5_S1", "demo": "lock_dir_rook" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_6",
		"use_board": true,
		"segments": [
			{ "text": "TUTORIAL_P6_S0", "demo": "king_change_dir" },
			{ "text": "TUTORIAL_P6_S1", "demo": "king_change_dir" }
		]
	},
	{
		"title": "TUTORIAL_TITLE_7",
		"use_board": false,
		"segments": [
			{
				"text": "TUTORIAL_P7_S0",
				"image": "res://Assets/Tutorial/sanae_tent/time_error/output/time_error/time_error.png"
			},
			{
				"text": "TUTORIAL_P7_S1",
				"image": "res://Assets/Tutorial/sanae_tent/time_error/output/3error/3error.png"
			}
		]
	},
	{
		"title": "TUTORIAL_TITLE_8",
		"use_board": false,
		"image": "res://Assets/Images/mary_placeholder.png",
		"segments": [
			{ "text": "TUTORIAL_P8_S0" }
		]
	}
]

func _ready() -> void:
	setup_board_overlay()
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
		
	await get_tree().process_frame
	start_page(0)
	
	prev_button.text = tr("TUTORIAL_PREV")
	

func setup_board_overlay() -> void:
	board_overlay = Control.new()
	board_overlay.name = "BoardOverlay"
	board_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration_rect.add_child(board_overlay)
	
	grid_debug_node = Control.new()
	grid_debug_node.name = "GridDebug"
	grid_debug_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_debug_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_debug_node.z_index = 10
	grid_debug_node.draw.connect(_on_draw_debug_grid)
	illustration_rect.add_child(grid_debug_node)
	
	# Tạo node riêng để phát GIF, không đụng vào texture của IllustrationRect
	gif_rect = TextureRect.new()
	gif_rect.name = "GifRect"
	gif_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gif_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gif_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gif_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gif_rect.visible = false
	illustration_rect.get_parent().add_child(gif_rect)
	
func _on_draw_debug_grid() -> void:
	if not debug_draw_grid or not board_overlay.visible:
		return
	var grid := get_board_grid_rect()
	var cs := get_cell_size()
	grid_debug_node.draw_rect(grid, Color.RED, false, 2.0)
	for c in range(1, board_cols):
		var x := grid.position.x + c * cs.x
		grid_debug_node.draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), Color(0, 1, 1, 0.7), 1.0)
	for r in range(1, board_rows):
		var y := grid.position.y + r * cs.y
		grid_debug_node.draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), Color(0, 1, 1, 0.7), 1.0)

func start_page(step_idx: int) -> void:
	if step_idx < 0 or step_idx >= tutorial_steps.size():
		return
	current_step = step_idx
	current_segment = 0
	prev_button.visible = (current_step > 0)
	
	var page_data: Dictionary = tutorial_steps[current_step]
	if page_data.has("title"):
		tutorial_title.text = tr(page_data["title"])
		
	var use_board: bool = page_data.get("use_board", false)
	if use_board:
		clear_gif_animation()
		illustration_rect.visible = true
		illustration_rect.texture = CHESS_BOARD_TEXTURE
		illustration_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		board_overlay.visible = true
	else:
		clear_board_demo()
		board_overlay.visible = false
		if page_data.has("image"):
			var keep_board: bool = page_data.get("keep_board", false)
			load_tutorial_media(page_data["image"], keep_board)
			
	if is_instance_valid(grid_debug_node):
		grid_debug_node.queue_redraw()
		
	instruction_label.text = ""
	instruction_label.visible_characters = 0
	play_current_segment()

func _process(delta: float) -> void:
	if gif_frames.is_empty():
		return
		
	gif_timer += delta
	var current_dur: float = gif_frames[gif_frame_idx]["duration"]
	while gif_timer >= current_dur:
		gif_timer -= current_dur
		gif_frame_idx = (gif_frame_idx + 1) % gif_frames.size()
		gif_rect.texture = gif_frames[gif_frame_idx]["texture"]
		current_dur = gif_frames[gif_frame_idx]["duration"]

func clear_gif_animation() -> void:
	gif_frames.clear()
	gif_frame_idx = 0
	gif_timer = 0.0
	if is_instance_valid(gif_rect):
		gif_rect.visible = false
		gif_rect.texture = null

func load_tutorial_media(png_path: String, keep_board: bool = false) -> void:
	clear_gif_animation()
	if png_path == "" or not ResourceLoader.exists(png_path):
		return
		
	var base_tex: Texture2D = load(png_path)
	var txt_path: String = png_path.get_basename() + ".txt"
	
	# Nếu là ảnh tĩnh (không có file .txt) -> hiện trên IllustrationRect
	if not FileAccess.file_exists(txt_path):
		illustration_rect.visible = true
		illustration_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		illustration_rect.texture = base_tex
		return
		
	var file := FileAccess.open(txt_path, FileAccess.READ)
	if file == null:
		return
		
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(",")
		if parts.size() >= 6:
			var atlas := AtlasTexture.new()
			atlas.atlas = base_tex
			atlas.region = Rect2(float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4]))
			var dur: float = max(0.01, float(parts[5]))
			gif_frames.append({"texture": atlas, "duration": dur})
			
	if not gif_frames.is_empty():
		# Nếu keep_board = true thì giữ bàn cờ nằm dưới, ngược lại ẩn IllustrationRect đi
		if keep_board:
			illustration_rect.visible = true
			illustration_rect.texture = CHESS_BOARD_TEXTURE
			illustration_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			illustration_rect.visible = false
			
		gif_rect.visible = true
		gif_rect.texture = gif_frames[0]["texture"]

func play_current_segment() -> void:
	var page_data: Dictionary = tutorial_steps[current_step]
	var segments: Array = page_data["segments"]
	if current_segment >= segments.size():
		return
		
	var seg_data: Dictionary = segments[current_segment]
	var prev_len: int = instruction_label.text.length()
	var new_text: String = instruction_label.text + tr(seg_data["text"])
	var total_len: int = new_text.length()
	
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		
	instruction_label.text = new_text
	instruction_label.visible_characters = prev_len
	is_typing = true
	
	var added_chars: int = total_len - prev_len
	typing_tween = create_tween()
	typing_tween.tween_property(instruction_label, "visible_characters", total_len, added_chars * 0.015)
	typing_tween.finished.connect(func(): is_typing = false)
	
	var is_finished: bool = (current_step == tutorial_steps.size() - 1) and (current_segment == segments.size() - 1)
	next_button.text = tr("TUTORIAL_DONE") if is_finished else tr("TUTORIAL_NEXT")

	if page_data.get("use_board", false):
		show_board_demo(seg_data.get("demo", "empty"))
	elif seg_data.has("image"):
		var keep_board: bool = seg_data.get("keep_board", page_data.get("keep_board", false))
		load_tutorial_media(seg_data["image"], keep_board)

func _on_next_pressed() -> void:
	if is_typing:
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()
		instruction_label.visible_characters = -1
		is_typing = false
		return
		
	var segments: Array = tutorial_steps[current_step]["segments"]
	if current_segment + 1 < segments.size():
		current_segment += 1
		play_current_segment()
		return
		
	if current_step + 1 < tutorial_steps.size():
		start_page(current_step + 1)
	else:
		_on_back_button_pressed()

func _on_prev_pressed() -> void:
	if current_step > 0:
		start_page(current_step - 1)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn")

# ==============================================================================
# HỆ THỐNG CĂN CHỈNH LƯỚI 6x8 VÀ DI CHUYỂN QUÂN CỜ
# ==============================================================================

func clear_board_demo() -> void:
	if demo_tween and demo_tween.is_valid():
		demo_tween.kill()
	for child in board_overlay.get_children():
		child.queue_free()

func get_board_grid_rect() -> Rect2:
	var rect_size: Vector2 = illustration_rect.size
	var tex_size: Vector2 = CHESS_BOARD_TEXTURE.get_size()
	
	var scale_factor: float = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
	var displayed_pos: Vector2 = (rect_size - tex_size * scale_factor) * 0.5
	
	var inner_pos_in_tex := Vector2(grid_margin_left, grid_margin_top)
	var inner_size_in_tex := tex_size - Vector2(grid_margin_left + grid_margin_right, grid_margin_top + grid_margin_bottom)
	
	return Rect2(displayed_pos + inner_pos_in_tex * scale_factor, inner_size_in_tex * scale_factor)

func get_cell_size() -> Vector2:
	var grid := get_board_grid_rect()
	return Vector2(grid.size.x / float(board_cols), grid.size.y / float(board_rows))

func get_piece_pos(col: int, row: int) -> Vector2:
	var grid := get_board_grid_rect()
	var cs := get_cell_size()
	var p_size := cs * piece_scale
	var cell_top_left := grid.position + Vector2(col * cs.x, row * cs.y)
	return cell_top_left + (cs - p_size) * 0.5 + Vector2(0.0, piece_offset_y)

func spawn_piece(color: Globals.COLORS, type: Globals.PIECE_TYPES, col: int, row: int) -> TextureRect:
	var tex_rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = PIECES_TEXTURE
	
	var grid_pos: Vector2i = Globals.SPRITE_MAPPING[color][type]
	atlas.region = Rect2(grid_pos.x * SPRITE_SIZE, grid_pos.y * SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE)
	
	tex_rect.texture = atlas
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size = get_cell_size() * piece_scale
	tex_rect.position = get_piece_pos(col, row)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_overlay.add_child(tex_rect)
	return tex_rect

func show_board_demo(demo_type: String) -> void:
	clear_board_demo()
	if is_instance_valid(grid_debug_node):
		grid_debug_node.queue_redraw()
	
	match demo_type:
		"empty":
			pass
			
		"pawn":
			var pawn := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.PAWN, 2, 5)
			var enemy := spawn_piece(Globals.COLORS.BLACK, Globals.PIECE_TYPES.PAWN, 3, 4)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.5)
			demo_tween.tween_property(pawn, "position", get_piece_pos(2, 4), 0.45)
			demo_tween.tween_interval(0.6)
			demo_tween.tween_property(pawn, "position", get_piece_pos(2, 5), 0.35)
			demo_tween.tween_interval(0.35)
			demo_tween.tween_property(pawn, "position", get_piece_pos(3, 4), 0.45)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 0.0, 0.35)
			demo_tween.tween_interval(0.7)
			demo_tween.tween_property(pawn, "position", get_piece_pos(2, 5), 0.35)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.35)
			
		"rook":
			var rook := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.ROOK, 2, 4)
			var enemy := spawn_piece(Globals.COLORS.BLACK, Globals.PIECE_TYPES.PAWN, 2, 1)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(rook, "position", get_piece_pos(0, 4), 0.45)
			demo_tween.tween_property(rook, "position", get_piece_pos(5, 4), 0.65)
			demo_tween.tween_property(rook, "position", get_piece_pos(2, 4), 0.45)
			demo_tween.tween_interval(0.3)
			demo_tween.tween_property(rook, "position", get_piece_pos(2, 1), 0.5)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 0.0, 0.35)
			demo_tween.tween_interval(0.7)
			demo_tween.tween_property(rook, "position", get_piece_pos(2, 4), 0.4)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.35)
			
		"bishop":
			var bishop := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.BISHOP, 2, 4)
			var enemy := spawn_piece(Globals.COLORS.BLACK, Globals.PIECE_TYPES.PAWN, 4, 2)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(bishop, "position", get_piece_pos(0, 2), 0.45)
			demo_tween.tween_property(bishop, "position", get_piece_pos(4, 6), 0.65)
			demo_tween.tween_property(bishop, "position", get_piece_pos(2, 4), 0.45)
			demo_tween.tween_interval(0.3)
			demo_tween.tween_property(bishop, "position", get_piece_pos(4, 2), 0.45)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 0.0, 0.35)
			demo_tween.tween_interval(0.7)
			demo_tween.tween_property(bishop, "position", get_piece_pos(2, 4), 0.4)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.35)
			
		"queen":
			var queen := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.QUEEN, 2, 4)
			var enemy := spawn_piece(Globals.COLORS.BLACK, Globals.PIECE_TYPES.PAWN, 5, 1)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(queen, "position", get_piece_pos(0, 4), 0.4)
			demo_tween.tween_property(queen, "position", get_piece_pos(2, 4), 0.35)
			demo_tween.tween_property(queen, "position", get_piece_pos(2, 6), 0.4)
			demo_tween.tween_property(queen, "position", get_piece_pos(2, 4), 0.35)
			demo_tween.tween_property(queen, "position", get_piece_pos(5, 1), 0.5)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 0.0, 0.35)
			demo_tween.tween_interval(0.7)
			demo_tween.tween_property(queen, "position", get_piece_pos(2, 4), 0.4)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.35)
			
		"king_unlock":
			var p1 := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.PAWN, 1, 5)
			var p2 := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.ROOK, 4, 5)
			var king := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.KING, 2, 6)
			king.modulate = Color(0.6, 0.6, 0.6, 0.85)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(p1, "position", get_piece_pos(1, 4), 0.4)
			demo_tween.tween_interval(0.2)
			demo_tween.tween_property(p2, "position", get_piece_pos(4, 3), 0.4)
			demo_tween.tween_property(king, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
			demo_tween.tween_property(king, "position", get_piece_pos(2, 5), 0.45)
			demo_tween.tween_interval(0.8)
			demo_tween.tween_property(p1, "position", get_piece_pos(1, 5), 0.25)
			demo_tween.parallel().tween_property(p2, "position", get_piece_pos(4, 5), 0.25)
			demo_tween.parallel().tween_property(king, "position", get_piece_pos(2, 6), 0.25)
			demo_tween.parallel().tween_property(king, "modulate", Color(0.6, 0.6, 0.6, 0.85), 0.25)
			
		"lock_dir_intro", "lock_dir_rook":
			var rook := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.ROOK, 5, 4)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(rook, "position", get_piece_pos(4, 4), 0.4)
			demo_tween.tween_interval(0.35)
			demo_tween.tween_property(rook, "position", get_piece_pos(1, 4), 0.55)
			demo_tween.tween_interval(0.8)
			demo_tween.tween_property(rook, "position", get_piece_pos(5, 4), 0.35)
			
		"king_change_dir":
			var king := spawn_piece(Globals.COLORS.WHITE, Globals.PIECE_TYPES.KING, 2, 6)
			var enemy := spawn_piece(Globals.COLORS.BLACK, Globals.PIECE_TYPES.PAWN, 2, 4)
			
			demo_tween = create_tween().set_loops()
			demo_tween.tween_interval(0.4)
			demo_tween.tween_property(king, "position", get_piece_pos(2, 4), 0.5)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 0.0, 0.35)
			demo_tween.tween_interval(0.3)
			demo_tween.tween_property(king, "position", get_piece_pos(4, 2), 0.55)
			demo_tween.tween_interval(0.8)
			demo_tween.tween_property(king, "position", get_piece_pos(2, 6), 0.35)
			demo_tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.35)
