extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Conecta sinais do Firebase Auth
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)

	# Se já existe arquivo de autenticação, loga direto
	if Firebase.Auth.check_auth_file():
		%FeedbackText.text = "Logged in"
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


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

	# Salva autenticação no arquivo
	Firebase.Auth.save_auth(auth)
	print("💾 save_auth() chamado")

	# Aguarda tempo generoso para garantir gravação no arquivo
	await get_tree().create_timer(1.5).timeout

	# Conecta ao Firestore e tenta obter documento do usuário
	var users_collection : FirestoreCollection = Firebase.Firestore.collection("users")
	var user_doc : FirestoreDocument = await users_collection.get_doc(uid)
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

	# Limpa arquivo de autenticação anterior para evitar conflitos
	if Firebase.Auth.check_auth_file():
		Firebase.Auth.logout()

	# Tenta logar
	Firebase.Auth.login_with_email_and_password(email, password)
	%FeedbackText.text = "Fazendo login..."
