extends Control

@onready var auth_manager = get_node("/root/AuthManager")
@onready var feedback_text = $TextureRect/VBoxContainer/FeedbackText

func _ready():
	# Conectamos ao sinal de mudança no estado de autenticação
	auth_manager.auth_state_changed.connect(_on_auth_state_changed)
	
	# Verificamos se o usuário já está autenticado
	if auth_manager.is_logged_in():
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_button_pressed() -> void:
	var email = $TextureRect/VBoxContainer/username.text
	var password = $TextureRect/VBoxContainer/password.text
	
	if email.is_empty() or password.is_empty():
		feedback_text.text = "Por favor, preencha email e senha"
		return
		
	feedback_text.text = "Fazendo login..."
	auth_manager.login_with_email(email, password)

func _on_auth_state_changed(is_logged_in):
	if is_logged_in:
		print("Login realizado com sucesso:", auth_manager.get_current_user_id())
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
	else:
		feedback_text.text = "Falha no login, verifique suas credenciais"

func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")
