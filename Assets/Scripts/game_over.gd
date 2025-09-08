extends Control

@onready var video_player = $VideoStreamPlayer
@onready var button_menu = $botao_tela_inicial
@onready var button_retry = $botao_tentar_novamente
@onready var button_leaderboard = $botao_classificacao
@onready var auth_manager = get_node("/root/AuthManager")

var pontuacao_final = 0

func _ready():
	# Já não precisamos criar o botão manualmente, ele já está na cena
	# Esconde os botões até o vídeo terminar
	button_menu.hide()
	button_retry.hide()
	button_leaderboard.hide()
	
	# Esconde o label de pontuação até o vídeo terminar
	$PontuacaoLabel.hide()
	
	# Conecta os botões
	button_menu.pressed.connect(_on_button_menu_pressed)
	button_retry.pressed.connect(_on_button_retry_pressed)
	button_leaderboard.pressed.connect(_on_button_leaderboard_pressed)
	
	# Conecta o sinal de finalização do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Carrega a pontuação do jogo anterior
	carregar_dados_jogo()
	
	# Salva a pontuação no servidor se o usuário estiver logado
	if auth_manager.is_logged_in():
		auth_manager.save_score(pontuacao_final)
	
	# Ajusta o vídeo para tela cheia
	ajustar_video_tela_cheia()

func ajustar_video_tela_cheia():
	# Obtém o tamanho da tela
	var screen_size = get_viewport_rect().size
	
	# Ajusta o tamanho do player de vídeo para cobrir a tela
	video_player.size = screen_size
	video_player.position = Vector2.ZERO

func _on_video_finished():
	print("Vídeo finalizado, mostrando botões")
	button_menu.show()
	button_retry.show()
	button_leaderboard.show()
	$PontuacaoLabel.show() # Mostra a pontuação final

func _on_button_menu_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_button_retry_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
	
func _on_button_leaderboard_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")

func carregar_dados_jogo():
	# Tenta carregar os dados temporários do jogo
	if FileAccess.file_exists("user://temp_game_data.save"):
		var save_game = FileAccess.open("user://temp_game_data.save", FileAccess.READ)
		var json_string = save_game.get_line()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.data
			if data.has("pontuacao"):
				pontuacao_final = data.pontuacao
				print("Pontuação carregada: ", pontuacao_final)
				
				# Atualiza a UI com a pontuação
				if has_node("PontuacaoLabel"):
					$PontuacaoLabel.text = "Pontuação: " + str(pontuacao_final)
		else:
			print("Erro ao analisar dados do jogo")
	else:
		print("Arquivo de dados do jogo não encontrado")
