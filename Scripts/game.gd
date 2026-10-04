extends Node2D

@onready var timer = $Timer
@onready var board = $Board
@onready var dice = $Dice

@onready var roll_button = $UI/Player1/Buttons/RollButton
@onready var skip_button = $UI/Player1/Buttons/SkipButton

@onready var player2_roll_button = $UI/Player2/Buttons/RollButton
@onready var player2_skip_button = $UI/Player2/Buttons/SkipButton

@onready var player1_status_notification = $UI/Player1/StatusNotification
@onready var player2_status_notification = $UI/Player2/StatusNotification

@onready var player1_status_label: Label = $UI/Player1/TimeStatusLabel
@onready var player2_status_label: Label = $UI/Player2/TimeStatusLabel

@onready var player1_movement_points = $UI/Player1/PlayerInfo/MovementPoints
@onready var player2_movement_points = $UI/Player2/PlayerInfo/MovementPoints

@onready var player2_error_points: Label = $UI/Player2/PlayerInfo/ErrorPoints
@onready var player1_error_points: Label = $UI/Player1/PlayerInfo/ErrorPoints

@onready var game_handle = $".."

@onready var dice_result = $UI/DiceResult
@onready var notification_layer = $UI/NotificationLayer

@onready var bot: Node = $Bot

@onready var game_over_ui = $UI/GameOver
@onready var game_over_animation = $UI/GameOver/AnimationPlayer
@onready var game_over_content = $UI/GameOver/GameOverContent

@onready var pvp_white_win = $UI/GameOver/GameOverContent/PvPWhiteWin
@onready var pvp_black_win = $UI/GameOver/GameOverContent/PvPBlackWin
@onready var pve_white_win = $UI/GameOver/GameOverContent/PvEWhiteWin
@onready var pve_white_lose = $UI/GameOver/GameOverContent/PvEWhiteLose

@onready var pvp_white_restart = $UI/GameOver/GameOverContent/PvPWhiteWin/MainContainer/ButtonContainer/RestartButton
@onready var pvp_white_menu = $UI/GameOver/GameOverContent/PvPWhiteWin/MainContainer/ButtonContainer/BakcToMenuButton

@onready var pvp_black_restart = $UI/GameOver/GameOverContent/PvPBlackWin/MainContainer/ButtonContainer/RestartButton
@onready var pvp_black_menu = $UI/GameOver/GameOverContent/PvPBlackWin/MainContainer/ButtonContainer/BakcToMenuButton

@onready var pve_win_restart = $UI/GameOver/GameOverContent/PvEWhiteWin/MainContainer/ButtonContainer/RestartButton
@onready var pve_win_menu = $UI/GameOver/GameOverContent/PvEWhiteWin/MainContainer/ButtonContainer/BakcToMenuButton

@onready var pve_lose_restart = $UI/GameOver/GameOverContent/PvEWhiteLose/MainContainer/ButtonContainer/RestartButton
@onready var pve_lose_menu = $UI/GameOver/GameOverContent/PvEWhiteLose/MainContainer/ButtonContainer/BakcToMenuButton

var has_moved_this_turn: bool = false
var has_swapped_this_turn = false
var first_roll: bool = true
var timer_max_time = 0
var current_player: Globals.COLORS = Globals.COLORS.WHITE
var phase = Globals.PHASE.MOVEMENT
var movement_phase_finished: bool = false
var game_ended = false

var timeout_errors = {
	Globals.COLORS.BLACK: 0,
	Globals.COLORS.WHITE: 0
}

