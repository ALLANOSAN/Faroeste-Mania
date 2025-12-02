extends CanvasLayer

@onready var btn_sim = $Panel/HBoxContainer/BtnSim
@onready var btn_nao = $Panel/HBoxContainer/BtnNao

func _ready():
	btn_sim.pressed.connect(_on_sim_pressed)
	btn_nao.pressed.connect(_on_nao_pressed)
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key by default
		if visible:
			hide_dialog()
		else:
			show_dialog()

func show_dialog():
	show()
	get_tree().paused = true

func hide_dialog():
	hide()
	get_tree().paused = false

func _on_sim_pressed():
	get_tree().quit()

func _on_nao_pressed():
	hide_dialog()
