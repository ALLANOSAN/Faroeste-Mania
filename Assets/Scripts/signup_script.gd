extends Control

@onready var feedback_text = %FeedbackText2
@onready var global = get_node("/root/Global")
@onready var auth = get_node("/root/Auth")

# Referências aos campos de entrada
@onready var display_name_input = %display_name
@onready var email_input = %email
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
		
	if !_is_valid_email(email):
		feedback_text.text = "Digite um email válido"
		return
		
	feedback_text.text = "Registrando..."
	
	# PASSE O EMAIL E A SENHA PARA O SCRIPT GLOBAL
	auth.signup(email, password)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

# Callback de sucesso de registro do Firebase
# CORRIGIDO: Agora vai para a tela de login
func _on_auth_signup_succeeded(auth_data):
	print("Signup succeeded with auth: ", auth_data)
	# Salva a autenticação do novo usuário
	Firebase.Auth.save_auth(auth_data)
	Firebase.Auth.load_auth()
	
	# Muda para a cena de login
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

func _on_auth_signup_failed(error_code, message):
	print("Signup failed with code: ", error_code)
	feedback_text.text = "Falha ao fazer o cadastro: Error %s (Code: %s)" % [message, error_code]

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
		if is_instance_valid(display_name_input):
			display_name_input.custom_minimum_size.y = 40
		if is_instance_valid(email_input):
			email_input.custom_minimum_size.y = 40
		if is_instance_valid(password_input):
			password_input.custom_minimum_size.y = 40
		if is_instance_valid(login_button):
			login_button.custom_minimum_size.y = 50
		if is_instance_valid(back_button):
			back_button.custom_minimum_size.y = 50

# Validar formato do email
func _is_valid_email(email: String) -> bool:
	return email.match("?*@?*.?*")