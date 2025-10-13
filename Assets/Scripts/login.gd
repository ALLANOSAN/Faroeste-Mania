extends Control

func _ready():
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)

	if Firebase.Auth.check_auth_file():
		%FeedbackText.text = "Logged in"
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


func on_login_succeeded(auth):
	print(auth)
	%FeedbackText.text = "Login success!"
	
	# Salva autenticação (função síncrona, sem await)
	Firebase.Auth.save_auth(auth)
	print("💾 save_auth() chamado")
	
	# Aguarda tempo generoso para o sistema de arquivos gravar
	# NÃO podemos chamar check_auth_file() aqui porque causaria conflito HTTP
	print("⏳ Aguardando gravação do arquivo...")
	await get_tree().create_timer(1.5).timeout
	
	print("✅ Login concluído, mudando para o menu...")
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText.text = "Login failed. Error: %s" % message
	

func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")


func _on_button_pressed() -> void:
	var email = %email.text
	var password = %password.text
	
	# Limpa arquivo de autenticação anterior para evitar conflitos
	if Firebase.Auth.check_auth_file():
		Firebase.Auth.logout()
		
	# Tentativa de login com novos dados
	Firebase.Auth.login_with_email_and_password(email, password)
	%FeedbackText.text = "Fazendo login..."
