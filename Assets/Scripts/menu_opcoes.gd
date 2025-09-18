extends Control

@onready var botao_voltar = %BTVoltarMainMenu
@onready var botao_som = %BTChamarMenuSom
@onready var botao_leaderboard = %BTChamarMenuLeadboard
@onready var botao_perfil = %BTPerfilJogador
@onready var loot_locker_manager = get_node("/root/LootLockerManager")
@onready var global = get_node("/root/Global")

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
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")

func _on_botao_perfil_pressed():
	# Vai para a tela de perfil do jogador
	get_tree().change_scene_to_file("res://Assets/Scenes/PerfilJogador.tscn")

func _update_perfil_button_visibility():
	# Mostra o botão de perfil apenas se o usuário estiver logado
	if global.is_user_logged_in():
		botao_perfil.show()
	else:
		botao_perfil.hide()

func _apply_platform_specific_settings():
	# Aplica configurações específicas para a plataforma atual
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis no menu de opções...")
		# Ajustar tamanhos de botões, fontes etc para telas menores se necessário
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop no menu de opções...")
		# Ajustar elementos para uso com mouse