func _ready():
	print("🎮 Chế độ chơi: ", Globals.player_2_type)
	print("🤖 Độ khó Bot: ", Globals.ai_difficulty)
	board.game_handle = self
	
	timer.timer_finished.connect(_on_timer_finished)
	
	roll_button.pressed.connect(_on_roll_button_pressed.bind(Globals.COLORS.WHITE))
	skip_button.pressed.connect(_on_skip_button_pressed.bind(Globals.COLORS.WHITE))
	player2_roll_button.pressed.connect(_on_roll_button_pressed.bind(Globals.COLORS.BLACK))
	player2_skip_button.pressed.connect(_on_skip_button_pressed.bind(Globals.COLORS.BLACK))
	
	update_player_buttons()
	update_time_status()
	
	player1_movement_points.text = "Điểm: 0"
	player2_movement_points.text = "Điểm: 0"
	
	player1_error_points.text = "Lỗi: 0"
	player2_error_points.text = "Lỗi: 0"
	#timer.start_roll_phase()
	bot.setup(self, board)
	
	pvp_white_restart.pressed.connect(restart_game)
	pvp_black_restart.pressed.connect(restart_game)
	pve_win_restart.pressed.connect(restart_game)
	pve_lose_restart.pressed.connect(restart_game)

	pvp_white_menu.pressed.connect(back_to_menu)
	pvp_black_menu.pressed.connect(back_to_menu)
	pve_win_menu.pressed.connect(back_to_menu)
	pve_lose_menu.pressed.connect(back_to_menu)
	
func _on_roll_button_pressed(_player):
	
	if game_ended:
		return

	if _player != current_player:
		notification_layer.show_notification("Chưa tới lượt!")
		return
	
	if not first_roll:
		if not has_moved_this_turn and dice.remaining_points > 0:
			notification_layer.show_notification("Chưa thực hiện nước đi!")
			return
		if has_moved_this_turn and phase != Globals.PHASE.ROLL:
			notification_layer.show_notification("Còn điểm, chưa thể tung!\nHãy đi tiếp hoặc bấm Bỏ qua.")
			return

	var result = dice.roll()
	hide_status_notification(_player)
	update_movement_points_ui(Globals.COLORS.BLACK if _player == Globals.COLORS.WHITE else Globals.COLORS.WHITE)
	
	var player_name = "WHITE" if current_player == Globals.COLORS.WHITE else "BLACK"
	
	print("Đến lượt: ", player_name)
	print("Điểm di chuyển: ", dice.remaining_points)
	
	if first_roll:
		first_roll = false
		
		print("🎲 Bạn đã gieo lần đầu.")
		
		switch_player()
		update_time_status()
		board.scan_board()
		
		if current_player == Globals.COLORS.BLACK:
			if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
				print("🤖 Bot nhận điểm và sẽ di chuyển.")
				start_bot_turn()
	else:
		switch_player()
		phase = Globals.PHASE.MOVEMENT
		update_time_status()
		movement_phase_finished = false
		
		var next_player_name = "WHITE" if current_player == Globals.COLORS.WHITE else "BLACK"
		print("🔄 Chuyển lượt cho: ", next_player_name)
		board.scan_board()
		
		if current_player == Globals.COLORS.BLACK:
			if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
				start_bot_turn()
			
	board.deselect_piece()
	board.ui.deselect_reserve()
	dice_result.texture = Globals.DICE_TEXTURES[result]

func start_turn():
	has_moved_this_turn = false
	has_swapped_this_turn = false
	board.reset_piece_directions()

func switch_player():
	if current_player == Globals.COLORS.WHITE:
		current_player = Globals.COLORS.BLACK
		var player_name = "WHITE" if current_player == Globals.COLORS.WHITE else "BLACK"
		print("Sau khi đổi lượt: ", player_name)
	else:
		current_player = Globals.COLORS.WHITE
		var player_name = "WHITE" if current_player == Globals.COLORS.WHITE else "BLACK"
		print("Sau khi đổi lượt: ", player_name)
	
	update_player_buttons()
	update_player_layers()
	 # Reset TimeBar của người chơi mới
	if current_player == Globals.COLORS.WHITE:
		$UI/Player1/TimeRow/TimeBarContainer/TimeBar.value = 40
	else:
		$UI/Player2/TimeRow/TimeBarContainer/TimeBar.value = 40

	# Bắt đầu lại Timer cho lượt mới
	timer_max_time = timer.MOVEMENT_TIME
	timer.start_movement_phase()
	start_turn()

