extends Control

# Variáveis para os nós da interface
@onready var login_button = $Panel/LoginButton
@onready var options_menu_button = $Panel/OptionsMenuButton
@onready var blinking_text = $Panel/BlinkingText
@onready var animation_player = $Panel/BlinkingText/AnimationPlayer
@onready var game_title = $Panel/GameTitle

func _ready():
	# Verifica o estado de login usando o Autoload AuthManager
	if AuthManager.is_logged_in():
		# Se o usuário está logado, esconde o botão de login e mostra as opções.
		login_button.hide()
		options_menu_button.show()
		blinking_text.show()
		animation_player.play("blink")
	else:
		# Se o usuário não está logado, esconde o botão de opções e mostra o de login.
		options_menu_button.hide()
		blinking_text.hide()
		animation_player.stop()
		login_button.show()
	
	# Conecta os botões para suas ações
	login_button.pressed.connect(_on_login_button_pressed)
	options_menu_button.pressed.connect(_on_options_menu_button_pressed)

func _on_login_button_pressed():
	# Este botão deve levar o jogador para a cena de login
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

func _on_options_menu_button_pressed():
	# Este botão deve levar o jogador para a cena de opções do jogo
	print("Botão de Opções pressionado!")
	# get_tree().change_scene_to_file("res://Assets/Scenes/options.tscn")
