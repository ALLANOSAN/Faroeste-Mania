extends Control

@onready var auth_manager = get_node("/root/AuthManager")
@onready var feedback_text = %FeedbackText
@onready var http_request = $HTTPRequest if has_node("HTTPRequest") else null

func _ready():
	# Conectamos ao sinal de mudança no estado de autenticação
	auth_manager.auth_state_changed.connect(_on_auth_state_changed)
	
	# Conectamos o sinal do HTTPRequest se ele existir e não estiver já conectado
	if http_request and not http_request.request_completed.is_connected(_on_http_request_request_completed):
		http_request.request_completed.connect(_on_http_request_request_completed)
	
	# Verificamos se o usuário já está autenticado
	if auth_manager.is_logged_in():
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_button_pressed() -> void:
	var email = %username.text
	var password = %password.text
	
	if email.is_empty() or password.is_empty():
		feedback_text.text = "Por favor, preencha email e senha"
		return
		
	feedback_text.text = "Fazendo login..."
	auth_manager.login_with_email(email, password)

func _on_auth_state_changed(is_logged_in):
	# Verificar se o nó ainda está na árvore antes de tentar usar get_tree()
	if not is_inside_tree():
		print("Aviso: Nó não está mais na árvore de cena")
		return
		
	if is_logged_in:
		print("Login realizado com sucesso:", auth_manager.get_current_user_id())
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
	else:
		if feedback_text:
			feedback_text.text = "Falha no login, verifique suas credenciais"

func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")

func _on_http_request_request_completed(_result, response_code, _headers, _body):
	# Aqui você pode processar a resposta do servidor se necessário
	print("Requisição HTTP completada: ", response_code)
	# Se essa requisição não precisa de processamento específico, você pode deixar esse método vazio
	# mas ele precisa existir para capturar o sinal
