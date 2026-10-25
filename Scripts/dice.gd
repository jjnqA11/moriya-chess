# xử lý xúc xắc ngẫu nhiên, cái này để game.gd gọi vào dùng th

extends Node2D

var value: int = 0
var remaining_points: int = 0

func roll():
	value = randi_range(1, 6)
	remaining_points = value
	print("Dice rolled: ", value)
	print("Remaining points: ", remaining_points)
	return value
