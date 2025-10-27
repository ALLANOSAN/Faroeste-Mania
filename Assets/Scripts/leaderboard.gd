extends Control

# Nós da cena
@onready var vbox_scores = %VBoxContainer
@onready var loading_label = %LoadingLabel
@onready var botao_voltar = %BotaoVoltar
@onready var botao_reiniciar = %BotaoReiniciar

# Medalhas
var medal_gold = preload("res://Assets/Art/medalhaouro.png")
var medal_silver = preload("res://Assets/Art/medalhaprata.png")
var medal_bronze = preload("res://Assets/Art/medalhabronze.png")

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
	botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	
	# Carrega os scores
	carregar_scores()


# Mantém Firebase.Firestore.auth sincronizado com Firebase.Auth.auth
func _sync_firestore_auth(auth_data):
	if auth_data != null and not auth_data.is_empty():
		Firebase.Firestore.auth = auth_data.duplicate(true)
		print("🔄 Firestore.auth sincronizado automaticamente")

# Callback para erros do Firestore
# O sinal error() envia apenas 1 argumento: um Dictionary com os dados do erro
func _on_firestore_error(error_data):
	print("🔥 ERRO FIRESTORE:")
	print("   Dados completos do erro: ", error_data)
	
	# Tenta extrair informações do erro se for um Dictionary
	if error_data is Dictionary:
		if error_data.has("code"):
			print("   Code: ", error_data.code)
		if error_data.has("status"):
			print("   Status: ", error_data.status)
		if error_data.has("message"):
			print("   Message: ", error_data.message)
			loading_label.text = "Erro: " + str(error_data.message)
		else:
			loading_label.text = "Erro ao conectar ao Firestore"
	else:
		print("   Tipo do erro: ", typeof(error_data))
		loading_label.text = "Erro: " + str(error_data)

# Função para carregar os scores do Firestore
func carregar_scores() -> void:
	loading_label.text = "Carregando pontuações..."
	loading_label.show()
	
	# Limpa linhas anteriores (mantém apenas o cabeçalho e separador)
	limpar_linhas()
	
	print("🏆 Buscando jogadores do Firestore...")
	
	# CRÍTICO: Queries exigem autenticação VÁLIDA (token não expirado)
	print("🔐 Verificando autenticação da sessão...")
	
	# Verifica se Firebase.Auth.auth já tem dados (usuário logado na sessão)
	if Firebase.Auth.auth == null or Firebase.Auth.auth.is_empty():
		print("❌ Usuário não está autenticado na sessão atual")
		loading_label.text = "Erro: Faça login primeiro"
		return
	
	# Verifica se tem token
	if not Firebase.Auth.auth.has("idtoken"):
		print("❌ Token de autenticação ausente")
		loading_label.text = "Erro: Token inválido. Faça login novamente"
		return
	
	print("✅ Usuário autenticado na sessão")
	print("   User ID: ", Firebase.Auth.auth.get("localid", "N/A"))
	print("   Email: ", Firebase.Auth.auth.get("email", "N/A"))
	print("   Token (primeiros 50 chars): ", str(Firebase.Auth.auth.get("idtoken", "")).substr(0, 50))
	
	# CRÍTICO: Sincroniza auth do Firebase.Auth para Firebase.Firestore
	# O plugin NÃO faz isso automaticamente!
	print("🔄 Sincronizando autenticação com Firestore...")
	Firebase.Firestore.auth = Firebase.Auth.auth.duplicate(true)
	
	# DEBUG: Verifica se o Firestore recebeu o auth corretamente
	print("✅ Firebase.Firestore.auth sincronizado!")
	print("   🔍 Firestore.auth tem idtoken?", Firebase.Firestore.auth.has("idtoken"))
	print("   🔍 Firestore.auth keys:", Firebase.Firestore.auth.keys())
	
	# Garante que o idtoken existe (pode estar como "idToken" em vez de "idtoken")
	if not Firebase.Firestore.auth.has("idtoken") and Firebase.Firestore.auth.has("idToken"):
		Firebase.Firestore.auth["idtoken"] = Firebase.Firestore.auth["idToken"]
		print("   ⚠️ Corrigido: copiou idToken para idtoken")
	
	# DEBUG: Vamos verificar EXATAMENTE o que está no auth
	print("🔍 DEBUG - Conteúdo completo de Firebase.Auth.auth:")
	for key in Firebase.Auth.auth.keys():
		if key == "idtoken" or key == "refreshtoken":
			# Mostra apenas primeiros caracteres do token por segurança
			var token_str = str(Firebase.Auth.auth[key])
			print("   ", key, ": ", token_str.substr(0, 50), "... (", token_str.length(), " chars)")
		else:
			print("   ", key, ": ", Firebase.Auth.auth[key])
	
	# Cria a query EXATAMENTE como na documentação
	# MAS sem order_by() porque ele requer índice no Firebase Console
	print("📤 Criando query do Firestore...")
	
	# CORREÇÃO: Firebase.Firestore.list() em vez de collection().list()
	print("📤 Listando documentos da coleção 'users'...")
	
	# ÚLTIMO CHECK: Verifica se Firebase.Firestore.auth ainda tem idtoken antes da query
	print("🔍 ANTES DA LIST - Firebase.Firestore.auth.has('idtoken'):", Firebase.Firestore.auth.has("idtoken"))
	print("🔍 ANTES DA LIST - Firebase.Firestore.auth é vazio?:", Firebase.Firestore.auth.is_empty())
	
	# Usa Firebase.Firestore.list() diretamente passando o caminho
	var results = await Firebase.Firestore.list("users")
	
	# Debug: mostra o tipo do resultado
	print("📦 Tipo do resultado: ", typeof(results))
	
	# Verifica se obteve resultados válidos
	if results == null:
		loading_label.text = "Erro ao conectar ao Firestore"
		print("❌ Query retornou null")
		print("💡 Possíveis causas:")
		print("   - Usuário não autenticado")
		print("   - Coleção 'users' não existe")
		print("   - Erro de conexão")
		print("   - Regras de segurança do Firestore bloqueando a query")
		return
	
	# Se não for Array, mostra erro
	if not results is Array:
		loading_label.text = "Erro ao processar dados"
		print("❌ Resultado não é um Array. Tipo: ", typeof(results))
		return
	
	print("📊 Query retornou Array com ", results.size(), " documentos")
	
	# Verifica se o array está vazio
	if results.is_empty():
		loading_label.text = "Nenhuma pontuação encontrada"
		print("⚠️ Nenhum jogador com pontuação ainda")
		return
	
	# Cria um array para armazenar os jogadores com pontuação
	var jogadores = []
	
	# Processa cada documento retornado pela query
	for doc in results:
		if doc is FirestoreDocument:
			var score_value = doc.get_value("score")
			var name_value = doc.get_value("display_name")
			
			# Só adiciona se tiver pontuação maior que 0
			if score_value != null and int(score_value) > 0:
				jogadores.append({
					"nome": name_value if name_value != null else "Jogador",
					"pontuacao": int(score_value)
				})
				print("   ✅ " + str(name_value) + ": " + str(score_value))
		else:
			print("   ⚠️ Item não é FirestoreDocument: ", typeof(doc))
	
	print("🎯 Jogadores com pontuação: ", jogadores.size())
	
	# Como não usamos order_by (que precisa de índice), ordenamos manualmente
	print("🔀 Ordenando jogadores por pontuação...")
	jogadores.sort_custom(func(a, b): return a.pontuacao > b.pontuacao)
	
	# Pega apenas os top 10
	var top_10 = jogadores.slice(0, min(10, jogadores.size()))
	print("🏆 Top 10 selecionado: ", top_10.size(), " jogadores")
	
	# Esconde o loading
	loading_label.hide()
	
	if top_10.is_empty():
		loading_label.text = "Nenhuma pontuação registrada ainda"
		loading_label.show()
		return
	
	# Cria as linhas do ranking
	for i in range(top_10.size()):
		criar_linha(i, top_10[i])
	
	print("✅ Ranking carregado com sucesso!")

