extends Control

@onready var login_button = %"MenuPrincipal#BTLogin"
@onready var options_menu_button = %"MenuPrincipal#BTOpcoes"
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var game_title = %"MenuPrincipal#GameTitle"
@onready var background = %"MenuPrincipal#Fundo"
@onready var auth_manager = get_node("/root/AuthManager")
@onready var user_info_label = %UserInfoLabel if has_node("UserInfoLabel") else null

func _ready():
	# Verificar se os nós estão disponíveis e imprimir mensagens de debug
	print("Verificando nós da interface...")
	
	# Verifica se todos os nós estão corretamente definidos
	for node_name in ["login_button", "options_menu_button", "blinking_text",
					 "animation_player", "game_title", "background"]:
		if get(node_name) == null:
			print("ERRO: " + node_name + " não encontrado")
		else:
			print(node_name + " encontrado")
	
	# Conecta ao sinal de mudança de estado de autenticação
	auth_manager.auth_state_changed.connect(_on_auth_state_changed)
	
	# Configura a interface com base no estado de autenticação
	_update_ui_based_on_auth()
	
	# Conectar botões somente se não forem nulos
	if login_button != null:
		login_button.pressed.connect(_on_login_button_pressed)
	if options_menu_button != null:
		options_menu_button.pressed.connect(_on_options_menu_button_pressed)

# Atualiza a UI com base no estado de autenticação
func _update_ui_based_on_auth():
	if auth_manager.is_logged_in():
		print("Usuário logado! ID: " + auth_manager.get_current_user_id())
		
		# Mostra opções e texto piscando
		if login_button != null:
			login_button.text = "Sair" # Mudamos o texto do botão para "Sair"
			login_button.show()
		if options_menu_button != null:
			options_menu_button.show()
		if blinking_text != null:
			blinking_text.show()
		if animation_player != null:
			animation_player.play("TextoAnimado")
		
		# Mostra informações do usuário
		if user_info_label != null:
			user_info_label.text = "Jogador: " + auth_manager.get_current_user_id()
			user_info_label.show()
		
		# Adiciona detecção de toque na tela quando logado
		if background != null and not background.gui_input.is_connected(_on_background_gui_input):
			background.gui_input.connect(_on_background_gui_input)
	else:
		print("Usuário não logado!")
		
		# Mostra apenas botão de login
		if login_button != null:
			login_button.text = "Login" # Restauramos o texto original
			login_button.show()
		if options_menu_button != null:
			options_menu_button.hide()
		if blinking_text != null:
			blinking_text.hide()
		if animation_player != null:
			animation_player.stop()
		if user_info_label != null:
			user_info_label.hide()
		
		# Desconecta detecção de toque se existir
		if background != null and background.gui_input.is_connected(_on_background_gui_input):
			background.gui_input.disconnect(_on_background_gui_input)

# Callback quando o estado de autenticação muda
func _on_auth_state_changed(_is_logged_in):
	_update_ui_based_on_auth()

# Botão de login → vai para a cena login.tscn OU faz logout
func _on_login_button_pressed():
	if auth_manager.is_logged_in():
		# Se já está logado, faz logout
		auth_manager.clear_session()
		_update_ui_based_on_auth()
	else:
		# Se não está logado, vai para tela de login
		get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

# Botão de opções → vai para o menu de opções
func _on_options_menu_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
	
# Função para lidar com cliques na tela quando logado
func _on_background_gui_input(event):
	if auth_manager.is_logged_in() and event is InputEventScreenTouch and event.pressed:
		get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
		print("Indo para o mapa do jogo...")
