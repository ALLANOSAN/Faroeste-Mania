extends Control

@onready var video_player = $VideoStreamPlayer
@onready var button_menu = $botao_tela_inicial
@onready var button_retry = $botao_tentar_novamente
@onready var button_leaderboard = $botao_classificacao

var pontuacao_final = 0

func _ready():
	# Verifica se o botão de classificação existe na cena, caso contrário cria-o
	if not has_node("botao_classificacao"):
		var new_button = Button.new()
		new_button.name = "botao_classificacao"
		new_button.text = "Ver Classificação"
		new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Configura o estilo do botão para ficar similar aos outros
		new_button.add_theme_font_size_override("font_size", 50)
		
		# Posiciona o botão abaixo dos outros
		new_button.anchor_left = 0.5
		new_button.anchor_top = 0.5
		new_button.anchor_right = 0.5
		new_button.anchor_bottom = 0.5
		new_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		new_button.grow_vertical = Control.GROW_DIRECTION_BOTH
		new_button.position = Vector2(-300, 500) # Posição abaixo dos botões existentes
		new_button.size = Vector2(600, 100)
		
		add_child(new_button)
		button_leaderboard = new_button
	
	# Esconde os botões até o vídeo terminar
	button_menu.hide()
	button_retry.hide()
	if button_leaderboard:
		button_leaderboard.hide()
	
	# Conecta os botões
	button_menu.pressed.connect(_on_button_menu_pressed)
	button_retry.pressed.connect(_on_button_retry_pressed)
	if button_leaderboard:
		button_leaderboard.pressed.connect(_on_button_leaderboard_pressed)
	
	# Conecta o sinal de finalização do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Carrega a pontuação do jogo anterior
	carregar_dados_jogo()
	
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
	if button_leaderboard:
		button_leaderboard.show()

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
