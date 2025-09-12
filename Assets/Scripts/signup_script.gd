extends Control

@onready var auth_manager = get_node("/root/AuthManager")
@onready var feedback_text = %FeedbackText2

func _on_button_pressed() -> void:
	var display_name = %display_name.text
	var email = %username.text
	var password = %password.text
	
	# Validações básicas
	if display_name.is_empty():
		feedback_text.text = "Por favor, digite seu nome de usuário"
		return
		
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
	# Salvar o nome de usuário para ser usado depois que o registro for concluído
	auth_manager.set_current_user_name(display_name)

func _on_auth_state_changed(is_logged_in):
	if is_logged_in:
		print("Registro realizado com sucesso:", auth_manager.get_current_user_id())
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
	else:
		feedback_text.text = "Falha no registro. Este email pode já estar em uso."

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
	
func _ready():
	# Conectamos ao sinal de mudança no estado de autenticação
	auth_manager.auth_state_changed.connect(_on_auth_state_changed)
	# Conectar o sinal do botão de login
	%login_button.pressed.connect(_on_button_pressed)
	# Conectar o sinal do botão de voltar
	%back_button.pressed.connect(_on_back_button_pressed)
