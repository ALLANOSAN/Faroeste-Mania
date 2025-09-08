extends Control

@onready var auth_manager = get_node("/root/AuthManager")
@onready var feedback_text = $TextureRect/VBoxContainer/FeedbackText

func _ready():
	# Conectamos ao sinal de mudança no estado de autenticação
	auth_manager.auth_state_changed.connect(_on_auth_state_changed)

func _on_button_pressed() -> void:
	var email = $TextureRect/VBoxContainer/username.text
	var password = $TextureRect/VBoxContainer/password.text
	
	# Validações básicas
	if email.is_empty() or password.is_empty():
		feedback_text.text = "Por favor, preencha email e senha"
		return
		
	if password.length() < 6:
		feedback_text.text = "A senha deve ter pelo menos 6 caracteres"
		return
		
	if !email.contains("@") or !email.contains("."):
		feedback_text.text = "Digite um email válido"
		return
	
	feedback_text.text = "Registrando..."
	auth_manager.register_with_email(email, password)

func _on_auth_state_changed(is_logged_in):
	if is_logged_in:
		print("Registro realizado com sucesso:", auth_manager.get_current_user_id())
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
	else:
		feedback_text.text = "Falha no registro. Este email pode já estar em uso."

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
