extends Control

var API_KEY = "AIzaSyCgzX43gWy7bGNHxqTC_TAHWeobJww2Il0"
var base_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KEY

@onready var http_request = $HTTPRequest

func _on_button_pressed() -> void:
	var json_data = {
		"email": $TextureRect/VBoxContainer/username.text,
		"password": $TextureRect/VBoxContainer/password.text,
		"returnSecureToken": true
	}
	http_request.request(base_url, [], HTTPClient.METHOD_POST, JSON.stringify(json_data))

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_data = body.get_string_from_utf8()
	var json_response = JSON.parse_string(response_data)

	if (response_code == 200):
		# Autenticado com sucesso
		var user_id = json_response["localId"]
		AuthManager.save_user_session(user_id)  # <-- guarda o login
		print("Login realizado com sucesso:", user_id)
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn") # volta pro menu principal
	else:
		$TextureRect/VBoxContainer/FeedbackText.text = json_response["error"]["message"]

func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/signup.tscn")
