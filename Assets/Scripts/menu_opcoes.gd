extends Control

@onready var botao_voltar = %BTVoltarMainMenu
@onready var botao_som = %BTChamarMenuSom
@onready var botao_leaderboard = %BTChamarMenuLeadboard
@onready var botao_perfil = %BTPerfilJogador

func _ready():
	# Conectar os sinais dos botões
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_som.pressed.connect(_on_botao_som_pressed)
	botao_leaderboard.pressed.connect(_on_botao_leaderboard_pressed)
	botao_perfil.pressed.connect(_on_botao_perfil_pressed)
	
	# Mostrar/esconder botão de perfil baseado no status de login
	_update_perfil_button_visibility()
	
	# Aplicar otimizações específicas de plataforma
	_apply_platform_specific_settings()

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_botao_som_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuSOM.tscn")
	
func _on_botao_leaderboard_pressed():
	# O leaderboard vai carregar a autenticação internamente
	print("📋 Abrindo leaderboard...")
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")

func _on_botao_perfil_pressed():
	# Vai para a tela de perfil do jogador
	get_tree().change_scene_to_file("res://Assets/Scenes/PerfilJogador.tscn")

func _update_perfil_button_visibility():
	# Mostra o botão de perfil apenas se o usuário estiver logado
	# Verifica se existe autenticação ativa no Firebase
	if Firebase.Auth.auth != null and not Firebase.Auth.auth.is_empty() and Firebase.Auth.auth.has("idtoken"):
		botao_perfil.show()
	else:
		botao_perfil.hide()

func _apply_platform_specific_settings():
	# Aplica configurações específicas para a plataforma atual
	if Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis no menu de opções...")
		# Ajustar tamanhos de botões, fontes etc para telas menores se necessário
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop no menu de opções...")
		# Ajustar elementos para uso com mouse
