extends Control

@onready var video_player = %VideoStreamPlayer
@onready var button_retry = %botao_tentar_novamente
@onready var button_leaderboard = %botao_classificacao
@onready var button_tela_inicial = %botao_tela_inicial
@onready var loot_locker_manager = get_node("/root/LootLockerManager")
@onready var global = get_node("/root/Global")

var pontuacao_final = 0
var foi_rank_salvo = false
var login_incentive_label = null

func _ready():
	# Já não precisamos criar o botão manualmente, ele já está na cena
	# Esconde os botões até o vídeo terminar
	button_tela_inicial.hide()
	button_retry.hide()
	button_leaderboard.hide()
	
	# Esconde o label de pontuação até o vídeo terminar
	%PontuacaoLabel.hide()
	
	# Conecta os botões
	button_tela_inicial.pressed.connect(_on_button_menu_pressed)
	button_retry.pressed.connect(_on_button_retry_pressed)
	button_leaderboard.pressed.connect(_on_button_leaderboard_pressed)
	
	# Conecta o sinal de finalização do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Carrega a pontuação atual do jogo que acabou de terminar
	carregar_pontuacao_atual()
	
	# Mostra informações do jogador se estiver logado
	if global.is_user_logged_in():
		print("Jogador logado: " + global.get_current_user_id())
		print("Pontuação máxima: " + str(global.get_player_high_score()))
	
	# Ajusta o vídeo para tela cheia
	ajustar_video_tela_cheia()
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func ajustar_video_tela_cheia():
	# Como o VideoPlayer já tem anchors = (0, 0, 1, 1), ele já está configurado para preencher toda a tela
	# Não precisamos definir o tamanho manualmente, pois os anchors já fazem isso
	# Removendo a definição de tamanho que estava causando o aviso
	pass

func _on_video_finished():
	print("Vídeo finalizado, mostrando botões")
	button_tela_inicial.show()
	button_retry.show()
	button_leaderboard.show()
	%PontuacaoLabel.show() # Mostra a pontuação final
	
	# Se o label de incentivo foi criado, também mostra
	if login_incentive_label and login_incentive_label.get_parent():
		login_incentive_label.get_parent().get_parent().show()

func _on_button_menu_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_button_retry_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
	
func _on_button_leaderboard_pressed():
	# Garante que vamos ver a pontuação atualizada imediatamente
	if global.is_user_logged_in():
		# Recarrega as pontuações antes de abrir a tela
		global.load_leaderboard()
	
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")

func carregar_pontuacao_atual():
	# Tenta carregar os dados temporários do jogo atual que acabou de terminar
	if FileAccess.file_exists("user://temp_game_data.save"):
		var save_game = FileAccess.open("user://temp_game_data.save", FileAccess.READ)
		var json_string = save_game.get_line()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.data
			if data.has("pontuacao"):
				pontuacao_final = data.pontuacao
				print("Pontuação atual carregada: ", pontuacao_final)
				
				# Verifica se o rank foi salvo
				foi_rank_salvo = data.get("rank_salvo", false)
				
				# Atualiza a UI com a pontuação
				if has_node("%PontuacaoLabel"):
					if foi_rank_salvo:
						%PontuacaoLabel.text = "Pontuação: %d\n(Salva na classificação!)" % pontuacao_final
					else:
						%PontuacaoLabel.text = "Pontuação: %d" % pontuacao_final
						
				# Se não estiver logado e tiver uma boa pontuação, incentivar login
				if not global.is_user_logged_in() and pontuacao_final > 50:
					criar_incentivo_login()
		else:
			print("Erro ao analisar dados do jogo")
	else:
		print("Arquivo de dados do jogo não encontrado")
		
	# Deletamos o arquivo temporário para evitar que seja carregado em sessões futuras
	# Isso garante que cada novo jogo tenha sua própria pontuação independente
	if FileAccess.file_exists("user://temp_game_data.save"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("temp_game_data.save")
			print("Arquivo temporário de pontuação removido")
