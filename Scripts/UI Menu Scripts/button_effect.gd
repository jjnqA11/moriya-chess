extends Button

@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color(1.0, 0.85, 0.2)   # vàng
@export var hover_scale: float = 1.1                      # phóng to 110%

@onready var glow: TextureRect = $Glow
var tween: Tween

func _ready() -> void:
	resized.connect(_update_button_pivot)
	_update_button_pivot()
	glow.resized.connect(_update_pivot)
	_update_pivot()
	glow.scale = Vector2(0.0, 0.5)
	glow.modulate.a = 0.0
	_set_text_color(normal_color)
	mouse_entered.connect(_expand)
	mouse_exited.connect(_shrink)
	focus_entered.connect(_expand)
	focus_exited.connect(_shrink)
	pressed.connect(Sfx.play_click)

func _update_button_pivot() -> void:
	pivot_offset = size / 2.0

func _update_pivot() -> void:
	glow.pivot_offset = glow.size / 2.0

func _set_text_color(c: Color) -> void:
	add_theme_color_override("font_color", c)
	add_theme_color_override("font_hover_color", c)
	add_theme_color_override("font_pressed_color", c)
	add_theme_color_override("font_focus_color", c)

func _get_text_color() -> Color:
	return get_theme_color("font_color")

func _expand() -> void:
	_animate(Vector2.ONE, 1.0, hover_color, Vector2.ONE * hover_scale, Tween.EASE_OUT, Tween.TRANS_BACK)

func _shrink() -> void:
	_animate(Vector2(0.0, 0.5), 0.0, normal_color, Vector2.ONE, Tween.EASE_IN, Tween.TRANS_CUBIC)

func _animate(glow_scale: Vector2, target_alpha: float, target_color: Color, btn_scale: Vector2, ease_type: Tween.EaseType, trans: Tween.TransitionType) -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(glow, "scale", glow_scale, 0.25).set_ease(ease_type).set_trans(trans)
	tween.tween_property(glow, "modulate:a", target_alpha, 0.2)
	tween.tween_method(_set_text_color, _get_text_color(), target_color, 0.2)
	tween.tween_property(self, "scale", btn_scale, 0.05).set_ease(ease_type).set_trans(trans)
