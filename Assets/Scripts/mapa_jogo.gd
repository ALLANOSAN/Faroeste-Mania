extends Node2D

# Variáveis do jogo
var vidas = 4
var pontos = 0
var combo = 0 # Contador de acertos consecutivos
var combo_timer = 0 # Temporizador para resetar o combo
var tempo_spawn = 1.2 # Tempo inicial de spawn em segundos (reduzido significativamente)
var max_tempo_spawn = 2.0 # Tempo máximo de spawn (reduzido significativamente)
var min_tempo_spawn = 0.6 # Tempo mínimo de spawn para não ficar impossível
var aumento_tempo = 0.05 # Quanto o tempo aumenta a cada acerto (reduzido)
var reducao_tempo = 0.1 # Quanto o tempo reduz quando perde vida (ajustado)
var combo_timeout = 1.5 # Tempo em segundos para resetar o combo
var alvo_ativo = false
var tempo_restante = 0

# Dados do usuário (obrigatório estar logado para jogar)
var user_id = ""
var user_name = ""

# Referências de nós
@onready var alvo = %CharacterBody2D
@onready var label_pontos = %LabelPontos
@onready var vidas_container = %VidasContainer
@onready var area_jogo = %AreaJogo # Área onde o alvo pode spawnar
@onready var audio_tiro = %AudioTiro
@onready var vidas_sprites = [
	%Vida1,
	%Vida2,
	%Vida3,
	%Vida4
]

# Referências para Screen Shake
@onready var camera = $Camera2D
@onready var background_layer = $BackgroundLayer
@onready var ui_layer = $CanvasLayer

# Variáveis de Screen Shake
var shake_strength: float = 0.0
var shake_decay: float = 5.0

# Cursor personalizado
const CURSOR_TEXTURE = preload("res://Assets/Art/ilustracao-em-vetor-revolver-vintage-remixada-da-arte-de-elizabeth-johnson1.png")

func _ready():
	# Configuração inicial
	randomize()
	atualizar_ui()
	
	# Define o cursor personalizado (mira/arma)
	# O hotspot (ponto de clique) está definido no centro da imagem (ajuste conforme necessário)
	# Se a imagem for muito grande, o cursor ficará grande. O ideal é uma imagem de 32x32 ou 64x64.
	Input.set_custom_mouse_cursor(CURSOR_TEXTURE)
	
	# Inicia música do mapa
	AudioManager.play_music_map()
	
	# Verifica se o usuário está logado (sem validar token imediatamente)
	await check_user_login()
	
	# Configurar o alvo para aceitar entrada
	alvo.input_pickable = true
	
	# Conecta o sinal de input_event do alvo se não estiver conectado
	if !alvo.input_event.is_connected(_on_alvo_input_event):
		alvo.input_event.connect(_on_alvo_input_event)
		print("Sinal input_event conectado ao alvo")
	
	# Inicia o primeiro spawn diretamente
	spawn_alvo()
	
	# Debug
	print("MapaJogo inicializado, pronto para jogar!")

func _exit_tree():
	# Para a música quando sair da cena (Game Over, Menu, etc)
	AudioManager.stop_music_map()
	
	# Reseta o cursor para o padrão do sistema
	Input.set_custom_mouse_cursor(null)

# Obtém os dados do usuário logado
func check_user_login() -> void:
	print("🔍 Verificando autenticação do jogador...")
	
	# Verifica se o usuário está autenticado NA SESSÃO ATUAL
	# NÃO usar load_auth() porque pode criar sessão anônima se o token expirou
	if Firebase.Auth.auth == null or Firebase.Auth.auth.is_empty():
		print("❌ Usuário não está autenticado na sessão atual!")
		print("🚪 Voltando para o menu de login...")
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
		return
	
	# Verifica se tem idtoken válido
	if not Firebase.Auth.auth.has("idtoken"):
		print("❌ Token de autenticação ausente ou inválido!")
		print("🚪 Voltando para o menu de login...")
		Firebase.Auth.logout()
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
		return
	
	# Pega o user_id diretamente do auth
	if Firebase.Auth.auth.has("localid"):
		user_id = Firebase.Auth.auth.get("localid")
	elif Firebase.Auth.auth.has("uid"):
		user_id = Firebase.Auth.auth.get("uid")
	else:
		print("❌ UID não encontrado no auth!")
		Firebase.Auth.logout()
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
		return
	
	print("✅ Usuário autenticado na sessão!")
	print("   User ID: " + user_id)
	
	# Busca o nome do usuário no Firestore
	await get_user_name()

