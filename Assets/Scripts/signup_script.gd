extends Control

@onready var feedback_text = %FeedbackText2
@onready var global = get_node("/root/Global")
@onready var loot_locker = get_node("/root/LootLockerManager")

# Referências aos campos de entrada
@onready var display_name_input = %display_name
@onready var email_input = %username
@onready var password_input = %password
@onready var login_button = %login_button
@onready var back_button = %back_button

# Função para registrar um novo usuário
func _on_button_pressed() -> void:
	var display_name = display_name_input.text
	var email = email_input.text
	var password = password_input.text
	
	# Validações básicas
	if display_name.is_empty():
		feedback_text.text = "Por favor, digite seu nome de usuário"
		return
		
	if email.is_empty() or password.is_empty():
		feedback_text.text = "Por favor, preencha email e senha"
		return
		
	if password.length() < 8:
		feedback_text.text = "A senha deve ter pelo menos 8 caracteres"
		return
		
	if !email.contains("@") or !email.contains("."):
		feedback_text.text = "Digite um email válido"
		return
	
	feedback_text.text = "Registrando..."
	
	# No LootLocker agora estamos usando White Label Authentication
	global.register_user(email, password)
	
	# O display_name será salvo após o login bem-sucedido
	# Conectamos ao sinal de registro bem-sucedido para definir o nome de exibição
	# Este callback será executado quando a autenticação for concluída com sucesso
	loot_locker.register_success.connect(func(_data): # Usando underscore para indicar que não usamos o parâmetro
		# De acordo com o SDK oficial, após a autenticação, definimos o nome do jogador
		print("Definindo nome de exibição do jogador: " + display_name)
		# Esta chamada usa internamente LL_Players.SetPlayerName.new(nome).send()
		# Em Godot 4.x, podemos simplesmente usar await diretamente
		var resposta = await loot_locker.set_player_name(display_name)
		
		# Verificamos se o nome foi definido com sucesso
		# Isso é importante porque o LootLockerManager.gd verifica o sucesso da chamada
		if resposta and resposta.success:
			print("Nome do jogador definido com sucesso para: " + display_name)
		else:
			print("Erro ao definir nome do jogador")
	, CONNECT_ONE_SHOT)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
	
func _ready():
	# Conectar sinais
	loot_locker.register_success.connect(_on_register_success)
	loot_locker.register_failed.connect(_on_register_failed)
	
	# Conectar o sinal do botão de login
	login_button.pressed.connect(_on_button_pressed)
	# Conectar o sinal do botão de voltar
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()
	
func _on_register_success(_user_data): # Usando underscore para indicar que não usamos o parâmetro
	# De acordo com o SDK oficial, o callback register_success é acionado
	# após o login bem-sucedido que ocorre automaticamente após o registro
	# Mostramos uma mensagem de confirmação
	feedback_text.text = "Registro concluído com sucesso!"
	
	# Não estamos usando os dados do usuário diretamente nesta função
	# O registro e login são gerenciados automaticamente pelo LootLockerManager
	
	# Após sucesso, navegamos para a tela principal do jogo (se necessário)
	# O LootLockerManager.gd já faz a maioria dos processos automaticamente
	
func _on_register_failed(error_message):
	feedback_text.text = "Falha no registro: " + error_message
	
func _apply_platform_specific_settings():
	"""Aplica configurações específicas para a plataforma atual"""
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis na tela de registro...")
		# Aumentar tamanho dos campos e botões para facilitar uso em tela touch
		if is_instance_valid(display_name_input):
			display_name_input.custom_minimum_size.y = 60
		if is_instance_valid(email_input):
			email_input.custom_minimum_size.y = 60
		if is_instance_valid(password_input):
			password_input.custom_minimum_size.y = 60
		if is_instance_valid(login_button):
			login_button.custom_minimum_size.y = 70
		if is_instance_valid(back_button):
			back_button.custom_minimum_size.y = 70
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop na tela de registro...")
		# Manter tamanhos padrão para uso com mouse
