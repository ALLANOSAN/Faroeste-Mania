extends Control

# Referência ao botão de voltar
@onready var botao_voltar = %BotaoVoltar
@onready var volume_slider = $Panel/HSlider
@onready var mute_checkbox = $Panel/CheckBox

func _ready():
	# Conecta o botão de voltar ao método correspondente
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	
	# Configura Slider
	if volume_slider:
		volume_slider.value = AudioManager.current_volume
		volume_slider.value_changed.connect(_on_volume_changed)
	
	# Configura CheckBox
	if mute_checkbox:
		mute_checkbox.button_pressed = AudioManager.is_muted
		mute_checkbox.toggled.connect(_on_mute_toggled)
		# Força atualização visual inicial se necessário
		if mute_checkbox.has_method("_on_checkbox_toggled"):
			mute_checkbox._on_checkbox_toggled(AudioManager.is_muted)
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func _on_volume_changed(value):
	AudioManager.set_volume(value)

func _on_mute_toggled(toggled_on):
	AudioManager.toggle_mute(toggled_on)

# Função para voltar ao menu de opções
func _on_botao_voltar_pressed():
	# Navega de volta para o menu de opções
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
	
func _apply_platform_specific_settings():
	# Aplica configurações específicas para a plataforma atual
	if Platform.is_mobile:
		# Otimizações para dispositivos móveis
		print("Aplicando configurações de UI para dispositivos móveis no menu de som...")
		# Ajustar tamanhos de botões, sliders etc para telas menores se necessário
	else:
		# Otimizações para desktop
		print("Aplicando configurações de UI para desktop no menu de som...")
		# Ajustar elementos para uso com mouse