# Busca o nome do usuário no Firestore
func get_user_name() -> void:
	if user_id.is_empty():
		print("   ⚠️ ID de usuário vazio, não é possível buscar nome")
		return
	
	print("   🔍 Buscando nome do usuário no Firestore...")
	print("   📋 User ID válido: " + user_id)
	
	# Conecta ao erro do Firestore para debug
	var user_collection: FirestoreCollection = Firebase.Firestore.collection("users")
	
	# Conecta sinal de erro para debug
	if not user_collection.error.is_connected(_on_firestore_error):
		user_collection.error.connect(_on_firestore_error)
	
	# Busca o documento do usuário
	var document: FirestoreDocument = await user_collection.get_doc(user_id)
	
	# Verifica se o documento foi recuperado com sucesso
	if document != null and document.doc_name == user_id:
		# Usa get_value para pegar o campo, conforme documentação
		if document.keys().has("display_name"):
			user_name = document.get_value("display_name")
			print("   ✅ Nome do usuário: " + user_name)
		else:
			user_name = "Jogador " + user_id.substr(0, 5)
			print("   ℹ️ Nome padrão: " + user_name)
	else:
		user_name = "Jogador"
		print("   ❌ Documento não encontrado ou erro ao buscar")

# Callback de erro do Firestore
func _on_firestore_error(error):
	print("   ❌ Erro do Firestore: " + str(error))

func _process(delta):
	# Lógica de Screen Shake
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		var offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		# Aplica o shake na câmera (afeta o mundo/alvo)
		if camera:
			camera.offset = offset
		
		# Aplica o shake nos CanvasLayers (afeta UI e Fundo)
		if background_layer:
			background_layer.offset = offset
		if ui_layer:
			ui_layer.offset = offset
	
	if alvo_ativo:
		# Atualiza o tempo restante
		tempo_restante -= delta
		if tempo_restante <= 0:
			# Tempo acabou, jogador perdeu uma vida
			perder_vida()
			
	# Gerencia o temporizador de combo
	if combo > 0:
		combo_timer += delta
		if combo_timer >= combo_timeout:
			# Resetar o combo se passou muito tempo
			combo = 0
			combo_timer = 0

func atualizar_ui():
	# Atualiza a pontuação na tela
	label_pontos.text = str(pontos)
	
	# Atualiza os sprites de coração conforme o número de vidas
	for i in range(vidas_sprites.size()):
		if i < vidas:
			vidas_sprites[i].visible = true
		else:
			vidas_sprites[i].visible = false
			
	# Nota: Poderíamos adicionar uma exibição visual do combo aqui no futuro
	# Por exemplo: label_combo.text = "Combo: " + str(combo) se tiver um label_combo

func spawn_alvo():
	# Define uma posição aleatória dentro da área de jogo
	var area_rect = area_jogo.get_global_rect()
	var pos_x = randf_range(area_rect.position.x + 100, area_rect.end.x - 100)
	var pos_y = randf_range(area_rect.position.y + 100, area_rect.end.y - 100)
	
	# Posiciona o alvo
	alvo.global_position = Vector2(pos_x, pos_y)
	alvo.show()
	alvo_ativo = true
	
	# Configura o tempo para este spawn
	tempo_restante = tempo_spawn

func _on_alvo_input_event(_viewport, event, _shape_idx):
	# Usa o sistema Platform para verificar se é um clique válido para a plataforma atual
	if alvo_ativo and Platform.is_valid_click(event):
		# Chama a função de acertar alvo
		acertar_alvo()

# Método alternativo para detecção de toques e cliques
# Usa o sistema Platform para otimizar por tipo de dispositivo
func _input(event):
	if alvo_ativo:
		var input_position = Vector2.ZERO
		var is_valid_input = false
		
		# Verificação otimizada baseada na plataforma atual
		if Platform.is_mobile:
			# Em dispositivos móveis, processa apenas eventos de toque
			if event is InputEventScreenTouch and event.pressed:
				input_position = event.position
				is_valid_input = true
		else:
			# Em desktop, processa apenas eventos de mouse
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				input_position = event.position
				is_valid_input = true
		
		# Se for um input válido (toque ou clique)
		if is_valid_input:
			# Verifica se o input está dentro do alvo
			if alvo.visible and alvo.get_node("CollisionShape2D").shape.get_rect().has_point(alvo.to_local(input_position)):
				print("Input detectado diretamente na área do alvo")
				acertar_alvo()
				# Consuma o evento para evitar dupla detecção
				get_viewport().set_input_as_handled()

