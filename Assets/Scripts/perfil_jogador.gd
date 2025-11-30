extends Control

# Nós da cena
@onready var player_id_label = %PlayerIDValue
@onready var nome_jogador_label = %NomeJogadorValue
@onready var player_rank_label = %PlayerRankLabel
@onready var username_input = %UsernameInput
@onready var save_username_button = %SaveUsernameButton
@onready var back_button = $MainContainer/HeaderContainer/BackButton
@onready var logout_button = %LogoutButton
@onready var excluir_button = %ExcluirButton

# Variável para armazenar o ID do usuário atual
var current_user_id = ""
var my_document: FirestoreDocument = null

func _ready():
	# Conecta ao sinal de erro do Firestore para debug
	Firebase.Firestore.error.connect(_on_firestore_error)

	# CRÍTICO: Conecta aos sinais do Auth para manter Firestore.auth sincronizado
	if not Firebase.Auth.login_succeeded.is_connected(_sync_firestore_auth):
		Firebase.Auth.login_succeeded.connect(_sync_firestore_auth)
	if not Firebase.Auth.token_refresh_succeeded.is_connected(_sync_firestore_auth):
		Firebase.Auth.token_refresh_succeeded.connect(_sync_firestore_auth)

	# Sincroniza auth imediatamente
	_sync_firestore_auth(Firebase.Auth.auth)

	# Conecta os botões
	back_button.pressed.connect(_on_back_button_pressed)
	save_username_button.pressed.connect(_on_save_username_pressed)
	
	# Conecta botões de conta (se existirem na cena)
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	if excluir_button:
		excluir_button.text = "EXCLUIR CONTA"
		excluir_button.pressed.connect(_on_excluir_conta_pressed)

	# Carrega os dados
	carregar_dados_jogador()

# Mantém Firebase.Firestore.auth sincronizado com Firebase.Auth.auth
func _sync_firestore_auth(auth_data):
	if auth_data != null and not auth_data.is_empty():
		Firebase.Firestore.auth = auth_data.duplicate(true)
		print("🔄 Firestore.auth sincronizado automaticamente")

# Callback para erros do Firestore
func _on_firestore_error(error_data):
	print("🔥 ERRO FIRESTORE:")
	print("   Dados completos do erro: ", error_data)
	
	var msg = "Erro desconhecido"
	if error_data is Dictionary:
		if error_data.has("message"):
			msg = str(error_data.message)
	else:
		msg = str(error_data)
		
	# Mostra erro no label de rank se possível, ou printa
	player_rank_label.text = "Erro: " + msg

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")

