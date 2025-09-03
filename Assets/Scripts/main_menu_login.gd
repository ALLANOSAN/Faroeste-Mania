extends Control

@onready var login_button = $"Menu Principal/BTLogin"
@onready var options_menu_button = $"Menu Principal/BTOpcoes"
@onready var blinking_text = $TextoAnimado
@onready var animation_player = $TextoAnimado/AnimaçãoTexto
@onready var game_title = $"Menu Principal/GameTitle"
@onready var background = $"Menu Principal/Fundo"

func _ready():
	# Verifica se já está logado
	if AuthManager.is_logged_in():
		# Mostra opções e texto piscando
		login_button.hide()
		options_menu_button.show()
		blinking_text.show()
		animation_player.play("TextoAnimado")
		
		# Adiciona detecção de toque na tela quando logado
		background.gui_input.connect(_on_background_gui_input)
	else:
		# Mostra apenas botão de login
		options_menu_button.hide()
		blinking_text.hide()
		animation_player.stop()
		login_button.show()
		
		# Desconecta detecção de toque se existir
		if background.gui_input.is_connected(_on_background_gui_input):
			background.gui_input.disconnect(_on_background_gui_input)

	# Conectar botões
	login_button.pressed.connect(_on_login_button_pressed)
	options_menu_button.pressed.connect(_on_options_menu_button_pressed)

# Botão de login → vai para a cena login.tscn
func _on_login_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

# Botão de opções → vai para o menu de opções
func _on_options_menu_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
	
# Função para lidar com cliques na tela quando logado
func _on_background_gui_input(event):
	if AuthManager.is_logged_in() and event is InputEventScreenTouch and event.pressed:
		get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
		print("Indo para o mapa do jogo...")
