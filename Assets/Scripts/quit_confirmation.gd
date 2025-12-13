extends CanvasLayer

@onready var btn_sim = $Panel/HBoxContainer/BtnSim
@onready var btn_nao = $Panel/HBoxContainer/BtnNao

# Cursor do mapa (pré-carregado)
var cursor_mira = preload("res://Assets/Art/set_of_cross_hairs2-removebg-preview.png")

# Sinal para notificar quando o diálogo fecha
signal dialog_closed

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
	
	# Suporte a teclado quando o diálogo está visível
	if visible:
		if event.is_action_pressed("ui_accept"): # Enter
			_on_sim_pressed()
		elif event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_S, KEY_Y: # S de Sim ou Y de Yes
					_on_sim_pressed()
				KEY_N: # N de Não
					_on_nao_pressed()

func show_dialog():
	show()
	get_tree().paused = true
	# Restaura o cursor padrão para poder clicar nos botões
	Input.set_custom_mouse_cursor(null)
	# Foca no botão "Não" por segurança (evita sair acidentalmente)
	btn_nao.grab_focus()

func hide_dialog():
	hide()
	get_tree().paused = false
	# Restaura o cursor customizado se estiver no mapa do jogo
	_restaurar_cursor_mapa()
	dialog_closed.emit()

func _restaurar_cursor_mapa():
	# Verifica se a cena atual é o mapa do jogo
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "MapadoJogo" or child.get_script() != null and child.has_method("_on_alvo_input_event"):
			Input.set_custom_mouse_cursor(cursor_mira)
			print("🎯 Cursor mira restaurado")
			return
	
	# Tenta de outra forma - busca pelo nome da cena
	var current = get_tree().current_scene
	if current:
		var scene_path = current.scene_file_path
		if scene_path.contains("MapadoJogo"):
			Input.set_custom_mouse_cursor(cursor_mira)
			print("🎯 Cursor mira restaurado (via scene_path)")

func _on_sim_pressed():
	get_tree().quit()

func _on_nao_pressed():
	hide_dialog()
