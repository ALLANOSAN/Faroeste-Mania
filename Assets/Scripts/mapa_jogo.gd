extends Node2D

# Variáveis do jogo
var vidas = 4
var pontos = 0
var tempo_spawn = 3.0 # Tempo inicial de spawn em segundos
var max_tempo_spawn = 6.0 # Tempo máximo de spawn
var aumento_tempo = 0.1 # Quanto o tempo aumenta a cada acerto ou falha
var alvo_ativo = false
var tempo_restante = 0

# Referência ao AuthManager
@onready var auth_manager = get_node("/root/AuthManager")

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

func _ready():
	# Configuração inicial
	randomize()
	atualizar_ui()
	
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

func _process(delta):
	if alvo_ativo:
		# Atualiza o tempo restante
		tempo_restante -= delta
		if tempo_restante <= 0:
			# Tempo acabou, jogador perdeu uma vida
			perder_vida()

func atualizar_ui():
	# Atualiza a pontuação na tela
	label_pontos.text = str(pontos)
	
	# Atualiza os sprites de coração conforme o número de vidas
	for i in range(vidas_sprites.size()):
		if i < vidas:
			vidas_sprites[i].visible = true
		else:
			vidas_sprites[i].visible = false

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
	if alvo_ativo and event is InputEventScreenTouch and event.pressed:
		# Chama a função de acertar alvo
		acertar_alvo()

# Método alternativo para detecção de toques
func _input(event):
	if alvo_ativo and event is InputEventScreenTouch and event.pressed:
		# Converte a posição do toque para coordenadas globais
		var touch_position = event.position
		
		# Verifica se o toque está dentro do alvo
		if alvo.visible and alvo.get_node("CollisionShape2D").shape.get_rect().has_point(alvo.to_local(touch_position)):
			print("Toque detectado diretamente na área do alvo")
			acertar_alvo()
			# Consuma o evento para evitar dupla detecção
			get_viewport().set_input_as_handled()

# Função comum para quando o jogador acerta o alvo
func acertar_alvo():
	pontos += 1
	alvo_ativo = false
	alvo.hide()
	
	# Toca o som de tiro (não esperamos ele terminar)
	audio_tiro.play()
	
	# Aumenta o tempo de spawn (torna o jogo mais lento a cada acerto)
	tempo_spawn = min(max_tempo_spawn, tempo_spawn + aumento_tempo)
	
	# Prepara para o próximo spawn imediatamente
	spawn_alvo()
	atualizar_ui()
	
	print("Ponto marcado! Pontuação atual: %d - Tempo de spawn: %.2f" % [pontos, tempo_spawn])

func perder_vida():
	vidas -= 1
	alvo_ativo = false
	alvo.hide()
	
	# Aumenta o tempo de spawn também quando perde vida
	tempo_spawn = min(max_tempo_spawn, tempo_spawn + aumento_tempo)
	
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
	
	# Salvar a pontuação para mostrar na tela de game over
	var jogo_data = {
		"pontuacao": pontos
	}
	
	# Salva temporariamente os dados do jogo (para uso local)
	var save_game = FileAccess.open("user://temp_game_data.save", FileAccess.WRITE)
	save_game.store_line(JSON.stringify(jogo_data))
	
	# Salva a pontuação no Firebase se o usuário estiver logado
	if auth_manager.is_logged_in():
		print("Salvando pontuação de %d diretamente do mapa_jogo.gd..." % pontos)
		salvar_pontuacao(pontos)
	else:
		print("Usuário não logado, pontuação não salva no Firebase")
	
	# Vai para a tela de game over
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

# Salva a pontuação usando o AuthManager
func salvar_pontuacao(pontuacao):
	if auth_manager.is_logged_in():
		print("Salvando pontuação de %d no Firebase..." % pontuacao)
		auth_manager.save_score(pontuacao)
	else:
		print("Usuário não está logado, não é possível salvar pontuação")
