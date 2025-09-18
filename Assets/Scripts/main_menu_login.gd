extends Control

@onready var login_button = %"MenuPrincipal#BTLogin"
@onready var options_menu_button = %"MenuPrincipal#BTOpcoes"
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var game_title = %"MenuPrincipal#GameTitle"
@onready var background = %"MenuPrincipal#Fundo"
@onready var global = get_node("/root/Global")
@onready var user_info_label = %UserInfoLabel if has_node("%UserInfoLabel") else null

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
	global.auth_state_changed.connect(_on_auth_state_changed)
	
	# Configura a interface com base no estado de autenticação
	_update_ui_based_on_auth()
	
	# Conectar botões somente se não forem nulos
	if login_button != null:
		login_button.pressed.connect(_on_login_button_pressed)
	if options_menu_button != null:
		options_menu_button.pressed.connect(_on_options_menu_button_pressed)

# Atualiza a UI com base no estado de autenticação
func _update_ui_based_on_auth():
	if global.is_user_logged_in():
		print("Usuário logado! ID: " + global.get_current_user_id())
		
		# USUÁRIO LOGADO: Esconde elementos de autenticação e mostra apenas jogo
		if login_button != null:
			login_button.hide() # Esconde completamente o botão de login
		
		# Mostra elementos do jogo
		if options_menu_button != null:
			options_menu_button.show() # Mostra botão de opções
		if blinking_text != null:
			blinking_text.show() # Mostra texto piscando
		if animation_player != null:
			animation_player.play("TextoAnimado") # Inicia animação
		
		# Mostra informações do usuário
		if user_info_label != null:
			user_info_label.text = "Jogador: " + global.get_current_user_id()
			user_info_label.show()
		
		# Adiciona detecção de toque na tela quando logado
		if background != null and not background.gui_input.is_connected(_on_background_gui_input):
			background.gui_input.connect(_on_background_gui_input)
	else:
		print("Usuário não logado!")
		
		# USUÁRIO NÃO LOGADO: Mostra elementos de autenticação e esconde jogo
		if login_button != null:
			login_button.text = "Clique para fazer login"
			login_button.show() # Mostra botão de login
		
		# Esconde elementos do jogo
		if options_menu_button != null:
			options_menu_button.hide() # Esconde botão de opções
		if blinking_text != null:
			blinking_text.hide() # Esconde texto piscando
		if animation_player != null:
			animation_player.stop() # Para animação
		if user_info_label != null:
			user_info_label.hide() # Esconde informações do usuário
		
		# Desconecta detecção de toque se existir
		if background != null and background.gui_input.is_connected(_on_background_gui_input):
			background.gui_input.disconnect(_on_background_gui_input)

# Callback quando o estado de autenticação muda
func _on_auth_state_changed(_is_logged_in):
	_update_ui_based_on_auth()

# Botão de login → vai para nossa própria tela de login
func _on_login_button_pressed():
	# Sempre vai para a tela de login, pois o botão só aparece se não estiver logado
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

# Botão de opções → vai para o menu de opções
func _on_options_menu_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
	
# Função para lidar com cliques na tela quando logado
# Utiliza o sistema Platform para detectar cliques de forma otimizada por plataforma
func _on_background_gui_input(event):
	if global.is_user_logged_in():
		# Usa o sistema Platform para verificar se é um clique válido para a plataforma atual
		if global.Platform.is_valid_click(event):
			get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
			print("Indo para o mapa do jogo...")