# Limpa as linhas do ranking (mantém cabeçalho)
func limpar_linhas() -> void:
	# Remove todos os filhos exceto os 2 primeiros (cabeçalho e separador)
	var children = vbox_scores.get_children()
	for i in range(children.size() - 1, 1, -1): # Começa do final, para no índice 2
		children[i].queue_free()

# Cria uma linha da leaderboard
func criar_linha(index: int, jogador: Dictionary) -> void:
	# Cria um HBoxContainer para a linha
	var linha = HBoxContainer.new()
	linha.custom_minimum_size = Vector2(0, 50)
	linha.add_theme_constant_override("separation", 10)
	
	# Container para posição (medalha ou número)
	var pos_container = Control.new()
	pos_container.custom_minimum_size = Vector2(60, 50)
	pos_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	# Define medalhas para os 3 primeiros ou número para o resto
	if index < 3:
		# Usa medalha
		var pos_sprite = TextureRect.new()
		pos_sprite.custom_minimum_size = Vector2(50, 50)
		pos_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		pos_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		match index:
			0: pos_sprite.texture = medal_gold
			1: pos_sprite.texture = medal_silver
			2: pos_sprite.texture = medal_bronze
		
		pos_container.add_child(pos_sprite)
	else:
		# Usa número
		var pos_label = Label.new()
		pos_label.text = str(index + 1)
		pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pos_label.add_theme_color_override("font_color", Color(1, 1, 1))
		pos_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		pos_label.add_theme_constant_override("outline_size", 3)
		pos_label.add_theme_font_size_override("font_size", 28)
		pos_label.size_flags_horizontal = Control.SIZE_FILL
		pos_label.size_flags_vertical = Control.SIZE_FILL
		pos_container.add_child(pos_label)
	
	# Label do nome
	var nome_label = Label.new()
	nome_label.text = jogador.nome
	nome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome_label.size_flags_stretch_ratio = 2.0
	nome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nome_label.add_theme_color_override("font_color", Color(1, 1, 1))
	nome_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	nome_label.add_theme_constant_override("outline_size", 3)
	nome_label.add_theme_font_size_override("font_size", 24)
	
	# Label da pontuação
	var pont_label = Label.new()
	pont_label.text = str(jogador.pontuacao)
	pont_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pont_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pont_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pont_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	pont_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	pont_label.add_theme_constant_override("outline_size", 3)
	pont_label.add_theme_font_size_override("font_size", 26)
	
	# Adiciona tudo à linha
	linha.add_child(pos_container)
	linha.add_child(nome_label)
	linha.add_child(pont_label)
	
	# Adiciona a linha ao VBox
	vbox_scores.add_child(linha)

# Botão de recarregar rankings
func _on_botao_reiniciar_pressed():
	print("🔄 Recarregando ranking...")
	carregar_scores()

# Botão de voltar
func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
