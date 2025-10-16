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
	
	# Conecta os botões
	botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	
	# Carrega os scores
	carregar_scores()

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
	
	# CRÍTICO: Segundo a documentação, queries EXIGEM autenticação
	# Precisamos garantir que o usuário está autenticado no Firebase.Auth
	print("🔐 Verificando autenticação...")
	
	# Verifica se existe arquivo de autenticação
	if not FileAccess.file_exists("user://user.auth"):
		loading_label.text = "Erro: Usuário não autenticado"
		print("❌ Arquivo de autenticação não encontrado")
		return
	
	# Carrega a autenticação do arquivo
	print("⏳ Carregando autenticação do arquivo...")
	await Firebase.Auth.load_auth()
	
	# Aguarda um pouco para o Firebase processar
	await get_tree().create_timer(0.5).timeout
	
	# Verifica se a autenticação foi carregada com sucesso
	if Firebase.Auth.auth == null or Firebase.Auth.auth.is_empty():
		loading_label.text = "Erro: Falha ao carregar autenticação"
		print("❌ Firebase.Auth.auth está vazio após load_auth()")
		return
	
	print("✅ Autenticação carregada com sucesso")
	print("   User ID: ", Firebase.Auth.auth.get("localid", "N/A"))
	print("   Token válido: ", Firebase.Auth.auth.has("idtoken"))
	
	# Cria a query EXATAMENTE como na documentação
	# MAS sem order_by() porque ele requer índice no Firebase Console
	print("📤 Criando query do Firestore...")
	
	var query: FirestoreQuery = FirestoreQuery.new()
	
	# FROM a collection (obrigatório)
	query.from("users")
	
	# NÃO usamos order_by() porque precisaria criar índice no Firebase Console
	# NÃO usamos limit() para pegar todos os usuários
	# Vamos ordenar manualmente depois
	
	print("📤 Executando query: FROM users (sem filtros, sem ordenação)")
	
	# Issue the query (como na documentação)
	var results = await Firebase.Firestore.query(query)
	
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
