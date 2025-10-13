extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)

func _on_register_button_pressed() -> void:
	var email = %email.text
	var password = %password.text
	Firebase.Auth.signup_with_email_and_password(email, password)
	%FeedbackText2.text = "Conta criada com sucesso!"
	

func on_signup_succeeded(auth):
	# Imprime o objeto auth completo para debug
	print("Objeto de autenticação completo:", auth)
	
	# Verifica se auth é um Dictionary válido e extrai o uid com segurança
	var uid = ""
	if auth is Dictionary and auth.has("localid"):
		uid = auth["localid"] # Em alguns SDKs Firebase, é "localId" ou "localid"
	elif auth is Dictionary and auth.has("uid"):
		uid = auth["uid"]
	elif auth is Dictionary and auth.has("user_id"):
		uid = auth["user_id"]
	else:
		print("Aviso: objeto auth não contém uid. Conteúdo do objeto:", auth)
		# Vamos usar a ID aleatória apenas se o uid estiver vazio
		if uid.is_empty():
			uid = str(randi()) # Gera um ID aleatório como fallback
			print("Usando ID gerado:", uid)
	
	print("UID extraído:", uid)
	
	# Verificamos se o usuário está autenticado no Firebase
	print("Verificando se usuário está autenticado...")
	var user_info = await Firebase.Auth.get_user_data() # Tenta obter dados do usuário atual
	print("Informações do usuário atual:", user_info)
	
	var display_name = $%display_name.text
	print("Nome de exibição:", display_name)

	# Criando dados do usuário
	var user_data = {
		"display_name": display_name,
		"created_at": Time.get_unix_time_from_system(),
		"userId": uid # Campo obrigatório conforme regras de segurança
	}
	
	# Método correto segundo a documentação: usando add() com o ID e os dados
	print("Salvando no Firestore com ID:", uid)
	var users_collection = Firebase.Firestore.collection("users")
	
	# Tentativa 1: Usando o método add() conforme a documentação oficial
	print("Tentando adicionar documento com:", uid, user_data)
	var document = await users_collection.add(uid, user_data)
	print("Resultado da operação:", document)
	
	# Verificamos se o documento foi criado corretamente
	if document != null:
		print("Documento criado com sucesso:", document)
		$%FeedbackText2.text = "Conta criada com sucesso!"
		await get_tree().create_timer(1.5).timeout # Espera 1.5 segundos antes de mudar a cena
		get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
	else:
		# Se o primeiro método falhou, tentamos o método alternativo
		print("Erro ao adicionar documento. Tentando método alternativo...")
		
		# Método alternativo usando document() diretamente como visto em exemplos
		var doc_ref = users_collection.document(uid)
		# Adicionamos cada campo individualmente
		var update_success = false
		
		# Tentamos obter o documento primeiro
		var existing_doc = await doc_ref.get_doc(uid)
		
		if existing_doc != null:
			# Atualiza campos existentes
			for key in user_data:
				existing_doc.add_or_update_field(key, user_data[key])
			var result = await users_collection.update(existing_doc)
			update_success = result != null
		else:
			# Tenta criar novo
			existing_doc = await doc_ref.set(user_data)
			update_success = existing_doc != null
		
		if update_success:
			print("Usuário criado com método alternativo")
			$%FeedbackText2.text = "Conta criada com sucesso!"
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
		else:
			$%FeedbackText2.text = "Erro ao criar perfil. Tente novamente."

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText2.text = "Erro ao fazer o cadastro. Error: %s" % message

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
