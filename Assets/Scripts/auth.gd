extends Control


func _ready():
	print("Auth script inicializado")
	Firebase.Auth.login.on_login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup.on_signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login.on_login_failed.connect(on_login_failed)
	Firebase.Auth.signup.on_signup_failed.connect(on_signup_failed)

	if Firebase.Auth.check_auth_file():
		%FeedbackText.text = "Logado"
		# Atualiza o estado global de autenticação
		var global = get_node("/root/Global")
		global.auth_state_changed.emit(true)
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func process(delta):
	pass


func _on_login_button_pressed():
	var email = %display_name.text
	var password = %password.text
	Firebase.Auth.login_with_email_and_password(email, password)


func _on_sign_up_button_pressed():
	var email = %display_name.text
	var password = %password.text
	Firebase.Auth.signup_with_email_and_password(email, password)

func on_login_succeeded(auth):
	print(auth)
	%FeedbackText.text = "login sucesso!"
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	# Atualiza o estado global de autenticação
	var global = get_node("/root/Global")
	global.auth_state_changed.emit(true)
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func on_signup_succeeded(auth):
	print(auth)
	%FeedbackText2.text = "Cadastro Feito com sucesso!"
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	
	# Salva os dados do usuário no Firestore
	if auth.has("localid") and is_instance_valid(%display_name):
		var user_id = auth.localid
		var display_name = %display_name.text
		
		# Cria um documento no Firestore com os dados do usuário
		var user_data = {
			"display_name": display_name,
			"score": 0,
			"created_at": Time.get_unix_time_from_system(),
			"updated_at": Time.get_unix_time_from_system()
		}
		
		# Adiciona o documento ao Firestore
		Firebase.Firestore.add("users", user_id, user_data).then(func(_result):
			print("Dados do usuário salvos no Firestore")
		).catch(func(error):
			print("Erro ao salvar dados do usuário: " + str(error))
		)
	
	# Atualiza o estado global de autenticação
	var global = get_node("/root/Global")
	global.auth_state_changed.emit(true)
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText.text = "Falha ao fazer login: Error %s" % message

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText2.text = "Falha ao fazer o cadastro: Error %s" % message

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
	
	# Retorna para a tela de menu principal
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")