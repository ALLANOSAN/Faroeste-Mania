extends Control

@onready var feedback_text = %FeedbackText
@onready var global = get_node("/root/Global")
@onready var auth = get_node("/root/Auth")

# Referências aos campos de entrada
@onready var email_field = %email
@onready var password_field = %password
@onready var login_button = %button
@onready var signup_button = %signup_button

func _ready():
	# Conectar sinais do auth para feedback
	auth.login_failed.connect(_on_auth_login_failed)
	auth.login_succeeded.connect(_on_auth_login_succeeded)
	
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
	# PASSE O EMAIL E A SENHA PARA O SCRIPT GLOBAL
	auth.login(email, password)

func _on_auth_login_succeeded(auth_data):
	# Trata sucesso do login
	feedback_text.text = "Login realizado com sucesso!"
	print("Login succeeded with auth: ", auth_data)
	
	# Muda para a cena principal
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_auth_login_failed(error_code, message):
	if feedback_text:
		feedback_text.text = "Falha ao fazer login: Error %s (Code: %s)" % [message, error_code]
		
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
