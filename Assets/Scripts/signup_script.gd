extends Control

func _ready():
	# Conecta os sinais de signup
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)


func _on_register_button_pressed() -> void:
	var email = %email.text
	var password = %password.text
	
	# Tenta criar a conta
	Firebase.Auth.signup_with_email_and_password(email, password)
	%FeedbackText2.text = "Criando conta..."


# Sinal chamado quando o cadastro é bem-sucedido
func on_signup_succeeded(auth: Dictionary) -> void:
	print("Cadastro realizado com sucesso! Auth:", auth)
	
	# Extrai o UID do usuário
	var uid = ""
	if auth.has("localid"):
		uid = auth["localid"]
	elif auth.has("uid"):
		uid = auth["uid"]
	else:
		print("⚠️ UID não encontrado no auth. Gerando aleatório.")
		uid = str(randi())
	
	print("UID do usuário:", uid)
	
	# Pega o nome de exibição que o usuário digitou
	var display_name = %display_name.text
	
	# Monta o dicionário com os dados do usuário
	var user_data : Dictionary = {
		"display_name": display_name,
		"created_at": Time.get_unix_time_from_system(),
		"userId": uid
	}
	
	# Pega referência da coleção "users"
	var users_collection : FirestoreCollection = Firebase.Firestore.collection("users")
	
	# Adiciona o documento usando UID como ID do documento
	var document : FirestoreDocument = await users_collection.add(uid, user_data)
	
	if document != null:
		print("✅ Documento criado com sucesso:", document)
		$%FeedbackText2.text = "Conta criada com sucesso!"
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
	else:
		print("❌ Erro ao criar documento no Firestore")
		$%FeedbackText2.text = "Erro ao criar perfil. Tente novamente."


# Sinal chamado quando o cadastro falha
func on_signup_failed(error_code: int, message: String) -> void:
	print("Erro ao cadastrar:", error_code, message)
	$%FeedbackText2.text = "Erro ao criar conta: %s" % message


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
