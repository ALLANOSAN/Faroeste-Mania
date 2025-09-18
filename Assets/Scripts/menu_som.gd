extends Control

# Referência ao botão de voltar
@onready var botao_voltar = %BotaoVoltar
@onready var global = get_node("/root/Global")

func _ready():
	# Conecta o botão de voltar ao método correspondente
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

# Função para voltar ao menu de opções
func _on_botao_voltar_pressed():
	# Navega de volta para o menu de opções
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
	
func _apply_platform_specific_settings():
	# Aplica configurações específicas para a plataforma atual
	if global.Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis no menu de som...")
		# Ajustar tamanhos de botões, sliders etc para telas menores se necessário
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop no menu de som...")
		# Ajustar elementos para uso com mouse
