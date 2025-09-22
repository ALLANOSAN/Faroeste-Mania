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
	global.load_scores()
	
	# Conecta ao sinal de pontuações atualizadas para mostrar o rank
	global.scores_updated.connect(_on_scores_updated)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func load_player_info():
	"""Carrega e exibe as informações do jogador"""
	if global.is_user_logged_in():
		player_id_value.text = global.get_current_user_id()
		show_status("Carregando perfil...", Color(1, 1, 0))
		# Usa o nome do Global.gd
		var nome = global.get_player_name()
		if nome and not nome.is_empty():
			username_input.text = nome
			show_status("Perfil carregado com sucesso!", Color(0, 1, 0))
		else:
			username_input.text = "Jogador " + global.get_current_user_id().substr(0, 5)
			show_status("Nome de usuário não configurado", Color(1, 1, 0))

		# Usa o score do Global.gd
		var score = global.get_player_high_score()
		if score > 0:
			player_score_label.text = "Sua pontuação: " + str(score)
		else:
			player_score_label.text = "Pontuação: 0"

		# Atualiza as informações de rank e pontuação
		atualizar_rank_jogador()
	else:
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_scores_updated(scores_data):
	"""Quando as pontuações são atualizadas, atualiza a exibição do rank do jogador"""
	# Atualiza o ranking
	atualizar_rank_jogador()
	
	# Se temos dados de pontuações, podemos atualizar diretamente
	if scores_data and scores_data.size() > 0:
		var user_id = global.get_current_user_id()
		var rank = 0
		var score = 0
		
		# Procura o usuário atual na lista de pontuações
		for i in range(scores_data.size()):
			if scores_data[i].user_id == user_id:
				rank = i + 1
				score = scores_data[i].score
				break
		
		# Atualiza as informações na interface
		if rank > 0:
			# Define a pontuação
			player_score_label.text = "Sua pontuação: " + str(score)
			
			# Define o rank com o mesmo esquema de formatação
			var cor_texto = Color(1, 1, 1) # Branco padrão
			var texto_medalha = ""
			var texto_adicional = ""
			
			# Personaliza a exibição com base no ranking
			if rank == 1:
				cor_texto = Color(1, 0.84, 0) # Dourado
				texto_medalha = "🏆 CAMPEÃO GLOBAL! 🏆"
				player_rank_label.text = texto_medalha
			elif rank == 2:
				cor_texto = Color(0.75, 0.75, 0.75) # Prata
				texto_medalha = " 🥈"
				player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank, texto_medalha]
			elif rank == 3:
				cor_texto = Color(0.8, 0.5, 0.2) # Bronze
				texto_medalha = " 🥉"
				player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank, texto_medalha]
			elif rank <= 10:
				cor_texto = Color(0, 0.8, 0.2) # Verde para top 10
				player_rank_label.text = "%dº Lugar - Top 10 Global!" % rank
			else:
				# Para ranks acima de 10
				cor_texto = Color(1, 0.7, 0.7) # Vermelho claro
				texto_adicional = "\n(Jogue mais para entrar no Top 10!)"
				player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank, texto_adicional]
			
			player_rank_label.modulate = cor_texto
			
			# Adiciona informação sobre o total de jogadores
			player_rank_label.text += "\n(%d de %d jogadores)" % [rank, scores_data.size()]

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
	
	# Salva o nome do jogador usando função centralizada do Global.gd
	var user_id = global.get_current_user_id()
	if user_id.is_empty():
		show_status("Erro: Usuário não logado!", Color(1, 0, 0))
		return

	# Chama função centralizada (você pode implementar set_player_name em Global.gd)
	global.set_player_name(new_username, func(success, msg):
		if success:
			show_status("Nome de usuário alterado com sucesso!", Color(0, 1, 0))
			print("Nome de usuário alterado para: " + new_username)
			global.load_leaderboard()
		else:
			show_status(msg, Color(1, 0, 0))
	)

func _handle_logout():
	"""Função para lidar com o clique no botão de logout"""
	# Mostramos um status de sucesso antes de fazer logout
	show_status("Logout realizado com sucesso!", Color(0, 1, 0))
	
	# Aguarda um pouco para que o status seja exibido
	await get_tree().create_timer(1.0).timeout
	
	# Carrega o script auth.gd e chama a função de logout do Firebase
	var auth = load("res://Assets/Scripts/auth.gd").new()
	auth._on_logout_button_pressed()
	
	# Não precisamos navegar manualmente para a tela de login
	# A função no auth.gd já faz isso

func _handle_delete_account():
	"""Gerencia a interface de confirmação para exclusão de conta"""
	# Mostra confirmação
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Tem certeza que deseja excluir sua conta?\nEsta ação não pode ser desfeita!"
	confirm_dialog.title = "Confirmar Exclusão"
	add_child(confirm_dialog)
	
	# Adiciona botão de cancelamento explícito
	confirm_dialog.add_cancel_button("Cancelar")
	
	# Conecta os sinais
	confirm_dialog.confirmed.connect(func():
		# Mostra feedback visual
		show_status("Excluindo sua conta...", Color(1, 0.6, 0))
		
		# Pequeno delay para feedback visual
		await get_tree().create_timer(0.5).timeout
		
		# Usa diretamente o singleton auth.gd
		var auth_script = load("res://Assets/Scripts/auth.gd").new()
		auth_script._on_delete_account_button_pressed()
		# A função no auth.gd cuida do resto: deletar a conta e navegar
	)
	
	# Exibe a mensagem de cancelamento
	confirm_dialog.canceled.connect(func():
		show_status("Exclusão cancelada.", Color(1, 1, 0))
	)
	
	# Exibe o diálogo
	confirm_dialog.popup_centered()

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
	player_rank_label.modulate = Color(1, 1, 0) # Amarelo para indicar carregamento
	
	# Obtem o rank e score do jogador via Global.gd
	var rank_info = await global.get_player_rank()
	var high_score = global.get_player_high_score()

	if high_score > 0:
		if high_score >= 1000:
			player_score_label.text = "🔥 %d pontos 🔥" % high_score
			player_score_label.modulate = Color(1, 0.5, 0)
		else:
			player_score_label.text = "%d pontos" % high_score
			player_score_label.modulate = Color(1, 0.8, 0)
	else:
		player_score_label.text = "0 pontos (Jogue para pontuar!)"
		player_score_label.modulate = Color(0.7, 0.7, 0.7)

	if rank_info.rank > 0:
		var cor_texto = Color(1, 1, 1)
		var texto_medalha = ""
		var texto_adicional = ""
		if rank_info.rank == 1:
			cor_texto = Color(1, 0.84, 0)
			texto_medalha = "🏆 CAMPEÃO GLOBAL! 🏆"
			player_rank_label.text = texto_medalha
		elif rank_info.rank == 2:
			cor_texto = Color(0.75, 0.75, 0.75)
			texto_medalha = " 🥈"
			player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank_info.rank, texto_medalha]
		elif rank_info.rank == 3:
			cor_texto = Color(0.8, 0.5, 0.2)
			texto_medalha = " 🥉"
			player_rank_label.text = "%dº Lugar no Ranking Global%s" % [rank_info.rank, texto_medalha]
		elif rank_info.rank <= 10:
			cor_texto = Color(0, 0.8, 0.2)
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
			save_username_button.custom_minimum_size.y = 60
		if is_instance_valid(logout_button):
			logout_button.custom_minimum_size.y = 60
		if is_instance_valid(delete_account_button):
			delete_account_button.custom_minimum_size.y = 60
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop na tela de perfil...")
		# Manter tamanhos padrão, adequados para uso com mouse
