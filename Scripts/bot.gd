extends Node

var game_handle
var board_handle

func setup(game, board):
	game_handle = game
	board_handle = board


func easy_move():
	while game_handle.dice.remaining_points > 0:
		var possible_moves = get_all_possible_moves()

		if possible_moves.is_empty():
			print("🤖 Bot không còn nước đi! → Skip phần điểm còn lại.")
			game_handle.dice.remaining_points = 0
			game_handle.update_movement_points_ui(Globals.COLORS.BLACK)
			break

		var random_move = possible_moves.pick_random()

		var piece = random_move["piece"]
		var target_position = random_move["target"]

		print("🤖 Bot chọn: ", piece.piece_type, " -> ", target_position)

		board_handle.execute_move(piece, target_position)

		# Chờ một chút để người chơi nhìn thấy Bot vừa đi
		if game_handle.dice.remaining_points > 0:
			await get_tree().create_timer(2).timeout

func get_all_possible_moves():
	var possible_moves = []
	
	for piece in board_handle.pieces:
		# Chỉ lấy quân của Bot
		if piece.color != Globals.COLORS.BLACK:
			continue
		
		var scan_result = piece.scan_piece(
			game_handle.dice.remaining_points
		)
		
		for result in scan_result:
			for target_position in result["positions"]:
				possible_moves.append({
					"piece": piece,
					"target": target_position
				})
	
	return possible_moves