func _on_skip_button_pressed(_player):
	if game_ended:
		return
	if first_roll:
		notification_layer.show_notification("Tung xúc xắc trước!")
		return
	if _player != current_player:
		notification_layer.show_notification("Chưa tới lượt!")
		return
	
	if phase == Globals.PHASE.ROLL:
		notification_layer.show_notification("Không khả dụng trong giai đoạn tung xúc xắc!")
		return
	
	print("Skip được bấm - phase hiện tại: ", phase)
	
	dice.remaining_points = 0
	update_movement_points_ui(_player)
	
	if check_action_error():
		return
	
	movement_phase_finished = true
	phase = Globals.PHASE.ROLL
	
	update_time_status()
	
	board.deselect_piece()
	board.clear_highlight_cells()
	show_status_notification(_player)
	
	timer_max_time = timer.ROLL_TIME
	timer.start_roll_phase()
	board.ui.deselect_reserve()
	
func update_player_buttons():
	# =========================
	# PVP
	# =========================
	if Globals.player_2_type == Globals.PLAYER_2_TYPE.HUMAN:
		# PvP → cả hai người đều có thể bấm nút
		# Logic _on_roll / _on_skip sẽ kiểm tra có đúng lượt hay không
		
		roll_button.disabled = false
		skip_button.disabled = false
		
		player2_roll_button.disabled = false
		player2_skip_button.disabled = false
		
		roll_button.modulate.a = 1.0
		skip_button.modulate.a = 1.0
		
		player2_roll_button.modulate.a = 1.0
		player2_skip_button.modulate.a = 1.0
		
		return
	
	
	# =========================
	# PVE
	# =========================
	if current_player == Globals.COLORS.WHITE:
		# White là người chơi
		roll_button.disabled = false
		skip_button.disabled = false
		
		roll_button.modulate.a = 1.0
		skip_button.modulate.a = 1.0
		
		# Black là Bot → khóa nút
		player2_roll_button.disabled = true
		player2_skip_button.disabled = true
		
		player2_roll_button.modulate.a = 0.5
		player2_skip_button.modulate.a = 0.5
		
	else:
		# Black là Bot → White cũng không được thao tác
		roll_button.disabled = true
		skip_button.disabled = true
		
		roll_button.modulate.a = 0.5
		skip_button.modulate.a = 0.5
		
		player2_roll_button.disabled = true
		player2_skip_button.disabled = true
		
		player2_roll_button.modulate.a = 0.5
		player2_skip_button.modulate.a = 0.5

func update_player_layers():
	if current_player == Globals.COLORS.WHITE:
		$UI/Player2Layer.modulate.a = 1.0
		$UI/Player1Layer.modulate.a = 0.35
	else:
		$UI/Player2Layer.modulate.a = 0.35
		$UI/Player1Layer.modulate.a = 1.0

func update_time_status():
	# Luôn xóa trạng thái cũ trước
	$UI/Player1/TimeStatusLabel.text = ""
	$UI/Player2/TimeStatusLabel.text = ""

	# Chưa tung xúc xắc lần đầu
	if first_roll:
		return

	# Game kết thúc
	if game_ended:
		return

	# Lấy trạng thái Reserve từ UI.gd
	var reserve_selected = $UI.selected_reserve_slot != null

	# =========================
	# PHASE MOVEMENT
	# =========================
	if phase == Globals.PHASE.MOVEMENT:

		# Đang chuẩn bị Swap
		if reserve_selected:

			if current_player == Globals.COLORS.WHITE:
				$UI/Player1/TimeStatusLabel.text = "🔃 Người chơi đang chuẩn bị thay quân"
			else:
				if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
					$UI/Player2/TimeStatusLabel.text = "🔃 Bot đang chuẩn bị thay quân"
				else:
					$UI/Player2/TimeStatusLabel.text = "🔃 Người chơi 2 đang chuẩn bị thay quân"

		# Movement bình thường
		else:

			if current_player == Globals.COLORS.WHITE:
				$UI/Player1/TimeStatusLabel.text = "⌛ Người chơi đang di chuyển"

			else:
				if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
					$UI/Player2/TimeStatusLabel.text = "⌛ Bot đang di chuyển"
				else:
					$UI/Player2/TimeStatusLabel.text = "⌛ Người chơi 2 đang di chuyển"

	# =========================
	# PHASE ROLL
	# =========================
	elif phase == Globals.PHASE.ROLL:

		if current_player == Globals.COLORS.WHITE:
			$UI/Player1/TimeStatusLabel.text = "🎲 Người chơi đang chuẩn bị tung xúc xắc, hãy sẵn sàng"

		else:
			if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
				$UI/Player2/TimeStatusLabel.text = "🎲 Bot đang chuẩn bị tung xúc xắc, hãy sẵn sàng"
			else:
				$UI/Player2/TimeStatusLabel.text = "🎲 Người chơi 2 đang chuẩn bị tung xúc xắc, hãy sẵn sàng"

