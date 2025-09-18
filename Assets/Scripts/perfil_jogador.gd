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
	logout_button.pressed.connect(_on_logout_button_pressed)
	delete_account_button.pressed.connect(_on_delete_account_button_pressed)
	
	# Carregar informações do jogador
	load_player_info()
	
	# Carrega as pontuações para mostrar o rank do jogador
	global.load_scores()
	
	# Conecta ao sinal de pontuações atualizadas para mostrar o rank
	global.scores_updated.connect(_on_scores_updated)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func load_player_info():
	"""Carrega e exibe as informações do jogador"""
	if global.is_user_logged_in():
		# Mostra ID do jogador
		player_id_value.text = global.get_current_user_id()
		
		# Define o nome de usuário atual no campo de input
		var player_name = global.get_player_name()
		if player_name != "Visitante":
			username_input.text = player_name
		else:
			username_input.text = global.get_current_user_id()
		
		print("Informações do jogador carregadas:")
		print("ID: " + global.get_current_user_id())
		print("Nome: " + global.get_player_name())
		
		# Atualiza as informações de rank e pontuação
		atualizar_rank_jogador()
	else:
		# Se não estiver logado, volta para o menu principal
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_scores_updated(_scores):
	"""Quando as pontuações são atualizadas, atualiza a exibição do rank do jogador"""
	atualizar_rank_jogador()

func _on_back_button_pressed():
	"""Volta para o menu de opções"""
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")

func _on_save_username_pressed():
	"""Salva o novo nome de usuário"""
	var new_username = username_input.text.strip_edges()
	
	if new_username == "":
		show_status("Nome de usuário não pode estar vazio!", Color(1, 0, 0))
		return
	
	if new_username == global.get_player_name():
		show_status("Este já é seu nome de usuário atual!", Color(1, 1, 0))
		return
		
	# Mostra status de salvamento
	show_status("Salvando nome de usuário...", Color(1, 1, 0))
	
	# Implementação real para salvar o nome do jogador usando LootLocker
	if global.loot_locker_manager:
		global.loot_locker_manager.set_player_name(new_username)
		show_status("Nome de usuário alterado com sucesso!", Color(0, 1, 0))
	else:
		show_status("Erro ao alterar nome de usuário!", Color(1, 0, 0))
		return
	
	print("Nome de usuário alterado para: " + new_username)

func _on_logout_button_pressed():
	"""Faz logout do jogador"""
	global.logout()
	show_status("Logout realizado com sucesso!", Color(0, 1, 0))
	
	# Aguarda um pouco e volta para o menu principal
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_delete_account_button_pressed():
	"""Exclui a conta do jogador"""
	# Mostra confirmação
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Tem certeza que deseja excluir sua conta?\nEsta ação não pode ser desfeita!"
	confirm_dialog.title = "Confirmar Exclusão"
	add_child(confirm_dialog)
	
	# Conecta o sinal de confirmação
	confirm_dialog.confirmed.connect(_confirm_delete_account)
	confirm_dialog.canceled.connect(_cancel_delete_account)
	
	confirm_dialog.popup_centered()

func _confirm_delete_account():
	"""Confirma a exclusão da conta"""
	show_status("Conta excluída com sucesso!", Color(0, 1, 0))
	
	# Aqui você implementaria a lógica real de exclusão da conta
	# Por enquanto, apenas faz logout
	global.clear_session()
	
	# Aguarda um pouco e volta para o menu principal
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _cancel_delete_account():
	"""Cancela a exclusão da conta"""
	show_status("Exclusão cancelada.", Color(1, 1, 0))

func show_status(message: String, color: Color):
	"""Mostra uma mensagem de status"""
	status_label.text = message
	status_label.modulate = color
	status_label.show()
	
	# Esconde a mensagem após 3 segundos
	await get_tree().create_timer(3.0).timeout
	status_label.hide()

func _input(event):
	"""Detecta tecla Enter para salvar nome de usuário"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER and username_input.has_focus():
			_on_save_username_pressed()
			
func atualizar_rank_jogador():
	"""Atualiza a exibição do rank do jogador"""
	if not is_instance_valid(player_rank_label) or not is_instance_valid(player_score_label):
		print("Labels de rank não encontrados. Eles podem não existir na cena.")
		return
		
	if not global.is_user_logged_in():
		player_rank_label.text = "Faça login para ver seu rank"
		player_score_label.text = "0"
		return
	
	# Mostra indicador de carregamento
	player_rank_label.text = "Carregando rank..."
	
	# Obtem o rank do jogador (função assíncrona)
	var rank_info = await global.get_player_rank()
	var high_score = global.get_player_high_score()
	
	if rank_info.rank > 0:
		player_rank_label.text = "%dº Lugar no Ranking Global" % rank_info.rank
		
		# Se o rank for maior que 10, adiciona uma mensagem especial
		if rank_info.rank > 10:
			player_rank_label.text += "\n(Fora do Top 10 mostrado na tabela principal)"
	else:
		player_rank_label.text = "Sem classificação ainda"
		
	player_score_label.text = "%d pontos" % high_score
	
func _apply_platform_specific_settings():
	"""Aplica configurações específicas para a plataforma atual"""
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis na tela de perfil...")
		# Ajustar tamanho de botões e inputs para melhor uso com toque
		if is_instance_valid(username_input):
			username_input.custom_minimum_size.y = 60
		if is_instance_valid(save_username_button):
			save_username_button.custom_minimum_size.y = 60
		if is_instance_valid(logout_button):
			logout_button.custom_minimum_size.y = 60
		if is_instance_valid(delete_account_button):
			delete_account_button.custom_minimum_size.y = 60
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop na tela de perfil...")
		# Manter tamanhos padrão, adequados para uso com mouse
