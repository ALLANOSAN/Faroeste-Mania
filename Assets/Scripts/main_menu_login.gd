extends Control

@onready var login_button = $Panel/LoginButton
@onready var options_menu_button = $Panel/OptionsMenuButton
@onready var blinking_text = $Panel/BlinkingText
@onready var animation_player = $Panel/BlinkingText/AnimationPlayer
@onready var game_title = $Panel/GameTitle

func _ready():
	# Verifica se já está logado
	if AuthManager.is_logged_in():
		# Mostra opções e texto piscando
		login_button.hide()
		options_menu_button.show()
		blinking_text.show()
		animation_player.play("blink")
	else:
		# Mostra apenas botão de login
		options_menu_button.hide()
		blinking_text.hide()
		animation_player.stop()
		login_button.show()

	# Conectar botões
	login_button.pressed.connect(_on_login_button_pressed)
	options_menu_button.pressed.connect(_on_options_menu_button_pressed)

# Botão de login → vai para a cena login.tscn
func _on_login_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/login.tscn")

# Botão de opções → vai para o menu de opções
func _on_options_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")
