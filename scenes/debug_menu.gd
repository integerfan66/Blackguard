extends CanvasLayer


@onready var guessPointResult : Label = $Panel/GuessPointResult
var isPaused : bool = true
@onready var Main : Node2D = $"../../../Main"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_text(t):
	guessPointResult.text = t

func _on_debug_menu_button_up() -> void:
	if not visible and not isPaused and Main.isStarted :
		visible = true
		isPaused = true
	else:
		visible = false
		isPaused = false


func _on_new_board_button_up() -> void:
	get_tree().reload_current_scene()
