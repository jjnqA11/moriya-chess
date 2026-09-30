extends Control

@onready var notification_label = $Notification

func show_notification(message):
	var new_notification = notification_label.duplicate()
	add_child(new_notification)

	new_notification.text = message
	new_notification.position = get_global_mouse_position()
	new_notification.modulate.a = 1.0
	new_notification.z_index = 25
	
	var start_position = new_notification.position
	var target_position = start_position + Vector2(0, -50)

	var tween = create_tween()
	tween.set_parallel()
	
	tween.tween_property(new_notification, "position", target_position, 0.5)
	tween.tween_property(new_notification, "modulate:a", 0.0, 0.5)
	
	tween.chain()
	
	tween.tween_callback(new_notification.queue_free)
	
	