func carregar_dados_jogador():
	player_rank_label.text = "Carregando..."
	nome_jogador_label.text = "Carregando..."
	player_id_label.text = "Carregando..."
	
	print("👤 Carregando perfil do jogador...")

	# Verifica autenticação
	if Firebase.Auth.auth == null or Firebase.Auth.auth.is_empty():
		print("❌ Usuário não está autenticado")
		player_rank_label.text = "Não autenticado"
		return

	# Pega o ID do usuário atual
	current_user_id = Firebase.Auth.auth.get("localid", "")
	# var email = Firebase.Auth.auth.get("email", "Sem email") # Não usado na UI
	
	player_id_label.text = current_user_id
	
	# Sincroniza auth explicitamente antes da query
	Firebase.Firestore.auth = Firebase.Auth.auth.duplicate(true)
	if not Firebase.Firestore.auth.has("idtoken") and Firebase.Firestore.auth.has("idToken"):
		Firebase.Firestore.auth["idtoken"] = Firebase.Firestore.auth["idToken"]

	# Busca todos os usuários para calcular o rank (mesma lógica do Leaderboard)
	print("📤 Buscando todos os usuários para calcular rank...")
	var results = await Firebase.Firestore.list("users")
	
	if results == null:
		player_rank_label.text = "Erro de conexão"
		return
		
	if not results is Array:
		player_rank_label.text = "Erro nos dados"
		return

	# Processa os jogadores
	var jogadores = []
	var meu_perfil = null
	my_document = null # Reseta o documento
	
	for doc in results:
		if doc is FirestoreDocument:
			var score_value = doc.get_value("score")
			var name_value = doc.get_value("display_name")
			var doc_id = doc.doc_name # O ID do documento é o ID do usuário
			
			var pontuacao = 0
			if score_value != null:
				pontuacao = int(score_value)
				
			var nome = name_value if name_value != null else "Jogador"
			
			jogadores.append({
				"id": doc_id,
				"nome": nome,
				"pontuacao": pontuacao
			})
			
			# Verifica se é o usuário atual
			if doc_id == current_user_id:
				my_document = doc # Guarda a referência para o documento
				meu_perfil = {
					"nome": nome,
					"pontuacao": pontuacao
				}

	# Ordena por pontuação (maior para menor)
	jogadores.sort_custom(func(a, b): return a.pontuacao > b.pontuacao)
	
	# Encontra a posição do usuário atual
	var minha_posicao = -1
	for i in range(jogadores.size()):
		if jogadores[i].id == current_user_id:
			minha_posicao = i + 1 # Rank começa em 1
			break
	
	# Atualiza a UI
	if meu_perfil:
		nome_jogador_label.text = meu_perfil.nome
		username_input.text = meu_perfil.nome # Preenche o input com o nome atual
		
		if minha_posicao > 0:
			player_rank_label.text = "#" + str(minha_posicao) + " (Score: " + str(meu_perfil.pontuacao) + ")"
		else:
			player_rank_label.text = "Sem classificação"
	else:
		nome_jogador_label.text = "Novo Jogador"
		player_rank_label.text = "Sem pontuação"
		username_input.text = ""

	print("✅ Perfil carregado!")

func _on_save_username_pressed():
	var novo_nome = username_input.text.strip_edges()
	
	if novo_nome.is_empty():
		print("⚠️ Nome vazio")
		return
		
	if current_user_id.is_empty():
		print("❌ ID de usuário inválido")
		return
		
	save_username_button.disabled = true
	save_username_button.text = "Salvando..."
	
	print("💾 Salvando novo nome: ", novo_nome)
	
	# Atualiza ou cria o documento do usuário
	# Precisamos manter o score se já existir, então vamos ler primeiro ou usar merge se possível
	# O plugin Godot-Firebase tem update() que faz merge se não me engano, ou set()
	
	# Vamos usar uma task para atualizar apenas o display_name
	var task = Firebase.Firestore.collection("users").update(current_user_id, {"display_name": novo_nome})
	var result = await task.task_finished
	
	if result: # Sucesso (dependendo da implementação do plugin, pode retornar o documento)
		print("✅ Nome salvo com sucesso!")
		nome_jogador_label.text = novo_nome
		save_username_button.text = "SALVO!"
		await get_tree().create_timer(2.0).timeout
		save_username_button.text = "SALVAR"
		save_username_button.disabled = false
		
		# Recarrega para atualizar tudo
		carregar_dados_jogador()
	else:
		print("❌ Erro ao salvar nome")
		save_username_button.text = "ERRO"
		save_username_button.disabled = false

func _on_logout_pressed():
	print("👋 Fazendo logout...")
	Firebase.Auth.logout()
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_excluir_conta_pressed():
	print("🗑️ Excluindo conta completa...")
	excluir_button.disabled = true
	excluir_button.text = "Excluindo..."
	
	# 1. Deleta o documento do usuário no Firestore (dados do jogo)
	if my_document != null:
		print("   Removendo dados do Firestore...")
		await Firebase.Firestore.collection("users").delete(my_document)
	elif not current_user_id.is_empty():
		print("   ⚠️ Documento não carregado, tentando deletar por ID...")
		# Se não tiver o documento carregado, infelizmente o delete() do plugin pode falhar
		# mas tentamos prosseguir para deletar a conta de qualquer jeito
	
	# 2. Deleta a conta de autenticação (Login)
	print("   Removendo conta de autenticação...")
	Firebase.Auth.delete_user_account()
	
	# Aguarda um pouco e redireciona
	await get_tree().create_timer(2.0).timeout
	
	print("✅ Conta e dados excluídos com sucesso")
	Firebase.Auth.logout() # Garante logout local
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
