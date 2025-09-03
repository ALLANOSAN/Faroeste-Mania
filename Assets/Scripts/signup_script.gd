extends Control

var API_KEY = "AIzaSyCgzX43gWy7bGNHxqTC_TAHWeobJww2Il0"
var base_url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY

@onready var http_request = $HTTPRequest

func _on_button_pressed() -> void:
	var json_data = {
		"email": $VBoxContainer/username.text,
		"password": $VBoxContainer/password.text,
		"returnSecureToken": true
	}
	
	http_request.request(base_url, [], HTTPClient.METHOD_POST, JSON.stringify(json_data))


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# Primeiro, verifica o resultado da requisição em nível de rede
	if result != HTTPRequest.RESULT_SUCCESS:
		$VBoxContainer/FeedbackText.text = "Erro de conexão. Verifique sua internet."
		return

	# Em seguida, analisa a resposta do servidor
	var response_data = body.get_string_from_utf8()
	var json_response = JSON.parse_string(response_data)
	
	if (response_code == 200):
		# Se a resposta for bem-sucedida, navega para a tela de login
		get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
	else:
		# Se a autenticação falhar, verifica o código do erro
		if json_response and json_response.has("error") and json_response["error"].has("message"):
			var error_message = json_response["error"]["message"]
			match error_message:
				"EMAIL_EXISTS":
					$VBoxContainer/FeedbackText.text = "Este e-mail já está em uso."
				"WEAK_PASSWORD : Password should be at least 6 characters":
					$VBoxContainer/FeedbackText.text = "A senha deve ter pelo menos 6 caracteres."
				"INVALID_EMAIL":
					$VBoxContainer/FeedbackText.text = "O formato do e-mail é inválido."
				_:
					# Mensagem padrão para erros desconhecidos
					$VBoxContainer/FeedbackText.text = "Erro no cadastro. Tente novamente."
		else:
			$VBoxContainer/FeedbackText.text = "Erro desconhecido. Tente novamente."
	
	print("Headers da resposta:", headers)
