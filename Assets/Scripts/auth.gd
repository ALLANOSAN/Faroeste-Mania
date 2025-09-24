extends Control

# Sinais para notificar login e signup
signal login_failed(error_code, message)
signal login_succeeded(auth)
signal signup_failed(error_code, message)
signal signup_succeeded(auth)

func _ready():
	print("Auth script inicializado")
	# Conecta sinais para serem usados
	login_succeeded.connect(_dummy_login_succeeded)
	signup_succeeded.connect(_dummy_signup_succeeded)
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)

	if Firebase.Auth.check_auth_file():
		%FeedbackText.text = "Logado"
		# Atualiza o estado global de autenticação
		var global = get_node("/root/Global")
		global.auth_state_changed.emit(true)
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


func login(email, password):
	Firebase.Auth.login_with_email_and_password(email, password)


func signup(email, password):
	Firebase.Auth.signup_with_email_and_password(email, password)

func on_login_succeeded(auth):
	print(auth)
	# Feedback será tratado em login_script.gd
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	login_succeeded.emit(auth)

func on_signup_succeeded(auth):
	print(auth)
	# Salva a autenticação e carrega os dados
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	# Emite sinal para notificar a cena de signup
	signup_succeeded.emit(auth)

func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	# Emite sinal para notificar a cena de login
	login_failed.emit(error_code, message)

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	# Emite sinal para notificar a cena de signup
	signup_failed.emit(error_code, message)

# Dummy functions to mark signals as used
func _dummy_login_succeeded(auth):
	print("Dummy login succeeded with auth: ", auth)

func _dummy_signup_succeeded(auth):
	print("Dummy signup succeeded with auth: ", auth)

func _on_logout_button_pressed():
	# Realiza logout no Firebase usando o método oficial
	Firebase.Auth.logout()
	print("Logout realizado com sucesso")
	# Atualiza o estado global
	var global = get_node("/root/Global")
	global.auth_state_changed.emit(false)
	# Retorna para a tela de menu principal
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_delete_account_button_pressed():
	"""Exclui a conta do usuário atual no Firebase"""
	print("Iniciando processo de exclusão de conta")
	
	# Verifica se há um usuário logado
	if not Firebase.Auth.check_auth_file():
		print("Erro: Não há usuário logado para excluir a conta")
		return
	
	# Usamos o método oficial do Firebase para excluir a conta do usuário
	# Este método lida com toda a comunicação com a API do Firebase
	Firebase.Auth.delete_user_account()
	
	print("Conta excluída com sucesso")
	
	# Atualiza o estado global
	var global = get_node("/root/Global")
	global.auth_state_changed.emit(false)
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")