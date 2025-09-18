extends Control

@onready var feedback_text = %FeedbackText
@onready var global = get_node("/root/Global")
@onready var loot_locker = get_node("/root/LootLockerManager")

# Referências aos campos de entrada
@onready var email_field = %username
@onready var password_field = %password
@onready var login_button = %button
@onready var signup_button = %signup_button

func _ready():
	# Conectamos ao sinal de mudança no estado de autenticação
	loot_locker.auth_state_changed.connect(_on_auth_state_changed)
	loot_locker.login_failed.connect(_on_login_failed)
	
	# Verificamos se o usuário já está autenticado
	if global.is_user_logged_in():
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
		
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()
	
	# Conecta o botão de login se ele não estiver já conectado
	if login_button and not login_button.pressed.is_connected(_on_button_pressed):
		login_button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	var email = email_field.text
	var password = password_field.text
	
	if email.is_empty() or password.is_empty():
		feedback_text.text = "Por favor, preencha email e senha"
		return
	
	feedback_text.text = "Fazendo login..."
	global.login_user(email, password)

func _on_auth_state_changed(is_logged_in):
	# Verificar se o nó ainda está na árvore antes de tentar usar get_tree()
	if not is_inside_tree():
		print("Aviso: Nó não está mais na árvore de cena")
		return
		
	if is_logged_in:
		print("Login realizado com sucesso!")
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_login_failed(error_message):
	if feedback_text:
		feedback_text.text = "Falha no login: " + error_message
		
func _on_signup_button_pressed() -> void:
	# Vai para a tela de registro
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")

func _apply_platform_specific_settings():
	"""Aplica configurações específicas para a plataforma atual"""
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis na tela de login...")
		# Aumentar tamanho dos campos e botões para facilitar uso em tela touch
		if is_instance_valid(email_field):
			email_field.custom_minimum_size.y = 60
		if is_instance_valid(password_field):
			password_field.custom_minimum_size.y = 60
		if is_instance_valid(login_button):
			login_button.custom_minimum_size.y = 70
		if is_instance_valid(signup_button):
			signup_button.custom_minimum_size.y = 70
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop na tela de login...")
		# Manter tamanhos padrão para uso com mouse
		
	# Conecta o botão de cadastro se existir e não estiver já conectado
	if signup_button and not signup_button.pressed.is_connected(_on_signup_button_pressed):
		signup_button.pressed.connect(_on_signup_button_pressed)
