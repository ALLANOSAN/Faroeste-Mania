extends Control

@onready var back_button = %BackButton
@onready var player_id_value = %PlayerIDValue
@onready var username_input = %UsernameInput
@onready var save_username_button = %SaveUsernameButton
@onready var status_label = %StatusLabel
@onready var logout_button = %LogoutButton
@onready var delete_account_button = %DeleteAccountButton
@onready var player_rank_label = %PlayerRankLabel # Label para o rank do jogador
@onready var player_score_label = %PlayerScoreLabel # Label para a pontuação do jogador

@onready var global = get_node("/root/Global")

func _ready():
	# Conectar botões
	back_button.pressed.connect(_on_back_button_pressed)
	save_username_button.pressed.connect(_on_save_username_pressed)
	logout_button.pressed.connect(_handle_logout)
	delete_account_button.pressed.connect(_handle_delete_account)
	
	# Carregar informações do jogador
	load_player_info()
	
	# Carrega as pontuações para mostrar o rank do jogador
	global.load_leaderboard()
	
	# Conecta ao sinal de pontuações atualizadas para mostrar o rank
	global.scores_updated.connect(_on_scores_updated)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func load_player_info():
	"""Carrega e exibe as informações do jogador"""
	if global.is_user_logged_in():
		player_id_value.text = "ID: " + global.get_current_user_id()
		username_input.text = global.get_current_user_name()
		player_score_label.text = "Sua melhor pontuação: %d" % global.get_player_high_score()
	else:
		player_id_value.text = "ID: Não Logado"
		username_input.text = ""
		player_score_label.text = ""
		
func _on_save_username_pressed():
	if not global.is_user_logged_in():
		status_label.text = "Erro: Faça login para salvar o nome de usuário."
		return
	
	var new_username = username_input.text.strip_edges()
	if new_username.is_empty():
		status_label.text = "O nome de usuário não pode estar vazio."
		return
		
	status_label.text = "Salvando nome de usuário..."
	global.update_player_name(new_username)
	
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _handle_logout():
	global.logout()
	
func _handle_delete_account():
	# Implemente a lógica de exclusão de conta aqui
	# Exemplo: global.auth.delete_user_account()
	pass
	
func _on_scores_updated(scores):
	var user_id = global.get_current_user_id()
	var rank_info = null
	if user_id:
		rank_info = get_player_rank_info(user_id, scores)
		
	_display_player_rank(rank_info)
	
# Retorna a informação do rank do jogador
func get_player_rank_info(user_id, scores):
	var rank = -1
	var total_players = scores.size()
	for i in range(total_players):
		var entry = scores[i]
		if entry.user_id == user_id:
			rank = i + 1
			break
			
	return {
		"rank": rank,
		"total": total_players,
		"is_top_10": rank != -1 and rank <= 10
	}

# Exibe o rank do jogador no label
func _display_player_rank(rank_info):
	if rank_info and rank_info.rank != -1:
		var cor_texto = Color(1, 1, 1)
		var texto_adicional = ""
		if rank_info.is_top_10:
			cor_texto = Color(0.8, 0.8, 0.2)
			player_rank_label.text = "%dº Lugar - Top 10 Global!" % rank_info.rank
		else:
			cor_texto = Color(1, 0.7, 0.7)
			texto_adicional = "\n(Jogue mais para entrar no Top 10!)"
			player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank_info.rank, texto_adicional]
		player_rank_label.modulate = cor_texto
		if rank_info.total > 0:
			player_rank_label.text += "\n(%d de %d jogadores)" % [rank_info.rank, rank_info.total]
	else:
		player_rank_label.text = "Sem classificação ainda\nJogue para entrar no ranking!"
		player_rank_label.modulate = Color(1, 0.6, 0.2)
		player_rank_label.modulate = Color(0.8, 0.8, 0.8)
		
func _apply_platform_specific_settings():
	"""Aplica configurações específicas para a plataforma atual"""
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis na tela de perfil...")
		# Ajustar tamanho de botões e inputs para melhor uso com toque
		if is_instance_valid(username_input):
			username_input.custom_minimum_size.y = 60
		if is_instance_valid(save_username_button):
			save_username_button.custom_minimum_size.y = 70
		if is_instance_valid(back_button):
			back_button.custom_minimum_size.y = 70
		if is_instance_valid(logout_button):
			logout_button.custom_minimum_size.y = 70
		if is_instance_valid(delete_account_button):
			delete_account_button.custom_minimum_size.y = 70
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop na tela de perfil...")
		pass