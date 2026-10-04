extends Node2D

const BOARD_WIDTH = 6
const BOARD_HEIGHT = 8

const BOARD_RESERVE_WIDTH = 1
const BOARD_RESERVE_HEIGHT = 3

const DICE_TEXTURES = {
	1: preload("res://Assets/Dice/Dice 1-6 Light (1).png"),
	2: preload("res://Assets/Dice/Dice 1-6 Light (2).png"),
	3: preload("res://Assets/Dice/Dice 1-6 Light (3).png"),
	4: preload("res://Assets/Dice/Dice 1-6 Light (4).png"),
	5: preload("res://Assets/Dice/Dice 1-6 Light (5).png"),
	6: preload("res://Assets/Dice/Dice 1-6 Light (6).png")
}

# =========================
# PLAYER
# =========================

enum PLAYER {
	ONE,
	TWO
}

enum PLAYER_2_TYPE {
	HUMAN,
	AI
}

var player_2_type = PLAYER_2_TYPE.AI

enum AI_DIFFICULTY {
	EASY,
	MEDIUM,
	HARD,
	INSANE,
	EXTREME
}

var ai_difficulty = AI_DIFFICULTY.EASY
# =========================
# COLORS
# =========================

enum COLORS {
	BLACK,
	WHITE
}


# =========================
# PIECE TYPES
# =========================

enum PIECE_TYPES {
	ROOK,
	BISHOP,
	QUEEN,
	KING,
	PAWN
}


# =========================
# SPRITE MAPPING
# =========================

const SPRITE_MAPPING = {
	COLORS.BLACK: {
		PIECE_TYPES.ROOK: Vector2i(0, 1),
		PIECE_TYPES.BISHOP: Vector2i(1, 0),
		PIECE_TYPES.QUEEN: Vector2i(3, 2),
		PIECE_TYPES.KING: Vector2i(2, 1),
		PIECE_TYPES.PAWN: Vector2i(3, 0)
	},

	COLORS.WHITE: {
		PIECE_TYPES.ROOK: Vector2i(2, 0),
		PIECE_TYPES.BISHOP: Vector2i(0, 0),
		PIECE_TYPES.QUEEN: Vector2i(3, 1),
		PIECE_TYPES.KING: Vector2i(1, 1),
		PIECE_TYPES.PAWN: Vector2i(2, 2)
	}
}


# =========================
# INITIAL PIECE SET
# =========================

const INITIAL_PIECE_SET_SINGLE = [
	# Hàng chính
	[PIECE_TYPES.ROOK, 0, 0],
	[PIECE_TYPES.BISHOP, 1, 0],
	[PIECE_TYPES.QUEEN, 2, 0],
	[PIECE_TYPES.KING, 3, 0],
	[PIECE_TYPES.BISHOP, 4, 0],
	[PIECE_TYPES.ROOK, 5, 0],

	# Hàng tốt
	[PIECE_TYPES.PAWN, 0, 1],
	[PIECE_TYPES.PAWN, 1, 1],
	[PIECE_TYPES.PAWN, 2, 1],
	[PIECE_TYPES.PAWN, 3, 1],
	[PIECE_TYPES.PAWN, 4, 1],
	[PIECE_TYPES.PAWN, 5, 1]
]

#Thời gian
enum PHASE {
	MOVEMENT,
	ROLL
}