func show_status_notification(player):
	if player == Globals.COLORS.WHITE:
		player1_status_notification.text = "Người chơi bỏ qua số điểm còn lại."
		return
	else:
		player2_status_notification.text = "Người chơi bỏ qua số điểm còn lại."
		return

func end_movement_phase_notification(player):
	if player == Globals.COLORS.WHITE:
		player1_status_notification.text = "Thời gian di chuyển đã hết."
		return
	else:
		player2_status_notification.text = "Thời gian di chuyển đã hết."
		return

func hide_status_notification(player):
	if player == Globals.COLORS.WHITE:
		player1_status_notification.text = ""
	else:
		player2_status_notification.text = ""

func update_movement_points_ui(player):
	if player == Globals.COLORS.WHITE:
		player1_movement_points.text = "Điểm: " + str(dice.remaining_points)
		player1_error_points.text = "Lỗi: " + str(timeout_errors[player]) 
	else:
		player2_movement_points.text = "Điểm: " + str(dice.remaining_points)
		player2_error_points.text = "Lỗi: " + str(timeout_errors[player])


func _on_timer_finished():
	print("🎮 Game.gd nhận được tín hiệu Timer hết giờ!")
	
	if phase == Globals.PHASE.MOVEMENT:
		update_time_status()
		dice.remaining_points = 0
		board.clear_highlight_cells()
		
		for piece in board.movable_pieces:
			piece.set_highlighted(false)
		
		board.deselect_piece()
		update_movement_points_ui(current_player)
		
		if check_action_error():
			return
		
		phase = Globals.PHASE.ROLL
		end_movement_phase_notification(current_player)
		update_time_status()
		print("🔄 Game chuyển sang phase ROLL")
		print("Phase hiện tại: ", phase)
		
		timer_max_time = timer.ROLL_TIME
		timer.start_roll_phase()
	else:
		board.deselect_piece()
		hide_status_notification(current_player)
		print("⏰ ROLL đã hết thời gian!")
		print("Người chơi hết thời gian: ", current_player)
		
		var result = dice.roll()
		dice_result.texture = Globals.DICE_TEXTURES[result]
		
		var next_player = Globals.COLORS.WHITE if current_player == Globals.COLORS.BLACK else Globals.COLORS.BLACK
		update_movement_points_ui(next_player)
		
		switch_player()
		board.scan_board()
		phase = Globals.PHASE.MOVEMENT
		timer_max_time = timer.MOVEMENT_TIME
		update_time_status()
		timer.start_movement_phase()
		start_bot_turn()
		#timeout_errors += 1
		#print("⚠️ Số lỗi câu giờ: ", timeout_errors)
		
		#if timeout_errors >= 3:
			#print("💀 Người chơi đã thua vì câu giờ!")

#func update_timer_bar():
	#if current_player == Globals.COLORS.WHITE:
		#$UI/Player1/TimerBar.value = timer.time_left
	#else:
		#$UI/Player2/TimerBar.value = timer.time_left

func get_timer_bar_value():
	if timer_max_time <= 0:
		return 0

	if phase == Globals.PHASE.MOVEMENT:
		return 10 + (timer.time_left / timer_max_time) * 30

	else:
		return (timer.time_left / timer_max_time) * 10

func get_timer_display_seconds():
	return ceili(get_timer_bar_value())

