extends Timer
	
const MOVEMENT_TIME = 30
const ROLL_TIME = 10

signal timer_finished

var game_handle

func _ready():
	game_handle = get_parent()
	timeout.connect(_on_timer_timeout)
	print("Timer đang sẵn sàng.")

func _on_timer_timeout():
	if game_handle.game_ended:
		return
	print("⏰ Timer hết thời gian!")
	timer_finished.emit()


func start_roll_phase():
	stop()
	start(ROLL_TIME)

func start_movement_phase():
	stop()
	start(MOVEMENT_TIME)
