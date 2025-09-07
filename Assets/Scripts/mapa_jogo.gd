extends Node2D

# Variáveis do jogo
var vidas = 4
var pontos = 0
var tempo_spawn = 3.0 # Tempo inicial de spawn em segundos
var max_tempo_spawn = 6.0 # Tempo máximo de spawn
var aumento_tempo = 0.1 # Quanto o tempo aumenta a cada acerto ou falha
var alvo_ativo = false
var tempo_restante = 0

# Referências de nós
@onready var alvo = $CharacterBody2D
@onready var timer_spawn = $TimerSpawn
@onready var label_pontos = $CanvasLayer/PontosContainer/LabelPontos
@onready var vidas_container = $CanvasLayer/VidasContainer
@onready var area_jogo = $AreaJogo # Área onde o alvo pode spawnar
@onready var audio_tiro = $AudioTiro
@onready var vidas_sprites = [
	$CanvasLayer/VidasContainer/Vida1,
	$CanvasLayer/VidasContainer/Vida2,
	$CanvasLayer/VidasContainer/Vida3,
	$CanvasLayer/VidasContainer/Vida4
]

func _ready():
	# Configuração inicial
	randomize()
	atualizar_ui()
	
	# Conecta o sinal de input_event do alvo
	alvo.input_event.connect(_on_alvo_input_event)
	
	# Inicia o primeiro spawn
	timer_spawn.wait_time = tempo_spawn
	timer_spawn.start()

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

func _on_timer_spawn_timeout():
	spawn_alvo()

func _on_alvo_input_event(_viewport, event, _shape_idx):
	if alvo_ativo and event is InputEventScreenTouch and event.pressed:
		# Jogador tocou no alvo
		pontos += 1
		alvo_ativo = false
		alvo.hide()
		
		# Toca o som de tiro
		audio_tiro.play()
		
		# Aumenta o tempo de spawn (torna o jogo mais lento a cada acerto)
		tempo_spawn = min(max_tempo_spawn, tempo_spawn + aumento_tempo)
		timer_spawn.wait_time = tempo_spawn
		
		# Prepara para o próximo spawn
		timer_spawn.start()
		atualizar_ui()
		
		print("Ponto marcado! Pontuação atual: ", pontos, " - Tempo de spawn: ", tempo_spawn)

func perder_vida():
	vidas -= 1
	alvo_ativo = false
	alvo.hide()
	
	# Aumenta o tempo de spawn também quando perde vida
	tempo_spawn = min(max_tempo_spawn, tempo_spawn + aumento_tempo)
	timer_spawn.wait_time = tempo_spawn
	
	if vidas <= 0:
		# Game over
		game_over()
	else:
		# Próximo spawn
		timer_spawn.start()
		atualizar_ui()
		
		print("Vida perdida! Vidas restantes: ", vidas, " - Tempo de spawn: ", tempo_spawn)

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
	if AuthManager.is_logged_in():
		salvar_pontuacao_firebase(pontos)
	
	# Vai para a tela de game over
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

func salvar_pontuacao_firebase(pontuacao):
	# Verifica se o usuário está logado
	var user_id = AuthManager.get_current_user_id()
	if not user_id:
		print("Usuário não está logado, não é possível salvar pontuação")
		return
		
	# Cria um nó HTTPRequest para enviar os dados para o Firebase
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_pontuacao_salva)
	
	# Dados para salvar (pontuação, data, etc)
	var data = {
		"pontuacao": pontuacao,
		"data": Time.get_datetime_string_from_system(),
		"user_id": user_id
	}
	
	# URL do Firebase Realtime Database
	# URL específica do seu banco de dados Firebase
	var firebase_db_url = "https://seu-projeto-default-rtdb.firebaseio.com" # Substitua esta URL pela que você copiou do console
	var endpoint = "/pontuacoes/%s.json" % user_id
	
	# Para adicionar uma nova pontuação à lista de pontuações do usuário
	# Você também pode usar .post() em vez de .put() se quiser manter um histórico
	# de pontuações para cada usuário
	http_request.request(firebase_db_url + endpoint, [], HTTPClient.METHOD_PUT, JSON.stringify(data))

func _on_pontuacao_salva(result, response_code, _headers, _body):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("Pontuação salva com sucesso no Firebase!")
	else:
		print("Erro ao salvar pontuação no Firebase. Código:", response_code)
