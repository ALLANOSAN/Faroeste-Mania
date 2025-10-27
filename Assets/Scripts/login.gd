extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Conecta sinais do Firebase Auth
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)


# Salva sessão de forma segura (refresh token criptografado)
func save_session(auth: Dictionary) -> void:
	var refresh_token = ""
	
	# Extrai refresh_token (pode vir com nomes diferentes)
	if auth.has("refreshtoken"):
		refresh_token = auth["refreshtoken"]
	elif auth.has("refresh_token"):
		refresh_token = auth["refresh_token"]
	elif auth.has("refreshToken"):
		refresh_token = auth["refreshToken"]
	else:
		push_error("Refresh token não encontrado!")
		return
	
	# Extrai user_id
	var user_id = ""
	if auth.has("localid"):
		user_id = auth["localid"]
	elif auth.has("localId"):
		user_id = auth["localId"]
	elif auth.has("uid"):
		user_id = auth["uid"]
	else:
		push_error("User ID não encontrado!")
		return
	
	# Cria dados da sessão
	var session_data = {
		"refresh_token": refresh_token,
		"user_id": user_id,
		"device_id": OS.get_unique_id(),
		"saved_at": Time.get_unix_time_from_system()
	}
	
	# Salva criptografado usando device ID como senha
	var file = FileAccess.open_encrypted_with_pass(
		"user://session.enc",
		FileAccess.WRITE,
		OS.get_unique_id()
	)
	
	if file == null:
		push_error("Erro ao criar arquivo de sessão: " + str(FileAccess.get_open_error()))
		return
	
	file.store_line(JSON.stringify(session_data))
	file.close()
	print("✅ Sessão salva com sucesso!")


# Limpa sessão salva (usado no logout)
func clear_session() -> void:
	if FileAccess.file_exists("user://session.enc"):
		DirAccess.remove_absolute("user://session.enc")
		print("🗑️ Sessão removida")


# Função chamada ao logar com sucesso
func on_login_succeeded(auth: Dictionary) -> void:
	print("Auth recebido:", auth)

	# Extrai UID de forma segura, tratando todos os casos
	var uid = ""
	if auth.has("localid"):
		uid = auth["localid"]
	elif auth.has("localId"):
		uid = auth["localId"]
	elif auth.has("uid"):
		uid = auth["uid"]
	else:
		push_error("UID não encontrado no auth!")
		%FeedbackText.text = "Erro: UID não encontrado!"
		return

	print("UID do usuário:", uid)
	%FeedbackText.text = "Login success!"

	# Salva sessão de forma segura
	save_session(auth)

	# Aguarda um pouco para processar
	await get_tree().create_timer(0.5).timeout

	# Conecta ao Firestore e tenta obter documento do usuário
	var users_collection: FirestoreCollection = Firebase.Firestore.collection("users")
	var user_doc: FirestoreDocument = await users_collection.get_doc(uid)
	print("Documento do usuário:", user_doc)

	if user_doc:
		print("✅ Documento do usuário encontrado:", user_doc.get_value("display_name"))
	else:
		print("⚠️ Documento do usuário não existe. Você pode criar um novo se necessário.")

	# Muda para o menu principal
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


# Função chamada quando o login falha
func on_login_failed(code, message: String) -> void:
	print("Login falhou. Código:", code, "Mensagem:", message)
	%FeedbackText.text = "Login failed. Error: %s" % message


# Botão para ir para cadastro
func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")


# Botão de login
func _on_button_pressed() -> void:
	var email = %email.text
	var password = %password.text

	# Limpa sessão anterior se existir
	clear_session()

	# Tenta logar
	Firebase.Auth.login_with_email_and_password(email, password)
	%FeedbackText.text = "Fazendo login..."