# Função comum para quando o jogador acerta o alvo
func acertar_alvo():
	# Incrementa o combo e reseta o timer
	combo += 1
	combo_timer = 0
	
	# Calcula os pontos baseados no combo (mais combo = mais pontos)
	var pontos_ganhos = 1
	if combo >= 3:
		pontos_ganhos = 2
	if combo >= 5:
		pontos_ganhos = 3
		
	pontos += pontos_ganhos
	alvo_ativo = false
	alvo.hide()
	
	# Toca o som de tiro (não esperamos ele terminar)
	audio_tiro.play()
	
	# Ajusta o tempo de spawn com base no combo
	# Com combo alto, quase não aumenta o tempo (jogo fica mais rápido)
	var ajuste_tempo = aumento_tempo / max(1, combo * 0.5)
	tempo_spawn = min(max_tempo_spawn, tempo_spawn + ajuste_tempo)
	
	# Ajusta a dificuldade com base na pontuação atual
	ajustar_dificuldade()
	
	# Prepara para o próximo spawn imediatamente
	spawn_alvo()
	atualizar_ui()
	
	print("Ponto marcado! Pontuação: %d, Combo: %d, Pontos ganhos: %d - Tempo: %.2f" %
		[pontos, combo, pontos_ganhos, tempo_spawn])

# Função para ajustar a dificuldade com base na pontuação
func ajustar_dificuldade():
	# A cada 5 pontos (era 10), reduz o tempo de spawn para aumentar a dificuldade
	if pontos > 0 and pontos % 5 == 0:
		# Reduz o tempo máximo permitido
		max_tempo_spawn = max(min_tempo_spawn + 0.3, max_tempo_spawn - 0.1)
		# Reduz o tempo atual um pouco mais agressivamente
		tempo_spawn = max(min_tempo_spawn, tempo_spawn - 0.15)
		print("Dificuldade aumentada! Novo tempo máximo: %.2f" % max_tempo_spawn)

# Função para iniciar o screen shake
func start_shake(intensity: float = 15.0):
	shake_strength = intensity

func perder_vida():
	# Inicia o efeito de tremer a tela
	start_shake(30.0)
	
	vidas -= 1
	alvo_ativo = false
	alvo.hide()
	
	# Reseta o combo quando perde vida
	combo = 0
	combo_timer = 0
	
	# Reduz o tempo de spawn quando perde vida, tornando o jogo mais desafiador
	# Redução mais agressiva quando não clica a tempo
	tempo_spawn = max(min_tempo_spawn, tempo_spawn - reducao_tempo * 1.5)
	
	if vidas <= 0:
		# Game over
		game_over()
	else:
		# Próximo spawn imediato
		spawn_alvo()
		atualizar_ui()
		
		print("Vida perdida! Vidas restantes: %d - Tempo de spawn: %.2f" % [vidas, tempo_spawn])

func game_over():
	print("Game Over! Pontuação final: ", pontos)
	
	# Armazena os dados do jogo para a tela de Game Over
	GameData.set_game_over_data(pontos, user_id, user_name)
	
	# Salva a pontuação no Firestore (usuário já está logado, obrigatório para jogar)
	if not user_id.is_empty():
		print("⏳ Aguardando salvamento da pontuação...")
		await save_score()
		print("✅ Salvamento concluído!")
	
	# Vai para a tela de Game Over
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

# Salva a pontuação do jogador no Firestore
func save_score():
	print("💾 Salvando pontuação: " + str(pontos))
	
	var user_collection = Firebase.Firestore.collection("users")
	
	# Usa await conforme a documentação
	var doc = await user_collection.get_doc(user_id)
	
	if doc:
		# get_value retorna null se o campo não existe
		var current_score_value = doc.get_value("score")
		var current_score = 0 if current_score_value == null else int(current_score_value)
		
		print("   📊 Pontuação atual no Firestore: " + str(current_score))
		print("   🎯 Nova pontuação: " + str(pontos))
		
		if pontos > current_score:
			# Adiciona ou atualiza os campos no documento
			doc.add_or_update_field("score", pontos)
			doc.add_or_update_field("updated_at", Time.get_unix_time_from_system())
			
			# Atualiza o documento usando o método correto da coleção
			var updated_doc = await user_collection.update(doc)
			
			if updated_doc:
				print("✅ Nova pontuação recorde salva: " + str(pontos))
			else:
				print("❌ Erro ao atualizar pontuação")
		else:
			print("ℹ️ Pontuação atual (" + str(current_score) + ") é maior ou igual. Não atualizado.")
	else:
		print("⚠️ Documento do usuário não encontrado")