func _process(_delta):
	if not timer.is_stopped():
		var bar_value = get_timer_bar_value()
		var time_seconds = get_timer_display_seconds()

		if current_player == Globals.COLORS.WHITE:
			$UI/Player1/TimeRow/TimeBarContainer/TimeBar.value = bar_value
			$UI/Player1/TimeRow/TimeLabel.text = str(time_seconds) + "s"

			$UI/Player2/TimeRow/TimeLabel.text = "0s"

		else:
			$UI/Player2/TimeRow/TimeBarContainer/TimeBar.value = bar_value
			$UI/Player2/TimeRow/TimeLabel.text = str(time_seconds) + "s"

			$UI/Player1/TimeRow/TimeLabel.text = "0s"

func check_no_action():
	if not has_moved_this_turn and not has_swapped_this_turn:
		print("❌ Lượt này không thực hiện hành động!")
		return true
	
	return false

func check_action_error():
	if has_moved_this_turn or has_swapped_this_turn:
		print("✅ Người chơi đã thực hiện hành động.")
		return

	timeout_errors[current_player] += 1

	print("⚠️ ", current_player, " không thực hiện hành động!")
	print("Số lỗi: ", timeout_errors[current_player])
	
	update_movement_points_ui(current_player)
	
	if timeout_errors[current_player] >= 3:
		var winner = (
			Globals.COLORS.WHITE
			if current_player == Globals.COLORS.BLACK
			else Globals.COLORS.BLACK
		)

		print("❌ ", current_player, " đã mắc 3 lỗi!")
		game_over(winner)
		return true

func start_bot_turn():
	if Globals.player_2_type != Globals.PLAYER_2_TYPE.AI:
		return
	if current_player != Globals.COLORS.BLACK:
		return
	
	if phase != Globals.PHASE.MOVEMENT:
		return
	
	print("🤖 Đến lượt Bot!")
	print("🤖 Bot có ", dice.remaining_points, " điểm.")
	
	await bot.make_move()
	if game_ended:
		return
	timer_max_time = timer.ROLL_TIME
	timer.start_roll_phase()
	update_time_status()
	finish_bot_turn()

func finish_bot_turn():
	if current_player != Globals.COLORS.BLACK:
		return
	
	print("🤖 Bot đã hoàn thành lượt.")
	
	phase = Globals.PHASE.ROLL
	update_time_status()
	# Bot chờ ngẫu nhiên từ 1 đến 10 giây trước khi tung xúc xắc
	var roll_wait_time = randi_range(1, 5)
	
	print("🎲 Bot sẽ tung xúc xắc sau ", roll_wait_time, " giây.")
	
	await get_tree().create_timer(roll_wait_time).timeout
	
	# Kiểm tra lại để tránh Bot tung trong trạng thái không hợp lệ
	if game_ended:
		return
	
	if current_player != Globals.COLORS.BLACK:
		return
	
	print("🤖 Bot đang tung xúc xắc...")
	
	var result = dice.roll()
	dice_result.texture = Globals.DICE_TEXTURES[result]
	
	update_movement_points_ui(Globals.COLORS.WHITE)
	
	print("🤖 Bot tung được: ", result)
	print("🏃 White nhận ", dice.remaining_points, " điểm.")
	
	switch_player()
	
	phase = Globals.PHASE.MOVEMENT
	update_time_status()
	movement_phase_finished = false
	
	board.scan_board()


func game_over(winner):
	print("🔥 GAME OVER! Người thắng: ", winner)

	game_ended = true
	timer.stop()
	board.clear_highlight_cells()
	board.ui.deselect_reserve()
	board.ui.clear_reserve_highlights()

	game_over_ui.show()

	game_over_content.modulate = Color.WHITE
	game_over_content.scale = Vector2.ONE

	pvp_white_win.hide()
	pvp_black_win.hide()
	pve_white_win.hide()
	pve_white_lose.hide()

	if Globals.player_2_type == Globals.PLAYER_2_TYPE.AI:
		if winner == Globals.COLORS.WHITE:
			pve_white_win.show()
		else:
			pve_white_lose.show()
	else:
		if winner == Globals.COLORS.WHITE:
			pvp_white_win.show()
		else:
			pvp_black_win.show()

	game_over_animation.play("GameOverAppear")
	get_tree().paused = true

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func back_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/TestMenu.tscn")
