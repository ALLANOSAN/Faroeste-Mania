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
var invencivel = false # Proteção contra perda de múltiplas vidas em sequência

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

# Cursor personalizado (mira)
const CURSOR_TEXTURE = preload("res://Assets/Art/set_of_cross_hairs2-removebg-preview.png")

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
	# Previne múltiplas perdas de vida em sequência
	if invencivel:
		return
	
	# Ativa invencibilidade temporária
	invencivel = true
	
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
	
	atualizar_ui()
	
	if vidas <= 0:
		# Game over
		game_over()
	else:
		# Aguarda um pequeno intervalo antes de spawnar o próximo alvo
		# Isso dá tempo ao jogador de se preparar
		await get_tree().create_timer(0.8).timeout
		invencivel = false
		spawn_alvo()
		
		print("Vida perdida! Vidas restantes: %d - Tempo de spawn: %.2f" % [vidas, tempo_spawn])

func game_over():
	print("Game Over! Pontuação final: ", pontos)
	
	# Armazena a pontuação para a tela de Game Over
	GameData.set_pontuacao(pontos)
	
	# Vai para a tela de Game Over
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")
